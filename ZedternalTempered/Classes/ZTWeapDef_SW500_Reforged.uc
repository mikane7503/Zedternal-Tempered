class ZTWeapDef_SW500_Reforged extends KFWeapDef_SW500 abstract;

const DEFAULT_WEAPON_PATH = "KFGameContent.KFWeap_Revolver_SW500";

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
	WeaponClassPath="ZedternalTempered.ZTWeap_Revolver_SW500_Reforged"
	BuyPrice=2625
	AmmoPricePerMag=70
	Name="Default__ZTWeapDef_SW500_Reforged"
}
