class DKWeapDef_Pistol_DualG18_Hollow extends KFWeapDef_Pistol_DualG18
	abstract;

static function string GetItemLocalization(string KeyName)
{
	if (KeyName ~= "ItemName")
		return "Twin Fracture";
	else if (KeyName ~= "ItemDescription")
		return "An absence given form. Perfected through mastery.";
	else
		return "";
}

defaultproperties
{
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_Pistol_DualG18_Hollow"
	BuyPrice=0
	Name="Default__DKWeapDef_Pistol_DualG18_Hollow"
}
