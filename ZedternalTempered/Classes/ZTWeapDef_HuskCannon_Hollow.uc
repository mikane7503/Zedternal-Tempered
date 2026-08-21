class ZTWeapDef_HuskCannon_Hollow extends KFWeapDef_HuskCannon abstract;

static function string GetItemLocalization(string KeyName)
{
	if (KeyName ~= "ItemName")
		return "Ash Maw";
	else if (KeyName ~= "ItemDescription")
		return "An absence given form. Perfected through mastery.";
	else
		return "";
}

defaultproperties
{
	WeaponClassPath="ZedternalTempered.ZTWeap_HuskCannon_Hollow"
	BuyPrice=0
	Name="Default__ZTWeapDef_HuskCannon_Hollow"
}
