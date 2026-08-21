class ZTWeapDef_HZ12_Reforged extends KFWeapDef_HZ12 abstract;

const DEFAULT_WEAPON_PATH = "KFGameContent.KFWeap_Shotgun_HZ12";

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
	WeaponClassPath="ZedternalTempered.ZTWeap_Shotgun_HZ12_Reforged"
	BuyPrice=2625
	AmmoPricePerMag=180
	Name="Default__ZTWeapDef_HZ12_Reforged"
}
