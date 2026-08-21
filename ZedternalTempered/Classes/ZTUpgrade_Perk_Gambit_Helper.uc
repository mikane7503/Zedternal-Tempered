// ===================================================================
// ZTUpgrade_Perk_Gambit_Helper - State machine for the Gambit perk
//
// Manages: gambit rolling, condition tracking, reward accumulation,
// wave detection, and HUD display data via ZTHudWrapper.
//
// Spawned as child actor of the owning pawn. Server-authoritative
// with replicated display vars for client-side HUD rendering.
//
// HUD rendering is delegated to ZTHudWrapper.DrawGambitDisplay().
// This helper pushes pre-formatted strings to the HUD wrapper
// via PushToHUD() -> UpdateGambitDisplay().
//
// SKILL INTEGRATION:
// Skills communicate via WMPerk.ExtensionFuncInteger() identifiers:
//   "GambitHotStreak"       - Hot Streak (streak reward multiplier)
//   "GambitDoubleOrNothing" - Double or Nothing (coin flip rewards)
//   "GambitRaiseTheStakes"  - Raise the Stakes (harder targets, 2x rewards)
//   "GambitHouseWins"       - The House Always Wins (failure pity timer)
//   "GambitWildCard"        - Wild Card (chance to auto-complete on kill)
//   "GambitAce"             - Ace Up Your Sleeve (bonus damage shots)
//   "GambitBluff"           - Bluff (survive lethal, fail gambit)
//   "GambitCardShark"       - Card Shark (failure = damage stacks)
//   "GambitRoyalFlush"      - Royal Flush (every Nth completion tripled)
//   "GambitAllIn"           - All In (reads progress percent)
// GetSkillLevel() returns 0=inactive, 1=standard, 2=deluxe.
// ===================================================================
class ZTUpgrade_Perk_Gambit_Helper extends Actor;

// ===================================================================
// CONSTANTS
// ===================================================================

const TOTAL_GAMBITS = 14;

// Rarity tiers
const RARITY_NORMAL = 0;
const RARITY_RARE = 1;
const RARITY_LEGENDARY = 2;
const RARITY_MYTHIC = 3;

// Condition types
const GC_KILL_COUNT = 0;
const GC_HEADSHOT_KILLS = 1;
const GC_MAX_DAMAGE_TAKEN = 2;
const GC_TIMED_KILLS = 3;
const GC_LARGE_ZED_KILLS = 4;
const GC_HEADSHOT_RATIO = 5;
const GC_ZERO_DAMAGE = 6;
const GC_RAPID_KILLS = 7;
const GC_LOW_HP_KILLS = 8;
const GC_LARGE_HEADSHOT_KILLS = 9;
const GC_FLAWLESS = 10;
const GC_LOW_RELOAD_KILLS = 11;
const GC_SIDEARM_LARGE_KILL = 12;
const GC_SINGLE_MAG_KILLS = 13;

// Reward types
const RT_DAMAGE = 0;
const RT_DOSH = 1;
const RT_SPEED = 2;
const RT_ALL = 3;
const RT_DAMAGE_DOSH = 4;
const RT_DAMAGE_SPEED = 5;

// Mythic roll chance (1%)
const MYTHIC_CHANCE = 0.01f;

// ===================================================================
// GAMBIT DEFINITION STRUCT
// ===================================================================

struct GambitDef
{
    var string GambitName;
    var string DescTemplate;     // %t = computed target, %s = secondary param
    var byte ConditionType;
    var int BaseTarget;          // base target value
    var int WaveScaleTarget;     // added per wave number
    var byte Rarity;
    var int RollWeight;
    var byte RewardType;
    var float BaseDamageReward;  // per perk level
    var float BaseDoshReward;    // per perk level
    var float BaseSpeedReward;   // per perk level
    var int SecondaryParam;      // context-dependent (time limit, min kills, etc.)
};

// ===================================================================
// VARIABLES
// ===================================================================

// --- Gambit Pool ---
var array<GambitDef> GambitPool;

// --- Perk State ---
var int PerkLevel;
var KFPawn_Human Player;

// --- Wave Tracking ---
var int CurrentWaveNum;
var int LastWaveNum;
var bool bFirstWaveHandled;

// --- Active Gambit ---
var int ActiveGambitIndex;       // index into GambitPool, -1 = none
var bool bGambitActive;
var bool bGambitCompleted;

// --- Tracking Counters (reset each wave) ---
var int TrackKills;
var int TrackHeadshotKills;
var int TrackLargeKills;
var int TrackLargeHeadshotKills;
var int TrackLowHPKills;
var int TrackDamageTaken;
var bool bTrackTookDamage;
var int TrackReloadCount;
var int TrackKillsSinceReload;
var float TrackWaveStartTime;
var int TrackBestRapidKills;
var bool bTrackSidearmLargeKill;

// Rapid kill tracking (rolling window)
var array<float> RecentKillTimes;

// Reload debounce
var float LastReloadTime;

// Sound guard -- prevents double-playing completion sound
var bool bCompleteSoundPlayed;

// --- Accumulated Permanent Rewards (persist across waves) ---
var float AccumulatedDamage;
var float AccumulatedSpeed;
var int AccumulatedDosh;
var float AccumulatedReload;
var float AccumulatedRecoil;
var float AccumulatedMagSize;
var float AccumulatedSpareAmmo;
var int TotalCompletions;

// --- Skill State (persist across waves) ---
var int StreakCount;             // Hot Streak: consecutive completions
var int FailureStacks;          // The House Always Wins: stacked failures
var int CardSharkStacks;        // Card Shark: failure damage stacks
var float CardSharkDamageBonus; // Card Shark: total accumulated damage bonus
var int AceShots;               // Ace Up Your Sleeve: remaining bonus shots
var float AceBonusPct;          // Ace Up Your Sleeve: damage bonus per shot
var float BluffCooldownEnd;     // Bluff: WorldInfo.TimeSeconds when cooldown expires
var bool bBluffImmune;          // Bluff: damage immunity active (deluxe)
var float BluffImmuneEnd;       // Bluff: when immunity expires

// --- Replicated Display Data (server -> owning client) ---
var byte RepGambitIndex;
var byte RepRarity;
var int RepProgress;
var int RepTarget;
var bool RepActive;
var bool RepCompleted;
var float RepAccDamage;
var float RepAccSpeed;
var int RepCompletions;
var int RepSecondary;          // context-dependent secondary info
var int RepStreak;             // Hot Streak display
var int RepAceShots;           // Ace Up Your Sleeve display

// ===================================================================
// REPLICATION
// ===================================================================

replication
{
    if (bNetDirty)
        RepGambitIndex, RepRarity, RepProgress, RepTarget,
        RepActive, RepCompleted, RepAccDamage, RepAccSpeed,
        RepCompletions, RepSecondary, RepStreak, RepAceShots,
        AccumulatedDamage, AccumulatedSpeed, AccumulatedDosh,
        AccumulatedReload, AccumulatedRecoil, AccumulatedMagSize,
        AccumulatedSpareAmmo, TotalCompletions;
}

// ===================================================================
// INITIALIZATION
// ===================================================================

simulated event PostBeginPlay()
{
    Super.PostBeginPlay();

    Player = KFPawn_Human(Owner);
    ActiveGambitIndex = -1;
    LastWaveNum = -1;

    SetupGambits();

    `log("Gambit Helper: Initialized for" @ Player);
}

function SetPerkLevel(int NewLevel)
{
    PerkLevel = NewLevel;
}

function SetupGambits()
{
    local GambitDef G;

    GambitPool.Length = 0;

    // ---------------------------------------------------------------
    // NORMAL GAMBITS (Rank 1+) -- Wave-scaled targets
    // ---------------------------------------------------------------

    // 0: Marksman
    G.GambitName = "Marksman";
    G.DescTemplate = "Get %t headshot kills";
    G.ConditionType = GC_HEADSHOT_KILLS;
    G.BaseTarget = 5;
    G.WaveScaleTarget = 1;
    G.Rarity = RARITY_NORMAL;
    G.RollWeight = 100;
    G.RewardType = RT_DAMAGE;
    G.BaseDamageReward = 0.005f;
    G.BaseDoshReward = 0.0f;
    G.BaseSpeedReward = 0.0f;
    G.SecondaryParam = 0;
    GambitPool.AddItem(G);

    // 1: Body Count
    G.GambitName = "Body Count";
    G.DescTemplate = "Kill %t zeds";
    G.ConditionType = GC_KILL_COUNT;
    G.BaseTarget = 10;
    G.WaveScaleTarget = 3;
    G.Rarity = RARITY_NORMAL;
    G.RollWeight = 100;
    G.RewardType = RT_DOSH;
    G.BaseDamageReward = 0.0f;
    G.BaseDoshReward = 50.0f;
    G.BaseSpeedReward = 0.0f;
    G.SecondaryParam = 0;
    GambitPool.AddItem(G);

    // 2: Iron Skin
    G.GambitName = "Iron Skin";
    G.DescTemplate = "Take no more than %t damage";
    G.ConditionType = GC_MAX_DAMAGE_TAKEN;
    G.BaseTarget = 150;
    G.WaveScaleTarget = 30;
    G.Rarity = RARITY_NORMAL;
    G.RollWeight = 100;
    G.RewardType = RT_SPEED;
    G.BaseDamageReward = 0.0f;
    G.BaseDoshReward = 0.0f;
    G.BaseSpeedReward = 0.0025f;
    G.SecondaryParam = 0;
    GambitPool.AddItem(G);

    // 3: Blitz
    G.GambitName = "Blitz";
    G.DescTemplate = "Kill %t zeds in the first 60 seconds";
    G.ConditionType = GC_TIMED_KILLS;
    G.BaseTarget = 5;
    G.WaveScaleTarget = 1;
    G.Rarity = RARITY_NORMAL;
    G.RollWeight = 100;
    G.RewardType = RT_DOSH;
    G.BaseDamageReward = 0.0f;
    G.BaseDoshReward = 50.0f;
    G.BaseSpeedReward = 0.0f;
    G.SecondaryParam = 60;
    GambitPool.AddItem(G);

    // 4: Big Game
    G.GambitName = "Big Game";
    G.DescTemplate = "Kill %t large zed(s)";
    G.ConditionType = GC_LARGE_ZED_KILLS;
    G.BaseTarget = 1;
    G.WaveScaleTarget = 0;
    G.Rarity = RARITY_NORMAL;
    G.RollWeight = 100;
    G.RewardType = RT_DAMAGE;
    G.BaseDamageReward = 0.005f;
    G.BaseDoshReward = 0.0f;
    G.BaseSpeedReward = 0.0f;
    G.SecondaryParam = 0;
    GambitPool.AddItem(G);

    // ---------------------------------------------------------------
    // RARE GAMBITS (Rank 10+)
    // ---------------------------------------------------------------

    // 5: Perfectionist
    G.GambitName = "Perfectionist";
    G.DescTemplate = "70%+ headshot ratio (min %t kills)";
    G.ConditionType = GC_HEADSHOT_RATIO;
    G.BaseTarget = 10;
    G.WaveScaleTarget = 1;
    G.Rarity = RARITY_RARE;
    G.RollWeight = 50;
    G.RewardType = RT_DAMAGE;
    G.BaseDamageReward = 0.01f;
    G.BaseDoshReward = 0.0f;
    G.BaseSpeedReward = 0.0f;
    G.SecondaryParam = 70;
    GambitPool.AddItem(G);

    // 6: Untouchable
    G.GambitName = "Untouchable";
    G.DescTemplate = "Take zero damage the entire wave";
    G.ConditionType = GC_ZERO_DAMAGE;
    G.BaseTarget = 1;
    G.WaveScaleTarget = 0;
    G.Rarity = RARITY_RARE;
    G.RollWeight = 50;
    G.RewardType = RT_SPEED;
    G.BaseDamageReward = 0.0f;
    G.BaseDoshReward = 0.0f;
    G.BaseSpeedReward = 0.005f;
    G.SecondaryParam = 0;
    GambitPool.AddItem(G);

    // 7: Rapid Fire
    G.GambitName = "Rapid Fire";
    G.DescTemplate = "Get %t kills within 8 seconds";
    G.ConditionType = GC_RAPID_KILLS;
    G.BaseTarget = 5;
    G.WaveScaleTarget = 0;
    G.Rarity = RARITY_RARE;
    G.RollWeight = 50;
    G.RewardType = RT_DAMAGE_DOSH;
    G.BaseDamageReward = 0.01f;
    G.BaseDoshReward = 100.0f;
    G.BaseSpeedReward = 0.0f;
    G.SecondaryParam = 8;
    GambitPool.AddItem(G);

    // 8: Desperado
    G.GambitName = "Desperado";
    G.DescTemplate = "Kill %t zeds while below 30%% health";
    G.ConditionType = GC_LOW_HP_KILLS;
    G.BaseTarget = 3;
    G.WaveScaleTarget = 1;
    G.Rarity = RARITY_RARE;
    G.RollWeight = 50;
    G.RewardType = RT_SPEED;
    G.BaseDamageReward = 0.0f;
    G.BaseDoshReward = 0.0f;
    G.BaseSpeedReward = 0.005f;
    G.SecondaryParam = 30;
    GambitPool.AddItem(G);

    // ---------------------------------------------------------------
    // LEGENDARY GAMBITS (Rank 20+)
    // ---------------------------------------------------------------

    // 9: Deadeye
    G.GambitName = "Deadeye";
    G.DescTemplate = "Kill %t large zeds with headshots";
    G.ConditionType = GC_LARGE_HEADSHOT_KILLS;
    G.BaseTarget = 3;
    G.WaveScaleTarget = 0;
    G.Rarity = RARITY_LEGENDARY;
    G.RollWeight = 25;
    G.RewardType = RT_DAMAGE;
    G.BaseDamageReward = 0.015f;
    G.BaseDoshReward = 0.0f;
    G.BaseSpeedReward = 0.0f;
    G.SecondaryParam = 0;
    GambitPool.AddItem(G);

    // 10: Flawless
    G.GambitName = "Flawless";
    G.DescTemplate = "90%+ HS ratio, min %t kills, <50 dmg taken";
    G.ConditionType = GC_FLAWLESS;
    G.BaseTarget = 15;
    G.WaveScaleTarget = 1;
    G.Rarity = RARITY_LEGENDARY;
    G.RollWeight = 25;
    G.RewardType = RT_DAMAGE_SPEED;
    G.BaseDamageReward = 0.015f;
    G.BaseDoshReward = 0.0f;
    G.BaseSpeedReward = 0.0075f;
    G.SecondaryParam = 90;
    GambitPool.AddItem(G);

    // 11: Endurance
    G.GambitName = "Endurance";
    G.DescTemplate = "Kill %t zeds with max 3 reloads";
    G.ConditionType = GC_LOW_RELOAD_KILLS;
    G.BaseTarget = 15;
    G.WaveScaleTarget = 2;
    G.Rarity = RARITY_LEGENDARY;
    G.RollWeight = 25;
    G.RewardType = RT_DOSH;
    G.BaseDamageReward = 0.0f;
    G.BaseDoshReward = 200.0f;
    G.BaseSpeedReward = 0.0f;
    G.SecondaryParam = 3;
    GambitPool.AddItem(G);

    // ---------------------------------------------------------------
    // MYTHIC GAMBITS (1% chance, Rank 10+)
    // ---------------------------------------------------------------

    // 12: Impossible Odds
    G.GambitName = "Impossible Odds";
    G.DescTemplate = "Kill a large zed with your sidearm";
    G.ConditionType = GC_SIDEARM_LARGE_KILL;
    G.BaseTarget = 1;
    G.WaveScaleTarget = 0;
    G.Rarity = RARITY_MYTHIC;
    G.RollWeight = 0;
    G.RewardType = RT_ALL;
    G.BaseDamageReward = 0.03f;
    G.BaseDoshReward = 500.0f;
    G.BaseSpeedReward = 0.015f;
    G.SecondaryParam = 0;
    GambitPool.AddItem(G);

    // 13: One Bullet
    G.GambitName = "One Bullet";
    G.DescTemplate = "Kill %t zeds without reloading";
    G.ConditionType = GC_SINGLE_MAG_KILLS;
    G.BaseTarget = 5;
    G.WaveScaleTarget = 0;
    G.Rarity = RARITY_MYTHIC;
    G.RollWeight = 0;
    G.RewardType = RT_ALL;
    G.BaseDamageReward = 0.03f;
    G.BaseDoshReward = 500.0f;
    G.BaseSpeedReward = 0.015f;
    G.SecondaryParam = 0;
    GambitPool.AddItem(G);

    `log("Gambit Helper: Setup" @ GambitPool.Length @ "gambits");
}

// ===================================================================
// SKILL QUERY -- Check if a Gambit skill is active via Extension funcs
// Returns 0 = not owned, 1 = standard, 2 = deluxe
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

// Simulated version for client-side queries (All In)
simulated function int GetSkillLevelClient(string SkillID)
{
    local KFPlayerController KFPC;
    local WMPerk MyPerk;

    if (Player == None)
        return 0;

    KFPC = KFPlayerController(GetALocalPlayerController());
    if (KFPC == None)
        return 0;

    MyPerk = WMPerk(KFPC.GetPerk());
    if (MyPerk == None)
        return 0;

    return MyPerk.ExtensionFuncInteger(0, SkillID);
}

// ===================================================================
// PROGRESS PERCENT -- Used by All In (client-safe)
// ===================================================================

simulated function float GetProgressPercent()
{
    if (!RepActive || RepCompleted || RepTarget <= 0)
        return 0.0f;

    return FClamp(float(RepProgress) / float(RepTarget), 0.0f, 1.0f);
}

// ===================================================================
// WAVE DETECTION (Tick-based, mirrors Shapeshifter pattern)
// ===================================================================

function Tick(float DeltaTime)
{
    local int WaveNum;

    Super.Tick(DeltaTime);

    if (Player == None || Player.Health <= 0)
        return;

    if (Player.WorldInfo.GRI == None)
        return;

    // Bluff immunity expiry check
    if (bBluffImmune && WorldInfo.TimeSeconds >= BluffImmuneEnd)
        bBluffImmune = False;

    WaveNum = KFGameReplicationInfo(Player.WorldInfo.GRI).WaveNum;

    // Detect wave change
    if (WaveNum != LastWaveNum && WaveNum > 0)
    {
        // Don't process wave 0 (lobby) or re-process same wave
        if (!bFirstWaveHandled || WaveNum > CurrentWaveNum)
        {
            CurrentWaveNum = WaveNum;
            LastWaveNum = WaveNum;
            bFirstWaveHandled = True;
            OnWaveStart();
        }
    }
}

// ===================================================================
// WAVE START -- Roll new gambit, reset tracking
// ===================================================================

function OnWaveStart()
{
    `log("Gambit Helper: Wave" @ CurrentWaveNum @ "started, rolling new gambit");

    ResetTracking();
    RollNewGambit();
    UpdateClientDisplay();
}

// ===================================================================
// WAVE END -- Evaluate current gambit, give rewards
// Called from ZTUpgrade_Perk_Gambit.WaveEnd
// ===================================================================

function OnWaveEnd(KFPlayerController KFPC)
{
    local int HotStreakLvl, HouseLvl, CardSharkLvl;
    local int MaxStacks;

    if (!bGambitActive || ActiveGambitIndex < 0)
        return;

    // Final completion check (wave-end-only conditions first)
    FinalWaveEndCheck();
    CheckGambitComplete();

    if (bGambitCompleted)
    {
        // Play completion sound for wave-end-only completions
        if (!bCompleteSoundPlayed)
        {
            PlayGambitSound('Gambit_Complete');
            bCompleteSoundPlayed = True;
        }

        GiveRewards(KFPC);
        ZTPlayerController(KFPC).ClientGambitAutoComplete(ActiveGambitIndex);
        `log("Gambit Helper: Gambit" @ GambitPool[ActiveGambitIndex].GambitName @ "COMPLETED on wave" @ CurrentWaveNum);
    }
    else
    {
        // Play failure sound
        PlayGambitSound('Gambit_Failed');

        ZTPlayerController(KFPC).ClientGambitExpired(ActiveGambitIndex);
        `log("Gambit Helper: Gambit" @ GambitPool[ActiveGambitIndex].GambitName @ "expired on wave" @ CurrentWaveNum);

        // --- SKILL: Hot Streak -- reset or decrement streak ---
        HotStreakLvl = GetSkillLevel("GambitHotStreak");
        if (HotStreakLvl > 0)
        {
            if (HotStreakLvl >= 2)
                StreakCount = Max(0, StreakCount - 1);
            else
                StreakCount = 0;

            `log("Gambit Helper: Hot Streak -" @ ((HotStreakLvl >= 2) ? "decremented to" : "reset to") @ StreakCount);
        }

        // --- SKILL: The House Always Wins -- increment failure stacks ---
        HouseLvl = GetSkillLevel("GambitHouseWins");
        if (HouseLvl > 0)
        {
            MaxStacks = (HouseLvl >= 2) ? 5 : 3;
            FailureStacks = Min(FailureStacks + 1, MaxStacks);
            `log("Gambit Helper: House Always Wins - failure stacks now" @ FailureStacks);
        }

        // --- SKILL: Card Shark -- increment damage stacks ---
        CardSharkLvl = GetSkillLevel("GambitCardShark");
        if (CardSharkLvl > 0)
        {
            CardSharkStacks++;
            CardSharkDamageBonus += (CardSharkLvl >= 2) ? 0.03f : 0.02f;
            `log("Gambit Helper: Card Shark - stacks now" @ CardSharkStacks @ "dmg bonus" @ FormatPercent(CardSharkDamageBonus));
        }
    }

    // Clear active gambit -- next one rolls at wave start via Tick
    bGambitActive = False;
    ActiveGambitIndex = -1;
    UpdateClientDisplay();
}

// ===================================================================
// GAMBIT ROLLING
// ===================================================================

function RollNewGambit()
{
    local int i, SelectedIndex;
    local int TotalWeight, Roll, RunningWeight;
    local array<int> EligibleIndices;
    local array<int> EligibleWeights;
    local array<int> MythicIndices;

    // Build eligible pool based on perk level
    for (i = 0; i < GambitPool.Length; i++)
    {
        if (GambitPool[i].Rarity == RARITY_NORMAL)
        {
            EligibleIndices.AddItem(i);
            EligibleWeights.AddItem(GambitPool[i].RollWeight);
        }
        else if (GambitPool[i].Rarity == RARITY_RARE && PerkLevel >= class'ZTConfig_Capstone'.default.Capstone_Rank1Level)
        {
            EligibleIndices.AddItem(i);
            EligibleWeights.AddItem(GambitPool[i].RollWeight);
        }
        else if (GambitPool[i].Rarity == RARITY_LEGENDARY && PerkLevel >= class'ZTConfig_Capstone'.default.Capstone_Rank2Level)
        {
            EligibleIndices.AddItem(i);
            EligibleWeights.AddItem(GambitPool[i].RollWeight);
        }
        else if (GambitPool[i].Rarity == RARITY_MYTHIC && PerkLevel >= class'ZTConfig_Capstone'.default.Capstone_Rank1Level)
        {
            MythicIndices.AddItem(i);
        }
    }

    // Mythic check (1% chance if eligible)
    if (MythicIndices.Length > 0 && FRand() < MYTHIC_CHANCE)
    {
        SelectedIndex = MythicIndices[Rand(MythicIndices.Length)];
        ActivateGambit(SelectedIndex);
        return;
    }

    // Weighted random from eligible pool
    if (EligibleIndices.Length == 0)
    {
        `log("Gambit Helper: No eligible gambits for level" @ PerkLevel);
        return;
    }

    TotalWeight = 0;
    for (i = 0; i < EligibleWeights.Length; i++)
        TotalWeight += EligibleWeights[i];

    Roll = Rand(TotalWeight);
    RunningWeight = 0;

    for (i = 0; i < EligibleIndices.Length; i++)
    {
        RunningWeight += EligibleWeights[i];
        if (Roll < RunningWeight)
        {
            ActivateGambit(EligibleIndices[i]);
            return;
        }
    }

    // Fallback -- should never reach here
    ActivateGambit(EligibleIndices[0]);
}

function ActivateGambit(int GambitIndex)
{
    ActiveGambitIndex = GambitIndex;
    bGambitActive = True;
    bGambitCompleted = False;
    TrackWaveStartTime = WorldInfo.TimeSeconds;

    `log("Gambit Helper: Activated [" $ GetRarityName(GambitPool[GambitIndex].Rarity) $ "]"
        @ GambitPool[GambitIndex].GambitName @ "- Target:" @ GetComputedTarget());

    // Play rarity-appropriate roll sound
    PlayGambitSound(GetRollSoundID(GambitPool[GambitIndex].Rarity));

    // Announce to player
    if (Player != None)
    {
        ZTPlayerController(Player.Controller).ClientGambitStart(
            GambitPool[GambitIndex].Rarity,
            GambitIndex,
            GetComputedTarget(),
            GambitPool[GambitIndex].SecondaryParam);
    }
}

// Compute the actual target value factoring in wave scaling + skill modifiers
function int GetComputedTarget()
{
    local int Target;
    local int StakesLvl, HouseLvl;
    local float Modifier;

    if (ActiveGambitIndex < 0 || ActiveGambitIndex >= GambitPool.Length)
        return 1;

    Target = GambitPool[ActiveGambitIndex].BaseTarget
        + (GambitPool[ActiveGambitIndex].WaveScaleTarget * CurrentWaveNum);

    // --- SKILL: Raise the Stakes -- increase target ---
    StakesLvl = GetSkillLevel("GambitRaiseTheStakes");
    if (StakesLvl >= 2)
        Target = Round(float(Target) * 1.25f);
    else if (StakesLvl > 0)
        Target = Round(float(Target) * 1.50f);

    // --- SKILL: The House Always Wins -- reduce target per failure stack ---
    HouseLvl = GetSkillLevel("GambitHouseWins");
    if (HouseLvl > 0 && FailureStacks > 0)
    {
        Modifier = 1.0f - (float(FailureStacks) * 0.20f);
        Target = Round(float(Target) * FMax(Modifier, 0.0f));
    }

    return Max(1, Target);
}

// Build description string with %t replaced by computed target
function string BuildDescription()
{
    local string Desc;
    local string TargetStr;

    if (ActiveGambitIndex < 0)
        return "";

    Desc = GambitPool[ActiveGambitIndex].DescTemplate;
    TargetStr = string(GetComputedTarget());

    // Replace %t with target
    Desc = Repl(Desc, "%t", TargetStr);
    // Replace %s with secondary param
    Desc = Repl(Desc, "%s", string(GambitPool[ActiveGambitIndex].SecondaryParam));

    return Desc;
}

// ===================================================================
// RESET TRACKING
// ===================================================================

function ResetTracking()
{
    TrackKills = 0;
    TrackHeadshotKills = 0;
    TrackLargeKills = 0;
    TrackLargeHeadshotKills = 0;
    TrackLowHPKills = 0;
    TrackDamageTaken = 0;
    bTrackTookDamage = False;
    TrackReloadCount = 0;
    TrackKillsSinceReload = 0;
    TrackBestRapidKills = 0;
    bTrackSidearmLargeKill = False;
    RecentKillTimes.Length = 0;
    LastReloadTime = 0.0f;
    bCompleteSoundPlayed = False;
}

// ===================================================================
// EVENT HANDLERS -- Called from ZTUpgrade_Perk_Gambit static functions
// ===================================================================

// Called from ModifyDamageGiven when damage is dealt to a zed
function OnDamageDealt(KFPawn_Monster MyKFPM, int InDamage, int HitZoneIdx, KFWeapon MyKFW)
{
    local bool bIsKill, bIsHeadshot, bIsLargeZed, bIsSidearm, bIsLowHP;
    local float CurrentTime;
    local int WildCardLvl;
    local float WildCardChance;

    if (!bGambitActive || bGambitCompleted)
        return;

    // Determine hit properties
    bIsKill = (MyKFPM != None && InDamage >= MyKFPM.Health);
    bIsHeadshot = (HitZoneIdx == HZI_HEAD);
    bIsLargeZed = IsLargeZed(MyKFPM);
    bIsSidearm = (MyKFW != None && MyKFW.bIsBackupWeapon);
    bIsLowHP = (Player != None && Player.Health > 0
        && (float(Player.Health) / float(Player.HealthMax)) < 0.30f);

    if (!bIsKill)
        return;

    // --- Record kill ---
    CurrentTime = WorldInfo.TimeSeconds;

    TrackKills++;
    TrackKillsSinceReload++;

    if (bIsHeadshot)
        TrackHeadshotKills++;

    if (bIsLargeZed)
    {
        TrackLargeKills++;
        if (bIsHeadshot)
            TrackLargeHeadshotKills++;
        if (bIsSidearm)
            bTrackSidearmLargeKill = True;
    }

    if (bIsLowHP)
        TrackLowHPKills++;

    // Rapid kill tracking -- add timestamp, compute best window
    RecentKillTimes.AddItem(CurrentTime);
    UpdateRapidKillCount(CurrentTime);

    // --- SKILL: Wild Card -- chance to auto-complete on kill ---
    WildCardLvl = GetSkillLevel("GambitWildCard");
    if (WildCardLvl > 0 && !bGambitCompleted)
    {
        WildCardChance = (WildCardLvl >= 2) ? 0.02f : 0.01f;
        if (FRand() < WildCardChance)
        {
            bGambitCompleted = True;
            `log("Gambit Helper: WILD CARD triggered! Auto-completed" @ GambitPool[ActiveGambitIndex].GambitName);

            PlayGambitSound('Gambit_WildCard');

            if (Player != None && Player.Controller != None)
            {
                class'ZTMessageManager'.static.SendCriticalLoc(
                    KFPlayerController(Player.Controller), 'GambitWildCard');
            }

            UpdateClientDisplay();
            return;
        }
    }

    // Check completion after each kill
    CheckGambitComplete();

    // Update client display
    UpdateClientDisplay();
}

// Called from ModifyDamageTaken when player takes damage
function OnDamageTaken(int InDamage)
{
    if (!bGambitActive || bGambitCompleted)
        return;

    TrackDamageTaken += InDamage;
    bTrackTookDamage = True;

    // Some gambits can be instantly failed or need tracking
    CheckGambitComplete();
    UpdateClientDisplay();
}

// Called from GetReloadRateScale -- debounced to count once per reload
function OnReload()
{
    local float CurrentTime;

    if (!bGambitActive || bGambitCompleted)
        return;

    CurrentTime = WorldInfo.TimeSeconds;
    if (CurrentTime - LastReloadTime > 0.5f)
    {
        TrackReloadCount++;
        TrackKillsSinceReload = 0;
        LastReloadTime = CurrentTime;
        UpdateClientDisplay();
    }
}

// ===================================================================
// RAPID KILL WINDOW CALCULATION
// ===================================================================

function UpdateRapidKillCount(float CurrentTime)
{
    local int i, Count, TimeWindow;
    local float CutoffTime;

    if (ActiveGambitIndex < 0)
        return;

    TimeWindow = GambitPool[ActiveGambitIndex].SecondaryParam;
    if (TimeWindow <= 0)
        TimeWindow = 8;

    CutoffTime = CurrentTime - float(TimeWindow);
    Count = 0;

    for (i = RecentKillTimes.Length - 1; i >= 0; i--)
    {
        if (RecentKillTimes[i] >= CutoffTime)
            Count++;
        else
            break;
    }

    if (Count > TrackBestRapidKills)
        TrackBestRapidKills = Count;
}

// ===================================================================
// COMPLETION CHECK
// ===================================================================

function CheckGambitComplete()
{
    local int Target;
    local float HSRatio;

    if (!bGambitActive || bGambitCompleted || ActiveGambitIndex < 0)
        return;

    Target = GetComputedTarget();

    switch (GambitPool[ActiveGambitIndex].ConditionType)
    {
        case GC_KILL_COUNT:
            bGambitCompleted = (TrackKills >= Target);
            break;

        case GC_HEADSHOT_KILLS:
            bGambitCompleted = (TrackHeadshotKills >= Target);
            break;

        case GC_MAX_DAMAGE_TAKEN:
            break;

        case GC_TIMED_KILLS:
            if ((WorldInfo.TimeSeconds - TrackWaveStartTime) <= float(GambitPool[ActiveGambitIndex].SecondaryParam))
                bGambitCompleted = (TrackKills >= Target);
            break;

        case GC_LARGE_ZED_KILLS:
            bGambitCompleted = (TrackLargeKills >= Target);
            break;

        case GC_HEADSHOT_RATIO:
            if (TrackKills >= Target)
            {
                HSRatio = (TrackKills > 0) ? (float(TrackHeadshotKills) / float(TrackKills) * 100.0f) : 0.0f;
                bGambitCompleted = (HSRatio >= float(GambitPool[ActiveGambitIndex].SecondaryParam));
            }
            break;

        case GC_ZERO_DAMAGE:
            break;

        case GC_RAPID_KILLS:
            bGambitCompleted = (TrackBestRapidKills >= Target);
            break;

        case GC_LOW_HP_KILLS:
            bGambitCompleted = (TrackLowHPKills >= Target);
            break;

        case GC_LARGE_HEADSHOT_KILLS:
            bGambitCompleted = (TrackLargeHeadshotKills >= Target);
            break;

        case GC_FLAWLESS:
            if (TrackKills >= Target)
            {
                HSRatio = (TrackKills > 0) ? (float(TrackHeadshotKills) / float(TrackKills) * 100.0f) : 0.0f;
                bGambitCompleted = (HSRatio >= float(GambitPool[ActiveGambitIndex].SecondaryParam)
                    && TrackDamageTaken < 50);
            }
            break;

        case GC_LOW_RELOAD_KILLS:
            if (TrackReloadCount <= GambitPool[ActiveGambitIndex].SecondaryParam)
                bGambitCompleted = (TrackKills >= Target);
            break;

        case GC_SIDEARM_LARGE_KILL:
            bGambitCompleted = bTrackSidearmLargeKill;
            break;

        case GC_SINGLE_MAG_KILLS:
            bGambitCompleted = (TrackKillsSinceReload >= Target);
            break;
    }

    if (bGambitCompleted)
    {
        `log("Gambit Helper: COMPLETED" @ GambitPool[ActiveGambitIndex].GambitName @ "mid-wave!");

        if (!bCompleteSoundPlayed)
        {
            PlayGambitSound('Gambit_Complete');
            bCompleteSoundPlayed = True;
        }

        if (Player != None && Player.Controller != None)
        {
            ZTPlayerController(Player.Controller).ClientGambitMidWaveComplete(ActiveGambitIndex);
        }
    }
}

// Special wave-end evaluation for conditions that can only be judged at wave end
function FinalWaveEndCheck()
{
    local int Target;

    if (!bGambitActive || bGambitCompleted || ActiveGambitIndex < 0)
        return;

    Target = GetComputedTarget();

    switch (GambitPool[ActiveGambitIndex].ConditionType)
    {
        case GC_MAX_DAMAGE_TAKEN:
            bGambitCompleted = (TrackDamageTaken <= Target);
            break;

        case GC_ZERO_DAMAGE:
            bGambitCompleted = !bTrackTookDamage;
            break;

        case GC_HEADSHOT_RATIO:
            if (TrackKills >= Target && !bGambitCompleted)
            {
                bGambitCompleted = ((float(TrackHeadshotKills) / float(TrackKills) * 100.0f)
                    >= float(GambitPool[ActiveGambitIndex].SecondaryParam));
            }
            break;

        case GC_FLAWLESS:
            if (TrackKills >= Target && !bGambitCompleted)
            {
                bGambitCompleted = ((float(TrackHeadshotKills) / float(TrackKills) * 100.0f)
                    >= float(GambitPool[ActiveGambitIndex].SecondaryParam))
                    && (TrackDamageTaken < 50);
            }
            break;

        default:
            break;
    }
}

// ===================================================================
// REWARD DISTRIBUTION
// ===================================================================

function GiveRewards(KFPlayerController KFPC)
{
    local float DamageReward, SpeedReward;
    local int DoshReward;
    local byte RewardType;
    local KFPlayerReplicationInfo KFPRI;
    local string DamagePctFmt, SpeedPctFmt;
    local int DoshAmountToShow, CardSharkStacksUsed;
    local float RewardMultiplier;
    local int HotStreakLvl, StakesLvl, RoyalFlushLvl, DoNLvl, AceLvl, CardSharkLvl;
    local int RoyalFlushInterval, CardSharkDosh;
    local float FlipChance;

    if (ActiveGambitIndex < 0 || !bGambitCompleted)
        return;

    RewardType = GambitPool[ActiveGambitIndex].RewardType;

    DamageReward = GambitPool[ActiveGambitIndex].BaseDamageReward * float(PerkLevel);
    DoshReward = Round(GambitPool[ActiveGambitIndex].BaseDoshReward * float(PerkLevel));
    SpeedReward = GambitPool[ActiveGambitIndex].BaseSpeedReward * float(PerkLevel);

    // =============================================================
    // SKILL REWARD MULTIPLIERS
    // =============================================================
    RewardMultiplier = 1.0f;

    // --- Raise the Stakes: double rewards ---
    StakesLvl = GetSkillLevel("GambitRaiseTheStakes");
    if (StakesLvl > 0)
        RewardMultiplier *= 2.0f;

    // --- Hot Streak: streak multiplier (1x -> 1.25x -> 1.5x -> 1.75x -> 2x) ---
    HotStreakLvl = GetSkillLevel("GambitHotStreak");
    if (HotStreakLvl > 0 && StreakCount > 0)
        RewardMultiplier *= (1.0f + FMin(float(StreakCount) * 0.25f, 1.0f));

    // --- Royal Flush: triple every Nth completion ---
    RoyalFlushLvl = GetSkillLevel("GambitRoyalFlush");
    if (RoyalFlushLvl > 0)
    {
        RoyalFlushInterval = (RoyalFlushLvl >= 2) ? 3 : 5;
        // TotalCompletions is 0-indexed (incremented AFTER rewards), so +1 for this check
        if (((TotalCompletions + 1) % RoyalFlushInterval) == 0)
        {
            RewardMultiplier *= 3.0f;
            PlayGambitSound('Gambit_RoyalFlush');
            class'ZTMessageManager'.static.SendCriticalLoc(KFPC, 'GambitRoyalFlush');
            `log("Gambit Helper: ROYAL FLUSH triggered on completion" @ (TotalCompletions + 1));
        }
    }

    // Apply multiplier to base rewards
    DamageReward *= RewardMultiplier;
    DoshReward = Round(float(DoshReward) * RewardMultiplier);
    SpeedReward *= RewardMultiplier;

    // --- Double or Nothing: coin flip AFTER other multipliers ---
    DoNLvl = GetSkillLevel("GambitDoubleOrNothing");
    if (DoNLvl > 0)
    {
        FlipChance = (DoNLvl >= 2) ? 0.60f : 0.50f;
        if (FRand() < FlipChance)
        {
            // Win -- double everything
            DamageReward *= 2.0f;
            DoshReward *= 2;
            SpeedReward *= 2.0f;
            PlayGambitSound('Gambit_DoubleOrNothing_Win');
            class'ZTMessageManager'.static.SendCriticalLoc(KFPC, 'GambitDoubleOrNothingWin');
        }
        else
        {
            // Lose -- zero everything
            DamageReward = 0.0f;
            DoshReward = 0;
            SpeedReward = 0.0f;
            PlayGambitSound('Gambit_DoubleOrNothing_Lose');
            class'ZTMessageManager'.static.SendImportantLoc(KFPC, 'GambitDoubleOrNothingBust');
        }
    }

    // =============================================================
    // APPLY REWARDS
    // =============================================================
    DamagePctFmt = "";
    SpeedPctFmt = "";
    DoshAmountToShow = 0;
    CardSharkStacksUsed = 0;

    if (RewardType == RT_DAMAGE || RewardType == RT_DAMAGE_DOSH
        || RewardType == RT_DAMAGE_SPEED || RewardType == RT_ALL)
    {
        if (DamageReward > 0.0f)
        {
            AccumulatedDamage += DamageReward;
            DamagePctFmt = "+" $ FormatPercent(DamageReward);
        }
    }

    if (RewardType == RT_DOSH || RewardType == RT_DAMAGE_DOSH || RewardType == RT_ALL)
    {
        if (DoshReward > 0)
        {
            KFPRI = KFPlayerReplicationInfo(KFPC.PlayerReplicationInfo);
            if (KFPRI != None)
                KFPRI.AddDosh(DoshReward);
            DoshAmountToShow = DoshReward;
        }
    }

    if (RewardType == RT_SPEED || RewardType == RT_DAMAGE_SPEED || RewardType == RT_ALL)
    {
        if (SpeedReward > 0.0f)
        {
            AccumulatedSpeed += SpeedReward;
            SpeedPctFmt = "+" $ FormatPercent(SpeedReward);
        }
    }

    // --- Card Shark: consume failure stacks for bonus dosh ---
    CardSharkLvl = GetSkillLevel("GambitCardShark");
    if (CardSharkLvl > 0 && CardSharkStacks > 0)
    {
        CardSharkDosh = (CardSharkLvl >= 2) ? (CardSharkStacks * 150) : (CardSharkStacks * 100);
        KFPRI = KFPlayerReplicationInfo(KFPC.PlayerReplicationInfo);
        if (KFPRI != None)
            KFPRI.AddDosh(CardSharkDosh);

        CardSharkStacksUsed = CardSharkStacks;
        `log("Gambit Helper: Card Shark cashed out" @ CardSharkStacks @ "stacks for" @ CardSharkDosh @ "dosh");
        CardSharkStacks = 0;
        CardSharkDamageBonus = 0.0f;
    }

    TotalCompletions++;

    // --- Hot Streak: increment streak on success ---
    if (HotStreakLvl > 0)
    {
        StreakCount = Min(StreakCount + 1, 4);
        `log("Gambit Helper: Hot Streak incremented to" @ StreakCount);
    }

    // --- House Always Wins: reset failure stacks on success ---
    if (GetSkillLevel("GambitHouseWins") > 0)
        FailureStacks = 0;

    // --- Ace Up Your Sleeve: grant bonus damage shots ---
    AceLvl = GetSkillLevel("GambitAce");
    if (AceLvl > 0)
    {
        AceShots = (AceLvl >= 2) ? 15 : 10;
        AceBonusPct = (AceLvl >= 2) ? 0.75f : 0.50f;
        `log("Gambit Helper: Ace Up Your Sleeve - granted" @ AceShots @ "shots at" @ FormatPercent(AceBonusPct));
    }

    ZTPlayerController(KFPC).ClientGambitReward(
        DamagePctFmt, DoshAmountToShow, SpeedPctFmt, CardSharkDosh, CardSharkStacksUsed);
    `log("Gambit Helper: Rewards given - DMG:" @ DamagePctFmt @ "Dosh:" @ DoshAmountToShow
        @ "SPD:" @ SpeedPctFmt @ "CS:" @ CardSharkDosh @ "x" @ CardSharkStacksUsed
        @ "| Total completions:" @ TotalCompletions);
}

// ===================================================================
// BLUFF -- Called from ZTUpgrade_Skill_Bluff.ModifyDamageTaken
// Returns true if Bluff triggered (caller should set HP to 1)
// ===================================================================

function bool TriggerBluff()
{
    local int BluffLvl;
    local float CooldownDuration;

    BluffLvl = GetSkillLevel("GambitBluff");
    if (BluffLvl <= 0)
        return False;

    // Check cooldown
    if (WorldInfo.TimeSeconds < BluffCooldownEnd)
        return False;

    // Must have an active gambit to sacrifice
    if (!bGambitActive || bGambitCompleted)
        return False;

    // Set cooldown
    CooldownDuration = (BluffLvl >= 2) ? 45.0f : 90.0f;
    BluffCooldownEnd = WorldInfo.TimeSeconds + CooldownDuration;

    // Deluxe: grant brief immunity
    if (BluffLvl >= 2)
    {
        bBluffImmune = True;
        BluffImmuneEnd = WorldInfo.TimeSeconds + 2.0f;
    }

    // Force-fail the gambit (no reward)
    bGambitActive = False;
    bGambitCompleted = False;
    ActiveGambitIndex = -1;

    PlayGambitSound('Gambit_Bluff');

    if (Player != None && Player.Controller != None)
    {
        class'ZTMessageManager'.static.SendCriticalLoc(
            KFPlayerController(Player.Controller), 'GambitBluff');
    }

    `log("Gambit Helper: Bluff triggered! Gambit forfeited, cooldown" @ CooldownDuration $ "s");

    UpdateClientDisplay();
    return True;
}

// Check if Bluff immunity is active (for DamageTaken check)
function bool IsBluffImmune()
{
    return bBluffImmune && (WorldInfo.TimeSeconds < BluffImmuneEnd);
}

// ===================================================================
// ACE UP YOUR SLEEVE -- Called from ZTUpgrade_Skill_AceUpYourSleeve
// Returns bonus damage and decrements counter
// ===================================================================

function float ConsumeAceShot()
{
    local float Bonus;

    if (AceShots <= 0)
        return 0.0f;

    Bonus = AceBonusPct;
    AceShots--;

    if (AceShots <= 0)
    {
        AceBonusPct = 0.0f;
        `log("Gambit Helper: Ace Up Your Sleeve - all shots spent");
    }

    return Bonus;
}

// ===================================================================
// CLIENT DISPLAY UPDATE -- Server sets Rep vars, then pushes to HUD
// ===================================================================

function UpdateClientDisplay()
{
    RepActive = bGambitActive;
    RepCompleted = bGambitCompleted;
    RepAccDamage = AccumulatedDamage;
    RepAccSpeed = AccumulatedSpeed;
    RepCompletions = TotalCompletions;
    RepStreak = StreakCount;
    RepAceShots = AceShots;

    if (ActiveGambitIndex >= 0 && ActiveGambitIndex < GambitPool.Length)
    {
        RepGambitIndex = byte(ActiveGambitIndex);
        RepRarity = GambitPool[ActiveGambitIndex].Rarity;
        RepTarget = GetComputedTarget();
        ComputeProgressAndSecondary();
    }
    else
    {
        RepGambitIndex = 255;
        RepRarity = 0;
        RepProgress = 0;
        RepTarget = 0;
        RepSecondary = 0;
    }

    // Send to owning client
    ClientUpdateDisplay(RepGambitIndex, RepRarity, RepProgress, RepTarget,
        RepActive, RepCompleted, RepAccDamage, RepAccSpeed,
        RepCompletions, RepSecondary, RepStreak, RepAceShots);
}

// Compute progress + secondary display value based on condition type
function ComputeProgressAndSecondary()
{
    local float HSRatio;

    if (ActiveGambitIndex < 0)
        return;

    switch (GambitPool[ActiveGambitIndex].ConditionType)
    {
        case GC_KILL_COUNT:
            RepProgress = TrackKills;
            RepSecondary = 0;
            break;

        case GC_HEADSHOT_KILLS:
            RepProgress = TrackHeadshotKills;
            RepSecondary = 0;
            break;

        case GC_MAX_DAMAGE_TAKEN:
            RepProgress = Max(0, RepTarget - TrackDamageTaken);
            RepSecondary = TrackDamageTaken;
            break;

        case GC_TIMED_KILLS:
            RepProgress = TrackKills;
            RepSecondary = Max(0, GambitPool[ActiveGambitIndex].SecondaryParam
                - int(WorldInfo.TimeSeconds - TrackWaveStartTime));
            break;

        case GC_LARGE_ZED_KILLS:
            RepProgress = TrackLargeKills;
            RepSecondary = 0;
            break;

        case GC_HEADSHOT_RATIO:
            HSRatio = (TrackKills > 0) ? (float(TrackHeadshotKills) / float(TrackKills) * 100.0f) : 0.0f;
            RepProgress = TrackKills;
            RepSecondary = Round(HSRatio);
            break;

        case GC_ZERO_DAMAGE:
            RepProgress = bTrackTookDamage ? 0 : 1;
            RepSecondary = TrackDamageTaken;
            break;

        case GC_RAPID_KILLS:
            RepProgress = TrackBestRapidKills;
            RepSecondary = 0;
            break;

        case GC_LOW_HP_KILLS:
            RepProgress = TrackLowHPKills;
            RepSecondary = 0;
            break;

        case GC_LARGE_HEADSHOT_KILLS:
            RepProgress = TrackLargeHeadshotKills;
            RepSecondary = 0;
            break;

        case GC_FLAWLESS:
            HSRatio = (TrackKills > 0) ? (float(TrackHeadshotKills) / float(TrackKills) * 100.0f) : 0.0f;
            RepProgress = TrackKills;
            RepSecondary = Round(HSRatio) * 1000 + Min(TrackDamageTaken, 999);
            break;

        case GC_LOW_RELOAD_KILLS:
            RepProgress = TrackKills;
            RepSecondary = TrackReloadCount;
            break;

        case GC_SIDEARM_LARGE_KILL:
            RepProgress = bTrackSidearmLargeKill ? 1 : 0;
            RepSecondary = 0;
            break;

        case GC_SINGLE_MAG_KILLS:
            RepProgress = TrackKillsSinceReload;
            RepSecondary = 0;
            break;
    }
}

// Client RPC -- receives display data and pushes to ZTHudWrapper
reliable client function ClientUpdateDisplay(byte InGambitIndex, byte InRarity,
    int InProgress, int InTarget, bool InActive, bool InCompleted,
    float InAccDamage, float InAccSpeed, int InCompletions, int InSecondary,
    int InStreak, int InAceShots)
{
    RepGambitIndex = InGambitIndex;
    RepRarity = InRarity;
    RepProgress = InProgress;
    RepTarget = InTarget;
    RepActive = InActive;
    RepCompleted = InCompleted;
    RepAccDamage = InAccDamage;
    RepAccSpeed = InAccSpeed;
    RepCompletions = InCompletions;
    RepSecondary = InSecondary;
    RepStreak = InStreak;
    RepAceShots = InAceShots;

    // Push to HUD wrapper for rendering
    PushToHUD();
}

// ===================================================================
// HUD WRAPPER INTEGRATION -- Push display data to ZTHudWrapper
// ===================================================================

simulated function PushToHUD()
{
    local KFPlayerController KFPC;
    local ZTHudWrapper HUD;
    local int GIdx;
    local string NameStr, DescStr, ProgressStr, SecondaryStr;

    if (Player == None)
        return;

    KFPC = KFPlayerController(GetALocalPlayerController());
    if (KFPC == None || KFPC.myHUD == None)
        return;

    HUD = ZTHudWrapper(KFPC.myHUD);
    if (HUD == None)
        return;

    GIdx = int(RepGambitIndex);

    if (RepActive && GIdx >= 0 && GIdx < GambitPool.Length)
    {
        NameStr = GetRarityTag(RepRarity) @ HUD.GetLocalizedGambitName(GIdx);
        DescStr = HUD.BuildLocalizedGambitDesc(GIdx, RepTarget, GambitPool[GIdx].SecondaryParam);
        ProgressStr = HUD.BuildLocalizedGambitProgress(GambitPool[GIdx].ConditionType, RepProgress, RepTarget, RepCompleted);
        SecondaryStr = HUD.BuildLocalizedGambitSecondary(GambitPool[GIdx].ConditionType, RepSecondary, GambitPool[GIdx].SecondaryParam);

        HUD.UpdateGambitDisplay(
            true, RepCompleted, RepRarity, RepGambitIndex,
            NameStr, DescStr, ProgressStr, SecondaryStr,
            RepProgress, RepTarget, RepCompletions,
            RepAccDamage, RepAccSpeed);
    }
    else
    {
        // No active gambit -- still show bank if completions exist
        if (RepCompletions > 0 || RepAccDamage > 0.0f || RepAccSpeed > 0.0f)
        {
            HUD.UpdateGambitDisplay(
                true, false, 0, 255,
                "Waiting...", "Next gambit rolls at wave start", "", "",
                0, 0, RepCompletions,
                RepAccDamage, RepAccSpeed);
        }
        else
        {
            HUD.ClearGambitDisplay();
        }
    }
}

// ===================================================================
// DISPLAY STRING BUILDERS (client-side, used by PushToHUD)
// ===================================================================

simulated function string BuildDescFromIndex(int GIdx)
{
    local string Desc, TargetStr;

    if (GIdx < 0 || GIdx >= GambitPool.Length)
        return "";

    Desc = GambitPool[GIdx].DescTemplate;
    TargetStr = string(RepTarget);
    Desc = Repl(Desc, "%t", TargetStr);
    Desc = Repl(Desc, "%s", string(GambitPool[GIdx].SecondaryParam));
    return Desc;
}

simulated function string BuildProgressString(int GIdx)
{
    if (GIdx < 0 || GIdx >= GambitPool.Length)
        return "";

    if (RepCompleted)
        return "COMPLETE!";

    switch (GambitPool[GIdx].ConditionType)
    {
        case GC_KILL_COUNT:
        case GC_HEADSHOT_KILLS:
        case GC_LARGE_ZED_KILLS:
        case GC_RAPID_KILLS:
        case GC_LOW_HP_KILLS:
        case GC_LARGE_HEADSHOT_KILLS:
        case GC_SINGLE_MAG_KILLS:
            return RepProgress $ " / " $ RepTarget;

        case GC_MAX_DAMAGE_TAKEN:
            return RepProgress $ " budget remaining";

        case GC_TIMED_KILLS:
            return RepProgress $ " / " $ RepTarget @ "kills";

        case GC_HEADSHOT_RATIO:
        case GC_FLAWLESS:
            return RepProgress $ " / " $ RepTarget @ "kills";

        case GC_ZERO_DAMAGE:
            return RepProgress > 0 ? "Clean!" : "HIT!";

        case GC_LOW_RELOAD_KILLS:
            return RepProgress $ " / " $ RepTarget @ "kills";

        case GC_SIDEARM_LARGE_KILL:
            return RepProgress > 0 ? "DONE!" : "Waiting...";

        default:
            return RepProgress $ " / " $ RepTarget;
    }
}

simulated function string BuildSecondaryString(int GIdx)
{
    if (GIdx < 0 || GIdx >= GambitPool.Length)
        return "";

    switch (GambitPool[GIdx].ConditionType)
    {
        case GC_TIMED_KILLS:
            if (RepSecondary > 0)
                return RepSecondary $ "s remaining";
            else
                return "Time expired";

        case GC_HEADSHOT_RATIO:
            return "HS Ratio: " $ RepSecondary $ "% (need "
                $ GambitPool[GIdx].SecondaryParam $ "%)";

        case GC_FLAWLESS:
            return "HS: " $ (RepSecondary / 1000) $ "% | DMG: " $ (RepSecondary % 1000) $ "/50";

        case GC_LOW_RELOAD_KILLS:
            return "Reloads: " $ RepSecondary $ " / " $ GambitPool[GIdx].SecondaryParam;

        default:
            return "";
    }
}

simulated function string BuildBankString()
{
    local string Msg;

    Msg = "Bank [" $ RepCompletions $ "]:";

    if (RepAccDamage > 0.0f)
        Msg @= "+" $ FormatPercent(RepAccDamage) $ " DMG";

    if (RepAccSpeed > 0.0f)
    {
        if (RepAccDamage > 0.0f)
            Msg @= "|";
        Msg @= "+" $ FormatPercent(RepAccSpeed) $ " SPD";
    }

    // Append streak if Hot Streak is active
    if (RepStreak > 0)
        Msg @= "| Streak:" @ RepStreak;

    // Append ace shots if any remain
    if (RepAceShots > 0)
        Msg @= "| Ace:" @ RepAceShots;

    return Msg;
}

// ===================================================================
// UTILITY FUNCTIONS
// ===================================================================

static function bool IsLargeZed(KFPawn_Monster KFPM)
{
    if (KFPM == None)
        return False;

    return KFPM.IsABoss()
        || KFPawn_ZedScrake(KFPM) != None
        || KFPawn_ZedFleshpound(KFPM) != None
        || KFPawn_ZedFleshpoundMini(KFPM) != None;
}

static function string GetRarityName(byte Rarity)
{
    switch (Rarity)
    {
        case RARITY_NORMAL:     return "NORMAL";
        case RARITY_RARE:       return "RARE";
        case RARITY_LEGENDARY:  return "LEGENDARY";
        case RARITY_MYTHIC:     return "MYTHIC";
        default:                return "UNKNOWN";
    }
}

simulated static function string GetRarityTag(byte Rarity)
{
    switch (Rarity)
    {
        case RARITY_NORMAL:     return "[N]";
        case RARITY_RARE:       return "[R]";
        case RARITY_LEGENDARY:  return "[L]";
        case RARITY_MYTHIC:     return "[M]";
        default:                return "[?]";
    }
}

simulated static function color GetRarityColor(byte Rarity)
{
    local color C;

    switch (Rarity)
    {
        case RARITY_NORMAL:
            C.R = 200; C.G = 200; C.B = 200; C.A = 255;
            break;
        case RARITY_RARE:
            C.R = 80; C.G = 160; C.B = 255; C.A = 255;
            break;
        case RARITY_LEGENDARY:
            C.R = 180; C.G = 80; C.B = 255; C.A = 255;
            break;
        case RARITY_MYTHIC:
            C.R = 255; C.G = 200; C.B = 50; C.A = 255;
            break;
        default:
            C.R = 200; C.G = 200; C.B = 200; C.A = 255;
            break;
    }

    return C;
}

static function string FormatPercent(float Value)
{
    local int Whole, Frac;

    Whole = int(Value * 100.0f);
    Frac = int((Value * 10000.0f) - float(Whole) * 100.0f);

    if (Frac > 0)
        return Whole $ "." $ Frac $ "%";
    else
        return Whole $ "%";
}

// ===================================================================
// SOUND PLAYBACK -- Route through ZTSoundManager + ClientPlayBuffSound
// ===================================================================

function PlayGambitSound(name SoundID)
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
        DKPC.ClientPlayBuffSound(Sound);
}

function name GetRollSoundID(byte Rarity)
{
    switch (Rarity)
    {
        case RARITY_NORMAL:     return 'Gambit_Roll_Normal';
        case RARITY_RARE:       return 'Gambit_Roll_Rare';
        case RARITY_LEGENDARY:  return 'Gambit_Roll_Legendary';
        case RARITY_MYTHIC:     return 'Gambit_Roll_Mythic';
        default:                return 'Gambit_Roll_Normal';
    }
}

defaultproperties
{
    RemoteRole=ROLE_SimulatedProxy
    bAlwaysRelevant=False
    bOnlyRelevantToOwner=True
    bHidden=True
    bCollideActors=False
    bBlockActors=False

    ActiveGambitIndex=-1
    PerkLevel=1
    CurrentWaveNum=0
    LastWaveNum=-1

    AccumulatedDamage=0.0f
    AccumulatedSpeed=0.0f
    TotalCompletions=0
    bCompleteSoundPlayed=False

    // Skill state defaults
    StreakCount=0
    FailureStacks=0
    CardSharkStacks=0
    CardSharkDamageBonus=0.0f
    AceShots=0
    AceBonusPct=0.0f
    BluffCooldownEnd=0.0f
    bBluffImmune=False
    BluffImmuneEnd=0.0f
    RepStreak=0
    RepAceShots=0

    Name="Default__ZTUpgrade_Perk_Gambit_Helper"
}
