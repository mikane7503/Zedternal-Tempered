class DKWeapDef_HRG_Warthog_Hollow extends KFWeapDef_HRG_Warthog
	abstract;

static function string GetItemLocalization(string KeyName)
{
	if (KeyName ~= "ItemName")
		return "Maw of Cinders";
	else if (KeyName ~= "ItemDescription")
		return "An absence given form. Perfected through mastery.";
	else
		return "";
}

defaultproperties
{
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_HRG_Warthog_Hollow"
	BuyPrice=0
	Name="Default__DKWeapDef_HRG_Warthog_Hollow"
}
