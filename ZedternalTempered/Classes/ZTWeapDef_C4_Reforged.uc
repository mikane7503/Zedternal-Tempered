class ZTWeapDef_C4_Reforged extends KFWeapDef_C4 abstract;

const DEFAULT_WEAPON_PATH = "KFGameContent.KFWeap_Thrown_C4";

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
	WeaponClassPath="ZedternalTempered.ZTWeap_Thrown_C4_Reforged"
	BuyPrice=1050
	AmmoPricePerMag=70
	Name="Default__ZTWeapDef_C4_Reforged"
}
