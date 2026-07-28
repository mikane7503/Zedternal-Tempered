class DKWeapDef_HRGWinterbite_Reforged extends KFWeapDef_HRGWinterbite
	abstract;

const DEFAULT_WEAPON_PATH = "KFGameContent.KFWeap_Pistol_HRGWinterbite";

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
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_Pistol_HRGWinterbite_Reforged"
	BuyPrice=1138
	AmmoPricePerMag=37
	Name="Default__DKWeapDef_HRGWinterbite_Reforged"
}
