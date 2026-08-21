class ZTWeapDef_Zweihander_Reforged extends KFWeapDef_Zweihander abstract;

const DEFAULT_WEAPON_PATH = "KFGameContent.KFWeap_Edged_Zweihander";

static function string GetItemLocalization(string KeyName)
{
	local array<string> Strings;
	local string Localization;

	ParseStringIntoArray(DEFAULT_WEAPON_PATH, Strings, ".", True);
	Localization = Localize(Strings[1], KeyName, Strings[0]);
	if (KeyName ~= "ItemName")
		return Chr(9733) @ Localization;
	else
		return Localization;
}

defaultproperties
{
	WeaponClassPath="ZedternalTempered.ZTWeap_Edged_Zweihander_Reforged"
	BuyPrice=4550
	Name="Default__ZTWeapDef_Zweihander_Reforged"
}
