class DKWeapDef_DoubleBarrel_Reforged extends KFWeapDef_DoubleBarrel
	abstract;

const DEFAULT_WEAPON_PATH = "KFGameContent.KFWeap_Shotgun_DoubleBarrel";

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
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_Shotgun_DoubleBarrel_Reforged"
	BuyPrice=2625
	AmmoPricePerMag=37
	Name="Default__DKWeapDef_DoubleBarrel_Reforged"
}
