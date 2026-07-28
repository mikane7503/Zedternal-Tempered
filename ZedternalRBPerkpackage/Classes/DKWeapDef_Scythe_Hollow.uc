class DKWeapDef_Scythe_Hollow extends KFWeapDef_Scythe
	abstract;

static function string GetItemLocalization(string KeyName)
{
	if (KeyName ~= "ItemName")
		return "Dusk Reaper";
	else if (KeyName ~= "ItemDescription")
		return "An absence given form. Perfected through mastery.";
	else
		return "";
}

defaultproperties
{
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_Edged_Scythe_Hollow"
	BuyPrice=0
	Name="Default__DKWeapDef_Scythe_Hollow"
}
