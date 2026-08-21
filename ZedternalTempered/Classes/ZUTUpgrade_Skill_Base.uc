// Ascension skill base. Numeric Deluxe values are kept at exactly twice
// the Standard value; bAllowDeluxe blocks qualitative/disabled Deluxe rows.
class ZUTUpgrade_Skill_Base extends ZTUpgrade_Skill abstract;

var bool bAllowDeluxe;

// The imported skill defaults store their localization target as
// "Package.Section" in UpgradeName. Resolve that legacy convention here so
// the copied Ascension classes keep their Korean names and descriptions.
static function ResolveUpgradeLocalization(out string PackageName, out string SectionName)
{
	local int DotIndex;

	PackageName = default.LocPackage;
	SectionName = default.LocSection;
	if (PackageName != "" && SectionName != "")
		return;

	DotIndex = InStr(default.UpgradeName, ".");
	if (DotIndex > 0)
	{
		PackageName = Left(default.UpgradeName, DotIndex);
		SectionName = Mid(default.UpgradeName, DotIndex + 1);
	}
}

static function string GetUpgradeName()
{
	local string PackageName, SectionName;

	ResolveUpgradeLocalization(PackageName, SectionName);
	return class'ZTLocalizationHelper'.static.TryLocalize(
		PackageName, SectionName, "UpgradeName", default.UpgradeName);
}

static function string GetUpgradeDescription(bool bDeluxe)
{
	local string PackageName, SectionName, KeyName, Fallback;

	ResolveUpgradeLocalization(PackageName, SectionName);
	if (bDeluxe)
	{
		KeyName = "DeluxeSkillUpgradeDescription";
		if (default.UpgradeDescription.Length > 1)
			Fallback = default.UpgradeDescription[1];
	}
	else
	{
		KeyName = "StandardSkillUpgradeDescription";
		if (default.UpgradeDescription.Length > 0)
			Fallback = default.UpgradeDescription[0];
	}

	return class'ZTLocalizationHelper'.static.TryLocalize(
		PackageName, SectionName, KeyName, Fallback);
}

static function bool AllowsDeluxe() { return default.bAllowDeluxe; }
static function float DeluxeFloat(float StandardValue) { return StandardValue * 2.0f; }
static function int DeluxeInt(int StandardValue) { return StandardValue * 2; }
static function float ValueByLevel(float StandardValue, int upgLevel)
{
	return upgLevel > 1 ? DeluxeFloat(StandardValue) : StandardValue;
}
static function int IntValueByLevel(int StandardValue, int upgLevel)
{
	return upgLevel > 1 ? DeluxeInt(StandardValue) : StandardValue;
}

defaultproperties
{
	bAllowDeluxe=True
	Name="Default__ZUTUpgrade_Skill_Base"
}
