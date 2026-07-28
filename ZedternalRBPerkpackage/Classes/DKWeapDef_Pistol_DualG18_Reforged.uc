class DKWeapDef_Pistol_DualG18_Reforged extends KFWeapDef_Pistol_DualG18
	abstract;

const DEFAULT_WEAPON_PATH = "KFGameContent.KFWeap_Pistol_DualG18";

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
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_Pistol_DualG18_Reforged"
	BuyPrice=5250
	AmmoPricePerMag=213
	Name="Default__DKWeapDef_Pistol_DualG18_Reforged"
}
