class DKWeapDef_MedicBat_Hollow extends KFWeapDef_MedicBat
	abstract;

static function string GetItemLocalization(string KeyName)
{
	if (KeyName ~= "ItemName")
		return "Marrow Severance";
	else if (KeyName ~= "ItemDescription")
		return "An absence given form. Perfected through mastery.";
	else
		return "";
}

defaultproperties
{
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_Blunt_MedicBat_Hollow"
	BuyPrice=0
	Name="Default__DKWeapDef_MedicBat_Hollow"
}
