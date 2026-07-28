class DKWeapDef_M4_Hollow extends KFWeapDef_M4
	abstract;

static function string GetItemLocalization(string KeyName)
{
	if (KeyName ~= "ItemName")
		return "Hollow Maw";
	else if (KeyName ~= "ItemDescription")
		return "An absence given form. Perfected through mastery.";
	else
		return "";
}

defaultproperties
{
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_Shotgun_M4_Hollow"
	BuyPrice=0
	Name="Default__DKWeapDef_M4_Hollow"
}
