class ZTWeapDef_M79_Reforged extends KFWeapDef_M79 abstract;

const DEFAULT_WEAPON_PATH = "KFGameContent.KFWeap_GrenadeLauncher_M79";

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
	WeaponClassPath="ZedternalTempered.ZTWeap_GrenadeLauncher_M79_Reforged"
	BuyPrice=2275
	AmmoPricePerMag=37
	Name="Default__ZTWeapDef_M79_Reforged"
}
