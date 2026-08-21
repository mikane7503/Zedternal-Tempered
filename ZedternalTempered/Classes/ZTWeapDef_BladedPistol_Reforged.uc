class ZTWeapDef_BladedPistol_Reforged extends KFWeapDef_BladedPistol abstract;

const DEFAULT_WEAPON_PATH = "KFGameContent.KFWeap_Pistol_Bladed";

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
	WeaponClassPath="ZedternalTempered.ZTWeap_Pistol_Bladed_Reforged"
	BuyPrice=2100
	AmmoPricePerMag=107
	Name="Default__ZTWeapDef_BladedPistol_Reforged"
}
