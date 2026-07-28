class DKWeapDef_9mm_Hollow extends KFWeapDef_9mm
	abstract;

static function string GetItemLocalization(string KeyName)
{
	if (KeyName ~= "ItemName")
		return "Hollow Needle";
	else if (KeyName ~= "ItemDescription")
		return "An absence given form. Perfected through mastery.";
	else
		return "";
}

defaultproperties
{
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_Pistol_9mm_Hollow"
	BuyPrice=0
	Name="Default__DKWeapDef_9mm_Hollow"
}
