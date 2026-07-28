class DKWeapDef_Hemogoblin_Hollow extends KFWeapDef_Hemogoblin
	abstract;

static function string GetItemLocalization(string KeyName)
{
	if (KeyName ~= "ItemName")
		return "Hollow Siphon";
	else if (KeyName ~= "ItemDescription")
		return "An absence given form. Perfected through mastery.";
	else
		return "";
}

defaultproperties
{
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_Rifle_Hemogoblin_Hollow"
	BuyPrice=0
	Name="Default__DKWeapDef_Hemogoblin_Hollow"
}
