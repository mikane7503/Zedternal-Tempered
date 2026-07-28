class DKWeapDef_ElephantGun_Reforged extends KFWeapDef_ElephantGun
	abstract;

const DEFAULT_WEAPON_PATH = "KFGameContent.KFWeap_Shotgun_ElephantGun";

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
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_Shotgun_ElephantGun_Reforged"
	BuyPrice=5250
	AmmoPricePerMag=70
	Name="Default__DKWeapDef_ElephantGun_Reforged"
}
