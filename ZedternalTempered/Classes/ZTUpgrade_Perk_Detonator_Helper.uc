// ===================================================================
// ZTUpgrade_Perk_Detonator_Helper - State machine for the Detonator perk
//
// Charging mode: Each kill increments the counter. When the counter
// hits the rank-scaled threshold, the perk flips to active mode.
//
// Active mode: A 10-second window where every kill triggers a contact-
// radius detonation at the dying zed's location. After the window
// expires, the perk flips back to charging mode (with any Apex Charge
// bank carrying over). Self-damage is filtered by the projectile.
//
//   Threshold: 50 - rank          -- 50 at R0, 30 at R20
//              Hair Trigger:  -5 standard / -10 deluxe
//   Window:    10 seconds base
//              Hair Trigger:  +3s standard / +6s deluxe
//   Damage:    400 + (rank * 30)   -- 400 at R0, 1000 at R20
//   Radius:    300 + (rank * 5)    -- 300 at R0, 400 at R20
//
// Counter persists across waves.
//
// SKILL INTEGRATION (via WMPerk.ExtensionFuncInteger):
//   "DetonatorHairTrigger"  - threshold reduction + window extension
//   "DetonatorSlowBurn"     - ground fire pool after detonation
//   "DetonatorApexCharge"   - boss-kill specials (instant fill, multipliers, bank)
//   "DetonatorDaisyChain"   - tag survivors; tagged death chains a detonation
// GetSkillLevel returns 0 = inactive, 1 = standard, 2 = deluxe.
// ===================================================================
class ZTUpgrade_Perk_Detonator_Helper extends Actor;

// ===================================================================
// CONSTANTS
// ===================================================================

const BASE_THRESHOLD = 50;
const RANK_THRESHOLD_REDUCTION = 1.0f;
const BASE_WINDOW_DURATION = 10.0f;
const BASE_DAMAGE = 400.0f;
const RANK_DAMAGE_BONUS = 30.0f;
const BASE_RADIUS = 300.0f;
const RANK_RADIUS_BONUS = 5.0f;

const HAIR_TRIGGER_STD_REDUCTION = 5;
const HAIR_TRIGGER_DLX_REDUCTION = 10;
const HAIR_TRIGGER_STD_WINDOW = 3.0f;
const HAIR_TRIGGER_DLX_WINDOW = 6.0f;

const APEX_STD_DMG_MULT = 1.5f;
const APEX_STD_RAD_MULT = 1.25f;
const APEX_DLX_DMG_MULT = 2.5f;
const APEX_DLX_RAD_MULT = 1.5f;
const APEX_DLX_BANK_FRAC = 0.5f;

const SLOW_BURN_STD_DURATION = 6.0f;
const SLOW_BURN_DLX_DURATION = 10.0f;
const SLOW_BURN_STD_DPS = 30;
const SLOW_BURN_DLX_DPS = 60;

const DAISY_CHAIN_STD_MAX = 8;
const DAISY_CHAIN_DLX_MAX = 12;
const DAISY_CHAIN_STD_DECAY = 20.0f;
const DAISY_CHAIN_DLX_DECAY = 30.0f;
const DAISY_CHAIN_DLX_RADIUS_MULT = 1.5f;

// ===================================================================
// STATE
// ===================================================================

// --- Perk state ---
var int PerkLevel;
var KFPawn_Human Player;

// --- Wave tracking (logging only -- counter persists across waves) ---
var int CurrentWaveNum;
var int LastWaveNum;

// --- Counter state ---
var int Counter;            // current kills toward threshold (charging mode)
var int ApexBank;           // pre-charge banked from Deluxe Apex Charge

// --- Active window state ---
var bool bWindowActive;
var float WindowEndTime;    // WorldInfo.TimeSeconds when window expires
var bool bWindowEndPending; // suppresses double-trigger of EndActiveWindow

// --- Daisy Chain tag tracking ---
struct DaisyTag
{
    var KFPawn_Monster Zed;
    var float ExpireTime;
};
var array<DaisyTag> TaggedZeds;

// --- Replicated display data (computed server-side, sent via RPC) ---
var int RepCounter;
var int RepThreshold;
var bool RepWindowActive;
var int RepWindowSecondsLeft;
var int RepWindowMaxSeconds;
var int RepApexBank;

// ===================================================================
// INITIALIZATION
// ===================================================================

simulated event PostBeginPlay()
{
    Super.PostBeginPlay();

    Player = KFPawn_Human(Owner);
    LastWaveNum = -1;

    // Periodic Daisy Chain tag cleanup
    SetTimer(2.0f, true, 'CleanupExpiredTags');

    `log("Detonator Helper: Initialized for" @ Player);
}

function SetPerkLevel(int NewLevel)
{
    PerkLevel = NewLevel;
}

// ===================================================================
// TICK -- wave logging + window-end safety net
// ===================================================================

function Tick(float DeltaTime)
{
    local int WaveNum;

    Super.Tick(DeltaTime);

    if (Player == None || Player.Health <= 0)
        return;

    if (Player.WorldInfo.GRI == None)
        return;

    WaveNum = KFGameReplicationInfo(Player.WorldInfo.GRI).WaveNum;
    if (WaveNum != LastWaveNum && WaveNum > 0)
    {
        CurrentWaveNum = WaveNum;
        LastWaveNum = WaveNum;
    }

    // Safety net for the active-window auto-end timer
    if (bWindowActive && !bWindowEndPending && WorldInfo.TimeSeconds >= WindowEndTime)
    {
        bWindowEndPending = True;
        EndActiveWindow();
    }
}

// ===================================================================
// THRESHOLD / WINDOW / DAMAGE / RADIUS COMPUTATION
// ===================================================================

function int ComputeThreshold()
{
    local int T;
    local int HairTrigLvl;

    T = Round(float(BASE_THRESHOLD) - float(PerkLevel) * RANK_THRESHOLD_REDUCTION);

    HairTrigLvl = GetSkillLevel("DetonatorHairTrigger");
    if (HairTrigLvl == 1)
        T -= HAIR_TRIGGER_STD_REDUCTION;
    else if (HairTrigLvl >= 2)
        T -= HAIR_TRIGGER_DLX_REDUCTION;

    return Max(1, T);
}

function float ComputeWindowDuration()
{
    local float D;
    local int HairTrigLvl;

    D = BASE_WINDOW_DURATION;

    HairTrigLvl = GetSkillLevel("DetonatorHairTrigger");
    if (HairTrigLvl == 1)
        D += HAIR_TRIGGER_STD_WINDOW;
    else if (HairTrigLvl >= 2)
        D += HAIR_TRIGGER_DLX_WINDOW;

    return D;
}

function float ComputeBaseDamage()
{
    return BASE_DAMAGE + (float(PerkLevel) * RANK_DAMAGE_BONUS);
}

function float ComputeBaseRadius()
{
    return BASE_RADIUS + (float(PerkLevel) * RANK_RADIUS_BONUS);
}

// ===================================================================
// SKILL QUERY (mirrors Gambit pattern)
// Returns 0 = not owned, 1 = standard, 2 = deluxe.
// ===================================================================

function int GetSkillLevel(string SkillID)
{
    local WMPerk MyPerk;

    if (Player == None || Player.Controller == None)
        return 0;

    MyPerk = WMPerk(KFPlayerController(Player.Controller).GetPerk());
    if (MyPerk == None)
        return 0;

    return MyPerk.ExtensionFuncInteger(0, SkillID);
}

// ===================================================================
// KILL HANDLER (called from ZTUpgrade_Perk_Detonator.ModifyDamageGiven)
// ===================================================================

function OnZedKilled(KFPawn_Monster KFPM, KFWeapon MyKFW)
{
    local bool bIsBoss;
    local int TagIdx;
    local bool bWasTagged;

    if (KFPM == None)
        return;

    bIsBoss = IsBossClass(KFPM);

    // Daisy Chain: was this zed tagged?
    bWasTagged = False;
    TagIdx = FindTagIndex(KFPM);
    if (TagIdx != INDEX_NONE)
    {
        bWasTagged = True;
        TaggedZeds.Remove(TagIdx, 1);
    }

    // Active-window kill: the in-window detonation (depth 0) wins over
    // any chain trigger -- a tagged zed dying during the window still
    // gets the full active-window detonation with Apex Charge multipliers.
    // The tag is silently consumed.
    if (bWindowActive)
    {
        SpawnDetonationAt(KFPM, bIsBoss, 0);
        // No counter increment during active window
        UpdateClientDisplay();
        return;
    }

    // Charging mode: tagged kill fires a chain detonation at depth 1.
    // The kill ALSO still counts for normal counter progression below.
    if (bWasTagged)
    {
        SpawnDetonationAt(KFPM, bIsBoss, 1);
    }

    // Charging mode: counter logic + Apex Charge specials
    HandleChargingModeKill(bIsBoss);
}

function HandleChargingModeKill(bool bIsBoss)
{
    local int ApexLvl;
    local int Threshold;

    Threshold = ComputeThreshold();

    // Apex Charge: boss kills are special
    if (bIsBoss)
    {
        ApexLvl = GetSkillLevel("DetonatorApexCharge");
        if (ApexLvl > 0)
        {
            // Standard and Deluxe both instant-fill the counter.
            Counter = Threshold;

            // Deluxe additionally banks +50% pre-charge for the next cycle.
            if (ApexLvl >= 2)
            {
                ApexBank = Max(ApexBank, Round(float(Threshold) * APEX_DLX_BANK_FRAC));
            }

            StartActiveWindow();
            return;
        }
    }

    // Standard kill: increment counter, flip if threshold reached.
    Counter += 1;

    if (Counter >= Threshold)
    {
        StartActiveWindow();
    }
    else
    {
        UpdateClientDisplay();
    }
}

// ===================================================================
// ACTIVE WINDOW STATE TRANSITIONS
// ===================================================================

function StartActiveWindow()
{
    local float Duration;

    Duration = ComputeWindowDuration();

    bWindowActive = True;
    bWindowEndPending = False;
    Counter = 0;                                  // counter unused during active mode
    WindowEndTime = WorldInfo.TimeSeconds + Duration;

    // Auto-end timer (Tick is the safety net)
    SetTimer(Duration, false, 'EndActiveWindow');

    // Live HUD countdown -- refresh seconds-left every second so the
    // card shows a real ticking clock instead of freezing on the start value.
    SetTimer(1.0f, true, 'TickActiveWindow');

    PlayDetonatorSound('Detonator_WindowStart');

    if (Player != None && Player.Controller != None)
    {
        class'ZTMessageManager'.static.SendCriticalLoc(
            KFPlayerController(Player.Controller),
            'DetonatorWindowStarted',
            string(int(Duration)));
    }

    `log("Detonator Helper: Active window started, duration" @ Duration);
    UpdateClientDisplay();
}

function EndActiveWindow()
{
    if (!bWindowActive)
        return;

    bWindowActive = False;
    bWindowEndPending = False;
    ClearTimer('EndActiveWindow');
    ClearTimer('TickActiveWindow');

    // Carry Apex bank into the next cycle
    Counter = ApexBank;
    ApexBank = 0;

    PlayDetonatorSound('Detonator_WindowEnd');

    if (Player != None && Player.Controller != None)
    {
        class'ZTMessageManager'.static.SendImportantLoc(
            KFPlayerController(Player.Controller),
            'DetonatorWindowExpired');
    }

    `log("Detonator Helper: Active window ended; carrying" @ Counter @ "into next cycle");
    UpdateClientDisplay();
}

// Live HUD countdown -- runs every 1s while bWindowActive to push fresh
// seconds-left to the client. UpdateClientDisplay re-reads WorldInfo.TimeSeconds
// against WindowEndTime each call. Self-clears as a safety net if state drifts.
function TickActiveWindow()
{
    if (!bWindowActive)
    {
        ClearTimer('TickActiveWindow');
        return;
    }
    UpdateClientDisplay();
}

// ===================================================================
// DETONATION SPAWNING
// ===================================================================

function SpawnDetonationAt(KFPawn_Monster KFPM, bool bIsBoss, int ChainDepth)
{
    local ZTProj_Detonator Proj;
    local vector SpawnLoc;
    local rotator SpawnRot;
    local float Damage, Radius;
    local int ApexLvl, SlowBurnLvl, DaisyLvl;
    local bool bShouldTag;
    local float TagRadius;

    if (Player == None || KFPM == None)
        return;

    Damage = ComputeBaseDamage();
    Radius = ComputeBaseRadius();

    // Apex Charge: in-window boss multipliers (only on original kills, not chains)
    if (bIsBoss && ChainDepth == 0)
    {
        ApexLvl = GetSkillLevel("DetonatorApexCharge");
        if (ApexLvl == 1)
        {
            Damage *= APEX_STD_DMG_MULT;
            Radius *= APEX_STD_RAD_MULT;
        }
        else if (ApexLvl >= 2)
        {
            Damage *= APEX_DLX_DMG_MULT;
            Radius *= APEX_DLX_RAD_MULT;
        }
    }

    // Spawn slightly elevated for a clean explosion at the dying zed's spot.
    SpawnLoc = KFPM.Location;
    SpawnLoc.Z += 32.0f;
    SpawnRot = rot(0,0,0);

    Proj = Player.Spawn(class'ZTProj_Detonator', Player, , SpawnLoc, SpawnRot);
    if (Proj != None)
    {
        Proj.DamageOverride = Damage;
        Proj.RadiusOverride = Radius;
    }

    // Slow Burn: spawn ground fire pool
    SlowBurnLvl = GetSkillLevel("DetonatorSlowBurn");
    if (SlowBurnLvl > 0)
    {
        SpawnGroundFire(SpawnLoc, Radius, SlowBurnLvl);
    }

    // Daisy Chain tagging:
    //   - Standard (lvl 1): tag only on ChainDepth 0
    //   - Deluxe   (lvl 2): tag on ChainDepth 0 and 1 (one bounce)
    DaisyLvl = GetSkillLevel("DetonatorDaisyChain");
    bShouldTag = (DaisyLvl > 0) && (
        (DaisyLvl >= 2 && ChainDepth <= 1) ||
        (DaisyLvl == 1 && ChainDepth == 0)
    );

    if (bShouldTag)
    {
        TagRadius = Radius;
        if (DaisyLvl >= 2)
            TagRadius *= DAISY_CHAIN_DLX_RADIUS_MULT;
        ApplyDaisyChainTags(SpawnLoc, TagRadius, DaisyLvl);
    }
}

function SpawnGroundFire(vector Loc, float ProjectileRadius, int SlowBurnLvl)
{
    local ZTProj_DetonatorGroundFire Fire;
    local KFPlayerController KFPC;
    local float Duration;
    local int Dps;

    if (Player == None || Player.Controller == None)
        return;

    KFPC = KFPlayerController(Player.Controller);
    if (KFPC == None)
        return;

    if (SlowBurnLvl >= 2)
    {
        Duration = SLOW_BURN_DLX_DURATION;
        Dps = SLOW_BURN_DLX_DPS;
    }
    else
    {
        Duration = SLOW_BURN_STD_DURATION;
        Dps = SLOW_BURN_STD_DPS;
    }

    Fire = Player.Spawn(class'ZTProj_DetonatorGroundFire', Player, , Loc, rot(0,0,0));
    if (Fire != None)
    {
        Fire.Duration = Duration;
        Fire.DamagePerTick = Round(float(Dps) * 0.5f); // 0.5s tick interval
        Fire.RadiusSq = ProjectileRadius * ProjectileRadius;
        Fire.InstigatorPC = KFPC;
    }
}

// ===================================================================
// DAISY CHAIN TAG MANAGEMENT
// ===================================================================

function ApplyDaisyChainTags(vector Center, float Radius, int DaisyLvl)
{
    local KFPawn_Monster KFM;
    local DaisyTag NewTag;
    local int MaxTags;
    local float DecayDuration;
    local float RadSq;
    local int Added;

    if (DaisyLvl >= 2)
    {
        MaxTags = DAISY_CHAIN_DLX_MAX;
        DecayDuration = DAISY_CHAIN_DLX_DECAY;
    }
    else
    {
        MaxTags = DAISY_CHAIN_STD_MAX;
        DecayDuration = DAISY_CHAIN_STD_DECAY;
    }

    RadSq = Radius * Radius;
    Added = 0;

    foreach DynamicActors(class'KFPawn_Monster', KFM)
    {
        if (Added >= MaxTags)
            break;

        if (KFM == None || !KFM.IsAliveAndWell())
            continue;

        if (VSizeSQ(KFM.Location - Center) > RadSq)
            continue;

        // Skip already-tagged zeds (one tag per zed)
        if (FindTagIndex(KFM) != INDEX_NONE)
            continue;

        NewTag.Zed = KFM;
        NewTag.ExpireTime = WorldInfo.TimeSeconds + DecayDuration;
        TaggedZeds.AddItem(NewTag);
        Added++;
    }

    if (Added > 0)
        `log("Detonator Helper: Daisy Chain tagged" @ Added @ "zeds (decay" @ DecayDuration $ "s)");
}

function int FindTagIndex(KFPawn_Monster KFPM)
{
    local int i;

    for (i = 0; i < TaggedZeds.Length; i++)
    {
        if (TaggedZeds[i].Zed == KFPM)
            return i;
    }

    return INDEX_NONE;
}

function CleanupExpiredTags()
{
    local int i;
    local float Now;

    Now = WorldInfo.TimeSeconds;

    for (i = TaggedZeds.Length - 1; i >= 0; i--)
    {
        if (TaggedZeds[i].ExpireTime < Now
            || TaggedZeds[i].Zed == None
            || !TaggedZeds[i].Zed.IsAliveAndWell())
        {
            TaggedZeds.Remove(i, 1);
        }
    }
}

// ===================================================================
// UTILITY
// ===================================================================

static function bool IsBossClass(KFPawn_Monster KFPM)
{
    if (KFPM == None)
        return False;

    return KFPM.IsABoss();
}

// ===================================================================
// CLIENT DISPLAY UPDATE (server-builds, client-renders)
// ===================================================================

function UpdateClientDisplay()
{
    local int Threshold;
    local int SecondsLeft;
    local int MaxSeconds;

    Threshold = ComputeThreshold();
    MaxSeconds = int(ComputeWindowDuration());

    if (bWindowActive)
        SecondsLeft = Max(0, int(WindowEndTime - WorldInfo.TimeSeconds));
    else
        SecondsLeft = 0;

    RepCounter = Counter;
    RepThreshold = Threshold;
    RepWindowActive = bWindowActive;
    RepWindowSecondsLeft = SecondsLeft;
    RepWindowMaxSeconds = MaxSeconds;
    RepApexBank = ApexBank;

    ClientUpdateDisplay(RepCounter, RepThreshold, RepWindowActive,
        RepWindowSecondsLeft, RepWindowMaxSeconds, RepApexBank, PerkLevel);
}

// Reliable client RPC -- pushes display data directly to the HUD wrapper.
// Per HUD_Element_Guide: the RPC must call the HUD method DIRECTLY, with
// NO intermediate simulated function in between. Also don't depend on
// Player/Owner here -- Owner may not have replicated yet on the client
// when this RPC fires, which would silently short-circuit the update.
reliable client function ClientUpdateDisplay(int InCounter, int InThreshold,
    bool InActive, int InSecondsLeft, int InMaxSeconds, int InApexBank, int InPerkLevel)
{
    local KFPlayerController KFPC;
    local ZTHudWrapper HUD;

    // Cache rep values for any future simulated readers on the client
    RepCounter = InCounter;
    RepThreshold = InThreshold;
    RepWindowActive = InActive;
    RepWindowSecondsLeft = InSecondsLeft;
    RepWindowMaxSeconds = InMaxSeconds;
    RepApexBank = InApexBank;
    PerkLevel = InPerkLevel;

    // Direct HUD lookup -- GetReaperHUD is the canonical accessor.
    KFPC = KFPlayerController(GetALocalPlayerController());
    if (KFPC == None)
        return;

    HUD = class'ZTHudWrapper'.static.GetReaperHUD(KFPC);
    if (HUD == None)
        return;

    HUD.UpdateDetonatorDisplay(
        true,                       // bIsActive (card visible)
        InActive,
        byte(InPerkLevel),
        InCounter,
        InThreshold,
        byte(InSecondsLeft),
        byte(InMaxSeconds),
        InApexBank);
}

// ===================================================================
// SOUND PLAYBACK (mirrors Gambit pattern)
// ===================================================================

function PlayDetonatorSound(name SoundID)
{
    local ZTPlayerController DKPC;
    local ZTMutator Mut;
    local SoundCue Sound;

    if (Player == None || Player.Controller == None)
        return;

    DKPC = ZTPlayerController(Player.Controller);
    if (DKPC == None)
        return;

    Mut = class'ZTSoundManager'.static.GetMutator(WorldInfo);
    if (Mut == None)
        return;

    Sound = class'ZTSoundManager'.static.GetSound(Mut, SoundID);
    if (Sound != None)
        DKPC.ClientPlayDetonatorSound(Sound);
}

defaultproperties
{
    RemoteRole=ROLE_SimulatedProxy
    bAlwaysRelevant=False
    bOnlyRelevantToOwner=True
    bHidden=True
    bCollideActors=False
    bBlockActors=False

    PerkLevel=1
    Counter=0
    ApexBank=0
    bWindowActive=False
    bWindowEndPending=False

    Name="Default__ZTUpgrade_Perk_Detonator_Helper"
}
