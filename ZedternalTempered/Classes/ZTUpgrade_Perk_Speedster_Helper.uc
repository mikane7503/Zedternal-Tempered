// ===================================================================
// ZTUpgrade_Perk_Speedster_Helper - per-player Blink Strike state machine
//
// Spawned as a ChildActor of the human pawn by the perk's GetHelper (server).
// Server authoritative. Replicates bBlinking to the owning client so the
// perk's ModifyDamageTaken invuln gate reads a consistent value.
//
// This is a PERK-SHIPPED ability (like Hyde's serum / Domain's Room), NOT a
// slotted skill ability -- so it deliberately does NOT use the RegisterAbility
// / F-slot system. It is triggered only by the dedicated U key
// (ZTPlayerController.ActivateSpeedster -> TryActivate).
//
// Flow: TryActivate -> StartBlink: snapshot start position, tag the nearest
// live zeds in range, then a looping BlinkTick timer flickers through them one
// per BlinkInterval (teleport adjacent + devastating strike + knockdown +
// capstone cleave). When the queue empties, FinishBlink blinks the player back
// to the start, holds invuln for InvulnTail, then EndBlink starts the cooldown.
//
// Speedfreak SKILLS feed in through ApplyXxx() setters (pushed by each skill's
// InitiateWeapon/WaveEnd/DeleteHelperClass, mirroring the Domain skills):
//   OpenSeason     -> +targets        (GetMaxTargets)
//   Overclock      -> -cooldown       (GetCooldown)
//   GiantKiller    -> +giant chunk    (StrikeTarget)
//   LongReach      -> +tag range      (GatherTargets)
//   Shockfront     -> AoE per strike  (StrikeTarget -> DoShockfront)
//   ConcussiveBlink-> stronger CC     (StrikeTarget knockdown scale)
//   Momentum       -> cooldown refund (EndBlink, off DashKills)
//   HuntersMark    -> mark struck zeds (StrikeTarget -> MarkZed; the skill's
//                     ModifyDamageGiven reads IsMarked)
//
// HUD: cooldown/ready state is reported via the bespoke three-state card
// (Ready / Active / Cooldown) drawn in ZTHudWrapper.DrawSpeedsterCard.
// ===================================================================
class ZTUpgrade_Perk_Speedster_Helper extends Info transient;

var KFPawn_Human OwnerPawn;
var ZTPlayerController DKPC;
var int PerkLevel;

// Replicated to the owning client (perk hooks read this).
var repnotify bool bBlinking;

// Cooldown bookkeeping (server).
var bool bOnCooldown;
var float CooldownStart;

// Blink-flurry state.
var vector StartLocation;
var array<KFPawn_Monster> BlinkQueue;
var int BlinkIndex;

// --- Speedfreak skill levels (0 = not owned, 1 = standard, 2 = deluxe) ---
var int OpenSeasonLevel;
var int OverclockLevel;
var int GiantKillerLevel;
var int LongReachLevel;
var int ShockfrontLevel;
var int ConcussiveLevel;
var int MomentumLevel;
var int HuntersMarkLevel;

// Momentum: zeds killed during the current dash.
var int DashKills;

// Hunter's Mark registry: zeds tagged by Blink Strike + when the tag expires.
struct SMarkedZed
{
    var KFPawn_Monster Zed;
    var float Expiry;
};
var array<SMarkedZed> MarkedZeds;

// HUD card states (mirror Domain's 0/1/2).
const HUD_READY    = 0;
const HUD_ACTIVE   = 1;
const HUD_COOLDOWN = 2;

replication
{
    if (bNetDirty)
        bBlinking;
}

// ===================================================================
// LIFECYCLE
// ===================================================================
function Initialize(KFPawn_Human InOwnerPawn, ZTPlayerController InDKPC)
{
    OwnerPawn = InOwnerPawn;
    DKPC = InDKPC;

    if (OwnerPawn == None || DKPC == None)
    {
        Destroy();
        return;
    }

    bBlinking = false;
    bOnCooldown = false;

    PushHUD(HUD_READY);
    SetTimer(0.1f, true, nameof(UpdateAbility));
}

function SetPerkLevel(int InLevel)
{
    PerkLevel = Clamp(InLevel, 1, 20);
}

// ===================================================================
// SKILL HOOKS (pushed in from the Speedfreak skill classes)
// ===================================================================
function ApplyOpenSeason(int lvl)    { OpenSeasonLevel = lvl; }
function ApplyOverclock(int lvl)     { OverclockLevel = lvl; }
function ApplyGiantKiller(int lvl)   { GiantKillerLevel = lvl; }
function ApplyLongReach(int lvl)     { LongReachLevel = lvl; }
function ApplyShockfront(int lvl)    { ShockfrontLevel = lvl; }
function ApplyConcussive(int lvl)    { ConcussiveLevel = lvl; }
function ApplyMomentum(int lvl)      { MomentumLevel = lvl; }
function ApplyHuntersMark(int lvl)   { HuntersMarkLevel = lvl; }

// ===================================================================
// CAPSTONE-AWARE GETTERS
// ===================================================================
function int GetMaxTargets()
{
    local int T;

    if (PerkLevel >= class'ZTConfig_Capstone'.static.GetRank1Level())
        T = class'ZTUpgrade_Perk_Speedster'.default.MaxTargetsCapstone10;
    else
        T = class'ZTUpgrade_Perk_Speedster'.default.MaxTargetsBase;

    if (OpenSeasonLevel >= 1)
        T += class'ZTUpgrade_Skill_OpenSeason'.default.TargetBonus[OpenSeasonLevel - 1];

    return Max(T, 1);
}

function float GetCooldown()
{
    local float CD;

    CD = class'ZTUpgrade_Perk_Speedster'.default.Cooldown;
    if (PerkLevel >= class'ZTConfig_Capstone'.static.GetRank1Level())
        CD *= class'ZTUpgrade_Perk_Speedster'.default.CooldownCapstone10Mult;

    if (OverclockLevel >= 1)
        CD *= 1.0f - class'ZTUpgrade_Skill_Overclock'.default.CooldownReduction[OverclockLevel - 1];

    return FMax(CD, 0.0f);
}

// ===================================================================
// ACTIVATION (called only by the U key dispatch -> ServerActivateSpeedster)
// ===================================================================
function TryActivate()
{
    if (OwnerPawn == None || OwnerPawn.Health <= 0)
    {
        class'ZTMessageManager'.static.SendMinor(DKPC, "Blink Strike: cannot dash while down.");
        return;
    }

    if (bBlinking)
        return;

    if (bOnCooldown)
    {
        class'ZTMessageManager'.static.SendMinor(DKPC, "Blink Strike: recharging.");
        return;
    }

    StartBlink();
}

function StartBlink()
{
    StartLocation = OwnerPawn.Location;

    GatherTargets();
    if (BlinkQueue.Length == 0)
    {
        class'ZTMessageManager'.static.SendMinor(DKPC, "Blink Strike: no targets in range.");
        return;
    }

    bBlinking = true;
    bNetDirty = true;
    BlinkIndex = 0;
    DashKills = 0;

    PushHUD(HUD_ACTIVE);
    PlayBlinkSound();
    class'ZTMessageManager'.static.SendImportant(DKPC, "BLINK STRIKE!");

    // First strike fires after one interval; subsequent strikes each tick.
    SetTimer(class'ZTUpgrade_Perk_Speedster'.default.BlinkInterval, true, nameof(BlinkTick));
}

// Collect the nearest live zeds within the (skill-widened) tag range of the
// start point, up to the (capstone-aware) target cap, nearest-first.
function GatherTargets()
{
    local KFPawn_Monster KFM;
    local array<KFPawn_Monster> Pool;
    local array<float> PoolDist;
    local float Range, RangeSQ, D;
    local int i, Best, MaxT;

    BlinkQueue.Length = 0;

    Range = class'ZTUpgrade_Perk_Speedster'.default.TagRange;
    if (LongReachLevel >= 1)
        Range *= 1.0f + class'ZTUpgrade_Skill_LongReach'.default.RangeBonus[LongReachLevel - 1];
    RangeSQ = Square(Range);

    foreach OwnerPawn.WorldInfo.AllPawns(class'KFPawn_Monster', KFM, StartLocation, Range)
    {
        if (KFM.IsAliveAndWell() && KFM.GetTeamNum() != OwnerPawn.GetTeamNum())
        {
            D = VSizeSQ(KFM.Location - StartLocation);
            if (D <= RangeSQ)
            {
                Pool.AddItem(KFM);
                PoolDist.AddItem(D);
            }
        }
    }

    MaxT = GetMaxTargets();
    while (BlinkQueue.Length < MaxT && Pool.Length > 0)
    {
        Best = 0;
        for (i = 1; i < Pool.Length; i++)
        {
            if (PoolDist[i] < PoolDist[Best])
                Best = i;
        }
        BlinkQueue.AddItem(Pool[Best]);
        Pool.Remove(Best, 1);
        PoolDist.Remove(Best, 1);
    }
}

// One blink per tick: skip any target that died since tagging, then teleport
// adjacent to the next live one and strike it. Ends the flurry when the queue
// is exhausted.
function BlinkTick()
{
    local KFPawn_Monster KFM;
    local vector Dest, Dir;

    if (OwnerPawn == None || OwnerPawn.Health <= 0)
    {
        FinishBlink();
        return;
    }

    KFM = None;
    while (BlinkIndex < BlinkQueue.Length)
    {
        KFM = BlinkQueue[BlinkIndex];
        BlinkIndex++;
        if (KFM != None && KFM.IsAliveAndWell())
            break;
        KFM = None;
    }

    if (KFM == None)
    {
        FinishBlink();
        return;
    }

    // Land just short of the zed, on the side we are coming from.
    Dir = Normal(OwnerPawn.Location - KFM.Location);
    if (IsZero(Dir))
        Dir = vect(1, 0, 0);
    Dest = KFM.Location + Dir * class'ZTUpgrade_Perk_Speedster'.default.BlinkStandoff;
    Dest.Z = KFM.Location.Z + 20.0f;
    OwnerPawn.SetLocation(Dest);

    StrikeTarget(KFM);

    if (BlinkIndex >= BlinkQueue.Length)
        FinishBlink();
}

// The devastating strike: % of the target's max health (trash dies outright;
// large zeds/bosses take a reduced chunk), plus a knockdown, plus skill riders
// (Giant-Killer, Concussive, Shockfront, Hunter's Mark, Momentum) and the
// capstone-2 cleave shockwave.
function StrikeTarget(KFPawn_Monster KFM)
{
    local int Dmg;
    local float Pct, LargeMult, KnockScale;
    local vector Push;
    local bool bBig;

    Pct = class'ZTUpgrade_Perk_Speedster'.default.BlinkStrikePctHP;
    bBig = KFM.IsLargeZed() || KFM.IsABoss() || KFInterface_MonsterBoss(KFM) != None;

    if (bBig)
    {
        if (PerkLevel >= class'ZTConfig_Capstone'.static.GetRank2Level())
            LargeMult = class'ZTUpgrade_Perk_Speedster'.default.BlinkStrikeLargeMultCapstone20;
        else
            LargeMult = class'ZTUpgrade_Perk_Speedster'.default.BlinkStrikeLargeMult;

        // Giant-Killer skill: scale up the reduced giant/boss chunk.
        if (GiantKillerLevel >= 1)
            LargeMult *= 1.0f + class'ZTUpgrade_Skill_GiantKiller'.default.ChunkBonus[GiantKillerLevel - 1];

        Dmg = Round(float(KFM.HealthMax) * Pct * LargeMult);
    }
    else
    {
        Dmg = Round(float(KFM.HealthMax) * Pct);
    }

    if (Dmg < 1)
        Dmg = 1;

    Push = Normal(KFM.Location - OwnerPawn.Location);
    if (IsZero(Push))
        Push = vect(1, 0, 0);

    KFM.TakeDamage(Dmg, DKPC, KFM.Location, Push * 1000.0f, class'ZTDT_BlinkStrike', , OwnerPawn);

    // Momentum: count this dash kill.
    if (MomentumLevel >= 1 && !KFM.IsAliveAndWell())
        DashKills++;

    // Knockdown (Concussive Blink scales the force).
    KnockScale = 1.0f;
    if (ConcussiveLevel >= 1)
        KnockScale = 1.0f + class'ZTUpgrade_Skill_ConcussiveBlink'.default.KnockdownBonus[ConcussiveLevel - 1];

    if (KFM.IsAliveAndWell() && KFM.CanDoSpecialMove(SM_Knockdown))
        KFM.Knockdown(Push * (400.0f * KnockScale), vect(1, 1, 1), KFM.Location, 1000.0f * KnockScale, 100.0f * KnockScale);

    // Hunter's Mark: tag survivors for bonus follow-up damage (after the strike,
    // so the strike itself does not self-buff and one-shot trash is irrelevant).
    if (HuntersMarkLevel >= 1 && KFM.IsAliveAndWell())
        MarkZed(KFM);

    // Shockfront skill: independent AoE around every landing, pre-capstone.
    if (ShockfrontLevel >= 1)
        DoShockfront(KFM, Dmg);

    // Capstone 2: cleave a fraction of the strike into nearby zeds.
    if (PerkLevel >= class'ZTConfig_Capstone'.static.GetRank2Level())
        Cleave(KFM, Dmg);
}

// Capstone-2 cleave (perk-driven).
function Cleave(KFPawn_Monster Center, int BaseDmg)
{
    local KFPawn_Monster M;
    local int Dmg;
    local float Radius;
    local vector Push;

    Dmg = Round(float(BaseDmg) * class'ZTUpgrade_Perk_Speedster'.default.CleaveFrac);
    if (Dmg < 1 || Center == None)
        return;

    Radius = class'ZTUpgrade_Perk_Speedster'.default.CleaveRadius;

    foreach OwnerPawn.WorldInfo.AllPawns(class'KFPawn_Monster', M, Center.Location, Radius)
    {
        if (M == Center || !M.IsAliveAndWell())
            continue;

        Push = Normal(M.Location - Center.Location);
        if (IsZero(Push))
            Push = vect(1, 0, 0);

        M.TakeDamage(Dmg, DKPC, M.Location, Push * 500.0f, class'ZTDT_BlinkStrike', , OwnerPawn);
    }
}

// Shockfront skill: small AoE pulse around a strike, independent of the
// capstone cleave (so it works the moment the skill is bought, and stacks).
function DoShockfront(KFPawn_Monster Center, int StrikeDmg)
{
    local KFPawn_Monster M;
    local int Dmg;
    local float Radius;
    local vector Push;

    if (Center == None || ShockfrontLevel < 1)
        return;

    Radius = class'ZTUpgrade_Skill_Shockfront'.default.Radius[ShockfrontLevel - 1];
    Dmg = Round(float(StrikeDmg) * class'ZTUpgrade_Skill_Shockfront'.default.DamageFrac[ShockfrontLevel - 1]);
    if (Dmg < 1)
        return;

    foreach OwnerPawn.WorldInfo.AllPawns(class'KFPawn_Monster', M, Center.Location, Radius)
    {
        if (M == Center || !M.IsAliveAndWell())
            continue;

        Push = Normal(M.Location - Center.Location);
        if (IsZero(Push))
            Push = vect(1, 0, 0);

        M.TakeDamage(Dmg, DKPC, M.Location, Push * 400.0f, class'ZTDT_BlinkStrike', , OwnerPawn);
    }
}

// ===================================================================
// HUNTER'S MARK registry (read live by the skill's ModifyDamageGiven)
// ===================================================================
function MarkZed(KFPawn_Monster KFM)
{
    local int i;
    local SMarkedZed M;
    local float Dur;

    if (KFM == None || HuntersMarkLevel < 1)
        return;

    Dur = class'ZTUpgrade_Skill_HuntersMark'.default.MarkDuration;

    for (i = 0; i < MarkedZeds.Length; i++)
    {
        if (MarkedZeds[i].Zed == KFM)
        {
            MarkedZeds[i].Expiry = WorldInfo.TimeSeconds + Dur;
            return;
        }
    }

    M.Zed = KFM;
    M.Expiry = WorldInfo.TimeSeconds + Dur;
    MarkedZeds.AddItem(M);
}

function bool IsMarked(KFPawn_Monster KFM)
{
    local int i;

    if (KFM == None || HuntersMarkLevel < 1)
        return false;

    // Prune stale/dead entries as we scan.
    for (i = MarkedZeds.Length - 1; i >= 0; i--)
    {
        if (MarkedZeds[i].Zed == None || WorldInfo.TimeSeconds > MarkedZeds[i].Expiry)
        {
            MarkedZeds.Remove(i, 1);
            continue;
        }

        if (MarkedZeds[i].Zed == KFM)
            return true;
    }

    return false;
}

// ===================================================================
// SOUND - dedicated-safe activation cue (routed through the controller RPC,
// NOT PlaySoundBase from server context).
// ===================================================================
function PlayBlinkSound()
{
    local ZTMutator Mut;
    local SoundCue Cue;

    if (DKPC == None)
        return;

    Mut = class'ZTSoundManager'.static.GetMutator(WorldInfo);
    if (Mut == None)
        return;

    Cue = class'ZTSoundManager'.static.GetSound(Mut, 'BlinkStrike_Activate');
    if (Cue != None)
        DKPC.ClientPlayBuffSound(Cue);
}

// Queue exhausted (or owner down): return to the start point and hold invuln
// for the tail before ending.
function FinishBlink()
{
    ClearTimer(nameof(BlinkTick));

    if (OwnerPawn != None && OwnerPawn.Health > 0)
        OwnerPawn.SetLocation(StartLocation);

    SetTimer(class'ZTUpgrade_Perk_Speedster'.default.InvulnTail, false, nameof(EndBlink));
}

function EndBlink()
{
    local float Refund, CD;

    bBlinking = false;
    bNetDirty = true;

    bOnCooldown = true;
    CD = GetCooldown();
    Refund = 0.0f;

    // Momentum: refund cooldown per dash kill, capped at 75% of the cooldown.
    if (MomentumLevel >= 1 && DashKills > 0)
    {
        Refund = FMin(float(DashKills) * class'ZTUpgrade_Skill_Momentum'.default.RefundPerKill[MomentumLevel - 1], CD * 0.75f);
        CD -= Refund;
    }

    // Shift the start back so UpdateAbility (which compares against the full
    // GetCooldown) reads the refund, and the HUD bar uses the trimmed length.
    CooldownStart = WorldInfo.TimeSeconds - Refund;

    ClientSpeedsterHUD(HUD_COOLDOWN, FMax(CD, 0.0f));
}

// ===================================================================
// COOLDOWN TICK
// ===================================================================
function UpdateAbility()
{
    local float CD, Elapsed;

    if (OwnerPawn == None || OwnerPawn.Health <= 0)
        return;

    if (bOnCooldown)
    {
        CD = GetCooldown();
        Elapsed = WorldInfo.TimeSeconds - CooldownStart;

        if (Elapsed >= CD)
        {
            bOnCooldown = false;
            PushHUD(HUD_READY);
            class'ZTMessageManager'.static.SendImportant(DKPC, "Blink Strike ready!");
        }
    }
}

// ===================================================================
// HUD - server pushes a state; the owning client records its own EndTime
// and animates the bar in ZTHudWrapper.DrawSpeedsterCard.
// ===================================================================
function PushHUD(byte State)
{
    local float Dur;

    if (State == HUD_COOLDOWN)
        Dur = GetCooldown();
    else if (State == HUD_ACTIVE)
        Dur = class'ZTUpgrade_Perk_Speedster'.default.InvulnTail + 0.3f;
    else
        Dur = 0.0f;   // Ready: full slim bar, no drain

    ClientSpeedsterHUD(State, Dur);
}

function ClearHUD()
{
    ClientSpeedsterHUD(255, 0.0f);   // 255 = hide
}

reliable client function ClientSpeedsterHUD(byte State, float Duration)
{
    local KFPlayerController LocalPC;
    local ZTHudWrapper HUD;

    LocalPC = KFPlayerController(GetALocalPlayerController());
    if (LocalPC == None)
        return;

    HUD = class'ZTHudWrapper'.static.GetReaperHUD(LocalPC);
    if (HUD == None)
        return;

    if (State == 255)
        HUD.ClearSpeedsterDisplay();
    else
        HUD.UpdateSpeedsterDisplay(State, Duration);
}

// ===================================================================
// WAVE / CLEANUP
// ===================================================================
function OnWaveEnd()
{
    // Cancel any in-flight dash and clear the cooldown for a fresh wave.
    ClearTimer(nameof(BlinkTick));
    ClearTimer(nameof(EndBlink));

    if (bBlinking && OwnerPawn != None && OwnerPawn.Health > 0)
        OwnerPawn.SetLocation(StartLocation);

    bBlinking = false;
    bOnCooldown = false;
    bNetDirty = true;

    DashKills = 0;
    MarkedZeds.Length = 0;

    PushHUD(HUD_READY);
}

function Cleanup()
{
    ClearTimer(nameof(BlinkTick));
    ClearTimer(nameof(EndBlink));
    ClearTimer(nameof(UpdateAbility));
    MarkedZeds.Length = 0;
    ClearHUD();
}

simulated function Destroyed()
{
    Cleanup();
    Super.Destroyed();
}

defaultproperties
{
    RemoteRole=ROLE_SimulatedProxy
    bOnlyRelevantToOwner=True
    bAlwaysRelevant=False
    bHidden=True

    bBlinking=False
    bOnCooldown=False
    PerkLevel=1

    Name="Default__ZTUpgrade_Perk_Speedster_Helper"
}
