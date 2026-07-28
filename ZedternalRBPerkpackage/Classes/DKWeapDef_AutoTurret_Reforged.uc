class DKWeapDef_AutoTurret_Reforged extends KFWeapDef_AutoTurret
	abstract;

const DEFAULT_WEAPON_PATH = "KFGameContent.KFWeap_AutoTurret";

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
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_AutoTurret_Reforged"
	BuyPrice=1750
	AmmoPricePerMag=84
	Name="Default__DKWeapDef_AutoTurret_Reforged"
}
