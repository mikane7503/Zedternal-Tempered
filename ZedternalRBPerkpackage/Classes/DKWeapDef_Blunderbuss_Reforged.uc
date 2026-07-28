class DKWeapDef_Blunderbuss_Reforged extends KFWeapDef_Blunderbuss
	abstract;

const DEFAULT_WEAPON_PATH = "KFGameContent.KFWeap_Pistol_Blunderbuss";

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
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_Pistol_Blunderbuss_Reforged"
	BuyPrice=5250
	AmmoPricePerMag=110
	Name="Default__DKWeapDef_Blunderbuss_Reforged"
}
