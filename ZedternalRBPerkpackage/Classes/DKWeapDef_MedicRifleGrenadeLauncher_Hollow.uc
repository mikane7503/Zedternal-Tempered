class DKWeapDef_MedicRifleGrenadeLauncher_Hollow extends KFWeapDef_MedicRifleGrenadeLauncher
	abstract;

static function string GetItemLocalization(string KeyName)
{
	if (KeyName ~= "ItemName")
		return "Rift Injection";
	else if (KeyName ~= "ItemDescription")
		return "An absence given form. Perfected through mastery.";
	else
		return "";
}

defaultproperties
{
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_AssaultRifle_MedicRifleGrenadeLauncher_Hollow"
	BuyPrice=0
	Name="Default__DKWeapDef_MedicRifleGrenadeLauncher_Hollow"
}
