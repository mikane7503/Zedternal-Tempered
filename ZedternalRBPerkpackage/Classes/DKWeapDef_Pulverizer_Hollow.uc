class DKWeapDef_Pulverizer_Hollow extends KFWeapDef_Pulverizer
	abstract;

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
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_Blunt_Pulverizer_Hollow"
	BuyPrice=0
	Name="Default__DKWeapDef_Pulverizer_Hollow"
}
