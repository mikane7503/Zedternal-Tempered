class DKWeapDef_FreezeThrower_Reforged extends KFWeapDef_FreezeThrower
	abstract;

const DEFAULT_WEAPON_PATH = "KFGameContent.KFWeap_Ice_FreezeThrower";

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
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_Ice_FreezeThrower_Reforged"
	BuyPrice=3850
	AmmoPricePerMag=126
	Name="Default__DKWeapDef_FreezeThrower_Reforged"
}
