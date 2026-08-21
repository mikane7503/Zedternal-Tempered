class ZTWeapDef_Pulverizer_Reforged extends KFWeapDef_Pulverizer abstract;

const DEFAULT_WEAPON_PATH = "KFGameContent.KFWeap_Blunt_Pulverizer";

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
	WeaponClassPath="ZedternalTempered.ZTWeap_Blunt_Pulverizer_Reforged"
	BuyPrice=4550
	AmmoPricePerMag=238
	Name="Default__ZTWeapDef_Pulverizer_Reforged"
}
