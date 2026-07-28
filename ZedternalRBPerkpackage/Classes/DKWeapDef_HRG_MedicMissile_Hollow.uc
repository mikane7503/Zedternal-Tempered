class DKWeapDef_HRG_MedicMissile_Hollow extends KFWeapDef_HRG_MedicMissile
	abstract;

static function string GetItemLocalization(string KeyName)
{
	if (KeyName ~= "ItemName")
		return "Marrow Seeking";
	else if (KeyName ~= "ItemDescription")
		return "An absence given form. Perfected through mastery.";
	else
		return "";
}

defaultproperties
{
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_HRG_MedicMissile_Hollow"
	BuyPrice=0
	Name="Default__DKWeapDef_HRG_MedicMissile_Hollow"
}
