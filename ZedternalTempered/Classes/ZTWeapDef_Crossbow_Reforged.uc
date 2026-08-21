class ZTWeapDef_Crossbow_Reforged extends KFWeapDef_Crossbow abstract;

const DEFAULT_WEAPON_PATH = "KFGameContent.KFWeap_Bow_Crossbow";

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
	WeaponClassPath="ZedternalTempered.ZTWeap_Bow_Crossbow_Reforged"
	BuyPrice=2275
	AmmoPricePerMag=16
	Name="Default__ZTWeapDef_Crossbow_Reforged"
}
