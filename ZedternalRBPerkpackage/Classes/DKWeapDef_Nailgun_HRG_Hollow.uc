class DKWeapDef_Nailgun_HRG_Hollow extends KFWeapDef_Nailgun_HRG
	abstract;

static function string GetItemLocalization(string KeyName)
{
	if (KeyName ~= "ItemName")
		return "Veil Suture";
	else if (KeyName ~= "ItemDescription")
		return "An absence given form. Perfected through mastery.";
	else
		return "";
}

defaultproperties
{
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_HRG_Nailgun_Hollow"
	BuyPrice=0
	Name="Default__DKWeapDef_Nailgun_HRG_Hollow"
}
