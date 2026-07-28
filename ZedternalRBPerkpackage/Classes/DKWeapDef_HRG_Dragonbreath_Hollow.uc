class DKWeapDef_HRG_Dragonbreath_Hollow extends KFWeapDef_HRG_Dragonbreath
	abstract;

static function string GetItemLocalization(string KeyName)
{
	if (KeyName ~= "ItemName")
		return "Ash Maw";
	else if (KeyName ~= "ItemDescription")
		return "An absence given form. Perfected through mastery.";
	else
		return "";
}

defaultproperties
{
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_HRG_Dragonbreath_Hollow"
	BuyPrice=0
	Name="Default__DKWeapDef_HRG_Dragonbreath_Hollow"
}
