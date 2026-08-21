class ZTWeapDef_G18_Reforged extends KFWeapDef_G18 abstract;

const DEFAULT_WEAPON_PATH = "KFGameContent.KFWeap_SMG_G18";

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
	WeaponClassPath="ZedternalTempered.ZTWeap_SMG_G18_Reforged"
	BuyPrice=5250
	AmmoPricePerMag=62
	Name="Default__ZTWeapDef_G18_Reforged"
}
