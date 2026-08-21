class ZTWeapDef_CompoundBow_Reforged extends KFWeapDef_CompoundBow abstract;

const DEFAULT_WEAPON_PATH = "KFGameContent.KFWeap_Bow_CompoundBow";

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
	WeaponClassPath="ZedternalTempered.ZTWeap_Bow_CompoundBow_Reforged"
	BuyPrice=7000
	AmmoPricePerMag=23
	Name="Default__ZTWeapDef_CompoundBow_Reforged"
}
