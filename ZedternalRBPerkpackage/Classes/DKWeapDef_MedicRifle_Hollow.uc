class DKWeapDef_MedicRifle_Hollow extends KFWeapDef_MedicRifle
	abstract;

static function string GetItemLocalization(string KeyName)
{
	if (KeyName ~= "ItemName")
		return "Hollow Suture";
	else if (KeyName ~= "ItemDescription")
		return "An absence given form. Perfected through mastery.";
	else
		return "";
}

defaultproperties
{
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_AssaultRifle_Medic_Hollow"
	BuyPrice=0
	Name="Default__DKWeapDef_MedicRifle_Hollow"
}
