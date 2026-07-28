class DKWeapDef_Bullpup_Hollow extends KFWeapDef_Bullpup
	abstract;

static function string GetItemLocalization(string KeyName)
{
	if (KeyName ~= "ItemName")
		return "Ashmarrow Sermon";
	else if (KeyName ~= "ItemDescription")
		return "An absence given form. Perfected through mastery.";
	else
		return "";
}

defaultproperties
{
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_AssaultRifle_Bullpup_Hollow"
	BuyPrice=0
	Name="Default__DKWeapDef_Bullpup_Hollow"
}
