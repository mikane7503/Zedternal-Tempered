class ZTWeapDef_CenterfireMB464_Reforged extends KFWeapDef_CenterfireMB464 abstract;

const DEFAULT_WEAPON_PATH = "KFGameContent.KFWeap_Rifle_CenterfireMB464";

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
	WeaponClassPath="ZedternalTempered.ZTWeap_Rifle_CenterfireMB464_Reforged"
	BuyPrice=2275
	AmmoPricePerMag=154
	Name="Default__ZTWeapDef_CenterfireMB464_Reforged"
}
