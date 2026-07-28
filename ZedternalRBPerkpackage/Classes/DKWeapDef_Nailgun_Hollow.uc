class DKWeapDef_Nailgun_Hollow extends KFWeapDef_Nailgun
	abstract;

static function string GetItemLocalization(string KeyName)
{
	if (KeyName ~= "ItemName")
		return "Iron Swallow";
	else if (KeyName ~= "ItemDescription")
		return "An absence given form. Perfected through mastery.";
	else
		return "";
}

defaultproperties
{
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_Shotgun_Nailgun_Hollow"
	BuyPrice=0
	Name="Default__DKWeapDef_Nailgun_Hollow"
}
