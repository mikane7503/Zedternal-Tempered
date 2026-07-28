class DKWeapDef_Kriss_Reforged extends KFWeapDef_Kriss
	abstract;

const DEFAULT_WEAPON_PATH = "KFGameContent.KFWeap_SMG_Kriss";

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
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_SMG_Kriss_Reforged"
	BuyPrice=5250
	AmmoPricePerMag=87
	Name="Default__DKWeapDef_Kriss_Reforged"
}
