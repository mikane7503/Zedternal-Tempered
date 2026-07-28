class DKWeapDef_G36C_Hollow extends KFWeapDef_G36C
	abstract;

static function string GetItemLocalization(string KeyName)
{
	if (KeyName ~= "ItemName")
		return "Duskfall Echo";
	else if (KeyName ~= "ItemDescription")
		return "An absence given form. Perfected through mastery.";
	else
		return "";
}

defaultproperties
{
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_AssaultRifle_G36C_Hollow"
	BuyPrice=0
	Name="Default__DKWeapDef_G36C_Hollow"
}
