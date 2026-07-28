class DKWeapDef_FlameThrower_Hollow extends KFWeapDef_FlameThrower
	abstract;

static function string GetItemLocalization(string KeyName)
{
	if (KeyName ~= "ItemName")
		return "Hollow Maw";
	else if (KeyName ~= "ItemDescription")
		return "An absence given form. Perfected through mastery.";
	else
		return "";
}

defaultproperties
{
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_Flame_Flamethrower_Hollow"
	BuyPrice=0
	Name="Default__DKWeapDef_FlameThrower_Hollow"
}
