class DKWeapDef_HVStormCannon_Hollow extends KFWeapDef_HVStormCannon
	abstract;

static function string GetItemLocalization(string KeyName)
{
	if (KeyName ~= "ItemName")
		return "Rift Tempest";
	else if (KeyName ~= "ItemDescription")
		return "An absence given form. Perfected through mastery.";
	else
		return "";
}

defaultproperties
{
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_HVStormCannon_Hollow"
	BuyPrice=0
	Name="Default__DKWeapDef_HVStormCannon_Hollow"
}
