class DKWeapDef_G18_Hollow extends KFWeapDef_G18
	abstract;

static function string GetItemLocalization(string KeyName)
{
	if (KeyName ~= "ItemName")
		return "Marrow Chatter";
	else if (KeyName ~= "ItemDescription")
		return "An absence given form. Perfected through mastery.";
	else
		return "";
}

defaultproperties
{
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_SMG_G18_Hollow"
	BuyPrice=0
	Name="Default__DKWeapDef_G18_Hollow"
}
