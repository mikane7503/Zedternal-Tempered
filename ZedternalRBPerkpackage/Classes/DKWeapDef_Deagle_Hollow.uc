class DKWeapDef_Deagle_Hollow extends KFWeapDef_Deagle
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
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_Pistol_Deagle_Hollow"
	BuyPrice=0
	Name="Default__DKWeapDef_Deagle_Hollow"
}
