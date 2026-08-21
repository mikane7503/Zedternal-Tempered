class ZTWeapDef_HK_UMP_Reforged extends KFWeapDef_HK_UMP abstract;

const DEFAULT_WEAPON_PATH = "KFGameContent.KFWeap_SMG_HK_UMP";

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
	WeaponClassPath="ZedternalTempered.ZTWeap_SMG_HK_UMP_Reforged"
	BuyPrice=4200
	AmmoPricePerMag=90
	Name="Default__ZTWeapDef_HK_UMP_Reforged"
}
