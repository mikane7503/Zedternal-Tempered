class DKWeapDef_DeagleDual_Reforged extends KFWeapDef_DeagleDual
	abstract;

const DEFAULT_WEAPON_PATH = "KFGameContent.KFWeap_Pistol_DualDeagle";

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
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_Pistol_DualDeagle_Reforged"
	BuyPrice=3850
	AmmoPricePerMag=118
	Name="Default__DKWeapDef_DeagleDual_Reforged"
}
