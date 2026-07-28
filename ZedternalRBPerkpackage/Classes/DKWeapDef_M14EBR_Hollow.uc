class DKWeapDef_M14EBR_Hollow extends KFWeapDef_M14EBR
	abstract;

static function string GetItemLocalization(string KeyName)
{
	if (KeyName ~= "ItemName")
		return "Marrow Needle";
	else if (KeyName ~= "ItemDescription")
		return "An absence given form. Perfected through mastery.";
	else
		return "";
}

defaultproperties
{
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_Rifle_M14EBR_Hollow"
	BuyPrice=0
	Name="Default__DKWeapDef_M14EBR_Hollow"
}
