class DKWeapDef_CompoundBow_Hollow extends KFWeapDef_CompoundBow
	abstract;

static function string GetItemLocalization(string KeyName)
{
	if (KeyName ~= "ItemName")
		return "Silence Drawn";
	else if (KeyName ~= "ItemDescription")
		return "An absence given form. Perfected through mastery.";
	else
		return "";
}

defaultproperties
{
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_Bow_CompoundBow_Hollow"
	BuyPrice=0
	Name="Default__DKWeapDef_CompoundBow_Hollow"
}
