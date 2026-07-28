class DKWeapDef_HRGWinterbiteDual_Hollow extends KFWeapDef_HRGWinterbiteDual
	abstract;

static function string GetItemLocalization(string KeyName)
{
	if (KeyName ~= "ItemName")
		return "Twin Marrow Whisper";
	else if (KeyName ~= "ItemDescription")
		return "An absence given form. Perfected through mastery.";
	else
		return "";
}

defaultproperties
{
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_Pistol_DualHRGWinterbite_Hollow"
	BuyPrice=0
	Name="Default__DKWeapDef_HRGWinterbiteDual_Hollow"
}
