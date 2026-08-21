// ===================================================================
// ZTConfig_PlayerCaps - Server-side player stat caps
// INI: ZedternalTempered_ZedternalUnlimited (config(ZedternalUnlimited))
// All caps disabled by default (0 / 0.0 = no cap). Enable bEnablePlayerCaps
// and set individual cap values to activate.
// Caps are enforced AFTER all perk/skill/equipment/roguelike bonuses, at the
// very end of each ZTPerk stat hook, so they win over every bonus source.
// ===================================================================
class ZTConfig_PlayerCaps extends Object config(ZedternalUnlimited);

var config int MODEVERSION;

// Master toggle - must be True for any caps to apply
var config bool bEnablePlayerCaps;

// ===================================================================
// GROUP A - ABSOLUTE caps (0 = no cap)
// Clamp the final value down to this number.
// ===================================================================

// Maximum health after all bonuses (e.g. 250)
var config int Cap_MaxHealth;

// Maximum armor after all bonuses (e.g. 250)
var config int Cap_MaxArmor;

// Maximum carry weight blocks after all bonuses (e.g. 25)
var config int Cap_CarryWeight;

// Maximum spare grenades after all bonuses (e.g. 10)
var config int Cap_MaxSpareGrenades;

// Maximum simultaneously deployed turrets/pets after all bonuses (e.g. 2)
var config int Cap_MaxDeployedTurrets;

// ===================================================================
// GROUP A-MIN - ABSOLUTE MINIMUMS (0 = no floor)
// Guarantee the final value is at least this number, applied AFTER the
// matching maximum cap above. For sane configs keep min <= max.
// ===================================================================

// Minimum max-health floor after all penalties (e.g. 100)
var config int Cap_MinHealth;

// Minimum max-armor floor after all penalties (e.g. 50)
var config int Cap_MinArmor;

// Minimum magazine size floor after all penalties (absolute round count, e.g. 5).
// Base-aware: never raises a weapon above its own base mag, so single-shot
// weapons (base mag 1) are not inflated.
var config int Cap_MinMagSize;

// ===================================================================
// GROUP B - "HIGHER IS BETTER" MULTIPLIER caps (0.0 = no cap)
// Final value may be at most (base value * cap). Example:
// Cap_DamageGivenMultiplier=1.5 -> final damage at most 150% of base.
// ===================================================================

// Max damage multiplier for all targets (e.g. 1.5 = 150% of base)
var config float Cap_DamageGivenMultiplier;

// Max damage multiplier specifically for large zeds (e.g. 1.0 = no bonus)
// If both this and DamageGiven are set, the LOWER cap applies for large zeds
var config float Cap_DamageToLargeMultiplier;

// Max damage multiplier for headshots specifically (e.g. 1.5 = 150% of base)
// If both this and DamageGiven are set, the LOWER cap applies for headshots
var config float Cap_HeadshotDamageMultiplier;

// Max movement speed as ratio of base speed (e.g. 1.0 = no speed increase)
var config float Cap_SpeedMultiplier;

// Max magazine size as ratio of base mag (e.g. 2.0 = at most double)
var config float Cap_MagSizeMultiplier;

// Max spare ammo as ratio of base spare capacity (e.g. 2.0 = at most double)
var config float Cap_SpareAmmoMultiplier;

// Max heal amount as ratio of base heal (e.g. 2.0 = at most double)
var config float Cap_HealAmountMultiplier;

// Max berserker hard-attack damage as ratio of base (e.g. 2.0)
var config float Cap_HardAttackDamageMultiplier;

// Absolute max penetration modifier value (e.g. 5.0)
var config float Cap_PenetrationMax;

// Absolute max stun power modifier value (e.g. 3.0)
var config float Cap_StunPowerMax;

// Absolute max stumble power modifier value (e.g. 3.0)
var config float Cap_StumblePowerMax;

// Absolute max knockdown power modifier value (e.g. 3.0)
var config float Cap_KnockdownPowerMax;

// Absolute max snare power modifier value (e.g. 3.0)
var config float Cap_SnarePowerMax;

// ===================================================================
// GROUP C - "LOWER IS BETTER" MIN-SCALE caps (0.0 = no cap)
// Final value must be at least (base value * cap). This caps how far a
// "lower is better" stat can be reduced. Example:
// Cap_ReloadRateMinScale=0.5 -> reload time at least 50% of base (max 2x faster).
// ===================================================================

// Minimum melee attack duration as ratio of base duration
// (1.0 = no attack speed increase allowed; 0.5 = max 2x faster)
var config float Cap_MeleeAttackSpeedMinDuration;

// Minimum reload rate scale (1.0 = default reload time; 0.5 = max 2x faster)
var config float Cap_ReloadRateMinScale;

// Minimum rate-of-fire interval as ratio of base (0.5 = max 2x faster firing)
var config float Cap_RateOfFireMinScale;

// Minimum weapon switch time as ratio of base (0.5 = max 2x faster swaps)
var config float Cap_WeaponSwitchMinScale;

// Minimum incoming damage as ratio of base (0.25 = always take at least 25%,
// i.e. damage resistance caps at 75%)
var config float Cap_DamageTakenMinScale;

// Minimum recoil as ratio of base recoil (0.25 = at most 75% recoil reduction)
var config float Cap_RecoilMinScale;

// Minimum spread as ratio of base spread (0.25 = at most 75% spread reduction)
var config float Cap_SpreadMinScale;

// ===================================================================
// CONFIG VERSIONING
// ===================================================================

static function UpdateConfig()
{
	local bool bDirty;

	bDirty = False;

	if (default.MODEVERSION < 1)
	{
		default.bEnablePlayerCaps = False;

		default.Cap_MaxHealth = 0;
		default.Cap_MaxArmor = 0;
		default.Cap_CarryWeight = 0;

		default.Cap_DamageGivenMultiplier = 0.0;
		default.Cap_DamageToLargeMultiplier = 0.0;
		default.Cap_HeadshotDamageMultiplier = 0.0;
		default.Cap_SpeedMultiplier = 0.0;
		default.Cap_MeleeAttackSpeedMinDuration = 0.0;

		default.MODEVERSION = 1;
		bDirty = True;
	}

	if (default.MODEVERSION < 2)
	{
		// New cappable stats added in v2 (all disabled by default)
		default.Cap_MaxSpareGrenades = 0;
		default.Cap_MaxDeployedTurrets = 0;

		default.Cap_MagSizeMultiplier = 0.0;
		default.Cap_SpareAmmoMultiplier = 0.0;
		default.Cap_HealAmountMultiplier = 0.0;
		default.Cap_HardAttackDamageMultiplier = 0.0;
		default.Cap_PenetrationMax = 0.0;
		default.Cap_StunPowerMax = 0.0;
		default.Cap_StumblePowerMax = 0.0;
		default.Cap_KnockdownPowerMax = 0.0;
		default.Cap_SnarePowerMax = 0.0;

		default.Cap_ReloadRateMinScale = 0.0;
		default.Cap_RateOfFireMinScale = 0.0;
		default.Cap_WeaponSwitchMinScale = 0.0;
		default.Cap_DamageTakenMinScale = 0.0;
		default.Cap_RecoilMinScale = 0.0;
		default.Cap_SpreadMinScale = 0.0;

		default.MODEVERSION = 2;
		bDirty = True;
	}

	if (default.MODEVERSION < 3)
	{
		// Minimum floors added in v3 (all disabled by default)
		default.Cap_MinHealth = 0;
		default.Cap_MinArmor = 0;
		default.Cap_MinMagSize = 0;

		// BEGIN TEMPERED INI DEFAULTS (generated; do not edit by hand)
		default.Cap_MaxHealth = 0;
		default.Cap_MaxArmor = 0;
		default.Cap_CarryWeight = 0;
		default.Cap_DamageGivenMultiplier = 0.000000f;
		default.Cap_DamageToLargeMultiplier = 0.000000f;
		default.Cap_HeadshotDamageMultiplier = 0.000000f;
		default.Cap_SpeedMultiplier = 0.000000f;
		default.Cap_MeleeAttackSpeedMinDuration = 0.250000f;
		default.Cap_MaxSpareGrenades = 0;
		default.Cap_MaxDeployedTurrets = 0;
		default.Cap_MinHealth = 1;
		default.Cap_MinArmor = 0;
		default.Cap_MinMagSize = 0;
		default.Cap_MagSizeMultiplier = 0.000000f;
		default.Cap_SpareAmmoMultiplier = 0.000000f;
		default.Cap_HealAmountMultiplier = 1.500000f;
		default.Cap_HardAttackDamageMultiplier = 0.000000f;
		default.Cap_PenetrationMax = 10.000000f;
		default.Cap_StunPowerMax = 2.000000f;
		default.Cap_StumblePowerMax = 2.000000f;
		default.Cap_KnockdownPowerMax = 2.000000f;
		default.Cap_SnarePowerMax = 2.000000f;
		default.Cap_ReloadRateMinScale = 0.500000f;
		default.Cap_RateOfFireMinScale = 0.200000f;
		default.Cap_WeaponSwitchMinScale = 0.200000f;
		default.Cap_DamageTakenMinScale = 0.200000f;
		default.Cap_RecoilMinScale = 0.100000f;
		default.Cap_SpreadMinScale = 0.100000f;
		// END TEMPERED INI DEFAULTS
		default.MODEVERSION = 3;
		bDirty = True;
	}

	if (bDirty)
	{
		StaticSaveConfig();
	}
}

static function CheckBasicConfigValues()
{
	local bool bDirty;

	bDirty = False;

	// --- Absolute int caps cannot be negative ---
	if (default.Cap_MaxHealth < 0)          { default.Cap_MaxHealth = 0;          bDirty = True; }
	if (default.Cap_MaxArmor < 0)           { default.Cap_MaxArmor = 0;           bDirty = True; }
	if (default.Cap_CarryWeight < 0)        { default.Cap_CarryWeight = 0;        bDirty = True; }
	if (default.Cap_MaxSpareGrenades < 0)   { default.Cap_MaxSpareGrenades = 0;   bDirty = True; }
	if (default.Cap_MaxDeployedTurrets < 0) { default.Cap_MaxDeployedTurrets = 0; bDirty = True; }
	if (default.Cap_MinHealth < 0)          { default.Cap_MinHealth = 0;          bDirty = True; }
	if (default.Cap_MinArmor < 0)           { default.Cap_MinArmor = 0;           bDirty = True; }
	if (default.Cap_MinMagSize < 0)         { default.Cap_MinMagSize = 0;         bDirty = True; }

	// --- Higher-is-better multiplier caps cannot be negative ---
	if (default.Cap_DamageGivenMultiplier < 0.0)      { default.Cap_DamageGivenMultiplier = 0.0;      bDirty = True; }
	if (default.Cap_DamageToLargeMultiplier < 0.0)    { default.Cap_DamageToLargeMultiplier = 0.0;    bDirty = True; }
	if (default.Cap_HeadshotDamageMultiplier < 0.0)   { default.Cap_HeadshotDamageMultiplier = 0.0;   bDirty = True; }
	if (default.Cap_SpeedMultiplier < 0.0)            { default.Cap_SpeedMultiplier = 0.0;            bDirty = True; }
	if (default.Cap_MagSizeMultiplier < 0.0)          { default.Cap_MagSizeMultiplier = 0.0;          bDirty = True; }
	if (default.Cap_SpareAmmoMultiplier < 0.0)        { default.Cap_SpareAmmoMultiplier = 0.0;        bDirty = True; }
	if (default.Cap_HealAmountMultiplier < 0.0)       { default.Cap_HealAmountMultiplier = 0.0;       bDirty = True; }
	if (default.Cap_HardAttackDamageMultiplier < 0.0) { default.Cap_HardAttackDamageMultiplier = 0.0; bDirty = True; }
	if (default.Cap_PenetrationMax < 0.0)             { default.Cap_PenetrationMax = 0.0;             bDirty = True; }
	if (default.Cap_StunPowerMax < 0.0)               { default.Cap_StunPowerMax = 0.0;               bDirty = True; }
	if (default.Cap_StumblePowerMax < 0.0)            { default.Cap_StumblePowerMax = 0.0;            bDirty = True; }
	if (default.Cap_KnockdownPowerMax < 0.0)          { default.Cap_KnockdownPowerMax = 0.0;          bDirty = True; }
	if (default.Cap_SnarePowerMax < 0.0)              { default.Cap_SnarePowerMax = 0.0;              bDirty = True; }

	// --- Lower-is-better min-scale caps cannot be negative ---
	if (default.Cap_MeleeAttackSpeedMinDuration < 0.0) { default.Cap_MeleeAttackSpeedMinDuration = 0.0; bDirty = True; }
	if (default.Cap_ReloadRateMinScale < 0.0)          { default.Cap_ReloadRateMinScale = 0.0;          bDirty = True; }
	if (default.Cap_RateOfFireMinScale < 0.0)          { default.Cap_RateOfFireMinScale = 0.0;          bDirty = True; }
	if (default.Cap_WeaponSwitchMinScale < 0.0)        { default.Cap_WeaponSwitchMinScale = 0.0;        bDirty = True; }
	if (default.Cap_DamageTakenMinScale < 0.0)         { default.Cap_DamageTakenMinScale = 0.0;         bDirty = True; }
	if (default.Cap_RecoilMinScale < 0.0)              { default.Cap_RecoilMinScale = 0.0;              bDirty = True; }
	if (default.Cap_SpreadMinScale < 0.0)              { default.Cap_SpreadMinScale = 0.0;              bDirty = True; }

	if (bDirty)
	{
		`log("[ZTConfig_PlayerCaps] Reset one or more negative cap values to 0 (disabled)");
		StaticSaveConfig();
	}
}

// ===================================================================
// GETTER FUNCTIONS
// ===================================================================

static function bool IsEnabled() { return default.bEnablePlayerCaps; }

// Group A - absolute
static function int GetCapMaxHealth()         { return default.Cap_MaxHealth; }
static function int GetCapMaxArmor()          { return default.Cap_MaxArmor; }
static function int GetCapCarryWeight()       { return default.Cap_CarryWeight; }
static function int GetCapMaxSpareGrenades()  { return default.Cap_MaxSpareGrenades; }
static function int GetCapMaxDeployedTurrets(){ return default.Cap_MaxDeployedTurrets; }

// Group A-MIN - absolute minimums
static function int GetCapMinHealth()  { return default.Cap_MinHealth; }
static function int GetCapMinArmor()   { return default.Cap_MinArmor; }
static function int GetCapMinMagSize() { return default.Cap_MinMagSize; }

// Group B - higher-is-better multipliers
static function float GetCapDamageGivenMultiplier()      { return default.Cap_DamageGivenMultiplier; }
static function float GetCapDamageToLargeMultiplier()    { return default.Cap_DamageToLargeMultiplier; }
static function float GetCapHeadshotDamageMultiplier()   { return default.Cap_HeadshotDamageMultiplier; }
static function float GetCapSpeedMultiplier()            { return default.Cap_SpeedMultiplier; }
static function float GetCapMagSizeMultiplier()          { return default.Cap_MagSizeMultiplier; }
static function float GetCapSpareAmmoMultiplier()        { return default.Cap_SpareAmmoMultiplier; }
static function float GetCapHealAmountMultiplier()       { return default.Cap_HealAmountMultiplier; }
static function float GetCapHardAttackDamageMultiplier() { return default.Cap_HardAttackDamageMultiplier; }
static function float GetCapPenetrationMax()             { return default.Cap_PenetrationMax; }
static function float GetCapStunPowerMax()               { return default.Cap_StunPowerMax; }
static function float GetCapStumblePowerMax()            { return default.Cap_StumblePowerMax; }
static function float GetCapKnockdownPowerMax()          { return default.Cap_KnockdownPowerMax; }
static function float GetCapSnarePowerMax()              { return default.Cap_SnarePowerMax; }

// Group C - lower-is-better min-scales
static function float GetCapMeleeAttackSpeedMinDuration() { return default.Cap_MeleeAttackSpeedMinDuration; }
static function float GetCapReloadRateMinScale()          { return default.Cap_ReloadRateMinScale; }
static function float GetCapRateOfFireMinScale()          { return default.Cap_RateOfFireMinScale; }
static function float GetCapWeaponSwitchMinScale()        { return default.Cap_WeaponSwitchMinScale; }
static function float GetCapDamageTakenMinScale()         { return default.Cap_DamageTakenMinScale; }
static function float GetCapRecoilMinScale()              { return default.Cap_RecoilMinScale; }
static function float GetCapSpreadMinScale()              { return default.Cap_SpreadMinScale; }

defaultproperties
{
	Name="Default__ZTConfig_PlayerCaps"
}
