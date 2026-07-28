class DKWeapDef_HRG_Kaboomstick_Hollow extends KFWeapDef_HRG_Kaboomstick
	abstract;

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
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_Shotgun_HRG_Kaboomstick_Hollow"
	BuyPrice=0
	Name="Default__DKWeapDef_HRG_Kaboomstick_Hollow"
}
