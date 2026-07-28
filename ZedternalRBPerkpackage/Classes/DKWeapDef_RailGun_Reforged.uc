class DKWeapDef_RailGun_Reforged extends KFWeapDef_RailGun
	abstract;

const DEFAULT_WEAPON_PATH = "KFGameContent.KFWeap_Rifle_RailGun";

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
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_Rifle_RailGun_Reforged"
	BuyPrice=5250
	AmmoPricePerMag=56
	Name="Default__DKWeapDef_RailGun_Reforged"
}
