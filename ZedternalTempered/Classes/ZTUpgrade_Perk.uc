// Intermediate base class for all Zedternal Unlimited perk upgrades.
// Every perk deliberately uses one original icon at every level.
class ZTUpgrade_Perk extends WMUpgrade_Perk abstract;

// ===================================================================
// LOCALIZATION SUPPORT (smart-fallback pattern)
// ===================================================================
// When LocPackage and LocSection are non-empty in a leaf class's
// defaultproperties, GetUpgradeName / GetUpgradeDescription will try to
// look up translations from the standard UE3 native loc system:
//   File:    KFGame/Localization/<lang>/<LocPackage>.<langext>
//   Section: [LocSection]
//   Keys:    UpgradeName, PerkUpgradeDescription1, PerkUpgradeDescription2, ...
//
// On lookup miss (no .int installed, key absent, or wrong language file),
// falls back to the literal default.UpgradeName / default.upgradeDescription[N].
// This preserves the UpgradeName field as the English literal -- so players
// without the loc pack always see the hardcoded text, no breaking change.
//
// To enable on a leaf perk:
//   bShouldLocalize=True
//   LocPackage="ZedternalTempered"
//   LocSection="ZTUpgrade_Perk_<Name>"
//   UpgradeName="<English literal>"           (still required as fallback)
//   upgradeDescription(0..N)="<English ...>"  (still required as fallback)
// ===================================================================
var string LocPackage;
var string LocSection;

static function string GetUpgradeName()
{
	return class'ZTLocalizationHelper'.static.TryLocalize(default.LocPackage, default.LocSection, "UpgradeName", default.UpgradeName);
}

static function string GetUpgradeDescription(byte Line)
{
	local string Fallback;

	if (int(Line) < default.UpgradeDescription.length)
		Fallback = default.UpgradeDescription[Line];

	return class'ZTLocalizationHelper'.static.TryLocalize(default.LocPackage, default.LocSection, "PerkUpgradeDescription" $ (int(Line) + 1), Fallback);
}

static simulated function Texture2D GetUpgradeIcon(int index)
{
	return default.UpgradeIcon[0];
}

// Config-seed hook. Default no-op; leaf upgrades with config-driven balance
// values override it. Lets ZTConfig_BalanceLoader call UpdateConfig() uniformly
// on any DK perk class (including ones without their own seeder).
static function UpdateConfig();

defaultproperties
{
	Name="Default__ZTUpgrade_Perk"
}
