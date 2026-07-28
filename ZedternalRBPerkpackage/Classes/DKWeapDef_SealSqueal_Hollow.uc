class DKWeapDef_SealSqueal_Hollow extends KFWeapDef_SealSqueal
	abstract;

static function string GetItemLocalization(string KeyName)
{
	if (KeyName ~= "ItemName")
		return "Maw's Dirge";
	else if (KeyName ~= "ItemDescription")
		return "An absence given form. Perfected through mastery.";
	else
		return "";
}

defaultproperties
{
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_RocketLauncher_SealSqueal_Hollow"
	BuyPrice=0
	Name="Default__DKWeapDef_SealSqueal_Hollow"
}
