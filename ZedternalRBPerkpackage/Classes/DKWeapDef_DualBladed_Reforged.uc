class DKWeapDef_DualBladed_Reforged extends KFWeapDef_DualBladed
	abstract;

const DEFAULT_WEAPON_PATH = "KFGameContent.KFWeap_Pistol_DualBladed";

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
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_Pistol_DualBladed_Reforged"
	BuyPrice=4200
	AmmoPricePerMag=213
	Name="Default__DKWeapDef_DualBladed_Reforged"
}
