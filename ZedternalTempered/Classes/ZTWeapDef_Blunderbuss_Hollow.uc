class ZTWeapDef_Blunderbuss_Hollow extends KFWeapDef_Blunderbuss abstract;

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
	WeaponClassPath="ZedternalTempered.ZTWeap_Pistol_Blunderbuss_Hollow"
	BuyPrice=0
	Name="Default__ZTWeapDef_Blunderbuss_Hollow"
}
