class DKWeapDef_FAMAS_Hollow extends KFWeapDef_FAMAS
	abstract;

static function string GetItemLocalization(string KeyName)
{
	if (KeyName ~= "ItemName")
		return "Void Staccato";
	else if (KeyName ~= "ItemDescription")
		return "An absence given form. Perfected through mastery.";
	else
		return "";
}

defaultproperties
{
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_AssaultRifle_FAMAS_Hollow"
	BuyPrice=0
	Name="Default__DKWeapDef_FAMAS_Hollow"
}
