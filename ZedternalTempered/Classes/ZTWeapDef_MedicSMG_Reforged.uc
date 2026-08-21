class ZTWeapDef_MedicSMG_Reforged extends KFWeapDef_MedicSMG abstract;

const DEFAULT_WEAPON_PATH = "KFGameContent.KFWeap_SMG_Medic";

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
	WeaponClassPath="ZedternalTempered.ZTWeap_SMG_Medic_Reforged"
	BuyPrice=2275
	AmmoPricePerMag=54
	Name="Default__ZTWeapDef_MedicSMG_Reforged"
}
