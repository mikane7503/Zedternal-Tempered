class ZTWeapDef_HRG_Boomy_Hollow extends KFWeapDef_HRG_Boomy abstract;

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
	WeaponClassPath="ZedternalTempered.ZTWeap_HRG_Boomy_Hollow"
	BuyPrice=0
	Name="Default__ZTWeapDef_HRG_Boomy_Hollow"
}
