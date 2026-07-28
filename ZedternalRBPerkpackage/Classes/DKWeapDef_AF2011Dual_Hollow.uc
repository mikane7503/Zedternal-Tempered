class DKWeapDef_AF2011Dual_Hollow extends KFWeapDef_AF2011Dual
	abstract;

static function string GetItemLocalization(string KeyName)
{
	if (KeyName ~= "ItemName")
		return "Mercury Echo";
	else if (KeyName ~= "ItemDescription")
		return "An absence given form. Perfected through mastery.";
	else
		return "";
}

defaultproperties
{
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_Pistol_DualAF2011_Hollow"
	BuyPrice=0
	Name="Default__DKWeapDef_AF2011Dual_Hollow"
}
