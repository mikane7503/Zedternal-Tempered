class ZTWeapDef_Remington1858_Reforged extends KFWeapDef_Remington1858 abstract;

const DEFAULT_WEAPON_PATH = "KFGameContent.KFWeap_Revolver_Rem1858";

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
	WeaponClassPath="ZedternalTempered.ZTWeap_Revolver_Rem1858_Reforged"
	BuyPrice=350
	AmmoPricePerMag=28
	Name="Default__ZTWeapDef_Remington1858_Reforged"
}
