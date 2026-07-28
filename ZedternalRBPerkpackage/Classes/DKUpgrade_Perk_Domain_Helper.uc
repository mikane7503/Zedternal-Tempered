// ===================================================================
// DKUpgrade_Perk_Domain_Helper - "Room" perk archetype, active core
//
// Server-authoritative room state + the 4 wheel actions. Activation flow
// (driven from DKPlayerController):
//   - Press key, no room, off cooldown -> CastRoom() at the player's feet.
//   - Press key while room is up        -> controller opens the SWF wheel.
//   - Release key                       -> controller calls FireAction(index)
//                                          with the highlighted segment:
//        0 = Shift     (teleport to where you aim, inside the room)
//        1 = SeverSwap (aim a zed: non-boss = instant kill; boss = swap+knockdown)
//        2 = Discharge (AoE damage + knockdown to every zed in the room)
//        3 = Collapse  (end the room early with the Puncture burst)
//
// Per-rank scaling (radius + duration) and capstone multipliers are pushed in
// from the perk via SetPerkLevel(). Passive bonuses while the room is up are
// applied by the static hooks in DKUpgrade_Perk_Domain.uc, which read this
// helper's room state.
// ===================================================================
class DKUpgrade_Perk_Domain_Helper extends Info
	transient;

var KFPawn_Human OwnerPawn;
var DKPlayerController DKPC;
var int PerkLevel;

// Room state (replicated to the owning client for the cosmetic globe / Scan)
var repnotify bool bRoomActive;
var vector DomainCenter;

// cooldown / duration bookkeeping (server)
var bool bOnCooldown;
var float CooldownStartTime;
var float RoomStartTime;
// Per-ability ready times, indexed by action:
//   0=Shift 1=Sever 2=Discharge 3=Collapse 4=Freeze 5=Shambles
//   6=Tact 7=Injection 8=Mes 9=Tempest. Collapse (3) never uses a cooldown.
var float ActionReadyTime[10];

// Mes mark: the marked zed takes extra owner damage until MarkExpiry.
var KFPawn_Monster MarkedZed;
var float MarkExpiry;
var float MarkDamageBonus; // captured at cast (std vs deluxe)

// Stasis (Freeze) window: refreshed each tick in UpdateAbility until FreezeExpiry.
var float FreezeExpiry;
var float FreezeNextApply;

// Skill modifiers pushed in by the Domain skill upgrades.
// 0 = not owned, 1 = standard, 2 = deluxe.
var int ExpandedDomainLevel;
var int RapidDeploymentLevel;
var int MobileRoomLevel;

// Per-ability unlock level for the skill-gated wheel abilities (indices 4-9).
// 0 = locked, 1 = standard, 2 = deluxe. Base actions 0-3 are never gated.
var byte AbilityUnlockLevel[10];

// effective values, recomputed in SetPerkLevel()
var float RoomDuration;
var float RoomRadius;
var float RoomRadiusSQ;
var int   EffBurstDamage;

const ACTION_REACH = 3000.0f;

var DKDomainVisual DomainVisual;

replication
{
	if (bNetDirty)
		bRoomActive, DomainCenter;
}

simulated event ReplicatedEvent(name VarName)
{
	if (VarName == 'bRoomActive')
	{
		// Cosmetic globe spawn/teardown hooks here once the asset exists.
	}
}

function Initialize(KFPawn_Human InOwnerPawn, DKPlayerController InDKPC)
{
	local int i;

	OwnerPawn = InOwnerPawn;
	DKPC = InDKPC;

	if (OwnerPawn == None || DKPC == None)
	{
		`log("Domain_Helper: ERROR - Invalid owner or controller!");
		Destroy();
		return;
	}

	bRoomActive = false;
	bOnCooldown = false;
	for (i = 0; i < 10; i++)
		ActionReadyTime[i] = 0.0f;

	// Show the Ready card as soon as the perk is live.
	PushCurrentHUD();

	SetTimer(0.1f, true, nameof(UpdateAbility));
}

// Pushed from the perk on purchase / wave end. Recomputes effective room stats
// from the per-rank config curve + capstone multipliers.
function SetPerkLevel(int InLevel)
{
	local float RadMult, DurMult;

	PerkLevel = Clamp(InLevel, 1, 20);

	RadMult = 1.0f;
	DurMult = 1.0f;

	// Capstone 1 (level 10): radius + duration spike.
	if (PerkLevel >= 10)
	{
		RadMult *= class'DKUpgrade_Perk_Domain'.default.RadiusCapstone10Mult;
		DurMult *= class'DKUpgrade_Perk_Domain'.default.DurationCapstone10Mult;
	}

	// Capstone 2 (level 20): the room blows out to cover the whole map.
	// Guarded so an unseeded (0) mult never zeroes the radius.
	if (PerkLevel >= 20 && class'DKUpgrade_Perk_Domain'.default.RadiusCapstone20Mult > 0.0f)
	{
		RadMult *= class'DKUpgrade_Perk_Domain'.default.RadiusCapstone20Mult;
	}

	RoomRadius = (class'DKUpgrade_Perk_Domain'.default.RoomRadiusBase
		+ class'DKUpgrade_Perk_Domain'.default.RoomRadiusPerRank * float(PerkLevel)) * RadMult;
	RoomDuration = (class'DKUpgrade_Perk_Domain'.default.RoomDurationBase
		+ class'DKUpgrade_Perk_Domain'.default.RoomDurationPerRank * float(PerkLevel)) * DurMult;

	// Skill: Expanded Domain (+radius / +duration).
	if (ExpandedDomainLevel >= 1)
	{
		RoomRadius *= 1.0f + class'DKUpgrade_Skill_ExpandedDomain'.default.RadiusBonus[ExpandedDomainLevel - 1];
		RoomDuration *= 1.0f + class'DKUpgrade_Skill_ExpandedDomain'.default.DurationBonus[ExpandedDomainLevel - 1];
	}

	// Skill: Mobile Room (Deluxe) - the roaming room lasts longer.
	if (MobileRoomLevel >= 2)
		RoomDuration += class'DKUpgrade_Skill_MobileRoom'.default.DeluxeDurationBonus;

	RoomRadiusSQ = RoomRadius * RoomRadius;

	EffBurstDamage = class'DKUpgrade_Perk_Domain'.default.BurstDamage;

	// Capstone 2 (level 20): bigger collapse burst. (Per-ability cooldowns are
	// always in effect now, so there is no instant-recharge here anymore.)
	if (PerkLevel >= 20)
	{
		EffBurstDamage *= 2;
	}

	// Keep the HUD card in sync with the current room/cooldown state.
	PushCurrentHUD();
}

// ---- skill modifiers (pushed in from the Domain skill upgrades) ------------
// Each setter stores the owned level; the ones that change room geometry/
// duration trigger a recompute. Called with 0 when the skill is sold.
function ApplyExpandedDomain(int lvl)
{
	if (ExpandedDomainLevel != lvl)
	{
		ExpandedDomainLevel = lvl;
		SetPerkLevel(PerkLevel);
	}
}

function ApplyRapidDeployment(int lvl)
{
	RapidDeploymentLevel = lvl; // read live in the cooldown getters
}

function ApplyMobileRoom(int lvl)
{
	if (MobileRoomLevel != lvl)
	{
		MobileRoomLevel = lvl;
		SetPerkLevel(PerkLevel); // Deluxe adds room duration
	}
}

// ---- in/out tests, read by the perk's static passive hooks -----------------
function bool IsRoomLive()
{
	return bRoomActive;
}

function bool IsOwnerInRoom()
{
	return bRoomActive && OwnerPawn != None && OwnerPawn.Health > 0
		&& VSizeSQ(OwnerPawn.Location - DomainCenter) <= RoomRadiusSQ;
}

function bool IsActorInRoom(Actor A)
{
	return bRoomActive && A != None && VSizeSQ(A.Location - DomainCenter) <= RoomRadiusSQ;
}

function bool CanCastRoom()
{
	return !bRoomActive && !bOnCooldown && OwnerPawn != None && OwnerPawn.Health > 0;
}

// ---------------------------------------------------------------------------
function CastRoom()
{
	local int i;

	if (!CanCastRoom())
		return;

	bRoomActive = true;
	bNetDirty = true;
	// Duration countdown begins only once the dome has finished expanding
	// (hold + grow). The room is active and usable during expansion; it just
	// won't start timing out until it reaches full size.
	RoomStartTime = OwnerPawn.WorldInfo.TimeSeconds
		+ class'DKUpgrade_Perk_Domain'.default.ExpandHoldDuration
		+ class'DKUpgrade_Perk_Domain'.default.ExpandDuration;
	DomainCenter = OwnerPawn.Location;
	for (i = 0; i < 10; i++)
		ActionReadyTime[i] = 0.0f;

	// Fresh room: clear any lingering Mes mark / Stasis window.
	MarkedZed = None;
	MarkExpiry = 0.0f;
	MarkDamageBonus = 0.0f;
	FreezeExpiry = 0.0f;

	SpawnVisual();

	`log("Domain: cast - PerkLevel=" $ PerkLevel $ " RoomRadius=" $ RoomRadius $ " RoomRadiusSQ=" $ RoomRadiusSQ);

	PlayDomainSound('Domain_Activate');

	// HUD: Active card. The bar drains over the whole room lifetime (expand
	// hold + grow + duration) so it empties exactly when the room collapses.
	PushDomainHUD(1, (RoomStartTime + RoomDuration) - OwnerPawn.WorldInfo.TimeSeconds);

	class'DKMessageManager'.static.SendImportant(DKPC, "DOMAIN cast - it is your battlefield now.");
}

// Called by the controller on wheel release with the chosen segment.
// bIgnoreUnlock is set by the debug path so abilities can be tested without
// owning their unlock skill; the real wheel path always honors the gate.
function FireAction(int ActionIndex, optional bool bIgnoreUnlock)
{
	local bool bFired;

	if (!bRoomActive || OwnerPawn == None || OwnerPawn.Health <= 0)
		return;

	if (ActionIndex < 0 || ActionIndex > 9)
		return;

	// Abilities 4-9 are gated behind their unlock skill.
	if (!bIgnoreUnlock && !IsActionUnlocked(ActionIndex))
	{
		class'DKMessageManager'.static.SendMinor(DKPC, "Domain: that ability is not unlocked.");
		return;
	}

	// Collapse (3) ends the room and has no cooldown. Everything else is gated
	// by its own per-ability cooldown.
	if (ActionIndex != 3 && OwnerPawn.WorldInfo.TimeSeconds < ActionReadyTime[ActionIndex])
	{
		class'DKMessageManager'.static.SendMinor(DKPC, "Domain: that ability is recharging.");
		return;
	}

	switch (ActionIndex)
	{
		case 0: bFired = DoShift();     break;
		case 1: bFired = DoSeverSwap(); break;
		case 2: bFired = DoDischarge(); break;
		case 3: DoCollapse();  return; // collapse ends the room; no action cooldown
		case 4: bFired = DoFreeze();    break;
		case 5: bFired = DoShambles();  break;
		case 6: bFired = DoTact();      break;
		case 7: bFired = DoInjection(); break;
		case 8: bFired = DoMes();       break;
		case 9: bFired = DoTempest();   break;
		default: return;
	}

	// Only start the cooldown / play the ability sound if the action actually
	// fired (e.g. Shift aimed outside the room does not burn its cooldown).
	if (bFired)
	{
		ActionReadyTime[ActionIndex] = OwnerPawn.WorldInfo.TimeSeconds + GetActionCooldown(ActionIndex);
		PlayActionSound(ActionIndex);
	}
}

// Plays the per-ability cue on a successful fire. Collapse plays its own in
// DoCollapse, so it is not listed here.
function PlayActionSound(int ActionIndex)
{
	switch (ActionIndex)
	{
		case 0: PlayDomainSound('Domain_Shift');     break;
		case 1: PlayDomainSound('Domain_Sever');     break;
		case 2: PlayDomainSound('Domain_Discharge'); break;
		case 4: PlayDomainSound('Domain_Freeze');    break;
		case 5: PlayDomainSound('Domain_Shambles');  break;
		case 6: PlayDomainSound('Domain_Tact');      break;
		case 7: PlayDomainSound('Domain_Injection'); break;
		case 8: PlayDomainSound('Domain_Mes');       break;
		case 9: PlayDomainSound('Domain_Tempest');   break;
	}
}

// Flat per-ability cooldown in seconds, with Rapid Deployment applied.
// Collapse (3) has none.
function float GetActionCooldown(int ActionIndex)
{
	local float CD;

	switch (ActionIndex)
	{
		case 0: CD = class'DKUpgrade_Perk_Domain'.default.ShiftCooldown;     break;
		case 1: CD = class'DKUpgrade_Perk_Domain'.default.SeverCooldown;     break;
		case 2: CD = class'DKUpgrade_Perk_Domain'.default.DischargeCooldown; break;
		case 4: CD = class'DKUpgrade_Perk_Domain'.default.FreezeCooldown;    break;
		case 5: CD = class'DKUpgrade_Perk_Domain'.default.ShamblesCooldown;  break;
		case 6: CD = class'DKUpgrade_Perk_Domain'.default.TactCooldown;      break;
		case 7: CD = class'DKUpgrade_Perk_Domain'.default.InjectionCooldown; break;
		case 8: CD = class'DKUpgrade_Perk_Domain'.default.MesCooldown;       break;
		case 9: CD = class'DKUpgrade_Perk_Domain'.default.TempestCooldown;   break;
		default: return 0.0f;
	}

	if (RapidDeploymentLevel >= 1)
		CD *= 1.0f - class'DKUpgrade_Skill_RapidDeployment'.default.CooldownReduction[RapidDeploymentLevel - 1];

	return FMax(CD, 0.0f);
}

// Room recharge after Collapse / expiry, with Rapid Deployment applied.
function float GetEffectiveRoomCooldown()
{
	local float CD;

	CD = class'DKUpgrade_Perk_Domain'.default.RoomCooldown;
	if (RapidDeploymentLevel >= 1)
		CD *= 1.0f - class'DKUpgrade_Skill_RapidDeployment'.default.CooldownReduction[RapidDeploymentLevel - 1];

	return FMax(CD, 0.0f);
}

// ---- ability unlock gating (pushed in from the wheel-ability skills) -------
// Base actions 0-3 are always available; 4-9 require their unlock skill.
function bool IsActionUnlocked(int ActionIndex)
{
	if (ActionIndex >= 0 && ActionIndex <= 3)
		return true;
	if (ActionIndex >= 4 && ActionIndex <= 9)
		return AbilityUnlockLevel[ActionIndex] >= 1;
	return false;
}

function bool IsAbilityDeluxe(int ActionIndex)
{
	return ActionIndex >= 0 && ActionIndex <= 9 && AbilityUnlockLevel[ActionIndex] >= 2;
}

// Pushed in by the wheel-ability skills' InitiateWeapon/WaveEnd (0 on sell).
function SetAbilityUnlock(int ActionIndex, int lvl)
{
	if (ActionIndex >= 4 && ActionIndex <= 9)
		AbilityUnlockLevel[ActionIndex] = byte(Clamp(lvl, 0, 2));
}

// Build the per-slot snapshot string for the ability wheel:
// "rem0,..,rem9|tot0,..,tot9|unl0,..,unl9". Cooldowns drive the fill; unlock is
// 1 for base actions 0-3 and the AbilityUnlockLevel for 4-9 (0 = locked, so the
// wheel hides it). Collapse (3) and ready/idle slots report 0 remaining/total.
function string BuildCooldownSnapshot()
{
	local int i, Unl;
	local float Now, Total, Rem;
	local string RemStr, TotStr, UnlStr;

	if (OwnerPawn == None)
		return "0,0,0,0,0,0,0,0,0,0|0,0,0,0,0,0,0,0,0,0|1,1,1,1,0,0,0,0,0,0";

	Now = OwnerPawn.WorldInfo.TimeSeconds;

	for (i = 0; i < 10; i++)
	{
		Total = GetActionCooldown(i);
		Rem = FMax(0.0f, ActionReadyTime[i] - Now);
		if (Rem > Total)
			Rem = Total;

		if (i <= 3)
			Unl = 1;
		else
			Unl = AbilityUnlockLevel[i];

		if (i > 0)
		{
			RemStr $= ",";
			TotStr $= ",";
			UnlStr $= ",";
		}
		RemStr $= string(Rem);
		TotStr $= string(Total);
		UnlStr $= string(Unl);
	}

	return RemStr $ "|" $ TotStr $ "|" $ UnlStr;
}

function bool DoShift()
{
	local vector ViewLoc, HitLoc, HitNormal, EndTrace, TargetPoint;
	local rotator ViewRot;
	local Actor HitActor;
	local float Reach;

	DKPC.GetPlayerViewPoint(ViewLoc, ViewRot);
	// Reach across the whole room: standing at one edge, the far edge is up to
	// 2x the radius away. Never shorter than the old fixed cap.
	Reach = FMax(ACTION_REACH, RoomRadius * 2.0f);
	EndTrace = ViewLoc + (vector(ViewRot) * Reach);
	HitActor = OwnerPawn.Trace(HitLoc, HitNormal, EndTrace, ViewLoc, true);

	if (HitActor != None && VSizeSQ(HitLoc - DomainCenter) <= RoomRadiusSQ)
	{
		TargetPoint = HitLoc;
		TargetPoint.Z += 20.0f;
		OwnerPawn.SetLocation(TargetPoint);
		class'DKMessageManager'.static.SendMinor(DKPC, "Shift.");
		return true;
	}

	class'DKMessageManager'.static.SendMinor(DKPC, "Shift: aim inside the room.");
	return false;
}

function bool DoSeverSwap()
{
	local vector ViewLoc, HitLoc, HitNormal, EndTrace, PLoc, MLoc;
	local rotator ViewRot;
	local Actor HitActor;
	local KFPawn_Monster M;
	local float Reach;

	DKPC.GetPlayerViewPoint(ViewLoc, ViewRot);
	Reach = FMax(ACTION_REACH, RoomRadius * 2.0f);
	EndTrace = ViewLoc + (vector(ViewRot) * Reach);
	HitActor = OwnerPawn.Trace(HitLoc, HitNormal, EndTrace, ViewLoc, true);

	M = KFPawn_Monster(HitActor);
	if (M == None || !M.IsAliveAndWell() || !IsActorInRoom(M))
	{
		class'DKMessageManager'.static.SendMinor(DKPC, "Sever: aim a zed inside the room.");
		return false;
	}

	if (M.IsABoss())
	{
		// Swap places + knockdown.
		PLoc = OwnerPawn.Location;
		MLoc = M.Location;
		OwnerPawn.SetLocation(MLoc);
		M.SetLocation(PLoc);
		if (M.CanDoSpecialMove(SM_Knockdown))
			M.Knockdown(vect(0,0,1) * 250.0f, vect(1,1,1), M.Location, 1000, 100);
		class'DKMessageManager'.static.SendImportant(DKPC, "Swap!");
	}
	else
	{
		// Decapitate via the real gore pipeline: drive the head hit zone's gore
		// health to zero so the engine fires HitZoneInjured(HZI_HEAD). That pops
		// the head on every client AND sets the headless bleed-out state. Calling
		// CauseHeadTrauma directly only set the state, so the head never came off.
		M.TakeHitZoneDamage(100000.0f, class'KFDT_Slashing', HZI_HEAD, OwnerPawn.Location);

		// Safety net for the rare zed that cannot be decapitated
		// (bDisableHeadless / bIsBountyHuntObjective) so Sever is never a dud.
		if (!M.bIsHeadless)
			M.TakeDamage(M.Health + 5000, DKPC, M.Location, vect(0,0,0), class'KFDT_Slashing', , OwnerPawn);

		class'DKMessageManager'.static.SendMinor(DKPC, "Sever!");
	}

	return true;
}

function bool DoDischarge()
{
	local KFPawn_Monster KFM;
	local vector KnockDir;
	local int HitCount;

	HitCount = 0;
	foreach OwnerPawn.DynamicActors(class'KFPawn_Monster', KFM)
	{
		if (KFM.IsAliveAndWell() && VSizeSQ(KFM.Location - DomainCenter) <= RoomRadiusSQ)
		{
			KFM.TakeDamage(class'DKUpgrade_Perk_Domain'.default.ShockDamage, DKPC, KFM.Location, vect(0,0,0), class'KFDT_Bludgeon', , OwnerPawn);

			KnockDir = Normal(KFM.Location - DomainCenter);
			KnockDir.Z = 0.5f;
			if (KFM.CanDoSpecialMove(SM_Knockdown))
				KFM.Knockdown(KnockDir * 500.0f, vect(1,1,1), KFM.Location, 1000, 100);

			HitCount++;
		}
	}

	class'DKMessageManager'.static.SendImportant(DKPC, "Discharge! Hit " $ HitCount $ " zeds.");
	return true;
}

// ===================================================================
// SKILL-UNLOCKED WHEEL ABILITIES (indices 4-9)
// ===================================================================

// 4 - Freeze / Stasis: freeze every non-boss zed in the room. UpdateAbility
// re-pulses the freeze until FreezeExpiry so they stay locked the full time.
function bool DoFreeze()
{
	local float Dur;

	if (IsAbilityDeluxe(4))
		Dur = class'DKUpgrade_Perk_Domain'.default.FreezeDurationDeluxe;
	else
		Dur = class'DKUpgrade_Perk_Domain'.default.FreezeDuration;

	FreezeExpiry = OwnerPawn.WorldInfo.TimeSeconds + Dur;
	ApplyFreezePulse();
	class'DKMessageManager'.static.SendImportant(DKPC, "Stasis - the room freezes.");
	return true;
}

// Applies the freeze affliction (FreezePower=100 via DKDT_DomainFreeze) to every
// non-boss zed in the room. Bosses cannot perform SM_Frozen so it is a no-op on
// them; the IsABoss() guard is belt-and-braces. Non-zero momentum is required
// or the affliction code skips the freeze.
function ApplyFreezePulse()
{
	local KFPawn_Monster KFM;
	local vector Mom;

	if (OwnerPawn == None)
		return;

	foreach OwnerPawn.DynamicActors(class'KFPawn_Monster', KFM)
	{
		if (KFM.IsAliveAndWell() && !KFM.IsABoss()
			&& VSizeSQ(KFM.Location - DomainCenter) <= RoomRadiusSQ)
		{
			Mom = Normal(KFM.Location - DomainCenter);
			if (IsZero(Mom))
				Mom = vect(1,0,0);
			KFM.TakeDamage(1, DKPC, KFM.Location, Mom * 50.0f, class'DKDT_DomainFreeze', , OwnerPawn);
		}
	}

	FreezeNextApply = OwnerPawn.WorldInfo.TimeSeconds + 0.9f;
}

// 5 - Shambles: yank every non-boss zed in the room to a point just in front of
// you, clumping the horde for an AoE follow-up.
function bool DoShambles()
{
	local KFPawn_Monster KFM;
	local vector ViewLoc, GatherPt;
	local rotator ViewRot;
	local int Count;
	local bool bDeluxe;

	bDeluxe = IsAbilityDeluxe(5);

	DKPC.GetPlayerViewPoint(ViewLoc, ViewRot);
	GatherPt = OwnerPawn.Location + (vector(ViewRot) * FMin(RoomRadius * 0.5f, 600.0f));
	GatherPt.Z = OwnerPawn.Location.Z;

	Count = 0;
	foreach OwnerPawn.DynamicActors(class'KFPawn_Monster', KFM)
	{
		if (KFM.IsAliveAndWell() && !KFM.IsABoss()
			&& VSizeSQ(KFM.Location - DomainCenter) <= RoomRadiusSQ)
		{
			// Small scatter so they do not perfectly overlap.
			KFM.SetLocation(GatherPt + (VRand() * 80.0f));

			// Deluxe: knock the clumped horde down on arrival.
			if (bDeluxe && KFM.CanDoSpecialMove(SM_Knockdown))
				KFM.Knockdown(vect(0,0,1) * 250.0f, vect(1,1,1), KFM.Location, 1000, 100);

			Count++;
		}
	}

	class'DKMessageManager'.static.SendImportant(DKPC, "Shambles! Pulled " $ Count $ " zeds.");
	return true;
}

// 6 - Tact: launch every non-boss zed in the room skyward; they fall and take
// slam damage + knockdown on landing.
function bool DoTact()
{
	local KFPawn_Monster KFM;
	local vector Launch;
	local float LaunchZ;
	local int Dmg;

	if (IsAbilityDeluxe(6))
	{
		LaunchZ = 900.0f;
		Dmg = class'DKUpgrade_Perk_Domain'.default.TactDamageDeluxe;
	}
	else
	{
		LaunchZ = 650.0f;
		Dmg = class'DKUpgrade_Perk_Domain'.default.TactDamage;
	}

	foreach OwnerPawn.DynamicActors(class'KFPawn_Monster', KFM)
	{
		if (KFM.IsAliveAndWell() && !KFM.IsABoss()
			&& VSizeSQ(KFM.Location - DomainCenter) <= RoomRadiusSQ)
		{
			Launch = vect(0,0,1) * LaunchZ;
			Launch.X += (FRand() - 0.5f) * 200.0f;
			Launch.Y += (FRand() - 0.5f) * 200.0f;

			KFM.Velocity = Launch;
			KFM.SetPhysics(PHYS_Falling);
			if (KFM.CanDoSpecialMove(SM_Knockdown))
				KFM.Knockdown(Launch, vect(1,1,1), KFM.Location, 1000, 100);

			KFM.TakeDamage(Dmg, DKPC, KFM.Location, vect(0,0,0), class'KFDT_Bludgeon', , OwnerPawn);
		}
	}

	class'DKMessageManager'.static.SendImportant(DKPC, "Tact - up you go.");
	return true;
}

// 7 - Injection Shot: a piercing line. Every zed within a tight radius of your
// aim line, inside the room, takes heavy damage.
function bool DoInjection()
{
	local vector ViewLoc, Dir, ClosestPt;
	local rotator ViewRot;
	local KFPawn_Monster KFM;
	local float Reach, Along, RadiusSQ;
	local int Count, Dmg;

	DKPC.GetPlayerViewPoint(ViewLoc, ViewRot);
	Dir = vector(ViewRot);
	Reach = FMax(ACTION_REACH, RoomRadius * 2.0f);

	if (IsAbilityDeluxe(7))
	{
		Dmg = class'DKUpgrade_Perk_Domain'.default.InjectionDamageDeluxe;
		RadiusSQ = 280.0f * 280.0f;
	}
	else
	{
		Dmg = class'DKUpgrade_Perk_Domain'.default.InjectionDamage;
		RadiusSQ = 180.0f * 180.0f;
	}

	Count = 0;
	foreach OwnerPawn.DynamicActors(class'KFPawn_Monster', KFM)
	{
		if (!KFM.IsAliveAndWell() || VSizeSQ(KFM.Location - DomainCenter) > RoomRadiusSQ)
			continue;

		// Project the zed onto the aim ray, then measure its distance from it.
		Along = FClamp((KFM.Location - ViewLoc) dot Dir, 0.0f, Reach);
		ClosestPt = ViewLoc + Dir * Along;

		if (VSizeSQ(KFM.Location - ClosestPt) <= RadiusSQ)
		{
			KFM.TakeDamage(Dmg, DKPC, KFM.Location, Dir * 100.0f, class'KFDT_Slashing', , OwnerPawn);
			Count++;
		}
	}

	class'DKMessageManager'.static.SendImportant(DKPC, "Injection Shot - pierced " $ Count $ ".");
	return true;
}

// 8 - Mes: aim a zed and expose its heart. While the mark holds it takes extra
// damage from you. (Sever covers the non-boss instakill / boss swap, so Mes is
// the soften-a-tough-target tool.)
function bool DoMes()
{
	local vector ViewLoc, HitLoc, HitNormal, EndTrace;
	local rotator ViewRot;
	local Actor HitActor;
	local KFPawn_Monster M;
	local float Reach;

	DKPC.GetPlayerViewPoint(ViewLoc, ViewRot);
	Reach = FMax(ACTION_REACH, RoomRadius * 2.0f);
	EndTrace = ViewLoc + (vector(ViewRot) * Reach);
	HitActor = OwnerPawn.Trace(HitLoc, HitNormal, EndTrace, ViewLoc, true);

	M = KFPawn_Monster(HitActor);
	if (M == None || !M.IsAliveAndWell() || !IsActorInRoom(M))
	{
		class'DKMessageManager'.static.SendMinor(DKPC, "Mes: aim a zed inside the room.");
		return false;
	}

	MarkedZed = M;
	if (IsAbilityDeluxe(8))
	{
		MarkExpiry = OwnerPawn.WorldInfo.TimeSeconds + class'DKUpgrade_Perk_Domain'.default.MesDurationDeluxe;
		MarkDamageBonus = class'DKUpgrade_Perk_Domain'.default.MesDamageBonusDeluxe;
	}
	else
	{
		MarkExpiry = OwnerPawn.WorldInfo.TimeSeconds + class'DKUpgrade_Perk_Domain'.default.MesDuration;
		MarkDamageBonus = class'DKUpgrade_Perk_Domain'.default.MesDamageBonus;
	}
	class'DKMessageManager'.static.SendImportant(DKPC, "Mes - heart exposed. Strike it!");
	return true;
}

// Read by the perk's ModifyDamageGiven: extra damage multiplier vs the marked
// target while the mark is live (1.0 = no bonus).
function float GetMarkDamageScale(KFPawn_Monster KFM)
{
	if (KFM != None && KFM == MarkedZed && OwnerPawn != None
		&& OwnerPawn.WorldInfo.TimeSeconds < MarkExpiry)
		return 1.0f + MarkDamageBonus;

	return 1.0f;
}

// 9 - Tempest: an EMP + stun pulse across the whole room. Disrupts Husks,
// Sirens and other specials and stuns trash (DKDT_DomainEMP carries the power).
// Bosses resist EMP/stun naturally.
function bool DoTempest()
{
	local KFPawn_Monster KFM;
	local vector Mom;
	local int Dmg;

	// Standard is EMP + stun only (1 dmg). Deluxe adds a real damage hit.
	if (IsAbilityDeluxe(9))
		Dmg = class'DKUpgrade_Perk_Domain'.default.TempestDamageDeluxe;
	else
		Dmg = 1;

	foreach OwnerPawn.DynamicActors(class'KFPawn_Monster', KFM)
	{
		if (KFM.IsAliveAndWell() && VSizeSQ(KFM.Location - DomainCenter) <= RoomRadiusSQ)
		{
			Mom = Normal(KFM.Location - DomainCenter);
			if (IsZero(Mom))
				Mom = vect(1,0,0);
			KFM.TakeDamage(Dmg, DKPC, KFM.Location, Mom * 50.0f, class'DKDT_DomainEMP', , OwnerPawn);
		}
	}

	class'DKMessageManager'.static.SendImportant(DKPC, "Tempest - systems down.");
	return true;
}

function DoCollapse()
{
	PlayDomainSound('Domain_Collapse');
	CollapseBurst();
	EndRoom();
	class'DKMessageManager'.static.SendImportant(DKPC, "Domain collapsed.");
}

function CollapseBurst()
{
	local KFPawn_Monster KFM;

	foreach OwnerPawn.DynamicActors(class'KFPawn_Monster', KFM)
	{
		if (KFM.IsAliveAndWell() && VSizeSQ(KFM.Location - DomainCenter) <= RoomRadiusSQ)
			KFM.TakeDamage(EffBurstDamage, DKPC, KFM.Location, vect(0,0,0), class'KFDT_Bludgeon', , OwnerPawn);
	}
}

function EndRoom()
{
	DestroyVisual();

	bRoomActive = false;
	bNetDirty = true;
	bOnCooldown = true;
	CooldownStartTime = OwnerPawn.WorldInfo.TimeSeconds;

	// HUD: switch to the Cooldown card, bar draining over the recharge.
	PushDomainHUD(2, GetEffectiveRoomCooldown());
}

// ---- sound + HUD plumbing --------------------------------------------------

// Look up a registered Domain SoundCue and play it on the owning client via
// the controller's reusable client RPC (server-side PlaySoundBase is silent).
function PlayDomainSound(name SoundID)
{
	local DKMutator Mutator;
	local SoundCue Sound;

	if (DKPC == None || OwnerPawn == None)
		return;

	Mutator = class'DKSoundManager'.static.GetMutator(OwnerPawn.WorldInfo);
	if (Mutator == None)
		return;

	Sound = class'DKSoundManager'.static.GetSound(Mutator, SoundID);
	if (Sound != None)
		DKPC.ClientPlayBuffSound(Sound);
}

// State: 0 = Ready, 1 = Active (duration), 2 = Cooldown. Duration is the
// length of the draining bar in seconds (ignored for Ready).
function PushDomainHUD(byte State, float Duration)
{
	if (DKPC != None)
		DKPC.ClientUpdateDomainHUD(State, Duration);
}

// Re-send whatever state the room is currently in (used on init / perk level
// changes so the card is always correct, even after a respawn or re-equip).
function PushCurrentHUD()
{
	local float Now;

	if (OwnerPawn == None)
		return;

	Now = OwnerPawn.WorldInfo.TimeSeconds;

	if (bRoomActive)
		PushDomainHUD(1, FMax(0.0f, (RoomStartTime + RoomDuration) - Now));
	else if (bOnCooldown)
		PushDomainHUD(2, FMax(0.0f, GetEffectiveRoomCooldown() - (Now - CooldownStartTime)));
	else
		PushDomainHUD(0, 0.0f);
}

// Cosmetic dome lifecycle.
function SpawnVisual()
{
	if (OwnerPawn == None)
		return;

	DestroyVisual();
	DomainVisual = OwnerPawn.Spawn(class'DKDomainVisual',,, DomainCenter);
	if (DomainVisual != None)
		DomainVisual.Setup(DomainCenter, RoomRadius, class'DKUpgrade_Perk_Domain'.default.ExpandDuration, class'DKUpgrade_Perk_Domain'.default.ExpandHoldDuration, RoomDuration + class'DKUpgrade_Perk_Domain'.default.ExpandHoldDuration + class'DKUpgrade_Perk_Domain'.default.ExpandDuration + 2.0f);
}

function DestroyVisual()
{
	if (DomainVisual != None)
	{
		DomainVisual.Destroy();
		DomainVisual = None;
	}
}

function UpdateAbility()
{
	local float Now, Elapsed;

	if (OwnerPawn == None || OwnerPawn.Health <= 0)
	{
		if (bRoomActive)
		{
			DestroyVisual();
			bRoomActive = false;
			bNetDirty = true;
		}
		return;
	}

	Now = OwnerPawn.WorldInfo.TimeSeconds;

	if (bRoomActive)
	{
		// Skill: Mobile Room re-centers the room on you each tick.
		if (MobileRoomLevel >= 1)
		{
			DomainCenter = OwnerPawn.Location;
			bNetDirty = true;
			if (DomainVisual != None)
				DomainVisual.SetLocation(DomainCenter);
		}

		// Stasis: keep non-boss zeds frozen until the window closes.
		if (FreezeExpiry > Now && Now >= FreezeNextApply)
			ApplyFreezePulse();

		Elapsed = Now - RoomStartTime;
		if (Elapsed >= RoomDuration)
		{
			PlayDomainSound('Domain_End');
			CollapseBurst();
			EndRoom();
			class'DKMessageManager'.static.SendImportant(DKPC, "Domain faded.");
		}
	}
	else if (bOnCooldown)
	{
		if (Now - CooldownStartTime >= GetEffectiveRoomCooldown())
		{
			bOnCooldown = false;
			PlayDomainSound('Domain_Ready');
			PushDomainHUD(0, 0.0f);
			class'DKMessageManager'.static.SendImportant(DKPC, "Domain ready!");
		}
	}
}

// Called by the perk's DeleteHelperClass on sell, and on cleanup.
function ForceRevert()
{
	DestroyVisual();

	if (bRoomActive)
	{
		bRoomActive = false;
		bNetDirty = true;
	}

	if (DKPC != None)
		DKPC.ClientClearDomainHUD();

	ClearTimer(nameof(UpdateAbility));
}

function Destroyed()
{
	DestroyVisual();
	ClearTimer(nameof(UpdateAbility));
	Super.Destroyed();
}

defaultproperties
{
	bRoomActive=false
	bOnCooldown=false
	PerkLevel=1

	Name="Default__DKUpgrade_Perk_Domain_Helper"
}
