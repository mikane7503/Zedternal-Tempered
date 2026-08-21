class ZTWeapDef_HRGWinterbiteDual_Reforged extends KFWeapDef_HRGWinterbiteDual abstract;

const DEFAULT_WEAPON_PATH = "KFGameContent.KFWeap_Pistol_DualHRGWinterbite";

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
	WeaponClassPath="ZedternalTempered.ZTWeap_Pistol_DualHRGWinterbite_Reforged"
	BuyPrice=2275
	AmmoPricePerMag=73
	Name="Default__ZTWeapDef_HRGWinterbiteDual_Reforged"
}
