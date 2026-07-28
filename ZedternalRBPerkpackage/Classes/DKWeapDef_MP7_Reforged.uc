class DKWeapDef_MP7_Reforged extends KFWeapDef_MP7
	abstract;

const DEFAULT_WEAPON_PATH = "KFGameContent.KFWeap_SMG_MP7";

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
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_SMG_MP7_Reforged"
	BuyPrice=700
	AmmoPricePerMag=40
	Name="Default__DKWeapDef_MP7_Reforged"
}
