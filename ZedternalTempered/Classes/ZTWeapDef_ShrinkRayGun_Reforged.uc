class ZTWeapDef_ShrinkRayGun_Reforged extends KFWeapDef_ShrinkRayGun abstract;

const DEFAULT_WEAPON_PATH = "KFGameContent.KFWeap_ShrinkRayGun";

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
	WeaponClassPath="ZedternalTempered.ZTWeap_ShrinkRayGun_Reforged"
	BuyPrice=3150
	AmmoPricePerMag=140
	Name="Default__ZTWeapDef_ShrinkRayGun_Reforged"
}
