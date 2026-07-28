class DKWeapDef_Scythe_Reforged extends KFWeapDef_Scythe
	abstract;

const DEFAULT_WEAPON_PATH = "KFGameContent.KFWeap_Edged_Scythe";

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
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_Edged_Scythe_Reforged"
	BuyPrice=5250
	Name="Default__DKWeapDef_Scythe_Reforged"
}
