class DKWeapDef_GravityImploder_Reforged extends KFWeapDef_GravityImploder
	abstract;

const DEFAULT_WEAPON_PATH = "KFGameContent.KFWeap_GravityImploder";

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
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_GravityImploder_Reforged"
	BuyPrice=7000
	AmmoPricePerMag=196
	Name="Default__DKWeapDef_GravityImploder_Reforged"
}
