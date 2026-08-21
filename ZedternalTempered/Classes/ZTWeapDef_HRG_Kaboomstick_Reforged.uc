class ZTWeapDef_HRG_Kaboomstick_Reforged extends KFWeapDef_HRG_Kaboomstick abstract;

const DEFAULT_WEAPON_PATH = "KFGameContent.KFWeap_Shotgun_HRG_Kaboomstick";

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
	WeaponClassPath="ZedternalTempered.ZTWeap_Shotgun_HRG_Kaboomstick_Reforged"
	BuyPrice=3850
	AmmoPricePerMag=42
	Name="Default__ZTWeapDef_HRG_Kaboomstick_Reforged"
}
