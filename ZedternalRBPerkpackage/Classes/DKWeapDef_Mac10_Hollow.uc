class DKWeapDef_Mac10_Hollow extends KFWeapDef_Mac10
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
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_SMG_Mac10_Hollow"
	BuyPrice=0
	Name="Default__DKWeapDef_Mac10_Hollow"
}
