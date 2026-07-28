class DKWeapDef_HRGIncision_Hollow extends KFWeapDef_HRGIncision
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
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_Rifle_HRGIncision_Hollow"
	BuyPrice=0
	Name="Default__DKWeapDef_HRGIncision_Hollow"
}
