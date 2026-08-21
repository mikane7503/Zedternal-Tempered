// ===================================================================
// ZTPawn_ZedCrawler_Broodmother
//
// A large, elite Crawler that periodically spawns mini-crawlers.
// Uses the CrawlerKing mesh with a toxic gas particle aura.
//
// Behavior:
//   - Trickle spawns 2 mini-crawlers every ~8 seconds
//   - At 25% health: enters flee mode (faster, regens, spawns more)
//   - At 40% health: exits flee mode, re-engages
//   - On death: bursts 6 mini-crawlers
//   - Only one Broodmother can exist at a time
// ===================================================================
class ZTPawn_ZedCrawler_Broodmother extends KFPawn_ZedCrawlerKing;

// ----- Visual -----
var string AuraTemplatePath;
var ParticleSystemComponent AuraEffect;

// ----- Spawning -----
var float TrickleSpawnInterval;
var float TrickleSpawnInterval_Flee;
var int TrickleSpawnCount;
var int DeathBurstCount;
var class<KFPawn_Monster> MiniCrawlerClass;

// ----- Flee / Regen -----
var bool bFleeing;
var float FleeHealthPct;
var float ReEngageHealthPct;
var float RegenPerSecond;
var float CachedGroundSpeed;
var float CachedSprintSpeed;
var float FleeSpeedMultiplier;

// ----- Damage Resistance -----
var const float ExtraDamageResistance;

// ===================================================================
// Naming
// ===================================================================
static function string GetLocalizedName()
{
	return "Broodmother";
}

// ===================================================================
// Initialization
// ===================================================================
simulated function PostBeginPlay()
{
	local ZTPawn_ZedCrawler_Broodmother OtherBrood;

	IntendedBodyScale = 2.2f;

	super.PostBeginPlay();

	// Singleton enforcement: only one Broodmother at a time
	if (Role == ROLE_Authority)
	{
		foreach WorldInfo.AllPawns(class'ZTPawn_ZedCrawler_Broodmother', OtherBrood)
		{
			if (OtherBrood != self && OtherBrood.IsAliveAndWell())
			{
				Destroy();
				return;
			}
		}
	}

	// Cache normal speeds for flee mode toggle
	CachedGroundSpeed = GroundSpeed;
	CachedSprintSpeed = SprintSpeed;

	// Start trickle spawner (server only)
	if (Role == ROLE_Authority)
	{
		SetTimer(TrickleSpawnInterval, true, nameOf(Timer_TrickleSpawn));
	}

	// Visual: attach particle aura (clients only)
	if (WorldInfo.NetMode != NM_DedicatedServer)
	{
		AttachAuraEffect();
	}
}

// ===================================================================
// Visual: Toxic gas particle aura (loaded at runtime)
// ===================================================================
simulated function AttachAuraEffect()
{
	local ParticleSystem LoadedTemplate;

	if (AuraTemplatePath != "" && Mesh != None)
	{
		LoadedTemplate = ParticleSystem(DynamicLoadObject(AuraTemplatePath, class'ParticleSystem'));
		if (LoadedTemplate != None)
		{
			AuraEffect = WorldInfo.MyEmitterPool.SpawnEmitterMeshAttachment(LoadedTemplate, Mesh, 'Root', true);
		}
	}
}

simulated function CleanupAuraEffect()
{
	if (AuraEffect != None)
	{
		AuraEffect.DeactivateSystem();
		AuraEffect = None;
	}
}

// ===================================================================
// Damage resistance (like Big Crawler)
// ===================================================================
function float GetDamageTypeModifier(class<DamageType> DT)
{
	local float CurrentMod;

	CurrentMod = super.GetDamageTypeModifier(DT);
	return FMax(0.025f, CurrentMod - ExtraDamageResistance);
}

// ===================================================================
// Health monitoring — flee mode
// ===================================================================
function AdjustDamage(out int InDamage, out vector Momentum, Controller InstigatedBy, vector HitLocation, class<DamageType> DamageType, TraceHitInfo HitInfo, Actor DamageCauser)
{
	super.AdjustDamage(InDamage, Momentum, InstigatedBy, HitLocation, DamageType, HitInfo, DamageCauser);

	if (Role == ROLE_Authority && !bFleeing && IsAliveAndWell())
	{
		if (GetHealthPercentage() <= FleeHealthPct)
		{
			EnterFleeMode();
		}
	}
}

function EnterFleeMode()
{
	if (bFleeing)
		return;

	bFleeing = true;

	GroundSpeed = CachedGroundSpeed * FleeSpeedMultiplier;
	SprintSpeed = CachedSprintSpeed * FleeSpeedMultiplier;

	ClearTimer(nameOf(Timer_TrickleSpawn));
	SetTimer(TrickleSpawnInterval_Flee, true, nameOf(Timer_TrickleSpawn));

	SetTimer(1.0f, true, nameOf(Timer_Regen));
	SetTimer(0.5f, true, nameOf(Timer_FleeAI));
}

function ExitFleeMode()
{
	if (!bFleeing)
		return;

	bFleeing = false;

	GroundSpeed = CachedGroundSpeed;
	SprintSpeed = CachedSprintSpeed;

	ClearTimer(nameOf(Timer_TrickleSpawn));
	SetTimer(TrickleSpawnInterval, true, nameOf(Timer_TrickleSpawn));

	ClearTimer(nameOf(Timer_Regen));
	ClearTimer(nameOf(Timer_FleeAI));
}

// ===================================================================
// Flee AI: periodically clear the controller's enemy
// ===================================================================
function Timer_FleeAI()
{
	local ZTAIController_ZedCrawler_Broodmother BroodAI;

	if (!bFleeing || !IsAliveAndWell())
	{
		ClearTimer(nameOf(Timer_FleeAI));
		return;
	}

	BroodAI = ZTAIController_ZedCrawler_Broodmother(Controller);
	if (BroodAI != None)
	{
		BroodAI.ClearEnemyForFlee();
	}
}

// ===================================================================
// Regeneration timer (flee mode only)
// ===================================================================
function Timer_Regen()
{
	local int HealAmount;

	if (!IsAliveAndWell() || !bFleeing)
	{
		ClearTimer(nameOf(Timer_Regen));
		return;
	}

	HealAmount = Max(1, int(float(HealthMax) * RegenPerSecond));
	Health = Min(Health + HealAmount, HealthMax);

	if (GetHealthPercentage() >= ReEngageHealthPct)
	{
		ExitFleeMode();
	}
}

// ===================================================================
// Trickle spawner
// ===================================================================
function Timer_TrickleSpawn()
{
	if (!IsAliveAndWell())
	{
		ClearTimer(nameOf(Timer_TrickleSpawn));
		return;
	}

	SpawnMiniCrawlers(TrickleSpawnCount);
}

// ===================================================================
// Death burst
// ===================================================================
function bool Died(Controller Killer, class<DamageType> DamageType, vector HitLocation)
{
	if (Role == ROLE_Authority)
	{
		SpawnMiniCrawlers(DeathBurstCount);
	}

	CleanupAuraEffect();
	return super.Died(Killer, DamageType, HitLocation);
}

// ===================================================================
// Core spawning logic for mini-crawlers
// ===================================================================
function SpawnMiniCrawlers(int Count)
{
	local int i;
	local vector SpawnLoc;
	local rotator SpawnRot;
	local KFPawn_Monster SpawnedCrawler;
	local float Angle, Radius;

	if (MiniCrawlerClass == None)
		return;

	for (i = 0; i < Count; ++i)
	{
		Angle = (6.2832f / float(Count)) * float(i) + FRand() * 0.5f;
		Radius = 120.0f + FRand() * 60.0f;

		SpawnLoc.X = Location.X + Cos(Angle) * Radius;
		SpawnLoc.Y = Location.Y + Sin(Angle) * Radius;
		SpawnLoc.Z = Location.Z;

		SpawnRot = Rotation;

		SpawnedCrawler = Spawn(MiniCrawlerClass, , , SpawnLoc, SpawnRot, , true);
		if (SpawnedCrawler != None)
		{
			SpawnedCrawler.SpawnDefaultController();
		}
	}
}

simulated function CancelExplosion()
{
	super.CancelExplosion();
}

function bool CanBeGrabbed(KFPawn GrabbingPawn, optional bool bIgnoreFalling, optional bool bAllowSameTeamGrab)
{
	return False;
}

simulated event Destroyed()
{
	CleanupAuraEffect();
	ClearTimer(nameOf(Timer_TrickleSpawn));
	ClearTimer(nameOf(Timer_Regen));
	ClearTimer(nameOf(Timer_FleeAI));
	super.Destroyed();
}

defaultproperties
{
	ControllerClass=class'ZedternalTempered.ZTAIController_ZedCrawler_Broodmother'
	DifficultySettings=class'ZedternalTempered.ZTDifficulty_Crawler_Broodmother'

	AuraTemplatePath="ZED_Bloat_ARCH.FX_Gas_AOE_01"

	bLargeZed=True
	bKnockdownWhenJumpedOn=False
	MinSpawnSquadSizeType=EST_Large
	Health=2500
	DoshValue=150
	Mass=500.0f
	GroundSpeed=280.0f
	SprintSpeed=340.0f
	ExtraDamageResistance=0.40f

	XPValues(0)=80
	XPValues(1)=100
	XPValues(2)=100
	XPValues(3)=100

	HitZones(0)=(GoreHealth=750)
	PenetrationResistance=5.0f

	MiniCrawlerClass=class'ZedternalReborn.WMPawn_ZedCrawler_Mini'
	TrickleSpawnCount=2
	TrickleSpawnInterval=8.0f
	TrickleSpawnInterval_Flee=4.0f
	DeathBurstCount=6

	bFleeing=False
	FleeHealthPct=0.25f
	ReEngageHealthPct=0.40f
	RegenPerSecond=0.01f
	FleeSpeedMultiplier=1.5f

	IncapSettings(AF_Stun)=(Vulnerability=(0.4, 0.55, 0.2, 0.2, 0.55), Cooldown=10.0, Duration=1.5)
	IncapSettings(AF_Knockdown)=(Vulnerability=(0.3), Cooldown=8.0)
	IncapSettings(AF_Stumble)=(Vulnerability=(0.3), Cooldown=5.0)
	IncapSettings(AF_GunHit)=(Vulnerability=(0.5), Cooldown=1.0)
	IncapSettings(AF_MeleeHit)=(Vulnerability=(0.5), Cooldown=1.5)
	IncapSettings(AF_Poison)=(Vulnerability=(5.0), Cooldown=10.0, Duration=4.0)
	IncapSettings(AF_Microwave)=(Vulnerability=(0.3), Cooldown=10.0, Duration=2.0)
	IncapSettings(AF_FirePanic)=(Vulnerability=(1.5), Cooldown=10.0, Duration=3.0)
	IncapSettings(AF_EMP)=(Vulnerability=(1.5), Cooldown=8.0, Duration=3.0)
	IncapSettings(AF_Freeze)=(Vulnerability=(1.0), Cooldown=8.0, Duration=2.0)
	IncapSettings(AF_Snare)=(Vulnerability=(5.0, 5.0, 5.0, 5.0), Cooldown=8.0, Duration=3.0)
	IncapSettings(AF_Bleed)=(Vulnerability=(1.0))
	IncapSettings(AF_Shrink)=(Vulnerability=(0.5))

	ShrinkEffectModifier=0.5f
	ParryResistance=4

	EliteAIType.Empty
	ElitePawnClass.Empty

	Name="Default__ZTPawn_ZedCrawler_Broodmother"
}
