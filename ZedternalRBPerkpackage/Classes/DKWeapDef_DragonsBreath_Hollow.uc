class DKWeapDef_DragonsBreath_Hollow extends KFWeapDef_DragonsBreath
	abstract;

static function string GetItemLocalization(string KeyName)
{
	if (KeyName ~= "ItemName")
		return "Cinder Swallow";
	else if (KeyName ~= "ItemDescription")
		return "An absence given form. Perfected through mastery.";
	else
		return "";
}

defaultproperties
{
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_Shotgun_DragonsBreath_Hollow"
	BuyPrice=0
	Name="Default__DKWeapDef_DragonsBreath_Hollow"
}
