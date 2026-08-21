#!/usr/bin/env python3
"""
DK Balance Config Migration Script
===================================
Converts hardcoded balance values in DK perk/skill .uc files to config vars
that auto-generate into KFZedternalUnlimited_Balance.ini on first server start.

What it does for each DK perk/skill file:
  1. Migrates 'extends WMUpgrade_Perk' -> 'extends DKUpgrade_Perk' (and Skill equiv)
  2. Identifies balance vars (vars with values in defaultproperties, excluding display-only)
  3. Marks balance vars as 'var config'
  4. Adds 'var config int MODEVERSION;'
  5. Adds 'static function UpdateConfig()' that seeds defaults on first run
  6. Removes balance values from defaultproperties block

Also:
  - Updates DKUpgrade_Perk.uc / DKUpgrade_Skill.uc to add config(ZedternalUnlimited_Balance)
  - Generates DKConfig_BalanceLoader.uc (called from DKGameInfo_Endless.InitGame)

Usage:
  python DK_BalanceConfigMigration.py                     # Dry run (preview only)
  python DK_BalanceConfigMigration.py --apply              # Apply changes + create backups
  python DK_BalanceConfigMigration.py --apply --no-backup  # Apply without backups
"""

import os
import re
import sys
import shutil
from datetime import datetime
from collections import OrderedDict

# =============================================================================
# CONFIGURATION
# =============================================================================

CLASSES_DIR = r"C:\Users\Anwender\Documents\My Games\KillingFloor2\KFGame\Src\ZedternalRBPerkpackage\Classes"

INI_NAME = "ZedternalUnlimited_Balance"

# Property base names in defaultproperties to NEVER convert to config
# (case-insensitive matching)
DISPLAY_PROPS = {
    'upgradename', 'upgradedescription', 'upgradeicon',
    'legacyupgradeicon', 'perkbonus', 'bshouldlocalize',
    'localizedescriptionlinecount', 'name'
}

# =============================================================================
# PARSING
# =============================================================================

def parse_class_declaration(lines):
    """Parse the class declaration (may span multiple lines)."""
    decl_lines = []
    start = -1
    for i, line in enumerate(lines):
        stripped = line.strip()
        if stripped.startswith('//') or stripped == '':
            continue
        if stripped.lower().startswith('class '):
            start = i
        if start >= 0:
            decl_lines.append(line)
            if ';' in line:
                end = i
                break
    else:
        return None
    full_text = '\n'.join(decl_lines)
    m = re.match(r'class\s+(\w+)\s+extends\s+(\w+)', full_text, re.IGNORECASE)
    if not m:
        return None
    return m.group(1), m.group(2), start, end, full_text


def parse_var_declarations(lines, class_end_line, dp_start_line):
    """Parse var declarations between class decl and defaultproperties."""
    var_decls = []
    for i in range(class_end_line + 1, dp_start_line):
        line = lines[i]
        stripped = line.strip()
        if not stripped.startswith('var '):
            continue

        # Remove trailing ; and inline comments for parsing
        code = stripped
        if '//' in code:
            code = code[:code.index('//')].rstrip()
        code = code.rstrip(';').strip()

        has_config = 'config' in code.split()

        # Remove 'var' prefix, skip modifiers to find type
        rest = code[3:].strip()
        parts = rest.split()
        modifiers = []
        idx = 0
        known_mods = {'config', 'const', 'localized', 'private', 'protected',
                       'transient', 'native', 'editconst', 'editinline',
                       'export', 'noexport', 'globalconfig', 'repnotify',
                       'databinding', 'editoronly', 'notforconsole',
                       'instanced', 'input', 'deprecated'}

        while idx < len(parts):
            if parts[idx].lower() in known_mods:
                modifiers.append(parts[idx])
                idx += 1
            else:
                break

        if idx >= len(parts):
            continue

        # Type token (handles array<type> possibly split by spaces)
        type_token = parts[idx]
        idx += 1
        if type_token.lower().startswith('array<') and '>' not in type_token:
            while idx < len(parts) and '>' not in type_token:
                type_token += ' ' + parts[idx]
                idx += 1

        type_str = type_token
        is_array = type_str.lower().startswith('array<')

        # Remaining parts are variable names (comma separated)
        names_part = ' '.join(parts[idx:])
        var_names = [n.strip().rstrip(';') for n in names_part.split(',') if n.strip()]

        for vn in var_names:
            var_decls.append({
                'name': vn, 'type': type_str, 'line_idx': i,
                'is_array': is_array, 'full_line': lines[i],
                'has_config': has_config, 'all_names_on_line': var_names,
                'modifiers': modifiers,
            })

    return var_decls


def find_defaultproperties(lines):
    """Find the defaultproperties block. Returns (start_line, end_line)."""
    start = -1
    brace_depth = 0
    for i, line in enumerate(lines):
        stripped = line.strip()
        if stripped.lower() == 'defaultproperties' or stripped.lower().startswith('defaultproperties'):
            start = i
        if start >= 0:
            brace_depth += stripped.count('{') - stripped.count('}')
            if brace_depth <= 0 and '{' in ''.join(lines[start:i+1]):
                return start, i
    return start, len(lines) - 1


def parse_dp_assignments(lines, dp_start, dp_end):
    """Parse assignments inside defaultproperties block."""
    assignments = []
    for i in range(dp_start, dp_end + 1):
        stripped = lines[i].strip()
        if stripped in ('defaultproperties', '{', '}', ''):
            continue
        if stripped.startswith('//'):
            continue

        m = re.match(r'^(\w+)(?:\((\d+)\))?\s*=\s*(.+)$', stripped)
        if m:
            assignments.append({
                'base_name': m.group(1),
                'index': int(m.group(2)) if m.group(2) is not None else None,
                'value': m.group(3).strip(),
                'line_idx': i,
                'full_line': lines[i],
            })

    return assignments


# =============================================================================
# TRANSFORMATION
# =============================================================================

def identify_balance_vars(var_decls, dp_assignments):
    """Identify vars that have values in defaultproperties and are NOT display-only."""
    dp_var_names = set()
    for a in dp_assignments:
        if a['base_name'].lower() not in DISPLAY_PROPS:
            dp_var_names.add(a['base_name'])

    # Exclude class<X> typed vars - UE3 doesn't allow config on object references
    # Exclude const vars - UE3 doesn't allow assigning const at runtime
    declared_names = set()
    for v in var_decls:
        if v['type'].lower().startswith('class<'):
            continue
        if 'const' in [m.lower() for m in v['modifiers']]:
            continue
        declared_names.add(v['name'])

    return dp_var_names & declared_names


def build_update_config(balance_vars, dp_assignments):
    """Build the UpdateConfig() function body as list of lines."""
    var_assignments = OrderedDict()
    for a in dp_assignments:
        if a['base_name'] in balance_vars:
            if a['base_name'] not in var_assignments:
                var_assignments[a['base_name']] = []
            var_assignments[a['base_name']].append(a)

    lines = []
    lines.append('static function UpdateConfig()')
    lines.append('{')
    lines.append('\tif (default.MODEVERSION < 1)')
    lines.append('\t{')

    for var_name, assigns in var_assignments.items():
        for a in assigns:
            # Strip inline comments from value (safe in defaultproperties but breaks code)
            val = a['value']
            if '//' in val and not val.strip().startswith('"'):
                val = val[:val.index('//')].rstrip()
            if a['index'] is not None:
                lines.append(f"\t\tdefault.{var_name}[{a['index']}] = {val};")
            else:
                lines.append(f"\t\tdefault.{var_name} = {val};")

    lines.append('')
    lines.append('\t\tdefault.MODEVERSION = 1;')
    lines.append('\t\tstatic.StaticSaveConfig();')
    lines.append('\t}')
    lines.append('}')

    return lines


def transform_file(filepath, dry_run=True):
    """Transform a single DK perk/skill file. Returns (new_content, report) or (None, report)."""
    with open(filepath, 'r', encoding='utf-8-sig') as f:
        content = f.read()
    lines = content.split('\n')

    report = {
        'file': os.path.basename(filepath),
        'extends_migrated': False,
        'balance_vars': [],
        'has_update_config': False,
        'skipped_reason': None,
    }

    # Parse class declaration
    result = parse_class_declaration(lines)
    if result is None:
        report['skipped_reason'] = 'Could not parse class declaration'
        return None, report

    class_name, parent_class, class_start, class_end, class_text = result

    # Skip if already converted
    if f'config({INI_NAME})' in content:
        report['skipped_reason'] = 'Already has config specifier'
        return None, report
    if 'MODEVERSION' in content:
        report['skipped_reason'] = 'Already has MODEVERSION'
        return None, report

    # Determine extends migration
    is_perk = 'DKUpgrade_Perk_' in class_name
    is_skill = 'DKUpgrade_Skill_' in class_name
    new_parent = None

    if is_perk and parent_class == 'WMUpgrade_Perk':
        new_parent = 'DKUpgrade_Perk'
        report['extends_migrated'] = True
    elif is_skill and parent_class == 'WMUpgrade_Skill':
        new_parent = 'DKUpgrade_Skill'
        report['extends_migrated'] = True

    # Find defaultproperties
    dp_start, dp_end = find_defaultproperties(lines)
    if dp_start < 0:
        report['skipped_reason'] = 'No defaultproperties block found'
        return None, report

    # Parse vars and defaultproperties
    var_decls = parse_var_declarations(lines, class_end, dp_start)
    dp_assignments = parse_dp_assignments(lines, dp_start, dp_end)

    # Identify balance vars
    balance_vars = identify_balance_vars(var_decls, dp_assignments)
    report['balance_vars'] = sorted(balance_vars)

    # If nothing to do, skip
    if not balance_vars and not report['extends_migrated']:
        report['skipped_reason'] = 'No balance vars and no extends migration needed'
        return None, report

    # =========================================================================
    # BUILD NEW FILE CONTENT
    # =========================================================================
    new_lines = []

    # -- Everything before class declaration
    for i in range(class_start):
        new_lines.append(lines[i])

    # -- Class declaration (with extends migration)
    for i in range(class_start, class_end + 1):
        line = lines[i]
        if new_parent:
            line = line.replace(f'extends {parent_class}', f'extends {new_parent}')
        new_lines.append(line)

    # -- Content between class decl and defaultproperties
    # Add 'config' keyword to balance var declarations
    for i in range(class_end + 1, dp_start):
        line = lines[i]
        stripped = line.strip()

        if stripped.startswith('var ') and not stripped.startswith('var config'):
            line_has_balance = any(
                vd['line_idx'] == i and vd['name'] in balance_vars
                for vd in var_decls
            )
            if line_has_balance:
                line = line.replace('var ', 'var config ', 1)

        new_lines.append(line)

    # -- Insert MODEVERSION + UpdateConfig after last var, before first function
    if balance_vars:
        report['has_update_config'] = True

        # Find insertion point: after last 'var' line in new_lines
        insert_idx = len(new_lines)
        for idx in range(len(new_lines) - 1, -1, -1):
            if new_lines[idx].strip().startswith('var '):
                insert_idx = idx + 1
                break

        # Detect indentation from existing vars
        indent = ''
        for vd in var_decls:
            vl = lines[vd['line_idx']]
            indent = vl[:len(vl) - len(vl.lstrip())]
            break

        # Build insert block: MODEVERSION var + blank + UpdateConfig function + blank
        insert_block = [
            indent + 'var config int MODEVERSION;',
            '',
        ]
        insert_block.extend(build_update_config(balance_vars, dp_assignments))
        insert_block.append('')

        for j, bl in enumerate(insert_block):
            new_lines.insert(insert_idx + j, bl)

    # -- Defaultproperties (remove balance var assignments, keep everything else)
    balance_dp_lines = {a['line_idx'] for a in dp_assignments if a['base_name'] in balance_vars}

    for i in range(dp_start, dp_end + 1):
        if i not in balance_dp_lines:
            new_lines.append(lines[i])

    # -- Anything after defaultproperties
    for i in range(dp_end + 1, len(lines)):
        new_lines.append(lines[i])

    return '\n'.join(new_lines), report


# =============================================================================
# BASE CLASS UPDATES
# =============================================================================

def update_base_class(filepath, dry_run=True):
    """Add config(ZedternalUnlimited_Balance) to DKUpgrade_Perk.uc or DKUpgrade_Skill.uc"""
    with open(filepath, 'r', encoding='utf-8-sig') as f:
        content = f.read()

    if f'config({INI_NAME})' in content:
        return None, 'Already has config specifier'

    lines = content.split('\n')
    result = parse_class_declaration(lines)
    if result is None:
        return None, 'Could not parse class declaration'

    class_name, parent_class, class_start, class_end, class_text = result

    # Insert config specifier before the semicolon on the last declaration line
    for i in range(class_start, class_end + 1):
        if ';' in lines[i]:
            lines[i] = lines[i].replace(';', f'\n\tconfig({INI_NAME});', 1)
            break

    return '\n'.join(lines), 'Updated'


# =============================================================================
# LOADER GENERATION
# =============================================================================

def generate_loader(perk_classes, skill_classes):
    """Generate DKConfig_BalanceLoader.uc"""
    lines = []
    lines.append('// Auto-generated by DK_BalanceConfigMigration.py')
    lines.append(f'// Generated: {datetime.now().strftime("%Y-%m-%d %H:%M:%S")}')
    lines.append('//')
    lines.append('// Loads all DK perk/skill balance configs on server start.')
    lines.append('// Call DKConfig_BalanceLoader.static.LoadAllBalanceConfigs()')
    lines.append('// from DKGameInfo_Endless.InitGame().')
    lines.append('class DKConfig_BalanceLoader extends Object;')
    lines.append('')
    lines.append('static function LoadAllBalanceConfigs()')
    lines.append('{')

    if perk_classes:
        lines.append('\t// === DK Perks ===')
        for cls in sorted(perk_classes):
            lines.append(f"\tclass'ZedternalRBPerkpackage.{cls}'.static.UpdateConfig();")
        lines.append('')

    if skill_classes:
        lines.append('\t// === DK Skills ===')
        for cls in sorted(skill_classes):
            lines.append(f"\tclass'ZedternalRBPerkpackage.{cls}'.static.UpdateConfig();")

    lines.append('}')
    lines.append('')
    lines.append('defaultproperties')
    lines.append('{')
    lines.append('\tName="Default__DKConfig_BalanceLoader"')
    lines.append('}')
    lines.append('')

    return '\n'.join(lines)


# =============================================================================
# MAIN
# =============================================================================

def main():
    dry_run = '--apply' not in sys.argv
    no_backup = '--no-backup' in sys.argv

    if dry_run:
        print("=" * 70)
        print("DRY RUN MODE - No files will be modified")
        print("Run with --apply to make changes")
        print("=" * 70)
    else:
        print("=" * 70)
        print("APPLY MODE - Files will be modified!")
        if not no_backup:
            print("Backups will be created in _backup_pre_config/")
        print("=" * 70)

    if not os.path.isdir(CLASSES_DIR):
        print(f"ERROR: Classes directory not found: {CLASSES_DIR}")
        sys.exit(1)

    # Collect files
    perk_files = []
    skill_files = []
    for fn in sorted(os.listdir(CLASSES_DIR)):
        if not fn.endswith('.uc'):
            continue
        if '_Helper' in fn:
            continue
        if fn.startswith('DKUpgrade_Perk_') and fn != 'DKUpgrade_Perk.uc':
            perk_files.append(fn)
        elif fn.startswith('DKUpgrade_Skill_') and fn != 'DKUpgrade_Skill.uc':
            skill_files.append(fn)

    print(f"\nFound {len(perk_files)} DK perk files")
    print(f"Found {len(skill_files)} DK skill files")
    print(f"Total: {len(perk_files) + len(skill_files)} files to process\n")

    # Create backup directory
    backup_dir = None
    if not dry_run and not no_backup:
        backup_dir = os.path.join(CLASSES_DIR, '_backup_pre_config')
        os.makedirs(backup_dir, exist_ok=True)

    # Process all files
    converted_perks = []
    converted_skills = []
    extends_only = []
    skipped = []
    migrated_extends = 0
    total_balance_vars = 0

    all_files = [(f, 'perk') for f in perk_files] + [(f, 'skill') for f in skill_files]

    for fn, ftype in all_files:
        filepath = os.path.join(CLASSES_DIR, fn)
        result, report = transform_file(filepath, dry_run)

        if result is None:
            skipped.append(report)
            continue

        if report['extends_migrated']:
            migrated_extends += 1
        total_balance_vars += len(report['balance_vars'])

        class_name = fn.replace('.uc', '')
        if report['has_update_config']:
            if ftype == 'perk':
                converted_perks.append(class_name)
            else:
                converted_skills.append(class_name)
        else:
            extends_only.append(class_name)

        if not dry_run:
            if backup_dir:
                shutil.copy2(filepath, os.path.join(backup_dir, fn))
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(result)
            tag = f"{len(report['balance_vars'])} balance vars" if report['balance_vars'] else "extends only"
            print(f"  [WROTE] {fn} ({tag})")
        else:
            parts = []
            if report['extends_migrated']:
                parts.append('extends->DK')
            if report['balance_vars']:
                parts.append(f"{len(report['balance_vars'])} vars")
            else:
                parts.append('extends only')
            print(f"  [WOULD] {fn} ({', '.join(parts)})")

    # Update base classes
    print("\n--- Base Classes ---")
    for base_fn in ['DKUpgrade_Perk.uc', 'DKUpgrade_Skill.uc']:
        base_path = os.path.join(CLASSES_DIR, base_fn)
        if os.path.exists(base_path):
            result, msg = update_base_class(base_path, dry_run)
            if result:
                if not dry_run:
                    if backup_dir:
                        shutil.copy2(base_path, os.path.join(backup_dir, base_fn))
                    with open(base_path, 'w', encoding='utf-8') as f:
                        f.write(result)
                    print(f"  [WROTE] {base_fn}: {msg}")
                else:
                    print(f"  [WOULD] {base_fn}: {msg}")
            else:
                print(f"  [SKIP]  {base_fn}: {msg}")

    # Generate loader
    print("\n--- Loader Class ---")
    loader_content = generate_loader(converted_perks, converted_skills)
    loader_path = os.path.join(CLASSES_DIR, 'DKConfig_BalanceLoader.uc')
    if not dry_run:
        with open(loader_path, 'w', encoding='utf-8') as f:
            f.write(loader_content)
        print(f"  [WROTE] DKConfig_BalanceLoader.uc ({len(converted_perks)} perks, {len(converted_skills)} skills)")
    else:
        print(f"  [WOULD] DKConfig_BalanceLoader.uc ({len(converted_perks)} perks, {len(converted_skills)} skills)")

    # Summary
    print("\n" + "=" * 70)
    print("SUMMARY")
    print("=" * 70)
    total_converted = len(converted_perks) + len(converted_skills)
    print(f"  Files with balance vars:  {total_converted}")
    print(f"    Perks:                  {len(converted_perks)}")
    print(f"    Skills:                 {len(converted_skills)}")
    print(f"  Extends-only migrations:  {len(extends_only)}")
    print(f"  Total extends migrated:   {migrated_extends} (WM -> DK)")
    print(f"  Total balance vars found: {total_balance_vars}")
    print(f"  Skipped (no changes):     {len(skipped)}")
    for s in skipped:
        print(f"    {s['file']}: {s['skipped_reason']}")
    print()

    if dry_run:
        print("This was a DRY RUN. Run with --apply to make changes.")
    else:
        print("Done! Changes applied.")
        print()
        print("NEXT STEPS:")
        print("  1. Add to DKGameInfo_Endless.InitGame() (after existing config loads):")
        print("       class'DKConfig_BalanceLoader'.static.LoadAllBalanceConfigs();")
        print("  2. Compile and test")
        print(f"  3. First server start will auto-generate KF{INI_NAME}.ini")
        print(f"  4. INI location: KFGame/Config/KF{INI_NAME}.ini")


if __name__ == '__main__':
    main()
