class DKWeapDef_CaulkBurn_Hollow extends KFWeapDef_CaulkBurn
	abstract;

static function string GetItemLocalization(string KeyName)
{
	if (KeyName ~= "ItemName")
		return "Immolation Maw";
	else if (KeyName ~= "ItemDescription")
		return "An absence given form. Perfected through mastery.";
	else
		return "";
}

defaultproperties
{
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_Flame_CaulkBurn_Hollow"
	BuyPrice=0
	Name="Default__DKWeapDef_CaulkBurn_Hollow"
}
