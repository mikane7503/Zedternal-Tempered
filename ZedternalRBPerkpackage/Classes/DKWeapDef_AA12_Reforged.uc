class DKWeapDef_AA12_Reforged extends KFWeapDef_AA12
	abstract;

const DEFAULT_WEAPON_PATH = "KFGameContent.KFWeap_Shotgun_AA12";

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
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_Shotgun_AA12_Reforged"
	BuyPrice=5250
	AmmoPricePerMag=230
	Name="Default__DKWeapDef_AA12_Reforged"
}
