class DKWeapDef_HRG_BarrierRifle_Hollow extends KFWeapDef_HRG_BarrierRifle
	abstract;

static function string GetItemLocalization(string KeyName)
{
	if (KeyName ~= "ItemName")
		return "Veil Warden";
	else if (KeyName ~= "ItemDescription")
		return "An absence given form. Perfected through mastery.";
	else
		return "";
}

defaultproperties
{
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_HRG_BarrierRifle_Hollow"
	BuyPrice=0
	Name="Default__DKWeapDef_HRG_BarrierRifle_Hollow"
}
