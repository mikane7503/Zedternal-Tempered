class DKWeapDef_Kriss_Hollow extends KFWeapDef_Kriss
	abstract;

static function string GetItemLocalization(string KeyName)
{
	if (KeyName ~= "ItemName")
		return "Whisper Swarm";
	else if (KeyName ~= "ItemDescription")
		return "An absence given form. Perfected through mastery.";
	else
		return "";
}

defaultproperties
{
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_SMG_Kriss_Hollow"
	BuyPrice=0
	Name="Default__DKWeapDef_Kriss_Hollow"
}
