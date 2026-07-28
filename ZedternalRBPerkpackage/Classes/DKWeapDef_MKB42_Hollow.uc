class DKWeapDef_MKB42_Hollow extends KFWeapDef_MKB42
	abstract;

static function string GetItemLocalization(string KeyName)
{
	if (KeyName ~= "ItemName")
		return "Dusk Repeater";
	else if (KeyName ~= "ItemDescription")
		return "An absence given form. Perfected through mastery.";
	else
		return "";
}

defaultproperties
{
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_AssaultRifle_MKB42_Hollow"
	BuyPrice=0
	Name="Default__DKWeapDef_MKB42_Hollow"
}
