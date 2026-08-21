#!/usr/bin/env python3
"""Synchronize UnrealScript config seed values from the shipped INI files.

The generated assignments are placed inside the final MODEVERSION-gated part
of each UpdateConfig/InitializeConfig function.  They therefore affect fresh
config generation and version migration, but do not overwrite an administrator's
INI edits on every server start.

By default this script performs a dry run.  Pass --apply to write changes.
"""

from __future__ import annotations

import argparse
import re
from collections import OrderedDict
from dataclasses import dataclass
from pathlib import Path


BEGIN_MARKER = "// BEGIN TEMPERED INI DEFAULTS (generated; do not edit by hand)"
END_MARKER = "// END TEMPERED INI DEFAULTS"
NUMBER_RE = re.compile(r"^[+-]?(?:\d+(?:\.\d*)?|\.\d+)(?:[eE][+-]?\d+)?$")
INACTIVE_SECTION_PREFIXES = (
    # Weapon-wrapper swapping is intentionally disabled in DKConfig_WrapperSwap.
    # The live, INI-editable replacements are the DKWeaponUpg_* classes.
    "DKWrapper_Weapon_",
)


@dataclass
class IniSection:
    ini_path: Path
    package: str
    class_name: str
    values: OrderedDict[str, list[str]]


def strip_inline_comment(value: str) -> str:
    """Remove an INI ;/# comment only when it is outside a quoted string."""
    quoted = False
    escaped = False
    for index, char in enumerate(value):
        if escaped:
            escaped = False
            continue
        if char == "\\" and quoted:
            escaped = True
            continue
        if char == '"':
            quoted = not quoted
            continue
        if not quoted and char in ";#" and (index == 0 or value[index - 1].isspace()):
            return value[:index].rstrip()
    return value.strip()


def split_top_level(value: str, separator: str = ",") -> list[str]:
    parts: list[str] = []
    start = 0
    depth = 0
    quoted = False
    escaped = False
    for index, char in enumerate(value):
        if escaped:
            escaped = False
            continue
        if char == "\\" and quoted:
            escaped = True
            continue
        if char == '"':
            quoted = not quoted
        elif not quoted:
            if char in "([<{":
                depth += 1
            elif char in ")]>}" and depth:
                depth -= 1
            elif char == separator and depth == 0:
                parts.append(value[start:index].strip())
                start = index + 1
    parts.append(value[start:].strip())
    return parts


def split_assignment(value: str) -> tuple[str, str] | None:
    quoted = False
    escaped = False
    depth = 0
    for index, char in enumerate(value):
        if escaped:
            escaped = False
            continue
        if char == "\\" and quoted:
            escaped = True
            continue
        if char == '"':
            quoted = not quoted
        elif not quoted:
            if char in "([<{":
                depth += 1
            elif char in ")]>}" and depth:
                depth -= 1
            elif char == "=" and depth == 0:
                return value[:index].strip(), value[index + 1 :].strip()
    return None


def parse_struct(value: str) -> OrderedDict[str, str]:
    value = value.strip()
    if not (value.startswith("(") and value.endswith(")")):
        raise ValueError(f"Not a struct value: {value}")
    fields: OrderedDict[str, str] = OrderedDict()
    for part in split_top_level(value[1:-1]):
        assignment = split_assignment(part)
        if assignment is None:
            raise ValueError(f"Malformed struct field: {part}")
        name, field_value = assignment
        fields[name] = field_value
    return fields


def raw_contains_numeric(value: str) -> bool:
    value = value.strip()
    if NUMBER_RE.match(value):
        return True
    if value.startswith("(") and value.endswith(")"):
        return any(raw_contains_numeric(item) for item in parse_struct(value).values())
    return False


def parse_ini_files(paths: list[Path]) -> list[IniSection]:
    sections: list[IniSection] = []
    for path in paths:
        current: IniSection | None = None
        text = path.read_text(encoding="utf-8-sig")
        for raw_line in text.splitlines():
            line = raw_line.strip()
            section_match = re.match(r"^\[([^.\]]+)\.([^\]]+)\]$", line)
            if section_match:
                current = IniSection(
                    ini_path=path,
                    package=section_match.group(1),
                    class_name=section_match.group(2),
                    values=OrderedDict(),
                )
                sections.append(current)
                continue
            if current is None or not line or line.startswith((";", "#")):
                continue
            assignment = split_assignment(line)
            if assignment is None:
                continue
            key, value = assignment
            if not re.match(r"^[A-Za-z_][A-Za-z0-9_]*$", key):
                continue
            current.values.setdefault(key, []).append(strip_inline_comment(value))
    return sections


def decode_source(data: bytes) -> tuple[str, str]:
    if data.startswith(b"\xff\xfe"):
        return data.decode("utf-16"), "utf-16"
    return data.decode("utf-8-sig"), "utf-8"


def find_matching_brace(text: str, open_index: int) -> int:
    depth = 0
    quoted = False
    escaped = False
    line_comment = False
    block_comment = False
    index = open_index
    while index < len(text):
        char = text[index]
        next_char = text[index + 1] if index + 1 < len(text) else ""
        if line_comment:
            if char in "\r\n":
                line_comment = False
            index += 1
            continue
        if block_comment:
            if char == "*" and next_char == "/":
                block_comment = False
                index += 2
            else:
                index += 1
            continue
        if escaped:
            escaped = False
            index += 1
            continue
        if char == "\\" and quoted:
            escaped = True
            index += 1
            continue
        if char == '"':
            quoted = not quoted
            index += 1
            continue
        if not quoted and char == "/" and next_char == "/":
            line_comment = True
            index += 2
            continue
        if not quoted and char == "/" and next_char == "*":
            block_comment = True
            index += 2
            continue
        if not quoted and char == "{":
            depth += 1
        elif not quoted and char == "}":
            depth -= 1
            if depth == 0:
                return index
        index += 1
    raise ValueError("Unmatched brace")


def normalize_type(value: str) -> str:
    return re.sub(r"\s+", "", value).lower()


def parse_var_declarations(text: str, config_only: bool) -> dict[str, str]:
    declarations: dict[str, str] = {}
    modifier = r"config\s+" if config_only else r"(?!config\b)"
    pattern = re.compile(
        rf"(?im)^\s*var\s+{modifier}(.+?)\s+([^;]+);\s*(?://.*)?$"
    )
    for match in pattern.finditer(text):
        type_name = match.group(1).strip()
        names = match.group(2)
        for name_part in split_top_level(names):
            name_match = re.match(r"([A-Za-z_][A-Za-z0-9_]*)", name_part.strip())
            if name_match:
                declarations[name_match.group(1).lower()] = type_name
    return declarations


def collect_struct_types(class_files: list[Path]) -> dict[str, dict[str, str]]:
    structs: dict[str, dict[str, str]] = {}
    for path in class_files:
        text, _ = decode_source(path.read_bytes())
        for match in re.finditer(r"(?im)^\s*struct\s+([A-Za-z_][A-Za-z0-9_]*)\b", text):
            brace = text.find("{", match.end())
            if brace < 0:
                continue
            try:
                end = find_matching_brace(text, brace)
            except ValueError:
                continue
            body = text[brace + 1 : end]
            structs[match.group(1).lower()] = parse_var_declarations(body, config_only=False)
    return structs


def is_array(type_name: str) -> bool:
    return normalize_type(type_name).startswith("array<")


def array_inner_type(type_name: str) -> str:
    match = re.match(r"(?is)\s*array\s*<\s*(.+?)\s*>\s*$", type_name)
    if not match:
        raise ValueError(f"Not an array type: {type_name}")
    return match.group(1).strip()


def is_numeric_type(type_name: str) -> bool:
    return normalize_type(type_name) in {"int", "float", "byte"}


def is_struct_type(type_name: str, structs: dict[str, dict[str, str]]) -> bool:
    return normalize_type(type_name) in structs


def has_numeric_struct_field(type_name: str, structs: dict[str, dict[str, str]]) -> bool:
    fields = structs.get(normalize_type(type_name), {})
    return any(is_numeric_type(field_type) for field_type in fields.values())


def escape_unreal_string(value: str) -> str:
    return value.replace("\\", "\\\\").replace('"', '\\"')


def unreal_value(raw: str, type_name: str | None) -> str:
    raw = raw.strip()
    normalized = normalize_type(type_name or "")
    if is_numeric_type(type_name or ""):
        if not NUMBER_RE.match(raw):
            raise ValueError(f"Expected numeric {type_name}, got {raw!r}")
        if normalized == "float":
            if not any(marker in raw.lower() for marker in (".", "e")):
                raw += ".0"
            return raw + ("f" if not raw.lower().endswith("f") else "")
        return raw
    if normalized == "bool":
        if raw.lower() not in {"true", "false"}:
            raise ValueError(f"Expected bool, got {raw!r}")
        return raw.title()
    if normalized == "string":
        if raw.startswith('"') and raw.endswith('"'):
            return raw
        return f'"{escape_unreal_string(raw)}"'
    if normalized == "name":
        if raw.startswith("'") and raw.endswith("'"):
            return raw
        return f"'{raw}'"
    if raw == "":
        return "None"
    return raw


def build_struct_assignments(
    target: str,
    raw: str,
    struct_type: str,
    structs: dict[str, dict[str, str]],
    include_all_fields: bool,
) -> list[str]:
    fields = parse_struct(raw)
    field_types = structs.get(normalize_type(struct_type), {})
    lines: list[str] = []
    for field_name, field_value in fields.items():
        field_type = field_types.get(field_name.lower())
        if field_type is None:
            raise ValueError(f"Unknown field {struct_type}.{field_name}")
        if is_array(field_type):
            inner = array_inner_type(field_type)
            if not is_numeric_type(inner):
                if include_all_fields:
                    raise ValueError(f"Unsupported nested array {struct_type}.{field_name}")
                continue
            value = field_value.strip()
            if not (value.startswith("(") and value.endswith(")")):
                raise ValueError(f"Expected array value for {struct_type}.{field_name}")
            items = split_top_level(value[1:-1]) if value[1:-1].strip() else []
            lines.append(f"default.{target}.{field_name}.Length = {len(items)};")
            for index, item in enumerate(items):
                lines.append(
                    f"default.{target}.{field_name}[{index}] = {unreal_value(item, inner)};"
                )
            continue
        if not include_all_fields and not is_numeric_type(field_type):
            continue
        lines.append(f"default.{target}.{field_name} = {unreal_value(field_value, field_type)};")
    return lines


def build_assignments(
    section: IniSection,
    var_types: dict[str, str],
    structs: dict[str, dict[str, str]],
) -> tuple[list[str], list[str], int]:
    lines: list[str] = []
    skipped: list[str] = []
    numeric_leaf_count = 0
    for key, raw_values in section.values.items():
        if key.lower() == "modeversion":
            continue
        type_name = var_types.get(key.lower())
        if type_name is None:
            if any(raw_contains_numeric(raw) for raw in raw_values):
                skipped.append(f"{key}: no var config declaration")
            continue
        if is_array(type_name):
            inner = array_inner_type(type_name)
            if is_numeric_type(inner):
                lines.append(f"default.{key}.Length = {len(raw_values)};")
                for index, raw in enumerate(raw_values):
                    lines.append(f"default.{key}[{index}] = {unreal_value(raw, inner)};")
                    numeric_leaf_count += 1
            elif is_struct_type(inner, structs) and has_numeric_struct_field(inner, structs):
                lines.append(f"default.{key}.Length = {len(raw_values)};")
                for index, raw in enumerate(raw_values):
                    generated = build_struct_assignments(
                        f"{key}[{index}]", raw, inner, structs, include_all_fields=True
                    )
                    lines.extend(generated)
                    numeric_leaf_count += sum(
                        1
                        for field, _ in parse_struct(raw).items()
                        if is_numeric_type(structs[normalize_type(inner)][field.lower()])
                    )
            continue
        if is_numeric_type(type_name):
            if len(raw_values) != 1:
                skipped.append(f"{key}: scalar has {len(raw_values)} INI values")
                continue
            lines.append(f"default.{key} = {unreal_value(raw_values[0], type_name)};")
            numeric_leaf_count += 1
            continue
        if is_struct_type(type_name, structs) and has_numeric_struct_field(type_name, structs):
            if len(raw_values) != 1:
                skipped.append(f"{key}: struct has {len(raw_values)} INI values")
                continue
            generated = build_struct_assignments(
                key, raw_values[0], type_name, structs, include_all_fields=False
            )
            lines.extend(generated)
            numeric_leaf_count += len(generated)
    return lines, skipped, numeric_leaf_count


def remove_generated_block(text: str) -> str:
    pattern = re.compile(
        rf"(?m)^([ \t]*){re.escape(BEGIN_MARKER)}\r?\n.*?^\1{re.escape(END_MARKER)}\r?\n?",
        re.DOTALL,
    )
    return pattern.sub("", text)


def insert_generated_block(text: str, assignments: list[str], newline: str) -> str:
    text = remove_generated_block(text)
    function_match = re.search(
        r"(?im)^\s*static\s+function\s+(?:UpdateConfig|InitializeConfig)\s*\([^)]*\)",
        text,
    )
    if function_match is None:
        raise ValueError("No UpdateConfig/InitializeConfig function")
    function_brace = text.find("{", function_match.end())
    if function_brace < 0:
        raise ValueError("Initializer has no opening brace")
    function_end = find_matching_brace(text, function_brace)
    body = text[function_brace + 1 : function_end]
    mode_matches = list(
        re.finditer(r"(?im)^([ \t]*)default\.MODEVERSION\s*=\s*[^;]+;", body)
    )
    if not mode_matches:
        raise ValueError("Initializer has no MODEVERSION assignment")
    insertion = function_brace + 1 + mode_matches[-1].start()
    indent = mode_matches[-1].group(1)
    block_lines = [indent + BEGIN_MARKER]
    block_lines.extend(indent + assignment for assignment in assignments)
    block_lines.append(indent + END_MARKER)
    block = newline.join(block_lines) + newline
    return text[:insertion] + block + text[insertion:]


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--apply", action="store_true", help="write synchronized source files")
    args = parser.parse_args()

    project_root = Path(__file__).resolve().parents[2]
    package_root = project_root / "ZedternalRBPerkpackage"
    source_roots = {
        "zedternalreborn": project_root / "Zedternal-Reborn-master" / "Classes",
        "zedternalrbperkpackage": package_root / "Classes",
    }
    ini_paths = sorted(package_root.glob("*.ini"))
    class_files = sorted(
        list(source_roots["zedternalreborn"].glob("*.uc"))
        + list(source_roots["zedternalrbperkpackage"].glob("*.uc"))
    )
    structs = collect_struct_types(class_files)
    sections = parse_ini_files(ini_paths)

    changed_files = 0
    generated_sections = 0
    numeric_leaves = 0
    missing_classes: list[str] = []
    inactive_sections: list[str] = []
    skipped_values: list[str] = []
    failures: list[str] = []

    for section in sections:
        source_root = source_roots.get(section.package.lower())
        if source_root is None:
            missing_classes.append(f"{section.package}.{section.class_name}: unknown package")
            continue
        source_path = source_root / f"{section.class_name}.uc"
        if not source_path.exists():
            qualified_name = f"{section.package}.{section.class_name}"
            if section.class_name.startswith(INACTIVE_SECTION_PREFIXES):
                inactive_sections.append(qualified_name)
            else:
                missing_classes.append(qualified_name)
            continue
        original_bytes = source_path.read_bytes()
        try:
            original_text, source_encoding = decode_source(original_bytes)
        except UnicodeDecodeError as error:
            failures.append(f"{source_path}: UTF-8 decode failed: {error}")
            continue
        var_types = parse_var_declarations(original_text, config_only=True)
        try:
            assignments, skipped, leaf_count = build_assignments(section, var_types, structs)
        except ValueError as error:
            failures.append(f"{section.package}.{section.class_name}: {error}")
            continue
        skipped_values.extend(
            f"{section.package}.{section.class_name}.{item}" for item in skipped
        )
        if not assignments:
            continue
        newline = "\r\n" if b"\r\n" in original_bytes else "\n"
        try:
            updated_text = insert_generated_block(original_text, assignments, newline)
        except ValueError as error:
            failures.append(f"{section.package}.{section.class_name}: {error}")
            continue
        updated_bytes = updated_text.encode(source_encoding)
        generated_sections += 1
        numeric_leaves += leaf_count
        if updated_bytes != original_bytes:
            changed_files += 1
            if args.apply:
                source_path.write_bytes(updated_bytes)

    mode = "APPLY" if args.apply else "DRY RUN"
    print(f"Mode: {mode}")
    print(f"INI files: {len(ini_paths)}")
    print(f"INI sections: {len(sections)}")
    print(f"Generated source sections: {generated_sections}")
    print(f"Numeric leaves synchronized: {numeric_leaves}")
    print(f"Source files changed: {changed_files}")
    print(f"Missing classes: {len(missing_classes)}")
    print(f"Skipped values: {len(skipped_values)}")
    print(f"Failures: {len(failures)}")
    if missing_classes:
        print("\nMissing classes:")
        for item in missing_classes:
            print(f"  {item}")
    if skipped_values:
        print("\nSkipped values:")
        for item in skipped_values:
            print(f"  {item}")
    if failures:
        print("\nFailures:")
        for item in failures:
            print(f"  {item}")
    return 1 if failures else 0


if __name__ == "__main__":
    raise SystemExit(main())
