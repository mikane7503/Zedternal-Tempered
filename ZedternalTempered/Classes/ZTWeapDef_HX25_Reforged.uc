class ZTWeapDef_HX25_Reforged extends KFWeapDef_HX25 abstract;

const DEFAULT_WEAPON_PATH = "KFGameContent.KFWeap_GrenadeLauncher_HX25";

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
	WeaponClassPath="ZedternalTempered.ZTWeap_GrenadeLauncher_HX25_Reforged"
	BuyPrice=1050
	AmmoPricePerMag=26
	Name="Default__ZTWeapDef_HX25_Reforged"
}
