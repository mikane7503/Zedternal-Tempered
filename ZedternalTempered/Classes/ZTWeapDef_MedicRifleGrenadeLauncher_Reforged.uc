class ZTWeapDef_MedicRifleGrenadeLauncher_Reforged extends KFWeapDef_MedicRifleGrenadeLauncher abstract;

const DEFAULT_WEAPON_PATH = "KFGameContent.KFWeap_AssaultRifle_MedicRifleGrenadeLauncher";

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
	WeaponClassPath="ZedternalTempered.ZTWeap_AssaultRifle_MedicRifleGrenadeLauncher_Reforged"
	BuyPrice=7000
	AmmoPricePerMag=132
	Name="Default__ZTWeapDef_MedicRifleGrenadeLauncher_Reforged"
}
