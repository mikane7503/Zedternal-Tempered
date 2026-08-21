// ===================================================================
// DKUpgrade_Perk_Fastball_Helper - Target pick, launch, landing watch
//
// Owned by the LAUNCHER's pawn. Server-side logic + client HUD RPC:
//   - TryLaunch() from DKPlayerController.ServerActivateFastball:
//     picks the teammate in the launcher's aim cone within range,
//     enforces consent (mutual facing by default), applies velocity,
//     spawns a DKFastball_PayloadMarker on the payload and starts a
//     landing poll.
//   - Landing poll (0.1s): tracks peak fall speed; when the payload
//     stops falling, detonates the shockwave (credited to launcher),
//     heals/armors the payload, cleans up the marker.
//   - HUD: card-stack cooldown card via ClientFastballHUD ->
//     DKHudWrapper (states 0 ready / 2 cooldown).
// Landing detection is poll-based on purpose: no DKPawn_Human edits,
// no Landed() overrides, robust against death/disconnect mid-flight.
// Replication: ROLE_SimulatedProxy + bOnlyRelevantToOwner so the
// reliable client HUD RPC reaches the owning client (Hyde pattern).
// ===================================================================
class DKUpgrade_Perk_Fastball_Helper extends Actor;

var KFPawn_Human OwnerPawn;
var int PerkLevel;

var bool bOnCooldown;
var bool bHUDInitialized;  // first READY push done

// --- Skill overrides (set by DKUpgrade_Skill_* via setters; Possess pattern) ---
var float SkillCooldownMult;    // Windmill Wind-Up
var float SkillForceMult;       // Heater
var float SkillRadiusMult;      // Ground Rule Double
var int SkillBullpenLevel;      // Bullpen (1: reset on landing kill, 2: reset on any landing)
var int SkillPayloadCareLevel;  // Fastball Special (1: double heal +15 armor, 2: +30 armor)
var int SkillReliefLevel;       // Relief Pitcher (buff after payload lands)
var float ReliefEndTime;        // read by DKUpgrade_Skill_ReliefPitcher conditional hooks

// Active flight tracking
var KFPawn_Human PayloadPawn;
var DKFastball_PayloadMarker PayloadMarker;
var bool bWatchingFlight;
var bool bPayloadLeftGround;

const POLL_INTERVAL = 0.1f;

const FB_HUD_HIDDEN = 255;
const FB_HUD_READY  = 0;
const FB_HUD_COOLDOWN = 2;

// ===================================================================
// LIFECYCLE
// ===================================================================
simulated event PostBeginPlay()
{
	super.PostBeginPlay();
	OwnerPawn = KFPawn_Human(Owner);
}

function SetPerkLevel(int L)
{
	PerkLevel = L;

	if (!bHUDInitialized)
	{
		bHUDInitialized = True;
		PushHUD(FB_HUD_READY, 0.0f);
	}
}

// --- Skill setters (0 level = revert to neutral) ---
function SetSkillCooldownMult(float M) { SkillCooldownMult = (M > 0.0f) ? M : 1.0f; }
function SetSkillForceMult(float M) { SkillForceMult = (M > 0.0f) ? M : 1.0f; }
function SetSkillRadiusMult(float M) { SkillRadiusMult = (M > 0.0f) ? M : 1.0f; }
function SetSkillBullpenLevel(int L) { SkillBullpenLevel = Clamp(L, 0, 2); }
function SetSkillPayloadCareLevel(int L) { SkillPayloadCareLevel = Clamp(L, 0, 2); }
function SetSkillReliefLevel(int L) { SkillReliefLevel = Clamp(L, 0, 2); }

function KFPlayerController GetPC()
{
	if (OwnerPawn != None)
		return KFPlayerController(OwnerPawn.Controller);
	return None;
}

// ===================================================================
// LAUNCH
// ===================================================================
function TryLaunch()
{
	local KFPawn_Human Target;
	local vector AimDir, LaunchVel;
	local float Force;

	if (OwnerPawn == None || OwnerPawn.Health <= 0)
		return;

	if (bOnCooldown)
	{
		class'DKMessageManager'.static.SendMinor(GetPC(), "Fastball: winding up, not ready yet.");
		return;
	}

	if (bWatchingFlight)
	{
		class'DKMessageManager'.static.SendMinor(GetPC(), "Fastball: your last throw is still airborne!");
		return;
	}

	Target = PickTarget();
	if (Target == None)
	{
		class'DKMessageManager'.static.SendMinor(GetPC(), "Fastball: no willing teammate in reach (they must be close and looking at you).");
		return;
	}

	AimDir = vector(OwnerPawn.GetViewRotation());

	Force = class'DKUpgrade_Perk_Fastball'.default.LaunchForce;
	if (PerkLevel >= 20)
		Force *= class'DKUpgrade_Perk_Fastball'.default.LaunchForceMultL20;
	Force *= SkillForceMult;

	LaunchVel = AimDir * Force;
	LaunchVel.Z += class'DKUpgrade_Perk_Fastball'.default.LaunchZBoost;

	// Payload marker: fall damage shield (zeroed in both DKGameInfos'
	// ReduceDamage) + flight bookkeeping
	PayloadMarker = Target.Spawn(class'DKFastball_PayloadMarker', Target);
	if (PayloadMarker != None)
	{
		PayloadMarker.LauncherPC = GetPC();
		PayloadMarker.LauncherPerkLevel = PerkLevel;
	}

	Target.SetPhysics(PHYS_Falling);
	Target.Velocity = LaunchVel;

	PayloadPawn = Target;
	bWatchingFlight = True;
	bPayloadLeftGround = False;
	SetTimer(POLL_INTERVAL, True, NameOf(PollFlight));

	bOnCooldown = True;
	SetTimer(class'DKUpgrade_Perk_Fastball'.default.CooldownSeconds * SkillCooldownMult, False, NameOf(EndCooldown));
	PushHUD(FB_HUD_COOLDOWN, class'DKUpgrade_Perk_Fastball'.default.CooldownSeconds * SkillCooldownMult);

	class'DKMessageManager'.static.SendMinor(GetPC(), "FASTBALL:" @ Target.PlayerReplicationInfo.PlayerName @ "is airborne!");
	class'DKMessageManager'.static.SendCritical(KFPlayerController(Target.Controller), "FASTBALL! You are the projectile now!");
}

// Pick the teammate the launcher is aiming at, in range, consenting.
function KFPawn_Human PickTarget()
{
	local KFPawn_Human Candidate, Best;
	local vector ToTarget, LauncherAim, TargetAim;
	local float Dist, BestDot, D;

	LauncherAim = vector(OwnerPawn.GetViewRotation());
	BestDot = class'DKUpgrade_Perk_Fastball'.default.TargetConeDot;

	foreach WorldInfo.AllPawns(class'KFGame.KFPawn_Human', Candidate)
	{
		if (Candidate == OwnerPawn || Candidate.Health <= 0)
			continue;

		// Players only - no launching bots' turrets or parked bodies
		if (PlayerController(Candidate.Controller) == None)
			continue;

		ToTarget = Candidate.Location - OwnerPawn.Location;
		Dist = VSize(ToTarget);
		if (Dist > class'DKUpgrade_Perk_Fastball'.default.TargetRange)
			continue;

		D = Normal(ToTarget) dot LauncherAim;
		if (D < BestDot)
			continue;

		// Consent: mutual facing (mode 1)
		if (class'DKUpgrade_Perk_Fastball'.default.ConsentMode == 1)
		{
			TargetAim = vector(Candidate.GetViewRotation());
			if ((Normal(OwnerPawn.Location - Candidate.Location) dot TargetAim)
				< class'DKUpgrade_Perk_Fastball'.default.ConsentFacingDot)
				continue;
		}

		Best = Candidate;
		BestDot = D;
	}

	return Best;
}

function EndCooldown()
{
	bOnCooldown = False;
	PushHUD(FB_HUD_READY, 0.0f);
	class'DKMessageManager'.static.SendMinor(GetPC(), "Fastball: ready.");
}

// ===================================================================
// FLIGHT WATCH + IMPACT
// ===================================================================
function PollFlight()
{
	local float Speed;

	// Payload died / left mid-flight: clean up quietly
	if (PayloadPawn == None || PayloadPawn.Health <= 0 || PayloadPawn.bDeleteMe)
	{
		EndFlightWatch();
		return;
	}

	if (PayloadPawn.Physics == PHYS_Falling)
	{
		bPayloadLeftGround = True;
		Speed = VSize(PayloadPawn.Velocity);
		if (PayloadMarker != None && Speed > PayloadMarker.PeakSpeed)
			PayloadMarker.PeakSpeed = Speed;
		return;
	}

	// Not falling: either landed (after having flown) or the launch
	// never took (blocked into a wall frame-one) - both end the watch.
	if (bPayloadLeftGround)
		DetonateLanding();

	EndFlightWatch();
}

function DetonateLanding()
{
	local float Damage, Radius, PeakSpeed;
	local int HealAmount;
	local KFPlayerController LauncherPC;

	PeakSpeed = (PayloadMarker != None) ? PayloadMarker.PeakSpeed : 0.0f;
	LauncherPC = GetPC();

	// Damage: base + landing-speed bonus. Per-level scaling is applied by
	// DKUpgrade_Perk_Fastball.ModifyDamageGiven via DKDT_Fastball_Impact.
	Damage = class'DKUpgrade_Perk_Fastball'.default.ImpactBaseDamage;
	Damage += Damage * class'DKUpgrade_Perk_Fastball'.default.ImpactSpeedDamageScale * (PeakSpeed / 1000.0f);

	Radius = class'DKUpgrade_Perk_Fastball'.default.ImpactRadius;
	if (PerkLevel >= 10)
		Radius *= class'DKUpgrade_Perk_Fastball'.default.ImpactRadiusMultL10;
	Radius *= SkillRadiusMult;

	PayloadPawn.HurtRadius(Damage, Radius, class'DKDT_Fastball_Impact', 2000.0f,
		PayloadPawn.Location, PayloadPawn, LauncherPC);

	// Skill: Bullpen - landing kills (Deluxe: any landing) reset the cooldown
	if (SkillBullpenLevel >= 2
		|| (SkillBullpenLevel == 1 && CountDeadMonstersNear(PayloadPawn.Location, Radius) > 0))
	{
		if (bOnCooldown)
		{
			ClearTimer(NameOf(EndCooldown));
			EndCooldown();
		}
	}

	// Skill: Relief Pitcher - launcher buff window after the landing
	if (SkillReliefLevel > 0)
		ReliefEndTime = WorldInfo.TimeSeconds + 6.0f;

	// Payload reward: landing patches them up
	HealAmount = (PerkLevel >= 20)
		? class'DKUpgrade_Perk_Fastball'.default.PayloadHealOnLandingL20
		: class'DKUpgrade_Perk_Fastball'.default.PayloadHealOnLanding;

	// Skill: Fastball Special - payload care doubled + bonus armor
	if (SkillPayloadCareLevel > 0)
		HealAmount *= 2;

	if (HealAmount > 0)
		PayloadPawn.HealDamage(HealAmount, LauncherPC, class'KFDT_Healing');

	if (class'DKUpgrade_Perk_Fastball'.default.PayloadArmorOnLanding > 0)
	{
		PayloadPawn.Armor = Min(PayloadPawn.MaxArmor,
			PayloadPawn.Armor + class'DKUpgrade_Perk_Fastball'.default.PayloadArmorOnLanding);
	}

	if (SkillPayloadCareLevel > 0)
	{
		PayloadPawn.Armor = Min(PayloadPawn.MaxArmor,
			PayloadPawn.Armor + ((SkillPayloadCareLevel >= 2) ? 30 : 15));
	}

	class'DKMessageManager'.static.SendMinor(KFPlayerController(PayloadPawn.Controller), "Fastball: STUCK THE LANDING!");
}

// Bullpen kill check: dead monsters near the landing right after the shockwave.
function int CountDeadMonstersNear(vector Loc, float Radius)
{
	local KFPawn_Monster KFPM;
	local int Count;

	foreach WorldInfo.AllPawns(class'KFGame.KFPawn_Monster', KFPM, Loc, Radius)
	{
		if (KFPM.Health <= 0)
			++Count;
	}

	return Count;
}

function EndFlightWatch()
{
	ClearTimer(NameOf(PollFlight));
	bWatchingFlight = False;
	bPayloadLeftGround = False;

	if (PayloadMarker != None)
	{
		PayloadMarker.Destroy();
		PayloadMarker = None;
	}

	PayloadPawn = None;
}

// ===================================================================
// HUD PUSH (server builds state, client renders - HUD_Element_Guide)
// ===================================================================
function PushHUD(byte State, float Duration)
{
	ClientFastballHUD(State, Duration);
}

reliable client function ClientFastballHUD(byte State, float Duration)
{
	local KFPlayerController LocalPC;
	local DKHudWrapper HUD;

	LocalPC = KFPlayerController(GetALocalPlayerController());
	if (LocalPC == None)
		return;

	HUD = class'DKHudWrapper'.static.GetReaperHUD(LocalPC);
	if (HUD == None)
		return;

	if (State == FB_HUD_HIDDEN)
		HUD.ClearFastballDisplay();
	else
		HUD.UpdateFastballDisplay(State, Duration);
}

// ===================================================================
// CLEANUP
// ===================================================================
simulated function Destroyed()
{
	if (Role == ROLE_Authority)
	{
		EndFlightWatch();
		ClientFastballHUD(FB_HUD_HIDDEN, 0.0f);
	}

	Super.Destroyed();
}

defaultproperties
{
	RemoteRole=ROLE_SimulatedProxy
	bOnlyRelevantToOwner=True
	bAlwaysRelevant=False
	bSkipActorPropertyReplication=False
	bHidden=True
	PerkLevel=1
	SkillCooldownMult=1.0f
	SkillForceMult=1.0f
	SkillRadiusMult=1.0f

	Name="Default__DKUpgrade_Perk_Fastball_Helper"
}
