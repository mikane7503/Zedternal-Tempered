class DKWeapDef_Shotgun_S12_Hollow extends KFWeapDef_Shotgun_S12
	abstract;

static function string GetItemLocalization(string KeyName)
{
	if (KeyName ~= "ItemName")
		return "Swallowing Glass";
	else if (KeyName ~= "ItemDescription")
		return "An absence given form. Perfected through mastery.";
	else
		return "";
}

defaultproperties
{
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_Shotgun_S12_Hollow"
	BuyPrice=0
	Name="Default__DKWeapDef_Shotgun_S12_Hollow"
}
