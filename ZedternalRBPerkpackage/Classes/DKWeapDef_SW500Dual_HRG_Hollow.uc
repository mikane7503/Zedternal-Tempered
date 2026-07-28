class DKWeapDef_SW500Dual_HRG_Hollow extends KFWeapDef_SW500Dual_HRG
	abstract;

static function string GetItemLocalization(string KeyName)
{
	if (KeyName ~= "ItemName")
		return "Paired Hollows";
	else if (KeyName ~= "ItemDescription")
		return "An absence given form. Perfected through mastery.";
	else
		return "";
}

defaultproperties
{
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_HRG_Revolver_DualBuckshot_Hollow"
	BuyPrice=0
	Name="Default__DKWeapDef_SW500Dual_HRG_Hollow"
}
