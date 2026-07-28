class DKWeapDef_Seeker6_Reforged extends KFWeapDef_Seeker6
	abstract;

const DEFAULT_WEAPON_PATH = "KFGameContent.KFWeap_RocketLauncher_Seeker6";

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
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_RocketLauncher_Seeker6_Reforged"
	BuyPrice=5250
	AmmoPricePerMag=154
	Name="Default__DKWeapDef_Seeker6_Reforged"
}
