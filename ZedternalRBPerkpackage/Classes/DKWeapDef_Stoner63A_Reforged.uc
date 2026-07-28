class DKWeapDef_Stoner63A_Reforged extends KFWeapDef_Stoner63A
	abstract;

const DEFAULT_WEAPON_PATH = "KFGameContent.KFWeap_LMG_Stoner63A";

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
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_LMG_Stoner63A_Reforged"
	BuyPrice=5250
	AmmoPricePerMag=196
	Name="Default__DKWeapDef_Stoner63A_Reforged"
}
