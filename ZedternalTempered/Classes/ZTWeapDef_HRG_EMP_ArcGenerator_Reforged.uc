class ZTWeapDef_HRG_EMP_ArcGenerator_Reforged extends KFWeapDef_HRG_EMP_ArcGenerator abstract;

const DEFAULT_WEAPON_PATH = "KFGameContent.KFWeap_HRG_EMP_ArcGenerator";

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
	WeaponClassPath="ZedternalTempered.ZTWeap_HRG_EMP_ArcGenerator_Reforged"
	BuyPrice=5250
	AmmoPricePerMag=308
	Name="Default__ZTWeapDef_HRG_EMP_ArcGenerator_Reforged"
}
