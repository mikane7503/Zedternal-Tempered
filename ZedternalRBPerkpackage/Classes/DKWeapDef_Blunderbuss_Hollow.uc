class DKWeapDef_Blunderbuss_Hollow extends KFWeapDef_Blunderbuss
	abstract;

static function string GetItemLocalization(string KeyName)
{
	if (KeyName ~= "ItemName")
		return "Hollowmaw";
	else if (KeyName ~= "ItemDescription")
		return "An absence given form. Perfected through mastery.";
	else
		return "";
}

defaultproperties
{
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_Pistol_Blunderbuss_Hollow"
	BuyPrice=0
	Name="Default__DKWeapDef_Blunderbuss_Hollow"
}
