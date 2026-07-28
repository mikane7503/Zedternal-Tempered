class DKWeapDef_ThermiteBore_Hollow extends KFWeapDef_ThermiteBore
	abstract;

static function string GetItemLocalization(string KeyName)
{
	if (KeyName ~= "ItemName")
		return "Cinder Rift";
	else if (KeyName ~= "ItemDescription")
		return "An absence given form. Perfected through mastery.";
	else
		return "";
}

defaultproperties
{
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_RocketLauncher_ThermiteBore_Hollow"
	BuyPrice=0
	Name="Default__DKWeapDef_ThermiteBore_Hollow"
}
