class DKWeapDef_MedicPistol_Hollow extends KFWeapDef_MedicPistol
	abstract;

static function string GetItemLocalization(string KeyName)
{
	if (KeyName ~= "ItemName")
		return "Veinwhisper";
	else if (KeyName ~= "ItemDescription")
		return "An absence given form. Perfected through mastery.";
	else
		return "";
}

defaultproperties
{
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_Pistol_Medic_Hollow"
	BuyPrice=0
	Name="Default__DKWeapDef_MedicPistol_Hollow"
}
