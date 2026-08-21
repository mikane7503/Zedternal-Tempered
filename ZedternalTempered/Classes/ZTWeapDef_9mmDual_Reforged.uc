class ZTWeapDef_9mmDual_Reforged extends KFWeapDef_9mmDual abstract;

const DEFAULT_WEAPON_PATH = "KFGameContent.KFWeap_Pistol_Dual9mm";

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
	WeaponClassPath="ZedternalTempered.ZTWeap_Pistol_Dual9mm_Reforged"
	BuyPrice=1050
	AmmoPricePerMag=68
	Name="Default__ZTWeapDef_9mmDual_Reforged"
}
