class ZTWeapDef_FlareGun_Reforged extends KFWeapDef_FlareGun abstract;

const DEFAULT_WEAPON_PATH = "KFGameContent.KFWeap_Pistol_Flare";

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
	WeaponClassPath="ZedternalTempered.ZTWeap_Pistol_Flare_Reforged"
	BuyPrice=1138
	AmmoPricePerMag=37
	Name="Default__ZTWeapDef_FlareGun_Reforged"
}
