class DKWeapDef_Crovel_Hollow extends KFWeapDef_Crovel
	abstract;

static function string GetItemLocalization(string KeyName)
{
	if (KeyName ~= "ItemName")
		return "Severance Edge";
	else if (KeyName ~= "ItemDescription")
		return "An absence given form. Perfected through mastery.";
	else
		return "";
}

defaultproperties
{
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_Blunt_Crovel_Hollow"
	BuyPrice=0
	Name="Default__DKWeapDef_Crovel_Hollow"
}
