class ZTWeapDef_MB500_Reforged extends KFWeapDef_MB500 abstract;

const DEFAULT_WEAPON_PATH = "KFGameContent.KFWeap_Shotgun_MB500";

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
	WeaponClassPath="ZedternalTempered.ZTWeap_Shotgun_MB500_Reforged"
	BuyPrice=700
	AmmoPricePerMag=84
	Name="Default__ZTWeapDef_MB500_Reforged"
}
