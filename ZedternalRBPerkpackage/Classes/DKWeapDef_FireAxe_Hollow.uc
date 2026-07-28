class DKWeapDef_FireAxe_Hollow extends KFWeapDef_FireAxe
	abstract;

static function string GetItemLocalization(string KeyName)
{
	if (KeyName ~= "ItemName")
		return "Marrow Cleave";
	else if (KeyName ~= "ItemDescription")
		return "An absence given form. Perfected through mastery.";
	else
		return "";
}

defaultproperties
{
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_Edged_FireAxe_Hollow"
	BuyPrice=0
	Name="Default__DKWeapDef_FireAxe_Hollow"
}
