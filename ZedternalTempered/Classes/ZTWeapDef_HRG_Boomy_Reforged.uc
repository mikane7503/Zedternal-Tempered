class ZTWeapDef_HRG_Boomy_Reforged extends KFWeapDef_HRG_Boomy abstract;

const DEFAULT_WEAPON_PATH = "KFGameContent.KFWeap_HRG_Boomy";

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
	WeaponClassPath="ZedternalTempered.ZTWeap_HRG_Boomy_Reforged"
	BuyPrice=2275
	AmmoPricePerMag=84
	Name="Default__ZTWeapDef_HRG_Boomy_Reforged"
}
