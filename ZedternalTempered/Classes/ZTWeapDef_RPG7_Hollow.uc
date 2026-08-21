class ZTWeapDef_RPG7_Hollow extends KFWeapDef_RPG7 abstract;

static function string GetItemLocalization(string KeyName)
{
	if (KeyName ~= "ItemName")
		return "Rift Maw";
	else if (KeyName ~= "ItemDescription")
		return "An absence given form. Perfected through mastery.";
	else
		return "";
}

defaultproperties
{
	WeaponClassPath="ZedternalTempered.ZTWeap_RocketLauncher_RPG7_Hollow"
	BuyPrice=0
	Name="Default__ZTWeapDef_RPG7_Hollow"
}
