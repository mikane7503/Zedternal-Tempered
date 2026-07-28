class DKWeapDef_Crossbow_Hollow extends KFWeapDef_Crossbow
	abstract;

static function string GetItemLocalization(string KeyName)
{
	if (KeyName ~= "ItemName")
		return "Marrow Bolt";
	else if (KeyName ~= "ItemDescription")
		return "An absence given form. Perfected through mastery.";
	else
		return "";
}

defaultproperties
{
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_Bow_Crossbow_Hollow"
	BuyPrice=0
	Name="Default__DKWeapDef_Crossbow_Hollow"
}
