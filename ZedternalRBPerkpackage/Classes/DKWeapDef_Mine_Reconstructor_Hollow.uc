class DKWeapDef_Mine_Reconstructor_Hollow extends KFWeapDef_Mine_Reconstructor
	abstract;

static function string GetItemLocalization(string KeyName)
{
	if (KeyName ~= "ItemName")
		return "Wither Seed";
	else if (KeyName ~= "ItemDescription")
		return "An absence given form. Perfected through mastery.";
	else
		return "";
}

defaultproperties
{
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_Mine_Reconstructor_Hollow"
	BuyPrice=0
	Name="Default__DKWeapDef_Mine_Reconstructor_Hollow"
}
