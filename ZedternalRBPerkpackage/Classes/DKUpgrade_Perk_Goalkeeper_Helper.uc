// ===================================================================
// DKUpgrade_Perk_Goalkeeper_Helper - Catch window, charge, throwback
//
// Owned by the perk holder's pawn. Server-side logic + client HUD RPC:
//   - TryActivate() from DKPlayerController.ServerActivateGoalkeeper:
//       no charge -> open catch window (repeating scan timer)
//       charge held -> throw it back along controller aim
//   - Catch scan: DynamicActors(KFProjectile) filtered to hostile,
//     keyword-matched, in-range, in front cone. First hit is caught.
//   - Perfect catch: caught inside PerfectCatchRange.
//   - Level 10+: catches restore armor.
//   - Level 20 + perfect: throw returns a spread barrage.
//   - HUD: card-stack card via ClientGoalkeeperHUD -> DKHudWrapper
//     (states 0 ready / 1 window / 2 cooldown / 3 charge held).
// Replication: ROLE_SimulatedProxy + bOnlyRelevantToOwner so the
// reliable client HUD RPC reaches the owning client (Hyde pattern).
// ===================================================================
class DKUpgrade_Perk_Goalkeeper_Helper extends Actor;

var KFPawn_Human OwnerPawn;
var int PerkLevel;

var bool bWindowOpen;
var bool bOnCooldown;
var bool bHoldingCharge;
var bool bPerfectCharge;
var bool bScanLogged;      // one diagnostic dump per window
var bool bHUDInitialized;  // first READY push done

// --- Skill overrides (set by DKUpgrade_Skill_* via setters; Possess pattern) ---
var float SkillCooldownMult;   // Sticky Gloves
var float SkillRangeMult;      // Sweeper Keeper
var float SkillConeMult;       // Sweeper Keeper (multiplies dot threshold down = wider)
var float SkillPerfectMult;    // Punt
var int SkillDoshPerCatch;     // Interception Bonus
var int SkillCrowdLevel;       // Crowd Favorite (0/1/2)

const SCAN_INTERVAL = 0.05f;

const GK_HUD_HIDDEN = 255;
const GK_HUD_READY  = 0;
const GK_HUD_WINDOW = 1;
const GK_HUD_COOLDOWN = 2;
const GK_HUD_CHARGE = 3;

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
		PushHUD(GK_HUD_READY, 0.0f);
	}
}

// --- Skill setters (0 level = revert to neutral) ---
function SetSkillCooldownMult(float M) { SkillCooldownMult = (M > 0.0f) ? M : 1.0f; }
function SetSkillReach(float RangeM, float ConeM)
{
	SkillRangeMult = (RangeM > 0.0f) ? RangeM : 1.0f;
	SkillConeMult = (ConeM > 0.0f) ? ConeM : 1.0f;
}
function SetSkillPerfectMult(float M) { SkillPerfectMult = (M > 0.0f) ? M : 1.0f; }
function SetSkillDoshPerCatch(int D) { SkillDoshPerCatch = Max(0, D); }
function SetSkillCrowdLevel(int L) { SkillCrowdLevel = Clamp(L, 0, 2); }

function KFPlayerController GetPC()
{
	if (OwnerPawn != None)
		return KFPlayerController(OwnerPawn.Controller);
	return None;
}

// ===================================================================
// ACTIVATION (single key, two states)
// ===================================================================
function TryActivate()
{
	if (OwnerPawn == None || OwnerPawn.Health <= 0)
		return;

	if (bHoldingCharge)
	{
		ThrowCharge();
		return;
	}

	if (bWindowOpen)
	{
		class'DKMessageManager'.static.SendMinor(GetPC(), "Goalkeeper: catch window already open!");
		return;
	}

	if (bOnCooldown)
	{
		class'DKMessageManager'.static.SendMinor(GetPC(), "Goalkeeper: recovering from the last miss.");
		return;
	}

	OpenCatchWindow();
}

// ===================================================================
// CATCH WINDOW
// ===================================================================
function OpenCatchWindow()
{
	bWindowOpen = True;
	bScanLogged = False;
	SetTimer(SCAN_INTERVAL, True, NameOf(ScanForProjectiles));
	SetTimer(class'DKUpgrade_Perk_Goalkeeper'.default.CatchWindowDuration, False, NameOf(CloseCatchWindow));
	PushHUD(GK_HUD_WINDOW, class'DKUpgrade_Perk_Goalkeeper'.default.CatchWindowDuration);
	class'DKMessageManager'.static.SendMinor(GetPC(), "Goalkeeper: CATCH!");
}

function CloseCatchWindow()
{
	if (!bWindowOpen)
		return;

	bWindowOpen = False;
	ClearTimer(NameOf(ScanForProjectiles));

	// Missed - start cooldown
	bOnCooldown = True;
	SetTimer(class'DKUpgrade_Perk_Goalkeeper'.default.CatchCooldown * SkillCooldownMult, False, NameOf(EndCooldown));
	PushHUD(GK_HUD_COOLDOWN, class'DKUpgrade_Perk_Goalkeeper'.default.CatchCooldown * SkillCooldownMult);
	class'DKMessageManager'.static.SendMinor(GetPC(), "Goalkeeper: nothing caught.");
}

function EndCooldown()
{
	bOnCooldown = False;
	PushHUD(GK_HUD_READY, 0.0f);
	class'DKMessageManager'.static.SendMinor(GetPC(), "Goalkeeper: ready.");
}

function ScanForProjectiles()
{
	local KFProjectile Proj;
	local vector ToProj, FaceDir;
	local float Dist, FaceDot;
	local string InstName;

	if (OwnerPawn == None || OwnerPawn.Health <= 0)
	{
		CloseCatchWindow();
		return;
	}

	FaceDir = vector(OwnerPawn.GetViewRotation());

	foreach DynamicActors(class'KFGame.KFProjectile', Proj)
	{
		if (Proj.bDeleteMe)
			continue;

		ToProj = Proj.Location - OwnerPawn.Location;
		Dist = VSize(ToProj);
		FaceDot = Normal(ToProj) dot FaceDir;

		// One diagnostic dump per window: every projectile in the world
		// with its filter values, so a failed catch is explainable from
		// the server log.
		if (!bScanLogged)
		{
			if (Proj.Instigator != None)
				InstName = string(Proj.Instigator.Class.Name);
			else
				InstName = "None";

			`log("[DK_GOALKEEPER] Candidate:" @ string(Proj.Class.Name)
				@ "Instigator:" @ InstName
				@ "IsMonster:" @ string(KFPawn_Monster(Proj.Instigator) != None)
				@ "KeywordMatch:" @ string(IsCatchableClass(string(Proj.Class.Name)))
				@ "Dist:" @ string(Dist)
				@ "FaceDot:" @ string(FaceDot));
		}

		// Hostile only: instigated by a zed
		if (KFPawn_Monster(Proj.Instigator) == None)
			continue;

		if (!IsCatchableClass(string(Proj.Class.Name)))
			continue;

		if (Dist > class'DKUpgrade_Perk_Goalkeeper'.default.CatchRange * SkillRangeMult)
			continue;

		// Front cone check (skip for point-blank - anything that close counts)
		if (Dist > 100.0f
			&& FaceDot < class'DKUpgrade_Perk_Goalkeeper'.default.CatchConeDot * SkillConeMult)
			continue;

		CatchProjectile(Proj, Dist);
		return;
	}

	bScanLogged = True;
}

function bool IsCatchableClass(string ProjClassName)
{
	local int i;

	for (i = 0; i < class'DKUpgrade_Perk_Goalkeeper'.default.CatchableClassKeywords.Length; ++i)
	{
		if (InStr(Caps(ProjClassName), Caps(class'DKUpgrade_Perk_Goalkeeper'.default.CatchableClassKeywords[i])) != INDEX_NONE)
			return True;
	}

	return False;
}

function CatchProjectile(KFProjectile Proj, float Dist)
{
	// Stop the window first so the scan timer dies
	bWindowOpen = False;
	ClearTimer(NameOf(ScanForProjectiles));
	ClearTimer(NameOf(CloseCatchWindow));

	bHoldingCharge = True;
	bPerfectCharge = (Dist <= class'DKUpgrade_Perk_Goalkeeper'.default.PerfectCatchRange * SkillPerfectMult);

	`log("[DK_GOALKEEPER] CAUGHT" @ string(Proj.Class.Name) @ "at dist" @ string(Dist) @ "perfect:" @ string(bPerfectCharge));

	// Level 10: armor on catch
	if (PerkLevel >= 10 && OwnerPawn != None)
	{
		OwnerPawn.Armor = Min(OwnerPawn.MaxArmor,
			OwnerPawn.Armor + class'DKUpgrade_Perk_Goalkeeper'.default.ArmorPerCatch);
	}

	// Skill: Interception Bonus - catches pay dosh
	if (SkillDoshPerCatch > 0 && GetPC() != None && GetPC().PlayerReplicationInfo != None)
		KFPlayerReplicationInfo(GetPC().PlayerReplicationInfo).AddDosh(SkillDoshPerCatch);

	// Skill: Crowd Favorite - nearby allies patched up on catch
	if (SkillCrowdLevel > 0)
		ApplyCrowdFavorite();

	Proj.Destroy();

	PushHUD(GK_HUD_CHARGE, 0.0f);

	if (bPerfectCharge)
		class'DKMessageManager'.static.SendCritical(GetPC(), "PERFECT CATCH! Press again to return it!");
	else
		class'DKMessageManager'.static.SendMinor(GetPC(), "Goalkeeper: caught! Press again to return it.");
}

// Skill: Crowd Favorite - heal (and Deluxe: armor) nearby living teammates.
function ApplyCrowdFavorite()
{
	local KFPawn_Human Ally;

	foreach WorldInfo.AllPawns(class'KFGame.KFPawn_Human', Ally, OwnerPawn.Location, 600.0f)
	{
		if (Ally == OwnerPawn || Ally.Health <= 0)
			continue;

		Ally.HealDamage((SkillCrowdLevel >= 2) ? 10 : 5, GetPC(), class'KFDT_Healing');

		if (SkillCrowdLevel >= 2)
			Ally.Armor = Min(Ally.MaxArmor, Ally.Armor + 10);
	}
}

// ===================================================================
// THROWBACK
// ===================================================================
function ThrowCharge()
{
	local KFPlayerController KFPC;
	local vector StartLoc, AimDir;
	local rotator AimRot, SpreadRot;
	local int Count, i;
	local float SpreadStep, SpreadStart;
	local DKProj_Goalkeeper_Return Ret;

	if (OwnerPawn == None || OwnerPawn.Health <= 0)
		return;

	KFPC = GetPC();
	if (KFPC == None)
		return;

	AimRot = OwnerPawn.GetViewRotation();
	AimDir = vector(AimRot);
	StartLoc = OwnerPawn.Location + OwnerPawn.BaseEyeHeight * vect(0, 0, 1) + AimDir * 60.0f;

	Count = 1;
	if (bPerfectCharge && PerkLevel >= 20)
		Count = Max(1, class'DKUpgrade_Perk_Goalkeeper'.default.PerfectBarrageCount);

	SpreadStep = 0.0f;
	SpreadStart = 0.0f;
	if (Count > 1)
	{
		SpreadStep = class'DKUpgrade_Perk_Goalkeeper'.default.PerfectBarrageSpreadDeg * 182.044f; // deg -> unreal rot units
		SpreadStart = -0.5f * SpreadStep * float(Count - 1);
	}

	for (i = 0; i < Count; ++i)
	{
		SpreadRot = AimRot;
		SpreadRot.Yaw += Round(SpreadStart + SpreadStep * float(i));

		Ret = Spawn(class'DKProj_Goalkeeper_Return', OwnerPawn,, StartLoc, SpreadRot);
		if (Ret != None)
		{
			Ret.Instigator = OwnerPawn;
			Ret.InstigatorController = KFPC;
			Ret.Init(vector(SpreadRot));
		}
	}

	bHoldingCharge = False;
	bPerfectCharge = False;
	PushHUD(GK_HUD_READY, 0.0f);
	class'DKMessageManager'.static.SendMinor(KFPC, "Goalkeeper: RETURNED!");
}

// ===================================================================
// HUD PUSH (server builds state, client renders - HUD_Element_Guide)
// ===================================================================
function PushHUD(byte State, float Duration)
{
	ClientGoalkeeperHUD(State, Duration, bPerfectCharge);
}

reliable client function ClientGoalkeeperHUD(byte State, float Duration, bool bInPerfect)
{
	local KFPlayerController LocalPC;
	local DKHudWrapper HUD;

	LocalPC = KFPlayerController(GetALocalPlayerController());
	if (LocalPC == None)
		return;

	HUD = class'DKHudWrapper'.static.GetReaperHUD(LocalPC);
	if (HUD == None)
		return;

	if (State == GK_HUD_HIDDEN)
		HUD.ClearGoalkeeperDisplay();
	else
		HUD.UpdateGoalkeeperDisplay(State, Duration, bInPerfect);
}

// ===================================================================
// CLEANUP
// ===================================================================
simulated function Destroyed()
{
	if (Role == ROLE_Authority)
		ClientGoalkeeperHUD(GK_HUD_HIDDEN, 0.0f, False);

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
	SkillRangeMult=1.0f
	SkillConeMult=1.0f
	SkillPerfectMult=1.0f

	Name="Default__DKUpgrade_Perk_Goalkeeper_Helper"
}
