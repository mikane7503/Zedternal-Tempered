class DKWeapDef_Remington1858Dual_Hollow extends KFWeapDef_Remington1858Dual
	abstract;

static function string GetItemLocalization(string KeyName)
{
	if (KeyName ~= "ItemName")
		return "Twin Marrow Whispers";
	else if (KeyName ~= "ItemDescription")
		return "An absence given form. Perfected through mastery.";
	else
		return "";
}

defaultproperties
{
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_Revolver_DualRem1858_Hollow"
	BuyPrice=0
	Name="Default__DKWeapDef_Remington1858Dual_Hollow"
}
