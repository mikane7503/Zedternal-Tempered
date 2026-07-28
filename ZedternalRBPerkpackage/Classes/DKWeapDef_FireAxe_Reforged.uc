class DKWeapDef_FireAxe_Reforged extends KFWeapDef_FireAxe
	abstract;

const DEFAULT_WEAPON_PATH = "KFGameContent.KFWeap_Edged_FireAxe";

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
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_Edged_FireAxe_Reforged"
	BuyPrice=2975
	Name="Default__DKWeapDef_FireAxe_Reforged"
}
