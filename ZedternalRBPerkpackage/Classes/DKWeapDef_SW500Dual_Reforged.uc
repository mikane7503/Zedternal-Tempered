class DKWeapDef_SW500Dual_Reforged extends KFWeapDef_SW500Dual
	abstract;

const DEFAULT_WEAPON_PATH = "KFGameContent.KFWeap_Revolver_DualSW500";

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
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_Revolver_DualSW500_Reforged"
	BuyPrice=5250
	AmmoPricePerMag=140
	Name="Default__DKWeapDef_SW500Dual_Reforged"
}
