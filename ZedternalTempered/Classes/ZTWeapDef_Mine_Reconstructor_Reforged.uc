class ZTWeapDef_Mine_Reconstructor_Reforged extends KFWeapDef_Mine_Reconstructor abstract;

const DEFAULT_WEAPON_PATH = "KFGameContent.KFWeap_Mine_Reconstructor";

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
	WeaponClassPath="ZedternalTempered.ZTWeap_Mine_Reconstructor_Reforged"
	BuyPrice=4200
	AmmoPricePerMag=101
	Name="Default__ZTWeapDef_Mine_Reconstructor_Reforged"
}
