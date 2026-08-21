class ZTWeapDef_Seeker6_Hollow extends KFWeapDef_Seeker6 abstract;

static function string GetItemLocalization(string KeyName)
{
	if (KeyName ~= "ItemName")
		return "Sixfold Hunger";
	else if (KeyName ~= "ItemDescription")
		return "An absence given form. Perfected through mastery.";
	else
		return "";
}

defaultproperties
{
	WeaponClassPath="ZedternalTempered.ZTWeap_RocketLauncher_Seeker6_Hollow"
	BuyPrice=0
	Name="Default__ZTWeapDef_Seeker6_Hollow"
}
