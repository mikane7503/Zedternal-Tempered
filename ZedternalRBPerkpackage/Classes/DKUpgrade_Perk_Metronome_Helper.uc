// ===================================================================
// DKUpgrade_Perk_Metronome_Helper — Per-Player State Manager
//
// Manages phase rotation, sync kill tracking, permanent bonuses,
// Harmony overlap (L10), Crescendo burst (L20), HUD + sound.
//
// HUD Integration: Reliable client RPCs → DKHudWrapper.UpdateMetronomeCard()
// Sound Integration: DKSoundManager → DKPlayerController.ClientPlayBuffSound()
//
// CRITICAL: Timer only runs on ROLE_Authority. GetHelper() in the perk
// class must NOT spawn on clients — client reads go through the
// replicated proxy which has no timer. All state lives server-side
// and is pushed to client via reliable RPCs.
// ===================================================================
class DKUpgrade_Perk_Metronome_Helper extends Info
    transient;

// Phase constants (duplicated from perk for helper access)
const PHASE_ASSAULT   = 0;
const PHASE_TEMPO     = 1;
const PHASE_MOMENTUM  = 2;
const PHASE_BASTION   = 3;
const NUM_PHASES      = 4;

// ===================================================================
// CORE STATE
// ===================================================================

var int PerkLevel;

// Current phase (0-3)
var byte CurrentPhase;

// Phase timer
var float PhaseTimeRemaining;       // Seconds left in current phase
var float PhaseDuration;            // 20 seconds per phase

// Wave-active tracking (phases only tick during waves)
var bool bWaveActive;               // Cached wave state

// ===================================================================
// HARMONY (Level 10) — Phase Overlap
// ===================================================================

var bool bHarmonyActive;            // True during overlap window
var byte HarmonyPreviousPhase;      // The outgoing phase still active
var float HarmonyTimeRemaining;     // Overlap seconds left
var float HarmonyBaseDuration;      // Base overlap: 2 seconds
var float HarmonyMaxDuration;       // Max overlap: 4 seconds

// ===================================================================
// CRESCENDO (Level 20) — Full Cycle Burst
// ===================================================================

var bool bCrescendoActive;          // True during burst
var float CrescendoTimeRemaining;   // Burst seconds left
var float CrescendoDuration;        // 5 seconds

// Track sync success per phase across current cycle
// Using individual vars because UE3 doesn't support bool arrays
var byte CycleSyncSuccess_0;        // 1 = Assault had good sync this cycle
var byte CycleSyncSuccess_1;        // 1 = Tempo had good sync this cycle
var byte CycleSyncSuccess_2;        // 1 = Momentum had good sync this cycle
var byte CycleSyncSuccess_3;        // 1 = Bastion had good sync this cycle

// ===================================================================
// SYNC TRACKING
// ===================================================================

// Current phase sync kills
var int CurrentSyncKills;

// Rapid kill tracking (Tempo sync)
var float LastKillTime;

// Permanent bonus stacks per phase (individual vars for UE3)
var int PermanentStacks_0;          // Assault
var int PermanentStacks_1;          // Tempo
var int PermanentStacks_2;          // Momentum
var int PermanentStacks_3;          // Bastion

// ===================================================================
// KILL DEDUPLICATION
// ===================================================================

var KFPawn_Monster LastKilledMonster;
var float LastKillDedupeTime;

// ===================================================================
// DISPLAY UPDATE THROTTLE
// ===================================================================

var float LastHUDUpdateTime;
var float HUDUpdateInterval;

// ===================================================================
// SOUND
// ===================================================================

var SoundCue PhaseShiftSound;
var SoundCue SyncKillSound;
var SoundCue CrescendoSound;

// ===================================================================
// INITIALIZATION — Server only
// ===================================================================

function PostBeginPlay()
{
    local DKMutator Mutator;

    super.PostBeginPlay();

    if (Owner == None)
    {
        Destroy();
        return;
    }

    // CRITICAL: Only run timer on server to prevent client-side duplicates
    if (Role != ROLE_Authority)
        return;

    // Load sounds via DKSoundManager
    foreach Owner.WorldInfo.AllActors(class'DKMutator', Mutator)
    {
        PhaseShiftSound = Mutator.GetCustomSound('Metronome_PhaseShift');
        SyncKillSound = Mutator.GetCustomSound('Metronome_SyncKill');
        CrescendoSound = Mutator.GetCustomSound('Metronome_Crescendo');

        if (PhaseShiftSound != None)
            `log("Metronome Helper: Loaded PhaseShift sound");
        if (SyncKillSound != None)
            `log("Metronome Helper: Loaded SyncKill sound");
        if (CrescendoSound != None)
            `log("Metronome Helper: Loaded Crescendo sound");

        break;
    }

    // Start first phase
    CurrentPhase = PHASE_ASSAULT;
    PhaseTimeRemaining = PhaseDuration;
    LastKillTime = 0.0f;
    LastHUDUpdateTime = 0.0f;
    bWaveActive = false;

    // Start server-side tick
    SetTimer(0.25f, true, 'TickPhase');

    `log("Metronome Helper: Initialized (server) for" @ KFPawn_Human(Owner).PlayerReplicationInfo.PlayerName);
}

// ===================================================================
// WAVE STATE CHECK
// ===================================================================

function bool IsWaveActive()
{
    local KFGameReplicationInfo KFGRI;

    KFGRI = KFGameReplicationInfo(Owner.WorldInfo.GRI);
    if (KFGRI == None)
        return false;

    return KFGRI.bWaveIsActive;
}

// ===================================================================
// PHASE TICK — Called every 0.25 seconds, SERVER ONLY
// ===================================================================

function TickPhase()
{
    local float DeltaTime;
    local bool bWaveNow;

    if (Owner == None)
    {
        Destroy();
        return;
    }

    DeltaTime = 0.25f;

    // Check wave state
    bWaveNow = IsWaveActive();

    // Detect wave start: reset phase timer on transition from trader → wave
    if (bWaveNow && !bWaveActive)
    {
        // Wave just started — reset phase to beginning
        CurrentPhase = PHASE_ASSAULT;
        PhaseTimeRemaining = PhaseDuration;
        CurrentSyncKills = 0;
        bHarmonyActive = false;
        // Don't reset Crescendo if active (reward carries over)
        // Don't reset permanent stacks (they persist all match)
        // Reset cycle tracking for the new wave's first cycle
        CycleSyncSuccess_0 = 0;
        CycleSyncSuccess_1 = 0;
        CycleSyncSuccess_2 = 0;
        CycleSyncSuccess_3 = 0;

        `log("Metronome: Wave started — phase reset to ASSAULT");
    }

    bWaveActive = bWaveNow;

    // Only tick phases during active waves
    if (!bWaveActive)
    {
        // During trader: still send HUD update so card shows paused state
        if (Owner.WorldInfo.TimeSeconds - LastHUDUpdateTime >= 1.0f)
        {
            LastHUDUpdateTime = Owner.WorldInfo.TimeSeconds;
            SendHUDUpdate();
        }
        return;
    }

    // Tick Crescendo
    if (bCrescendoActive)
    {
        CrescendoTimeRemaining -= DeltaTime;
        if (CrescendoTimeRemaining <= 0.0f)
        {
            bCrescendoActive = false;
            CrescendoTimeRemaining = 0.0f;
        }
    }

    // Tick Harmony overlap
    if (bHarmonyActive)
    {
        HarmonyTimeRemaining -= DeltaTime;
        if (HarmonyTimeRemaining <= 0.0f)
        {
            bHarmonyActive = false;
            HarmonyTimeRemaining = 0.0f;
        }
    }

    // Tick main phase timer
    PhaseTimeRemaining -= DeltaTime;
    if (PhaseTimeRemaining <= 0.0f)
    {
        TransitionPhase();
    }

    // Throttled HUD update
    if (Owner.WorldInfo.TimeSeconds - LastHUDUpdateTime >= HUDUpdateInterval)
    {
        LastHUDUpdateTime = Owner.WorldInfo.TimeSeconds;
        SendHUDUpdate();
    }
}

// ===================================================================
// PHASE TRANSITION
// ===================================================================

function TransitionPhase()
{
    local byte OutgoingPhase;
    local bool bSyncSuccess;
    local float HarmonyDuration;
    local int SyncThreshold;

    OutgoingPhase = CurrentPhase;
    SyncThreshold = class'DKUpgrade_Perk_Metronome'.default.SyncKillsForBonus;

    // Evaluate sync for outgoing phase
    bSyncSuccess = (CurrentSyncKills >= SyncThreshold);

    // Grant permanent bonus if sync was good
    if (bSyncSuccess)
    {
        AddPermanentStack(OutgoingPhase);
    }

    // Track cycle sync success
    SetCycleSyncSuccess(OutgoingPhase, bSyncSuccess);

    // Advance phase
    CurrentPhase = (CurrentPhase + 1) % NUM_PHASES;
    PhaseTimeRemaining = PhaseDuration;
    CurrentSyncKills = 0;

    // Level 10 — Harmony: overlap window
    if (PerkLevel >= class'DKConfig_Capstone'.default.Capstone_Rank1Level)
    {
        // Scale overlap duration by sync performance: 2s base + up to 2s bonus
        HarmonyDuration = HarmonyBaseDuration;
        if (bSyncSuccess)
        {
            // Good sync = longer overlap
            HarmonyDuration = HarmonyMaxDuration;
        }

        bHarmonyActive = true;
        HarmonyPreviousPhase = OutgoingPhase;
        HarmonyTimeRemaining = HarmonyDuration;
    }

    // Level 20 — Crescendo: check if we just completed a full cycle
    if (PerkLevel >= class'DKConfig_Capstone'.default.Capstone_Rank2Level && CurrentPhase == PHASE_ASSAULT)
    {
        // Just finished Bastion → back to Assault = full cycle
        if (CycleSyncSuccess_0 > 0 && CycleSyncSuccess_1 > 0 && CycleSyncSuccess_2 > 0 && CycleSyncSuccess_3 > 0)
        {
            // ALL phases had good sync — trigger Crescendo!
            bCrescendoActive = true;
            CrescendoTimeRemaining = CrescendoDuration;

            PlayMetronomeSound(CrescendoSound);
            `log("Metronome: CRESCENDO triggered! All phases synced this cycle.");
        }

        // Reset cycle tracking
        CycleSyncSuccess_0 = 0;
        CycleSyncSuccess_1 = 0;
        CycleSyncSuccess_2 = 0;
        CycleSyncSuccess_3 = 0;
    }

    // Play phase shift sound
    PlayMetronomeSound(PhaseShiftSound);

    // Immediate HUD update on transition
    SendHUDUpdate();
}

// ===================================================================
// KILL HANDLING — Called from perk's ModifyDamageGiven (server only)
// ===================================================================

function OnKill(bool bIsHeadshot, bool bCloseRange, KFPawn_Monster KilledMonster)
{
    local float CurrentTime;
    local float TimeSinceLastKill;
    local bool bPlayerMoving;
    local bool bSynced;

    if (KilledMonster == None)
        return;

    // Deduplicate
    CurrentTime = Owner.WorldInfo.TimeSeconds;
    if (KilledMonster == LastKilledMonster && (CurrentTime - LastKillDedupeTime) < 0.03f)
        return;

    LastKilledMonster = KilledMonster;
    LastKillDedupeTime = CurrentTime;

    // Check sync condition for CURRENT phase
    bSynced = false;

    switch (CurrentPhase)
    {
        case PHASE_ASSAULT:
            // Sync: headshot kills
            bSynced = bIsHeadshot;
            break;

        case PHASE_TEMPO:
            // Sync: rapid kills (within 3 seconds of previous kill)
            TimeSinceLastKill = CurrentTime - LastKillTime;
            bSynced = (LastKillTime > 0.0f && TimeSinceLastKill <= 3.0f);
            break;

        case PHASE_MOMENTUM:
            // Sync: kills while moving
            if (KFPawn(Owner) != None)
            {
                bPlayerMoving = (VSize(KFPawn(Owner).Velocity) > 50.0f);
            }
            bSynced = bPlayerMoving;
            break;

        case PHASE_BASTION:
            // Sync: close-range kills
            bSynced = bCloseRange;
            break;
    }

    // Also check Harmony overlap phase
    if (!bSynced && bHarmonyActive)
    {
        switch (HarmonyPreviousPhase)
        {
            case PHASE_ASSAULT:
                if (bIsHeadshot) bSynced = true;
                break;
            case PHASE_TEMPO:
                TimeSinceLastKill = CurrentTime - LastKillTime;
                if (LastKillTime > 0.0f && TimeSinceLastKill <= 3.0f) bSynced = true;
                break;
            case PHASE_MOMENTUM:
                if (KFPawn(Owner) != None)
                {
                    if (VSize(KFPawn(Owner).Velocity) > 50.0f) bSynced = true;
                }
                break;
            case PHASE_BASTION:
                if (bCloseRange) bSynced = true;
                break;
        }
    }

    if (bSynced)
    {
        CurrentSyncKills++;

        // Play sync kill sound (throttled: only every 2nd sync to avoid spam)
        if (CurrentSyncKills % 2 == 1)
            PlayMetronomeSound(SyncKillSound);
    }

    // Update last kill time (for Tempo rapid-kill detection)
    LastKillTime = CurrentTime;
}

// ===================================================================
// PHASE QUERY — Used by perk static functions
// ===================================================================

function bool IsPhaseActive(byte Phase)
{
    // Phases are inactive during trader time
    if (!bWaveActive)
        return false;

    // Current phase is always active
    if (CurrentPhase == Phase)
        return true;

    // Harmony overlap: previous phase is also active
    if (bHarmonyActive && HarmonyPreviousPhase == Phase)
        return true;

    return false;
}

// ===================================================================
// PERMANENT BONUS
// ===================================================================

function float GetPermanentBonus(byte Phase)
{
    local float BonusPerStack;

    BonusPerStack = class'DKUpgrade_Perk_Metronome'.default.PermanentBonusPerStack;

    switch (Phase)
    {
        case 0: return float(PermanentStacks_0) * BonusPerStack;
        case 1: return float(PermanentStacks_1) * BonusPerStack;
        case 2: return float(PermanentStacks_2) * BonusPerStack;
        case 3: return float(PermanentStacks_3) * BonusPerStack;
        default: return 0.0f;
    }
}

function AddPermanentStack(byte Phase)
{
    switch (Phase)
    {
        case 0: PermanentStacks_0++; break;
        case 1: PermanentStacks_1++; break;
        case 2: PermanentStacks_2++; break;
        case 3: PermanentStacks_3++; break;
    }
}

function SetCycleSyncSuccess(byte Phase, bool bSuccess)
{
    local byte Val;

    if (bSuccess)
        Val = 1;
    else
        Val = 0;

    switch (Phase)
    {
        case 0: CycleSyncSuccess_0 = Val; break;
        case 1: CycleSyncSuccess_1 = Val; break;
        case 2: CycleSyncSuccess_2 = Val; break;
        case 3: CycleSyncSuccess_3 = Val; break;
    }
}

function int GetPermanentStackCount(byte Phase)
{
    switch (Phase)
    {
        case 0: return PermanentStacks_0;
        case 1: return PermanentStacks_1;
        case 2: return PermanentStacks_2;
        case 3: return PermanentStacks_3;
        default: return 0;
    }
}

// ===================================================================
// SOUND PLAYBACK — DKSoundManager pattern
// ===================================================================

function PlayMetronomeSound(SoundCue Sound)
{
    local DKPlayerController DKPC;

    if (Sound == None || Owner == None)
        return;

    if (KFPawn_Human(Owner) != None)
    {
        DKPC = DKPlayerController(KFPawn_Human(Owner).Controller);
        if (DKPC != None)
            DKPC.ClientPlayBuffSound(Sound);
    }
}

// ===================================================================
// HUD UPDATE — Reliable Client RPC → DKHudWrapper
// ===================================================================

function SendHUDUpdate()
{
    local int SyncThreshold;
    local byte Stacks0, Stacks1, Stacks2, Stacks3;
    local byte HarmonyPhase;
    local byte PhaseTimePct;

    SyncThreshold = class'DKUpgrade_Perk_Metronome'.default.SyncKillsForBonus;

    Stacks0 = byte(Clamp(PermanentStacks_0, 0, 255));
    Stacks1 = byte(Clamp(PermanentStacks_1, 0, 255));
    Stacks2 = byte(Clamp(PermanentStacks_2, 0, 255));
    Stacks3 = byte(Clamp(PermanentStacks_3, 0, 255));

    if (bHarmonyActive)
        HarmonyPhase = HarmonyPreviousPhase;
    else
        HarmonyPhase = 255; // None

    // Phase time as percentage (0-100)
    PhaseTimePct = byte(Clamp(int((PhaseTimeRemaining / PhaseDuration) * 100.0f), 0, 100));

    ClientUpdateMetronomeHUD(
        CurrentPhase,
        PhaseTimePct,
        byte(Clamp(CurrentSyncKills, 0, 255)),
        byte(SyncThreshold),
        Stacks0, Stacks1, Stacks2, Stacks3,
        bHarmonyActive,
        HarmonyPhase,
        bCrescendoActive
    );
}

reliable client function ClientUpdateMetronomeHUD(
    byte Phase,
    byte PhaseTimePct,
    byte SyncKills,
    byte SyncTarget,
    byte S0, byte S1, byte S2, byte S3,
    bool bHarmony,
    byte HarmPhase,
    bool bCrescendo)
{
    local KFPlayerController KFPC;
    local DKHudWrapper HUD;

    KFPC = KFPlayerController(GetALocalPlayerController());
    if (KFPC == None)
        return;

    HUD = class'DKHudWrapper'.static.GetReaperHUD(KFPC);
    if (HUD != None)
    {
        HUD.UpdateMetronomeCard(Phase, PhaseTimePct, SyncKills, SyncTarget,
            S0, S1, S2, S3, bHarmony, HarmPhase, bCrescendo);
    }
}

reliable client function ClientClearMetronomeHUD()
{
    local KFPlayerController KFPC;
    local DKHudWrapper HUD;

    KFPC = KFPlayerController(GetALocalPlayerController());
    if (KFPC == None)
        return;

    HUD = class'DKHudWrapper'.static.GetReaperHUD(KFPC);
    if (HUD != None)
        HUD.ClearMetronomeCard();
}

// ===================================================================
// CLEANUP
// ===================================================================

event Destroyed()
{
    ClientClearMetronomeHUD();
    super.Destroyed();
}

// ===================================================================
// DEFAULT PROPERTIES
// ===================================================================

defaultproperties
{
    PhaseDuration=20.0f

    // Harmony (Level 10)
    HarmonyBaseDuration=2.0f
    HarmonyMaxDuration=4.0f

    // Crescendo (Level 20)
    CrescendoDuration=5.0f

    // State init
    CurrentPhase=0
    CurrentSyncKills=0
    PermanentStacks_0=0
    PermanentStacks_1=0
    PermanentStacks_2=0
    PermanentStacks_3=0
    CycleSyncSuccess_0=0
    CycleSyncSuccess_1=0
    CycleSyncSuccess_2=0
    CycleSyncSuccess_3=0
    bHarmonyActive=false
    bCrescendoActive=false
    bWaveActive=false
    LastKillTime=0.0f
    LastKillDedupeTime=0.0f

    // HUD throttle
    HUDUpdateInterval=0.25f
    LastHUDUpdateTime=0.0f

    // Replication (RPCs only, no replicated vars)
    RemoteRole=ROLE_SimulatedProxy
    bOnlyRelevantToOwner=true

    Name="Default__DKUpgrade_Perk_Metronome_Helper"
}
