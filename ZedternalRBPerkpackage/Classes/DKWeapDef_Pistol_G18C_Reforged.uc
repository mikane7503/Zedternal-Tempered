class DKWeapDef_Pistol_G18C_Reforged extends KFWeapDef_Pistol_G18C
	abstract;

const DEFAULT_WEAPON_PATH = "KFGameContent.KFWeap_Pistol_G18C";

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
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_Pistol_G18C_Reforged"
	BuyPrice=2625
	AmmoPricePerMag=107
	Name="Default__DKWeapDef_Pistol_G18C_Reforged"
}
