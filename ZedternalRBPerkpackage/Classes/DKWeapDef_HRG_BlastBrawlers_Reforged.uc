class DKWeapDef_HRG_BlastBrawlers_Reforged extends KFWeapDef_HRG_BlastBrawlers
	abstract;

const DEFAULT_WEAPON_PATH = "KFGameContent.KFWeap_HRG_BlastBrawlers";

static function string GetItemLocalization(string KeyName)
{
	local array<string> Strings;
	local string Localization;

	ParseStringIntoArray(DEFAULT_WEAPON_PATH, Strings, ".", True);
	Localization = Localize(Strings[1], KeyName, Strings[0]);
	if (KeyName ~= "ItemName")
		return Chr(9733) @ Localization;
	else
		return Localization;
}

defaultproperties
{
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_HRG_BlastBrawlers_Reforged"
	BuyPrice=5600
	AmmoPricePerMag=84
	Name="Default__DKWeapDef_HRG_BlastBrawlers_Reforged"
}
