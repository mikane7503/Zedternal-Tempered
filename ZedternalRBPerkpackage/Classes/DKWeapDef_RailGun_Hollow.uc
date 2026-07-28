class DKWeapDef_RailGun_Hollow extends KFWeapDef_RailGun
	abstract;

static function string GetItemLocalization(string KeyName)
{
	if (KeyName ~= "ItemName")
		return "Absence Needle";
	else if (KeyName ~= "ItemDescription")
		return "An absence given form. Perfected through mastery.";
	else
		return "";
}

defaultproperties
{
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_Rifle_RailGun_Hollow"
	BuyPrice=0
	Name="Default__DKWeapDef_RailGun_Hollow"
}
