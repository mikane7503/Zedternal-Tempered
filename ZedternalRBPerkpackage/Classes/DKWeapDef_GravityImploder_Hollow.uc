class DKWeapDef_GravityImploder_Hollow extends KFWeapDef_GravityImploder
	abstract;

static function string GetItemLocalization(string KeyName)
{
	if (KeyName ~= "ItemName")
		return "Rift Hunger";
	else if (KeyName ~= "ItemDescription")
		return "An absence given form. Perfected through mastery.";
	else
		return "";
}

defaultproperties
{
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_GravityImploder_Hollow"
	BuyPrice=0
	Name="Default__DKWeapDef_GravityImploder_Hollow"
}
