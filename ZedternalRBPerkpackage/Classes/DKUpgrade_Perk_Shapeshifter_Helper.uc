// ===================================================================
// DKUpgrade_Perk_Shapeshifter_Helper
//
// Server-authoritative state manager for the Shapeshifter perk.
// Handles buff rolling, persistent stacking (Mimicry at Rank 20),
// HUD display via DKHudWrapper, and sound framework via DKSoundManager.
//
// REPLICATION FIX: Uses ReplicatedBuffMask (replicated int bitmask)
// so client-side Modify* functions (fire rate, recoil, spread, etc.)
// can query IsBuffActive() and get correct results.
//
// WEAPON FIX: Calls UpdateWeaponMagAndCap() after rolling buffs so
// cached weapon stats (spare ammo, mag size) recalculate immediately.
//
// HUD FIX: Uses standalone ShapeshifterDisplay system instead of
// PerkTracker entries, preventing overlap with other trackers.
//
// BUFF EFFECTIVENESS SYSTEM:
// GetBuffEffectiveness() returns a 0.0-N.0 float per buff that
// accounts for: active state, residual echoes, buff amplification,
// ZED time amplification, and single-buff amplification.
// Skills configure multiplier vars via InitiateWeapon.
//
// BUFF POOL (15 total):
// ---------------------------------------------------------------
// #0  Carnage       Offense   +3% all damage /lvl       Weight 10
// #1  Executioner   Offense   +5% headshot dmg /lvl     Weight 10
// #2  Rampage       Offense   +3% fire rate /lvl        Weight 10
// #3  Crusher       Offense   +5% heavy melee /lvl      Weight 7
// #4  Berserker     Offense   +3% melee speed /lvl      Weight 7
// #5  Fortress      Defense   -2% dmg taken /lvl        Weight 10
// #6  Leech         Defense   +1 HP on kill /lvl        Weight 4
// #7  Anchor        Handling  -3% recoil /lvl           Weight 10
// #8  Hawk          Handling  -3% spread /lvl           Weight 7
// #9  Speedloader   Handling  +3% reload speed /lvl     Weight 10
// #10 Switchblade   Handling  +3% switch speed /lvl     Weight 7
// #11 Speedfreak    Utility   +2% move speed /lvl       Weight 10
// #12 Hoarder       Utility   +5% spare ammo /lvl       Weight 10
// #13 Drumfire      Utility   +3% mag size /lvl         Weight 7
// #14 Phantom       Utility   +5% ZED fire rate /lvl    Weight 4
// ===================================================================
class DKUpgrade_Perk_Shapeshifter_Helper extends Info;

// ===================================================================
// CONSTANTS
// ===================================================================

const TOTAL_BUFFS = 15;
const POLL_INTERVAL = 0.5f;

// Category bitmasks for Chimera Protocol
// Offense:  bits 0-4   = 31
// Defense:  bits 5-6   = 96
// Handling: bits 7-10  = 1920
// Utility:  bits 11-14 = 30720
const CATEGORY_OFFENSE_MASK = 31;
const CATEGORY_DEFENSE_MASK = 96;
const CATEGORY_HANDLING_MASK = 1920;
const CATEGORY_UTILITY_MASK = 30720;

// ===================================================================
// BUFF NAME TABLE
// ===================================================================

var const string BuffNames[15];

// ===================================================================
// BUFF WEIGHT TABLE (for weighted random selection)
// Common=10, Uncommon=7, Rare=4
// ===================================================================

var const int BuffWeights[15];

// ===================================================================
// STATE TRACKING
// ===================================================================

// Current perk level (updated from main perk class)
var int CurrentPerkLevel;

// Active buff tracking (server-side authoritative array)
// Rank 1-9:  only index 0 used
// Rank 10-19: indices 0 and 1 used
// Rank 20+:  permanent accumulation (Mimicry)
var byte ActiveBuffs[15];  // 0=inactive, 1=active

// REPLICATED bitmask - packs 15 buff states into one int.
// This is what IsBuffActive() checks, so it works on BOTH server and client.
var int ReplicatedBuffMask;

// Previous wave's buff mask (for Residual Form skill)
var int PreviousBuffMask;

// Timestamp of last buff roll (for Volatile Shift skill)
var float LastRollTimestamp;

// Number of currently active buffs (for HUD)
var int ActiveBuffCount;

// Track previous wave's buffs to prevent repeats
var int PreviousBuff1;
var int PreviousBuff2;

// Mimicry state (Rank 20+)
var bool bMimicryActive;
var int MimicryStackCount;

// Wave polling state
var int LastKnownWave;
var bool bInitialRollDone;
var bool bPendingWaveStart;
var bool bLastTraderState;

// Player controller reference
var KFPlayerController KFPC;

// Replicated owner identity - PRI references are consistent across
// server and client, unlike Owner which can mismatch on clients.
var PlayerReplicationInfo OwnerPRI;

// Pending second buff sound (for staggered playback at Rank 10+)
var int PendingSecondBuffSound;

// ===================================================================
// SKILL-CONFIGURABLE MULTIPLIERS
//
// Set by Shapeshifter skill upgrades via InitiateWeapon.
// All default to neutral values (no effect).
// GetBuffEffectiveness() combines these into a single output.
// ===================================================================

// Residual Form: previous wave's buffs linger at reduced power
var float ResidualMultiplier;       // 0.0 = disabled (default)
var float ResidualDuration;         // seconds residuals last (0.0 = disabled)

// Overclocked Form: amplify all buff values
var float BuffAmplifier;            // 1.0 = no change (default)

// Flux State: amplify buffs during ZED time
var float ZedTimeBuffMultiplier;    // 1.0 = no change (default)

// Monomorph: amplify single buff when only 1 active
var float SingleBuffAmplifier;      // 1.0 = no change (default)

// Genetic Memory: first-ever buff ghosts permanently
var int FirstBuffIndex;             // -1 = not set yet (default)
var float FirstBuffMultiplier;      // 0.0 = disabled (default)

// ===================================================================
// REPLICATION
// ===================================================================

replication
{
    if (bNetDirty)
        ReplicatedBuffMask, OwnerPRI, PreviousBuffMask, LastRollTimestamp,
        ResidualMultiplier, ResidualDuration, BuffAmplifier,
        ZedTimeBuffMultiplier, SingleBuffAmplifier, FirstBuffIndex,
        FirstBuffMultiplier;
}

// ===================================================================
// INITIALIZATION
// ===================================================================

function PostBeginPlay()
{
    local int i;

    super.PostBeginPlay();

    if (Owner == None)
    {
        Destroy();
        return;
    }

    // Get player controller and set replicated PRI
    KFPC = KFPlayerController(Pawn(Owner).Controller);
    OwnerPRI = Pawn(Owner).PlayerReplicationInfo;

    // Initialize all buffs as inactive
    for (i = 0; i < TOTAL_BUFFS; i++)
    {
        ActiveBuffs[i] = 0;
    }

    ReplicatedBuffMask = 0;
    PreviousBuffMask = 0;
    LastRollTimestamp = 0.0f;
    ActiveBuffCount = 0;
    PreviousBuff1 = -1;
    PreviousBuff2 = -1;
    bMimicryActive = false;
    MimicryStackCount = 0;
    bInitialRollDone = false;
    bPendingWaveStart = false;
    bLastTraderState = true;  // Assume starting in trader
    LastKnownWave = -1;
    PendingSecondBuffSound = -1;

    // Skill multiplier defaults (neutral - no effect)
    ResidualMultiplier = 0.0f;
    ResidualDuration = 0.0f;
    BuffAmplifier = 1.0f;
    ZedTimeBuffMultiplier = 1.0f;
    SingleBuffAmplifier = 1.0f;
    FirstBuffIndex = -1;
    FirstBuffMultiplier = 0.0f;

    // Start wave-state polling
    SetTimer(POLL_INTERVAL, true, 'PollWaveState');

    `log("Shapeshifter Helper: Initialized for" @ Owner.Name);
}

// ===================================================================
// WAVE-START DETECTION (polling with trader awareness)
//
// WaveNum typically changes when the wave ENDS (trader opens).
// We detect that change, then wait for trader to close before rolling.
// This ensures buffs are active the instant zeds start spawning.
// ===================================================================

function PollWaveState()
{
    local KFGameReplicationInfo KFGRI;
    local int CurrentWave;
    local bool bTraderOpen;

    KFGRI = KFGameReplicationInfo(WorldInfo.GRI);
    if (KFGRI == None)
        return;

    CurrentWave = KFGRI.WaveNum;
    bTraderOpen = KFGRI.bTraderIsOpen;

    // Detect wave number change
    if (CurrentWave != LastKnownWave)
    {
        `log("Shapeshifter Helper: WaveNum changed from" @ LastKnownWave @ "to" @ CurrentWave @ "TraderOpen=" $ bTraderOpen);
        LastKnownWave = CurrentWave;

        if (!bTraderOpen)
        {
            // Wave started without trader phase (or we caught it in time)
            // Clear pending flag to prevent double roll from deferred check below
            bPendingWaveStart = false;
            OnWaveStart();
        }
        else
        {
            // WaveNum changed while trader is open - defer roll
            bPendingWaveStart = true;
        }
    }

    // Check if trader just closed with a pending roll
    if (bPendingWaveStart && !bTraderOpen)
    {
        `log("Shapeshifter Helper: Trader closed - executing deferred wave start roll");
        bPendingWaveStart = false;
        OnWaveStart();
    }

    bLastTraderState = bTraderOpen;
}

function OnWaveStart()
{
    if (!bInitialRollDone)
    {
        bInitialRollDone = true;
        RollNewBuffs();
        return;
    }

    if (bMimicryActive)
    {
        AddMimicryBuff();
    }
    else
    {
        RollNewBuffs();
    }
}

// ===================================================================
// PERK LEVEL MANAGEMENT
// ===================================================================

function SetPerkLevel(int NewLevel)
{
    CurrentPerkLevel = NewLevel;

    // Check if we just reached Rank 20
    if (NewLevel >= class'DKConfig_Capstone'.default.Capstone_Rank2Level && !bMimicryActive)
    {
        ActivateMimicry();
    }

    `log("Shapeshifter Helper: Perk level set to" @ NewLevel);
}

// ===================================================================
// BUFF QUERY - LEGACY (still used internally for HUD/message logic)
//
// Uses ReplicatedBuffMask so this works on BOTH server AND client.
// ===================================================================

simulated function bool IsBuffActive(int BuffIndex)
{
    if (BuffIndex < 0 || BuffIndex >= TOTAL_BUFFS)
        return false;

    return ((ReplicatedBuffMask & (1 << BuffIndex)) != 0);
}

// ===================================================================
// BUFF EFFECTIVENESS SYSTEM
//
// Returns a 0.0-N.0 float representing a buff's total effectiveness.
// Combines: active state, residual echoes, and all skill multipliers.
//
// Called by the perk's Modify* functions instead of IsBuffActive().
// Runs on BOTH server and client (simulated).
// ===================================================================

simulated function float GetBuffEffectiveness(int BuffIndex)
{
    local float BuffBase;
    local float Multiplier;
    local int ActiveCount;

    if (BuffIndex < 0 || BuffIndex >= TOTAL_BUFFS)
        return 0.0f;

    // Determine base effectiveness
    if ((ReplicatedBuffMask & (1 << BuffIndex)) != 0)
    {
        // Currently active buff - full power
        BuffBase = 1.0f;
    }
    else
    {
        // Not currently active - check ghost sources (take highest)
        BuffBase = 0.0f;

        // Residual Form: previous wave's buffs linger
        if (ResidualMultiplier > 0.0f && ResidualDuration > 0.0f
            && (PreviousBuffMask & (1 << BuffIndex)) != 0
            && LastRollTimestamp > 0.0f
            && (WorldInfo.TimeSeconds - LastRollTimestamp) < ResidualDuration)
        {
            BuffBase = FMax(BuffBase, ResidualMultiplier);
        }

        if (BuffBase <= 0.0f && !(FirstBuffMultiplier > 0.0f && BuffIndex == FirstBuffIndex))
            return 0.0f;
    }

    // Genetic Memory: first-ever buff always gets bonus (additive on top)
    if (FirstBuffMultiplier > 0.0f && BuffIndex == FirstBuffIndex)
    {
        BuffBase += FirstBuffMultiplier;
    }

    // Start with buff amplifier (Overclocked Form)
    Multiplier = BuffAmplifier;

    // ZED time multiplier (Flux State)
    if (ZedTimeBuffMultiplier > 1.0f && WorldInfo.TimeDilation < 1.0f)
    {
        Multiplier *= ZedTimeBuffMultiplier;
    }

    // Single buff amplifier (Monomorph) - count only CURRENT buffs, not residuals
    if (SingleBuffAmplifier > 1.0f)
    {
        ActiveCount = CountActiveBits(ReplicatedBuffMask);
        if (ActiveCount == 1)
        {
            Multiplier *= SingleBuffAmplifier;
        }
    }

    return BuffBase * Multiplier;
}

// Count number of set bits in a bitmask (up to TOTAL_BUFFS)
simulated function int CountActiveBits(int Mask)
{
    local int Count, i;

    Count = 0;
    for (i = 0; i < TOTAL_BUFFS; i++)
    {
        if ((Mask & (1 << i)) != 0)
            Count++;
    }
    return Count;
}

// Count unique buff categories represented in a bitmask
simulated function int CountActiveCategories(int Mask)
{
    local int Categories;

    Categories = 0;
    if ((Mask & CATEGORY_OFFENSE_MASK) != 0) Categories++;
    if ((Mask & CATEGORY_DEFENSE_MASK) != 0) Categories++;
    if ((Mask & CATEGORY_HANDLING_MASK) != 0) Categories++;
    if ((Mask & CATEGORY_UTILITY_MASK) != 0) Categories++;
    return Categories;
}

// Count active buffs within a specific category bitmask
simulated function int CountBuffsInCategory(int CategoryMask)
{
    return CountActiveBits(ReplicatedBuffMask & CategoryMask);
}

// ===================================================================
// BUFF DESCRIPTION (for HUD display)
// ===================================================================

function string GetBuffDescription(int BuffIndex)
{
    local int Level;

    Level = CurrentPerkLevel;
    if (Level < 1) Level = 1;

    switch (BuffIndex)
    {
        case 0:  return "+" $ (3 * Level) $ "% Damage";
        case 1:  return "+" $ (5 * Level) $ "% Headshot Dmg";
        case 2:  return "+" $ (3 * Level) $ "% Fire Rate";
        case 3:  return "+" $ (5 * Level) $ "% Heavy Melee";
        case 4:  return "+" $ (3 * Level) $ "% Melee Speed";
        case 5:  return "-" $ (2 * Level) $ "% Damage Taken";
        case 6:  return "+" $ (1 * Level) $ " HP on Kill";
        case 7:  return "-" $ (3 * Level) $ "% Recoil";
        case 8:  return "-" $ (3 * Level) $ "% Spread";
        case 9:  return "+" $ (3 * Level) $ "% Reload Speed";
        case 10: return "+" $ (3 * Level) $ "% Switch Speed";
        case 11: return "+" $ (2 * Level) $ "% Move Speed";
        case 12: return "+" $ (5 * Level) $ "% Spare Ammo";
        case 13: return "+" $ (3 * Level) $ "% Mag Size";
        case 14: return "+" $ (5 * Level) $ "% ZED Fire Rate";
        default: return "";
    }
}

// ===================================================================
// BITMASK SYNC
// Packs ActiveBuffs[] into ReplicatedBuffMask and marks dirty.
// Must be called after every change to ActiveBuffs[].
// ===================================================================

function SyncBuffMask()
{
    local int Mask, i;

    Mask = 0;
    for (i = 0; i < TOTAL_BUFFS; i++)
    {
        if (ActiveBuffs[i] != 0)
            Mask = Mask | (1 << i);
    }
    ReplicatedBuffMask = Mask;
    bNetDirty = true;
}

// Legacy wrapper (used by HUD communication)
function int PackBuffMask()
{
    return ReplicatedBuffMask;
}

// ===================================================================
// WEAPON STAT RECALCULATION
// Forces weapons to recalculate cached stats (spare ammo, mag size)
// after buff changes. Only needed server-side; weapon properties
// replicate to clients automatically.
// ===================================================================

function ForceWeaponRecalc()
{
    local WMPlayerController WMPC;

    WMPC = WMPlayerController(KFPC);
    if (WMPC != None)
    {
        WMPC.UpdateWeaponMagAndCap();
        `log("Shapeshifter Helper: Forced weapon recalculation");
    }
}

// ===================================================================
// BUFF ROLLING (Rank 1-19)
// ===================================================================

function RollNewBuffs()
{
    local int NumBuffsToRoll;
    local int Buff1, Buff2;
    local int i;

    // Safety: never roll if Mimicry is active
    if (bMimicryActive)
    {
        `log("Shapeshifter: RollNewBuffs blocked - Mimicry is active");
        return;
    }

    // Determine how many buffs to roll
    if (CurrentPerkLevel >= class'DKConfig_Capstone'.default.Capstone_Rank1Level)
        NumBuffsToRoll = 2;
    else
        NumBuffsToRoll = 1;

    // Store current mask as previous (for Residual Form skill)
    PreviousBuffMask = ReplicatedBuffMask;

    // Record roll timestamp (for Volatile Shift skill)
    LastRollTimestamp = WorldInfo.TimeSeconds;

    // Clear all active buffs
    for (i = 0; i < TOTAL_BUFFS; i++)
    {
        ActiveBuffs[i] = 0;
    }
    ActiveBuffCount = 0;

    // Roll first buff (cannot repeat previous wave's buff 1)
    Buff1 = RollWeightedBuff(PreviousBuff1, -1);
    ActiveBuffs[Buff1] = 1;
    ActiveBuffCount = 1;

    // Record first-ever buff for Genetic Memory skill
    if (FirstBuffIndex == -1 && FirstBuffMultiplier > 0.0f)
    {
        FirstBuffIndex = Buff1;
        bNetDirty = true;
        `log("Shapeshifter: Genetic Memory locked to buff #" $ Buff1 @ "(" $ BuffNames[Buff1] $ ")");
    }

    `log("Shapeshifter: Rolled buff #" $ Buff1 @ "(" $ BuffNames[Buff1] $ ")");

    PlayBuffSound(Buff1);

    if (NumBuffsToRoll >= 2)
    {
        // Roll second buff (cannot be same as buff1 or previous wave's buff 2)
        Buff2 = RollWeightedBuff(Buff1, PreviousBuff2);
        ActiveBuffs[Buff2] = 1;
        ActiveBuffCount = 2;

        `log("Shapeshifter: Rolled second buff #" $ Buff2 @ "(" $ BuffNames[Buff2] $ ")");

        // Stagger second sound by 0.4s to avoid overlap
        PendingSecondBuffSound = Buff2;
        SetTimer(0.4f, false, 'PlayDelayedBuffSound');
    }
    else
    {
        Buff2 = -1;
    }

    // Store for next wave's repeat prevention
    PreviousBuff1 = Buff1;
    PreviousBuff2 = Buff2;

    // Sync bitmask for client replication
    SyncBuffMask();

    // Force weapon recalculation for Hoarder (#12) and Drumfire (#13)
    ForceWeaponRecalc();

    // Update HUD
    UpdateShapeshifterHUD();

    // Send message
    SendBuffMessage(Buff1, Buff2);
}

// ===================================================================
// WEIGHTED RANDOM SELECTION
// ===================================================================

// Roll a weighted random buff, excluding up to two specific indices
function int RollWeightedBuff(int Exclude1, int Exclude2)
{
    local int i;
    local int TotalWeight;
    local int Roll;
    local int RunningWeight;

    // Calculate total weight excluding forbidden indices
    TotalWeight = 0;
    for (i = 0; i < TOTAL_BUFFS; i++)
    {
        if (i != Exclude1 && i != Exclude2)
            TotalWeight += BuffWeights[i];
    }

    if (TotalWeight <= 0)
        return 0; // Failsafe

    Roll = Rand(TotalWeight);
    RunningWeight = 0;

    for (i = 0; i < TOTAL_BUFFS; i++)
    {
        if (i == Exclude1 || i == Exclude2)
            continue;

        RunningWeight += BuffWeights[i];
        if (Roll < RunningWeight)
            return i;
    }

    return 0; // Failsafe
}

// ===================================================================
// MIMICRY SYSTEM (Rank 20+)
// ===================================================================

function ActivateMimicry()
{
    bMimicryActive = true;

    // Current active buffs become first Mimicry stacks
    MimicryStackCount = ActiveBuffCount;

    // Record timestamp (Volatile Shift triggers on Mimicry activation)
    LastRollTimestamp = WorldInfo.TimeSeconds;

    `log("Shapeshifter: MIMICRY ACTIVATED - Buffs are now permanent!");

    if (KFPC != None)
    {
        class'DKMessageManager'.static.SendGameMessage(
            KFPC,
            "MIMICRY AWAKENED - Your forms are now permanent!",
            MP_Critical
        );
    }

    PlayMimicrySound('Shapeshifter_Mimicry_Activate');

    // Sync bitmask and recalculate weapons
    SyncBuffMask();
    ForceWeaponRecalc();

    UpdateShapeshifterHUD();
}

function AddMimicryBuff()
{
    local int NewBuff;
    local int i;
    local int AvailableCount;

    // Count how many buffs are still available
    AvailableCount = 0;
    for (i = 0; i < TOTAL_BUFFS; i++)
    {
        if (ActiveBuffs[i] == 0)
            AvailableCount++;
    }

    // All buffs collected
    if (AvailableCount <= 0)
    {
        `log("Shapeshifter: All 15 Mimicry buffs collected! Full mastery achieved.");

        if (KFPC != None)
        {
            class'DKMessageManager'.static.SendGameMessage(
                KFPC,
                "MIMICRY COMPLETE - All 15 forms mastered!",
                MP_Critical
            );
        }

        PlayMimicrySound('Shapeshifter_Mimicry_Complete');

        UpdateShapeshifterHUD();
        return;
    }

    // Record timestamp (Volatile Shift triggers on new Mimicry buff too)
    LastRollTimestamp = WorldInfo.TimeSeconds;

    // Roll from remaining (uncollected) buffs
    NewBuff = RollMimicryBuff();

    if (NewBuff >= 0 && NewBuff < TOTAL_BUFFS)
    {
        ActiveBuffs[NewBuff] = 1;
        MimicryStackCount++;
        ActiveBuffCount = MimicryStackCount;

        `log("Shapeshifter: Mimicry gained buff #" $ NewBuff @ "(" $ BuffNames[NewBuff] $ ") - Stack" @ MimicryStackCount $ "/15");

        PlayMimicrySound('Shapeshifter_Mimicry_Stack');

        if (KFPC != None)
        {
            DKPlayerController(KFPC).ClientShapeshifterMimicryGain(
                NewBuff,
                GetBuffDescription(NewBuff),
                MimicryStackCount
            );
        }

        // Sync bitmask and recalculate weapons for newly gained buff
        SyncBuffMask();
        ForceWeaponRecalc();
    }

    UpdateShapeshifterHUD();
}

// Roll from only uncollected buffs (weighted)
function int RollMimicryBuff()
{
    local int i;
    local int TotalWeight;
    local int Roll;
    local int RunningWeight;

    TotalWeight = 0;
    for (i = 0; i < TOTAL_BUFFS; i++)
    {
        if (ActiveBuffs[i] == 0)
            TotalWeight += BuffWeights[i];
    }

    if (TotalWeight <= 0)
        return -1;

    Roll = Rand(TotalWeight);
    RunningWeight = 0;

    for (i = 0; i < TOTAL_BUFFS; i++)
    {
        if (ActiveBuffs[i] != 0)
            continue;

        RunningWeight += BuffWeights[i];
        if (Roll < RunningWeight)
            return i;
    }

    return -1;
}

// ===================================================================
// HUD COMMUNICATION
// Uses the standalone ShapeshifterDisplay system on DKHudWrapper
// instead of PerkTracker entries to prevent overlap.
// ===================================================================

function UpdateShapeshifterHUD()
{
    local int Buff1Index, Buff2Index;
    local string Buff1Name, Buff2Name;
    local string Buff1Desc, Buff2Desc;
    local int BuffMask;

    Buff1Index = -1;
    Buff2Index = -1;
    Buff1Name = "";
    Buff2Name = "";
    Buff1Desc = "";
    Buff2Desc = "";
    BuffMask = ReplicatedBuffMask;

    if (bMimicryActive)
    {
        // Mimicry mode: send stack count + bitmask of collected buffs
        ClientUpdateShapeshifterHUD(
            true,
            -1, "", "",
            -1, "", "",
            MimicryStackCount, TOTAL_BUFFS,
            BuffMask
        );
        return;
    }

    // Normal mode: find the 1-2 active buffs
    GetActiveBuffIndicesForDisplay(Buff1Index, Buff2Index);

    if (Buff1Index >= 0 && Buff1Index < TOTAL_BUFFS)
    {
        Buff1Name = BuffNames[Buff1Index];
        Buff1Desc = GetBuffDescription(Buff1Index);
    }
    if (Buff2Index >= 0 && Buff2Index < TOTAL_BUFFS)
    {
        Buff2Name = BuffNames[Buff2Index];
        Buff2Desc = GetBuffDescription(Buff2Index);
    }

    ClientUpdateShapeshifterHUD(
        false,
        Buff1Index, Buff1Name, Buff1Desc,
        Buff2Index, Buff2Name, Buff2Desc,
        0, TOTAL_BUFFS,
        BuffMask
    );
}

// Find active buff indices for display purposes
function GetActiveBuffIndicesForDisplay(out int OutBuff1, out int OutBuff2)
{
    local int i;
    local int Found;

    Found = 0;
    OutBuff1 = -1;
    OutBuff2 = -1;

    // Normal mode: find the 1-2 active buffs
    for (i = 0; i < TOTAL_BUFFS; i++)
    {
        if (ActiveBuffs[i] != 0)
        {
            if (Found == 0)
            {
                OutBuff1 = i;
                Found++;
            }
            else if (Found == 1)
            {
                OutBuff2 = i;
                return;
            }
        }
    }
}

// Client-side HUD update via reliable replication
// Now calls UpdateShapeshifterDisplay() on DKHudWrapper (standalone system)
// instead of the old PerkTracker-based functions.
reliable client function ClientUpdateShapeshifterHUD(
    bool bIsMimicry,
    int Buff1Index, string Buff1Name, string Buff1Desc,
    int Buff2Index, string Buff2Name, string Buff2Desc,
    int StackCount, int MaxStack,
    int BuffMask)
{
    local KFPlayerController LocalKFPC;
    local DKHudWrapper ShapeshifterHUD;

    LocalKFPC = KFPlayerController(GetALocalPlayerController());
    if (LocalKFPC == None) return;

    ShapeshifterHUD = class'DKHudWrapper'.static.GetReaperHUD(LocalKFPC);
    if (ShapeshifterHUD == None) return;

    ShapeshifterHUD.UpdateShapeshifterDisplay(
        bIsMimicry,
        Buff1Index, Buff1Name, Buff1Desc,
        Buff2Index, Buff2Name, Buff2Desc,
        StackCount, MaxStack,
        BuffMask
    );
}

// ===================================================================
// MESSAGE SYSTEM
// ===================================================================

function SendBuffMessage(int Buff1, int Buff2)
{
    local int Buff2Out;
    local string Desc2Out;

    if (KFPC == None)
        return;

    if (Buff2 >= 0 && Buff2 < TOTAL_BUFFS)
    {
        Buff2Out = Buff2;
        Desc2Out = GetBuffDescription(Buff2);
    }
    else
    {
        Buff2Out = -1;
        Desc2Out = "";
    }

    DKPlayerController(KFPC).ClientShapeshifterTransform(
        Buff1,
        GetBuffDescription(Buff1),
        Buff2Out,
        Desc2Out
    );
}

// ===================================================================
// SOUND FRAMEWORK
// ===================================================================

// Play the sound associated with a specific buff activation
// Routes through DKPlayerController client RPC for proper audio playback
function PlayBuffSound(int BuffIndex)
{
    local DKPlayerController DKPC;
    local DKMutator Mutator;
    local SoundCue Sound;

    if (BuffIndex < 0 || BuffIndex >= TOTAL_BUFFS)
        return;

    DKPC = DKPlayerController(KFPC);
    if (DKPC == None)
        return;

    Mutator = class'DKSoundManager'.static.GetMutator(WorldInfo);
    if (Mutator == None)
        return;

    Sound = class'DKSoundManager'.static.GetSound(Mutator, name("Shapeshifter_Buff_" $ BuffNames[BuffIndex]));
    if (Sound != None)
    {
        DKPC.ClientPlayBuffSound(Sound);
        `log("Shapeshifter Sound: Playing" @ BuffNames[BuffIndex]);
    }
}

// Play a Mimicry sound via client RPC
function PlayMimicrySound(name SoundID)
{
    local DKPlayerController DKPC;
    local DKMutator Mutator;
    local SoundCue Sound;

    DKPC = DKPlayerController(KFPC);
    if (DKPC == None)
        return;

    Mutator = class'DKSoundManager'.static.GetMutator(WorldInfo);
    if (Mutator == None)
        return;

    Sound = class'DKSoundManager'.static.GetSound(Mutator, SoundID);
    if (Sound != None)
    {
        DKPC.ClientPlayBuffSound(Sound);
        `log("Shapeshifter Sound: Playing" @ SoundID);
    }
}

// Delayed second buff sound (called by timer for Rank 10+ stagger)
function PlayDelayedBuffSound()
{
    if (PendingSecondBuffSound >= 0)
    {
        PlayBuffSound(PendingSecondBuffSound);
        PendingSecondBuffSound = -1;
    }
}

// ===================================================================
// CLEANUP
// ===================================================================

function Destroyed()
{
    ClearTimer('PollWaveState');
    `log("Shapeshifter Helper: Destroyed");
    super.Destroyed();
}

// ===================================================================
// DEFAULT PROPERTIES
// ===================================================================

defaultproperties
{
    // Ensure replication works
    RemoteRole=ROLE_SimulatedProxy
    bAlwaysRelevant=false
    bOnlyRelevantToOwner=true
    NetUpdateFrequency=1.0f

    CurrentPerkLevel=0
    ReplicatedBuffMask=0
    PreviousBuffMask=0
    LastRollTimestamp=0.0f
    ActiveBuffCount=0
    PreviousBuff1=-1
    PreviousBuff2=-1
    bMimicryActive=false
    MimicryStackCount=0
    bInitialRollDone=false
    bPendingWaveStart=false
    bLastTraderState=true
    LastKnownWave=-1
    PendingSecondBuffSound=-1

    // Skill multiplier defaults (neutral)
    ResidualMultiplier=0.0f
    ResidualDuration=0.0f
    BuffAmplifier=1.0f
    ZedTimeBuffMultiplier=1.0f
    SingleBuffAmplifier=1.0f
    FirstBuffIndex=-1
    FirstBuffMultiplier=0.0f

    // Buff names (indexed 0-14)
    BuffNames(0)="Carnage"
    BuffNames(1)="Executioner"
    BuffNames(2)="Rampage"
    BuffNames(3)="Crusher"
    BuffNames(4)="Berserker"
    BuffNames(5)="Fortress"
    BuffNames(6)="Leech"
    BuffNames(7)="Anchor"
    BuffNames(8)="Hawk"
    BuffNames(9)="Speedloader"
    BuffNames(10)="Switchblade"
    BuffNames(11)="Speedfreak"
    BuffNames(12)="Hoarder"
    BuffNames(13)="Drumfire"
    BuffNames(14)="Phantom"

    // Buff weights: Common(10), Uncommon(7), Rare(4)
    // Total: (7x10)+(5x7)+(3x4) = 70+35+12 = 117
    BuffWeights(0)=10   // Carnage       Common
    BuffWeights(1)=10   // Executioner    Common
    BuffWeights(2)=10   // Rampage        Common
    BuffWeights(3)=7    // Crusher        Uncommon
    BuffWeights(4)=7    // Berserker      Uncommon
    BuffWeights(5)=10   // Fortress       Common
    BuffWeights(6)=4    // Leech          Rare
    BuffWeights(7)=10   // Anchor         Common
    BuffWeights(8)=7    // Hawk           Uncommon
    BuffWeights(9)=10   // Speedloader    Common
    BuffWeights(10)=7   // Switchblade    Uncommon
    BuffWeights(11)=10  // Speedfreak     Common
    BuffWeights(12)=10  // Hoarder        Common
    BuffWeights(13)=7   // Drumfire       Uncommon
    BuffWeights(14)=4   // Phantom        Rare

    // Sound registration: see DKSoundManager.RegisterDefaultSounds()

    Name="Default__DKUpgrade_Perk_Shapeshifter_Helper"
}
