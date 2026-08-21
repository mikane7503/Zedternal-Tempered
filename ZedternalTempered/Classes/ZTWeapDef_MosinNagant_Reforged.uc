class ZTWeapDef_MosinNagant_Reforged extends KFWeapDef_MosinNagant abstract;

const DEFAULT_WEAPON_PATH = "KFGameContent.KFWeap_Rifle_MosinNagant";

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
	WeaponClassPath="ZedternalTempered.ZTWeap_Rifle_MosinNagant_Reforged"
	BuyPrice=3850
	AmmoPricePerMag=118
	Name="Default__ZTWeapDef_MosinNagant_Reforged"
}
