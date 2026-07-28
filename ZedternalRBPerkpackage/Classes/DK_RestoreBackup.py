#!/usr/bin/env python3
"""Restore all .uc files from _backup_pre_config/ back to the Classes directory."""
import os
import shutil

CLASSES_DIR = r"C:\Users\Anwender\Documents\My Games\KillingFloor2\KFGame\Src\ZedternalRBPerkpackage\Classes"
BACKUP_DIR = os.path.join(CLASSES_DIR, '_backup_pre_config')

if not os.path.isdir(BACKUP_DIR):
    print(f"ERROR: Backup directory not found: {BACKUP_DIR}")
    exit(1)

count = 0
for fn in sorted(os.listdir(BACKUP_DIR)):
    if fn.endswith('.uc'):
        src = os.path.join(BACKUP_DIR, fn)
        dst = os.path.join(CLASSES_DIR, fn)
        shutil.copy2(src, dst)
        count += 1

print(f"Restored {count} files from backup.")
print("Also deleting DKConfig_BalanceLoader.uc if it exists...")

loader = os.path.join(CLASSES_DIR, 'DKConfig_BalanceLoader.uc')
if os.path.exists(loader):
    os.remove(loader)
    print("  Deleted DKConfig_BalanceLoader.uc")

ini_path = None
for root_candidate in [
    r"C:\Users\Anwender\Desktop\Fummelecke KF2 Server\KFGame\Config",
    os.path.expanduser(r"~\Documents\My Games\KillingFloor2\KFGame\Config"),
]:
    candidate = os.path.join(root_candidate, "KFZedternalUnlimited_Balance.ini")
    if os.path.exists(candidate):
        os.remove(candidate)
        print(f"  Deleted {candidate}")

print("\nDone! Now run: python DK_BalanceConfigMigration.py --apply")
