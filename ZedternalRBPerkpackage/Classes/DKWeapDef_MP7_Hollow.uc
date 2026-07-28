class DKWeapDef_MP7_Hollow extends KFWeapDef_MP7
	abstract;

static function string GetItemLocalization(string KeyName)
{
	if (KeyName ~= "ItemName")
		return "Glass Flicker";
	else if (KeyName ~= "ItemDescription")
		return "An absence given form. Perfected through mastery.";
	else
		return "";
}

defaultproperties
{
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_SMG_MP7_Hollow"
	BuyPrice=0
	Name="Default__DKWeapDef_MP7_Hollow"
}
