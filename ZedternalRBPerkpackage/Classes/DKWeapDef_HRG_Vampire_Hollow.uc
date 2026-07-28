class DKWeapDef_HRG_Vampire_Hollow extends KFWeapDef_HRG_Vampire
	abstract;

static function string GetItemLocalization(string KeyName)
{
	if (KeyName ~= "ItemName")
		return "Thirst Hollowed";
	else if (KeyName ~= "ItemDescription")
		return "An absence given form. Perfected through mastery.";
	else
		return "";
}

defaultproperties
{
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_HRG_Vampire_Hollow"
	BuyPrice=0
	Name="Default__DKWeapDef_HRG_Vampire_Hollow"
}
