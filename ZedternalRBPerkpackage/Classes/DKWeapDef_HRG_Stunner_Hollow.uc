class DKWeapDef_HRG_Stunner_Hollow extends KFWeapDef_HRG_Stunner
	abstract;

static function string GetItemLocalization(string KeyName)
{
	if (KeyName ~= "ItemName")
		return "Numbing Whisper";
	else if (KeyName ~= "ItemDescription")
		return "An absence given form. Perfected through mastery.";
	else
		return "";
}

defaultproperties
{
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_HRG_Stunner_Hollow"
	BuyPrice=0
	Name="Default__DKWeapDef_HRG_Stunner_Hollow"
}
