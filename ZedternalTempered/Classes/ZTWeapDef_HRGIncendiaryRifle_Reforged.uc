class ZTWeapDef_HRGIncendiaryRifle_Reforged extends KFWeapDef_HRGIncendiaryRifle abstract;

const DEFAULT_WEAPON_PATH = "KFGameContent.KFWeap_AssaultRifle_HRGIncendiaryRifle";

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
	WeaponClassPath="ZedternalTempered.ZTWeap_AssaultRifle_HRGIncendiaryRifle_Reforged"
	BuyPrice=4200
	AmmoPricePerMag=84
	Name="Default__ZTWeapDef_HRGIncendiaryRifle_Reforged"
}
