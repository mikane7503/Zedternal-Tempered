class DKWeapDef_Stoner63A_Hollow extends KFWeapDef_Stoner63A
	abstract;

static function string GetItemLocalization(string KeyName)
{
	if (KeyName ~= "ItemName")
		return "Duskfall Storm";
	else if (KeyName ~= "ItemDescription")
		return "An absence given form. Perfected through mastery.";
	else
		return "";
}

defaultproperties
{
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_LMG_Stoner63A_Hollow"
	BuyPrice=0
	Name="Default__DKWeapDef_Stoner63A_Hollow"
}
