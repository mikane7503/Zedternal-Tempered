class DKWeapDef_HRG_Energy_Hollow extends KFWeapDef_HRG_Energy
	abstract;

static function string GetItemLocalization(string KeyName)
{
	if (KeyName ~= "ItemName")
		return "Fracture Echo";
	else if (KeyName ~= "ItemDescription")
		return "An absence given form. Perfected through mastery.";
	else
		return "";
}

defaultproperties
{
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_HRG_Energy_Hollow"
	BuyPrice=0
	Name="Default__DKWeapDef_HRG_Energy_Hollow"
}
