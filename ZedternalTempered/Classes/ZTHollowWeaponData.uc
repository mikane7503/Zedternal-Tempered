class ZTHollowWeaponData extends Object abstract;

// Deliberately small registry: only Demolitionist weapons can earn a Hollow
// mastery reward.  Stats are handled centrally by ZTUpgrade_Perk_Hollow.
var array<string> HollowWeaponNormNames;
var array<string> HollowWeaponDefPaths;

static function int GetHollowWeaponCount()
{
	return default.HollowWeaponNormNames.Length;
}

static function string GetHollowNormName(int Index)
{
	if (Index >= 0 && Index < default.HollowWeaponNormNames.Length)
		return default.HollowWeaponNormNames[Index];
	return "";
}

static function string GetHollowDefPath(int Index)
{
	if (Index >= 0 && Index < default.HollowWeaponDefPaths.Length)
		return default.HollowWeaponDefPaths[Index];
	return "";
}

static function bool HasHollowVariant(string NormName)
{
	local int i;
	for (i = 0; i < default.HollowWeaponNormNames.Length; ++i)
		if (default.HollowWeaponNormNames[i] == NormName) return true;
	return false;
}

static function string GetHollowDefPathForWeapon(string NormName)
{
	local int i;
	for (i = 0; i < default.HollowWeaponNormNames.Length; ++i)
		if (default.HollowWeaponNormNames[i] == NormName)
			return GetHollowDefPath(i);
	return "";
}

defaultproperties
{
	HollowWeaponNormNames(0)="Thrown_C4"
	HollowWeaponNormNames(1)="GrenadeLauncher_HX25"
	HollowWeaponNormNames(2)="GrenadeLauncher_M79"
	HollowWeaponNormNames(3)="GrenadeLauncher_M32"
	HollowWeaponNormNames(4)="RocketLauncher_RPG7"
	HollowWeaponNormNames(5)="RocketLauncher_Seeker6"
	HollowWeaponNormNames(6)="RocketLauncher_SealSqueal"
	HollowWeaponNormNames(7)="AssaultRifle_M16M203"
	HollowWeaponNormNames(8)="Blunt_Pulverizer"
	HollowWeaponNormNames(9)="Shotgun_HRG_Kaboomstick"
	HollowWeaponNormNames(10)="Pistol_Blunderbuss"
	HollowWeaponNormNames(11)="HRG_Boomy"
	HollowWeaponNormNames(12)="HRG_Crossboom"
	HollowWeaponNormNames(13)="HRG_BallisticBouncer"
	HollowWeaponNormNames(14)="RocketLauncher_ThermiteBore"
	HollowWeaponNormNames(15)="HuskCannon"

	HollowWeaponDefPaths(0)="ZedternalTempered.ZTWeapDef_C4_Hollow"
	HollowWeaponDefPaths(1)="ZedternalTempered.ZTWeapDef_HX25_Hollow"
	HollowWeaponDefPaths(2)="ZedternalTempered.ZTWeapDef_M79_Hollow"
	HollowWeaponDefPaths(3)="ZedternalTempered.ZTWeapDef_M32_Hollow"
	HollowWeaponDefPaths(4)="ZedternalTempered.ZTWeapDef_RPG7_Hollow"
	HollowWeaponDefPaths(5)="ZedternalTempered.ZTWeapDef_Seeker6_Hollow"
	HollowWeaponDefPaths(6)="ZedternalTempered.ZTWeapDef_SealSqueal_Hollow"
	HollowWeaponDefPaths(7)="ZedternalTempered.ZTWeapDef_M16M203_Hollow"
	HollowWeaponDefPaths(8)="ZedternalTempered.ZTWeapDef_Pulverizer_Hollow"
	HollowWeaponDefPaths(9)="ZedternalTempered.ZTWeapDef_HRG_Kaboomstick_Hollow"
	HollowWeaponDefPaths(10)="ZedternalTempered.ZTWeapDef_Blunderbuss_Hollow"
	HollowWeaponDefPaths(11)="ZedternalTempered.ZTWeapDef_HRG_Boomy_Hollow"
	HollowWeaponDefPaths(12)="ZedternalTempered.ZTWeapDef_HRG_Crossboom_Hollow"
	HollowWeaponDefPaths(13)="ZedternalTempered.ZTWeapDef_HRG_BallisticBouncer_Hollow"
	HollowWeaponDefPaths(14)="ZedternalTempered.ZTWeapDef_ThermiteBore_Hollow"
	HollowWeaponDefPaths(15)="ZedternalTempered.ZTWeapDef_HuskCannon_Hollow"
}
