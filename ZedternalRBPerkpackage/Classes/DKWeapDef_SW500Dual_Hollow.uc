class DKWeapDef_SW500Dual_Hollow extends KFWeapDef_SW500Dual
	abstract;

static function string GetItemLocalization(string KeyName)
{
	if (KeyName ~= "ItemName")
		return "Twin Maw";
	else if (KeyName ~= "ItemDescription")
		return "An absence given form. Perfected through mastery.";
	else
		return "";
}

defaultproperties
{
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_Revolver_DualSW500_Hollow"
	BuyPrice=0
	Name="Default__DKWeapDef_SW500Dual_Hollow"
}
