class ZTWeapDef_MedicBat_Reforged extends KFWeapDef_MedicBat abstract;

const DEFAULT_WEAPON_PATH = "KFGameContent.KFWeap_Blunt_MedicBat";

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
	WeaponClassPath="ZedternalTempered.ZTWeap_Blunt_MedicBat_Reforged"
	BuyPrice=4200
	AmmoPricePerMag=210
	Name="Default__ZTWeapDef_MedicBat_Reforged"
}
