class ZTWeapDef_Hemogoblin_Reforged extends KFWeapDef_Hemogoblin abstract;

const DEFAULT_WEAPON_PATH = "KFGameContent.KFWeap_Rifle_Hemogoblin";

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
	WeaponClassPath="ZedternalTempered.ZTWeap_Rifle_Hemogoblin_Reforged"
	BuyPrice=3850
	AmmoPricePerMag=84
	Name="Default__ZTWeapDef_Hemogoblin_Reforged"
}
