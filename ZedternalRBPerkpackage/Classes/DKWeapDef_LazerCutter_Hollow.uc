class DKWeapDef_LazerCutter_Hollow extends KFWeapDef_LazerCutter
	abstract;

static function string GetItemLocalization(string KeyName)
{
	if (KeyName ~= "ItemName")
		return "Rift Carver";
	else if (KeyName ~= "ItemDescription")
		return "An absence given form. Perfected through mastery.";
	else
		return "";
}

defaultproperties
{
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_AssaultRifle_LazerCutter_Hollow"
	BuyPrice=0
	Name="Default__DKWeapDef_LazerCutter_Hollow"
}
