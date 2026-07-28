class DKWeapDef_HRGScorcher_Reforged extends KFWeapDef_HRGScorcher
	abstract;

const DEFAULT_WEAPON_PATH = "KFGameContent.KFWeap_Pistol_HRGScorcher";

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
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_Pistol_HRGScorcher_Reforged"
	BuyPrice=3500
	AmmoPricePerMag=34
	Name="Default__DKWeapDef_HRGScorcher_Reforged"
}
