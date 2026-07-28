class DKWeapDef_AR15_Hollow extends KFWeapDef_AR15
	abstract;

static function string GetItemLocalization(string KeyName)
{
	if (KeyName ~= "ItemName")
		return "Bone Whisper Caliber";
	else if (KeyName ~= "ItemDescription")
		return "An absence given form. Perfected through mastery.";
	else
		return "";
}

defaultproperties
{
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_AssaultRifle_AR15_Hollow"
	BuyPrice=0
	Name="Default__DKWeapDef_AR15_Hollow"
}
