// ===================================================================
// ZTUpgrade_Perk_Omen_Helper - Prophecy Engine
//
// Server-side logic: prophecy draw, condition tracking, blessing/doom
// resolution, personal accumulated buff/debuff storage.
// Client-side: HUD sync via reliable client RPCs.
//
// DOOM SYSTEM: On failure, the player receives a personal curse equal
// to -2x the blessing reward on the same stats. No global ZedBuffs.
//
// SKILL INTEGRATION: Iterates ChildActors of ZTUpgrade_Skill_OmenBase_Helper
// at key moments. Skills modify prophecy behavior via virtual callbacks.
// ===================================================================
class ZTUpgrade_Perk_Omen_Helper extends Info transient;

// ===================================================================
// ENUMS
// ===================================================================

// Prophecy condition types - determines what behavior is tracked
enum EProphecyCondition
{
    PC_HeadshotsOnly,       // Every shot must be a headshot
    PC_NoReload,            // No manual reload (only auto-reload on empty)
    PC_NoSprint,            // No sprinting
    PC_NoHealing,           // No healing received
    PC_CloseQuarters,       // No damage beyond 10m
    PC_NoJump,              // No jumping
    PC_NoWeaponSwitch,      // No weapon switching
    PC_NoDamageTaken,       // Take no damage
    PC_NoMelee,             // No melee/bash damage dealt
    PC_OneMagazine,         // One mag per weapon, must swap to reload
    PC_NoTurns,             // No 90-degree turns
    PC_NoADS,               // No aiming down sights
    PC_StopEvery3s,         // Must stop moving every 3 seconds
    PC_SidearmOnly,         // Sidearm/knife only
    PC_Executioner,         // Every killing blow must be headshot
    PC_KnifeOnly,           // Knife/bash only, no shooting
    PC_ShootOnly,           // Only shoot (no grenade/bash/melee/jump/sprint)
    PC_TriggerDiscipline,   // Max 3 shots then 2s cooldown
    PC_AlternateWeapons     // Must swap weapons between every attack
};

// ===================================================================
// PROPHECY DATA STRUCT
// ===================================================================
struct ProphecyData
{
    var string Name;
    var string BlessingDesc;
    var string WhisperText;
    var EProphecyCondition Condition;
    var byte Tier;

    // Blessing reward values (doom = -2x of the same stats)
    var float RewardDamage;
    var float RewardHeadshotDamage;
    var float RewardDamageResist;
    var float RewardReloadSpeed;
    var float RewardMoveSpeed;
    var int RewardMaxHealth;
    var int RewardMaxArmor;
};

// ===================================================================
// CORE STATE
// ===================================================================
var KFPawn_Human Player;
var int CurrentUpgradeLevel;
var int CurrentWaveNum;

var array<ProphecyData> ProphecyPool;
var int ActiveProphecyIndex;
var int LastProphecyIndex;
var bool bProphecyActive;
var bool bProphecyFailed;
var bool bProphecyCompleted;
var bool bWaveInProgress;

// Tracks whether the current prophecy's condition was hidden by a skill
var bool bCurrentProphecyHidden;

// Replicated HUD data (stored by RPC, pushed by simulated function - Predator pattern)
var string RepTitle;
var string RepCondition;
var string RepReward;
var string RepDoom;
var string RepWhisper;
var byte RepTier;
var byte RepState;
var byte RepIconIndex;

// Level 10: Doom Resilience
var bool bDoomResilienceActive;
var float DoomResilienceEndTime;

// Level 20: Deny Fate
var int DenyFateWaveCounter;
var bool bDenyFateAvailable;
var bool bDenyFateUsed;

// ===================================================================
// ACCUMULATED PLAYER BUFFS (permanent, can go negative from doom)
// ===================================================================
var float AccDamage;
var float AccHeadshotDamage;
var float AccDamageResist;
var float AccReloadSpeed;
var float AccMoveSpeed;
var int AccMaxHealth;
var int AccMaxArmor;

// ===================================================================
// CONDITION TRACKING STATE
// ===================================================================
var int LastKnownAmmoCount;
var class<KFWeapon> LastReloadWeaponClass;
var class<Weapon> TrackedWeaponClass;
var array< class<KFWeapon> > UsedMagazineWeapons;
var int LastRotationYaw;
var bool bRotationTracked;
var float ContinuousMoveStartTime;
var vector LastStillnessPos;
var bool bStillnessTracked;
var int BurstShotCount;
var float LastShotTime;
var float BurstCooldownEndTime;
var class<Weapon> LastAttackWeaponClass;
var bool bFirstAttackDone;
var float PollInterval;
var float ProphecyGraceEndTime;    // Grace period after prophecy draw



// ===================================================================
// SOUNDS
// ===================================================================

// ===================================================================
// INITIALIZATION
// ===================================================================
function PostBeginPlay()
{
    super.PostBeginPlay();
    Player = KFPawn_Human(Owner);

    `log("[DK_OMEN] PostBeginPlay: Owner=" @ Owner @ "Player=" @ Player);
}

function Initialize(KFPawn_Human InPlayer, int InLevel)
{
    Player = InPlayer;
    CurrentUpgradeLevel = InLevel;
    ActiveProphecyIndex = -1;
    LastProphecyIndex = -1;
    bProphecyActive = false;
    bWaveInProgress = false;
    DenyFateWaveCounter = 0;
    bDenyFateAvailable = false;
    bCurrentProphecyHidden = false;

    BuildProphecyPool();
    SetTimer(PollInterval, true, 'TickPoll');

    `log("[DK_OMEN] Initialized for" @ Player.PlayerReplicationInfo.PlayerName @ "Level:" @ InLevel @ "Pool:" @ ProphecyPool.Length);
}

function SetUpgradeLevel(int InLevel)
{
    local int OldLevel;
    OldLevel = CurrentUpgradeLevel;
    CurrentUpgradeLevel = InLevel;

    if ((OldLevel < class'ZTConfig_Capstone'.default.Capstone_Rank1Level && InLevel >= class'ZTConfig_Capstone'.default.Capstone_Rank1Level) || (OldLevel < class'ZTConfig_Capstone'.default.Capstone_Rank2Level && InLevel >= class'ZTConfig_Capstone'.default.Capstone_Rank2Level))
        BuildProphecyPool();
}

// ===================================================================
// PROPHECY POOL CONSTRUCTION
// ===================================================================
function BuildProphecyPool()
{
    local ProphecyData P;

    ProphecyPool.Length = 0;

    // --- TIER 1 (Levels 1+) ---

    P.Name = "Marksman's Oath";
    P.BlessingDesc = "Every shot must be a headshot";
    P.WhisperText = "The eye sees all that wanders...";
    P.Condition = PC_HeadshotsOnly;
    P.Tier = 1;
    P.RewardDamage = 0.0f; P.RewardHeadshotDamage = 0.03f; P.RewardDamageResist = 0.0f;
    P.RewardReloadSpeed = 0.0f; P.RewardMoveSpeed = 0.0f; P.RewardMaxHealth = 0; P.RewardMaxArmor = 0;
    ProphecyPool.AddItem(P);

    P.Name = "Iron Discipline";
    P.BlessingDesc = "Do not manually reload";
    P.WhisperText = "Patience is a forgotten virtue...";
    P.Condition = PC_NoReload;
    P.Tier = 1;
    P.RewardDamage = 0.0f; P.RewardHeadshotDamage = 0.0f; P.RewardDamageResist = 0.0f;
    P.RewardReloadSpeed = 0.02f; P.RewardMoveSpeed = 0.0f; P.RewardMaxHealth = 0; P.RewardMaxArmor = 0;
    ProphecyPool.AddItem(P);

    P.Name = "Unwavering";
    P.BlessingDesc = "Do not sprint";
    P.WhisperText = "Haste invites ruin...";
    P.Condition = PC_NoSprint;
    P.Tier = 1;
    P.RewardDamage = 0.03f; P.RewardHeadshotDamage = 0.0f; P.RewardDamageResist = 0.0f;
    P.RewardReloadSpeed = 0.0f; P.RewardMoveSpeed = 0.0f; P.RewardMaxHealth = 0; P.RewardMaxArmor = 0;
    ProphecyPool.AddItem(P);

    P.Name = "Stoneskin";
    P.BlessingDesc = "Receive no healing";
    P.WhisperText = "Flesh mends; fate does not...";
    P.Condition = PC_NoHealing;
    P.Tier = 1;
    P.RewardDamage = 0.0f; P.RewardHeadshotDamage = 0.0f; P.RewardDamageResist = 0.0f;
    P.RewardReloadSpeed = 0.0f; P.RewardMoveSpeed = 0.0f; P.RewardMaxHealth = 10; P.RewardMaxArmor = 0;
    ProphecyPool.AddItem(P);

    P.Name = "Close Quarters";
    P.BlessingDesc = "Do not damage zeds beyond 10 meters";
    P.WhisperText = "Only the bold survive what looms near...";
    P.Condition = PC_CloseQuarters;
    P.Tier = 1;
    P.RewardDamage = 0.0f; P.RewardHeadshotDamage = 0.0f; P.RewardDamageResist = 0.02f;
    P.RewardReloadSpeed = 0.0f; P.RewardMoveSpeed = 0.0f; P.RewardMaxHealth = 0; P.RewardMaxArmor = 0;
    ProphecyPool.AddItem(P);

    P.Name = "Grounded";
    P.BlessingDesc = "Do not jump";
    P.WhisperText = "The earth remembers those who leave it...";
    P.Condition = PC_NoJump;
    P.Tier = 1;
    P.RewardDamage = 0.03f; P.RewardHeadshotDamage = 0.0f; P.RewardDamageResist = 0.0f;
    P.RewardReloadSpeed = 0.0f; P.RewardMoveSpeed = 0.0f; P.RewardMaxHealth = 0; P.RewardMaxArmor = 0;
    ProphecyPool.AddItem(P);

    P.Name = "Unyielding";
    P.BlessingDesc = "Do not switch weapons";
    P.WhisperText = "Loyalty to the blade is loyalty to yourself...";
    P.Condition = PC_NoWeaponSwitch;
    P.Tier = 1;
    P.RewardDamage = 0.0f; P.RewardHeadshotDamage = 0.0f; P.RewardDamageResist = 0.0f;
    P.RewardReloadSpeed = 0.03f; P.RewardMoveSpeed = 0.0f; P.RewardMaxHealth = 0; P.RewardMaxArmor = 0;
    ProphecyPool.AddItem(P);

    P.Name = "Untouched";
    P.BlessingDesc = "Take no damage";
    P.WhisperText = "A single scratch unravels destiny...";
    P.Condition = PC_NoDamageTaken;
    P.Tier = 1;
    // Untouched is the hardest tier-1 condition (zero damage taken all wave) yet was the
    // weakest-rewarding (+5 armor). Now grants compounding +3% damage resistance plus +10
    // max armor so the payoff matches the difficulty. Doom remains -2x on these stats.
    P.RewardDamage = 0.0f; P.RewardHeadshotDamage = 0.0f; P.RewardDamageResist = 0.03f;
    P.RewardReloadSpeed = 0.0f; P.RewardMoveSpeed = 0.0f; P.RewardMaxHealth = 0; P.RewardMaxArmor = 10;
    ProphecyPool.AddItem(P);

    // --- TIER 2 (Level 10+) ---
    if (CurrentUpgradeLevel >= class'ZTConfig_Capstone'.default.Capstone_Rank1Level)
    {
        P.Name = "Pacifist's Paradox";
        P.BlessingDesc = "Deal no melee or bash damage";
        P.WhisperText = "The fist closes, and the world shudders...";
        P.Condition = PC_NoMelee;
        P.Tier = 2;
        P.RewardDamage = 0.05f; P.RewardHeadshotDamage = 0.0f; P.RewardDamageResist = 0.0f;
        P.RewardReloadSpeed = 0.0f; P.RewardMoveSpeed = 0.0f; P.RewardMaxHealth = 0; P.RewardMaxArmor = 0;
        ProphecyPool.AddItem(P);

        P.Name = "One Magazine";
        P.BlessingDesc = "One magazine per weapon - swap to reload";
        P.WhisperText = "Every bullet is a promise kept or broken...";
        P.Condition = PC_OneMagazine;
        P.Tier = 2;
        P.RewardDamage = 0.0f; P.RewardHeadshotDamage = 0.0f; P.RewardDamageResist = 0.0f;
        P.RewardReloadSpeed = 0.05f; P.RewardMoveSpeed = 0.0f; P.RewardMaxHealth = 0; P.RewardMaxArmor = 0;
        ProphecyPool.AddItem(P);

        P.Name = "Tunnel Vision";
        P.BlessingDesc = "No sudden turns beyond 90 degrees";
        P.WhisperText = "Look only forward; the abyss flanks you...";
        P.Condition = PC_NoTurns;
        P.Tier = 2;
        P.RewardDamage = 0.0f; P.RewardHeadshotDamage = 0.05f; P.RewardDamageResist = 0.0f;
        P.RewardReloadSpeed = 0.0f; P.RewardMoveSpeed = 0.0f; P.RewardMaxHealth = 0; P.RewardMaxArmor = 0;
        ProphecyPool.AddItem(P);

        P.Name = "Blind Faith";
        P.BlessingDesc = "Do not aim down sights";
        P.WhisperText = "Trust the hand, not the eye...";
        P.Condition = PC_NoADS;
        P.Tier = 2;
        P.RewardDamage = 0.0f; P.RewardHeadshotDamage = 0.0f; P.RewardDamageResist = 0.05f;
        P.RewardReloadSpeed = 0.0f; P.RewardMoveSpeed = 0.0f; P.RewardMaxHealth = 0; P.RewardMaxArmor = 0;
        ProphecyPool.AddItem(P);

        P.Name = "Vow of Stillness";
        P.BlessingDesc = "Stop moving for 1 second every 3 seconds";
        P.WhisperText = "Motion is an illusion; stillness is truth...";
        P.Condition = PC_StopEvery3s;
        P.Tier = 2;
        P.RewardDamage = 0.0f; P.RewardHeadshotDamage = 0.05f; P.RewardDamageResist = 0.0f;
        P.RewardReloadSpeed = 0.0f; P.RewardMoveSpeed = 0.0f; P.RewardMaxHealth = 0; P.RewardMaxArmor = 0;
        ProphecyPool.AddItem(P);

        P.Name = "Disarmed";
        P.BlessingDesc = "Only use sidearm or knife";
        P.WhisperText = "Power discarded is power earned...";
        P.Condition = PC_SidearmOnly;
        P.Tier = 2;
        P.RewardDamage = 0.08f; P.RewardHeadshotDamage = 0.0f; P.RewardDamageResist = 0.0f;
        P.RewardReloadSpeed = 0.0f; P.RewardMoveSpeed = 0.0f; P.RewardMaxHealth = 0; P.RewardMaxArmor = 0;
        ProphecyPool.AddItem(P);
    }

    // --- TIER 3 (Level 20+) ---
    if (CurrentUpgradeLevel >= class'ZTConfig_Capstone'.default.Capstone_Rank2Level)
    {
        P.Name = "Executioner";
        P.BlessingDesc = "Every killing blow must be a headshot";
        P.WhisperText = "Death must be precise, or it is nothing...";
        P.Condition = PC_Executioner;
        P.Tier = 3;
        P.RewardDamage = 0.0f; P.RewardHeadshotDamage = 0.10f; P.RewardDamageResist = 0.0f;
        P.RewardReloadSpeed = 0.0f; P.RewardMoveSpeed = 0.0f; P.RewardMaxHealth = 0; P.RewardMaxArmor = 0;
        ProphecyPool.AddItem(P);

        P.Name = "Ascetic";
        P.BlessingDesc = "Knife and bash only - no shooting";
        P.WhisperText = "Bare hands against the tide...";
        P.Condition = PC_KnifeOnly;
        P.Tier = 3;
        P.RewardDamage = 0.10f; P.RewardHeadshotDamage = 0.0f; P.RewardDamageResist = 0.05f;
        P.RewardReloadSpeed = 0.0f; P.RewardMoveSpeed = 0.0f; P.RewardMaxHealth = 0; P.RewardMaxArmor = 0;
        ProphecyPool.AddItem(P);

        P.Name = "Silence";
        P.BlessingDesc = "Only shoot - no grenades, melee, jump, or sprint";
        P.WhisperText = "In silence, the gun speaks volumes...";
        P.Condition = PC_ShootOnly;
        P.Tier = 3;
        P.RewardDamage = 0.08f; P.RewardHeadshotDamage = 0.0f; P.RewardDamageResist = 0.0f;
        P.RewardReloadSpeed = 0.05f; P.RewardMoveSpeed = 0.0f; P.RewardMaxHealth = 0; P.RewardMaxArmor = 0;
        ProphecyPool.AddItem(P);

        P.Name = "Trigger Discipline";
        P.BlessingDesc = "Max 3 shots, then 2 second cooldown";
        P.WhisperText = "Restraint carves the path to power...";
        P.Condition = PC_TriggerDiscipline;
        P.Tier = 3;
        P.RewardDamage = 0.08f; P.RewardHeadshotDamage = 0.0f; P.RewardDamageResist = 0.05f;
        P.RewardReloadSpeed = 0.0f; P.RewardMoveSpeed = 0.0f; P.RewardMaxHealth = 0; P.RewardMaxArmor = 0;
        ProphecyPool.AddItem(P);

        P.Name = "Lone Wolf";
        P.BlessingDesc = "Swap weapons between every attack";
        P.WhisperText = "No blade knows loyalty; neither should you...";
        P.Condition = PC_AlternateWeapons;
        P.Tier = 3;
        P.RewardDamage = 0.10f; P.RewardHeadshotDamage = 0.0f; P.RewardDamageResist = 0.0f;
        P.RewardReloadSpeed = 0.0f; P.RewardMoveSpeed = 0.05f; P.RewardMaxHealth = 0; P.RewardMaxArmor = 0;
        ProphecyPool.AddItem(P);
    }

    `log("[DK_OMEN] Built prophecy pool with" @ ProphecyPool.Length @ "entries (Level" @ CurrentUpgradeLevel $ ")");
}

// ===================================================================
// WAVE DETECTION + PROPHECY DRAW
// ===================================================================
function TickPoll()
{
    local KFGameReplicationInfo KFGRI;
    local int WaveNum;

    if (Player == None || Player.Health <= 0)
        return;

    KFGRI = KFGameReplicationInfo(WorldInfo.GRI);
    if (KFGRI == None)
        return;

    WaveNum = KFGRI.WaveNum;

    // Detect wave start
    if (WaveNum > 0 && WaveNum != CurrentWaveNum && !KFGRI.bTraderIsOpen)
    {
        CurrentWaveNum = WaveNum;
        if (!bWaveInProgress)
        {
            bWaveInProgress = true;
            OnWaveStart();
        }
    }

    // Poll behavioral conditions
    if (bProphecyActive && !bProphecyFailed)
        PollContinuousConditions();

    // Doom Resilience timer
    if (bDoomResilienceActive && WorldInfo.TimeSeconds >= DoomResilienceEndTime)
        bDoomResilienceActive = false;

    // Deny Fate availability
    // Deny Fate now rearms every 3 waves instead of 5 -- at 5 the L20 capstone almost never
    // came up. 3 keeps it a safety net rather than a once-a-match novelty.
    if (CurrentUpgradeLevel >= class'ZTConfig_Capstone'.default.Capstone_Rank2Level)
        bDenyFateAvailable = (DenyFateWaveCounter >= 3);
}

function OnWaveStart()
{
    local ZTUpgrade_Skill_OmenBase_Helper SH;
    local int HPCost;

    `log("[DK_OMEN] OnWaveStart: Wave" @ CurrentWaveNum @ "Pool:" @ ProphecyPool.Length @ "Level:" @ CurrentUpgradeLevel);

    ResetConditionTracking();
    bCurrentProphecyHidden = false;

    // --- Notify skill helpers of wave start ---
    if (Player != None)
    {
        foreach Player.ChildActors(class'ZTUpgrade_Skill_OmenBase_Helper', SH)
        {
            // HP sacrifice (Blood Tithe)
            HPCost = SH.GetWaveStartHPSacrifice();
            if (HPCost > 0)
            {
                Player.Health = Max(Player.Health - HPCost, 1);
                `log("[DK_OMEN] Skill HP sacrifice:" @ HPCost @ "HP remaining:" @ Player.Health);
            }

            SH.OnWaveStart(Player);
        }
    }

    DrawProphecy();
    SendProphecyToHUD();
    PlayOmenSound('Omen_Prophecy_Reveal');
}

function DrawProphecy()
{
    local int Roll, Attempts;

    if (ProphecyPool.Length == 0)
        return;

    Attempts = 0;
    do
    {
        Roll = Rand(ProphecyPool.Length);
        Attempts++;
    } until (Roll != LastProphecyIndex || ProphecyPool.Length <= 1 || Attempts > 20);

    ActiveProphecyIndex = Roll;
    bProphecyActive = true;
    bProphecyFailed = false;
    bProphecyCompleted = false;
    bDenyFateUsed = false;
    ProphecyGraceEndTime = WorldInfo.TimeSeconds + 1.5f;

    `log("[DK_OMEN] Drew prophecy [" $ ProphecyPool[ActiveProphecyIndex].Name $ "] (Tier" @ ProphecyPool[ActiveProphecyIndex].Tier $ ")");
}

// ===================================================================
// CONDITION TRACKING RESET
// ===================================================================
function ResetConditionTracking()
{
    LastKnownAmmoCount = -1;
    LastReloadWeaponClass = None;

    if (Player != None && Player.Weapon != None)
        TrackedWeaponClass = Player.Weapon.Class;
    else
        TrackedWeaponClass = None;

    UsedMagazineWeapons.Length = 0;

    if (Player != None)
    {
        LastRotationYaw = Player.Rotation.Yaw;
        bRotationTracked = true;
        LastStillnessPos = Player.Location;
        ContinuousMoveStartTime = WorldInfo.TimeSeconds;
        bStillnessTracked = true;
    }

    BurstShotCount = 0;
    LastShotTime = 0.0f;
    BurstCooldownEndTime = 0.0f;
    LastAttackWeaponClass = None;
    bFirstAttackDone = false;
}

// ===================================================================
// CONTINUOUS CONDITION POLLING
// ===================================================================
function PollContinuousConditions()
{
    local EProphecyCondition Cond;
    local KFWeapon KFW;
    local int RotDelta;
    local float DistSq;

    if (ActiveProphecyIndex < 0 || ActiveProphecyIndex >= ProphecyPool.Length)
        return;

    if (WorldInfo.TimeSeconds < ProphecyGraceEndTime)
        return;

    Cond = ProphecyPool[ActiveProphecyIndex].Condition;

    if (Cond == PC_NoSprint && Player != None && Player.bIsSprinting)
    {
        FailProphecy("Sprinted!");
        return;
    }

    if (Cond == PC_NoJump && Player != None && Player.Physics == PHYS_Falling)
    {
        FailProphecy("Jumped!");
        return;
    }

    if (Cond == PC_NoADS && Player != None)
    {
        KFW = KFWeapon(Player.Weapon);
        if (KFW != None && KFW.bUsingSights)
        {
            FailProphecy("Used iron sights!");
            return;
        }
    }

    if (Cond == PC_NoWeaponSwitch && Player != None && Player.Weapon != None)
    {
        if (TrackedWeaponClass != None && Player.Weapon.Class != TrackedWeaponClass)
        {
            FailProphecy("Switched weapons!");
            return;
        }
    }

    if (Cond == PC_NoTurns && Player != None && bRotationTracked)
    {
        RotDelta = Abs(Player.Rotation.Yaw - LastRotationYaw);
        if (RotDelta > 32768)
            RotDelta = 65536 - RotDelta;
        if (RotDelta > 14000)
        {
            FailProphecy("Turned too fast!");
            return;
        }
        LastRotationYaw = Player.Rotation.Yaw;
    }

    if (Cond == PC_StopEvery3s && Player != None && bStillnessTracked)
    {
        DistSq = VSizeSq(Player.Location - LastStillnessPos);
        if (DistSq < 2500.0f)
            ContinuousMoveStartTime = WorldInfo.TimeSeconds;
        else if (WorldInfo.TimeSeconds - ContinuousMoveStartTime > 3.0f)
        {
            FailProphecy("Moved for too long!");
            return;
        }
        LastStillnessPos = Player.Location;
    }

    if (Cond == PC_ShootOnly && Player != None)
    {
        if (Player.bIsSprinting)
        {
            FailProphecy("Sprinted!");
            return;
        }
        if (Player.Physics == PHYS_Falling)
        {
            FailProphecy("Jumped!");
            return;
        }
    }
}

// ===================================================================
// DAMAGE GIVEN CALLBACK
// ===================================================================
function OnDamageGiven(int InDamage, int DefaultDamage, KFPawn_Monster MyKFPM,
    class<KFDamageType> DamageType, int HitZoneIdx, KFWeapon MyKFW)
{
    local EProphecyCondition Cond;
    local float DistSq;
    local bool bIsMelee, bIsGrenade;

    if (!bProphecyActive || bProphecyFailed || ActiveProphecyIndex < 0)
        return;

    if (WorldInfo.TimeSeconds < ProphecyGraceEndTime)
        return;

    Cond = ProphecyPool[ActiveProphecyIndex].Condition;
    bIsMelee = (DamageType != None && class'WMUpgrade'.static.IsMeleeDamageType(DamageType));
    bIsGrenade = (DamageType != None && class'WMUpgrade'.static.IsGrenadeDT(DamageType));

    if (Cond == PC_HeadshotsOnly && !bIsMelee && HitZoneIdx != HZI_HEAD)
    {
        FailProphecy("Non-headshot hit!");
        return;
    }

    if (Cond == PC_CloseQuarters && Player != None && MyKFPM != None)
    {
        DistSq = VSizeSq(Player.Location - MyKFPM.Location);
        if (DistSq > 1000000.0f)
        {
            FailProphecy("Damaged a distant zed!");
            return;
        }
    }

    if (Cond == PC_NoMelee && bIsMelee)
    {
        FailProphecy("Dealt melee damage!");
        return;
    }

    if (Cond == PC_SidearmOnly && MyKFW != None)
    {
        if (!class'WMUpgrade'.static.IsWeaponSidearmOrKnife(MyKFW))
        {
            FailProphecy("Used non-sidearm weapon!");
            return;
        }
    }

    if (Cond == PC_KnifeOnly && !bIsMelee)
    {
        FailProphecy("Used a ranged weapon!");
        return;
    }

    if (Cond == PC_ShootOnly)
    {
        if (bIsMelee)
        {
            FailProphecy("Used melee!");
            return;
        }
        if (bIsGrenade)
        {
            FailProphecy("Used grenades!");
            return;
        }
    }

    if (Cond == PC_TriggerDiscipline && !bIsMelee)
    {
        if (WorldInfo.TimeSeconds < BurstCooldownEndTime)
        {
            FailProphecy("Shot during cooldown!");
            return;
        }

        if (WorldInfo.TimeSeconds - LastShotTime > 0.05f)
        {
            BurstShotCount++;
            LastShotTime = WorldInfo.TimeSeconds;
            if (BurstShotCount >= 3)
            {
                BurstShotCount = 0;
                BurstCooldownEndTime = WorldInfo.TimeSeconds + 2.0f;
            }
        }
    }

    if (Cond == PC_AlternateWeapons && MyKFW != None)
    {
        if (bFirstAttackDone && MyKFW.Class == LastAttackWeaponClass)
        {
            FailProphecy("Same weapon twice!");
            return;
        }
        LastAttackWeaponClass = MyKFW.Class;
        bFirstAttackDone = true;
    }

    if (Cond == PC_OneMagazine && MyKFW != None)
    {
        if (UsedMagazineWeapons.Find(MyKFW.Class) != INDEX_NONE)
        {
            FailProphecy("Fired a reloaded weapon!");
            return;
        }
    }

    if (Cond == PC_Executioner && MyKFPM != None)
    {
        if (InDamage >= MyKFPM.Health && MyKFPM.Health > 0 && HitZoneIdx != HZI_HEAD)
        {
            FailProphecy("Non-headshot kill!");
            return;
        }
    }
}

// ===================================================================
// OTHER CALLBACKS
// ===================================================================
function OnDamageTaken()
{
    if (!bProphecyActive || bProphecyFailed || ActiveProphecyIndex < 0)
        return;
    if (WorldInfo.TimeSeconds < ProphecyGraceEndTime)
        return;
    if (ProphecyPool[ActiveProphecyIndex].Condition == PC_NoDamageTaken)
        FailProphecy("Took damage!");
}

function OnHealed()
{
    if (!bProphecyActive || bProphecyFailed || ActiveProphecyIndex < 0)
        return;
    if (WorldInfo.TimeSeconds < ProphecyGraceEndTime)
        return;
    if (ProphecyPool[ActiveProphecyIndex].Condition == PC_NoHealing)
        FailProphecy("Received healing!");
}

function OnReload(KFWeapon KFW)
{
    local EProphecyCondition Cond;

    if (!bProphecyActive || bProphecyFailed || ActiveProphecyIndex < 0 || KFW == None)
        return;
    if (WorldInfo.TimeSeconds < ProphecyGraceEndTime)
        return;

    Cond = ProphecyPool[ActiveProphecyIndex].Condition;

    if (Cond == PC_NoReload && KFW.AmmoCount[0] > 0)
    {
        FailProphecy("Manual reload!");
        return;
    }

    if (Cond == PC_OneMagazine)
    {
        if (UsedMagazineWeapons.Find(KFW.Class) == INDEX_NONE)
            UsedMagazineWeapons.AddItem(KFW.Class);
    }
}

// ===================================================================
// PROPHECY RESOLUTION
// ===================================================================
function FailProphecy(string Reason)
{
    local ZTUpgrade_Skill_OmenBase_Helper SH;

    if (!bProphecyActive || bProphecyFailed)
        return;

    bProphecyFailed = true;
    `log("[DK_OMEN] PROPHECY FAILED [" $ ProphecyPool[ActiveProphecyIndex].Name $ "] - " $ Reason);

    // Level 20: Deny Fate
    if (bDenyFateAvailable && !bDenyFateUsed && CurrentUpgradeLevel >= class'ZTConfig_Capstone'.default.Capstone_Rank2Level)
    {
        bDenyFateUsed = true;
        bDenyFateAvailable = false;
        DenyFateWaveCounter = 0;
        bProphecyFailed = false;
        `log("[DK_OMEN] DENY FATE used! Doom cancelled.");
        PlayOmenSound('Omen_Deny_Fate');
        SendDenyFateToHUD();
        return;
    }

    ApplyDoom();

    // Notify skill helpers of failure (after doom applied)
    if (Player != None)
    {
        foreach Player.ChildActors(class'ZTUpgrade_Skill_OmenBase_Helper', SH)
        {
            SH.OnProphecyFailed();
        }
    }

    if (CurrentUpgradeLevel >= class'ZTConfig_Capstone'.default.Capstone_Rank1Level)
    {
        bDoomResilienceActive = true;
        DoomResilienceEndTime = WorldInfo.TimeSeconds + 20.0f;
    }

    PlayOmenSound('Omen_Doom_Activate');
    SendDoomToHUD();
}

function CompleteProphecy()
{
    local ProphecyData P;
    local ZTUpgrade_Skill_OmenBase_Helper SH;
    local float RewardMult;
    local int BonusHP;
    local int HealthReward;
    local int ArmorReward;

    if (!bProphecyActive || bProphecyFailed || ActiveProphecyIndex < 0)
        return;

    bProphecyCompleted = true;
    P = ProphecyPool[ActiveProphecyIndex];

    `log("[DK_OMEN] BLESSING COMPLETE [" $ P.Name $ "]");

    // --- Calculate total reward multiplier from skill helpers ---
    RewardMult = 1.0f;
    if (Player != None)
    {
        foreach Player.ChildActors(class'ZTUpgrade_Skill_OmenBase_Helper', SH)
        {
            RewardMult *= SH.GetRewardMultiplier();
        }
    }

    `log("[DK_OMEN] Reward multiplier:" @ RewardMult);

    if (RewardMult > 0.0f)
    {
        // Apply rewards with multiplier
        AccDamage += P.RewardDamage * RewardMult;
        AccHeadshotDamage += P.RewardHeadshotDamage * RewardMult;
        AccDamageResist += P.RewardDamageResist * RewardMult;
        AccReloadSpeed += P.RewardReloadSpeed * RewardMult;
        AccMoveSpeed += P.RewardMoveSpeed * RewardMult;

        HealthReward = Round(float(P.RewardMaxHealth) * RewardMult);
        ArmorReward = Round(float(P.RewardMaxArmor) * RewardMult);

        AccMaxHealth += HealthReward;
        AccMaxArmor += ArmorReward;

        if (Player != None)
        {
            if (HealthReward > 0)
            {
                Player.HealthMax += HealthReward;
                Player.Health = Min(Player.Health + HealthReward, Player.HealthMax);
            }
            if (ArmorReward > 0)
                Player.MaxArmor += ArmorReward;
        }

        // --- Bonus HP from skill helpers (Blood Tithe) ---
        if (Player != None)
        {
            foreach Player.ChildActors(class'ZTUpgrade_Skill_OmenBase_Helper', SH)
            {
                BonusHP = SH.GetCompletionBonusHP();
                if (BonusHP > 0)
                {
                    Player.HealthMax += BonusHP;
                    Player.Health = Min(Player.Health + BonusHP, Player.HealthMax);
                    AccMaxHealth += BonusHP;
                    `log("[DK_OMEN] Skill bonus HP:" @ BonusHP);
                }
            }
        }

        PlayOmenSound('Omen_Blessing_Complete');
        SendBlessingToHUD();
    }
    else
    {
        // Reward nullified (Double or Nothing: NOTHING!)
        `log("[DK_OMEN] Reward nullified by skill (Double or Nothing)");
        PlayOmenSound('Omen_Doom_Activate');
        SendNothingToHUD();
    }

    // --- Notify skill helpers of completion ---
    if (Player != None)
    {
        foreach Player.ChildActors(class'ZTUpgrade_Skill_OmenBase_Helper', SH)
        {
            SH.OnProphecyCompleted();
        }
    }
}

// ===================================================================
// WAVE END
// ===================================================================
function OnWaveEnd(int upgLevel)
{
    local bool bWasCompleted;

    CurrentUpgradeLevel = upgLevel;

    bWasCompleted = false;
    if (bProphecyActive && !bProphecyFailed)
    {
        CompleteProphecy();
        bWasCompleted = true;
    }

    LastProphecyIndex = ActiveProphecyIndex;
    bProphecyActive = false;
    bWaveInProgress = false;
    ActiveProphecyIndex = -1;
    DenyFateWaveCounter++;

    if ((upgLevel >= class'ZTConfig_Capstone'.default.Capstone_Rank1Level && ProphecyPool.Length < 14) || (upgLevel >= class'ZTConfig_Capstone'.default.Capstone_Rank2Level && ProphecyPool.Length < 19))
        BuildProphecyPool();

    if (!bWasCompleted)
        SendClearHUD();

    `log("[DK_OMEN] Wave ended. AccDmg=" $ AccDamage @ "AccHS=" $ AccHeadshotDamage @ "AccDR=" $ AccDamageResist @ "AccReload=" $ AccReloadSpeed);
}

// ===================================================================
// PERSONAL DOOM - Apply -2x of the blessing reward to the same stats
// Modified by skill helpers via GetDoomMultiplier()
// ===================================================================
function ApplyDoom()
{
    local ProphecyData P;
    local ZTUpgrade_Skill_OmenBase_Helper SH;
    local float DoomMult;
    local int HealthPenalty, ArmorPenalty;

    if (ActiveProphecyIndex < 0 || ActiveProphecyIndex >= ProphecyPool.Length)
        return;

    P = ProphecyPool[ActiveProphecyIndex];

    // --- Calculate total doom multiplier from skill helpers ---
    DoomMult = 1.0f;
    if (Player != None)
    {
        foreach Player.ChildActors(class'ZTUpgrade_Skill_OmenBase_Helper', SH)
        {
            DoomMult *= SH.GetDoomMultiplier();
        }
    }

    `log("[DK_OMEN] Doom multiplier:" @ DoomMult);

    // Subtract (2x * DoomMult) of each reward from accumulated stats
    AccDamage -= P.RewardDamage * 2.0f * DoomMult;
    AccHeadshotDamage -= P.RewardHeadshotDamage * 2.0f * DoomMult;
    AccDamageResist -= P.RewardDamageResist * 2.0f * DoomMult;
    AccReloadSpeed -= P.RewardReloadSpeed * 2.0f * DoomMult;
    AccMoveSpeed -= P.RewardMoveSpeed * 2.0f * DoomMult;

    HealthPenalty = Round(float(P.RewardMaxHealth) * 2.0f * DoomMult);
    ArmorPenalty = Round(float(P.RewardMaxArmor) * 2.0f * DoomMult);

    AccMaxHealth -= HealthPenalty;
    AccMaxArmor -= ArmorPenalty;

    if (Player != None)
    {
        if (HealthPenalty > 0)
        {
            Player.HealthMax -= HealthPenalty;
            if (Player.HealthMax < 25)
                Player.HealthMax = 25;
            if (Player.Health > Player.HealthMax)
                Player.Health = Player.HealthMax;
        }
        if (ArmorPenalty > 0)
        {
            Player.MaxArmor -= ArmorPenalty;
            if (Player.MaxArmor < 0)
                Player.MaxArmor = 0;
            if (Player.Armor > Player.MaxArmor)
                Player.Armor = Player.MaxArmor;
        }
    }

    `log("[DK_OMEN] DOOM applied (DoomMult=" $ DoomMult $ "): AccDmg=" $ AccDamage @ "AccHS=" $ AccHeadshotDamage
        @ "AccDR=" $ AccDamageResist @ "AccReload=" $ AccReloadSpeed
        @ "AccSpeed=" $ AccMoveSpeed @ "AccHP=" $ AccMaxHealth @ "AccArmor=" $ AccMaxArmor);
}

// ===================================================================
// SOUND PLAYBACK
// ===================================================================
function PlayOmenSound(name SoundID)
{
    local ZTPlayerController DKPC;
    local SoundCue Sound;
    local ZTMutator MutObj;

    if (Player == None) return;
    DKPC = ZTPlayerController(Player.Controller);
    if (DKPC == None) return;

    MutObj = class'ZTSoundManager'.static.GetMutator(WorldInfo);
    if (MutObj == None) return;

    Sound = class'ZTSoundManager'.static.GetSound(MutObj, SoundID);
    if (Sound != None)
        DKPC.ClientPlayBuffSound(Sound);
}

// ===================================================================
// HUD SYNC RPCs
//
// PHASE 3 LOCALIZATION REFACTOR:
//   The RPC now sends raw indices + reward float values instead of
//   pre-formatted English strings. The client builds localized strings
//   from the active locale's [ZTHudWrapper] section using helper
//   functions on ZTHudWrapper (GetLocalizedOmenName/Desc/Whisper,
//   BuildLocalizedOmenReward, BuildLocalizedOmenDoom).
//
//   SubState codes (RPC parameter):
//     0 = ACTIVE normal prophecy
//     1 = HIDDEN prophecy (skill-suppressed)
//     2 = DOOM (prophecy failed)
//     3 = BLESSING complete
//     4 = DON_NOTHING (Double or Nothing reward nullified)
//     5 = DENY_FATE (capstone Deny Fate triggered)
//
//   These map onto the existing DisplayState convention used by
//   DrawOmenCard (RepState):
//     0 = active, 1 = blessing, 2 = doom, 3 = deny_fate
// ===================================================================
function SendProphecyToHUD()
{
    local ProphecyData P;
    local ZTUpgrade_Skill_OmenBase_Helper SH;
    local byte SubState;
    local byte ShowWhisper;

    if (ActiveProphecyIndex < 0 || ActiveProphecyIndex >= ProphecyPool.Length)
    {
        `log("[DK_OMEN] SendProphecyToHUD ABORT: ActiveProphecyIndex=" @ ActiveProphecyIndex @ "PoolLength=" @ ProphecyPool.Length);
        return;
    }

    P = ProphecyPool[ActiveProphecyIndex];

    // --- Check if any skill helper wants to hide the prophecy ---
    bCurrentProphecyHidden = false;
    if (Player != None)
    {
        foreach Player.ChildActors(class'ZTUpgrade_Skill_OmenBase_Helper', SH)
        {
            if (SH.ShouldHideProphecy())
            {
                bCurrentProphecyHidden = true;
                break;
            }
        }
    }

    if (bCurrentProphecyHidden)
    {
        SubState = 1;  // HIDDEN
        ShowWhisper = 0;
        `log("[DK_OMEN] Prophecy HIDDEN by skill helper");
    }
    else
    {
        SubState = 0;  // ACTIVE normal
        if (CurrentUpgradeLevel >= class'ZTConfig_Capstone'.default.Capstone_Rank1Level)
            ShowWhisper = 1;
        else
            ShowWhisper = 0;
    }

    `log("[DK_OMEN] SendProphecyToHUD: [" $ P.Name $ "] Tier:" @ P.Tier @ "Hidden:" @ bCurrentProphecyHidden);
    ClientUpdateOmenHUD(SubState, byte(ActiveProphecyIndex), P.Condition, P.Tier, ShowWhisper,
        P.RewardDamage, P.RewardHeadshotDamage, P.RewardDamageResist,
        P.RewardReloadSpeed, P.RewardMoveSpeed, P.RewardMaxHealth, P.RewardMaxArmor);
}

function SendDoomToHUD()
{
    local ProphecyData P;
    if (ActiveProphecyIndex < 0) return;
    P = ProphecyPool[ActiveProphecyIndex];
    ClientUpdateOmenHUD(2, byte(ActiveProphecyIndex), P.Condition, P.Tier, 0,
        P.RewardDamage, P.RewardHeadshotDamage, P.RewardDamageResist,
        P.RewardReloadSpeed, P.RewardMoveSpeed, P.RewardMaxHealth, P.RewardMaxArmor);
}

function SendBlessingToHUD()
{
    local ProphecyData P;
    if (ActiveProphecyIndex < 0) return;
    P = ProphecyPool[ActiveProphecyIndex];
    ClientUpdateOmenHUD(3, byte(ActiveProphecyIndex), P.Condition, P.Tier, 0,
        P.RewardDamage, P.RewardHeadshotDamage, P.RewardDamageResist,
        P.RewardReloadSpeed, P.RewardMoveSpeed, P.RewardMaxHealth, P.RewardMaxArmor);
}

function SendNothingToHUD()
{
    // Double or Nothing: NOTHING! - DON_NOTHING substate, no prophecy data needed
    ClientUpdateOmenHUD(4, 255, 255, 0, 0, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0, 0);
}

function SendDenyFateToHUD()
{
    local byte IconIdx;

    if (ActiveProphecyIndex >= 0 && ActiveProphecyIndex < ProphecyPool.Length)
        IconIdx = ProphecyPool[ActiveProphecyIndex].Condition;
    else
        IconIdx = 255;

    ClientUpdateOmenHUD(5, 255, IconIdx, 3, 0, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0, 0);
}

function SendClearHUD()
{
    ClientClearOmenHUD();
}

// New RPC signature: receives indices + raw reward floats; client builds
// localized strings using ZTHudWrapper helpers based on the active locale.
reliable client function ClientUpdateOmenHUD(
    byte SubState, byte ProphecyIndex, byte IconIndex, byte Tier, byte ShowWhisper,
    float RewardDmg, float RewardHSDmg, float RewardDR,
    float RewardReload, float RewardSpeed,
    int RewardHP, int RewardArmor)
{
    local KFPlayerController KFPC;
    local ZTHudWrapper HUD;

    `log("[DK_OMEN] ClientUpdateOmenHUD RPC received. SubState:" @ SubState @ "ProphecyIdx:" @ ProphecyIndex @ "Tier:" @ Tier);

    KFPC = KFPlayerController(GetALocalPlayerController());
    if (KFPC == None)
    {
        `log("[DK_OMEN] ClientUpdateOmenHUD ABORT: KFPC None (expected on dedicated server)");
        return;
    }

    HUD = class'ZTHudWrapper'.static.GetReaperHUD(KFPC);
    if (HUD == None)
    {
        `log("[DK_OMEN] ClientUpdateOmenHUD ABORT: HUD is None");
        return;
    }

    // Build localized strings + map SubState -> DisplayState (existing convention)
    switch (SubState)
    {
        case 0:  // ACTIVE prophecy
            RepTitle = HUD.GetLocalizedOmenName(int(ProphecyIndex));
            RepCondition = HUD.GetLocalizedOmenDesc(int(ProphecyIndex));
            RepReward = HUD.BuildLocalizedOmenReward(RewardDmg, RewardHSDmg, RewardDR, RewardReload, RewardSpeed, RewardHP, RewardArmor);
            RepDoom = HUD.BuildLocalizedOmenDoom(RewardDmg, RewardHSDmg, RewardDR, RewardReload, RewardSpeed, RewardHP, RewardArmor);
            if (ShowWhisper != 0)
                RepWhisper = HUD.GetLocalizedOmenWhisper(int(ProphecyIndex));
            else
                RepWhisper = "";
            RepState = 0;
            break;
        case 1:  // HIDDEN prophecy
            RepTitle = HUD.Omen_Hidden_Title;
            RepCondition = HUD.Omen_Hidden_Cond;
            RepReward = HUD.Omen_Hidden_Cond;   // "???"
            RepDoom = HUD.Omen_Hidden_Cond;     // "???"
            RepWhisper = HUD.Omen_Hidden_Whisper;
            RepState = 0;
            break;
        case 2:  // DOOM (after failure)
            RepTitle = HUD.GetLocalizedOmenName(int(ProphecyIndex));
            RepDoom = HUD.BuildLocalizedOmenDoom(RewardDmg, RewardHSDmg, RewardDR, RewardReload, RewardSpeed, RewardHP, RewardArmor);
            RepCondition = HUD.Omen_DoomStatePrefix $ RepDoom;
            RepReward = "";
            RepWhisper = "";
            RepState = 2;
            break;
        case 3:  // BLESSING complete
            RepTitle = HUD.GetLocalizedOmenName(int(ProphecyIndex));
            RepCondition = HUD.Omen_BlessingComplete;
            RepReward = HUD.BuildLocalizedOmenReward(RewardDmg, RewardHSDmg, RewardDR, RewardReload, RewardSpeed, RewardHP, RewardArmor);
            RepDoom = "";
            RepWhisper = "";
            RepState = 1;
            break;
        case 4:  // DON_NOTHING
            RepTitle = HUD.Omen_DON_Title;
            RepCondition = HUD.Omen_DON_NothingCond;
            RepReward = "";
            RepDoom = "";
            RepWhisper = HUD.Omen_DON_NothingWhisper;
            RepState = 2;
            break;
        case 5:  // DENY_FATE
            RepTitle = HUD.Omen_DenyFate_Title;
            RepCondition = HUD.Omen_DenyFate_Cond;
            RepReward = "";
            RepDoom = "";
            RepWhisper = HUD.Omen_DenyFate_Whisper;
            RepState = 3;
            break;
    }

    RepTier = Tier;
    RepIconIndex = IconIndex;

    PushOmenToHUD();
}

reliable client function ClientClearOmenHUD()
{
    `log("[DK_OMEN] ClientClearOmenHUD RPC received.");
    ClearOmenFromHUD();
}

// ===================================================================
// HUD PUSH (simulated - Predator pattern)
// ===================================================================

simulated function PushOmenToHUD()
{
    local KFPlayerController KFPC;
    local ZTHudWrapper HUD;

    `log("[DK_OMEN] PushOmenToHUD called. Title:" @ RepTitle @ "State:" @ RepState);

    KFPC = KFPlayerController(GetALocalPlayerController());
    if (KFPC == None)
    {
        `log("[DK_OMEN] PushOmenToHUD ABORT: KFPC is None (expected on dedicated server)");
        return;
    }

    HUD = class'ZTHudWrapper'.static.GetReaperHUD(KFPC);
    if (HUD == None)
    {
        `log("[DK_OMEN] PushOmenToHUD ABORT: HUD is None");
        return;
    }

    `log("[DK_OMEN] PushOmenToHUD: Calling UpdateOmenDisplay");
    HUD.UpdateOmenDisplay(RepTitle, RepCondition, RepReward, RepDoom, RepWhisper, RepTier, RepState, RepIconIndex);
}

simulated function ClearOmenFromHUD()
{
    local KFPlayerController KFPC;
    local ZTHudWrapper HUD;

    KFPC = KFPlayerController(GetALocalPlayerController());
    if (KFPC == None)
        return;

    HUD = class'ZTHudWrapper'.static.GetReaperHUD(KFPC);
    if (HUD == None)
        return;

    HUD.ClearOmenDisplay();
}

// ===================================================================
// CLEANUP
// ===================================================================
function Cleanup()
{
    `log("[DK_OMEN] Cleanup - AccDmg=" $ AccDamage @ "AccHS=" $ AccHeadshotDamage
        @ "AccDR=" $ AccDamageResist @ "AccReload=" $ AccReloadSpeed
        @ "AccSpeed=" $ AccMoveSpeed @ "AccHP=" $ AccMaxHealth @ "AccArmor=" $ AccMaxArmor);
}

// ===================================================================
// DEFAULT PROPERTIES
// ===================================================================
defaultproperties
{
    RemoteRole=ROLE_SimulatedProxy
    bOnlyRelevantToOwner=True

    PollInterval=0.2f
    ActiveProphecyIndex=-1
    LastProphecyIndex=-1
    bProphecyActive=false
    bProphecyFailed=false
    ProphecyGraceEndTime=0.0f
    bProphecyCompleted=false
    bWaveInProgress=false
    bCurrentProphecyHidden=false
    bDoomResilienceActive=false
    bDenyFateAvailable=false
    bDenyFateUsed=false
    DenyFateWaveCounter=0
    CurrentWaveNum=0

    AccDamage=0.0f
    AccHeadshotDamage=0.0f
    AccDamageResist=0.0f
    AccReloadSpeed=0.0f
    AccMoveSpeed=0.0f
    AccMaxHealth=0
    AccMaxArmor=0

    BurstShotCount=0
    LastShotTime=0.0f
    BurstCooldownEndTime=0.0f
    bFirstAttackDone=false
    bRotationTracked=false
    bStillnessTracked=false
    LastKnownAmmoCount=-1



    Name="Default__ZTUpgrade_Perk_Omen_Helper"
}
