class DKWeapDef_HRG_Boomy_Hollow extends KFWeapDef_HRG_Boomy
	abstract;

static function string GetItemLocalization(string KeyName)
{
	if (KeyName ~= "ItemName")
		return "Rupture Hymn";
	else if (KeyName ~= "ItemDescription")
		return "An absence given form. Perfected through mastery.";
	else
		return "";
}

defaultproperties
{
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_HRG_Boomy_Hollow"
	BuyPrice=0
	Name="Default__DKWeapDef_HRG_Boomy_Hollow"
}
