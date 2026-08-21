class ZTWeapDef_SCAR_Reforged extends KFWeapDef_SCAR abstract;

const DEFAULT_WEAPON_PATH = "KFGameContent.KFWeap_AssaultRifle_SCAR";

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
	WeaponClassPath="ZedternalTempered.ZTWeap_AssaultRifle_SCAR_Reforged"
	BuyPrice=5250
	AmmoPricePerMag=79
	Name="Default__ZTWeapDef_SCAR_Reforged"
}
