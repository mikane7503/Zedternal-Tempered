class DKWeapDef_HK_UMP_Hollow extends KFWeapDef_HK_UMP
	abstract;

static function string GetItemLocalization(string KeyName)
{
	if (KeyName ~= "ItemName")
		return "Marrow Whisper";
	else if (KeyName ~= "ItemDescription")
		return "An absence given form. Perfected through mastery.";
	else
		return "";
}

defaultproperties
{
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_SMG_HK_UMP_Hollow"
	BuyPrice=0
	Name="Default__DKWeapDef_HK_UMP_Hollow"
}
