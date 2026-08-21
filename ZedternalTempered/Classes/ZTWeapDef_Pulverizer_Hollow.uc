class ZTWeapDef_Pulverizer_Hollow extends KFWeapDef_Pulverizer abstract;

static function string GetItemLocalization(string KeyName)
{
	if (KeyName ~= "ItemName")
		return "Ossuary Maw";
	else if (KeyName ~= "ItemDescription")
		return "An absence given form. Perfected through mastery.";
	else
		return "";
}

defaultproperties
{
	WeaponClassPath="ZedternalTempered.ZTWeap_Blunt_Pulverizer_Hollow"
	BuyPrice=0
	Name="Default__ZTWeapDef_Pulverizer_Hollow"
}
