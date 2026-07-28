class DKWeapDef_MedicShotgun_Hollow extends KFWeapDef_MedicShotgun
	abstract;

static function string GetItemLocalization(string KeyName)
{
	if (KeyName ~= "ItemName")
		return "Maw of Absence";
	else if (KeyName ~= "ItemDescription")
		return "An absence given form. Perfected through mastery.";
	else
		return "";
}

defaultproperties
{
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_Shotgun_Medic_Hollow"
	BuyPrice=0
	Name="Default__DKWeapDef_MedicShotgun_Hollow"
}
