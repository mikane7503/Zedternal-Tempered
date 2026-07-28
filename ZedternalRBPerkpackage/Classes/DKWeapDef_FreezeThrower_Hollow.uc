class DKWeapDef_FreezeThrower_Hollow extends KFWeapDef_FreezeThrower
	abstract;

static function string GetItemLocalization(string KeyName)
{
	if (KeyName ~= "ItemName")
		return "Rime Maw";
	else if (KeyName ~= "ItemDescription")
		return "An absence given form. Perfected through mastery.";
	else
		return "";
}

defaultproperties
{
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_Ice_FreezeThrower_Hollow"
	BuyPrice=0
	Name="Default__DKWeapDef_FreezeThrower_Hollow"
}
