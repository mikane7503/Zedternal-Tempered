class ZTWeapDef_ZedMKIII_Reforged extends KFWeapDef_ZedMKIII abstract;

const DEFAULT_WEAPON_PATH = "KFGameContent.KFWeap_ZedMKIII";

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
	WeaponClassPath="ZedternalTempered.ZTWeap_ZedMKIII_Reforged"
	BuyPrice=7000
	AmmoPricePerMag=210
	Name="Default__ZTWeapDef_ZedMKIII_Reforged"
}
