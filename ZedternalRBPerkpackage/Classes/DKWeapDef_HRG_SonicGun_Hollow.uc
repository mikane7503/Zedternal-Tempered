class DKWeapDef_HRG_SonicGun_Hollow extends KFWeapDef_HRG_SonicGun
	abstract;

static function string GetItemLocalization(string KeyName)
{
	if (KeyName ~= "ItemName")
		return "Rift Howl";
	else if (KeyName ~= "ItemDescription")
		return "An absence given form. Perfected through mastery.";
	else
		return "";
}

defaultproperties
{
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_HRG_SonicGun_Hollow"
	BuyPrice=0
	Name="Default__DKWeapDef_HRG_SonicGun_Hollow"
}
