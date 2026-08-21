// Intermediate base class for all Zedternal Unlimited skill upgrades.
// Adds artwork switching between original (AI-generated) and legacy (hand-made) icons.
//
// How it works:
//   - UpgradeIcon        = Original AI-generated artwork (unchanged, the default)
//   - LegacyUpgradeIcon  = Hand-made legacy artwork (added over time as new art is created)
//   - No changes needed to existing DK skill files beyond changing extends to ZTUpgrade_Skill
//   - If LegacyUpgradeIcon is empty, original artwork is always shown regardless of setting
//
// Example defaultproperties in a subclass:
//   // These stay exactly as they are (AI art):
//   UpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_MySkill'
//   UpgradeIcon(1)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_MySkill_Deluxe'
//   // Add these as you create the hand-made art:
//   LegacyUpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_MySkill_Legacy'
//   LegacyUpgradeIcon(1)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_MySkill_Legacy_Deluxe'
class ZTUpgrade_Skill extends WMUpgrade_Skill abstract;

// Hand-made legacy artwork icons
// Populated in subclass defaultproperties as new art is created
// When empty, GetUpgradeIcon always returns original artwork from UpgradeIcon
var array<Texture2D> LegacyUpgradeIcon;

// ===================================================================
// LOCALIZATION SUPPORT (smart-fallback pattern)
// ===================================================================
// When LocPackage and LocSection are non-empty in a leaf class's
// defaultproperties, GetUpgradeName / GetUpgradeDescription will try to
// look up translations from the standard UE3 native loc system:
//   File:    KFGame/Localization/<lang>/<LocPackage>.<langext>
//   Section: [LocSection]
//   Keys:    UpgradeName, StandardSkillUpgradeDescription, DeluxeSkillUpgradeDescription
//
// On lookup miss (no .int installed, key absent, or wrong language file),
// falls back to the literal default.UpgradeName / default.upgradeDescription[N].
// This preserves the UpgradeName field as the English literal -- so players
// without the loc pack always see the hardcoded text, no breaking change.
//
// To enable on a leaf skill:
//   bShouldLocalize=True
//   LocPackage="ZedternalTempered"
//   LocSection="ZTUpgrade_Skill_<Name>"
//   UpgradeName="<English literal>"           (still required as fallback)
//   upgradeDescription(0)="<Standard text>"   (still required as fallback)
//   upgradeDescription(1)="<Deluxe text>"     (still required as fallback)
// ===================================================================
var string LocPackage;
var string LocSection;

static function string GetUpgradeName()
{
	return class'ZTLocalizationHelper'.static.TryLocalize(default.LocPackage, default.LocSection, "UpgradeName", default.UpgradeName);
}

static function string GetUpgradeDescription(bool bDeluxe)
{
	local string KeyName, Fallback;

	if (bDeluxe)
	{
		KeyName = "DeluxeSkillUpgradeDescription";
		if (default.UpgradeDescription.length > 1)
			Fallback = default.UpgradeDescription[1];
	}
	else
	{
		KeyName = "StandardSkillUpgradeDescription";
		if (default.UpgradeDescription.length > 0)
			Fallback = default.UpgradeDescription[0];
	}

	return class'ZTLocalizationHelper'.static.TryLocalize(default.LocPackage, default.LocSection, KeyName, Fallback);
}

static simulated function Texture2D GetUpgradeIcon(int index)
{
	local byte ServerMode;
	local bool bUseLegacy;

	// Determine artwork preference
	// Server mode: 0=player choice, 1=force legacy (hand-made), 2=force original (AI)
	ServerMode = class'ZedternalTempered.ZTConfig_Artwork'.default.Artwork_ServerMode;

	if (ServerMode == 1)
		bUseLegacy = true;
	else if (ServerMode == 2)
		bUseLegacy = false;
	else
		bUseLegacy = class'ZedternalTempered.ZTConfig_LocalArtwork'.default.bUseLegacyArtwork;

	// Legacy (hand-made) artwork path - only if icons exist
	if (bUseLegacy && default.LegacyUpgradeIcon.length > 0)
	{
		if (index < 0)
			return default.LegacyUpgradeIcon[0];
		else if (index < default.LegacyUpgradeIcon.length)
			return default.LegacyUpgradeIcon[index];
		else
			return default.LegacyUpgradeIcon[default.LegacyUpgradeIcon.length - 1];
	}

	// Original (AI-generated) artwork path - the default
	if (index < 0)
		return default.UpgradeIcon[0];
	else if (index < default.UpgradeIcon.length)
		return default.UpgradeIcon[index];
	else
		return default.UpgradeIcon[default.UpgradeIcon.length - 1];
}

// Config-seed hook. Default no-op; leaf upgrades with config-driven balance
// values override it. Lets ZTConfig_BalanceLoader call UpdateConfig() uniformly
// on any DK skill class (including ones without their own seeder).
static function UpdateConfig();

defaultproperties
{
	Name="Default__ZTUpgrade_Skill"
}
