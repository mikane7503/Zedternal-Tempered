class ZTWeapDef_M32_Hollow extends KFWeapDef_M32 abstract;

static function string GetItemLocalization(string KeyName)
{
	if (KeyName ~= "ItemName")
		return "Sixfold Maw";
	else if (KeyName ~= "ItemDescription")
		return "An absence given form. Perfected through mastery.";
	else
		return "";
}

defaultproperties
{
	WeaponClassPath="ZedternalTempered.ZTWeap_GrenadeLauncher_M32_Hollow"
	BuyPrice=0
	Name="Default__ZTWeapDef_M32_Hollow"
}
