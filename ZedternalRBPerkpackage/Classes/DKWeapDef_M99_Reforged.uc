class DKWeapDef_M99_Reforged extends KFWeapDef_M99
	abstract;

const DEFAULT_WEAPON_PATH = "KFGameContent.KFWeap_Rifle_M99";

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
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_Rifle_M99_Reforged"
	BuyPrice=8750
	AmmoPricePerMag=107
	Name="Default__DKWeapDef_M99_Reforged"
}
