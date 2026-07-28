class DKWeapDef_MaceAndShield_Hollow extends KFWeapDef_MaceAndShield
	abstract;

static function string GetItemLocalization(string KeyName)
{
	if (KeyName ~= "ItemName")
		return "Warden's Absence";
	else if (KeyName ~= "ItemDescription")
		return "An absence given form. Perfected through mastery.";
	else
		return "";
}

defaultproperties
{
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_Blunt_MaceAndShield_Hollow"
	BuyPrice=0
	Name="Default__DKWeapDef_MaceAndShield_Hollow"
}
