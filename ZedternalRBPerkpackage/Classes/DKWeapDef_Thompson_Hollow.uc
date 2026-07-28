class DKWeapDef_Thompson_Hollow extends KFWeapDef_Thompson
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
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_AssaultRifle_Thompson_Hollow"
	BuyPrice=0
	Name="Default__DKWeapDef_Thompson_Hollow"
}
