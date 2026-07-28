class DKWeapDef_RPG7_Reforged extends KFWeapDef_RPG7
	abstract;

const DEFAULT_WEAPON_PATH = "KFGameContent.KFWeap_RocketLauncher_RPG7";

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
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_RocketLauncher_RPG7_Reforged"
	BuyPrice=5250
	AmmoPricePerMag=84
	Name="Default__DKWeapDef_RPG7_Reforged"
}
