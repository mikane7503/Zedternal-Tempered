class ZTWeapDef_SW500Dual_HRG_Reforged extends KFWeapDef_SW500Dual_HRG abstract;

const DEFAULT_WEAPON_PATH = "KFGameContent.KFWeap_HRG_Revolver_DualBuckshot";

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
	WeaponClassPath="ZedternalTempered.ZTWeap_HRG_Revolver_DualBuckshot_Reforged"
	BuyPrice=3850
	AmmoPricePerMag=118
	Name="Default__ZTWeapDef_SW500Dual_HRG_Reforged"
}
