class ZTWeapDef_Bullpup_Reforged extends KFWeapDef_Bullpup abstract;

const DEFAULT_WEAPON_PATH = "KFGameContent.KFWeap_AssaultRifle_Bullpup";

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
	WeaponClassPath="ZedternalTempered.ZTWeap_AssaultRifle_Bullpup_Reforged"
	BuyPrice=2275
	AmmoPricePerMag=90
	Name="Default__ZTWeapDef_Bullpup_Reforged"
}
