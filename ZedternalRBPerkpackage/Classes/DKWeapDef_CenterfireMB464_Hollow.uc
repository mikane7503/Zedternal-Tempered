class DKWeapDef_CenterfireMB464_Hollow extends KFWeapDef_CenterfireMB464
	abstract;

static function string GetItemLocalization(string KeyName)
{
	if (KeyName ~= "ItemName")
		return "Bone Whisper";
	else if (KeyName ~= "ItemDescription")
		return "An absence given form. Perfected through mastery.";
	else
		return "";
}

defaultproperties
{
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_Rifle_CenterfireMB464_Hollow"
	BuyPrice=0
	Name="Default__DKWeapDef_CenterfireMB464_Hollow"
}
