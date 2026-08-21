class ZTWeapDef_M32_Reforged extends KFWeapDef_M32 abstract;

const DEFAULT_WEAPON_PATH = "KFGameContent.KFWeap_GrenadeLauncher_M32";

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
	WeaponClassPath="ZedternalTempered.ZTWeap_GrenadeLauncher_M32_Reforged"
	BuyPrice=7000
	AmmoPricePerMag=188
	Name="Default__ZTWeapDef_M32_Reforged"
}
