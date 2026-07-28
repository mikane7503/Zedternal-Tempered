class DKWeapDef_Winchester1894_Ripper extends KFWeapDef_Winchester1894
	abstract;

const DEFAULT_WEAPON_PATH = "KFGameContent.KFWeap_Rifle_Winchester1894";

static function string GetItemLocalization(string KeyName)
{
	local array<string> Strings;
	local string Localization;

	ParseStringIntoArray(DEFAULT_WEAPON_PATH, Strings, ".", True);
	Localization = Localize(Strings[1], KeyName, Strings[0]);
	if (KeyName ~= "ItemName")
		return Chr(8471) @ Localization;
	else
		return Localization;
}

defaultproperties
{
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_Rifle_Winchester1894_Ripper"
	BuyPrice=800
	AmmoPricePerMag=120
	ImagePath="Texture2D'ZedternalRBPerkpackage_Resources.Weapons.UI_WeaponSelect_WinchesterRipper'"
	Name="Default__DKWeapDef_Winchester1894_Ripper"
}