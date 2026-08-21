class ZTWeapDef_MedicShotgun_Reforged extends KFWeapDef_MedicShotgun abstract;

const DEFAULT_WEAPON_PATH = "KFGameContent.KFWeap_Shotgun_Medic";

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
	WeaponClassPath="ZedternalTempered.ZTWeap_Shotgun_Medic_Reforged"
	BuyPrice=3850
	AmmoPricePerMag=112
	Name="Default__ZTWeapDef_MedicShotgun_Reforged"
}
