// ===================================================================
// DKGameInfo_Endless - Game mode for Zedternal Endless
// Supports Roguelike Upgrade System, Boss Wave forcing,
// Artificer Reforged Weapon Registration,
// Perk Filter Config (achievement locks, prerequisites),
// and Perk Reroll System (chat command during trader time)
// ===================================================================
class DKGameInfo_Endless extends WMGameInfo_Endless;

// ===================================================================
// EXTENDED LIMITS CONSTANTS
// ===================================================================

const DK_MAX_WEAPON_UPGRADES = 51200;
const DK_MAX_TRADER_WEAPONS = 1024;

// Per-weapon slot budget (0 = use config value). Set by
// ComputeUpgradeSlotBudget in AllWeapons mode when weapons x config
// would exceed DK_MAX_WEAPON_UPGRADES; plain Endless mode leaves it 0.
var int EffectiveUpgradesPerWeapon;

// ===================================================================
// ROGUELIKE UPGRADE SYSTEM
// ===================================================================

var DKRoguelikeUpgradeManager RoguelikeManager;
var bool bRoguelikeEnabled;
var int TraderRefreshRetries;

// ===================================================================
// PERK FILTER SYSTEM
// Moved from DKMutator so it works without requiring the mutator.
// Applied during RepPlayerInfo (initial join) and during trader time
// (dynamic unlock as prerequisites are met).
// ===================================================================

var PerkFilterConfig PerkConfig;

struct PendingUnlockNotification
{
    var string PerkName;
    var Texture2D PerkIcon;
    var KFPlayerController PlayerController;
};
var array<PendingUnlockNotification> PendingPerkUnlocks;

// ===================================================================
// PERK REROLL SYSTEM
// Players type "mutate rerollperks" during trader time to re-randomize
// their unpurchased perk selection for an escalating dosh cost.
// ===================================================================

struct PerkRerollTracker
{
    var string PlayerID;
    var int RerollCount;
};
var array<PerkRerollTracker> PerkRerollTrackers;

// ===================================================================
// REFORGED WEAPON REGISTRATION (Artificer Perk)
// All 131 Reforged weapon WeapDef paths, loaded via DynamicLoadObject
// Order is deterministic (alphabetical by short name) and defines bit indices
// ===================================================================

var array<string> ReforgedWeaponDefPaths;

// ===================================================================
// HOLLOW WEAPON REGISTRATION (Hollow Perk)
// 128 Hollow weapon WeapDef paths, loaded via DynamicLoadObject
// ===================================================================

var array<string> HollowWeaponDefPaths;

// Collectible reward tracking
var bool bCollectiblesAwarded;

// Event Wave system
var int EventWavesTriggered;
var byte ForcedEventWaveID;
var DKEventWaveManager EventWaveManager;

// ===================================================================
// BULK SYNC SYSTEM — server-side trigger
// ===================================================================
// On each player's PostLogin, we add them to PendingBulkSyncPCs and
// schedule (or reschedule) ProcessPendingBulkSync to fire 1 second
// later. The 1s delay lets the net connection settle and ensures
// scalar property replication (NumberOfX, etc.) has had time to land
// before chunked roster RPCs start flowing. Multiple joins within the
// 1s window get batched into a single processing call.

var array<DKPlayerController> PendingBulkSyncPCs;

// ===================================================================
// INITIALIZATION
// ===================================================================

event InitGame(string Options, out string ErrorMessage)
{
    // Load wrapper config defaults (seeds INI on first run)
    class'DKConfig_WrapperLoader'.static.LoadAllWrapperConfigs();

    // Swap external upgrade class paths to DK wrappers BEFORE super loads them
    class'DKConfig_WrapperSwap'.static.SwapAll();

    Super.InitGame(Options, ErrorMessage);
    
    `log("[DKGameInfo] Initializing DK Zedternal Reborn Extension");

    // Spawn balance replication helper and populate with config values
    SpawnBalanceRepHelper();

    
    // Initialize Boss Wave Config
    class'Config_BossWave'.static.InitializeConfig();
    class'Config_BossWave'.static.CheckBasicConfigValues();

    // Initialize Perk Reroll Config
    class'DKConfig_PerkReroll'.static.InitializeConfig();
    class'DKConfig_PerkReroll'.static.CheckBasicConfigValues();

    class'DKConfig_HollowWeapons'.static.InitializeConfig();
    class'DKConfig_HollowWeapons'.static.CheckBasicConfigValues();

    // Initialize Capstone Config
    class'DKConfig_Capstone'.static.InitializeConfig();
    class'DKConfig_Capstone'.static.CheckBasicConfigValues();

    // Initialize Perk Unlock Rules Config
    class'DKConfig_PerkUnlockRules'.static.InitializeConfig();
    class'DKConfig_PerkUnlockRules'.static.CheckBasicConfigValues();

    // Initialize Gravity Config and apply
    class'DKConfig_Gravity'.static.InitializeConfig();
    class'DKConfig_Gravity'.static.CheckBasicConfigValues();
    ApplyGravityConfig();

    // Initialize Rank Settings config
    class'DKConfig_RankSettings'.static.UpdateConfig();
    class'DKConfig_ServerRank'.static.UpdateConfig();

    // Initialize Collectibles reward config
    class'DKConfig_Collectibles'.static.UpdateConfig();
    class'DKConfig_Collectibles'.static.CheckBasicConfigValues();

    // Initialize Event Wave config
    class'DKConfig_EventWave'.static.UpdateConfig();
    class'DKConfig_EventWave'.static.CheckBasicConfigValues();

    // Initialize Player Caps config
    class'DKConfig_PlayerCaps'.static.UpdateConfig();
    class'DKConfig_PlayerCaps'.static.CheckBasicConfigValues();

    // Initialize Grouped Zed Inject config
    class'DKConfig_ZedInjectGroup'.static.UpdateConfig();
    class'DKConfig_ZedInjectGroup'.static.CheckBasicConfigValues();

    // Initialize Roguelike config
    class'DKConfig_Roguelike'.static.UpdateConfig();
    class'DKConfig_Roguelike'.static.CheckBasicConfigValues();

    class'DKConfig_DeluxeUpgrade'.static.UpdateConfig();
    class'DKConfig_DeluxeUpgrade'.static.CheckBasicConfigValues();

    // Master on/off for the entire roguelike system (gates manager spawn,
    // upgrade-selection popup, and Wealthy wave-start dosh).
    bRoguelikeEnabled = class'DKConfig_Roguelike'.static.IsRoguelikeEnabled();

    // Initialize Roguelike Pool override config (admin StatValue/Description/disable overrides)
    class'DKConfig_RoguelikePool'.static.InitializeConfig();
    class'DKConfig_RoguelikePool'.static.CheckBasicConfigValues();

    // Initialize Map Cooldown system and register the current map
    class'DKConfig_MapCooldown'.static.UpdateConfig();
    class'DKConfig_MapCooldown'.static.RegisterCurrentMap(string(WorldInfo.GetPackageName()));

    // Initialize Artwork Config (server-side icon set forcing)
    class'DKConfig_Artwork'.static.InitializeConfig();
    class'DKConfig_Artwork'.static.CheckBasicConfigValues();

    // Initialize Perk Limit Config (max different perks per player)
    class'DKConfig_PerkLimit'.static.InitializeConfig();
    class'DKConfig_PerkLimit'.static.CheckBasicConfigValues();

    // Initialize Player Speed Config (server-side speed modifier + cap)
    class'DKConfig_PlayerSpeed'.static.InitializeConfig();
    class'DKConfig_PlayerSpeed'.static.CheckBasicConfigValues();

    // Initialize Perk Filter Config
    PerkConfig = new class'PerkFilterConfig';
    if (PerkConfig != None)
    {
        InitializeDefaultPerkRules();
        `log("[DKGameInfo] PerkFilterConfig initialized:" @ PerkConfig.UnlockRules.Length @ "unlock rules," @ PerkConfig.AchievementLockedPerks.Length @ "achievement locks");
    }
    else
    {
        `log("[DKGameInfo] ERROR: Failed to create PerkFilterConfig!");
    }
}

event PreBeginPlay()
{
    Super.PreBeginPlay();
    
    // Seed DK perk/skill/weapon-upgrade balance configs. MUST run here (not
    // InitGame): ConfigData is populated in WMGameInfo_Endless.PreBeginPlay().
    class'DKConfig_BalanceLoader'.static.LoadAllBalanceConfigs();

    // Spawn Roguelike Upgrade Manager if enabled
    if (bRoguelikeEnabled)
    {
        RoguelikeManager = Spawn(class'DKRoguelikeUpgradeManager');
        if (RoguelikeManager != None)
        {
            RoguelikeManager.OwningGameInfo = self;
            RoguelikeManager.UpgradeWaveInterval = class'DKConfig_Roguelike'.static.GetUpgradeWaveInterval();
            RoguelikeManager.CatchUpMaxSelections = class'DKConfig_Roguelike'.static.GetCatchUpMaxSelections();
            `log("[DK_ROGUELIKE] RoguelikeManager spawned. Interval=" $ RoguelikeManager.UpgradeWaveInterval $ " CatchUpMax=" $ RoguelikeManager.CatchUpMaxSelections);
        }
        else
        {
            `log("[DK_ROGUELIKE] ERROR: Failed to spawn RoguelikeManager!");
        }
    }
    else
    {
        `log("[DK_ROGUELIKE] Roguelike system disabled");
    }
}

// Push perk reroll config to GRI after super populates all WM data
event PostBeginPlay()
{
    local DKGameReplicationInfo DKGRI;

    Super.PostBeginPlay();

    DKGRI = DKGameReplicationInfo(MyKFGRI);
    if (DKGRI != None)
    {
        DKGRI.bAllowPerkReroll = class'DKConfig_PerkReroll'.default.PerkReroll_bEnable;
        DKGRI.PerkRerollBaseCost = class'DKConfig_PerkReroll'.default.PerkReroll_BasePrice;
        DKGRI.PerkRerollMultiplier = class'DKConfig_PerkReroll'.default.PerkReroll_NextRerollPriceMultiplier;
        `log("[DK_PERKREROLL] Config pushed to GRI: bEnable=" $ DKGRI.bAllowPerkReroll
            @ "BaseCost=" $ DKGRI.PerkRerollBaseCost
            @ "Multiplier=" $ DKGRI.PerkRerollMultiplier);

        // Push perk-limit / capstone caps so DKUI_UPGMenu can pre-check
        // purchases client-side (mirrors the server-side rejection in
        // DKPlayerController.BuyPerkUpgrade). Without these on the client,
        // the menu's optimistic update fakes a successful purchase even
        // though the server refused the buy.
        DKGRI.MaxDifferentPerks = class'DKConfig_PerkLimit'.default.Player_MaxDifferentPerks;
        DKGRI.bProgressivePerkUnlock = class'DKConfig_PerkLimit'.default.Player_ProgressivePerkUnlock;
        DKGRI.CapstoneR1Level = class'DKConfig_Capstone'.default.Capstone_Rank1Level;
        DKGRI.CapstoneR2Level = class'DKConfig_Capstone'.default.Capstone_Rank2Level;
        DKGRI.CapstoneMaxR1 = class'DKConfig_Capstone'.default.Capstone_MaxActiveRank1;
        DKGRI.CapstoneMaxR2 = class'DKConfig_Capstone'.default.Capstone_MaxActiveRank2;
        `log("[DK_PERKLIMIT] Config pushed to GRI: MaxDifferentPerks=" $ DKGRI.MaxDifferentPerks
            @ "ProgressiveUnlock=" $ DKGRI.bProgressivePerkUnlock
            @ "CapstoneR1=" $ DKGRI.CapstoneMaxR1 $ "@L" $ DKGRI.CapstoneR1Level
            @ "CapstoneR2=" $ DKGRI.CapstoneMaxR2 $ "@L" $ DKGRI.CapstoneR2Level);

        // Deluxe skill upgrade config (on-demand dosh sink). Replicated so the
        // trader menu can build and gate the Deluxe upgrade rows client-side.
        DKGRI.bDeluxeUpgradeEnabled = class'DKConfig_DeluxeUpgrade'.static.IsEnabled();
        DKGRI.DeluxeMinPerkLevel = class'DKConfig_DeluxeUpgrade'.static.GetMinPerkLevel();
        DKGRI.DeluxeUpgradeCost = class'DKConfig_DeluxeUpgrade'.static.GetUpgradeCost();
        DKGRI.bDeluxeTargetedSelection = class'DKConfig_DeluxeUpgrade'.static.IsTargeted();
        `log("[DK_DELUXE] Config pushed to GRI: Enabled=" $ DKGRI.bDeluxeUpgradeEnabled
            @ "MinPerkLevel=" $ DKGRI.DeluxeMinPerkLevel
            @ "Cost=" $ DKGRI.DeluxeUpgradeCost
            @ "Targeted=" $ DKGRI.bDeluxeTargetedSelection);
    }
}

// ===================================================================
// BULK SYNC TRIGGER — PostLogin override
// ===================================================================
// After parent's PostLogin completes (which runs RepPlayerInfo and the
// PerkFilter rules), queue this player for bulk sync kickoff. The 1s
// delay batches multiple simultaneous joins and lets the net connection
// stabilize before high-volume RPC traffic.

event PostLogin(PlayerController NewPlayer)
{
    local DKPlayerController DKPC;

    Super.PostLogin(NewPlayer);

    DKPC = DKPlayerController(NewPlayer);
    if (DKPC != None)
    {
        PendingBulkSyncPCs.AddItem(DKPC);
        // (Re)schedule the kickoff. Each join resets the 1s timer; if
        //  multiple players join in rapid succession, all get processed
        //  together when the timer finally fires.
        SetTimer(1.0f, false, NameOf(ProcessPendingBulkSync));
        `log("[DK_BULKSYNC] Queued bulk sync kickoff for" @ DKPC.PlayerReplicationInfo.PlayerName
            @ "-- pending count:" @ PendingBulkSyncPCs.Length);

        // Late-joiner roguelike catch-up (opt-in). Snapshot what they missed now;
        // it is flushed at trader time (OpenTrader / EndUpgradeSelection). If they
        // joined while the trader is already open, attempt an immediate flush.
        if (bRoguelikeEnabled && RoguelikeManager != None
            && class'DKConfig_Roguelike'.static.IsCatchUpEnabled())
        {
            RoguelikeManager.EnqueueCatchUp(DKPC);
            if (MyKFGRI != None && MyKFGRI.bTraderIsOpen)
                RoguelikeManager.ProcessCatchUpQueue();
        }
    }
}

/** Timer callback. Walks the pending list and calls ServerStartBulkSync
 *  on each PC that's still alive. Called 1s after the last queued join. */
function ProcessPendingBulkSync()
{
    local int i;
    local DKGameReplicationInfo DKGRI;

    DKGRI = DKGameReplicationInfo(MyKFGRI);
    if (DKGRI == None)
    {
        // GRI not ready (unusual at this point). Retry once.
        `log("[DK_BULKSYNC] WARNING: ProcessPendingBulkSync ran but GRI is not DKGameReplicationInfo -- retry in 1s");
        SetTimer(1.0f, false, NameOf(ProcessPendingBulkSync));
        return;
    }

    for (i = 0; i < PendingBulkSyncPCs.Length; ++i)
    {
        if (PendingBulkSyncPCs[i] != None)
        {
            PendingBulkSyncPCs[i].ServerStartBulkSync(DKGRI, self);
        }
    }

    `log("[DK_BULKSYNC] Kicked off bulk sync for" @ PendingBulkSyncPCs.Length @ "player(s)");
    PendingBulkSyncPCs.Length = 0;
}

// ===================================================================
// PERK FILTER — DEFAULT RULES
// These define which perks require prerequisites or achievements.
// ===================================================================

function ApplyGravityConfig()
{
    local float GravityValue;
    local string MapName;

    MapName = WorldInfo.GetMapName(True);
    GravityValue = class'DKConfig_Gravity'.static.GetGravityForMap(MapName);

    if (GravityValue < 0.0f)
    {
        WorldInfo.WorldGravityZ = GravityValue;
        WorldInfo.GlobalGravityZ = GravityValue;
        `log("[DK_GRAVITY] Applied gravity=" $ GravityValue @ "for map" @ MapName);
    }
    else
    {
        `log("[DK_GRAVITY] Using default gravity for map" @ MapName);
    }
}

function InitializeDefaultPerkRules()
{
    if (PerkConfig == None) return;

    // Load all rules from INI config
    class'DKConfig_PerkUnlockRules'.static.ApplyRules(PerkConfig);

    `log("[DKGameInfo] Perk rules: " $ PerkConfig.UnlockRules.Length $ " prerequisite rules, " $ PerkConfig.AchievementLockedPerks.Length $ " achievement locks, " $ PerkConfig.ExclusionRules.Length $ " exclusion rules");
}

// ===================================================================
// PERK FILTER — PLAYER JOIN (RepPlayerInfo Override)
// Called when a player connects. Super handles the WM random selection,
// then we apply filter rules to lock perks that shouldn't be visible.
// ===================================================================

function RepPlayerInfo(WMPlayerReplicationInfo WMPRI)
{
    // Let WM do its standard random perk selection first
    Super.RepPlayerInfo(WMPRI);

    // Apply filter rules on top — lock achievement-locked and prerequisite-gated perks
    if (PerkConfig != None && WMPRI != None)
    {
        ApplyPerkFilterRules(WMPRI);
    }
}

// Initial lock pass: lock perks that should not be visible at join time.
// This runs AFTER Super.RepPlayerInfo has done its random unlock selection.
function ApplyPerkFilterRules(WMPlayerReplicationInfo WMPRI)
{
    local WMGameReplicationInfo WMGRI;
    local DKPlayerReplicationInfo DKPRI;
    local int i, RuleIdx, PerkIdx, ReqIdx;
    local string PerkClassName, SteamID;
    local bool bMeetsRequirements;
    local byte GlobalRank, LocalRank;

    WMGRI = WMGameReplicationInfo(MyKFGRI);
    if (WMGRI == None) return;

    // Get player's rank for rank-gated perk checks
    DKPRI = DKPlayerReplicationInfo(WMPRI);
    GlobalRank = 0;
    LocalRank = 0;
    if (DKPRI != None)
        GlobalRank = DKPRI.PlayerRank;
    if (class'DKConfig_RankSettings'.static.IsLocalRank())
    {
        SteamID = class'DKConfig_ServerRank'.static.GetSteamIDFromPRI(WMPRI);
        if (SteamID != "")
            LocalRank = class'DKConfig_ServerRank'.static.GetPlayerRank(SteamID);
    }

    // Pass 1: Lock achievement-locked perks
    for (i = 0; i < WMGRI.PerkUpgradesList.Length; i++)
    {
        PerkClassName = string(WMGRI.PerkUpgradesList[i].PerkUpgrade.Name);

        if (PerkConfig.IsAchievementLocked(PerkClassName))
        {
            WMPRI.bPerkUpgrade[i].bUnlocked = False;
            `log("[DK_PERKFILTER] Locked achievement perk:" @ PerkClassName @ "for" @ WMPRI.PlayerName);
        }

        // Rank-gated perk check (skip if rank is 0 — rank hasn't been reported yet,
        // will be enforced when ServerReportRank fires with the actual rank)
        if (GlobalRank > 0 || LocalRank > 0)
        {
            if (!class'DKConfig_PerkUnlockRules'.static.MeetsRankRequirement(PerkClassName, GlobalRank, LocalRank))
            {
                WMPRI.bPerkUpgrade[i].bUnlocked = False;
                `log("[DK_PERKFILTER] Locked rank-gated perk:" @ PerkClassName @ "for" @ WMPRI.PlayerName
                    @ "(Global:" @ GlobalRank @ "Local:" @ LocalRank
                    @ "Required:" @ class'DKConfig_PerkUnlockRules'.static.GetRankRequirement(PerkClassName) $ ")");
            }
        }
    }

    // Pass 2: Lock prerequisite-gated perks where requirements aren't met
    for (RuleIdx = 0; RuleIdx < PerkConfig.UnlockRules.Length; RuleIdx++)
    {
        PerkClassName = PerkConfig.UnlockRules[RuleIdx].PerkClassName;

        // Skip achievement-locked perks (already handled above)
        if (PerkConfig.IsAchievementLocked(PerkClassName))
            continue;

        PerkIdx = FindPerkIndex(WMGRI, PerkClassName);
        if (PerkIdx == INDEX_NONE) continue;

        // Check if all prerequisites are met
        bMeetsRequirements = True;
        for (ReqIdx = 0; ReqIdx < PerkConfig.UnlockRules[RuleIdx].RequiredPerks.Length; ReqIdx++)
        {
            i = FindPerkIndex(WMGRI, PerkConfig.UnlockRules[RuleIdx].RequiredPerks[ReqIdx]);
            if (i == INDEX_NONE || WMPRI.bPerkUpgrade[i].level < PerkConfig.UnlockRules[RuleIdx].RequiredPerkLevels[ReqIdx])
            {
                bMeetsRequirements = False;
                break;
            }
        }

        if (!bMeetsRequirements)
        {
            WMPRI.bPerkUpgrade[PerkIdx].bUnlocked = False;
            `log("[DK_PERKFILTER] Locked prerequisite perk:" @ PerkClassName @ "for" @ WMPRI.PlayerName);
        }
    }
}

// ===================================================================
// PERK FILTER — TRADER-TIME DYNAMIC UNLOCK
// While trader is open, periodically check if prerequisites are now met
// (e.g. player leveled Symbiote to 10, Cinder should appear).
// ===================================================================

function CheckPerkUnlocks()
{
    local WMGameReplicationInfo WMGRI;
    local WMPlayerController WMPC;
    local WMPlayerReplicationInfo WMPRI;

    WMGRI = WMGameReplicationInfo(MyKFGRI);
    if (WMGRI == None) return;

    // Stop checking if trader closed
    if (!WMGRI.bTraderIsOpen)
    {
        ClearTimer(NameOf(CheckPerkUnlocks));
        return;
    }

    foreach WorldInfo.AllControllers(class'WMPlayerController', WMPC)
    {
        WMPRI = WMPlayerReplicationInfo(WMPC.PlayerReplicationInfo);
        if (WMPRI != None)
        {
            ApplyPerkUnlockRules(WMPRI, WMGRI);
        }
    }

    // Show any queued unlock notifications
    if (PendingPerkUnlocks.Length > 0)
    {
        ShowPendingPerkUnlockNotifications();
    }
}

// Dynamic unlock pass: check all prerequisite rules and unlock/lock as needed.
// Unlike the initial pass, this can UNLOCK perks mid-game when prerequisites are met.
function ApplyPerkUnlockRules(WMPlayerReplicationInfo WMPRI, WMGameReplicationInfo WMGRI)
{
    local DKPlayerReplicationInfo DKPRI;
    local int RuleIdx, PerkIdx, ReqIdx;
    local string PerkClassName, PerkName, SteamID;
    local bool bMeetsRequirements, bWasLocked;
    local int LockedPerkIdx;
    local byte DynGlobalRank, DynLocalRank;

    if (PerkConfig == None || WMPRI == None || WMGRI == None) return;

    // Get ranks for rank-gate checks
    DKPRI = DKPlayerReplicationInfo(WMPRI);
    DynGlobalRank = 0;
    DynLocalRank = 0;
    if (DKPRI != None)
        DynGlobalRank = DKPRI.PlayerRank;
    if (class'DKConfig_RankSettings'.static.IsLocalRank())
    {
        SteamID = class'DKConfig_ServerRank'.static.GetSteamIDFromPRI(WMPRI);
        if (SteamID != "")
            DynLocalRank = class'DKConfig_ServerRank'.static.GetPlayerRank(SteamID);
    }

    for (RuleIdx = 0; RuleIdx < PerkConfig.UnlockRules.Length; RuleIdx++)
    {
        PerkClassName = PerkConfig.UnlockRules[RuleIdx].PerkClassName;

        // Skip achievement-locked perks — only achievements can unlock those
        if (PerkConfig.IsAchievementLocked(PerkClassName))
            continue;

        // Skip rank-locked perks the player hasn't reached rank for
        if (!class'DKConfig_PerkUnlockRules'.static.MeetsRankRequirement(PerkClassName, DynGlobalRank, DynLocalRank))
            continue;

        LockedPerkIdx = FindPerkIndex(WMGRI, PerkClassName);
        if (LockedPerkIdx == INDEX_NONE) continue;

        PerkName = WMGRI.PerkUpgradesList[LockedPerkIdx].PerkUpgrade.default.UpgradeName;
        bWasLocked = !WMPRI.bPerkUpgrade[LockedPerkIdx].bUnlocked;

        // Check all prerequisites
        bMeetsRequirements = True;
        for (ReqIdx = 0; ReqIdx < PerkConfig.UnlockRules[RuleIdx].RequiredPerks.Length; ReqIdx++)
        {
            PerkIdx = FindPerkIndex(WMGRI, PerkConfig.UnlockRules[RuleIdx].RequiredPerks[ReqIdx]);
            if (PerkIdx == INDEX_NONE
                || WMPRI.bPerkUpgrade[PerkIdx].level < PerkConfig.UnlockRules[RuleIdx].RequiredPerkLevels[ReqIdx])
            {
                bMeetsRequirements = False;
                break;
            }
        }

        if (bMeetsRequirements)
        {
            if (bWasLocked)
            {
                // Perk just became unlockable — queue notification
                QueuePerkUnlock(WMPRI, PerkName, LockedPerkIdx, WMGRI);
            }
            else
            {
                WMPRI.bPerkUpgrade[LockedPerkIdx].bUnlocked = True;
            }
        }
        else
        {
            WMPRI.bPerkUpgrade[LockedPerkIdx].bUnlocked = False;
        }
    }
}

function QueuePerkUnlock(WMPlayerReplicationInfo WMPRI, string PerkName, int PerkIdx, WMGameReplicationInfo WMGRI)
{
    local PendingUnlockNotification PendingNotif;
    local PlayerController PC;

    PendingNotif.PerkName = PerkName;
    PendingNotif.PerkIcon = None;

    foreach WorldInfo.AllControllers(class'PlayerController', PC)
    {
        if (PC.PlayerReplicationInfo == WMPRI)
        {
            PendingNotif.PlayerController = KFPlayerController(PC);
            break;
        }
    }

    if (PendingNotif.PlayerController != None)
    {
        PendingPerkUnlocks.AddItem(PendingNotif);
        `log("[DK_PERKFILTER] Queued perk unlock notification:" @ PerkName);
    }
}

function ShowPendingPerkUnlockNotifications()
{
    local int i, PerkIdx;
    local DKMessageReplicator Replicator;
    local WMGameReplicationInfo WMGRI;
    local WMPlayerReplicationInfo WMPRI;
    local DKPlayerController DKPC;
    local SoundCue PerkUnlockSound;
    local DKMutator DKMut;

    if (PendingPerkUnlocks.Length == 0) return;

    WMGRI = WMGameReplicationInfo(MyKFGRI);
    if (WMGRI == None) return;

    `log("[DK_PERKFILTER] Showing" @ PendingPerkUnlocks.Length @ "perk unlock notifications");

    DKMut = class'DKSoundManager'.static.GetMutator(WorldInfo);
    if (DKMut != None)
        PerkUnlockSound = class'DKSoundManager'.static.GetSound(DKMut, 'PerkUnlock_Epic');

    for (i = 0; i < PendingPerkUnlocks.Length; i++)
    {
        if (PendingPerkUnlocks[i].PlayerController == None) continue;

        WMPRI = WMPlayerReplicationInfo(PendingPerkUnlocks[i].PlayerController.PlayerReplicationInfo);
        if (WMPRI != None)
        {
            PerkIdx = FindPerkIndexByName(WMGRI, PendingPerkUnlocks[i].PerkName);
            if (PerkIdx != INDEX_NONE)
            {
                WMPRI.bPerkUpgrade[PerkIdx].bUnlocked = true;
            }
        }

        // Play perk unlock sound
        DKPC = DKPlayerController(PendingPerkUnlocks[i].PlayerController);
        if (DKPC != None && PerkUnlockSound != None)
        {
            DKPC.ClientPlayPerkUnlockSound(PerkUnlockSound);
        }

        // Show notification popup
        Replicator = class'DKMessageReplicator'.static.GetReplicatorForPlayer(PendingPerkUnlocks[i].PlayerController);
        if (Replicator != None)
        {
            Replicator.ShowPerkUnlockPopupByIndex(
                PendingPerkUnlocks[i].PerkName,
                PerkIdx
            );
        }

        class'DKMessageManager'.static.SendCritical(
            PendingPerkUnlocks[i].PlayerController,
            "NEW PERK UNLOCKED:" @ PendingPerkUnlocks[i].PerkName
        );
    }

    PendingPerkUnlocks.Length = 0;
}

// ===================================================================
// PERK FILTER — HELPER FUNCTIONS
// ===================================================================

function int FindPerkIndex(WMGameReplicationInfo WMGRI, string ClassName)
{
    local int i;
    local string CurrentName;
    local class<WMUpgrade_Perk> SearchClass;

    for (i = 0; i < WMGRI.PerkUpgradesList.Length; i++)
    {
        CurrentName = string(WMGRI.PerkUpgradesList[i].PerkUpgrade.Name);

        // Exact class name match
        if (CurrentName ~= ClassName)
            return i;

        // Strip package prefix and match
        if (CurrentName ~= GetItemName(ClassName))
            return i;

        // Full path match
        if (PathName(WMGRI.PerkUpgradesList[i].PerkUpgrade) ~= ClassName)
            return i;
    }

    // Inheritance check: if ClassName is a parent class (e.g. WMUpgrade_Perk_Berserker)
    // and the list has a wrapper subclass (DKWrapper_Perk_Berserker), match by inheritance
    SearchClass = class<WMUpgrade_Perk>(DynamicLoadObject(ClassName, class'Class', True));
    if (SearchClass == None)
        SearchClass = class<WMUpgrade_Perk>(DynamicLoadObject("ZedternalReborn." $ ClassName, class'Class', True));
    if (SearchClass == None)
        SearchClass = class<WMUpgrade_Perk>(DynamicLoadObject("ZedternalRBPerkpackage." $ ClassName, class'Class', True));

    if (SearchClass != None)
    {
        for (i = 0; i < WMGRI.PerkUpgradesList.Length; i++)
        {
            if (ClassIsChildOf(WMGRI.PerkUpgradesList[i].PerkUpgrade, SearchClass))
                return i;
        }
    }

    return INDEX_NONE;
}

function int FindPerkIndexByName(WMGameReplicationInfo WMGRI, string PerkName)
{
    local int i;

    for (i = 0; i < WMGRI.PerkUpgradesList.Length; i++)
    {
        if (WMGRI.PerkUpgradesList[i].PerkUpgrade.default.UpgradeName ~= PerkName)
            return i;
    }

    return INDEX_NONE;
}

// ===================================================================
// PERK REROLL SYSTEM — COMMAND HANDLER
// Intercepts "mutate rerollperks" commands from players.
// Usage:
//   mutate rerollperks       — execute the reroll (costs dosh)
//   mutate rerollperks cost  — show current cost without rerolling
// ===================================================================

function Mutate(string MutateString, PlayerController Sender)
{
    local string Cmd;

    Cmd = Locs(MutateString);

    if (Cmd == "rerollperks")
    {
        HandlePerkReroll(Sender);
    }
    else if (Cmd == "rerollperks cost")
    {
        ShowPerkRerollCost(Sender);
    }
    else
    {
        Super.Mutate(MutateString, Sender);
    }
}

// Show the player their current perk reroll cost
function ShowPerkRerollCost(PlayerController Sender)
{
    local int Cost, PlayerRerollCount;
    local DKGameReplicationInfo DKGRI;

    if (Sender == None) return;

    DKGRI = DKGameReplicationInfo(MyKFGRI);
    if (DKGRI == None || !DKGRI.bAllowPerkReroll)
    {
        Sender.ClientMessage("Perk reroll is disabled on this server.");
        return;
    }

    PlayerRerollCount = GetPlayerPerkRerollCount(Sender);
    Cost = GetPerkRerollCost(PlayerRerollCount);

    Sender.ClientMessage("Perk Reroll Cost:" @ Cost @ "Dosh (reroll #" $ (PlayerRerollCount + 1) $ ")");
    Sender.ClientMessage("Type 'mutate rerollperks' during trader time to reroll.");
}

// Execute perk reroll for the requesting player
function HandlePerkReroll(PlayerController Sender)
{
    local WMGameReplicationInfo WMGRI;
    local WMPlayerReplicationInfo WMPRI;
    local DKPlayerReplicationInfo DKPRI;
    local DKGameReplicationInfo DKGRI;
    local int i, Cost, PlayerRerollCount;
    local int UnlockedUnpurchasedCount;
    local array<int> RerollPool;
    local array<int> ProtectedPerks;
    local int NumToUnlock, Choice;
    local string PerkClassName;
    local byte RerollGlobalRank;

    if (Sender == None) return;

    DKGRI = DKGameReplicationInfo(MyKFGRI);
    WMGRI = WMGameReplicationInfo(MyKFGRI);
    WMPRI = WMPlayerReplicationInfo(Sender.PlayerReplicationInfo);

    DKPRI = DKPlayerReplicationInfo(WMPRI);

    // Validate basic state
    if (DKGRI == None || WMGRI == None || WMPRI == None)
    {
        Sender.ClientMessage("Perk reroll failed: invalid game state.");
        return;
    }

    // Check feature is enabled
    if (!DKGRI.bAllowPerkReroll)
    {
        Sender.ClientMessage("Perk reroll is disabled on this server.");
        return;
    }

    // Check trader is open
    if (!WMGRI.bTraderIsOpen)
    {
        Sender.ClientMessage("Perk reroll is only available during trader time!");
        return;
    }

    // Calculate cost
    PlayerRerollCount = GetPlayerPerkRerollCount(Sender);
    Cost = GetPerkRerollCost(PlayerRerollCount);

    // Check player can afford it
    if (WMPRI.Score < Cost)
    {
        Sender.ClientMessage("Not enough Dosh! Perk reroll costs" @ Cost @ "Dosh. You have" @ WMPRI.Score @ "Dosh.");
        return;
    }

    // ---------------------------------------------------------------
    // STEP 1: Count currently unlocked-but-unpurchased perks
    // These are the slots we will re-randomize.
    // ---------------------------------------------------------------
    UnlockedUnpurchasedCount = 0;
    for (i = 0; i < WMGRI.PerkUpgradesList.Length; ++i)
    {
        if (WMPRI.bPerkUpgrade[i].bUnlocked && WMPRI.bPerkUpgrade[i].level == 0)
        {
            // Don't count static perks — they stay locked in place
            if (i < StaticPerks.Length && StaticPerks[i])
                continue;

            ++UnlockedUnpurchasedCount;
        }
    }

    if (UnlockedUnpurchasedCount == 0)
    {
        Sender.ClientMessage("No unpurchased perks to reroll!");
        return;
    }

    // ---------------------------------------------------------------
    // STEP 2: Build reroll pool — all unpurchased, non-static perks
    // This includes perks that are currently locked AND unlocked.
    // PerkFilter rules will be applied after randomization.
    // ---------------------------------------------------------------
    for (i = 0; i < WMGRI.PerkUpgradesList.Length; ++i)
    {
        // Skip purchased perks (level > 0) — these are kept
        if (WMPRI.bPerkUpgrade[i].level > 0)
            continue;

        // Skip static perks — always available, not part of random pool
        if (i < StaticPerks.Length && StaticPerks[i])
            continue;

        // Skip achievement-locked perks — only achievements can unlock these
        PerkClassName = string(WMGRI.PerkUpgradesList[i].PerkUpgrade.Name);
        if (PerkConfig != None)
        {
            if (PerkConfig.IsAchievementLocked(PerkClassName))
                continue;
        }

        // Skip rank-locked perks — player hasn't reached required rank
        RerollGlobalRank = 0;
        if (DKPRI != None)
            RerollGlobalRank = DKPRI.PlayerRank;
        if (!class'DKConfig_PerkUnlockRules'.static.MeetsRankRequirement(PerkClassName, RerollGlobalRank, 0))
            continue;

        RerollPool.AddItem(i);
    }

    if (RerollPool.Length == 0)
    {
        Sender.ClientMessage("No perks available for reroll!");
        return;
    }

    `log("[DK_PERKREROLL]" @ WMPRI.PlayerName @ "rerolling perks. Pool:" @ RerollPool.Length
        @ "slots, unlocking" @ UnlockedUnpurchasedCount @ "perks. Cost:" @ Cost);

    // ---------------------------------------------------------------
    // STEP 3: Lock all pool perks, then randomly unlock
    // ---------------------------------------------------------------
    for (i = 0; i < RerollPool.Length; ++i)
    {
        WMPRI.bPerkUpgrade[RerollPool[i]].bUnlocked = False;
    }

    NumToUnlock = Min(UnlockedUnpurchasedCount, RerollPool.Length);
    for (i = 0; i < NumToUnlock; ++i)
    {
        Choice = Rand(RerollPool.Length);
        WMPRI.bPerkUpgrade[RerollPool[Choice]].bUnlocked = True;
        RerollPool.Remove(Choice, 1);
    }

    // ---------------------------------------------------------------
    // STEP 4: Protect perks that must survive the reroll, re-apply the
    // PerkFilter rules, then restore the protected perks.
    //
    // ApplyPerkFilterRules is the join-time lock pass: it unconditionally
    // re-locks every achievement-locked perk (Tycoon, Headhunter) and any
    // perk whose prerequisites/rank aren't met. Achievement unlocks are
    // one-time events that cannot be re-derived from current perk levels, so
    // re-running the filter on a reroll wrongly strips perks the player has
    // already EARNED -- or worse, INVESTED in -- even though those are
    // deliberately excluded from the reroll pool above. Snapshot them first,
    // re-filter (still needed to gate prerequisite perks in the rolled set),
    // then re-assert their unlock.
    // ---------------------------------------------------------------
    ProtectedPerks.Length = 0;
    for (i = 0; i < WMGRI.PerkUpgradesList.Length; ++i)
    {
        // Invested perks must never be locked -- the player paid for them.
        if (WMPRI.bPerkUpgrade[i].level > 0)
        {
            ProtectedPerks.AddItem(i);
            continue;
        }

        // Earned achievement perks (unlocked but unpurchased) are not part
        // of the reroll pool; preserve their earned unlock across the reroll.
        if (WMPRI.bPerkUpgrade[i].bUnlocked && PerkConfig != None)
        {
            PerkClassName = string(WMGRI.PerkUpgradesList[i].PerkUpgrade.Name);
            if (PerkConfig.IsAchievementLocked(PerkClassName))
                ProtectedPerks.AddItem(i);
        }
    }

    if (PerkConfig != None)
    {
        ApplyPerkFilterRules(WMPRI);
    }

    for (i = 0; i < ProtectedPerks.Length; ++i)
    {
        WMPRI.bPerkUpgrade[ProtectedPerks[i]].bUnlocked = True;
    }

    // ---------------------------------------------------------------
    // STEP 5: Deduct dosh and increment reroll counter
    // ---------------------------------------------------------------
    WMPRI.AddDosh(-Cost);
    IncrementPlayerPerkRerollCount(Sender);

    // Notify the player
    Sender.ClientMessage("Perks rerolled! Cost:" @ Cost @ "Dosh. Next reroll:" @ GetPerkRerollCost(PlayerRerollCount + 1) @ "Dosh.");

    `log("[DK_PERKREROLL]" @ WMPRI.PlayerName @ "perk reroll complete. Remaining dosh:" @ WMPRI.Score);
}

// ===================================================================
// PERK REROLL — COST & TRACKING HELPERS
// ===================================================================

// Calculate cost: BaseCost * (Multiplier ^ RerollCount)
function int GetPerkRerollCost(int RerollCount)
{
    local float Cost;

    Cost = float(class'DKConfig_PerkReroll'.default.PerkReroll_BasePrice)
         * (class'DKConfig_PerkReroll'.default.PerkReroll_NextRerollPriceMultiplier ** float(RerollCount));

    return int(Cost);
}

// Get how many times this player has rerolled perks
function int GetPlayerPerkRerollCount(PlayerController PC)
{
    local int i;
    local string PID;

    if (PC == None || PC.PlayerReplicationInfo == None)
        return 0;

    PID = PC.PlayerReplicationInfo.UniqueId.Uid.A $ "_" $ PC.PlayerReplicationInfo.UniqueId.Uid.B;

    for (i = 0; i < PerkRerollTrackers.Length; ++i)
    {
        if (PerkRerollTrackers[i].PlayerID == PID)
            return PerkRerollTrackers[i].RerollCount;
    }

    return 0;
}

// Increment this player's reroll count
function IncrementPlayerPerkRerollCount(PlayerController PC)
{
    local int i;
    local string PID;
    local PerkRerollTracker NewTracker;

    if (PC == None || PC.PlayerReplicationInfo == None)
        return;

    PID = PC.PlayerReplicationInfo.UniqueId.Uid.A $ "_" $ PC.PlayerReplicationInfo.UniqueId.Uid.B;

    for (i = 0; i < PerkRerollTrackers.Length; ++i)
    {
        if (PerkRerollTrackers[i].PlayerID == PID)
        {
            ++PerkRerollTrackers[i].RerollCount;
            return;
        }
    }

    // New entry
    NewTracker.PlayerID = PID;
    NewTracker.RerollCount = 1;
    PerkRerollTrackers.AddItem(NewTracker);
}

// ===================================================================
// WEAPON LIST — Remove Precious, then register Reforged weapons
// ===================================================================

function BuildWeaponList()
{
    // Register all normal weapons first (wave-gated as usual)
    super.BuildWeaponList();

    // DK FIX: RemovePreciousWeapons() call REMOVED. Stripping Precious entries
    // from AllowedWeaponsList/WeaponUpgradeSlotsList AFTER generation desynced
    // the seeded RNG stream between server (which consumed positions for
    // Precious weapons) and client (which regenerates from the stripped list
    // and never consumes them). Result: BuyWeaponUpgrade(index) applied a
    // different upgrade than the trader UI displayed. Precious variants are
    // now allowed again, restoring exact ZR parity. RemovePreciousWeapons()
    // is kept below as dead code for reference.

    // Append all Reforged weapons (hidden by bitmask until unlocked)
    RegisterReforgedWeapons();

    // Append all Hollow weapons (hidden by per-player unlock until conditions met)
    if (class'DKConfig_HollowWeapons'.static.IsEnabled())
        RegisterHollowWeapons();
}

// Removes Precious weapon variants from visibility and upgrade lists ONLY.
// IMPORTANT: We deliberately keep SaleItems and KFWeaponDefPath intact.
// Both client and server must have identical SaleItems arrays for the
// index-based buy system (ServerBuyWeaponZedternal) to work correctly.
// Removing from SaleItems on the server causes index mismatches on
// dedicated servers where the client rebuilds its list via replication.
//
// What we remove from:
//   1. AllowedWeaponsList — hides Precious from trader UI (IsItemAllowed)
//   2. WeaponUpgradeSlotsList — frees upgrade slots for Reforged weapons
//
// What we keep intact:
//   - TraderItems.SaleItems — preserves buy index parity
//   - KFWeaponDefPath — preserves replication parity
function RemovePreciousWeapons()
{
    local int i, RemovedSlots, RemovedAllowed;
    local WMGameReplicationInfo WMGRI;

    WMGRI = WMGameReplicationInfo(MyKFGRI);
    if (WMGRI == None)
        return;

    RemovedSlots = 0;
    RemovedAllowed = 0;

    // 1. Remove from AllowedWeaponsList (hides from trader UI)
    for (i = WMGRI.AllowedWeaponsList.Length - 1; i >= 0; --i)
    {
        if (InStr(WMGRI.AllowedWeaponsList[i].KFWeaponPath, "Precious") != INDEX_NONE)
        {
            WMGRI.AllowedWeaponsList.Remove(i, 1);
            ++RemovedAllowed;
        }
    }

    // 2. Remove from WeaponUpgradeSlotsList (frees upgrade slots)
    for (i = WMGRI.WeaponUpgradeSlotsList.Length - 1; i >= 0; --i)
    {
        if (WMGRI.WeaponUpgradeSlotsList[i].KFWeapon != None
            && InStr(PathName(WMGRI.WeaponUpgradeSlotsList[i].KFWeapon), "Precious") != INDEX_NONE)
        {
            WMGRI.WeaponUpgradeSlotsList.Remove(i, 1);
            ++RemovedSlots;
        }
    }

    `log("ZR Precious Removal: Removed" @ RemovedAllowed @ "AllowedWeapons," @ RemovedSlots @ "upgrade slots (SaleItems/KFWeaponDefPath preserved)");
    `log("ZR Precious Removal: Remaining - AllowedWeapons:" @ WMGRI.AllowedWeaponsList.Length
        @ "| SaleItems:" @ TraderItems.SaleItems.Length
        @ "| KFWeaponDefPath:" @ KFWeaponDefPath.Length
        @ "| UpgradeSlots:" @ WMGRI.WeaponUpgradeSlotsList.Length);
}

// Adds Reforged weapons to AllowedWeaponsList starting AFTER all normal weapons
// Records ReforgedStartIndex on the GRI so IsItemAllowed knows the boundary
// Uses AddWeaponInTrader() to also generate weapon upgrade slots
function RegisterReforgedWeapons()
{
    local int i, RegisteredCount, IDCount;
    local class<KFWeaponDefinition> WD;
    local DKGameReplicationInfo DKGRI;
    local STraderItem NewWeapon;

    DKGRI = DKGameReplicationInfo(MyKFGRI);
    if (DKGRI == None)
    {
        `log("ZR Artificer ERROR: GRI is not DKGameReplicationInfo! Reforged weapons will not be registered.");
        return;
    }

    // Mark where Reforged weapons begin in AllowedWeaponsList
    DKGRI.ReforgedStartIndex = DKGRI.AllowedWeaponsList.Length;
    RegisteredCount = 0;

    // SaleItems ItemID continues from current count
    IDCount = TraderItems.SaleItems.Length;

    for (i = 0; i < default.ReforgedWeaponDefPaths.Length; ++i)
    {
        WD = class<KFWeaponDefinition>(DynamicLoadObject(default.ReforgedWeaponDefPaths[i], class'Class', True));
        if (WD != None)
        {
            // 1. AddWeaponInTrader handles BOTH:
            //    - AllowedWeaponsList (for IsItemAllowed bitmask gating)
            //    - WeaponUpgradeSlotsList (for trader upgrade tab compatibility)
            AddWeaponInTrader(WD);

            // 2. TraderItems.SaleItems — for trader UI to display the item
            NewWeapon.WeaponDef = WD;
            NewWeapon.ItemID = IDCount;
            TraderItems.SaleItems.AddItem(NewWeapon);

            // 3. KFWeaponDefPath — for client replication of trader items
            KFWeaponDefPath.AddItem(PathName(WD));

            ++IDCount;
            ++RegisteredCount;
        }
        else
        {
            `log("ZR Artificer WARNING: Failed to load Reforged WeapDef:" @ default.ReforgedWeaponDefPaths[i]);
        }
    }

    `log("ZR Artificer: Registered" @ RegisteredCount @ "Reforged weapons (start index:" @ DKGRI.ReforgedStartIndex $ ")");

    // Refresh trader items info with the newly added Reforged weapons
    TraderItems.SetItemsInfo(TraderItems.SaleItems);
    MyKFGRI.TraderItems = TraderItems;
}

// ===================================================================
// HOLLOW WEAPON REGISTRATION (Hollow Perk)
// Adds 128 Hollow weapon variants to trader. Uses AddWeaponInTrader()
// for AllowedWeaponsList + WeaponUpgradeSlotsList, plus manual
// SaleItems + KFWeaponDefPath additions for trader UI replication.
// Per-player visibility is handled client-side by DKGFxTraderContainer_Store
// checking each player's Hollow Helper unlock cache.
// ===================================================================

function RegisterHollowWeapons()
{
    local int i, RegisteredCount, IDCount;
    local class<KFWeaponDefinition> WD;
    local STraderItem NewWeapon;

    RegisteredCount = 0;
    IDCount = TraderItems.SaleItems.Length;

    for (i = 0; i < default.HollowWeaponDefPaths.Length; ++i)
    {
        WD = class<KFWeaponDefinition>(DynamicLoadObject(default.HollowWeaponDefPaths[i], class'Class', True));
        if (WD != None)
        {
            // 1. AddWeaponInTrader handles:
            //    - AllowedWeaponsList (for IsItemAllowed)
            //    - WeaponUpgradeSlotsList (for trader upgrade tab)
            AddWeaponInTrader(WD);

            // 2. TraderItems.SaleItems — for trader UI display
            NewWeapon.WeaponDef = WD;
            NewWeapon.ItemID = IDCount;
            TraderItems.SaleItems.AddItem(NewWeapon);

            // 3. KFWeaponDefPath — for client replication
            KFWeaponDefPath.AddItem(PathName(WD));

            ++IDCount;
            ++RegisteredCount;
        }
        else
        {
            `log("ZR Hollow WARNING: Failed to load Hollow WeapDef:" @ default.HollowWeaponDefPaths[i]);
        }
    }

    `log("ZR Hollow: Registered" @ RegisteredCount @ "Hollow weapons in trader");

    // Refresh trader items info
    TraderItems.SetItemsInfo(TraderItems.SaleItems);
    MyKFGRI.TraderItems = TraderItems;
}

// ===================================================================
// OMEN PERK — ZEDBUFF REGISTRATION
// Injects 5 Omen doom ZedBuff classes into ConfigData.ZedBuffObjects
// so they replicate to clients. MinWave=9999 prevents random activation;
// only the Omen helper triggers them manually.
// ===================================================================

function InitializeZedBuff()
{
    Super.InitializeZedBuff();
    RegisterOmenZedBuffs();
}

function RegisterOmenZedBuffs()
{
    local array<string> OmenPaths;
    local int i, NewIndex;
    local class<WMZedBuff> BuffClass;
    local S_Zed_Buff ZB;

    OmenPaths.AddItem("ZedternalRBPerkpackage.DKZedBuff_Omen_Health");
    OmenPaths.AddItem("ZedternalRBPerkpackage.DKZedBuff_Omen_Damage");
    OmenPaths.AddItem("ZedternalRBPerkpackage.DKZedBuff_Omen_Speed");
    OmenPaths.AddItem("ZedternalRBPerkpackage.DKZedBuff_Omen_SpawnRate");
    OmenPaths.AddItem("ZedternalRBPerkpackage.DKZedBuff_Omen_HardAttack");

    for (i = 0; i < OmenPaths.Length; ++i)
    {
        BuffClass = class<WMZedBuff>(DynamicLoadObject(OmenPaths[i], class'Class', True));
        if (BuffClass == None)
        {
            `log("[DK_OMEN] ERROR: Failed to load ZedBuff:" @ OmenPaths[i]);
            continue;
        }

        NewIndex = ConfigData.ZedBuffObjects.Length;
        ConfigData.ZedBuffObjects.AddItem(BuffClass);

        ZB.ID = NewIndex;
        ZB.MinWave = 9999;
        ZB.MaxWave = 9999;
        ZB.bActivated = False;
        ZedBuffSettings.AddItem(ZB);

        `log("[DK_OMEN] Registered ZedBuff:" @ OmenPaths[i] @ "at index" @ NewIndex);
    }

    if (ConfigData.ZedBuffObjects.Length > 256)
        `log("[DK_OMEN] WARNING: ZedBuff count" @ ConfigData.ZedBuffObjects.Length @ "exceeds 256!");
}

// ===================================================================
// WAVE SYSTEM - WEALTHY DOSH HOOK
// ===================================================================

/** Override StartWave to grant Wealthy bonus dosh and stop perk check timer */
function StartWave()
{
    local DKGameReplicationInfo DKGRI;
    local byte RolledEvent;

    // Stop trader-time perk unlock checking
    ClearTimer(NameOf(CheckPerkUnlocks));

    // Grant Wealthy bonus BEFORE wave starts
    if (bRoguelikeEnabled)
    {
        GrantWealthyWaveStartDosh();
    }

    // === EVENT WAVE ROLL ===
    DKGRI = DKGameReplicationInfo(MyKFGRI);
    if (DKGRI != None)
    {
        if (ForcedEventWaveID > 0)
        {
            RolledEvent = ForcedEventWaveID;
            ForcedEventWaveID = 0;
            `log("[DK_EVENTWAVE] Forced event wave:" @ class'DKConfig_EventWave'.static.GetEventName(RolledEvent) @ "(ID" @ RolledEvent $ ")");
        }
        else
        {
            RolledEvent = class'DKConfig_EventWave'.static.RollEventWave(WaveNum, EventWavesTriggered, GetLivingPlayerCount());
        }

        if (RolledEvent > 0)
        {
            DKGRI.ActiveEventWaveID = RolledEvent;
            DKGRI.EventWaveStartTime = WorldInfo.TimeSeconds;
            DKGRI.bForceNetUpdate = True;
            EventWavesTriggered++;
            `log("[DK_EVENTWAVE] Wave" @ WaveNum @ "- Event:" @ class'DKConfig_EventWave'.static.GetEventName(RolledEvent));

            // Play announcement sound to all players
            BroadcastEventWaveSound(RolledEvent);

            // Spawn or reuse the manager for server-side events
            if (class'DKConfig_EventWave'.static.NeedsManager(RolledEvent))
            {
                if (EventWaveManager == None)
                    EventWaveManager = Spawn(class'DKEventWaveManager', self);
                if (EventWaveManager != None)
                    EventWaveManager.StartEvent(RolledEvent);
            }
        }
        else
        {
            DKGRI.ActiveEventWaveID = 0;
        }
    }

    // Call parent to start the actual wave (builds GroupList in spawn manager)
    Super.StartWave();

    // Process DK grouped zed injection (after GroupList is built)
    ProcessGroupedZedInject();

    // Start collectible monitoring on first wave
    if (WaveNum == 1 && !bCollectiblesAwarded && class'DKConfig_Collectibles'.default.bEnabled)
        StartCollectibleMonitor();
}

// ===================================================================
// GROUPED ZED INJECTION
// Processes DKConfig_ZedInjectGroup entries. For each GroupID that matches
// the current wave, picks exactly ONE entry randomly (weighted) and injects
// it into the spawn manager's GroupList.
// ===================================================================

function ProcessGroupedZedInject()
{
    local WMAISpawnManager SM;
    local int i, j, k, GrSize;
    local string CurrentGroupID;
    local array<string> ProcessedGroups;
    local array<int> GroupCandidates;
    local float TotalWeight, Roll, Cumulative;
    local int PickedIdx;
    local class<KFPawn_Monster> ZedClass;
    local bool bAlreadyProcessed;

    if (class'DKConfig_ZedInjectGroup'.default.DK_ZedInjectGroup.Length == 0)
        return;

    SM = WMAISpawnManager(SpawnManager);
    if (SM == None)
        return;

    // Iterate all entries, group by GroupID
    for (i = 0; i < class'DKConfig_ZedInjectGroup'.default.DK_ZedInjectGroup.Length; ++i)
    {
        CurrentGroupID = class'DKConfig_ZedInjectGroup'.default.DK_ZedInjectGroup[i].GroupID;

        // Skip if we already processed this group
        bAlreadyProcessed = False;
        for (j = 0; j < ProcessedGroups.Length; ++j)
        {
            if (ProcessedGroups[j] == CurrentGroupID)
            {
                bAlreadyProcessed = True;
                break;
            }
        }
        if (bAlreadyProcessed)
            continue;

        ProcessedGroups.AddItem(CurrentGroupID);

        // Collect all entries in this group that match the current wave and difficulty
        GroupCandidates.Length = 0;
        TotalWeight = 0.0f;

        for (j = 0; j < class'DKConfig_ZedInjectGroup'.default.DK_ZedInjectGroup.Length; ++j)
        {
            if (class'DKConfig_ZedInjectGroup'.default.DK_ZedInjectGroup[j].GroupID != CurrentGroupID)
                continue;

            // Check wave match
            if (class'DKConfig_ZedInjectGroup'.default.DK_ZedInjectGroup[j].bRepeat)
            {
                if (WaveNum % class'DKConfig_ZedInjectGroup'.default.DK_ZedInjectGroup[j].Wave != 0)
                    continue;
            }
            else
            {
                if (WaveNum != class'DKConfig_ZedInjectGroup'.default.DK_ZedInjectGroup[j].Wave)
                    continue;
            }

            // Check difficulty
            if (GameDifficultyZedternal < class'DKConfig_ZedInjectGroup'.default.DK_ZedInjectGroup[j].MinDiff
                || GameDifficultyZedternal > class'DKConfig_ZedInjectGroup'.default.DK_ZedInjectGroup[j].MaxDiff)
                continue;

            GroupCandidates.AddItem(j);
            TotalWeight += class'DKConfig_ZedInjectGroup'.default.DK_ZedInjectGroup[j].Weight;
        }

        if (GroupCandidates.Length == 0 || TotalWeight <= 0.0f)
            continue;

        // Pick one entry from the group using weighted random
        Roll = FRand() * TotalWeight;
        Cumulative = 0.0f;
        PickedIdx = GroupCandidates[0];

        for (j = 0; j < GroupCandidates.Length; ++j)
        {
            Cumulative += class'DKConfig_ZedInjectGroup'.default.DK_ZedInjectGroup[GroupCandidates[j]].Weight;
            if (Roll <= Cumulative)
            {
                PickedIdx = GroupCandidates[j];
                break;
            }
        }

        // Resolve the zed class
        ZedClass = class<KFPawn_Monster>(DynamicLoadObject(
            class'DKConfig_ZedInjectGroup'.default.DK_ZedInjectGroup[PickedIdx].ZedPath, class'Class'));

        if (ZedClass == None)
        {
            `log("[DK_ZEDINJECT] ERROR: Failed to load class" @ class'DKConfig_ZedInjectGroup'.default.DK_ZedInjectGroup[PickedIdx].ZedPath);
            continue;
        }

        // Determine position in GroupList
        if (class'DKConfig_ZedInjectGroup'.default.DK_ZedInjectGroup[PickedIdx].Position ~= "BEG")
        {
            k = 0;
            SM.GroupList.Insert(k, 1);
        }
        else if (class'DKConfig_ZedInjectGroup'.default.DK_ZedInjectGroup[PickedIdx].Position ~= "MID")
        {
            k = SM.GroupList.Length / 2;
            SM.GroupList.Insert(k, 1);
        }
        else
        {
            k = SM.GroupList.Length;
            SM.GroupList.Add(1);
        }

        // Add zeds to the group
        for (GrSize = 0; GrSize < class'DKConfig_ZedInjectGroup'.default.DK_ZedInjectGroup[PickedIdx].Count; ++GrSize)
        {
            SM.GroupList[k].ZedClasses.AddItem(ZedClass);
        }

        SM.WaveTotalAI += class'DKConfig_ZedInjectGroup'.default.DK_ZedInjectGroup[PickedIdx].Count;
        MyKFGRI.AIRemaining += class'DKConfig_ZedInjectGroup'.default.DK_ZedInjectGroup[PickedIdx].Count;
        MyKFGRI.WaveTotalAICount += class'DKConfig_ZedInjectGroup'.default.DK_ZedInjectGroup[PickedIdx].Count;

        `log("[DK_ZEDINJECT] Group '" $ CurrentGroupID $ "' wave" @ WaveNum
            $ ": Picked" @ class'DKConfig_ZedInjectGroup'.default.DK_ZedInjectGroup[PickedIdx].ZedPath
            @ "x" $ class'DKConfig_ZedInjectGroup'.default.DK_ZedInjectGroup[PickedIdx].Count
            @ "at" @ class'DKConfig_ZedInjectGroup'.default.DK_ZedInjectGroup[PickedIdx].Position);
    }
}

// ===================================================================
// COLLECTIBLE REWARD SYSTEM
// Monitors KFMapInfo collectibles and awards dosh when all are found.
// ===================================================================

function StartCollectibleMonitor()
{
    local KFMapInfo KFMI;

    KFMI = KFMapInfo(WorldInfo.GetMapInfo());
    if (KFMI == None || KFMI.CollectiblesToFind <= 0)
    {
        `log("[DK_COLLECTIBLES] Map has no collectibles, skipping monitor");
        return;
    }

    `log("[DK_COLLECTIBLES] Started monitor: " $ KFMI.CollectiblesToFind $ " collectibles on this map");
    SetTimer(5.0f, true, NameOf(CheckCollectibles));
}

function CheckCollectibles()
{
    local KFMapInfo KFMI;

    if (bCollectiblesAwarded)
    {
        ClearTimer(NameOf(CheckCollectibles));
        return;
    }

    KFMI = KFMapInfo(WorldInfo.GetMapInfo());
    if (KFMI == None)
        return;

    if (KFMI.CollectiblesFound >= KFMI.CollectiblesToFind)
    {
        bCollectiblesAwarded = True;
        ClearTimer(NameOf(CheckCollectibles));
        AwardCollectibleReward(KFMI.CollectiblesToFind);
    }
}

function AwardCollectibleReward(int TotalCollectibles)
{
    local KFPlayerController KFPC;
    local KFPlayerReplicationInfo KFPRI;
    local int DoshAmount;

    DoshAmount = class'DKConfig_Collectibles'.default.DoshReward;
    if (DoshAmount <= 0)
        return;

    `log("[DK_COLLECTIBLES] All " $ TotalCollectibles $ " collectibles found! Awarding " $ DoshAmount $ " dosh to all players");

    foreach WorldInfo.AllControllers(class'KFPlayerController', KFPC)
    {
        KFPRI = KFPlayerReplicationInfo(KFPC.PlayerReplicationInfo);
        if (KFPRI != None && !KFPRI.bOnlySpectator)
        {
            KFPRI.AddDosh(DoshAmount);
            `log("[DK_COLLECTIBLES] Awarded " $ DoshAmount $ " dosh to " $ KFPRI.PlayerName);
        }
    }

    // Broadcast to all players
    Broadcast(self, "All " $ TotalCollectibles $ " collectibles found! +" $ DoshAmount $ " Dosh", 'Say');
}

/** Grant dosh to all players with Wealthy upgrade at wave start */
function GrantWealthyWaveStartDosh()
{
    local PlayerController PC;
    local DKPlayerController DKPC;
    local DKPlayerReplicationInfo DKPRI;
    local int DoshBonus;
    
    `log("[DK_ROGUELIKE] Checking Wealthy bonuses for wave " $ (WaveNum + 1));
    
    foreach WorldInfo.AllControllers(class'PlayerController', PC)
    {
        DKPC = DKPlayerController(PC);
        if (DKPC != None)
        {
            DKPRI = DKPlayerReplicationInfo(DKPC.PlayerReplicationInfo);
            if (DKPRI != None)
            {
                DoshBonus = DKPRI.GetRoguelikeWaveStartDosh();
                
                if (DoshBonus > 0)
                {
                    // Add dosh to player
                    DKPRI.AddDosh(DoshBonus, true);
                    
                    `log("[DK_ROGUELIKE_WEALTHY] " $ DKPRI.PlayerName $ " received +" $ DoshBonus $ " wave start dosh");
                    
                    // Optional: Show message to player
                    if (DKPC.MyGFxHUD != None)
                    {
                        DKPC.MyGFxHUD.ShowNonCriticalMessage("Wealthy: +" $ DoshBonus $ " Dosh");
                    }
                }
            }
        }
    }
}

// ===================================================================
// EVENT WAVE CLEAR (server-authoritative)
// Runs the manager's EndEvent cleanup for manager-backed events, then resets
// the replicated state so client-only effects (Paranoia sounds, overlays)
// stop. Safe to call repeatedly; no-op when nothing is active.
// ===================================================================

function ClearActiveEventWave(string Reason)
{
    local DKGameReplicationInfo DKGRI;

    DKGRI = DKGameReplicationInfo(MyKFGRI);
    if (DKGRI != None && DKGRI.ActiveEventWaveID > 0)
    {
        `log("[DK_EVENTWAVE] Clearing event wave" @ class'DKConfig_EventWave'.static.GetEventName(DKGRI.ActiveEventWaveID) @ "(" $ Reason $ ")");
        if (EventWaveManager != None && EventWaveManager.ActiveEventID > 0)
            EventWaveManager.EndEvent();
        DKGRI.ActiveEventWaveID = 0;
        DKGRI.EventWaveTargetPRI = None;
        DKGRI.EventSwapInterval = 0;
        DKGRI.bForceNetUpdate = True;
    }
}

// ===================================================================
// ROGUELIKE UPGRADE SYSTEM - TRADER INTEGRATION
// ===================================================================

function OpenTrader()
{
    local KFTraderTrigger TT;
    local int TraderCount;
    local DKGameReplicationInfo DKGRI;

    // Clear event wave overlay when trader opens (wave ended)
    DKGRI = DKGameReplicationInfo(MyKFGRI);
    if (DKGRI != None && DKGRI.ActiveEventWaveID > 0)
    {
        `log("[DK_EVENTWAVE] Clearing event wave" @ class'DKConfig_EventWave'.static.GetEventName(DKGRI.ActiveEventWaveID) @ "on trader open");
        if (EventWaveManager != None && EventWaveManager.ActiveEventID > 0)
            EventWaveManager.EndEvent();
        DKGRI.ActiveEventWaveID = 0;
        DKGRI.EventWaveTargetPRI = None;
        DKGRI.bForceNetUpdate = True;
    }

    // DEBUG: Check trader state BEFORE opening
    TraderCount = 0;
    foreach DynamicActors(class'KFTraderTrigger', TT)
    {
        ++TraderCount;
        `log("[DK_DEBUG] TraderTrigger:" @ TT @ "bEnabled=" $ TT.bEnabled @ "bOpened=" $ TT.bOpened @ "Location=" $ TT.Location);
    }
    `log("[DK_DEBUG] OpenTrader PRE - TraderCount=" $ TraderCount @ "NextTrader=" $ MyKFGRI.NextTrader @ "OpenedTrader=" $ MyKFGRI.OpenedTrader @ "bTraderIsOpen=" $ MyKFGRI.bTraderIsOpen @ "WaveNum=" $ WaveNum);

    // Always call Super.OpenTrader() FIRST to properly initialize game state
    Super.OpenTrader();
    
    `log("[DK_DEBUG] OpenTrader POST - NextTrader=" $ MyKFGRI.NextTrader @ "OpenedTrader=" $ MyKFGRI.OpenedTrader @ "bTraderIsOpen=" $ MyKFGRI.bTraderIsOpen);

    // DEBUG: Check bOpened on all triggers AFTER Super.OpenTrader()
    foreach DynamicActors(class'KFTraderTrigger', TT)
    {
        `log("[DK_DEBUG] POST TraderTrigger:" @ TT @ "bOpened=" $ TT.bOpened);
    }

    // Only schedule trader refresh on listen servers when no local player exists yet
    // (e.g. ?wave=N startup). On dedicated servers GetALocalPlayerController() is
    // always None, so we must NOT run this path — it was causing trader pod rotation.
    // NOTE: IsConsoleDedicatedServer() only returns True on Xbox/PS4. Use NetMode check.
    if (WorldInfo.NetMode != NM_DedicatedServer && GetALocalPlayerController() == None)
    {
        `log("[DK_DEBUG] OpenTrader: Listen server - no local player yet, scheduling trader refresh");
        TraderRefreshRetries = 0;
        SetTimer(0.5f, false, NameOf(CheckAndRefreshTrader));
    }

    `log("[DK_ROGUELIKE] OpenTrader called (Wave " $ WaveNum $ ")");
    
    // After trader is properly opened, check if we should show upgrade selection
    if (bRoguelikeEnabled && RoguelikeManager != None 
        && RoguelikeManager.ShouldTriggerUpgradeSelection(WaveNum))
    {
        `log("[DK_ROGUELIKE] Wave " $ WaveNum $ " - showing upgrade selection overlay");
        RoguelikeManager.StartUpgradeSelection();
    }

    // Flush queued late-joiner catch-up selections. Runs after the normal
    // trigger above; ProcessCatchUpQueue no-ops while a group selection is
    // active and is re-driven from EndUpgradeSelection when that finishes.
    if (bRoguelikeEnabled && RoguelikeManager != None)
    {
        RoguelikeManager.ProcessCatchUpQueue();
    }

    // Start periodic perk unlock checking during trader time
    if (PerkConfig != None)
    {
        SetTimer(0.5f, true, NameOf(CheckPerkUnlocks));
    }
}

// ===================================================================
// TRADER REFRESH FIX
// When using ?wave=N on a LISTEN server, the trader opens before the
// local player controller is fully registered. This retries until the
// player exists, then re-opens the SAME trader to refresh client visuals.
// ===================================================================

function CheckAndRefreshTrader()
{
    local KFPlayerController KFPC;
    local KFTraderTrigger OpenedTrigger;

    KFPC = KFPlayerController(GetALocalPlayerController());

    // If no local player with a pawn yet, retry (up to 10 times = 5 seconds)
    if (KFPC == None || KFPC.Pawn == None)
    {
        ++TraderRefreshRetries;
        if (TraderRefreshRetries < 10)
        {
            `log("[DK_DEBUG] CheckAndRefreshTrader: No local player with pawn yet, retry" @ TraderRefreshRetries);
            SetTimer(0.5f, false, NameOf(CheckAndRefreshTrader));
        }
        else
        {
            `log("[DK_DEBUG] CheckAndRefreshTrader: Gave up after" @ TraderRefreshRetries @ "retries");
        }
        return;
    }

    // Player exists — refresh the trader trigger
    OpenedTrigger = MyKFGRI.OpenedTrader;
    if (OpenedTrigger == None || !MyKFGRI.bTraderIsOpen)
    {
        `log("[DK_DEBUG] CheckAndRefreshTrader: Trader no longer open, skipping");
        return;
    }

    `log("[DK_DEBUG] CheckAndRefreshTrader: Player found (" $ KFPC $ "), refreshing SAME trader");

    // Close and reopen the SAME trader — do NOT call SetupNextTrader()
    // which would rotate to a different pod
    MyKFGRI.CloseTrader();
    MyKFGRI.NextTrader = OpenedTrigger;
    MyKFGRI.OpenTrader(TimeBetweenWaves);
    NotifyTraderOpened();
}

// ===================================================================
// SPECIAL WAVE SYSTEM
// ===================================================================

function SetupSpecialWave()
{
    local int i;
    local string ForcedBossPath;
    local float ForcedProbability;
    local class<WMSpecialWave> ForcedBossClass;
    
    // Check for forced boss waves from Config_BossWave
    if (class'Config_BossWave'.static.IsBossWaveForced(WaveNum, ForcedBossPath, ForcedProbability))
    {
        if (FRand() <= ForcedProbability)
        {
            ForcedBossClass = class<WMSpecialWave>(DynamicLoadObject(ForcedBossPath, class'Class', true));
            if (ForcedBossClass != None)
            {
                `log("DK: Forcing boss wave on wave" @ WaveNum @ ":" @ ForcedBossPath);
                
                // Find the ID in the special wave list
                for (i = 0; i < SpecialWaveList.Length; ++i)
                {
                    if (SpecialWaveList[i] == ForcedBossClass)
                    {
                        WMGameReplicationInfo(MyKFGRI).SpecialWaveID[0] = i;
                        LastSpecialWaveID_First = i;
                        WMGameReplicationInfo(MyKFGRI).SpecialWaveID[1] = INDEX_NONE;
                        LastSpecialWaveID_Second = INDEX_NONE;
                        
                        if (WorldInfo.NetMode != NM_DedicatedServer)
                            WMGameReplicationInfo(MyKFGRI).TriggerSpecialWaveMessage();
                        
                        SetTimer(5.0f, False, NameOf(SetSpecialWaveActor));
                        return;
                    }
                }
                
                `log("DK Warning: Forced boss class" @ ForcedBossPath @ "not found in SpecialWaveList!");
            }
            else
            {
                `log("DK Error: Failed to load forced boss class:" @ ForcedBossPath);
            }
        }
    }
    
    // No forced wave, use normal special wave logic
    Super.SetupSpecialWave();
}

// ===================================================================
// EXTENDED LIMITS — RepGameInfoHighPriority Override
// Raises NumberOf caps from parent (512/MAXWEAPONUPGRADES) to 1024/8192
// ===================================================================

function RepGameInfoHighPriority()
{
    local WMGameReplicationInfo WMGRI;
    local DKGameReplicationInfo DKGRI;
    local int SavedAllowedWeapons, SavedTraderWeapons, SavedUpgradeSlots;

    // Save original lengths BEFORE super truncates them to old caps
    WMGRI = WMGameReplicationInfo(MyKFGRI);
    if (WMGRI != None)
    {
        SavedAllowedWeapons = WMGRI.AllowedWeaponsList.Length;
        SavedUpgradeSlots = WMGRI.WeaponUpgradeSlotsList.Length;
    }
    SavedTraderWeapons = TraderItems.SaleItems.Length;

    // Parent runs — sets NumberOf* and truncates arrays to old caps
    super.RepGameInfoHighPriority();

    if (WMGRI == None)
        return;

    // Override with our higher caps using ORIGINAL pre-truncation lengths
    WMGRI.NumberOfAllowedWeapons = Min(DK_MAX_TRADER_WEAPONS, SavedAllowedWeapons);
    WMGRI.NumberOfTraderWeapons = Min(DK_MAX_TRADER_WEAPONS, SavedTraderWeapons);
    WMGRI.NumberOfWeaponUpgradeSlots = Min(DK_MAX_WEAPON_UPGRADES, SavedUpgradeSlots);

    // Weapon-upgrade TYPE registry is capped at 256 (ZR's WeaponUpgradesRepArray[256]
    // plus the byte slot-index used in the OPTION 2 recording). Past index 255, types
    // are silently dropped, which undercounts a weapon's upgrades. Make that loud so a
    // stacked-modpack registry that overflows the ceiling is never silent.
    if (ConfigData != None && ConfigData.ValidWeaponUpgrades.Length > 256)
        `log("[DK_UPGSLOTS] WARNING: ValidWeaponUpgrades.Length=" $ ConfigData.ValidWeaponUpgrades.Length $ " exceeds the 256 weapon-upgrade-TYPE replication ceiling -- types past index 255 are NOT offered. Trim stacked weapon-upgrade packs, or the type rep needs widening.");

    // Restore arrays that super truncated
    WMGRI.AllowedWeaponsList.Length = WMGRI.NumberOfAllowedWeapons;
    WMGRI.WeaponUpgradeSlotsList.Length = WMGRI.NumberOfWeaponUpgradeSlots;

    DKGRI = DKGameReplicationInfo(WMGRI);
    if (DKGRI != None)
    {
        `log("DK Extended Limits: AllowedWeapons=" $ WMGRI.NumberOfAllowedWeapons
            @ "TraderWeapons=" $ WMGRI.NumberOfTraderWeapons
            @ "WeaponUpgradeSlots=" $ WMGRI.NumberOfWeaponUpgradeSlots);
    }
}

// ===================================================================
// EXTENDED LIMITS — RepGameInfoLowPriority Override
// Populates C/D replication arrays for trader weapons 512-1023
// ===================================================================

function RepGameInfoLowPriority()
{
    local DKGameReplicationInfo DKGRI;
    local int i, shifted;

    // Let parent populate A/B for everything
    super.RepGameInfoLowPriority();

    DKGRI = DKGameReplicationInfo(MyKFGRI);
    if (DKGRI == None)
        return;

    // Allowed Weapons C (indices 512-767)
    for (i = 512; i < Min(768, DKGRI.AllowedWeaponsList.Length); ++i)
    {
        shifted = i - 512;
        DKGRI.AllowedWeaponsRepArray_C[shifted].WeaponPathName = DKGRI.AllowedWeaponsList[i].KFWeaponPath;
        DKGRI.AllowedWeaponsRepArray_C[shifted].BuyPrice = DKGRI.AllowedWeaponsList[i].BuyPrice;
        DKGRI.AllowedWeaponsRepArray_C[shifted].bValid = True;
    }

    // Allowed Weapons D (indices 768-1023)
    for (i = 768; i < Min(1024, DKGRI.AllowedWeaponsList.Length); ++i)
    {
        shifted = i - 768;
        DKGRI.AllowedWeaponsRepArray_D[shifted].WeaponPathName = DKGRI.AllowedWeaponsList[i].KFWeaponPath;
        DKGRI.AllowedWeaponsRepArray_D[shifted].BuyPrice = DKGRI.AllowedWeaponsList[i].BuyPrice;
        DKGRI.AllowedWeaponsRepArray_D[shifted].bValid = True;
    }

    // Trader Items C (indices 512-767)
    for (i = 512; i < Min(768, KFWeaponDefPath.Length); ++i)
    {
        shifted = i - 512;
        DKGRI.KFWeaponDefPath_C[shifted] = KFWeaponDefPath[i];
    }

    // Trader Items D (indices 768-1023)
    for (i = 768; i < Min(1024, KFWeaponDefPath.Length); ++i)
    {
        shifted = i - 768;
        DKGRI.KFWeaponDefPath_D[shifted] = KFWeaponDefPath[i];
    }

    // DK OPTION2: copy slot composition recordings into the paged rep
    // arrays and compute the arrival checksum. Idempotent.
    DKGRI.FinalizeSlotData();

    `log("DK Extended Limits: Populated rep arrays — AllowedWeapons:" @ DKGRI.AllowedWeaponsList.Length
        @ "KFWeaponDefPath:" @ KFWeaponDefPath.Length);
}

// ===================================================================
// EXTENDED LIMITS — AddWeaponInTrader Override
// Replaces parent's MAXWEAPONUPGRADES guard (4096) with 16384
// OPTION 2: Records the slot composition (per-pick upgrade index and
// per-weapon slot count) into DKGameReplicationInfo's recording buffers
// so clients can rebuild the slot list from data instead of replaying
// the seeded RNG (which desynced on any DynamicLoadObject hiccup).
// Weapons beyond DK_MAX_TRADER_WEAPONS (1024) get ZERO slots: the
// client's AllowedWeaponsList is truncated to 1024, so slots for later
// weapons would be unreachable and would break index alignment.
// ===================================================================

// Returns the per-weapon upgrade slot bound. EffectiveUpgradesPerWeapon
// is computed in AllWeapons mode (ComputeUpgradeSlotBudget) when the
// config value would overflow the global slot cap; 0 means "no clamp
// computed", fall back to the raw config value. Min(255) keeps the
// per-weapon count byte-safe for Option-2 recording.
function int GetEffectiveUpgradesPerWeapon()
{
    if (EffectiveUpgradesPerWeapon > 0)
        return EffectiveUpgradesPerWeapon;

    return Min(255, class'ZedternalReborn.Config_WeaponUpgradeOptions'.default.WeaponUpgrade_NumberUpgradePerWeapon);
}

function AddWeaponInTrader(const class<KFWeaponDefinition> KFWD)
{
    local int i, BuyPrice, Choice, SlotsBefore;
    local bool bIsSidearm;
    local class<KFWeapon> KFW;
    local array< class<WMUpgrade_Weapon> > AllowedUpgrades, StaticUpgrades;
    local array<int> AllowedUpgrades_PU, StaticUpgrades_PU;
    local array<float> AllowedUpgrades_PM, StaticUpgrades_PM;
    local array<int> AllowedUpgrades_ML, StaticUpgrades_ML;
    local array<byte> AllowedUpgrades_Idx, StaticUpgrades_Idx;
    local array< class<WMUpgrade_Weapon> > HollowUpgrades;
    local array<int> HollowUpgrades_PU, HollowUpgrades_ML;
    local array<float> HollowUpgrades_PM;
    local array<byte> HollowUpgrades_Idx;
    local WMGameReplicationInfo WMGRI;
    local DKGameReplicationInfo DKGRI;

    WMGRI = WMGameReplicationInfo(MyKFGRI);
    DKGRI = DKGameReplicationInfo(MyKFGRI);
    KFW = class<KFWeapon>(DynamicLoadObject(KFWD.default.WeaponClassPath, class'Class'));
    if (WMGRI != None && KFW != None)
    {
        bIsSidearm = False;
        for (i = 0; i < WMGRI.SidearmsList.Length; ++i)
        {
            if (WMGRI.SidearmsList[i].Sidearm.default.WeaponClassPath ~= PathName(KFW))
            {
                bIsSidearm = True;
                BuyPrice = WMGRI.SidearmsList[i].BuyPrice;
                break;
            }
            else if (KFW.default.DualClass != None && WMGRI.SidearmsList[i].Sidearm.default.WeaponClassPath ~= PathName(KFW.default.DualClass))
            {
                bIsSidearm = True;
                BuyPrice = WMGRI.SidearmsList[i].BuyPrice / 2;
                break;
            }
        }

        if (!bIsSidearm)
            BuyPrice = KFWD.default.BuyPrice;

        WMGRI.AddAllowedWeapon(KFWD, BuyPrice);
        SlotsBefore = WMGRI.WeaponUpgradeSlotsList.Length;

        // DK OPTION2: slots only for weapons the client can index (first
        // DK_MAX_TRADER_WEAPONS) and while under the global slot cap.
        // Either limit hit => this weapon gets 0 slots, recorded as count 0
        // below, so the client stays index-aligned.
        if (WMGRI.AllowedWeaponsList.Length <= DK_MAX_TRADER_WEAPONS
            && WMGRI.WeaponUpgradeSlotsList.Length < DK_MAX_WEAPON_UPGRADES)
        {
            for (i = 0; i < Min(256, ConfigData.ValidWeaponUpgrades.Length); ++i)
            {
                if (ConfigData.WeaponUpgObjects[i].static.IsUpgradeCompatible(KFW))
                {
                    // DK HOLLOW: route Hollow upgrades to a dedicated list so they
                    // never enter the random regular-slot draw (which hid them in
                    // the trader and made the visible slot count drift per restart).
                    if (class<DKWeaponUpg_HollowBase>(ConfigData.WeaponUpgObjects[i]) != None)
                    {
                        HollowUpgrades.AddItem(ConfigData.WeaponUpgObjects[i]);
                        HollowUpgrades_PU.AddItem(ConfigData.ValidWeaponUpgrades[i].PriceUnit);
                        HollowUpgrades_PM.AddItem(ConfigData.ValidWeaponUpgrades[i].PriceMultiplier);
                        HollowUpgrades_ML.AddItem(ConfigData.ValidWeaponUpgrades[i].MaxLevel);
                        HollowUpgrades_Idx.AddItem(byte(i));
                    }
                    else if (ConfigData.ValidWeaponUpgrades[i].bIsStatic)
                    {
                        StaticUpgrades.AddItem(ConfigData.WeaponUpgObjects[i]);
                        StaticUpgrades_PU.AddItem(ConfigData.ValidWeaponUpgrades[i].PriceUnit);
                        StaticUpgrades_PM.AddItem(ConfigData.ValidWeaponUpgrades[i].PriceMultiplier);
                        StaticUpgrades_ML.AddItem(ConfigData.ValidWeaponUpgrades[i].MaxLevel);
                        StaticUpgrades_Idx.AddItem(byte(i));
                    }
                    else
                    {
                        AllowedUpgrades.AddItem(ConfigData.WeaponUpgObjects[i]);
                        AllowedUpgrades_PU.AddItem(ConfigData.ValidWeaponUpgrades[i].PriceUnit);
                        AllowedUpgrades_PM.AddItem(ConfigData.ValidWeaponUpgrades[i].PriceMultiplier);
                        AllowedUpgrades_ML.AddItem(ConfigData.ValidWeaponUpgrades[i].MaxLevel);
                        AllowedUpgrades_Idx.AddItem(byte(i));
                    }
                }
            }

            // Per-weapon bound: budget-aware (clamped in AllWeapons mode)
            // and byte-safe (<=255) for count recording
            for (i = 0; i < GetEffectiveUpgradesPerWeapon(); ++i)
            {
                if (WMGRI.WeaponUpgradeSlotsList.Length >= DK_MAX_WEAPON_UPGRADES)
                {
                    `log("[DK_UPGSLOTS] WARNING: global slot cap (" $ DK_MAX_WEAPON_UPGRADES $ ") reached at weapon" @ WMGRI.AllowedWeaponsList.Length @ "(" $ KFWD $ ") -- remaining weapons get no upgrade slots");
                    break;
                }

                if (StaticUpgrades.Length > 0)
                {
                    WMGRI.AddWeaponUpgrade(KFW, StaticUpgrades[0], StaticUpgrades_PU[0], StaticUpgrades_PM[0], BuyPrice, StaticUpgrades_ML[0]);
                    if (DKGRI != None)
                        DKGRI.ServerSlotUpgIdxRecord.AddItem(StaticUpgrades_Idx[0]);
                    StaticUpgrades.Remove(0, 1);
                    StaticUpgrades_PU.Remove(0, 1);
                    StaticUpgrades_PM.Remove(0, 1);
                    StaticUpgrades_ML.Remove(0, 1);
                    StaticUpgrades_Idx.Remove(0, 1);
                }
                else if (AllowedUpgrades.Length > 0)
                {
                    Choice = class'ZedternalReborn.WMRandom'.static.SeedRandom(WeaponUpgRandSeed, WeaponUpgRandPosition, AllowedUpgrades.Length);
                    WMGRI.AddWeaponUpgrade(KFW, AllowedUpgrades[Choice], AllowedUpgrades_PU[Choice], AllowedUpgrades_PM[Choice], BuyPrice, AllowedUpgrades_ML[Choice]);
                    if (DKGRI != None)
                        DKGRI.ServerSlotUpgIdxRecord.AddItem(AllowedUpgrades_Idx[Choice]);
                    AllowedUpgrades.Remove(Choice, 1);
                    AllowedUpgrades_PU.Remove(Choice, 1);
                    AllowedUpgrades_PM.Remove(Choice, 1);
                    AllowedUpgrades_ML.Remove(Choice, 1);
                    AllowedUpgrades_Idx.Remove(Choice, 1);
                    ++WeaponUpgRandPosition;
                }
            }

            // DK HOLLOW: append every compatible Hollow upgrade as a DEDICATED
            // slot, outside the random regular-slot budget. Deterministic order,
            // always all of them -> Hollow row count is fixed (no drift) and the
            // regular slots are now pure non-Hollow. Still shared server-wide and
            // gated client-side in DKUI_UPGMenu by skill ownership.
            for (i = 0; i < HollowUpgrades.Length; ++i)
            {
                if (WMGRI.WeaponUpgradeSlotsList.Length >= DK_MAX_WEAPON_UPGRADES)
                {
                    `log("[DK_UPGSLOTS] WARNING: global slot cap (" $ DK_MAX_WEAPON_UPGRADES $ ") reached while adding Hollow slots at weapon" @ WMGRI.AllowedWeaponsList.Length @ "(" $ KFWD $ ")");
                    break;
                }

                WMGRI.AddWeaponUpgrade(KFW, HollowUpgrades[i], HollowUpgrades_PU[i], HollowUpgrades_PM[i], BuyPrice, HollowUpgrades_ML[i]);
                if (DKGRI != None)
                    DKGRI.ServerSlotUpgIdxRecord.AddItem(HollowUpgrades_Idx[i]);
            }
        }

        // DK OPTION2: record this weapon's slot count -- exactly ONE entry
        // per AllowedWeaponsList entry, including zero-slot weapons.
        if (DKGRI != None)
            DKGRI.ServerWeaponSlotCntRecord.AddItem(byte(WMGRI.WeaponUpgradeSlotsList.Length - SlotsBefore));
    }
}

// ===================================================================
// BALANCE REPLICATION HELPER
// ===================================================================

function SpawnBalanceRepHelper()
{
    local DKBalanceRepHelper H;

    H = Spawn(class'DKBalanceRepHelper');
    if (H != None)
    {
        class'DKWrapper_Equipment_SpareBatteries'.static.PopulateHelper(H);
        class'DKWrapper_Skill_AmmoPickup'.static.PopulateHelper(H);
        class'DKWrapper_Skill_DeadEye'.static.PopulateHelper(H);
        class'DKWrapper_Skill_Emergency'.static.PopulateHelper(H);
        class'DKWrapper_Skill_ExtraRounds'.static.PopulateHelper(H);
        class'DKWrapper_Skill_HighCapacityMags'.static.PopulateHelper(H);
        class'DKWrapper_Skill_HighCapacityMagsB'.static.PopulateHelper(H);
        class'DKWrapper_Skill_LiquidLoading'.static.PopulateHelper(H);
        class'DKWrapper_Skill_Pressure'.static.PopulateHelper(H);
        class'DKWrapper_Skill_Pyromaniac'.static.PopulateHelper(H);
        class'DKWrapper_Skill_ShockTrooper'.static.PopulateHelper(H);
        class'DKWrapper_Skill_ShootAndRun'.static.PopulateHelper(H);
        class'DKWrapper_Skill_Spartan'.static.PopulateHelper(H);
        class'DKWrapper_Skill_SpecialUnit'.static.PopulateHelper(H);
        class'DKWrapper_Skill_Speedloader'.static.PopulateHelper(H);
        class'DKWrapper_Skill_Stability'.static.PopulateHelper(H);
        class'DKWrapper_Skill_Steady'.static.PopulateHelper(H);
        class'DKWrapper_Skill_Tactician'.static.PopulateHelper(H);
        class'DKWrapper_Skill_WhirlwindOfLead'.static.PopulateHelper(H);
        // Equipment exchange wrappers - speed/mag/reload/rof/recoil run in
        // simulated passives, so their tuned values must reach clients here.
        class'DKWrapper_Equipment_Exchange_Bulwark'.static.PopulateHelper(H);
        class'DKWrapper_Equipment_Exchange_LightPacker'.static.PopulateHelper(H);
        class'DKWrapper_Equipment_Exchange_ExcessiveMag'.static.PopulateHelper(H);
        class'DKWrapper_Equipment_Exchange_ShortMag'.static.PopulateHelper(H);
        class'DKWrapper_Equipment_Exchange_TapFire'.static.PopulateHelper(H);
        class'DKWrapper_Equipment_Exchange_TriggerHappy'.static.PopulateHelper(H);
        // Weapon wrapper PopulateHelper calls REMOVED — wrapper .uc files
        // do not exist on disk; references caused unresolved class compile
        // errors. Weapon balance values now use ZR's hardcoded defaults.

        H.bForceNetUpdate = True;
        `log("[DKGameInfo] Balance helper spawned: 25 wrappers populated (weapon wrappers removed)");
    }
    else
    {
        `log("[DKGameInfo] ERROR: Failed to spawn DKBalanceRepHelper!");
    }
}

// ===================================================================
// RANK SYSTEM - XP TRACKING
// ===================================================================

// ===================================================================
// EVENT WAVE SOUND BROADCAST
// ===================================================================

function BroadcastEventWaveSound(byte EventID)
{
    local DKMutator Mut;
    local SoundCue EventSound;
    local name SoundID;
    local DKPlayerController DKPC;

    SoundID = class'DKConfig_EventWave'.static.GetEventSoundID(EventID);
    if (SoundID == '')
        return;

    Mut = class'DKSoundManager'.static.GetMutator(WorldInfo);
    if (Mut == None)
        return;

    EventSound = class'DKSoundManager'.static.GetSound(Mut, SoundID);
    if (EventSound == None)
    {
        `log("[DK_EVENTWAVE] Sound not found for" @ SoundID);
        return;
    }

    foreach WorldInfo.AllControllers(class'DKPlayerController', DKPC)
    {
        DKPC.ClientPlayBuffSound(EventSound);
    }
}

// ===================================================================
// DAMAGE MODIFICATION — Event Wave overrides
// ===================================================================

function ReduceDamage(out int Damage, Pawn Injured, Controller InstigatedBy, vector HitLocation, out vector Momentum, class<DamageType> DamageType, Actor DamageCauser, TraceHitInfo HitInfo)
{
    local int PreSuperDamage;
    local int AmogusDmg;
    local DKPlayerController PossessorDealerPC;
    local DKUpgrade_Perk_Possessor_Helper PossessorDmgHelper;

    PreSuperDamage = Damage;

    Super.ReduceDamage(Damage, Injured, InstigatedBy, HitLocation, Momentum, DamageType, DamageCauser, HitInfo);

    if (EventWaveManager != None && EventWaveManager.ActiveEventID > 0)
    {
        Damage = EventWaveManager.ModifyEventDamage(Damage, Injured, InstigatedBy);

        if (Damage == 0 && PreSuperDamage > 0)
        {
            AmogusDmg = EventWaveManager.GetAmogusFFDamage(PreSuperDamage, Injured, InstigatedBy);
            if (AmogusDmg > 0)
                Damage = AmogusDmg;
        }
    }

    // POSSESSOR: scale damage DEALT by a player-possessed zed. Its Versus-
    // balanced attacks are far too weak against Endless zeds, so multiply the
    // outgoing hit by the possessing player's rank / deluxe / per-form scalar
    // (read off the Possessor helper, which lives on the parked human). Big
    // forms - Scrake, Fleshpound, Patriarch - carry a much larger multiplier.
    PossessorDealerPC = DKPlayerController(InstigatedBy);
    if (Damage > 0 && PossessorDealerPC != None && PossessorDealerPC.PuppetZed != None
        && PossessorDealerPC.Pawn == PossessorDealerPC.PuppetZed
        && Injured != PossessorDealerPC.PuppetZed
        && PossessorDealerPC.PuppetSavedHuman != None)
    {
        PossessorDmgHelper = class'DKUpgrade_Perk_Possessor'.static.FindHelper(PossessorDealerPC.PuppetSavedHuman);
        if (PossessorDmgHelper != None && PossessorDmgHelper.bPossessing)
            Damage = int(float(Damage) * PossessorDmgHelper.GetPuppetDamageScalar(PossessorDmgHelper.CurrentFormIndex));
    }
}

function Killed(Controller Killer, Controller KilledPlayer, Pawn KilledPawn, class<DamageType> DT)
{
    local DKPlayerController DKPC;

    Super.Killed(Killer, KilledPlayer, KilledPawn, DT);

    // Award rank XP to the killer for zed kills
    if (KFPawn_Monster(KilledPawn) != None && Killer != None)
    {
        DKPC = DKPlayerController(Killer);
        if (DKPC != None)
            DKPC.AddRankXP(class'ZedternalRBPerkpackage.DKRank'.static.GetXPForZed(KilledPawn));

        // Notify Artificer perk of confirmed kill (authoritative kill tracking)
        class'DKUpgrade_Perk_Artificer'.static.NotifyZedKilled(Killer, KilledPawn, DT);

        // Notify Detonator perk of confirmed kill (authoritative kill tracking)
        class'DKUpgrade_Perk_Detonator'.static.NotifyZedKilled(Killer, KilledPawn, DT);

        // Notify Possessor perk of confirmed kill (capstone 20: kills while
        // possessed extend the possession timer)
        class'DKUpgrade_Perk_Possessor'.static.NotifyZedKilled(Killer, KilledPawn, DT);

        // Notify Event Wave Manager of zed kill (OITC ammo grant)
        if (EventWaveManager != None && EventWaveManager.ActiveEventID > 0)
        {
            EventWaveManager.NotifyZedKilledOITC(Killer);
            EventWaveManager.NotifyNemesisKilled(KilledPawn);
            EventWaveManager.NotifyXMenKill(Killer, KilledPawn);
        }
    }

    // Notify event wave manager of player death (VIP tracking)
    if (KFPawn_Human(KilledPawn) != None && KilledPlayer != None && EventWaveManager != None)
    {
        DKPC = DKPlayerController(KilledPlayer);
        if (DKPC != None)
            EventWaveManager.NotifyPlayerDied(DKPC);
    }
}

// ZedternalReborn's WMGameInfo_Endless.CheckForBrokenZeds() (15s repeating timer)
// force-kills any zed whose MyKFAIC is None. A player-possessed Puppet Master zed
// has a PlayerController instead of AI, so the stock check executes it within ~15s
// of possession via Died(None,...) - a death with no source. Skip player-driven
// zeds. *** REMOVE/REVISIT BEFORE SHIPPING *** (mirrored in DKGameInfo_Endless_AllWeapons).
function CheckForBrokenZeds()
{
    local KFPawn_Monster KFPM;

    foreach DynamicActors(class'KFGame.KFPawn_Monster', KFPM)
    {
        if (KFPM != None && !KFPM.IsInState('Dying'))
        {
            // A possessed zed (its player is driving it) must never be force-killed.
            if (PlayerController(KFPM.Controller) != None)
                continue;

            if (KFPM.Health <= 0)
            {
                `log("ZR Warning: Zed" @ KFPM.Name @ "has zero health but is not dead. Killing forcefully");
                KFPM.Died(None, None, KFPM.Location);
            }

            if (!bDisableZedAICheck && KFPM.MyKFAIC == None)
            {
                `log("ZR Warning: Zed" @ KFPM.Name @ "has no AI controller but is not dead. Killing forcefully");
                KFPM.Died(None, None, KFPM.Location);
            }
        }
    }
}

function WaveEnded(EWaveEndCondition WinCondition)
{
    local DKPlayerController DKPC;

    // If anyone is still possessing a puppet zed when the wave ends, drop them back
    // into their human body BEFORE trader/GRI bookkeeping runs - otherwise they are
    // stranded as a zed through trader and into the next wave. The puppet is alive
    // here (wave won), so this takes the clean manual-drop path.
    // *** REMOVE/REVISIT BEFORE SHIPPING *** (mirrored in DKGameInfo_Endless_AllWeapons).
    foreach WorldInfo.AllControllers(class'DKPlayerController', DKPC)
    {
        if (DKPC.PuppetZed != None)
            DKPC.ServerPuppetDrop();
    }

    Super.WaveEnded(WinCondition);

    // Event waves end with the combat wave. Clear here (authoritative) so
    // client-only effects (e.g. Paranoia phantom sounds) stop immediately and
    // never linger into later waves, independent of trader-open timing.
    ClearActiveEventWave("wave ended");

    // Award wave clear bonus and flush all accumulated XP
    foreach WorldInfo.AllControllers(class'DKPlayerController', DKPC)
    {
        if (WinCondition == WEC_WaveWon && DKPC.Pawn != None && DKPC.Pawn.IsAliveAndWell())
        {
            DKPC.AddRankXP(class'ZedternalRBPerkpackage.DKRank'.const.XP_WAVE_CLEAR);
        }
        DKPC.FlushRankXP();
    }
}

// ===================================================================
// MAP COOLDOWN SYSTEM — Filter recently played maps from vote and rotation
// ===================================================================

function SendMapOptionsAndOpenAARMenu()
{
    local KFPlayerController KFPC;
    local KFPlayerReplicationInfo KFPRI;
    local KFGameReplicationInfo KFGRI;
    local int i, AvailableCount;
    local bool bApplyCooldown;

    KFGRI = KFGameReplicationInfo(WorldInfo.GRI);

    // Safety: count how many maps would remain after filtering.
    // If fewer than 2 would be available, skip cooldown filtering entirely.
    bApplyCooldown = class'DKConfig_MapCooldown'.default.bEnabled;
    if (bApplyCooldown)
    {
        AvailableCount = 0;
        for (i = 0; i < GameMapCycles[ActiveMapCycle].Maps.Length; ++i)
        {
            if (GameModeSupportsMap(3, GameMapCycles[ActiveMapCycle].Maps[i])
                && !class'DKConfig_MapCooldown'.static.IsMapOnCooldown(GameMapCycles[ActiveMapCycle].Maps[i]))
            {
                ++AvailableCount;
            }
        }
        if (AvailableCount < 2)
            bApplyCooldown = False;
    }

    foreach WorldInfo.AllControllers(class'KFPlayerController', KFPC)
    {
        if (WorldInfo.NetMode == NM_StandAlone)
        {
            if (KFGRI != None && KFGRI.VoteCollector != None)
            {
                class'KFGfxMenu_StartGame'.static.GetMapList(KFGRI.VoteCollector.MapList, 3);
                for (i = 0; i < KFGRI.VoteCollector.MapList.Length; ++i)
                {
                    if (!GameModeSupportsMap(3, KFGRI.VoteCollector.MapList[i])
                        || (bApplyCooldown && class'DKConfig_MapCooldown'.static.IsMapOnCooldown(KFGRI.VoteCollector.MapList[i])))
                    {
                        KFGRI.VoteCollector.MapList.Remove(i, 1);
                        i--;
                    }
                }
            }
        }
        else
        {
            KFPRI = KFPlayerReplicationInfo(KFPC.PlayerReplicationInfo);
            for (i = 0; i < GameMapCycles[ActiveMapCycle].Maps.Length; ++i)
            {
                if (KFPRI != None)
                {
                    if (GameModeSupportsMap(3, GameMapCycles[ActiveMapCycle].Maps[i])
                        && !(bApplyCooldown && class'DKConfig_MapCooldown'.static.IsMapOnCooldown(GameMapCycles[ActiveMapCycle].Maps[i])))
                    {
                        KFPRI.RecieveAARMapOption(GameMapCycles[ActiveMapCycle].Maps[i]);
                    }
                }
            }
        }

        KFPC.ClientShowPostGameMenu();
    }
}

function string GetNextMapBase()
{
    local array<string> MapList;
    local int i;
    local bool bApplyCooldown;

    bApplyCooldown = class'DKConfig_MapCooldown'.default.bEnabled;

    if (bUseMapList && GameMapCycles.Length > 0)
    {
        if (MapCycleIndex == INDEX_NONE)
        {
            MapList = GameMapCycles[ActiveMapCycle].Maps;
            MapCycleIndex = GetCurrentMapCycleIndex(MapList);
            if (MapCycleIndex == INDEX_NONE)
                MapCycleIndex = 0;
        }

        // First pass: try to find a map that is supported AND not on cooldown
        for (i = 0; i < GameMapCycles[ActiveMapCycle].Maps.Length; ++i)
        {
            MapCycleIndex = MapCycleIndex + 1 < GameMapCycles[ActiveMapCycle].Maps.Length ? (MapCycleIndex + 1) : 0;

            if (GameModeSupportsMap(3, GameMapCycles[ActiveMapCycle].Maps[MapCycleIndex]))
            {
                if (!bApplyCooldown || !class'DKConfig_MapCooldown'.static.IsMapOnCooldown(GameMapCycles[ActiveMapCycle].Maps[MapCycleIndex]))
                {
                    SaveConfig();
                    return GameMapCycles[ActiveMapCycle].Maps[MapCycleIndex];
                }
            }
        }

        // Fallback: all maps are on cooldown, just pick any supported map
        for (i = 0; i < GameMapCycles[ActiveMapCycle].Maps.Length; ++i)
        {
            MapCycleIndex = MapCycleIndex + 1 < GameMapCycles[ActiveMapCycle].Maps.Length ? (MapCycleIndex + 1) : 0;

            if (GameModeSupportsMap(3, GameMapCycles[ActiveMapCycle].Maps[MapCycleIndex]))
            {
                SaveConfig();
                return GameMapCycles[ActiveMapCycle].Maps[MapCycleIndex];
            }
        }

        return string(WorldInfo.GetPackageName());
    }
    else
        return string(WorldInfo.GetPackageName());

    return "";
}

function SetMonsterDefaults(KFPawn_Monster P)
{
    super.SetMonsterDefaults(P);

    // Notify Event Wave Manager of new zed (R.A.G.E. enrage, etc.)
    if (EventWaveManager != None && EventWaveManager.ActiveEventID > 0)
    {
        EventWaveManager.OnZedSpawned(P);
    }
}

defaultproperties
{
    PlayerControllerClass=class'ZedternalRBPerkpackage.DKPlayerController'
    DefaultPawnClass=class'ZedternalRBPerkpackage.DKPawn_Human'
    PlayerReplicationInfoClass=class'ZedternalRBPerkpackage.DKPlayerReplicationInfo'
    HUDType=class'ZedternalRBPerkpackage.DKGFxScoreBoardWrapper'
    KFGFxManagerClass=class'ZedternalRBPerkpackage.DKGFxMoviePlayer_Manager'
    GameReplicationInfoClass=class'ZedternalRBPerkpackage.DKGameReplicationInfo'
    DifficultyInfoClass=class'ZedternalRBPerkpackage.DKGameDifficulty_Endless'
    DifficultyInfoConsoleClass=class'ZedternalRBPerkpackage.DKGameDifficulty_Endless_Console'
    
    // Roguelike upgrade system settings
    bRoguelikeEnabled=true

    // 131 Reforged weapon definitions (alphabetical by short name)
    // Bit index = array index (0-130)
    ReforgedWeaponDefPaths(0)="ZedternalRBPerkpackage.DKWeapDef_9mm_Reforged"
    ReforgedWeaponDefPaths(1)="ZedternalRBPerkpackage.DKWeapDef_9mmDual_Reforged"
    ReforgedWeaponDefPaths(2)="ZedternalRBPerkpackage.DKWeapDef_AA12_Reforged"
    ReforgedWeaponDefPaths(3)="ZedternalRBPerkpackage.DKWeapDef_AF2011_Reforged"
    ReforgedWeaponDefPaths(4)="ZedternalRBPerkpackage.DKWeapDef_AF2011Dual_Reforged"
    ReforgedWeaponDefPaths(5)="ZedternalRBPerkpackage.DKWeapDef_AK12_Reforged"
    ReforgedWeaponDefPaths(6)="ZedternalRBPerkpackage.DKWeapDef_AR15_Reforged"
    ReforgedWeaponDefPaths(7)="ZedternalRBPerkpackage.DKWeapDef_AbominationAxe_Reforged"
    ReforgedWeaponDefPaths(8)="ZedternalRBPerkpackage.DKWeapDef_AutoTurret_Reforged"
    ReforgedWeaponDefPaths(9)="ZedternalRBPerkpackage.DKWeapDef_AutoTurretWeapon_Reforged"
    ReforgedWeaponDefPaths(10)="ZedternalRBPerkpackage.DKWeapDef_BladedPistol_Reforged"
    ReforgedWeaponDefPaths(11)="ZedternalRBPerkpackage.DKWeapDef_Blunderbuss_Reforged"
    ReforgedWeaponDefPaths(12)="ZedternalRBPerkpackage.DKWeapDef_Bullpup_Reforged"
    ReforgedWeaponDefPaths(13)="ZedternalRBPerkpackage.DKWeapDef_C4_Reforged"
    ReforgedWeaponDefPaths(14)="ZedternalRBPerkpackage.DKWeapDef_CaulkBurn_Reforged"
    ReforgedWeaponDefPaths(15)="ZedternalRBPerkpackage.DKWeapDef_CenterfireMB464_Reforged"
    ReforgedWeaponDefPaths(16)="ZedternalRBPerkpackage.DKWeapDef_ChainBat_Reforged"
    ReforgedWeaponDefPaths(17)="ZedternalRBPerkpackage.DKWeapDef_ChiappaRhino_Reforged"
    ReforgedWeaponDefPaths(18)="ZedternalRBPerkpackage.DKWeapDef_ChiappaRhinoDual_Reforged"
    ReforgedWeaponDefPaths(19)="ZedternalRBPerkpackage.DKWeapDef_Colt1911_Reforged"
    ReforgedWeaponDefPaths(20)="ZedternalRBPerkpackage.DKWeapDef_Colt1911Dual_Reforged"
    ReforgedWeaponDefPaths(21)="ZedternalRBPerkpackage.DKWeapDef_CompoundBow_Reforged"
    ReforgedWeaponDefPaths(22)="ZedternalRBPerkpackage.DKWeapDef_Crossbow_Reforged"
    ReforgedWeaponDefPaths(23)="ZedternalRBPerkpackage.DKWeapDef_Crovel_Reforged"
    ReforgedWeaponDefPaths(24)="ZedternalRBPerkpackage.DKWeapDef_Deagle_Reforged"
    ReforgedWeaponDefPaths(25)="ZedternalRBPerkpackage.DKWeapDef_DeagleDual_Reforged"
    ReforgedWeaponDefPaths(26)="ZedternalRBPerkpackage.DKWeapDef_Doshinegun_Reforged"
    ReforgedWeaponDefPaths(27)="ZedternalRBPerkpackage.DKWeapDef_DoubleBarrel_Reforged"
    ReforgedWeaponDefPaths(28)="ZedternalRBPerkpackage.DKWeapDef_DragonsBreath_Reforged"
    ReforgedWeaponDefPaths(29)="ZedternalRBPerkpackage.DKWeapDef_DualBladed_Reforged"
    ReforgedWeaponDefPaths(30)="ZedternalRBPerkpackage.DKWeapDef_ElephantGun_Reforged"
    ReforgedWeaponDefPaths(31)="ZedternalRBPerkpackage.DKWeapDef_Eviscerator_Reforged"
    ReforgedWeaponDefPaths(32)="ZedternalRBPerkpackage.DKWeapDef_FAMAS_Reforged"
    ReforgedWeaponDefPaths(33)="ZedternalRBPerkpackage.DKWeapDef_FNFal_Reforged"
    ReforgedWeaponDefPaths(34)="ZedternalRBPerkpackage.DKWeapDef_FireAxe_Reforged"
    ReforgedWeaponDefPaths(35)="ZedternalRBPerkpackage.DKWeapDef_FlameThrower_Reforged"
    ReforgedWeaponDefPaths(36)="ZedternalRBPerkpackage.DKWeapDef_FlareGun_Reforged"
    ReforgedWeaponDefPaths(37)="ZedternalRBPerkpackage.DKWeapDef_FlareGunDual_Reforged"
    ReforgedWeaponDefPaths(38)="ZedternalRBPerkpackage.DKWeapDef_FreezeThrower_Reforged"
    ReforgedWeaponDefPaths(39)="ZedternalRBPerkpackage.DKWeapDef_G18_Reforged"
    ReforgedWeaponDefPaths(40)="ZedternalRBPerkpackage.DKWeapDef_G36C_Reforged"
    ReforgedWeaponDefPaths(41)="ZedternalRBPerkpackage.DKWeapDef_GravityImploder_Reforged"
    ReforgedWeaponDefPaths(42)="ZedternalRBPerkpackage.DKWeapDef_HK_UMP_Reforged"
    ReforgedWeaponDefPaths(43)="ZedternalRBPerkpackage.DKWeapDef_HRGIncendiaryRifle_Reforged"
    ReforgedWeaponDefPaths(44)="ZedternalRBPerkpackage.DKWeapDef_HRGIncision_Reforged"
    ReforgedWeaponDefPaths(45)="ZedternalRBPerkpackage.DKWeapDef_HRGScorcher_Reforged"
    ReforgedWeaponDefPaths(46)="ZedternalRBPerkpackage.DKWeapDef_HRGTeslauncher_Reforged"
    ReforgedWeaponDefPaths(47)="ZedternalRBPerkpackage.DKWeapDef_HRGWinterbite_Reforged"
    ReforgedWeaponDefPaths(48)="ZedternalRBPerkpackage.DKWeapDef_HRGWinterbiteDual_Reforged"
    ReforgedWeaponDefPaths(49)="ZedternalRBPerkpackage.DKWeapDef_HRG_93R_Reforged"
    ReforgedWeaponDefPaths(50)="ZedternalRBPerkpackage.DKWeapDef_HRG_93R_Dual_Reforged"
    ReforgedWeaponDefPaths(51)="ZedternalRBPerkpackage.DKWeapDef_HRG_BallisticBouncer_Reforged"
    ReforgedWeaponDefPaths(52)="ZedternalRBPerkpackage.DKWeapDef_HRG_BarrierRifle_Reforged"
    ReforgedWeaponDefPaths(53)="ZedternalRBPerkpackage.DKWeapDef_HRG_BlastBrawlers_Reforged"
    ReforgedWeaponDefPaths(54)="ZedternalRBPerkpackage.DKWeapDef_HRG_Boomy_Reforged"
    ReforgedWeaponDefPaths(55)="ZedternalRBPerkpackage.DKWeapDef_HRG_CranialPopper_Reforged"
    ReforgedWeaponDefPaths(56)="ZedternalRBPerkpackage.DKWeapDef_HRG_Crossboom_Reforged"
    ReforgedWeaponDefPaths(57)="ZedternalRBPerkpackage.DKWeapDef_HRG_Dragonbreath_Reforged"
    ReforgedWeaponDefPaths(58)="ZedternalRBPerkpackage.DKWeapDef_HRG_EMP_ArcGenerator_Reforged"
    ReforgedWeaponDefPaths(59)="ZedternalRBPerkpackage.DKWeapDef_HRG_Energy_Reforged"
    ReforgedWeaponDefPaths(60)="ZedternalRBPerkpackage.DKWeapDef_HRG_Kaboomstick_Reforged"
    ReforgedWeaponDefPaths(61)="ZedternalRBPerkpackage.DKWeapDef_HRG_Locust_Reforged"
    ReforgedWeaponDefPaths(62)="ZedternalRBPerkpackage.DKWeapDef_HRG_MedicMissile_Reforged"
    ReforgedWeaponDefPaths(63)="ZedternalRBPerkpackage.DKWeapDef_HRG_SonicGun_Reforged"
    ReforgedWeaponDefPaths(64)="ZedternalRBPerkpackage.DKWeapDef_HRG_Stunner_Reforged"
    ReforgedWeaponDefPaths(65)="ZedternalRBPerkpackage.DKWeapDef_HRG_Vampire_Reforged"
    ReforgedWeaponDefPaths(66)="ZedternalRBPerkpackage.DKWeapDef_HRG_Warthog_Reforged"
    ReforgedWeaponDefPaths(67)="ZedternalRBPerkpackage.DKWeapDef_HRG_WarthogWeapon_Reforged"
    ReforgedWeaponDefPaths(68)="ZedternalRBPerkpackage.DKWeapDef_HVStormCannon_Reforged"
    ReforgedWeaponDefPaths(69)="ZedternalRBPerkpackage.DKWeapDef_HX25_Reforged"
    ReforgedWeaponDefPaths(70)="ZedternalRBPerkpackage.DKWeapDef_HZ12_Reforged"
    ReforgedWeaponDefPaths(71)="ZedternalRBPerkpackage.DKWeapDef_Healthrower_HRG_Reforged"
    ReforgedWeaponDefPaths(72)="ZedternalRBPerkpackage.DKWeapDef_Hemogoblin_Reforged"
    ReforgedWeaponDefPaths(73)="ZedternalRBPerkpackage.DKWeapDef_HuskCannon_Reforged"
    ReforgedWeaponDefPaths(74)="ZedternalRBPerkpackage.DKWeapDef_IonThruster_Reforged"
    ReforgedWeaponDefPaths(75)="ZedternalRBPerkpackage.DKWeapDef_Katana_Reforged"
    ReforgedWeaponDefPaths(76)="ZedternalRBPerkpackage.DKWeapDef_Kriss_Reforged"
    ReforgedWeaponDefPaths(77)="ZedternalRBPerkpackage.DKWeapDef_LazerCutter_Reforged"
    ReforgedWeaponDefPaths(78)="ZedternalRBPerkpackage.DKWeapDef_M14EBR_Reforged"
    ReforgedWeaponDefPaths(79)="ZedternalRBPerkpackage.DKWeapDef_M16M203_Reforged"
    ReforgedWeaponDefPaths(80)="ZedternalRBPerkpackage.DKWeapDef_M32_Reforged"
    ReforgedWeaponDefPaths(81)="ZedternalRBPerkpackage.DKWeapDef_M4_Reforged"
    ReforgedWeaponDefPaths(82)="ZedternalRBPerkpackage.DKWeapDef_M79_Reforged"
    ReforgedWeaponDefPaths(83)="ZedternalRBPerkpackage.DKWeapDef_M99_Reforged"
    ReforgedWeaponDefPaths(84)="ZedternalRBPerkpackage.DKWeapDef_MB500_Reforged"
    ReforgedWeaponDefPaths(85)="ZedternalRBPerkpackage.DKWeapDef_MG3_Reforged"
    ReforgedWeaponDefPaths(86)="ZedternalRBPerkpackage.DKWeapDef_MKB42_Reforged"
    ReforgedWeaponDefPaths(87)="ZedternalRBPerkpackage.DKWeapDef_MP5RAS_Reforged"
    ReforgedWeaponDefPaths(88)="ZedternalRBPerkpackage.DKWeapDef_MP7_Reforged"
    ReforgedWeaponDefPaths(89)="ZedternalRBPerkpackage.DKWeapDef_Mac10_Reforged"
    ReforgedWeaponDefPaths(90)="ZedternalRBPerkpackage.DKWeapDef_MaceAndShield_Reforged"
    ReforgedWeaponDefPaths(91)="ZedternalRBPerkpackage.DKWeapDef_MedicBat_Reforged"
    ReforgedWeaponDefPaths(92)="ZedternalRBPerkpackage.DKWeapDef_MedicPistol_Reforged"
    ReforgedWeaponDefPaths(93)="ZedternalRBPerkpackage.DKWeapDef_MedicRifle_Reforged"
    ReforgedWeaponDefPaths(94)="ZedternalRBPerkpackage.DKWeapDef_MedicRifleGrenadeLauncher_Reforged"
    ReforgedWeaponDefPaths(95)="ZedternalRBPerkpackage.DKWeapDef_MedicSMG_Reforged"
    ReforgedWeaponDefPaths(96)="ZedternalRBPerkpackage.DKWeapDef_MedicShotgun_Reforged"
    ReforgedWeaponDefPaths(97)="ZedternalRBPerkpackage.DKWeapDef_MicrowaveGun_Reforged"
    ReforgedWeaponDefPaths(98)="ZedternalRBPerkpackage.DKWeapDef_MicrowaveRifle_Reforged"
    ReforgedWeaponDefPaths(99)="ZedternalRBPerkpackage.DKWeapDef_Mine_Reconstructor_Reforged"
    ReforgedWeaponDefPaths(100)="ZedternalRBPerkpackage.DKWeapDef_Minigun_Reforged"
    ReforgedWeaponDefPaths(101)="ZedternalRBPerkpackage.DKWeapDef_MosinNagant_Reforged"
    ReforgedWeaponDefPaths(102)="ZedternalRBPerkpackage.DKWeapDef_Nailgun_Reforged"
    ReforgedWeaponDefPaths(103)="ZedternalRBPerkpackage.DKWeapDef_Nailgun_HRG_Reforged"
    ReforgedWeaponDefPaths(104)="ZedternalRBPerkpackage.DKWeapDef_P90_Reforged"
    ReforgedWeaponDefPaths(105)="ZedternalRBPerkpackage.DKWeapDef_ParasiteImplanter_Reforged"
    ReforgedWeaponDefPaths(106)="ZedternalRBPerkpackage.DKWeapDef_Pistol_DualG18_Reforged"
    ReforgedWeaponDefPaths(107)="ZedternalRBPerkpackage.DKWeapDef_Pistol_G18C_Reforged"
    ReforgedWeaponDefPaths(108)="ZedternalRBPerkpackage.DKWeapDef_PowerGloves_Reforged"
    ReforgedWeaponDefPaths(109)="ZedternalRBPerkpackage.DKWeapDef_Pulverizer_Reforged"
    ReforgedWeaponDefPaths(110)="ZedternalRBPerkpackage.DKWeapDef_RPG7_Reforged"
    ReforgedWeaponDefPaths(111)="ZedternalRBPerkpackage.DKWeapDef_RailGun_Reforged"
    ReforgedWeaponDefPaths(112)="ZedternalRBPerkpackage.DKWeapDef_Remington1858_Reforged"
    ReforgedWeaponDefPaths(113)="ZedternalRBPerkpackage.DKWeapDef_Remington1858Dual_Reforged"
    ReforgedWeaponDefPaths(114)="ZedternalRBPerkpackage.DKWeapDef_Rifle_FrostShotgunAxe_Reforged"
    ReforgedWeaponDefPaths(115)="ZedternalRBPerkpackage.DKWeapDef_SCAR_Reforged"
    ReforgedWeaponDefPaths(116)="ZedternalRBPerkpackage.DKWeapDef_SW500_Reforged"
    ReforgedWeaponDefPaths(117)="ZedternalRBPerkpackage.DKWeapDef_SW500Dual_Reforged"
    ReforgedWeaponDefPaths(118)="ZedternalRBPerkpackage.DKWeapDef_SW500Dual_HRG_Reforged"
    ReforgedWeaponDefPaths(119)="ZedternalRBPerkpackage.DKWeapDef_SW500_HRG_Reforged"
    ReforgedWeaponDefPaths(120)="ZedternalRBPerkpackage.DKWeapDef_Scythe_Reforged"
    ReforgedWeaponDefPaths(121)="ZedternalRBPerkpackage.DKWeapDef_SealSqueal_Reforged"
    ReforgedWeaponDefPaths(122)="ZedternalRBPerkpackage.DKWeapDef_Seeker6_Reforged"
    ReforgedWeaponDefPaths(123)="ZedternalRBPerkpackage.DKWeapDef_Shotgun_S12_Reforged"
    ReforgedWeaponDefPaths(124)="ZedternalRBPerkpackage.DKWeapDef_ShrinkRayGun_Reforged"
    ReforgedWeaponDefPaths(125)="ZedternalRBPerkpackage.DKWeapDef_Stoner63A_Reforged"
    ReforgedWeaponDefPaths(126)="ZedternalRBPerkpackage.DKWeapDef_ThermiteBore_Reforged"
    ReforgedWeaponDefPaths(127)="ZedternalRBPerkpackage.DKWeapDef_Thompson_Reforged"
    ReforgedWeaponDefPaths(128)="ZedternalRBPerkpackage.DKWeapDef_Winchester1894_Reforged"
    ReforgedWeaponDefPaths(129)="ZedternalRBPerkpackage.DKWeapDef_ZedMKIII_Reforged"
    ReforgedWeaponDefPaths(130)="ZedternalRBPerkpackage.DKWeapDef_Zweihander_Reforged"

    HollowWeaponDefPaths(0)="ZedternalRBPerkpackage.DKWeapDef_9mmDual_Hollow"
    HollowWeaponDefPaths(1)="ZedternalRBPerkpackage.DKWeapDef_9mm_Hollow"
    HollowWeaponDefPaths(2)="ZedternalRBPerkpackage.DKWeapDef_AA12_Hollow"
    HollowWeaponDefPaths(3)="ZedternalRBPerkpackage.DKWeapDef_AF2011Dual_Hollow"
    HollowWeaponDefPaths(4)="ZedternalRBPerkpackage.DKWeapDef_AF2011_Hollow"
    HollowWeaponDefPaths(5)="ZedternalRBPerkpackage.DKWeapDef_AK12_Hollow"
    HollowWeaponDefPaths(6)="ZedternalRBPerkpackage.DKWeapDef_AR15_Hollow"
    HollowWeaponDefPaths(7)="ZedternalRBPerkpackage.DKWeapDef_AbominationAxe_Hollow"
    HollowWeaponDefPaths(8)="ZedternalRBPerkpackage.DKWeapDef_BladedPistol_Hollow"
    HollowWeaponDefPaths(9)="ZedternalRBPerkpackage.DKWeapDef_Blunderbuss_Hollow"
    HollowWeaponDefPaths(10)="ZedternalRBPerkpackage.DKWeapDef_Bullpup_Hollow"
    HollowWeaponDefPaths(11)="ZedternalRBPerkpackage.DKWeapDef_C4_Hollow"
    HollowWeaponDefPaths(12)="ZedternalRBPerkpackage.DKWeapDef_CaulkBurn_Hollow"
    HollowWeaponDefPaths(13)="ZedternalRBPerkpackage.DKWeapDef_CenterfireMB464_Hollow"
    HollowWeaponDefPaths(14)="ZedternalRBPerkpackage.DKWeapDef_ChainBat_Hollow"
    HollowWeaponDefPaths(15)="ZedternalRBPerkpackage.DKWeapDef_ChiappaRhinoDual_Hollow"
    HollowWeaponDefPaths(16)="ZedternalRBPerkpackage.DKWeapDef_ChiappaRhino_Hollow"
    HollowWeaponDefPaths(17)="ZedternalRBPerkpackage.DKWeapDef_Colt1911Dual_Hollow"
    HollowWeaponDefPaths(18)="ZedternalRBPerkpackage.DKWeapDef_Colt1911_Hollow"
    HollowWeaponDefPaths(19)="ZedternalRBPerkpackage.DKWeapDef_CompoundBow_Hollow"
    HollowWeaponDefPaths(20)="ZedternalRBPerkpackage.DKWeapDef_Crossbow_Hollow"
    HollowWeaponDefPaths(21)="ZedternalRBPerkpackage.DKWeapDef_Crovel_Hollow"
    HollowWeaponDefPaths(22)="ZedternalRBPerkpackage.DKWeapDef_DeagleDual_Hollow"
    HollowWeaponDefPaths(23)="ZedternalRBPerkpackage.DKWeapDef_Deagle_Hollow"
    HollowWeaponDefPaths(24)="ZedternalRBPerkpackage.DKWeapDef_Doshinegun_Hollow"
    HollowWeaponDefPaths(25)="ZedternalRBPerkpackage.DKWeapDef_DoubleBarrel_Hollow"
    HollowWeaponDefPaths(26)="ZedternalRBPerkpackage.DKWeapDef_DragonsBreath_Hollow"
    HollowWeaponDefPaths(27)="ZedternalRBPerkpackage.DKWeapDef_DualBladed_Hollow"
    HollowWeaponDefPaths(28)="ZedternalRBPerkpackage.DKWeapDef_ElephantGun_Hollow"
    HollowWeaponDefPaths(29)="ZedternalRBPerkpackage.DKWeapDef_Eviscerator_Hollow"
    HollowWeaponDefPaths(30)="ZedternalRBPerkpackage.DKWeapDef_FAMAS_Hollow"
    HollowWeaponDefPaths(31)="ZedternalRBPerkpackage.DKWeapDef_FNFal_Hollow"
    HollowWeaponDefPaths(32)="ZedternalRBPerkpackage.DKWeapDef_FireAxe_Hollow"
    HollowWeaponDefPaths(33)="ZedternalRBPerkpackage.DKWeapDef_FlameThrower_Hollow"
    HollowWeaponDefPaths(34)="ZedternalRBPerkpackage.DKWeapDef_FlareGunDual_Hollow"
    HollowWeaponDefPaths(35)="ZedternalRBPerkpackage.DKWeapDef_FlareGun_Hollow"
    HollowWeaponDefPaths(36)="ZedternalRBPerkpackage.DKWeapDef_FreezeThrower_Hollow"
    HollowWeaponDefPaths(37)="ZedternalRBPerkpackage.DKWeapDef_G18_Hollow"
    HollowWeaponDefPaths(38)="ZedternalRBPerkpackage.DKWeapDef_G36C_Hollow"
    HollowWeaponDefPaths(39)="ZedternalRBPerkpackage.DKWeapDef_GravityImploder_Hollow"
    HollowWeaponDefPaths(40)="ZedternalRBPerkpackage.DKWeapDef_HK_UMP_Hollow"
    HollowWeaponDefPaths(41)="ZedternalRBPerkpackage.DKWeapDef_HRGIncendiaryRifle_Hollow"
    HollowWeaponDefPaths(42)="ZedternalRBPerkpackage.DKWeapDef_HRGIncision_Hollow"
    HollowWeaponDefPaths(43)="ZedternalRBPerkpackage.DKWeapDef_HRGScorcher_Hollow"
    HollowWeaponDefPaths(44)="ZedternalRBPerkpackage.DKWeapDef_HRGTeslauncher_Hollow"
    HollowWeaponDefPaths(45)="ZedternalRBPerkpackage.DKWeapDef_HRGWinterbiteDual_Hollow"
    HollowWeaponDefPaths(46)="ZedternalRBPerkpackage.DKWeapDef_HRGWinterbite_Hollow"
    HollowWeaponDefPaths(47)="ZedternalRBPerkpackage.DKWeapDef_HRG_93R_Dual_Hollow"
    HollowWeaponDefPaths(48)="ZedternalRBPerkpackage.DKWeapDef_HRG_93R_Hollow"
    HollowWeaponDefPaths(49)="ZedternalRBPerkpackage.DKWeapDef_HRG_BallisticBouncer_Hollow"
    HollowWeaponDefPaths(50)="ZedternalRBPerkpackage.DKWeapDef_HRG_BarrierRifle_Hollow"
    HollowWeaponDefPaths(51)="ZedternalRBPerkpackage.DKWeapDef_HRG_BlastBrawlers_Hollow"
    HollowWeaponDefPaths(52)="ZedternalRBPerkpackage.DKWeapDef_HRG_Boomy_Hollow"
    HollowWeaponDefPaths(53)="ZedternalRBPerkpackage.DKWeapDef_HRG_CranialPopper_Hollow"
    HollowWeaponDefPaths(54)="ZedternalRBPerkpackage.DKWeapDef_HRG_Crossboom_Hollow"
    HollowWeaponDefPaths(55)="ZedternalRBPerkpackage.DKWeapDef_HRG_Dragonbreath_Hollow"
    HollowWeaponDefPaths(56)="ZedternalRBPerkpackage.DKWeapDef_HRG_EMP_ArcGenerator_Hollow"
    HollowWeaponDefPaths(57)="ZedternalRBPerkpackage.DKWeapDef_HRG_Energy_Hollow"
    HollowWeaponDefPaths(58)="ZedternalRBPerkpackage.DKWeapDef_HRG_Kaboomstick_Hollow"
    HollowWeaponDefPaths(59)="ZedternalRBPerkpackage.DKWeapDef_HRG_Locust_Hollow"
    HollowWeaponDefPaths(60)="ZedternalRBPerkpackage.DKWeapDef_HRG_MedicMissile_Hollow"
    HollowWeaponDefPaths(61)="ZedternalRBPerkpackage.DKWeapDef_HRG_SonicGun_Hollow"
    HollowWeaponDefPaths(62)="ZedternalRBPerkpackage.DKWeapDef_HRG_Stunner_Hollow"
    HollowWeaponDefPaths(63)="ZedternalRBPerkpackage.DKWeapDef_HRG_Vampire_Hollow"
    HollowWeaponDefPaths(64)="ZedternalRBPerkpackage.DKWeapDef_HRG_Warthog_Hollow"
    HollowWeaponDefPaths(65)="ZedternalRBPerkpackage.DKWeapDef_HVStormCannon_Hollow"
    HollowWeaponDefPaths(66)="ZedternalRBPerkpackage.DKWeapDef_HX25_Hollow"
    HollowWeaponDefPaths(67)="ZedternalRBPerkpackage.DKWeapDef_HZ12_Hollow"
    HollowWeaponDefPaths(68)="ZedternalRBPerkpackage.DKWeapDef_Healthrower_HRG_Hollow"
    HollowWeaponDefPaths(69)="ZedternalRBPerkpackage.DKWeapDef_Hemogoblin_Hollow"
    HollowWeaponDefPaths(70)="ZedternalRBPerkpackage.DKWeapDef_HuskCannon_Hollow"
    HollowWeaponDefPaths(71)="ZedternalRBPerkpackage.DKWeapDef_IonThruster_Hollow"
    HollowWeaponDefPaths(72)="ZedternalRBPerkpackage.DKWeapDef_Katana_Hollow"
    HollowWeaponDefPaths(73)="ZedternalRBPerkpackage.DKWeapDef_Kriss_Hollow"
    HollowWeaponDefPaths(74)="ZedternalRBPerkpackage.DKWeapDef_LazerCutter_Hollow"
    HollowWeaponDefPaths(75)="ZedternalRBPerkpackage.DKWeapDef_M14EBR_Hollow"
    HollowWeaponDefPaths(76)="ZedternalRBPerkpackage.DKWeapDef_M16M203_Hollow"
    HollowWeaponDefPaths(77)="ZedternalRBPerkpackage.DKWeapDef_M32_Hollow"
    HollowWeaponDefPaths(78)="ZedternalRBPerkpackage.DKWeapDef_M4_Hollow"
    HollowWeaponDefPaths(79)="ZedternalRBPerkpackage.DKWeapDef_M79_Hollow"
    HollowWeaponDefPaths(80)="ZedternalRBPerkpackage.DKWeapDef_M99_Hollow"
    HollowWeaponDefPaths(81)="ZedternalRBPerkpackage.DKWeapDef_MB500_Hollow"
    HollowWeaponDefPaths(82)="ZedternalRBPerkpackage.DKWeapDef_MG3_Hollow"
    HollowWeaponDefPaths(83)="ZedternalRBPerkpackage.DKWeapDef_MKB42_Hollow"
    HollowWeaponDefPaths(84)="ZedternalRBPerkpackage.DKWeapDef_MP5RAS_Hollow"
    HollowWeaponDefPaths(85)="ZedternalRBPerkpackage.DKWeapDef_MP7_Hollow"
    HollowWeaponDefPaths(86)="ZedternalRBPerkpackage.DKWeapDef_Mac10_Hollow"
    HollowWeaponDefPaths(87)="ZedternalRBPerkpackage.DKWeapDef_MaceAndShield_Hollow"
    HollowWeaponDefPaths(88)="ZedternalRBPerkpackage.DKWeapDef_MedicBat_Hollow"
    HollowWeaponDefPaths(89)="ZedternalRBPerkpackage.DKWeapDef_MedicPistol_Hollow"
    HollowWeaponDefPaths(90)="ZedternalRBPerkpackage.DKWeapDef_MedicRifleGrenadeLauncher_Hollow"
    HollowWeaponDefPaths(91)="ZedternalRBPerkpackage.DKWeapDef_MedicRifle_Hollow"
    HollowWeaponDefPaths(92)="ZedternalRBPerkpackage.DKWeapDef_MedicSMG_Hollow"
    HollowWeaponDefPaths(93)="ZedternalRBPerkpackage.DKWeapDef_MedicShotgun_Hollow"
    HollowWeaponDefPaths(94)="ZedternalRBPerkpackage.DKWeapDef_MicrowaveGun_Hollow"
    HollowWeaponDefPaths(95)="ZedternalRBPerkpackage.DKWeapDef_MicrowaveRifle_Hollow"
    HollowWeaponDefPaths(96)="ZedternalRBPerkpackage.DKWeapDef_Mine_Reconstructor_Hollow"
    HollowWeaponDefPaths(97)="ZedternalRBPerkpackage.DKWeapDef_Minigun_Hollow"
    HollowWeaponDefPaths(98)="ZedternalRBPerkpackage.DKWeapDef_MosinNagant_Hollow"
    HollowWeaponDefPaths(99)="ZedternalRBPerkpackage.DKWeapDef_Nailgun_HRG_Hollow"
    HollowWeaponDefPaths(100)="ZedternalRBPerkpackage.DKWeapDef_Nailgun_Hollow"
    HollowWeaponDefPaths(101)="ZedternalRBPerkpackage.DKWeapDef_P90_Hollow"
    HollowWeaponDefPaths(102)="ZedternalRBPerkpackage.DKWeapDef_ParasiteImplanter_Hollow"
    HollowWeaponDefPaths(103)="ZedternalRBPerkpackage.DKWeapDef_Pistol_DualG18_Hollow"
    HollowWeaponDefPaths(104)="ZedternalRBPerkpackage.DKWeapDef_Pistol_G18C_Hollow"
    HollowWeaponDefPaths(105)="ZedternalRBPerkpackage.DKWeapDef_PowerGloves_Hollow"
    HollowWeaponDefPaths(106)="ZedternalRBPerkpackage.DKWeapDef_Pulverizer_Hollow"
    HollowWeaponDefPaths(107)="ZedternalRBPerkpackage.DKWeapDef_RPG7_Hollow"
    HollowWeaponDefPaths(108)="ZedternalRBPerkpackage.DKWeapDef_RailGun_Hollow"
    HollowWeaponDefPaths(109)="ZedternalRBPerkpackage.DKWeapDef_Remington1858Dual_Hollow"
    HollowWeaponDefPaths(110)="ZedternalRBPerkpackage.DKWeapDef_Remington1858_Hollow"
    HollowWeaponDefPaths(111)="ZedternalRBPerkpackage.DKWeapDef_Rifle_FrostShotgunAxe_Hollow"
    HollowWeaponDefPaths(112)="ZedternalRBPerkpackage.DKWeapDef_SCAR_Hollow"
    HollowWeaponDefPaths(113)="ZedternalRBPerkpackage.DKWeapDef_SW500Dual_HRG_Hollow"
    HollowWeaponDefPaths(114)="ZedternalRBPerkpackage.DKWeapDef_SW500Dual_Hollow"
    HollowWeaponDefPaths(115)="ZedternalRBPerkpackage.DKWeapDef_SW500_HRG_Hollow"
    HollowWeaponDefPaths(116)="ZedternalRBPerkpackage.DKWeapDef_SW500_Hollow"
    HollowWeaponDefPaths(117)="ZedternalRBPerkpackage.DKWeapDef_Scythe_Hollow"
    HollowWeaponDefPaths(118)="ZedternalRBPerkpackage.DKWeapDef_SealSqueal_Hollow"
    HollowWeaponDefPaths(119)="ZedternalRBPerkpackage.DKWeapDef_Seeker6_Hollow"
    HollowWeaponDefPaths(120)="ZedternalRBPerkpackage.DKWeapDef_Shotgun_S12_Hollow"
    HollowWeaponDefPaths(121)="ZedternalRBPerkpackage.DKWeapDef_ShrinkRayGun_Hollow"
    HollowWeaponDefPaths(122)="ZedternalRBPerkpackage.DKWeapDef_Stoner63A_Hollow"
    HollowWeaponDefPaths(123)="ZedternalRBPerkpackage.DKWeapDef_ThermiteBore_Hollow"
    HollowWeaponDefPaths(124)="ZedternalRBPerkpackage.DKWeapDef_Thompson_Hollow"
    HollowWeaponDefPaths(125)="ZedternalRBPerkpackage.DKWeapDef_Winchester1894_Hollow"
    HollowWeaponDefPaths(126)="ZedternalRBPerkpackage.DKWeapDef_ZedMKIII_Hollow"
    HollowWeaponDefPaths(127)="ZedternalRBPerkpackage.DKWeapDef_Zweihander_Hollow"
    
    Name="Default__DKGameInfo_Endless"
}
