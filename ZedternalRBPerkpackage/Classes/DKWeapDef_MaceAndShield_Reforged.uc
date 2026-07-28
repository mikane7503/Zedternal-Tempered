class DKWeapDef_MaceAndShield_Reforged extends KFWeapDef_MaceAndShield
	abstract;

const DEFAULT_WEAPON_PATH = "KFGameContent.KFWeap_Blunt_MaceAndShield";

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
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_Blunt_MaceAndShield_Reforged"
	BuyPrice=5600
	Name="Default__DKWeapDef_MaceAndShield_Reforged"
}
