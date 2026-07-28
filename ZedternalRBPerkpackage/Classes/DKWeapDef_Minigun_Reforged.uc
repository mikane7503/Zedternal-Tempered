class DKWeapDef_Minigun_Reforged extends KFWeapDef_Minigun
	abstract;

const DEFAULT_WEAPON_PATH = "KFGameContent.KFWeap_Minigun";

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
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_Minigun_Reforged"
	BuyPrice=7000
	AmmoPricePerMag=336
	Name="Default__DKWeapDef_Minigun_Reforged"
}
