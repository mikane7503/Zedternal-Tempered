class ZTWeapDef_ChiappaRhino_Reforged extends KFWeapDef_ChiappaRhino abstract;

const DEFAULT_WEAPON_PATH = "KFGameContent.KFWeap_Pistol_ChiappaRhino";

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
	WeaponClassPath="ZedternalTempered.ZTWeap_Pistol_ChiappaRhino_Reforged"
	BuyPrice=1925
	AmmoPricePerMag=48
	Name="Default__ZTWeapDef_ChiappaRhino_Reforged"
}
