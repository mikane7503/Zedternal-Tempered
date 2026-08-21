// Shared localization bridge for Tempered-owned wrappers of KF2's ten
// original perks. English remains embedded as the safe fallback while KOR
// and other languages can override each line from the Tempered package.
class ZTOriginalPerkLocalization extends Object;

static function string GetName(string SectionName, string Fallback)
{
	return class'ZTLocalizationHelper'.static.TryLocalize(
		"ZedternalTempered", SectionName, "UpgradeName", Fallback);
}

static function string GetDescription(string SectionName, byte Line, string Fallback)
{
	return class'ZTLocalizationHelper'.static.TryLocalize(
		"ZedternalTempered", SectionName,
		"PerkUpgradeDescription" $ string(int(Line) + 1), Fallback);
}

defaultproperties
{
	Name="Default__ZTOriginalPerkLocalization"
}
