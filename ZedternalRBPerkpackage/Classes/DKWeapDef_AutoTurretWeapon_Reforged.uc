class DKWeapDef_AutoTurretWeapon_Reforged extends KFWeapDef_AutoTurretWeapon
	abstract;

const DEFAULT_WEAPON_PATH = "KFGameContent.KFWeap_AutoTurretWeapon";

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
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_AutoTurretWeapon_Reforged"
	Name="Default__DKWeapDef_AutoTurretWeapon_Reforged"
}
