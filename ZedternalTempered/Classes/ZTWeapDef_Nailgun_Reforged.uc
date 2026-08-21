class ZTWeapDef_Nailgun_Reforged extends KFWeapDef_Nailgun abstract;

const DEFAULT_WEAPON_PATH = "KFGameContent.KFWeap_Shotgun_Nailgun";

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
	WeaponClassPath="ZedternalTempered.ZTWeap_Shotgun_Nailgun_Reforged"
	BuyPrice=2625
	AmmoPricePerMag=110
	Name="Default__ZTWeapDef_Nailgun_Reforged"
}
