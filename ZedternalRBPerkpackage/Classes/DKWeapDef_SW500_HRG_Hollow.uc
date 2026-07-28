class DKWeapDef_SW500_HRG_Hollow extends KFWeapDef_SW500_HRG
	abstract;

static function string GetItemLocalization(string KeyName)
{
	if (KeyName ~= "ItemName")
		return "Hollow Fang";
	else if (KeyName ~= "ItemDescription")
		return "An absence given form. Perfected through mastery.";
	else
		return "";
}

defaultproperties
{
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_HRG_Revolver_Buckshot_Hollow"
	BuyPrice=0
	Name="Default__DKWeapDef_SW500_HRG_Hollow"
}
