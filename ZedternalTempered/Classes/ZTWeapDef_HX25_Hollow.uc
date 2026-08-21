class ZTWeapDef_HX25_Hollow extends KFWeapDef_HX25 abstract;

static function string GetItemLocalization(string KeyName)
{
	if (KeyName ~= "ItemName")
		return "Void Seed";
	else if (KeyName ~= "ItemDescription")
		return "An absence given form. Perfected through mastery.";
	else
		return "";
}

defaultproperties
{
	WeaponClassPath="ZedternalTempered.ZTWeap_GrenadeLauncher_HX25_Hollow"
	BuyPrice=0
	Name="Default__ZTWeapDef_HX25_Hollow"
}
