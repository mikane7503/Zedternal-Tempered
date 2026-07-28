class DKWeapDef_HRG_BlastBrawlers_Hollow extends KFWeapDef_HRG_BlastBrawlers
	abstract;

static function string GetItemLocalization(string KeyName)
{
	if (KeyName ~= "ItemName")
		return "Bone Maw";
	else if (KeyName ~= "ItemDescription")
		return "An absence given form. Perfected through mastery.";
	else
		return "";
}

defaultproperties
{
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_HRG_BlastBrawlers_Hollow"
	BuyPrice=0
	Name="Default__DKWeapDef_HRG_BlastBrawlers_Hollow"
}
