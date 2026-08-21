class ZTWeapDef_Nailgun_HRG_Reforged extends KFWeapDef_Nailgun_HRG abstract;

const DEFAULT_WEAPON_PATH = "KFGameContent.KFWeap_HRG_Nailgun";

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
	WeaponClassPath="ZedternalTempered.ZTWeap_HRG_Nailgun_Reforged"
	BuyPrice=3850
	AmmoPricePerMag=126
	Name="Default__ZTWeapDef_Nailgun_HRG_Reforged"
}
