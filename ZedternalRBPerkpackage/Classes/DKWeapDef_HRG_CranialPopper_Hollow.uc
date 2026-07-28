class DKWeapDef_HRG_CranialPopper_Hollow extends KFWeapDef_HRG_CranialPopper
	abstract;

static function string GetItemLocalization(string KeyName)
{
	if (KeyName ~= "ItemName")
		return "Marrow Needle";
	else if (KeyName ~= "ItemDescription")
		return "An absence given form. Perfected through mastery.";
	else
		return "";
}

defaultproperties
{
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_HRG_CranialPopper_Hollow"
	BuyPrice=0
	Name="Default__DKWeapDef_HRG_CranialPopper_Hollow"
}
