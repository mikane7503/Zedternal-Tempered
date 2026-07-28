class DKWeapDef_HRGTeslauncher_Hollow extends KFWeapDef_HRGTeslauncher
	abstract;

static function string GetItemLocalization(string KeyName)
{
	if (KeyName ~= "ItemName")
		return "Rift Conductor";
	else if (KeyName ~= "ItemDescription")
		return "An absence given form. Perfected through mastery.";
	else
		return "";
}

defaultproperties
{
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_AssaultRifle_HRGTeslauncher_Hollow"
	BuyPrice=0
	Name="Default__DKWeapDef_HRGTeslauncher_Hollow"
}
