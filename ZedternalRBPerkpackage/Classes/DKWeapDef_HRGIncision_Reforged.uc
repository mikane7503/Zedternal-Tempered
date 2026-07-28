class DKWeapDef_HRGIncision_Reforged extends KFWeapDef_HRGIncision
	abstract;

const DEFAULT_WEAPON_PATH = "KFGameContent.KFWeap_Rifle_HRGIncision";

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
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_Rifle_HRGIncision_Reforged"
	BuyPrice=5250
	AmmoPricePerMag=40
	Name="Default__DKWeapDef_HRGIncision_Reforged"
}
