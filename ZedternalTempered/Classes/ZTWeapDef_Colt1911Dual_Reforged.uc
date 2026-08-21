class ZTWeapDef_Colt1911Dual_Reforged extends KFWeapDef_Colt1911Dual abstract;

const DEFAULT_WEAPON_PATH = "KFGameContent.KFWeap_Pistol_DualColt1911";

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
	WeaponClassPath="ZedternalTempered.ZTWeap_Pistol_DualColt1911_Reforged"
	BuyPrice=2275
	AmmoPricePerMag=73
	Name="Default__ZTWeapDef_Colt1911Dual_Reforged"
}
