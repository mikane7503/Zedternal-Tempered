class DKWeapDef_MB500_Hollow extends KFWeapDef_MB500
	abstract;

static function string GetItemLocalization(string KeyName)
{
	if (KeyName ~= "ItemName")
		return "Throat of Ash";
	else if (KeyName ~= "ItemDescription")
		return "An absence given form. Perfected through mastery.";
	else
		return "";
}

defaultproperties
{
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_Shotgun_MB500_Hollow"
	BuyPrice=0
	Name="Default__DKWeapDef_MB500_Hollow"
}
