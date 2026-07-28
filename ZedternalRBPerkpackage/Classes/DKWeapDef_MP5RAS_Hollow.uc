class DKWeapDef_MP5RAS_Hollow extends KFWeapDef_MP5RAS
	abstract;

static function string GetItemLocalization(string KeyName)
{
	if (KeyName ~= "ItemName")
		return "Maw of Cinders";
	else if (KeyName ~= "ItemDescription")
		return "An absence given form. Perfected through mastery.";
	else
		return "";
}

defaultproperties
{
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_SMG_MP5RAS_Hollow"
	BuyPrice=0
	Name="Default__DKWeapDef_MP5RAS_Hollow"
}
