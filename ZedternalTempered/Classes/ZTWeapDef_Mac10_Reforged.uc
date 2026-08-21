class ZTWeapDef_Mac10_Reforged extends KFWeapDef_Mac10 abstract;

const DEFAULT_WEAPON_PATH = "KFGameContent.KFWeap_SMG_Mac10";

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
	WeaponClassPath="ZedternalTempered.ZTWeap_SMG_Mac10_Reforged"
	BuyPrice=3150
	AmmoPricePerMag=82
	Name="Default__ZTWeapDef_Mac10_Reforged"
}
