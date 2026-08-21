class ZTWeapDef_CaulkBurn_Reforged extends KFWeapDef_CaulkBurn abstract;

const DEFAULT_WEAPON_PATH = "KFGameContent.KFWeap_Flame_CaulkBurn";

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
	WeaponClassPath="ZedternalTempered.ZTWeap_Flame_CaulkBurn_Reforged"
	BuyPrice=700
	AmmoPricePerMag=56
	Name="Default__ZTWeapDef_CaulkBurn_Reforged"
}
