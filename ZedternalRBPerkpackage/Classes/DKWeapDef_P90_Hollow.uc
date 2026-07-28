class DKWeapDef_P90_Hollow extends KFWeapDef_P90
	abstract;

static function string GetItemLocalization(string KeyName)
{
	if (KeyName ~= "ItemName")
		return "Riftseed Storm";
	else if (KeyName ~= "ItemDescription")
		return "An absence given form. Perfected through mastery.";
	else
		return "";
}

defaultproperties
{
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_SMG_P90_Hollow"
	BuyPrice=0
	Name="Default__DKWeapDef_P90_Hollow"
}
