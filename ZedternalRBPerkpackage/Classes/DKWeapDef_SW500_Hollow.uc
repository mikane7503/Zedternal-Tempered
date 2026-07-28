class DKWeapDef_SW500_Hollow extends KFWeapDef_SW500
	abstract;

static function string GetItemLocalization(string KeyName)
{
	if (KeyName ~= "ItemName")
		return "Mercury Fang";
	else if (KeyName ~= "ItemDescription")
		return "An absence given form. Perfected through mastery.";
	else
		return "";
}

defaultproperties
{
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_Revolver_SW500_Hollow"
	BuyPrice=0
	Name="Default__DKWeapDef_SW500_Hollow"
}
