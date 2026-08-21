// ===================================================================
// ZTUpgrade_Weapon - Intermediate base class for all DK weapon upgrades.
//
// Provides:
//   1. Localization support via the smart-fallback pattern (mirrors
//      ZTUpgrade_Perk and ZTUpgrade_Skill).
//   2. (Future) Artwork switching parity with the perk/skill base classes.
//      Not implemented yet -- weapon upgrades currently have no legacy art.
//
// All DK weapon upgrade leaf classes (ZTUpgrade_Weapon_* and DKWeaponUpg_*)
// extend this instead of WMUpgrade_Weapon directly. This is a one-line
// change in each leaf's class declaration. Existing functionality is
// preserved -- WMUpgrade_Weapon behavior is fully inherited.
// ===================================================================
class ZTUpgrade_Weapon extends WMUpgrade_Weapon abstract;

// ===================================================================
// LOCALIZATION SUPPORT (smart-fallback pattern)
// ===================================================================
// When LocPackage and LocSection are non-empty in a leaf class's
// defaultproperties, GetUpgradeName / GetUpgradeDescription will try to
// look up translations from the standard UE3 native loc system:
//   File:    KFGame/Localization/<lang>/<LocPackage>.<langext>
//   Section: [LocSection]
//   Keys:    UpgradeName, WeaponUpgradeDescription
//
// On lookup miss (no .int installed, key absent, or wrong language file),
// falls back to the literal default.UpgradeName / default.upgradeDescription[0].
// This preserves the UpgradeName field as the English literal -- so players
// without the loc pack always see the hardcoded text, no breaking change.
//
// To enable on a leaf weapon upgrade:
//   bShouldLocalize=True
//   LocPackage="ZedternalTempered"
//   LocSection="ZTUpgrade_Weapon_<Name>"  (or "DKWeaponUpg_<Name>")
//   UpgradeName="<English literal>"            (still required as fallback)
//   upgradeDescription(0)="<English text>"     (still required as fallback)
// ===================================================================
var string LocPackage;
var string LocSection;

static function string GetUpgradeName()
{
	return class'ZTLocalizationHelper'.static.TryLocalize(default.LocPackage, default.LocSection, "UpgradeName", default.UpgradeName);
}

static function string GetUpgradeDescription()
{
	local string Fallback;

	if (default.UpgradeDescription.length > 0)
		Fallback = default.UpgradeDescription[0];

	return class'ZTLocalizationHelper'.static.TryLocalize(default.LocPackage, default.LocSection, "WeaponUpgradeDescription", Fallback);
}

defaultproperties
{
	Name="Default__ZTUpgrade_Weapon"
}
