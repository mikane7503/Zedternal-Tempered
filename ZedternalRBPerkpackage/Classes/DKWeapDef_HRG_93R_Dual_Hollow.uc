class DKWeapDef_HRG_93R_Dual_Hollow extends KFWeapDef_HRG_93R_Dual
	abstract;

static function string GetItemLocalization(string KeyName)
{
	if (KeyName ~= "ItemName")
		return "Twin Fracture";
	else if (KeyName ~= "ItemDescription")
		return "An absence given form. Perfected through mastery.";
	else
		return "";
}

defaultproperties
{
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_HRG_93R_Dual_Hollow"
	BuyPrice=0
	Name="Default__DKWeapDef_HRG_93R_Dual_Hollow"
}
