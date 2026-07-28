class DKWeapDef_M14EBR_Reforged extends KFWeapDef_M14EBR
	abstract;

const DEFAULT_WEAPON_PATH = "KFGameContent.KFWeap_Rifle_M14EBR";

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
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_Rifle_M14EBR_Reforged"
	BuyPrice=3850
	AmmoPricePerMag=149
	Name="Default__DKWeapDef_M14EBR_Reforged"
}
