class DKWeapDef_MicrowaveGun_Hollow extends KFWeapDef_MicrowaveGun
	abstract;

static function string GetItemLocalization(string KeyName)
{
	if (KeyName ~= "ItemName")
		return "Absence Tongue";
	else if (KeyName ~= "ItemDescription")
		return "An absence given form. Perfected through mastery.";
	else
		return "";
}

defaultproperties
{
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_Beam_Microwave_Hollow"
	BuyPrice=0
	Name="Default__DKWeapDef_MicrowaveGun_Hollow"
}
