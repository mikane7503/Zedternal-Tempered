class DKWeapDef_HRGIncendiaryRifle_Hollow extends KFWeapDef_HRGIncendiaryRifle
	abstract;

static function string GetItemLocalization(string KeyName)
{
	if (KeyName ~= "ItemName")
		return "Ash Vein";
	else if (KeyName ~= "ItemDescription")
		return "An absence given form. Perfected through mastery.";
	else
		return "";
}

defaultproperties
{
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_AssaultRifle_HRGIncendiaryRifle_Hollow"
	BuyPrice=0
	Name="Default__DKWeapDef_HRGIncendiaryRifle_Hollow"
}
