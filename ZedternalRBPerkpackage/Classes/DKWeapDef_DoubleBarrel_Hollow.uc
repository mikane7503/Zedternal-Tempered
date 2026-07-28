class DKWeapDef_DoubleBarrel_Hollow extends KFWeapDef_DoubleBarrel
	abstract;

static function string GetItemLocalization(string KeyName)
{
	if (KeyName ~= "ItemName")
		return "Twin Maw";
	else if (KeyName ~= "ItemDescription")
		return "An absence given form. Perfected through mastery.";
	else
		return "";
}

defaultproperties
{
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_Shotgun_DoubleBarrel_Hollow"
	BuyPrice=0
	Name="Default__DKWeapDef_DoubleBarrel_Hollow"
}
