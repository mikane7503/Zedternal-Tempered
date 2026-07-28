class DKWeapDef_IonThruster_Hollow extends KFWeapDef_IonThruster
	abstract;

static function string GetItemLocalization(string KeyName)
{
	if (KeyName ~= "ItemName")
		return "Mercury Fang";
	else if (KeyName ~= "ItemDescription")
		return "An absence given form. Perfected through mastery.";
	else
		return "";
}

defaultproperties
{
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_Edged_IonThruster_Hollow"
	BuyPrice=0
	Name="Default__DKWeapDef_IonThruster_Hollow"
}
