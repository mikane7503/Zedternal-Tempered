class ZTWeapDef_Rifle_FrostShotgunAxe_Reforged extends KFWeapDef_Rifle_FrostShotgunAxe abstract;

const DEFAULT_WEAPON_PATH = "KFGameContent.KFWeap_Rifle_FrostShotgunAxe";

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
	WeaponClassPath="ZedternalTempered.ZTWeap_Rifle_FrostShotgunAxe_Reforged"
	BuyPrice=4550
	AmmoPricePerMag=110
	Name="Default__ZTWeapDef_Rifle_FrostShotgunAxe_Reforged"
}
