class DKWeapDef_HZ12_Hollow extends KFWeapDef_HZ12
	abstract;

static function string GetItemLocalization(string KeyName)
{
	if (KeyName ~= "ItemName")
		return "Bone Swallow";
	else if (KeyName ~= "ItemDescription")
		return "An absence given form. Perfected through mastery.";
	else
		return "";
}

defaultproperties
{
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_Shotgun_HZ12_Hollow"
	BuyPrice=0
	Name="Default__DKWeapDef_HZ12_Hollow"
}
