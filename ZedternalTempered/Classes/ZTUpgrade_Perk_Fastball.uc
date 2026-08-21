// ===================================================================
// ZTUpgrade_Perk_Fastball - "Teammates are projectiles"
//
// Active (dedicated key - default M, ActivateFastball):
//   Aim at a nearby teammate and press to LAUNCH them along your aim.
//   The payload flies with full fall damage immunity and lands as a
//   shockwave (ZTDT_Fastball_Impact) credited to YOU, scaled by fall
//   speed and your perk level. Landing also patches the payload up
//   (heal + armor) so being thrown is always a favor, never a grief.
//
// Consent (config ConsentMode):
//   0 = launch anyone in range
//   1 = MUTUAL FACING (default): the teammate must be looking at you
//       when you press - both of you agree with your eyes.
//
// Passive: impact damage +%x% per level.
// Level 10: shockwave radius x1.5.
// Level 20: launch force x1.6 and the payload lands with a bigger
// heal - human artillery, properly maintained.
//
// Flight/impact state lives in ZTUpgrade_Perk_Fastball_Helper plus a
// ZTFastball_PayloadMarker on the launched pawn (fall damage shield -
// zeroed in both ZTGameInfos' ReduceDamage, MIRRORED).
// ===================================================================
class ZTUpgrade_Perk_Fastball extends ZTUpgrade_Perk
	config(ZedternalUnlimited);

// --- Launch tunables ---
var config float TargetRange;            // uu - how close a teammate must be to grab
var config float TargetConeDot;          // launcher aim dot gate to select the teammate
var config int ConsentMode;              // 0 = free, 1 = mutual facing (default)
var config float ConsentFacingDot;       // payload-looking-at-launcher dot gate (mode 1)
var config float LaunchForce;            // horizontal launch speed (uu/s)
var config float LaunchZBoost;           // additional upward speed (uu/s)
var config float LaunchForceMultL20;     // force multiplier at level 20
var config float CooldownSeconds;        // per-launcher cooldown

// --- Impact tunables ---
var config float ImpactBaseDamage;       // shockwave damage before scaling
var config float ImpactRadius;           // uu
var config float ImpactRadiusMultL10;    // radius multiplier at level 10
var config float ImpactSpeedDamageScale; // extra damage fraction per 1000 uu/s of landing speed
var config float ImpactDamagePerLevel;   // fraction added per perk level (0.05 = +5%/level)

// --- Payload reward ---
var config int PayloadHealOnLanding;     // health restored to the launched teammate
var config int PayloadHealOnLandingL20;  // health restored at launcher level 20
var config int PayloadArmorOnLanding;    // armor restored to the launched teammate

var config int MODEVERSION;

// ===================================================================
// CONFIG SEED
// ===================================================================
static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.TargetRange = 350.0f;
		default.TargetConeDot = 0.7f;
		default.ConsentMode = 1;
		default.ConsentFacingDot = 0.5f;
		default.LaunchForce = 2200.0f;
		default.LaunchZBoost = 750.0f;
		default.LaunchForceMultL20 = 1.6f;
		default.CooldownSeconds = 10.0f;

		default.ImpactBaseDamage = 200.0f;
		default.ImpactRadius = 400.0f;
		default.ImpactRadiusMultL10 = 1.5f;
		default.ImpactSpeedDamageScale = 0.25f;
		default.ImpactDamagePerLevel = 0.05f;

		default.PayloadHealOnLanding = 15;
		default.PayloadHealOnLandingL20 = 40;
		default.PayloadArmorOnLanding = 10;

		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

// ===================================================================
// HELPER MANAGEMENT
// ===================================================================

// Spawns if missing (server-side). Safe to call from server hooks.
static function ZTUpgrade_Perk_Fastball_Helper GetHelper(Pawn OwnerPawn)
{
	local ZTUpgrade_Perk_Fastball_Helper H;

	if (KFPawn_Human(OwnerPawn) != None)
	{
		foreach OwnerPawn.ChildActors(class'ZTUpgrade_Perk_Fastball_Helper', H)
			return H;

		H = OwnerPawn.Spawn(class'ZTUpgrade_Perk_Fastball_Helper', OwnerPawn);
	}

	return H;
}

// Never spawns - safe for client-side simulated hooks.
static simulated function ZTUpgrade_Perk_Fastball_Helper FindHelper(Pawn OwnerPawn)
{
	local ZTUpgrade_Perk_Fastball_Helper H;

	if (KFPawn_Human(OwnerPawn) != None)
	{
		foreach OwnerPawn.ChildActors(class'ZTUpgrade_Perk_Fastball_Helper', H)
			return H;
	}

	return None;
}

static simulated function InitiateWeapon(int upgLevel, KFWeapon KFW, KFPawn OwnerPawn)
{
	local ZTUpgrade_Perk_Fastball_Helper H;

	if (KFPawn_Human(OwnerPawn) != None && OwnerPawn.Role == ROLE_Authority)
	{
		H = GetHelper(OwnerPawn);
		if (H != None)
			H.SetPerkLevel(upgLevel);
	}
}

static simulated function DeleteHelperClass(Pawn OwnerPawn)
{
	local ZTUpgrade_Perk_Fastball_Helper H;

	if (KFPawn_Human(OwnerPawn) != None)
	{
		foreach OwnerPawn.ChildActors(class'ZTUpgrade_Perk_Fastball_Helper', H)
			H.Destroy();
	}
}

// ===================================================================
// DAMAGE HOOK - scale impact shockwave per perk level
// ===================================================================
static function ModifyDamageGiven(out int InDamage, int DefaultDamage, int upgLevel,
	optional Actor DamageCauser, optional KFPawn_Monster MyKFPM,
	optional KFPlayerController DamageInstigator, optional class<KFDamageType> DamageType,
	optional int HitZoneIdx, optional KFWeapon MyKFW)
{
	if (DamageType == None || !ClassIsChildOf(DamageType, class'ZTDT_Fastball_Impact'))
		return;

	InDamage += Round(float(DefaultDamage) * default.ImpactDamagePerLevel * float(upgLevel));
}

defaultproperties
{
	bShouldLocalize=True
	LocPackage="ZedternalTempered"
	LocSection="ZTUpgrade_Perk_Fastball"
	LocalizeDescriptionLineCount=5

	UpgradeName="Fastball"
	upgradeDescription(0)="Aim at a teammate looking back at you and press your <font color=\"#15d7fa\">Fastball</font> key (default <font color=\"#ffc832\">M</font>) to <font color=\"#ff3399\">LAUNCH THEM</font> along your aim. <font color=\"#be4d25\">10s</font> cooldown."
	upgradeDescription(1)="Launched allies take <font color=\"#77d914\">no fall damage</font> and land as an explosive <font color=\"#15d7fa\">shockwave</font> that heals them on arrival."
	upgradeDescription(2)="Shockwave damage <font color=\"#77d914\">+%x%%</font> (plus a bonus from landing speed)."
	upgradeDescription(3)="<font color=\"#8B0000\">LEVEL 10:</font> Shockwave radius <font color=\"#77d914\">+50%</font>."
	upgradeDescription(4)="<font color=\"#8B0000\">LEVEL 20:</font> Launch force <font color=\"#77d914\">+60%</font> and the landing heal is <font color=\"#77d914\">greatly increased</font>."

	// Drives the dynamic %x% in line 2 (impact damage bonus = 5 * level).
	PerkBonus(2)=(baseValue=0, incValue=5, maxValue=-1)

	$10'
	$10'
	$10'
	$10'
	$10'
	$10'
	$10'
	$10'
	$10'
	$10'
	$10'
	$10'
	$10'
	$10'
	$10'
	$10'
	$10'
	$10'
	$10'
	$10'
	$10'

	Name="Default__ZTUpgrade_Perk_Fastball"
}
