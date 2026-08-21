// ===================================================================
// ZTWish_Buff - Wishmaster effect carrier, attached to the WISH TARGET
// (any player, not just Wishmaster owners).
//
// Holds:
//   - PermHPDelta / WaveHPDelta:     max health mods (permanent / next-wave)
//   - PermArmorDelta:                max armor mod (permanent)
//   - WaveSpeedMult:                 ground speed multiplier (next-wave)
//   - GuardianCharge:                1 = survive next lethal hit at 1 HP
//   - CurseFirstHit:                 1 = next hit taken is doubled
//
// ZR recalculates HealthMax / MaxArmor / GroundSpeed from the target's
// own upgrades at various points, silently wiping direct edits. This
// carrier RE-ASSERTS its deltas whenever it detects a recalc (value
// changed since we last applied). Guardian/Curse are consumed by
// ZTGameInfo_Endless(.ReduceDamage) - MIRRORED in both GameInfos.
//
// Wave-scoped effects expire when the trader opens again.
// ===================================================================
class ZTWish_Buff extends Actor;

var int PermHPDelta;
var int WaveHPDelta;
var int PermArmorDelta;
var float WaveSpeedMult;   // 1.0 = neutral
var int GuardianCharge;
var int CurseFirstHit;

// Re-assert bookkeeping
var int LastSeenHealthMax;
var int LastSeenMaxArmor;
var float LastSeenGroundSpeed;
var bool bWasTraderOpen;

const TICK_INTERVAL = 0.25f;

simulated event PostBeginPlay()
{
	super.PostBeginPlay();
	WaveSpeedMult = 1.0f;
	SetTimer(TICK_INTERVAL, True, NameOf(AssertTick));
}

// -------------------------------------------------------------------
// Grant entry points (called by the Wishmaster helper)
// -------------------------------------------------------------------
function AddPermHP(int Delta)
{
	local KFPawn_Human KFPH;

	KFPH = KFPawn_Human(Owner);
	if (KFPH == None)
		return;

	PermHPDelta += Delta;
	KFPH.HealthMax = Max(1, KFPH.HealthMax + Delta);
	if (Delta > 0)
		KFPH.Health = Min(KFPH.Health + Delta, KFPH.HealthMax);
	else
		KFPH.Health = Min(KFPH.Health, KFPH.HealthMax);
	LastSeenHealthMax = KFPH.HealthMax;
}

function AddWaveHP(int Delta)
{
	local KFPawn_Human KFPH;

	KFPH = KFPawn_Human(Owner);
	if (KFPH == None)
		return;

	WaveHPDelta += Delta;
	KFPH.HealthMax = Max(1, KFPH.HealthMax + Delta);
	if (Delta > 0)
		KFPH.Health = Min(KFPH.Health + Delta, KFPH.HealthMax);
	else
		KFPH.Health = Min(KFPH.Health, KFPH.HealthMax);
	LastSeenHealthMax = KFPH.HealthMax;
}

function AddPermArmor(int Delta)
{
	local KFPawn_Human KFPH;

	KFPH = KFPawn_Human(Owner);
	if (KFPH == None)
		return;

	PermArmorDelta += Delta;
	KFPH.MaxArmor = Max(0, KFPH.MaxArmor + Delta);
	KFPH.Armor = Min(KFPH.Armor, KFPH.MaxArmor);
	LastSeenMaxArmor = KFPH.MaxArmor;
}

function SetWaveSpeed(float Mult)
{
	local KFPawn_Human KFPH;

	KFPH = KFPawn_Human(Owner);
	if (KFPH == None || Mult <= 0.0f)
		return;

	WaveSpeedMult = Mult;
	KFPH.GroundSpeed *= WaveSpeedMult;
	LastSeenGroundSpeed = KFPH.GroundSpeed;
}

function GrantGuardian() { GuardianCharge = 1; }
function GrantCurse() { CurseFirstHit = 1; }

// -------------------------------------------------------------------
// Re-assert + wave expiry
// -------------------------------------------------------------------
function AssertTick()
{
	local KFPawn_Human KFPH;
	local KFGameReplicationInfo KFGRI;
	local bool bTraderOpen;

	KFPH = KFPawn_Human(Owner);
	if (KFPH == None || KFPH.Health <= 0)
	{
		Destroy();
		return;
	}

	// --- Wave-scoped expiry: trader opening ends "next wave" effects ---
	KFGRI = KFGameReplicationInfo(WorldInfo.GRI);
	if (KFGRI != None)
	{
		bTraderOpen = KFGRI.bTraderIsOpen;
		if (bTraderOpen && !bWasTraderOpen)
			ExpireWaveEffects(KFPH);
		bWasTraderOpen = bTraderOpen;
	}

	// --- Re-assert max health after external recalc ---
	if ((PermHPDelta != 0 || WaveHPDelta != 0) && KFPH.HealthMax != LastSeenHealthMax)
	{
		KFPH.HealthMax = Max(1, KFPH.HealthMax + PermHPDelta + WaveHPDelta);
		KFPH.Health = Min(KFPH.Health, KFPH.HealthMax);
		LastSeenHealthMax = KFPH.HealthMax;
	}

	// --- Re-assert max armor after external recalc ---
	if (PermArmorDelta != 0 && KFPH.MaxArmor != LastSeenMaxArmor)
	{
		KFPH.MaxArmor = Max(0, KFPH.MaxArmor + PermArmorDelta);
		KFPH.Armor = Min(KFPH.Armor, KFPH.MaxArmor);
		LastSeenMaxArmor = KFPH.MaxArmor;
	}

	// --- Re-assert speed multiplier after external recalc ---
	if (WaveSpeedMult != 1.0f && KFPH.GroundSpeed != LastSeenGroundSpeed)
	{
		KFPH.GroundSpeed *= WaveSpeedMult;
		LastSeenGroundSpeed = KFPH.GroundSpeed;
	}

	MaybeSelfDestruct();
}

function ExpireWaveEffects(KFPawn_Human KFPH)
{
	if (WaveHPDelta != 0)
	{
		KFPH.HealthMax = Max(1, KFPH.HealthMax - WaveHPDelta);
		KFPH.Health = Min(KFPH.Health, KFPH.HealthMax);
		WaveHPDelta = 0;
		LastSeenHealthMax = KFPH.HealthMax;
	}

	if (WaveSpeedMult != 1.0f)
	{
		KFPH.GroundSpeed /= WaveSpeedMult;
		WaveSpeedMult = 1.0f;
		LastSeenGroundSpeed = KFPH.GroundSpeed;
	}

	// Guardian / Curse are "next wave" scoped too - unspent charges lapse.
	GuardianCharge = 0;
	CurseFirstHit = 0;
}

function MaybeSelfDestruct()
{
	if (PermHPDelta == 0 && WaveHPDelta == 0 && PermArmorDelta == 0
		&& WaveSpeedMult == 1.0f && GuardianCharge == 0 && CurseFirstHit == 0)
	{
		Destroy();
	}
}

defaultproperties
{
	bHidden=True
	RemoteRole=ROLE_None

	Name="Default__ZTWish_Buff"
}
