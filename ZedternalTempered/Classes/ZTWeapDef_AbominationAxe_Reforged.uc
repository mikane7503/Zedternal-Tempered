class ZTWeapDef_AbominationAxe_Reforged extends KFWeapDef_AbominationAxe abstract;

const DEFAULT_WEAPON_PATH = "KFGameContent.KFWeap_Edged_AbominationAxe";

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
	WeaponClassPath="ZedternalTempered.ZTWeap_Edged_AbominationAxe_Reforged"
	BuyPrice=7000
	Name="Default__ZTWeapDef_AbominationAxe_Reforged"
}
