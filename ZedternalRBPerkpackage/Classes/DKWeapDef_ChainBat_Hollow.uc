class DKWeapDef_ChainBat_Hollow extends KFWeapDef_ChainBat
	abstract;

static function string GetItemLocalization(string KeyName)
{
	if (KeyName ~= "ItemName")
		return "Wither Fang";
	else if (KeyName ~= "ItemDescription")
		return "An absence given form. Perfected through mastery.";
	else
		return "";
}

defaultproperties
{
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_Blunt_ChainBat_Hollow"
	BuyPrice=0
	Name="Default__DKWeapDef_ChainBat_Hollow"
}
