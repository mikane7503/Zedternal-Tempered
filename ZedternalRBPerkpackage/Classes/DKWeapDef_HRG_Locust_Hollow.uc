class DKWeapDef_HRG_Locust_Hollow extends KFWeapDef_HRG_Locust
	abstract;

static function string GetItemLocalization(string KeyName)
{
	if (KeyName ~= "ItemName")
		return "Swarm Unfed";
	else if (KeyName ~= "ItemDescription")
		return "An absence given form. Perfected through mastery.";
	else
		return "";
}

defaultproperties
{
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_HRG_Locust_Hollow"
	BuyPrice=0
	Name="Default__DKWeapDef_HRG_Locust_Hollow"
}
