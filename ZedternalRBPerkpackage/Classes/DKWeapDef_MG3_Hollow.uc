class DKWeapDef_MG3_Hollow extends KFWeapDef_MG3
	abstract;

static function string GetItemLocalization(string KeyName)
{
	if (KeyName ~= "ItemName")
		return "Marrow Cascade";
	else if (KeyName ~= "ItemDescription")
		return "An absence given form. Perfected through mastery.";
	else
		return "";
}

defaultproperties
{
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_LMG_MG3_Hollow"
	BuyPrice=0
	Name="Default__DKWeapDef_MG3_Hollow"
}
