class DKWeapDef_Healthrower_HRG_Hollow extends KFWeapDef_Healthrower_HRG
	abstract;

static function string GetItemLocalization(string KeyName)
{
	if (KeyName ~= "ItemName")
		return "Veil Marrow";
	else if (KeyName ~= "ItemDescription")
		return "An absence given form. Perfected through mastery.";
	else
		return "";
}

defaultproperties
{
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_HRG_Healthrower_Hollow"
	BuyPrice=0
	Name="Default__DKWeapDef_Healthrower_HRG_Hollow"
}
