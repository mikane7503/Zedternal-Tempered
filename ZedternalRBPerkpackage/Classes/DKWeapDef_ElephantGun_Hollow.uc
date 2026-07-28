class DKWeapDef_ElephantGun_Hollow extends KFWeapDef_ElephantGun
	abstract;

static function string GetItemLocalization(string KeyName)
{
	if (KeyName ~= "ItemName")
		return "Bone Aperture";
	else if (KeyName ~= "ItemDescription")
		return "An absence given form. Perfected through mastery.";
	else
		return "";
}

defaultproperties
{
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_Shotgun_ElephantGun_Hollow"
	BuyPrice=0
	Name="Default__DKWeapDef_ElephantGun_Hollow"
}
