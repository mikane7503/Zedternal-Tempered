class DKWeapDef_HRG_CranialPopper_Reforged extends KFWeapDef_HRG_CranialPopper
	abstract;

const DEFAULT_WEAPON_PATH = "KFGameContent.KFWeap_HRG_CranialPopper";

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
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_HRG_CranialPopper_Reforged"
	BuyPrice=3850
	AmmoPricePerMag=112
	Name="Default__DKWeapDef_HRG_CranialPopper_Reforged"
}
