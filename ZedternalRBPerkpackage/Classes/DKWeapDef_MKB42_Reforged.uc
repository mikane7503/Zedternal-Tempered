class DKWeapDef_MKB42_Reforged extends KFWeapDef_MKB42
	abstract;

const DEFAULT_WEAPON_PATH = "KFGameContent.KFWeap_AssaultRifle_MKB42";

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
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_AssaultRifle_MKB42_Reforged"
	BuyPrice=3850
	AmmoPricePerMag=140
	Name="Default__DKWeapDef_MKB42_Reforged"
}
