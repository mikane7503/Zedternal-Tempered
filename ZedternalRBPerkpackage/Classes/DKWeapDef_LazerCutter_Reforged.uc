class DKWeapDef_LazerCutter_Reforged extends KFWeapDef_LazerCutter
	abstract;

const DEFAULT_WEAPON_PATH = "KFGameContent.KFWeap_AssaultRifle_LazerCutter";

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
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_AssaultRifle_LazerCutter_Reforged"
	BuyPrice=7000
	AmmoPricePerMag=236
	Name="Default__DKWeapDef_LazerCutter_Reforged"
}
