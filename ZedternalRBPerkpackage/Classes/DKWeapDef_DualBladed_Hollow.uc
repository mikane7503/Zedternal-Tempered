class DKWeapDef_DualBladed_Hollow extends KFWeapDef_DualBladed
	abstract;

static function string GetItemLocalization(string KeyName)
{
	if (KeyName ~= "ItemName")
		return "Mirror Fang";
	else if (KeyName ~= "ItemDescription")
		return "An absence given form. Perfected through mastery.";
	else
		return "";
}

defaultproperties
{
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_Pistol_DualBladed_Hollow"
	BuyPrice=0
	Name="Default__DKWeapDef_DualBladed_Hollow"
}
