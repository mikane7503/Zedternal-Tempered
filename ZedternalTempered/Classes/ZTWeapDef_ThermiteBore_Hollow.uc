class ZTWeapDef_ThermiteBore_Hollow extends KFWeapDef_ThermiteBore abstract;

static function string GetItemLocalization(string KeyName)
{
	if (KeyName ~= "ItemName")
		return "Cinder Rift";
	else if (KeyName ~= "ItemDescription")
		return "An absence given form. Perfected through mastery.";
	else
		return "";
}

defaultproperties
{
	WeaponClassPath="ZedternalTempered.ZTWeap_RocketLauncher_ThermiteBore_Hollow"
	BuyPrice=0
	Name="Default__ZTWeapDef_ThermiteBore_Hollow"
}
