class ZTWeapDef_Deagle_Reforged extends KFWeapDef_Deagle abstract;

const DEFAULT_WEAPON_PATH = "KFGameContent.KFWeap_Pistol_Deagle";

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
	WeaponClassPath="ZedternalTempered.ZTWeap_Pistol_Deagle_Reforged"
	BuyPrice=1925
	AmmoPricePerMag=59
	Name="Default__ZTWeapDef_Deagle_Reforged"
}
