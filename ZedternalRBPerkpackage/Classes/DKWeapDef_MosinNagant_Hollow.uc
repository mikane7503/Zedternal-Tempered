class DKWeapDef_MosinNagant_Hollow extends KFWeapDef_MosinNagant
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
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_Rifle_MosinNagant_Hollow"
	BuyPrice=0
	Name="Default__DKWeapDef_MosinNagant_Hollow"
}
