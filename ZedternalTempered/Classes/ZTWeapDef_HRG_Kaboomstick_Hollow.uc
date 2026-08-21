class ZTWeapDef_HRG_Kaboomstick_Hollow extends KFWeapDef_HRG_Kaboomstick abstract;

static function string GetItemLocalization(string KeyName)
{
	if (KeyName ~= "ItemName")
		return "Maw of Collapse";
	else if (KeyName ~= "ItemDescription")
		return "An absence given form. Perfected through mastery.";
	else
		return "";
}

defaultproperties
{
	WeaponClassPath="ZedternalTempered.ZTWeap_Shotgun_HRG_Kaboomstick_Hollow"
	BuyPrice=0
	Name="Default__ZTWeapDef_HRG_Kaboomstick_Hollow"
}
