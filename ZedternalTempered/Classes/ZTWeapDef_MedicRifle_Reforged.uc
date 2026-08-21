class ZTWeapDef_MedicRifle_Reforged extends KFWeapDef_MedicRifle abstract;

const DEFAULT_WEAPON_PATH = "KFGameContent.KFWeap_AssaultRifle_Medic";

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
	WeaponClassPath="ZedternalTempered.ZTWeap_AssaultRifle_Medic_Reforged"
	BuyPrice=5250
	AmmoPricePerMag=112
	Name="Default__ZTWeapDef_MedicRifle_Reforged"
}
