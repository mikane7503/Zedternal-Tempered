class DKWeapDef_Pistol_G18C_Hollow extends KFWeapDef_Pistol_G18C
	abstract;

static function string GetItemLocalization(string KeyName)
{
	if (KeyName ~= "ItemName")
		return "Fracture";
	else if (KeyName ~= "ItemDescription")
		return "An absence given form. Perfected through mastery.";
	else
		return "";
}

defaultproperties
{
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_Pistol_G18C_Hollow"
	BuyPrice=0
	Name="Default__DKWeapDef_Pistol_G18C_Hollow"
}
