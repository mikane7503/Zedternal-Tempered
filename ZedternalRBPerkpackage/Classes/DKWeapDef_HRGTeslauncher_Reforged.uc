class DKWeapDef_HRGTeslauncher_Reforged extends KFWeapDef_HRGTeslauncher
	abstract;

const DEFAULT_WEAPON_PATH = "KFGameContent.KFWeap_AssaultRifle_HRGTeslauncher";

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
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_AssaultRifle_HRGTeslauncher_Reforged"
	BuyPrice=5250
	AmmoPricePerMag=174
	Name="Default__DKWeapDef_HRGTeslauncher_Reforged"
}
