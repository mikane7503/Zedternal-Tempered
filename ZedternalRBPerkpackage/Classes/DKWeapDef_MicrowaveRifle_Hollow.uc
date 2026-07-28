class DKWeapDef_MicrowaveRifle_Hollow extends KFWeapDef_MicrowaveRifle
	abstract;

static function string GetItemLocalization(string KeyName)
{
	if (KeyName ~= "ItemName")
		return "Rift Scorcher";
	else if (KeyName ~= "ItemDescription")
		return "An absence given form. Perfected through mastery.";
	else
		return "";
}

defaultproperties
{
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_AssaultRifle_Microwave_Hollow"
	BuyPrice=0
	Name="Default__DKWeapDef_MicrowaveRifle_Hollow"
}
