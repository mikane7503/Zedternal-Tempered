class DKWeapDef_FNFal_Hollow extends KFWeapDef_FNFal
	abstract;

static function string GetItemLocalization(string KeyName)
{
	if (KeyName ~= "ItemName")
		return "Absence Herald";
	else if (KeyName ~= "ItemDescription")
		return "An absence given form. Perfected through mastery.";
	else
		return "";
}

defaultproperties
{
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_AssaultRifle_FNFal_Hollow"
	BuyPrice=0
	Name="Default__DKWeapDef_FNFal_Hollow"
}
