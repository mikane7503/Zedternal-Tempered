class DKWeapDef_HuskCannon_Hollow extends KFWeapDef_HuskCannon
	abstract;

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
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_HuskCannon_Hollow"
	BuyPrice=0
	Name="Default__DKWeapDef_HuskCannon_Hollow"
}
