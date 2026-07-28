class DKWeapDef_MedicSMG_Hollow extends KFWeapDef_MedicSMG
	abstract;

static function string GetItemLocalization(string KeyName)
{
	if (KeyName ~= "ItemName")
		return "Pulse Void";
	else if (KeyName ~= "ItemDescription")
		return "An absence given form. Perfected through mastery.";
	else
		return "";
}

defaultproperties
{
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_SMG_Medic_Hollow"
	BuyPrice=0
	Name="Default__DKWeapDef_MedicSMG_Hollow"
}
