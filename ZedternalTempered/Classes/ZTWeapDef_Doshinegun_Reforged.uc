class ZTWeapDef_Doshinegun_Reforged extends KFWeapDef_Doshinegun abstract;

const DEFAULT_WEAPON_PATH = "KFGameContent.KFWeap_AssaultRifle_Doshinegun";

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
	WeaponClassPath="ZedternalTempered.ZTWeap_AssaultRifle_Doshinegun_Reforged"
	BuyPrice=1400
	Name="Default__ZTWeapDef_Doshinegun_Reforged"
}
