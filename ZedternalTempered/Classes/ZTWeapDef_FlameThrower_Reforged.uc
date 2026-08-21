class ZTWeapDef_FlameThrower_Reforged extends KFWeapDef_FlameThrower abstract;

const DEFAULT_WEAPON_PATH = "KFGameContent.KFWeap_Flame_Flamethrower";

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
	WeaponClassPath="ZedternalTempered.ZTWeap_Flame_Flamethrower_Reforged"
	BuyPrice=4200
	AmmoPricePerMag=233
	Name="Default__ZTWeapDef_FlameThrower_Reforged"
}
