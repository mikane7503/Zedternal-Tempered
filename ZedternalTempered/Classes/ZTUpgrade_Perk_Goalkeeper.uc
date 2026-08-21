// ===================================================================
// ZTUpgrade_Perk_Goalkeeper - "Catch it and throw it back"
//
// Active (dedicated key - default N, ActivateGoalkeeper):
//   - No charge held: opens a short CATCH WINDOW. Any hostile zed
//     projectile (Husk fireballs, puke mines, boss rockets - config
//     keyword list) entering the front cone within range is caught
//     and stored. Missing the window puts the catch on cooldown.
//   - Charge held: HURLS the caught projectile back along your aim
//     as a player-owned fireball (ZTProj_Goalkeeper_Return).
//
// Passive: returned projectile damage +%x% per level (via
// ModifyDamageGiven gating on ZTDT_Goalkeeper_Return).
// Level 10: every catch restores armor.
// Level 20: PERFECT catches (projectile caught very close to you)
// return as a 3-projectile barrage.
//
// All runtime state (window, cooldown, stored charge, scanning) lives
// in ZTUpgrade_Perk_Goalkeeper_Helper. This class is the upgrade hook
// surface + helper management + config.
// ===================================================================
class ZTUpgrade_Perk_Goalkeeper extends ZTUpgrade_Perk
	config(ZedternalUnlimited);

// --- Catch tunables ---
var config float CatchWindowDuration;    // seconds the catch window stays open
var config float CatchRange;             // uu - max distance to catch
var config float CatchConeDot;           // facing dot gate (0.5 = ~60 degree half-angle)
var config float CatchCooldown;          // seconds after a MISSED window
var config float PerfectCatchRange;      // uu - catches inside this distance are PERFECT

// --- Return throw tunables ---
var config float ReturnDamagePerLevel;   // fraction added per perk level (0.05 = +5%/level)
var config int PerfectBarrageCount;      // projectiles returned on a perfect catch at level 20
var config float PerfectBarrageSpreadDeg; // horizontal spread of the barrage in degrees

// --- Level 10 ---
var config int ArmorPerCatch;            // armor restored per successful catch

// --- Catchable projectile filter ---
// A hostile projectile is catchable if its class name contains any of
// these keywords (case-insensitive). Admins can extend for modded zeds.
var config array<string> CatchableClassKeywords;

var config int MODEVERSION;

// ===================================================================
// CONFIG SEED
// ===================================================================
static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.CatchWindowDuration = 0.6f;
		default.CatchRange = 450.0f;
		default.CatchConeDot = 0.45f;
		default.CatchCooldown = 6.0f;
		default.PerfectCatchRange = 150.0f;

		default.ReturnDamagePerLevel = 0.05f;
		default.PerfectBarrageCount = 3;
		default.PerfectBarrageSpreadDeg = 8.0f;

		default.ArmorPerCatch = 10;

		default.CatchableClassKeywords.Length = 0;
		default.CatchableClassKeywords.AddItem("Husk_Fireball");
		default.CatchableClassKeywords.AddItem("HuskFireball");
		default.CatchableClassKeywords.AddItem("PukeMine");
		default.CatchableClassKeywords.AddItem("Rocket_Patriarch");
		default.CatchableClassKeywords.AddItem("HansGrenade");
		default.CatchableClassKeywords.AddItem("HansNade");
		default.CatchableClassKeywords.AddItem("Missile");

		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

// ===================================================================
// HELPER MANAGEMENT
// ===================================================================

// Spawns if missing (server-side). Safe to call from server hooks.
static function ZTUpgrade_Perk_Goalkeeper_Helper GetHelper(Pawn OwnerPawn)
{
	local ZTUpgrade_Perk_Goalkeeper_Helper H;

	if (KFPawn_Human(OwnerPawn) != None)
	{
		foreach OwnerPawn.ChildActors(class'ZTUpgrade_Perk_Goalkeeper_Helper', H)
			return H;

		H = OwnerPawn.Spawn(class'ZTUpgrade_Perk_Goalkeeper_Helper', OwnerPawn);
	}

	return H;
}

// Never spawns - safe for client-side simulated hooks.
static simulated function ZTUpgrade_Perk_Goalkeeper_Helper FindHelper(Pawn OwnerPawn)
{
	local ZTUpgrade_Perk_Goalkeeper_Helper H;

	if (KFPawn_Human(OwnerPawn) != None)
	{
		foreach OwnerPawn.ChildActors(class'ZTUpgrade_Perk_Goalkeeper_Helper', H)
			return H;
	}

	return None;
}

static simulated function InitiateWeapon(int upgLevel, KFWeapon KFW, KFPawn OwnerPawn)
{
	local ZTUpgrade_Perk_Goalkeeper_Helper H;

	if (KFPawn_Human(OwnerPawn) != None && OwnerPawn.Role == ROLE_Authority)
	{
		H = GetHelper(OwnerPawn);
		if (H != None)
			H.SetPerkLevel(upgLevel);
	}
}

static simulated function DeleteHelperClass(Pawn OwnerPawn)
{
	local ZTUpgrade_Perk_Goalkeeper_Helper H;

	if (KFPawn_Human(OwnerPawn) != None)
	{
		foreach OwnerPawn.ChildActors(class'ZTUpgrade_Perk_Goalkeeper_Helper', H)
			H.Destroy();
	}
}

// ===================================================================
// DAMAGE HOOK - scale returned projectile damage per perk level
// ===================================================================
static function ModifyDamageGiven(out int InDamage, int DefaultDamage, int upgLevel,
	optional Actor DamageCauser, optional KFPawn_Monster MyKFPM,
	optional KFPlayerController DamageInstigator, optional class<KFDamageType> DamageType,
	optional int HitZoneIdx, optional KFWeapon MyKFW)
{
	if (DamageType == None || !ClassIsChildOf(DamageType, class'ZTDT_Goalkeeper_Return'))
		return;

	InDamage += Round(float(DefaultDamage) * default.ReturnDamagePerLevel * float(upgLevel));
}

defaultproperties
{
	bShouldLocalize=True
	LocPackage="ZedternalTempered"
	LocSection="ZTUpgrade_Perk_Goalkeeper"
	LocalizeDescriptionLineCount=5

	UpgradeName="Goalkeeper"
	upgradeDescription(0)="Press your <font color=\"#15d7fa\">Catch</font> key (default <font color=\"#ffc832\">N</font>) to open a <font color=\"#77d914\">0.6s</font> catch window: hostile projectiles entering your front cone are <font color=\"#15d7fa\">CAUGHT</font>. A missed window has a <font color=\"#be4d25\">6s</font> cooldown."
	upgradeDescription(1)="Press again while holding a catch to <font color=\"#ff3399\">HURL IT BACK</font> as an explosive fireball."
	upgradeDescription(2)="Returned projectiles deal <font color=\"#77d914\">+%x%%</font> damage."
	upgradeDescription(3)="<font color=\"#8B0000\">LEVEL 10:</font> Every catch restores <font color=\"#77d914\">10 Armor</font>."
	upgradeDescription(4)="<font color=\"#8B0000\">LEVEL 20:</font> <font color=\"#FFD700\">Perfect catches</font> (caught at close range) return as a <font color=\"#ff3399\">3-fireball barrage</font>."

	// Drives the dynamic %x% in line 2 (return damage bonus = 5 * level).
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

	Name="Default__ZTUpgrade_Perk_Goalkeeper"
}
