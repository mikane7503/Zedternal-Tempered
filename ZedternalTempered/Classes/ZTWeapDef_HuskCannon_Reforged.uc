class ZTWeapDef_HuskCannon_Reforged extends KFWeapDef_HuskCannon abstract;

const DEFAULT_WEAPON_PATH = "KFGameContent.KFWeap_HuskCannon";

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
	WeaponClassPath="ZedternalTempered.ZTWeap_HuskCannon_Reforged"
	BuyPrice=5250
	AmmoPricePerMag=350
	Name="Default__ZTWeapDef_HuskCannon_Reforged"
}
