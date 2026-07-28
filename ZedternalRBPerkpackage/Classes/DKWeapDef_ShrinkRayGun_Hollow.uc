class DKWeapDef_ShrinkRayGun_Hollow extends KFWeapDef_ShrinkRayGun
	abstract;

static function string GetItemLocalization(string KeyName)
{
	if (KeyName ~= "ItemName")
		return "Collapse Sigil";
	else if (KeyName ~= "ItemDescription")
		return "An absence given form. Perfected through mastery.";
	else
		return "";
}

defaultproperties
{
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_ShrinkRayGun_Hollow"
	BuyPrice=0
	Name="Default__DKWeapDef_ShrinkRayGun_Hollow"
}
