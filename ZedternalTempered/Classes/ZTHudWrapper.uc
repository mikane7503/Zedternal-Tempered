class ZTHudWrapper extends WMGFxHudWrapper;

// ===================================================================
// RESOLUTION SCALING SYSTEM
//
// Auto-detection curve (720p baseline):
//   Below/at 1080p: linear   ResScale = SizeY / 720.0
//     720p  -> 1.00x
//     1080p -> 1.50x
//   Above 1080p: dampened    ResScale = 1.5 * sqrt(SizeY / 1080.0)
//     1440p -> 1.73x
//     4K    -> 2.12x
//     5K    -> 2.45x
//
// HudScaleMultiplier: user preference from ZTConfig_HudPreferences.
//   Multiplies the auto scale. Default 1.0. Saved to INI.
//   Set via console: DKHudScale <value>
//
// Final: ResScale = AutoScale * HudScaleMultiplier
// ===================================================================
var float ResScale;             // Final computed scale, used by all HUD elements
var float AutoResScale;         // Auto-detected scale before user multiplier
var float HudScaleMultiplier;   // User preference multiplier (from config, default 1.0)
var float CardStackMaxY;        // Config: max screen fraction for card stack (default 0.82)
var byte CardStackMaxCards;     // Config: cards before compression (default 4)
var float CardStackShrink;      // Computed per-frame: 1.0 = no shrink, <1.0 = compressed
var bool bHudPrefsLoaded;       // True once preferences have been loaded from config

// Scoreboard is owned by ZTGFxScoreBoardWrapper subclass




// ===================================================================
// EXISTING SYSTEMS - Multiple Perk Tracker & Evolution Panel
// ===================================================================

// Structure for the evolution panel display
struct EvolutionPanelData
{
    var bool bShowPanel;
    var float PanelDisplayTime;
    var bool bToggleMode;
};

var EvolutionPanelData EvolutionPanel;

// Structure for instant kill notifications
struct InstantKillNotification
{
    var string NotificationText;
    var float DisplayTime;
    var float MaxDisplayTime;
    var Color TextColor;
    var bool bIsActive;
    var float TextScale;
};

var InstantKillNotification InstantKillNotif;

// ===================================================================
// EXISTING: Chain Notification System
// ===================================================================

struct ChainNotification
{
    var string NotificationTitle;
    var string NotificationText;
    var float DisplayTime;
    var float MaxDisplayTime;
    var Color TitleColor;
    var Color TextColor;
    var bool bIsActive;
    var float TitleScale;
    var float TextScale;
};

var ChainNotification ChainNotif;

// ===================================================================
// NEW: Notification Feed System
// ===================================================================

struct NotificationMessage
{
    var string MessageText;
    var Color MessageColor;
    var float DisplayTime;
    var float MaxDisplayTime;
    var bool bIsActive;
    var byte Priority;
};

var array<NotificationMessage> NotificationMessages;

var float NotificationFeedX;
var float NotificationFeedY;
var float NotificationSpacing;
var float NotificationMaxWidth;
var float NotificationTextScale;
var int MaxVisibleNotifications;

// ===================================================================
// NEW: Active Ability Display System
// ===================================================================

struct AbilitySlotDisplay
{
    var bool bHasAbility;
    var string AbilityName;
    var Texture2D AbilityIcon;
    var bool bIsActive;
    var bool bOnCooldown;
    var float RemainingTime;
    var float MaxTime;
};

var array<AbilitySlotDisplay> AbilitySlots;

var float AbilityDisplayX;
var float AbilityDisplayY;
var float AbilitySlotWidth;
var float AbilitySlotHeight;
var float AbilitySlotSpacing;

// ===================================================================
// NEW: Perk Unlock Popup System with Glow Pulse Animation
// ===================================================================

struct PerkUnlockPopup
{
    var string PerkName;
    var Texture2D PerkIcon;
    var float DisplayTime;
    var float MaxDisplayTime;
    var bool bIsActive;
    var Color TitleColor;
    var Color BackgroundColor;
};

var PerkUnlockPopup UnlockPopup;

// ===================================================================
// NEW: Achievement Unlock Popup System (UPDATED WITH DESCRIPTION)
// ===================================================================

struct AchievementUnlockPopup
{
    var string AchievementName;
    var string Description;  // <-- ADDED: Achievement description field
    var Texture2D AchievementIcon;
    var float DisplayTime;
    var float MaxDisplayTime;
    var bool bIsActive;
    var Color TitleColor;
    var Color BackgroundColor;
};

var AchievementUnlockPopup AchievementPopup;

struct UnlockParticle
{
    var float X;
    var float Y;
    var float VelocityX;
    var float VelocityY;
    var float Life;
    var float MaxLife;
    var float Size;
    var byte ColorR;
    var byte ColorG;
    var byte ColorB;
};

var array<UnlockParticle> UnlockParticles;

// ===================================================================
// EXISTING PERK TRACKER SYSTEM
// ===================================================================

struct PerkTrackerData
{
    var string PerkName;
    var int CurrentValue;
    var int MaxValue;
    var bool bIsActive;
    var float DisplayTime;
    var Texture2D PerkIcon;
    var Color TextColor;
    var Color BackgroundColor;
    var string DisplayText;
};

var array<PerkTrackerData> PerkTrackers;

var float TrackerStartX;
var float TrackerStartY;
var float TrackerSpacing;
var float TrackerWidth;
var float TrackerHeight;

var Font TrackerFont;
var float TextScale;

// ===================================================================
// THE WATCHER - Easter Egg Visual Effects System
// ===================================================================

// Watcher effect state
struct WatcherEffectState
{
    var bool bIsActive;
    var int CurrentStage;
    var float VignetteIntensity;
    var float StaticIntensity;
    var bool bShowSubliminal;
    var float SubliminalTimer;
    var string SubliminalText;
    var float SubliminalPosX;
    var float SubliminalPosY;
    var bool bScreenDim;
    var float DimTimer;
    var bool bColorInvert;
    var float InvertTimer;
    var float ScanLineY;
    var bool bShowScanLine;
    var float HeartbeatTimer;
    var float AmbientTimer;
};

// Watcher system variables
var WatcherEffectState WatcherState;

// Eye data stored as parallel arrays (no bool arrays - use byte instead)
var int WatcherEyeCount;
var float WatcherEyePosX[16];
var float WatcherEyePosY[16];
var float WatcherEyeSize[16];
var float WatcherEyeAlpha[16];
var float WatcherEyePupilX[16];
var float WatcherEyePupilY[16];
var byte WatcherEyeBlinking[16];
var float WatcherEyeBlinkTimer[16];

// Watcher eye colors
var Color WatcherEyeColorOuter;
var Color WatcherEyeColorSclera;
var Color WatcherEyeColorIris;
var Color WatcherEyeColorPupil;

// Watcher subliminal messages
var array<string> WatcherSubliminalMessages;

// ===================================================================
// EVENT WAVE OVERLAY SYSTEM
// ===================================================================

var byte EventWaveOverlayID;         // Currently rendering event (0=none, matches GRI)
var float EventWaveAlpha;            // Master fade alpha (0..1)
var float EventWaveStartTimeLocal;   // Local TimeSeconds when event started (for Eclipse)
var float EventWaveBannerTimer;      // Countdown for announcement banner
var bool bEventWaveFadingOut;        // True when wave ended, fading out

// Client-local swap timing for the targeted-event countdown. Keyed off the
// replicated EventWaveTargetPRI change so it is immune to clock differences.
var PlayerReplicationInfo CachedEventTargetPRI;
var float CachedEventSwapTime;
var bool bIsolationActive;           // True when other player pawns are hidden
var bool bDeadSilenceActive;         // True when audio is muted
var bool bRedactedHUDHidden;         // True when Flash HUD is hidden by Redacted
var bool bZedFormHidHUD;             // True when the zed-form HUD hid the Flash HUD
var float ParanoiaSoundTimer;        // Countdown to next fake zed sound

const EVENT_FADE_IN_TIME = 3.0;
const EVENT_FADE_OUT_TIME = 2.0;
const EVENT_BANNER_DURATION = 5.0;

// ===================================================================
// SHAPESHIFTER BUFF DISPLAY SYSTEM
// ===================================================================

struct ShapeshifterDisplayData
{
    var bool bIsActive;         // Whether display is visible
    var bool bIsMimicry;        // Mimicry mode vs normal
    // Buff 1
    var int Buff1Index;
    var string Buff1Name;
    var string Buff1Desc;
    // Buff 2 (only in normal mode, rank 10+)
    var int Buff2Index;
    var string Buff2Name;
    var string Buff2Desc;
    // Mimicry
    var int MimicryStack;
    var int MimicryMax;
    // Bitmask of collected buffs (bit N = buff N active)
    var int BuffMask;
};

var ShapeshifterDisplayData ShapeshifterDisplay;

// Dev stat overlay mode (set via ZTCheatManager exec StatOverlay)
// 0 = Off, 1 = Basic (values only), 2 = Sources (per-upgrade attribution)
var byte StatOverlayMode;

// Total Stat Increase panel toggle (Phase 1 of ZTStatAggregator).
// Toggled via ZTPlayerController.ToggleStats() exec, or `mutate stats`.
var bool bShowStatPanel;

// Compact bottom-center summary of bonuses that currently apply to the local
// player. The upgrade scan is throttled; every frame only draws cached text.
var float AppliedStatsNextRefreshTime;
var array<string> AppliedStatsLines;
// Owner-local state for event-driven Parry, whose helper actor is not always
// discoverable on the owning client.
var bool bParryStatBuffActive;
var float ParryStatBuffExpiresAt;

// Shapeshifter display positioning
var float ShapeshifterDisplayX;     // Normalized X position
var float ShapeshifterDisplayY;     // Normalized Y position
var float ShapeshifterIconSize;     // Icon size in pixels

// ===================================================================
// GAMBIT CHALLENGE DISPLAY SYSTEM
// ===================================================================

struct GambitDisplayData
{
    var bool bIsActive;         // Whether display is visible
    var bool bCompleted;        // Challenge completed this wave
    var byte Rarity;            // 0=Normal, 1=Rare, 2=Legendary, 3=Mythic
    var byte GambitIndex;       // Index into gambit pool (0-13) for icon lookup
    var string GambitName;      // e.g. "[R] Perfectionist"
    var string Description;     // e.g. "70%+ headshot ratio (min 11 kills)"
    var string ProgressString;  // e.g. "5 / 11 kills"
    var string SecondaryInfo;   // e.g. "HS Ratio: 62% (need 70%)"
    var int Progress;           // Current progress value
    var int Target;             // Target value
    var int Completions;        // Total lifetime completions
    var float AccDamage;        // Accumulated damage bonus
    var float AccSpeed;         // Accumulated speed bonus
};

var GambitDisplayData GambitDisplay;

// Gambit display positioning (legacy - kept for reference, actual position from card stack)
var float GambitDisplayX;       // Normalized X position (unused, see DisplayCardBaseX)
var float GambitDisplayY;       // Normalized Y position (unused, see DisplayCardBaseY)

// ===================================================================
// JEKYLL & HYDE - serum meter card (top-center). The client records its
// own EndTime so DrawHydeDisplay can animate the red bar smoothly each
// frame, independent of replication cadence.
// ===================================================================
struct HydeDisplayData
{
    var bool  bIsActive;
    var byte  State;       // 1 = ready (Jekyll), 2 = transformed (Hyde)
    var float EndTime;     // local TimeSeconds when Hyde ends
    var float Duration;
    var int   Charges;
    var int   MaxCharges;
};
var HydeDisplayData HydeDisplay;
var bool bHideHydeCard;

// ===================================================================
// Domain "Room" perk card. One card, three states, client-animated bar:
//   0 = Ready (off cooldown), 1 = Active (room duration draining),
//   2 = Cooldown (recharge draining). EndTime/Duration drive the bar locally
//   so it animates smoothly regardless of RPC cadence.
// ===================================================================
struct DomainDisplayData
{
    var bool  bIsActive;
    var byte  State;       // 0 = ready, 1 = active(duration), 2 = cooldown
    var float EndTime;     // local TimeSeconds when current phase ends
    var float Duration;    // length of current phase (for the bar fraction)
};
var DomainDisplayData DomainDisplay;
var bool bHideDomainCard;

// ===================================================================
// Speedster "Blink Strike" perk card. Same three-state, client-animated
// shape as Domain: 0 = Ready (off cooldown), 1 = Active (brief dash),
// 2 = Cooldown (recharge draining). EndTime/Duration drive the bar locally.
// ===================================================================
struct SpeedsterDisplayData
{
    var bool  bIsActive;
    var byte  State;       // 0 = ready, 1 = active, 2 = cooldown
    var float EndTime;     // local TimeSeconds when current phase ends
    var float Duration;    // length of current phase (for the bar fraction)
};
var SpeedsterDisplayData SpeedsterDisplay;
var bool bHideSpeedsterCard;

// ===================================================================
// Possessor "Possession" perk card. Same three-state, client-animated
// shape as Speedster: 0 = Ready (off cooldown), 1 = Possessing (timer
// draining in real time, remaining seconds shown), 2 = Cooldown
// (recharge draining). EndTime/Duration drive the bar locally.
// ===================================================================
struct PossessorDisplayData
{
    var bool  bIsActive;
    var byte  State;       // 0 = ready, 1 = possessing, 2 = cooldown
    var float EndTime;     // local TimeSeconds when current phase ends
    var float Duration;    // length of current phase (for the bar fraction)
};
var PossessorDisplayData PossessorDisplay;
var bool bHidePossessorCard;

// ===================================================================
// DISPLAY CARD STACKING SYSTEM
// ===================================================================
// Generic slot-based system for vertically stacking rich HUD display
// cards (Shapeshifter, Gambit, future perks). Each card registers a
// slot; positions are computed top-to-bottom each frame so cards
// never overlap regardless of which combination is active.
//
// To add a new card perk, see HUD_Element_Guide.md
// ===================================================================

const CARD_SHAPESHIFTER = 0;
const CARD_GAMBIT       = 1;
const CARD_ARTIFICER    = 2;
const CARD_PREDATOR     = 3;
const CARD_OMEN         = 4;
const CARD_HOLLOW       = 5;
const CARD_METRONOME    = 6;
const CARD_DETONATOR    = 7;
const CARD_HYDE         = 8;
const CARD_DOMAIN       = 9;
const CARD_SPEEDSTER    = 10;
const CARD_POSSESSOR    = 11;

struct DisplayCardSlot
{
    var byte CardType;      // CARD_SHAPESHIFTER, CARD_GAMBIT, etc.
    var float HeightPx;     // Pixel height computed this frame
    var float DrawY;        // Computed normalized Y position for this card
};

var array<DisplayCardSlot> ActiveDisplayCards;
var float DisplayCardBaseX;     // Shared X for all display cards (normalized)
var float DisplayCardBaseY;     // Y where the first card starts (normalized)
var float DisplayCardGapPx;     // Pixel gap between stacked cards

// Card visibility toggles (set via exec commands)
var bool bHideShapeshifterCard;
var bool bHideGambitCard;
var bool bHideArtificerCard;
var bool bHidePredatorCard;
var bool bHideOmenCard;
var bool bHideHollowCard;

// ===================================================================
// GAMBIT BUFFS OVERLAY - shown via console command "GambitBuffs"
// ===================================================================

struct GambitBuffSnapshot
{
    var int Completions;
    var int Dosh;
    var float Damage;
    var float Speed;
    var float Reload;
    var float Recoil;
    var float MagSize;
    var float SpareAmmo;
};

var bool bShowGambitBuffs;              // True while overlay is visible
var GambitBuffSnapshot GambitBuffData;  // Snapshot taken when command fires
var float GambitBuffsShowTime;          // WorldInfo.TimeSeconds when shown
var float GambitBuffsDuration;          // How long to display (seconds)


// ===================================================================
// ARTIFICER FORGE DISPLAY SYSTEM
// ===================================================================

struct ArtificerDisplayData
{
    var bool bIsActive;
    var byte DisplayMode;       // 0=Progress, 1=ReforgeUnlock, 2=MasteryComplete
    var byte Phase;             // 0=Reforge unlock tracking (orange), 1=Mastery tracking (gold)
    var string WeaponName;      // Normalized weapon display name
    var int KillCount;          // Current kills on this weapon
    var int KillTarget;         // Kills needed for next milestone
    var int MilestoneNum;       // How many milestones completed on this weapon
    var string RollsString;     // Pre-formatted stat roll results (Mode 2)
    var float NotifyTimer;      // Countdown for timed notifications (Modes 1 & 2)
};

var ArtificerDisplayData ArtificerDisplay;

// ===================================================================
// PREDATOR TROPHY DISPLAY SYSTEM
// ===================================================================

struct PredatorDisplayData
{
    var bool bIsActive;
    var byte TrophyCount[11];
    var byte TotalTrophies;
    var int CompletedSets;
    var byte CompletedSetsCount;
    var bool bTrophyMaster;
    var bool bStackingPhase;
    var float AccAllDamage;
    var float AccLargeZedDamage;
    var float AccDamageResist;
    var float AccSpeed;
    var float AccReload;
    var float AccMeleeDamage;
    var float AccMagSize;
    var float AccWeaponSwitch;
    var float AccSpareAmmo;
    var float AccHeadshotDamage;
    var int StackBonusHP;
    var int StackBonusArmor;
    var int StackBonusDosh;
    var bool bCanNotBeGrabbed;
    var bool bCanSeeEnemyHealth;
    var byte MaxSlots;
};

var PredatorDisplayData PredatorDisplay;
var bool bShowPredatorTrophies;             // True while trophy overlay is visible
var float PredatorTrophiesShowTime;         // WorldInfo.TimeSeconds when shown
var float PredatorTrophiesDuration;         // How long to display (seconds)

// ===================================================================
// OMEN PROPHECY DISPLAY SYSTEM
// ===================================================================

struct OmenDisplayData
{
    var bool bIsActive;
    var byte State;             // 0=active prophecy, 1=blessing complete, 2=doom, 3=deny fate
    var byte Tier;              // 1, 2, or 3
    var byte IconIndex;         // Index into GetProphecyIcon (maps to EProphecyCondition)
    var string Title;           // Prophecy name
    var string Condition;       // Blessing condition text (or status message)
    var string Reward;          // Reward summary string
    var string Doom;            // Doom punishment text
    var string Whisper;         // Cryptic whisper (Level 10+)
    var float StateTimer;       // Countdown for transient states (blessing/doom flash)
};

var OmenDisplayData OmenDisplay;

// ===================================================================
// HOLLOW TRIAL DISPLAY SYSTEM
// Shows current weapon trial conditions, progress bars, and unlock
// notifications for the Hollow perk's weapon transformation system.
// ===================================================================

struct HollowDisplayData
{
    var bool bIsActive;
    var byte DisplayMode;       // 0=Progress, 1=ConditionComplete, 2=WeaponUnlock
    var string WeaponName;      // Normalized weapon display name
    var byte ActiveCondition;   // Which of 5 conditions is being tracked (0-4, or NUM_CONDITIONS=done)
    var int Progress;           // Current progress toward active condition
    var int Target;             // Target count for active condition
    var byte bIsMelee;          // 1 if weapon is melee (affects condition labels)
    var float NotifyTimer;      // Countdown for timed notifications (Modes 1 & 2)
    var byte CompletedIdx;      // Which condition index just completed (Mode 1)
};

var HollowDisplayData HollowDisplay;

// Call of the Void: client-side shatter threshold cache
// Populated via RPC from Helper on unlock + respawn
struct SShatterCache
{
    var string NormName;
    var float Threshold;
};
var array<SShatterCache> HollowShatterCache;

// ===================================================================
// METRONOME PHASE DISPLAY SYSTEM
// ===================================================================

struct MetronomeDisplayData
{
    var bool bIsActive;
    var byte CurrentPhase;      // 0=Assault, 1=Tempo, 2=Momentum, 3=Bastion
    var byte PhaseTimePct;      // 0-100 percentage of phase remaining
    var byte SyncKills;         // Sync kills this phase
    var byte SyncTarget;        // Sync kills needed for bonus
    var byte Stacks_0;          // Permanent stacks: Assault
    var byte Stacks_1;          // Permanent stacks: Tempo
    var byte Stacks_2;          // Permanent stacks: Momentum
    var byte Stacks_3;          // Permanent stacks: Bastion
    var bool bHarmonyActive;    // Level 10 overlap active
    var byte HarmonyPhase;      // Which phase is overlapping (255=none)
    var bool bCrescendoActive;  // Level 20 burst active
};

var MetronomeDisplayData MetronomeDisplay;
var bool bHideMetronomeCard;

// ===================================================================
// DETONATOR DISPLAY SYSTEM
// ===================================================================

struct DetonatorDisplayData
{
    var bool bIsActive;         // Whether display is visible
    var bool bWindowActive;     // Active mode (true) vs charging mode (false)
    var byte PerkLevel;         // For icon ranking
    var int Counter;            // Current charge progress
    var int Threshold;          // Target charge value to flip to active
    var byte SecondsLeft;       // Active window seconds remaining
    var byte MaxSeconds;        // Active window total duration
    var int ApexBank;           // Pre-charge banked from Deluxe Apex Charge
};

var DetonatorDisplayData DetonatorDisplay;
var bool bHideDetonatorCard;

// Paranoia sounds (Event Wave)
var array<AkEvent> ParanoiaSounds;
var bool bParanoiaSoundsLoaded;


// ===================================================================
// LOCALIZED HUD STRINGS
// ===================================================================
// Class-scope `localized` vars auto-populate from the active locale's
// .int / .kor / etc. file under the [ZTHudWrapper] section at engine
// startup. defaultproperties values below are the English fallbacks
// (used when no .int entry overrides them).
//
// To add a translation: edit ZedternalTempered.<lang> directly
// (UTF-16 LE BOM) or run ZU_AddDKMessagesSection.py after registering
// the new key in the script.
// ===================================================================

// --- Side-panel perk tracker labels (set in Initialize*Tracking) ---
var localized string Reaper_Display;
var localized string Symbiote_Display;
var localized string SymbioteEvolutions_Display;
var localized string Scavenger_Display;
var localized string ScavengerAdaptations_Display;
var localized string Tycoon_Display;
var localized string TycoonPortfolio_Display;
var localized string ForgeWarden_Display;
var localized string ForgeWardenGrenades_Display;
var localized string Hydra_Display;
var localized string WendigoStalk_Display;
var localized string WendigoAmbush_Display;
var localized string WendigoApex_Display;
var localized string Archangel_Display;
var localized string ArchangelHealing_Display;
var localized string Medusa_Display;
var localized string MedusaScales_Display;
var localized string CryophiliteIcicle_Display;
var localized string CryophiliteAbsolute_Display;
var localized string CinderBurning_Display;
var localized string CinderKills_Display;
var localized string CinderPhoenix_Display;
var localized string HivemindNetwork_Display;
var localized string HivemindSwarm_Display;
var localized string HivemindActive_Display;
var localized string ParasiteSiphon_Display;
var localized string ParasiteHarvest_Display;
var localized string ParasiteDrain_Display;
var localized string ShapeshifterBuff1_Display;
var localized string ShapeshifterMimicry_Display;
var localized string Riot_Display;
var localized string Agony_Display;

// --- State-change tracker labels (used in Update*Tracking branches) ---
var localized string Riot_ActiveText;
var localized string Wendigo_AmbushTriggered;
var localized string Wendigo_ApexHunter;
var localized string Medusa_FullGorgon;
var localized string MedusaScales_FullGorgon;

// --- Dynamic tracker text templates (use with Repl on %1/%2/%3) ---
var localized string Agony_ZedTimeFormat;     // "ZED TIME: %1s total | %2s to reward"
var localized string Agony_TotalFormat;       // "Total: %1s | Rewards: %2 (+%3 dosh)"
var localized string MedusaScales_Format;     // "Scales +%1% resist +%2% speed"

// --- ChainNotification title+body pairs (TriggerChainNotification calls) ---
var localized string ChainTitle_Icicle;
var localized string ChainBody_Icicle;
var localized string ChainTitle_AbsoluteZero;
var localized string ChainBody_AbsoluteZero;
var localized string ChainTitle_HydraBarrage;
var localized string ChainBody_HydraBarrage;
var localized string ChainTitle_DivineService;
var localized string ChainBody_DivineService;
var localized string ChainTitle_GorgonAwakens;
var localized string ChainBody_GorgonAwakens;
var localized string ChainTitle_SerpentScale;
var localized string ChainBody_SerpentScale;
var localized string ChainTitle_WendigoAwakens;
var localized string ChainBody_WendigoAwakens;

// --- Misc instant-kill notification ---
var localized string InstantKill_Text;


// --- Hollow card labels ---
var localized string Hollow_Cond_Headshot;
var localized string Hollow_Cond_TotalKills;
var localized string Hollow_Cond_Collateral;
var localized string Hollow_Cond_Melee;
var localized string Hollow_Cond_Rapid;
var localized string Hollow_Cond_LargeZed;
var localized string Hollow_Cond_Complete;
var localized string Hollow_TrialComplete;
var localized string Hollow_WeaponUnlocked;
var localized string Hollow_Prefix;
var localized string Hollow_AllTrialsComplete;
var localized string Hollow_CallOfVoid;

// --- Metronome card labels ---
var localized string Metronome_Phase_Assault;
var localized string Metronome_Phase_Tempo;
var localized string Metronome_Phase_Momentum;
var localized string Metronome_Phase_Bastion;
var localized string Metronome_Phase_Unknown;
var localized string Metronome_Sync_Headshot;
var localized string Metronome_Sync_Rapid;
var localized string Metronome_Sync_Moving;
var localized string Metronome_Sync_Close;
var localized string Metronome_Crescendo;
var localized string Metronome_SyncLabel;
var localized string Metronome_RhythmBonus;
var localized string Metronome_AllPhases;
var localized string Metronome_HarmonyPrefix;

// --- Detonator card labels ---
var localized string Detonator_Active;
var localized string Detonator_Title;
var localized string Detonator_WindowLabel;
var localized string Detonator_ChargeLabel;
var localized string Detonator_ApexBankLabel;
var localized string Detonator_KillsSuffix;
var localized string Detonator_SecondsRemaining;

// --- Omen card label ---
var localized string Omen_DoomPrefix;

// --- Omen prophecy names (19 prophecies, indexed 0-18) ---
// Helper class ZTUpgrade_Perk_Omen_Helper sends ProphecyIndex via RPC;
// client looks up the localized name here so each player sees their own locale.
var localized string OmenName_0;   // Marksman's Oath
var localized string OmenName_1;   // Iron Discipline
var localized string OmenName_2;   // Unwavering
var localized string OmenName_3;   // Stoneskin
var localized string OmenName_4;   // Close Quarters
var localized string OmenName_5;   // Grounded
var localized string OmenName_6;   // Unyielding
var localized string OmenName_7;   // Untouched
var localized string OmenName_8;   // Pacifist's Paradox
var localized string OmenName_9;   // One Magazine
var localized string OmenName_10;  // Tunnel Vision
var localized string OmenName_11;  // Blind Faith
var localized string OmenName_12;  // Vow of Stillness
var localized string OmenName_13;  // Disarmed
var localized string OmenName_14;  // Executioner
var localized string OmenName_15;  // Ascetic
var localized string OmenName_16;  // Silence
var localized string OmenName_17;  // Trigger Discipline
var localized string OmenName_18;  // Lone Wolf

// --- Omen prophecy condition descriptions ---
var localized string OmenDesc_0;   // "Every shot must be a headshot"
var localized string OmenDesc_1;   // "Do not manually reload"
var localized string OmenDesc_2;   // "Do not sprint"
var localized string OmenDesc_3;   // "Receive no healing"
var localized string OmenDesc_4;   // "Do not damage zeds beyond 10 meters"
var localized string OmenDesc_5;   // "Do not jump"
var localized string OmenDesc_6;   // "Do not switch weapons"
var localized string OmenDesc_7;   // "Take no damage"
var localized string OmenDesc_8;   // "Deal no melee or bash damage"
var localized string OmenDesc_9;   // "One magazine per weapon - swap to reload"
var localized string OmenDesc_10;  // "No sudden turns beyond 90 degrees"
var localized string OmenDesc_11;  // "Do not aim down sights"
var localized string OmenDesc_12;  // "Stop moving for 1 second every 3 seconds"
var localized string OmenDesc_13;  // "Only use sidearm or knife"
var localized string OmenDesc_14;  // "Every killing blow must be a headshot"
var localized string OmenDesc_15;  // "Knife and bash only - no shooting"
var localized string OmenDesc_16;  // "Only shoot - no grenades, melee, jump, or sprint"
var localized string OmenDesc_17;  // "Max 3 shots, then 2 second cooldown"
var localized string OmenDesc_18;  // "Swap weapons between every attack"

// --- Omen whisper texts (cryptic flavor lines, capstone-only) ---
var localized string OmenWhisper_0;   // "The eye sees all that wanders..."
var localized string OmenWhisper_1;   // "Patience is a forgotten virtue..."
var localized string OmenWhisper_2;   // "Haste invites ruin..."
var localized string OmenWhisper_3;   // "Flesh mends; fate does not..."
var localized string OmenWhisper_4;   // "Only the bold survive what looms near..."
var localized string OmenWhisper_5;   // "The earth remembers those who leave it..."
var localized string OmenWhisper_6;   // "Loyalty to the blade is loyalty to yourself..."
var localized string OmenWhisper_7;   // "A single scratch unravels destiny..."
var localized string OmenWhisper_8;   // "The fist closes, and the world shudders..."
var localized string OmenWhisper_9;   // "Every bullet is a promise kept or broken..."
var localized string OmenWhisper_10;  // "Look only forward; the abyss flanks you..."
var localized string OmenWhisper_11;  // "Trust the hand, not the eye..."
var localized string OmenWhisper_12;  // "Motion is an illusion; stillness is truth..."
var localized string OmenWhisper_13;  // "Power discarded is power earned..."
var localized string OmenWhisper_14;  // "Death must be precise, or it is nothing..."
var localized string OmenWhisper_15;  // "Bare hands against the tide..."
var localized string OmenWhisper_16;  // "In silence, the gun speaks volumes..."
var localized string OmenWhisper_17;  // "Restraint carves the path to power..."
var localized string OmenWhisper_18;  // "No blade knows loyalty; neither should you..."

// --- Omen reward stat suffixes (each includes leading + trailing space
//     to match the original concat format " Dmg " " HS Dmg " etc.) ---
var localized string Omen_Stat_Damage;     // " Dmg "
var localized string Omen_Stat_HSDamage;   // " HS Dmg "
var localized string Omen_Stat_DR;         // " DR "
var localized string Omen_Stat_Reload;     // " Reload "
var localized string Omen_Stat_Speed;      // " Speed "
var localized string Omen_Stat_HP;         // " HP " (gaming term, typically kept ASCII)
var localized string Omen_Stat_Armor;      // " Armor "

// --- Omen special state strings (hidden prophecy / blessing / doom / DoN / Deny Fate) ---
var localized string Omen_Hidden_Title;       // "Hidden Prophecy"
var localized string Omen_Hidden_Cond;        // "???"
var localized string Omen_Hidden_Whisper;     // "Fate speaks in silence..."
var localized string Omen_BlessingComplete;   // "BLESSING COMPLETE"
var localized string Omen_DoomStatePrefix;    // "DOOM - "
var localized string Omen_DON_Title;          // "Double or Nothing"
var localized string Omen_DON_NothingCond;    // "NOTHING!"
var localized string Omen_DON_NothingWhisper; // "The coin betrays you..."
var localized string Omen_DenyFate_Title;     // "Deny Fate"
var localized string Omen_DenyFate_Cond;      // "Doom has been denied!"
var localized string Omen_DenyFate_Whisper;   // "Fate bends to your will..."

// --- Event Wave UI ---
var localized string EventWave_Subtitle;
var localized string EventWave_TargetVIP;
var localized string EventWave_TargetActive;
var localized string EventWave_TargetMarked;
var localized string EventWave_Redacted;

// Persistent on-screen targeted-event indicator (VIP/Hot Potato/Highlander/Marked)
var localized string EventWave_HudVIP;
var localized string EventWave_HudPotato;
var localized string EventWave_HudHighlander;
var localized string EventWave_HudMarked;
var localized string EventWave_SelfVIP;
var localized string EventWave_SelfPotato;
var localized string EventWave_SelfHighlander;
var localized string EventWave_SelfMarked;

// --- Watcher subliminal messages ---
var localized string Watcher_Subliminal_1;
var localized string Watcher_Subliminal_2;
var localized string Watcher_Subliminal_3;
var localized string Watcher_Subliminal_4;
var localized string Watcher_Subliminal_5;
var localized string Watcher_Subliminal_6;
var localized string Watcher_Subliminal_7;
var localized string Watcher_Subliminal_8;

// --- Shapeshifter card extras ---
var localized string Shapeshifter_PermanentStacking;

// --- Shapeshifter buff names (15 buffs, indexed 0-14) ---
// Helper class ZTUpgrade_Perk_Shapeshifter_Helper sends Buff1Index/Buff2Index;
// client looks up the localized name here so each player sees their own locale.
var localized string ShapeshifterBuff_0;   // Carnage
var localized string ShapeshifterBuff_1;   // Executioner
var localized string ShapeshifterBuff_2;   // Rampage
var localized string ShapeshifterBuff_3;   // Crusher
var localized string ShapeshifterBuff_4;   // Berserker
var localized string ShapeshifterBuff_5;   // Fortress
var localized string ShapeshifterBuff_6;   // Leech
var localized string ShapeshifterBuff_7;   // Anchor
var localized string ShapeshifterBuff_8;   // Hawk
var localized string ShapeshifterBuff_9;   // Speedloader
var localized string ShapeshifterBuff_10;  // Switchblade
var localized string ShapeshifterBuff_11;  // Speedfreak
var localized string ShapeshifterBuff_12;  // Hoarder
var localized string ShapeshifterBuff_13;  // Drumfire
var localized string ShapeshifterBuff_14;  // Phantom

// --- Shapeshifter stat suffixes (15 buffs, mirrors GetBuffDescription) ---
// The helper sends Buff1Desc with the format "<sign><value>[%] <Stat>".
// Client extracts the numeric prefix and substitutes the localized stat name.
var localized string ShapeshifterStat_0;   // Damage
var localized string ShapeshifterStat_1;   // Headshot Dmg
var localized string ShapeshifterStat_2;   // Fire Rate
var localized string ShapeshifterStat_3;   // Heavy Melee
var localized string ShapeshifterStat_4;   // Melee Speed
var localized string ShapeshifterStat_5;   // Damage Taken
var localized string ShapeshifterStat_6;   // HP on Kill
var localized string ShapeshifterStat_7;   // Recoil
var localized string ShapeshifterStat_8;   // Spread
var localized string ShapeshifterStat_9;   // Reload Speed
var localized string ShapeshifterStat_10;  // Switch Speed
var localized string ShapeshifterStat_11;  // Move Speed
var localized string ShapeshifterStat_12;  // Spare Ammo
var localized string ShapeshifterStat_13;  // Mag Size
var localized string ShapeshifterStat_14;  // ZED Fire Rate

// --- Shapeshifter popup message templates ---
// Used by ZTPlayerController.ClientShapeshifterMimicryGain / ...Transform
// to build localized popup messages from server-sent buff indices.
// %1 = Buff1 name, %2 = Buff1 desc, %3 = StackCount or Buff2 name, %4 = Buff2 desc
var localized string Shapeshifter_MimicryTemplate;          // "Mimicry +%1 (%2) [%3/15]"
var localized string Shapeshifter_TransformSingleTemplate;  // "Shapeshifted: %1 (%2)"
var localized string Shapeshifter_TransformDualTemplate;    // "Shapeshifted: %1 (%2) + %3 (%4)"

// --- Gambit card extras ---
var localized string Gambit_CompletePrefix;

// --- Gambit names (14 gambits, indexed 0-13) ---
// Helper class ZTUpgrade_Perk_Gambit_Helper sends GambitIndex via RPC;
// client looks up the localized name here so each player sees their own locale.
var localized string GambitName_0;   // Marksman
var localized string GambitName_1;   // Body Count
var localized string GambitName_2;   // Iron Skin
var localized string GambitName_3;   // Blitz
var localized string GambitName_4;   // Big Game
var localized string GambitName_5;   // Perfectionist
var localized string GambitName_6;   // Untouchable
var localized string GambitName_7;   // Rapid Fire
var localized string GambitName_8;   // Desperado
var localized string GambitName_9;   // Deadeye
var localized string GambitName_10;  // Flawless
var localized string GambitName_11;  // Endurance
var localized string GambitName_12;  // Impossible Odds
var localized string GambitName_13;  // One Bullet

// --- Gambit description templates (mirrors GambitPool[N].DescTemplate) ---
// %t = computed target value (substituted client-side)
// %s = secondary param (substituted client-side)
var localized string GambitDesc_0;   // "Get %t headshot kills"
var localized string GambitDesc_1;   // "Kill %t zeds"
var localized string GambitDesc_2;   // "Take no more than %t damage"
var localized string GambitDesc_3;   // "Kill %t zeds in the first 60 seconds"
var localized string GambitDesc_4;   // "Kill %t large zed(s)"
var localized string GambitDesc_5;   // "70%+ headshot ratio (min %t kills)"
var localized string GambitDesc_6;   // "Take zero damage the entire wave"
var localized string GambitDesc_7;   // "Get %t kills within 8 seconds"
var localized string GambitDesc_8;   // "Kill %t zeds while below 30%% health"
var localized string GambitDesc_9;   // "Kill %t large zeds with headshots"
var localized string GambitDesc_10;  // "90%+ HS ratio, min %t kills, <50 dmg taken"
var localized string GambitDesc_11;  // "Kill %t zeds with max 3 reloads"
var localized string GambitDesc_12;  // "Kill a large zed with your sidearm"
var localized string GambitDesc_13;  // "Kill %t zeds without reloading"

// --- Gambit rarity tier names (used in popups and card display) ---
// The bracketed tags [N]/[R]/[L]/[M] are kept ASCII (no localization).
var localized string GambitRarity_Normal;
var localized string GambitRarity_Rare;
var localized string GambitRarity_Legendary;
var localized string GambitRarity_Mythic;

// --- Gambit progress strings (BuildProgressString switch outputs) ---
var localized string Gambit_Progress_Complete;        // "COMPLETE!"
var localized string Gambit_Progress_BudgetRemaining; // " budget remaining"
var localized string Gambit_Progress_Kills;           // "kills"
var localized string Gambit_Progress_Clean;           // "Clean!"
var localized string Gambit_Progress_Hit;             // "HIT!"
var localized string Gambit_Progress_Done;            // "DONE!"
var localized string Gambit_Progress_Waiting;         // "Waiting..."

// --- Gambit secondary strings (BuildSecondaryString switch outputs) ---
var localized string Gambit_Secondary_SecondsRemaining; // "s remaining"
var localized string Gambit_Secondary_TimeExpired;      // "Time expired"
var localized string Gambit_Secondary_HSRatio;          // "HS Ratio: "
var localized string Gambit_Secondary_HSRatioNeed;      // "% (need "
var localized string Gambit_Secondary_HSRatioClose;     // "%)"
var localized string Gambit_Secondary_HSPrefix;         // "HS: "
var localized string Gambit_Secondary_DmgSep;           // "% | DMG: "
var localized string Gambit_Secondary_DmgMax;           // "/50"
var localized string Gambit_Secondary_Reloads;          // "Reloads: "

// --- Gambit popup message templates ---
// Used by ZTPlayerController.ClientGambit* RPCs to build localized popups.
// %1 = rarity, %2 = gambit name, %3 = description (start only)
var localized string Gambit_StartTemplate;            // "[%1] GAMBIT: %2 - %3"
var localized string Gambit_AutoCompleteTemplate;     // "GAMBIT COMPLETE: %1 - Reward claimed!"
var localized string Gambit_ExpiredTemplate;          // "GAMBIT EXPIRED: %1 - Better luck next wave!"
var localized string Gambit_MidWaveCompleteTemplate;  // "GAMBIT COMPLETE! %1"

// --- Gambit reward popup ---
// %1 = constructed reward components (DMG/Dosh/SPD strings joined)
var localized string Gambit_RewardTemplate;           // "REWARD: %1"
var localized string Gambit_Reward_Damage;            // " DMG"
var localized string Gambit_Reward_Dosh;              // " Dosh"
var localized string Gambit_Reward_Speed;             // " SPD"
var localized string Gambit_Reward_NoReward;          // "No reward (Double or Nothing bust)"
var localized string Gambit_Reward_CardSharkPrefix;   // " Dosh (Card Shark x"
var localized string Gambit_Reward_CardSharkSuffix;   // ")"

// --- Gambit Buffs Overlay ---
var localized string GambitBuffs_Header;
var localized string GambitBuffs_CompletionsLabel;
var localized string GambitBuffs_NoBuffs;
var localized string GambitBuffs_Damage;
var localized string GambitBuffs_Speed;
var localized string GambitBuffs_Reload;
var localized string GambitBuffs_Recoil;
var localized string GambitBuffs_MagSize;
var localized string GambitBuffs_SpareAmmo;
var localized string GambitBuffs_DoshEarned;

// --- Artificer card labels ---
var localized string Artificer_ForgingPrefix;
var localized string Artificer_MasteryPrefix;
var localized string Artificer_KillsPrefix;
var localized string Artificer_MilestonePrefix;
var localized string Artificer_UnlockReforged;
var localized string Artificer_Reforged;
var localized string Artificer_NowAvailable;
var localized string Artificer_MasteryNumPrefix;

// --- Predator card labels ---
var localized string Predator_Title;
var localized string Predator_Stacking;
var localized string Predator_SetsLabel;
var localized string Predator_EndlessHunt;
var localized string Predator_AllDamage;
var localized string Predator_LargeZedDamage;
var localized string Predator_HeadshotDamage;
var localized string Predator_DamageTaken;
var localized string Predator_MovementSpeed;
var localized string Predator_ReloadSpeed;
var localized string Predator_MeleeDamage;
var localized string Predator_MagazineSize;
var localized string Predator_WeaponSwitch;
var localized string Predator_SpareAmmo;
var localized string Predator_MaxHP;
var localized string Predator_MaxArmor;
var localized string Predator_DoshPerWave;
var localized string Predator_GrabImmunity;
var localized string Predator_SeeEnemyHealth;

// --- Predator Trophy Overlay extras ---
var localized string PredatorOverlay_TitlePrefix;
var localized string PredatorOverlay_SetsPrefix;
var localized string PredatorOverlay_SetsCompleted;
var localized string PredatorOverlay_BonusesHeader;

// --- Predator set names (GetPredatorSetName) ---
var localized string Predator_Set0;
var localized string Predator_Set1;
var localized string Predator_Set2;
var localized string Predator_Set3;
var localized string Predator_Set4;
var localized string Predator_Set5;
var localized string Predator_Set6;
var localized string Predator_Set7;
var localized string Predator_Set8;
var localized string Predator_Set9;
var localized string Predator_Set10;
var localized string Predator_Set11;
var localized string Predator_SetUnknown;

// ===================================================================
// ===================================================================
// INITIALIZATION
// ===================================================================

simulated function PostBeginPlay()
{
    Super.PostBeginPlay();
    
    // Load HUD preferences from client INI
    LoadHudPreferences();
    
    // Initialize tracker positioning
    TrackerStartX = 0.75f;
    TrackerStartY = 0.25f;
    TrackerSpacing = 0.08f;
    TrackerWidth = 200.0f;
    TrackerHeight = 40.0f;
    
    TextScale = 0.8f;
    
    InitializeReaperTracking();
    InitializeSymbioteTracking();
    InitializeScavengerTracking();
    InitializeTycoonTracking();
    InitializeForgeWardenTracking();
    InitializeHydraTracking();
    InitializeWendigoTracking();
    InitializeArchangelTracking();
    InitializeMedusaTracking();
    InitializeCryophiliteTracking();
    InitializeRiotTracking();
    InitializeAgonyTracking();
    
    InitializeCinderTracking();
    InitializeHivemindTracking();
    InitializeParasiteTracking();
    InitializeShapeshifterTracking();
    InitializeGambitDisplay();
    InitializeArtificerDisplay();
    InitializePredatorDisplay();
    InitializeHollowDisplay();
    InitializeInstantKillNotification();
    InitializeChainNotification();
    InitializeEvolutionPanel();
    InitializeNotificationFeed();
    InitializeAbilityDisplay();
    InitializeAchievementPopup();
    

    // Initialize The Watcher easter egg system
    InitializeWatcherSystem();
    
    

}



function InitializeNotificationFeed()
{
    NotificationFeedX = 0.02f;
    NotificationFeedY = 0.30f;
    NotificationSpacing = 5.0f;
    NotificationMaxWidth = 600.0f;
    NotificationTextScale = 0.75f;
    MaxVisibleNotifications = 8;
    
    NotificationMessages.Length = 0;
    
    `log("ZTHudWrapper: Notification Feed initialized");
}

function InitializeAbilityDisplay()
{
    local int i;
    local AbilitySlotDisplay EmptySlot;
    
    AbilityDisplayX = 0.5f;
    AbilityDisplayY = 0.85f;
    AbilitySlotWidth = 70.0f;
    AbilitySlotHeight = 70.0f;
    AbilitySlotSpacing = 15.0f;
    
    AbilitySlots.Length = 0;
    EmptySlot.bHasAbility = false;
    EmptySlot.AbilityName = "";
    EmptySlot.AbilityIcon = None;
    EmptySlot.bIsActive = false;
    EmptySlot.bOnCooldown = false;
    EmptySlot.RemainingTime = 0.0f;
    EmptySlot.MaxTime = 0.0f;
    
    for (i = 0; i < 4; i++)
    {
        AbilitySlots.AddItem(EmptySlot);
    }
    
    `log("ZTHudWrapper: Active Ability Display initialized (4 slots)");
}

function InitializeAchievementPopup()
{
    AchievementPopup.AchievementName = "";
    AchievementPopup.Description = "";  // <-- ADDED: Initialize description
    AchievementPopup.AchievementIcon = None;
    AchievementPopup.DisplayTime = 0.0f;
    AchievementPopup.MaxDisplayTime = 8.0f;
    AchievementPopup.bIsActive = false;
    AchievementPopup.TitleColor = MakeColorFromRGB(255, 140, 0, 255); // Orange
    AchievementPopup.BackgroundColor = MakeColorFromRGB(0, 0, 0, 230);
    
    `log("ZTHudWrapper: Achievement Popup initialized");
}

function InitializeReaperTracking()
{
    local PerkTrackerData ReaperData;
    local int Index;
    
    ReaperData.PerkName = "Reaper";
    ReaperData.CurrentValue = 0;
    ReaperData.MaxValue = 100;
    ReaperData.bIsActive = false;
    ReaperData.DisplayTime = 0.0f;
    ReaperData.TextColor = MakeColorFromRGB(255, 215, 0, 255);
    ReaperData.BackgroundColor = MakeColorFromRGB(20, 20, 20, 180);
    ReaperData.DisplayText = Reaper_Display;
    
    ReaperData.PerkIcon = Texture2D'ZedternalRBPerkpackage_Resources.Textures.ReaperIcons.ReaperWidget';
    if (ReaperData.PerkIcon == None)
    {
        `log("Warning: ReaperWidget icon not found, using fallback display");
    }
    
    Index = FindTrackerIndex("Reaper");
    if (Index == INDEX_NONE)
    {
        PerkTrackers.AddItem(ReaperData);
    }
    else
    {
        PerkTrackers[Index] = ReaperData;
    }
}

function InitializeSymbioteTracking()
{
    local PerkTrackerData SymbioteData;
    local int Index;
    
    SymbioteData.PerkName = "Symbiote";
    SymbioteData.CurrentValue = 0;
    SymbioteData.MaxValue = 100;
    SymbioteData.bIsActive = false;
    SymbioteData.DisplayTime = 0.0f;
    SymbioteData.TextColor = MakeColorFromRGB(0, 255, 127, 255);
    SymbioteData.BackgroundColor = MakeColorFromRGB(10, 30, 10, 180);
    SymbioteData.DisplayText = Symbiote_Display;
    
    SymbioteData.PerkIcon = Texture2D'ZedternalRBPerkpackage_Resources.Textures.SymbioteIcons.SymbioteWidget';
    if (SymbioteData.PerkIcon == None)
    {
        `log("Warning: SymbioteWidget icon not found, using fallback display");
    }
    
    Index = FindTrackerIndex("Symbiote");
    if (Index == INDEX_NONE)
    {
        PerkTrackers.AddItem(SymbioteData);
    }
    else
    {
        PerkTrackers[Index] = SymbioteData;
    }
    
    SymbioteData.PerkName = "SymbioteEvolutions";
    SymbioteData.CurrentValue = 0;
    SymbioteData.MaxValue = 999;
    SymbioteData.bIsActive = false;
    SymbioteData.DisplayTime = 0.0f;
    SymbioteData.TextColor = MakeColorFromRGB(173, 255, 47, 255);
    SymbioteData.BackgroundColor = MakeColorFromRGB(20, 40, 20, 180);
    SymbioteData.DisplayText = SymbioteEvolutions_Display;
    SymbioteData.PerkIcon = SymbioteData.PerkIcon;
    
    Index = FindTrackerIndex("SymbioteEvolutions");
    if (Index == INDEX_NONE)
    {
        PerkTrackers.AddItem(SymbioteData);
    }
    else
    {
        PerkTrackers[Index] = SymbioteData;
    }
}

function InitializeScavengerTracking()
{
    local PerkTrackerData ScavengerData;
    local int Index;
    
    ScavengerData.PerkName = "Scavenger";
    ScavengerData.CurrentValue = 0;
    ScavengerData.MaxValue = 50;
    ScavengerData.bIsActive = false;
    ScavengerData.DisplayTime = 0.0f;
    ScavengerData.TextColor = MakeColorFromRGB(218, 165, 32, 255);
    ScavengerData.BackgroundColor = MakeColorFromRGB(25, 20, 10, 180);
    ScavengerData.DisplayText = Scavenger_Display;
    
    ScavengerData.PerkIcon = Texture2D'ZedternalRBPerkpackage_Resources.Textures.ScavengerIcons.ScavengerWidget';
    if (ScavengerData.PerkIcon == None)
    {
        `log("Warning: ScavengerWidget icon not found, using fallback display");
    }
    
    Index = FindTrackerIndex("Scavenger");
    if (Index == INDEX_NONE)
    {
        PerkTrackers.AddItem(ScavengerData);
    }
    else
    {
        PerkTrackers[Index] = ScavengerData;
    }
    
    ScavengerData.PerkName = "ScavengerAdaptations";
    ScavengerData.CurrentValue = 0;
    ScavengerData.MaxValue = 999;
    ScavengerData.bIsActive = false;
    ScavengerData.DisplayTime = 0.0f;
    ScavengerData.TextColor = MakeColorFromRGB(255, 215, 0, 255);
    ScavengerData.BackgroundColor = MakeColorFromRGB(30, 25, 15, 180);
    ScavengerData.DisplayText = ScavengerAdaptations_Display;
    ScavengerData.PerkIcon = ScavengerData.PerkIcon;
    
    Index = FindTrackerIndex("ScavengerAdaptations");
    if (Index == INDEX_NONE)
    {
        PerkTrackers.AddItem(ScavengerData);
    }
    else
    {
        PerkTrackers[Index] = ScavengerData;
    }
}

function InitializeTycoonTracking()
{
    local PerkTrackerData TycoonData;
    local int Index;
    
    TycoonData.PerkName = "Tycoon";
    TycoonData.CurrentValue = 0;
    TycoonData.MaxValue = 2500;
    TycoonData.bIsActive = false;
    TycoonData.DisplayTime = 0.0f;
    TycoonData.TextColor = MakeColorFromRGB(255, 215, 0, 255);
    TycoonData.BackgroundColor = MakeColorFromRGB(10, 30, 10, 180);
    TycoonData.DisplayText = Tycoon_Display;
    
    TycoonData.PerkIcon = Texture2D'ZedternalRBPerkpackage_Resources.Textures.TycoonIcons.TycoonWidget';
    if (TycoonData.PerkIcon == None)
    {
        `log("Warning: TycoonWidget icon not found, using fallback display");
    }
    
    Index = FindTrackerIndex("Tycoon");
    if (Index == INDEX_NONE)
    {
        PerkTrackers.AddItem(TycoonData);
    }
    else
    {
        PerkTrackers[Index] = TycoonData;
    }
    
    TycoonData.PerkName = "TycoonPortfolio";
    TycoonData.CurrentValue = 0;
    TycoonData.MaxValue = 999;
    TycoonData.bIsActive = false;
    TycoonData.DisplayTime = 0.0f;
    TycoonData.TextColor = MakeColorFromRGB(0, 255, 0, 255);
    TycoonData.BackgroundColor = MakeColorFromRGB(15, 35, 15, 180);
    TycoonData.DisplayText = TycoonPortfolio_Display;
    TycoonData.PerkIcon = TycoonData.PerkIcon;
    
    Index = FindTrackerIndex("TycoonPortfolio");
    if (Index == INDEX_NONE)
    {
        PerkTrackers.AddItem(TycoonData);
    }
    else
    {
        PerkTrackers[Index] = TycoonData;
    }
}

function InitializeForgeWardenTracking()
{
    local PerkTrackerData ForgeWardenData;
    local int Index;
    
    ForgeWardenData.PerkName = "ForgeWarden";
    ForgeWardenData.CurrentValue = 0;
    ForgeWardenData.MaxValue = 75;
    ForgeWardenData.bIsActive = false;
    ForgeWardenData.DisplayTime = 0.0f;
    ForgeWardenData.TextColor = MakeColorFromRGB(255, 69, 0, 255);
    ForgeWardenData.BackgroundColor = MakeColorFromRGB(25, 10, 5, 180);
    ForgeWardenData.DisplayText = ForgeWarden_Display;
    
    ForgeWardenData.PerkIcon = Texture2D'ZedternalRBPerkpackage_Resources.Textures.ForgeWardenIcons.ForgeWardenWidget';
    if (ForgeWardenData.PerkIcon == None)
    {
        `log("Warning: ForgeWardenWidget icon not found, using fallback display");
    }
    
    Index = FindTrackerIndex("ForgeWarden");
    if (Index == INDEX_NONE)
    {
        PerkTrackers.AddItem(ForgeWardenData);
    }
    else
    {
        PerkTrackers[Index] = ForgeWardenData;
    }
    
    ForgeWardenData.PerkName = "ForgeWardenGrenades";
    ForgeWardenData.CurrentValue = 0;
    ForgeWardenData.MaxValue = 999;
    ForgeWardenData.bIsActive = false;
    ForgeWardenData.DisplayTime = 0.0f;
    ForgeWardenData.TextColor = MakeColorFromRGB(255, 140, 0, 255);
    ForgeWardenData.BackgroundColor = MakeColorFromRGB(30, 15, 5, 180);
    ForgeWardenData.DisplayText = ForgeWardenGrenades_Display;
    ForgeWardenData.PerkIcon = ForgeWardenData.PerkIcon;
    
    Index = FindTrackerIndex("ForgeWardenGrenades");
    if (Index == INDEX_NONE)
    {
        PerkTrackers.AddItem(ForgeWardenData);
    }
    else
    {
        PerkTrackers[Index] = ForgeWardenData;
    }
}

function InitializeHydraTracking()
{
    local PerkTrackerData HydraData;
    local int Index;
    
    HydraData.PerkName = "Hydra";
    HydraData.CurrentValue = 0;
    HydraData.MaxValue = 75;
    HydraData.bIsActive = false;
    HydraData.DisplayTime = 0.0f;
    HydraData.TextColor = MakeColorFromRGB(255, 102, 0, 255);
    HydraData.BackgroundColor = MakeColorFromRGB(25, 10, 5, 180);
    HydraData.DisplayText = Hydra_Display;
    
    HydraData.PerkIcon = Texture2D'ZedternalRBPerkpackage_Resources.Textures.HydraIcons.HydraWidget';
    if (HydraData.PerkIcon == None)
    {
        `log("Warning: HydraWidget icon not found, using fallback display");
    }
    
    Index = FindTrackerIndex("Hydra");
    if (Index == INDEX_NONE)
    {
        PerkTrackers.AddItem(HydraData);
    }
    else
    {
        PerkTrackers[Index] = HydraData;
    }
}

function InitializeWendigoTracking()
{
    local PerkTrackerData WendigoData;
    local int Index;
    
    WendigoData.PerkName = "WendigoStalk";
    WendigoData.CurrentValue = 0;
    WendigoData.MaxValue = 15;
    WendigoData.bIsActive = false;
    WendigoData.DisplayTime = 0.0f;
    WendigoData.TextColor = MakeColorFromRGB(135, 206, 235, 255);
    WendigoData.BackgroundColor = MakeColorFromRGB(47, 79, 79, 180);
    WendigoData.DisplayText = WendigoStalk_Display;
    
    WendigoData.PerkIcon = Texture2D'ZedternalRBPerkpackage_Resources.Textures.WendigoIcons.WendigoWidget';
    if (WendigoData.PerkIcon == None)
    {
        `log("Warning: WendigoWidget icon not found, using fallback display");
    }
    
    Index = FindTrackerIndex("WendigoStalk");
    if (Index == INDEX_NONE)
    {
        PerkTrackers.AddItem(WendigoData);
    }
    else
    {
        PerkTrackers[Index] = WendigoData;
    }
    
    WendigoData.PerkName = "WendigoAmbush";
    WendigoData.CurrentValue = 0;
    WendigoData.MaxValue = 999;
    WendigoData.bIsActive = false;
    WendigoData.DisplayTime = 0.0f;
    WendigoData.TextColor = MakeColorFromRGB(173, 216, 230, 255);
    WendigoData.BackgroundColor = MakeColorFromRGB(70, 130, 180, 180);
    WendigoData.DisplayText = WendigoAmbush_Display;
    WendigoData.PerkIcon = WendigoData.PerkIcon;
    
    Index = FindTrackerIndex("WendigoAmbush");
    if (Index == INDEX_NONE)
    {
        PerkTrackers.AddItem(WendigoData);
    }
    else
    {
        PerkTrackers[Index] = WendigoData;
    }
    
    WendigoData.PerkName = "WendigoApex";
    WendigoData.CurrentValue = 0;
    WendigoData.MaxValue = 30;
    WendigoData.bIsActive = false;
    WendigoData.DisplayTime = 0.0f;
    WendigoData.TextColor = MakeColorFromRGB(240, 248, 255, 255);
    WendigoData.BackgroundColor = MakeColorFromRGB(25, 25, 112, 200);
    WendigoData.DisplayText = WendigoApex_Display;
    WendigoData.PerkIcon = WendigoData.PerkIcon;
    
    Index = FindTrackerIndex("WendigoApex");
    if (Index == INDEX_NONE)
    {
        PerkTrackers.AddItem(WendigoData);
    }
    else
    {
        PerkTrackers[Index] = WendigoData;
    }
}

function InitializeArchangelTracking()
{
    local PerkTrackerData ArchangelData;
    local int Index;
    
    ArchangelData.PerkName = "Archangel";
    ArchangelData.CurrentValue = 0;
    ArchangelData.MaxValue = 500;
    ArchangelData.bIsActive = false;
    ArchangelData.DisplayTime = 0.0f;
    ArchangelData.TextColor = MakeColorFromRGB(255, 215, 0, 255);
    ArchangelData.BackgroundColor = MakeColorFromRGB(25, 25, 40, 180);
    ArchangelData.DisplayText = Archangel_Display;
    
    ArchangelData.PerkIcon = Texture2D'ZedternalRBPerkpackage_Resources.Textures.ArchangelIcons.ArchangelWidget';
    if (ArchangelData.PerkIcon == None)
    {
        `log("Warning: ArchangelWidget icon not found, using fallback display");
    }
    
    Index = FindTrackerIndex("Archangel");
    if (Index == INDEX_NONE)
    {
        PerkTrackers.AddItem(ArchangelData);
    }
    else
    {
        PerkTrackers[Index] = ArchangelData;
    }
    
    ArchangelData.PerkName = "ArchangelHealing";
    ArchangelData.CurrentValue = 0;
    ArchangelData.MaxValue = 999;
    ArchangelData.bIsActive = false;
    ArchangelData.DisplayTime = 0.0f;
    ArchangelData.TextColor = MakeColorFromRGB(173, 255, 47, 255);
    ArchangelData.BackgroundColor = MakeColorFromRGB(30, 40, 30, 180);
    ArchangelData.DisplayText = ArchangelHealing_Display;
    ArchangelData.PerkIcon = ArchangelData.PerkIcon;
    
    Index = FindTrackerIndex("ArchangelHealing");
    if (Index == INDEX_NONE)
    {
        PerkTrackers.AddItem(ArchangelData);
    }
    else
    {
        PerkTrackers[Index] = ArchangelData;
    }
}

function InitializeMedusaTracking()
{
    local PerkTrackerData MedusaData;
    local int Index;
    
    MedusaData.PerkName = "Medusa";
    MedusaData.CurrentValue = 0;
    MedusaData.MaxValue = 2500;
    MedusaData.bIsActive = false;
    MedusaData.DisplayTime = 0.0f;
    MedusaData.TextColor = MakeColorFromRGB(139, 0, 139, 255);
    MedusaData.BackgroundColor = MakeColorFromRGB(25, 10, 25, 180);
    MedusaData.DisplayText = Medusa_Display;
    
    MedusaData.PerkIcon = Texture2D'ZedternalRBPerkpackage_Resources.Textures.MedusaIcons.MedusaWidget';
    if (MedusaData.PerkIcon == None)
    {
        `log("Warning: MedusaWidget icon not found, using fallback display");
    }
    
    Index = FindTrackerIndex("Medusa");
    if (Index == INDEX_NONE)
    {
        PerkTrackers.AddItem(MedusaData);
    }
    else
    {
        PerkTrackers[Index] = MedusaData;
    }
    
    MedusaData.PerkName = "MedusaScales";
    MedusaData.CurrentValue = 0;
    MedusaData.MaxValue = 6;
    MedusaData.bIsActive = false;
    MedusaData.DisplayTime = 0.0f;
    MedusaData.TextColor = MakeColorFromRGB(186, 85, 211, 255);
    MedusaData.BackgroundColor = MakeColorFromRGB(30, 15, 30, 180);
    MedusaData.DisplayText = MedusaScales_Display;
    MedusaData.PerkIcon = MedusaData.PerkIcon;
    
    Index = FindTrackerIndex("MedusaScales");
    if (Index == INDEX_NONE)
    {
        PerkTrackers.AddItem(MedusaData);
    }
    else
    {
        PerkTrackers[Index] = MedusaData;
    }
}

function InitializeCryophiliteTracking()
{
    local PerkTrackerData CryophiliteData;
    local int Index;
    
    CryophiliteData.PerkName = "CryophiliteIcicle";
    CryophiliteData.CurrentValue = 0;
    CryophiliteData.MaxValue = 10;
    CryophiliteData.bIsActive = false;
    CryophiliteData.DisplayTime = 0.0f;
    CryophiliteData.TextColor = MakeColorFromRGB(240, 248, 255, 255);
    CryophiliteData.BackgroundColor = MakeColorFromRGB(25, 25, 112, 180);
    CryophiliteData.DisplayText = CryophiliteIcicle_Display;
    
    CryophiliteData.PerkIcon = Texture2D'ZedternalRBPerkpackage_Resources.Textures.CryophiliteIcons.CryophiliteWidget';
    if (CryophiliteData.PerkIcon == None)
    {
        `log("Warning: CryophiliteWidget icon not found, using fallback display");
    }
    
    Index = FindTrackerIndex("CryophiliteIcicle");
    if (Index == INDEX_NONE)
    {
        PerkTrackers.AddItem(CryophiliteData);
    }
    else
    {
        PerkTrackers[Index] = CryophiliteData;
    }
    
    CryophiliteData.PerkName = "CryophiliteAbsolute";
    CryophiliteData.CurrentValue = 0;
    CryophiliteData.MaxValue = 20;
    CryophiliteData.bIsActive = false;
    CryophiliteData.DisplayTime = 0.0f;
    CryophiliteData.TextColor = MakeColorFromRGB(173, 216, 230, 255);
    CryophiliteData.BackgroundColor = MakeColorFromRGB(70, 130, 180, 180);
    CryophiliteData.DisplayText = CryophiliteAbsolute_Display;
    CryophiliteData.PerkIcon = CryophiliteData.PerkIcon;
    
    Index = FindTrackerIndex("CryophiliteAbsolute");
    if (Index == INDEX_NONE)
    {
        PerkTrackers.AddItem(CryophiliteData);
    }
    else
    {
        PerkTrackers[Index] = CryophiliteData;
    }
}

function InitializeCinderTracking()
{
    local PerkTrackerData CinderData;
    local int Index;
    
    // Tracker 1: Burning enemy count (Level 10+)
    CinderData.PerkName = "CinderBurning";
    CinderData.CurrentValue = 0;
    CinderData.MaxValue = 10; // Max 10 burning enemies
    CinderData.bIsActive = false;
    CinderData.DisplayTime = 0.0f;
    CinderData.TextColor = MakeColorFromRGB(255, 200, 0, 255); // Bright yellow/orange
    CinderData.BackgroundColor = MakeColorFromRGB(50, 25, 0, 180); // Dark orange
    CinderData.DisplayText = CinderBurning_Display;
    
    CinderData.PerkIcon = Texture2D'ZedternalRBPerkpackage_Resources.Textures.CinderIcons.CinderWidget';
    if (CinderData.PerkIcon == None)
    {
        `log("Warning: CinderWidget icon not found, using fallback display");
    }
    
    Index = FindTrackerIndex("CinderBurning");
    if (Index == INDEX_NONE)
    {
        PerkTrackers.AddItem(CinderData);
    }
    else
    {
        PerkTrackers[Index] = CinderData;
    }
    
    // Tracker 2: Fire kills and permanent bonus
    CinderData.PerkName = "CinderKills";
    CinderData.CurrentValue = 0;
    CinderData.MaxValue = 1000; // Counts to 1000
    CinderData.bIsActive = false;
    CinderData.DisplayTime = 0.0f;
    CinderData.TextColor = MakeColorFromRGB(255, 100, 0, 255); // Orange
    CinderData.BackgroundColor = MakeColorFromRGB(40, 20, 0, 180); // Dark red-orange
    CinderData.DisplayText = CinderKills_Display;
    CinderData.PerkIcon = CinderData.PerkIcon; // Reuse icon
    
    Index = FindTrackerIndex("CinderKills");
    if (Index == INDEX_NONE)
    {
        PerkTrackers.AddItem(CinderData);
    }
    else
    {
        PerkTrackers[Index] = CinderData;
    }
    
    // Tracker 3: Phoenix Protocol status (Level 20)
    CinderData.PerkName = "CinderPhoenix";
    CinderData.CurrentValue = 0;
    CinderData.MaxValue = 1; // Binary: active or not
    CinderData.bIsActive = false;
    CinderData.DisplayTime = 0.0f;
    CinderData.TextColor = MakeColorFromRGB(255, 50, 0, 255); // Bright red
    CinderData.BackgroundColor = MakeColorFromRGB(60, 0, 0, 200); // Dark red
    CinderData.DisplayText = CinderPhoenix_Display;
    CinderData.PerkIcon = CinderData.PerkIcon; // Reuse icon
    
    Index = FindTrackerIndex("CinderPhoenix");
    if (Index == INDEX_NONE)
    {
        PerkTrackers.AddItem(CinderData);
    }
    else
    {
        PerkTrackers[Index] = CinderData;
    }
}

function InitializeHivemindTracking()
{
    local PerkTrackerData HivemindData;
    local int Index;
    
    // Tracker 1: Connected teammates (Neural Network)
    HivemindData.PerkName = "HivemindNetwork";
    HivemindData.CurrentValue = 0;
    HivemindData.MaxValue = 5; // Max 5 teammates (6-player team)
    HivemindData.bIsActive = false;
    HivemindData.DisplayTime = 0.0f;
    HivemindData.TextColor = MakeColorFromRGB(50, 255, 50, 255); // Emerald green
    HivemindData.BackgroundColor = MakeColorFromRGB(20, 80, 20, 180); // Dark green
    HivemindData.DisplayText = HivemindNetwork_Display;
    
    HivemindData.PerkIcon = Texture2D'ZedternalRBPerkpackage_Resources.Textures.HivemindIcons.HivemindWidget';
    if (HivemindData.PerkIcon == None)
    {
        `log("Warning: HivemindWidget icon not found, using fallback display");
    }
    
    Index = FindTrackerIndex("HivemindNetwork");
    if (Index == INDEX_NONE)
    {
        PerkTrackers.AddItem(HivemindData);
    }
    else
    {
        PerkTrackers[Index] = HivemindData;
    }
    
    // Tracker 2: Swarm Collective kill progress
    HivemindData.PerkName = "HivemindSwarm";
    HivemindData.CurrentValue = 0;
    HivemindData.MaxValue = 20; // 20 kills needed
    HivemindData.bIsActive = false;
    HivemindData.DisplayTime = 0.0f;
    HivemindData.TextColor = MakeColorFromRGB(150, 50, 255, 255); // Purple
    HivemindData.BackgroundColor = MakeColorFromRGB(50, 20, 80, 180); // Dark purple
    HivemindData.DisplayText = HivemindSwarm_Display;
    
    // Use separate Swarm icon
    HivemindData.PerkIcon = Texture2D'ZedternalRBPerkpackage_Resources.Textures.HivemindIcons.SwarmWidget';
    if (HivemindData.PerkIcon == None)
    {
        `log("Warning: SwarmWidget icon not found, using fallback display");
    }
    
    Index = FindTrackerIndex("HivemindSwarm");
    if (Index == INDEX_NONE)
    {
        PerkTrackers.AddItem(HivemindData);
    }
    else
    {
        PerkTrackers[Index] = HivemindData;
    }
    
    // Tracker 3: Swarm Collective active countdown
    HivemindData.PerkName = "HivemindActive";
    HivemindData.CurrentValue = 0;
    HivemindData.MaxValue = 8; // 8 seconds duration
    HivemindData.bIsActive = false;
    HivemindData.DisplayTime = 0.0f;
    HivemindData.TextColor = MakeColorFromRGB(200, 255, 220, 255); // Pale cyan
    HivemindData.BackgroundColor = MakeColorFromRGB(50, 100, 50, 200); // Medium green
    HivemindData.DisplayText = HivemindActive_Display;
    HivemindData.PerkIcon = HivemindData.PerkIcon; // Reuse icon
    
    Index = FindTrackerIndex("HivemindActive");
    if (Index == INDEX_NONE)
    {
        PerkTrackers.AddItem(HivemindData);
    }
    else
    {
        PerkTrackers[Index] = HivemindData;
    }
}

// ===================================================================
// PARASITE PERK TRACKER INITIALIZATION
// ===================================================================

function InitializeParasiteTracking()
{
    local PerkTrackerData ParasiteData;
    local int Index;
    
    // Tracker 1: Siphoned enemy count (Level 10+)
    ParasiteData.PerkName = "ParasiteSiphon";
    ParasiteData.CurrentValue = 0;
    ParasiteData.MaxValue = 8; // Max 8 siphoned enemies
    ParasiteData.bIsActive = false;
    ParasiteData.DisplayTime = 0.0f;
    ParasiteData.TextColor = MakeColorFromRGB(180, 0, 40, 255); // Crimson red
    ParasiteData.BackgroundColor = MakeColorFromRGB(50, 0, 15, 180); // Dark crimson
    ParasiteData.DisplayText = ParasiteSiphon_Display;
    
    ParasiteData.PerkIcon = Texture2D'ZedternalRBPerkpackage_Resources.Textures.ParasiteIcons.ParasiteWidget';
    if (ParasiteData.PerkIcon == None)
    {
        `log("Warning: ParasiteWidget icon not found, using fallback display");
    }
    
    Index = FindTrackerIndex("ParasiteSiphon");
    if (Index == INDEX_NONE)
    {
        PerkTrackers.AddItem(ParasiteData);
    }
    else
    {
        PerkTrackers[Index] = ParasiteData;
    }
    
    // Tracker 2: Blood Harvest progress (Level 20)
    ParasiteData.PerkName = "ParasiteHarvest";
    ParasiteData.CurrentValue = 0;
    ParasiteData.MaxValue = 20; // 20 kills needed
    ParasiteData.bIsActive = false;
    ParasiteData.DisplayTime = 0.0f;
    ParasiteData.TextColor = MakeColorFromRGB(139, 0, 0, 255); // Dark red
    ParasiteData.BackgroundColor = MakeColorFromRGB(40, 0, 10, 180); // Very dark red
    ParasiteData.DisplayText = ParasiteHarvest_Display;
    ParasiteData.PerkIcon = ParasiteData.PerkIcon; // Reuse icon
    
    Index = FindTrackerIndex("ParasiteHarvest");
    if (Index == INDEX_NONE)
    {
        PerkTrackers.AddItem(ParasiteData);
    }
    else
    {
        PerkTrackers[Index] = ParasiteData;
    }
    
    // Tracker 3: Double Life Steal active countdown
    ParasiteData.PerkName = "ParasiteDrain";
    ParasiteData.CurrentValue = 0;
    ParasiteData.MaxValue = 8; // 8 seconds duration
    ParasiteData.bIsActive = false;
    ParasiteData.DisplayTime = 0.0f;
    ParasiteData.TextColor = MakeColorFromRGB(255, 50, 50, 255); // Bright red
    ParasiteData.BackgroundColor = MakeColorFromRGB(80, 0, 0, 200); // Blood red
    ParasiteData.DisplayText = ParasiteDrain_Display;
    ParasiteData.PerkIcon = ParasiteData.PerkIcon; // Reuse icon
    
    Index = FindTrackerIndex("ParasiteDrain");
    if (Index == INDEX_NONE)
    {
        PerkTrackers.AddItem(ParasiteData);
    }
    else
    {
        PerkTrackers[Index] = ParasiteData;
    }
}

// ===================================================================
// SHAPESHIFTER PERK TRACKER INITIALIZATION
// ===================================================================

function InitializeShapeshifterTracking()
{
    local PerkTrackerData ShapeshifterData;
    local int Index;

    // Buff Slot 1 (always visible when Shapeshifter is active)
    ShapeshifterData.PerkName = "ShapeshifterBuff1";
    ShapeshifterData.CurrentValue = 0;
    ShapeshifterData.MaxValue = 1;
    ShapeshifterData.bIsActive = false;
    ShapeshifterData.DisplayTime = 0.0f;
    ShapeshifterData.TextColor = MakeColorFromRGB(199, 125, 255, 255);  // Shapeshifter purple
    ShapeshifterData.BackgroundColor = MakeColorFromRGB(40, 20, 60, 200);
    ShapeshifterData.DisplayText = ShapeshifterBuff1_Display;
    ShapeshifterData.PerkIcon = None;

    Index = FindTrackerIndex("ShapeshifterBuff1");
    if (Index == INDEX_NONE)
        PerkTrackers.AddItem(ShapeshifterData);
    else
        PerkTrackers[Index] = ShapeshifterData;

    // Buff Slot 2 (visible at Rank 10-19)
    ShapeshifterData.PerkName = "ShapeshifterBuff2";
    ShapeshifterData.bIsActive = false;
    ShapeshifterData.DisplayText = "";
    ShapeshifterData.PerkIcon = None;

    Index = FindTrackerIndex("ShapeshifterBuff2");
    if (Index == INDEX_NONE)
        PerkTrackers.AddItem(ShapeshifterData);
    else
        PerkTrackers[Index] = ShapeshifterData;

    // Mimicry tracker (Rank 20+)
    ShapeshifterData.PerkName = "ShapeshifterMimicry";
    ShapeshifterData.CurrentValue = 0;
    ShapeshifterData.MaxValue = 15;
    ShapeshifterData.bIsActive = false;
    ShapeshifterData.TextColor = MakeColorFromRGB(255, 109, 0, 255);  // Mimicry orange
    ShapeshifterData.BackgroundColor = MakeColorFromRGB(60, 25, 0, 220);
    ShapeshifterData.DisplayText = ShapeshifterMimicry_Display;
    ShapeshifterData.PerkIcon = None;

    Index = FindTrackerIndex("ShapeshifterMimicry");
    if (Index == INDEX_NONE)
        PerkTrackers.AddItem(ShapeshifterData);
    else
        PerkTrackers[Index] = ShapeshifterData;
}

function InitializeRiotTracking()
{
    local PerkTrackerData RiotData;
    local int Index;
    
    RiotData.PerkName = "Riot";
    RiotData.CurrentValue = 0;
    RiotData.MaxValue = 5; // Max nearby enemies that matter
    RiotData.bIsActive = false;
    RiotData.DisplayTime = 0.0f;
    RiotData.TextColor = MakeColorFromRGB(220, 220, 220, 255);
    RiotData.BackgroundColor = MakeColorFromRGB(35, 35, 40, 180);
    RiotData.DisplayText = Riot_Display;
    
    RiotData.PerkIcon = Texture2D'ZedternalRBPerkpackage_Resources.Textures.RiotIcons.RiotWidget';
    if (RiotData.PerkIcon == None)
    {
        `log("Warning: RiotWidget icon not found, using fallback display");
    }
    
    Index = FindTrackerIndex("Riot");
    if (Index == INDEX_NONE)
    {
        PerkTrackers.AddItem(RiotData);
    }
    else
    {
        PerkTrackers[Index] = RiotData;
    }
}

// ===================================================================
// NEW: AGONY PERK TRACKER INITIALIZATION
// ===================================================================

function InitializeAgonyTracking()
{
    local PerkTrackerData AgonyData;
    local int Index;
    
    AgonyData.PerkName = "Agony";
    AgonyData.CurrentValue = 0;
    AgonyData.MaxValue = 120;  // 120 seconds to next reward
    AgonyData.bIsActive = false;
    AgonyData.DisplayTime = 0.0f;
    AgonyData.TextColor = MakeColorFromRGB(150, 50, 255, 255);  // Purple/Violet
    AgonyData.BackgroundColor = MakeColorFromRGB(30, 10, 50, 200);  // Dark purple
    AgonyData.DisplayText = Agony_Display;
    
    AgonyData.PerkIcon = Texture2D'ZedternalRBPerkpackage_Resources.Textures.AgonyIcons.AgonyWidget';
    if (AgonyData.PerkIcon == None)
    {
        `log("Warning: AgonyWidget icon not found, using fallback display");
    }
    
    Index = FindTrackerIndex("Agony");
    if (Index == INDEX_NONE)
    {
        PerkTrackers.AddItem(AgonyData);
    }
    else
    {
        PerkTrackers[Index] = AgonyData;
    }
    
    `log("ZTHudWrapper: Agony tracker initialized");
}

function UpdateRiotTracking(int NearbyEnemies, bool bMaxBonusActive)
{
    local int Index;
    
    Index = FindTrackerIndex("Riot");
    if (Index == INDEX_NONE) return;
    
    PerkTrackers[Index].CurrentValue = NearbyEnemies;
    PerkTrackers[Index].MaxValue = 5; // Max threshold
    PerkTrackers[Index].bIsActive = (NearbyEnemies > 0 || bMaxBonusActive);
    PerkTrackers[Index].DisplayTime = 6.0f;
    
    if (bMaxBonusActive)
    {
        PerkTrackers[Index].DisplayText = Riot_ActiveText;
        PerkTrackers[Index].TextColor = MakeColorFromRGB(255, 69, 0, 255); // Bright orange
        PerkTrackers[Index].BackgroundColor = MakeColorFromRGB(50, 50, 55, 200);
        PerkTrackers[Index].DisplayTime = 8.0f;
    }
    else
    {
        PerkTrackers[Index].DisplayText = Riot_Display;
        PerkTrackers[Index].TextColor = MakeColorFromRGB(220, 220, 220, 255);
        PerkTrackers[Index].BackgroundColor = MakeColorFromRGB(35, 35, 40, 180);
    }
}

// ===================================================================
// NEW: AGONY STATUS UPDATE FUNCTION
// ===================================================================

/**
 * Update Agony perk tracker with ZED time duration and dosh rewards
 * @param bZedTimeActive - Whether ZED time is currently active
 * @param TotalSeconds - Total cumulative seconds spent in ZED time
 * @param RewardsEarned - Number of 500-dosh rewards earned
 * @param CurrentUpgradeLevel - Current upgrade level of the perk
 */
function UpdateAgonyZedTimeTracker(bool bZedTimeActive, float TotalSeconds, int RewardsEarned, int CurrentUpgradeLevel)
{
    local int Index;
    local int SecondsToNext;
    local string DisplayText;
    
    // Only show for Level 20+
    if (CurrentUpgradeLevel < class'ZTConfig_Capstone'.default.Capstone_Rank2Level)
        return;
    
    Index = FindTrackerIndex("Agony");
    if (Index == INDEX_NONE)
    {
        `log("Warning: Agony tracker not found!");
        return;
    }
    
    // Calculate seconds until next reward
    SecondsToNext = 120 - (int(TotalSeconds) % 120);
    
    // Update tracker data
    PerkTrackers[Index].CurrentValue = int(TotalSeconds) % 120;
    PerkTrackers[Index].MaxValue = 120;
    
    if (bZedTimeActive)
    {
        // Show active during ZED time
        PerkTrackers[Index].bIsActive = true;
        PerkTrackers[Index].DisplayTime = 999.0f;  // Stay visible
        
        DisplayText = Repl(Agony_ZedTimeFormat, "%1", string(int(TotalSeconds)));
        DisplayText = Repl(DisplayText, "%2", string(SecondsToNext));
        PerkTrackers[Index].DisplayText = DisplayText;
        PerkTrackers[Index].TextColor = MakeColorFromRGB(200, 100, 255, 255);  // Bright purple during ZED time
        PerkTrackers[Index].BackgroundColor = MakeColorFromRGB(40, 20, 60, 220);
    }
    else
    {
        // Show brief update when ZED time ends
        PerkTrackers[Index].bIsActive = true;
        PerkTrackers[Index].DisplayTime = 6.0f;  // Show for 6 seconds after ZED time
        
        DisplayText = Repl(Agony_TotalFormat, "%1", string(int(TotalSeconds)));
        DisplayText = Repl(DisplayText, "%2", string(RewardsEarned));
        DisplayText = Repl(DisplayText, "%3", string(RewardsEarned * 500));
        PerkTrackers[Index].DisplayText = DisplayText;
        PerkTrackers[Index].TextColor = MakeColorFromRGB(150, 50, 255, 255);  // Standard purple
        PerkTrackers[Index].BackgroundColor = MakeColorFromRGB(30, 10, 50, 200);
    }
}

function UpdateCryophiliteTrackers(byte HeadshotKills, byte TotalKills, bool bIcicleReady, bool bAbsoluteReady, optional int CurrentUpgradeLevel = 1)
{
    if (CurrentUpgradeLevel >= class'ZTConfig_Capstone'.default.Capstone_Rank1Level)
    {
        if (bIcicleReady)
        {
            UpdatePerkTracker("CryophiliteIcicle", 10, 10, true, 8.0f);
            TriggerChainNotification(ChainTitle_Icicle, ChainBody_Icicle, 4.0f);
        }
        else
        {
            UpdatePerkTracker("CryophiliteIcicle", HeadshotKills, 10, false, 6.0f);
        }
    }
    
    if (CurrentUpgradeLevel >= class'ZTConfig_Capstone'.default.Capstone_Rank2Level)
    {
        if (bAbsoluteReady)
        {
            UpdatePerkTracker("CryophiliteAbsolute", 20, 20, true, 8.0f);
            TriggerChainNotification(ChainTitle_AbsoluteZero, ChainBody_AbsoluteZero, 4.0f);
        }
        else
        {
            UpdatePerkTracker("CryophiliteAbsolute", TotalKills, 20, false, 6.0f);
        }
    }
}

// ===================================================================
// CARD VISIBILITY TOGGLES - Console commands to hide/show HUD cards
// Usage: HideCard Shapeshifter | HideCard Gambit | HideCard Artificer | HideCard Predator
//        ShowCard Shapeshifter | ShowCard All
// ===================================================================

exec function HideCard(string CardName)
{
    CardName = Caps(CardName);
    if (CardName == "SHAPESHIFTER")
    {
        bHideShapeshifterCard = True;
        PlayerOwner.ClientMessage("Shapeshifter card hidden. Use ShowCard Shapeshifter to restore.");
    }
    else if (CardName == "GAMBIT")
    {
        bHideGambitCard = True;
        PlayerOwner.ClientMessage("Gambit card hidden. Use ShowCard Gambit to restore.");
    }
    else if (CardName == "ARTIFICER")
    {
        bHideArtificerCard = True;
        PlayerOwner.ClientMessage("Artificer card hidden. Use ShowCard Artificer to restore.");
    }
    else if (CardName == "PREDATOR")
    {
        bHidePredatorCard = True;
        PlayerOwner.ClientMessage("Predator card hidden. Use ShowCard Predator to restore.");
    }
    else if (CardName == "OMEN")
    {
        bHideOmenCard = True;
        PlayerOwner.ClientMessage("Omen card hidden. Use ShowCard Omen to restore.");
    }
    else if (CardName == "HOLLOW")
    {
        bHideHollowCard = True;
        PlayerOwner.ClientMessage("Hollow card hidden. Use ShowCard Hollow to restore.");
    }
    else if (CardName == "METRONOME")
    {
        bHideMetronomeCard = True;
        PlayerOwner.ClientMessage("Metronome card hidden. Use ShowCard Metronome to restore.");
    }
    else if (CardName == "DETONATOR")
    {
        bHideDetonatorCard = True;
        PlayerOwner.ClientMessage("Detonator card hidden. Use ShowCard Detonator to restore.");
    }
    else if (CardName == "ALL")
    {
        bHideShapeshifterCard = True;
        bHideGambitCard = True;
        bHideArtificerCard = True;
        bHidePredatorCard = True;
        bHideOmenCard = True;
        bHideHollowCard = True;
        bHideMetronomeCard = True;
        bHideDetonatorCard = True;
        PlayerOwner.ClientMessage("All HUD cards hidden. Use ShowCard All to restore.");
    }
    else
    {
        PlayerOwner.ClientMessage("Unknown card:" @ CardName $ ". Options: Shapeshifter, Gambit, Artificer, Predator, Omen, Hollow, Metronome, Detonator, All");
    }
}

exec function ShowCard(string CardName)
{
    CardName = Caps(CardName);
    if (CardName == "SHAPESHIFTER")
    {
        bHideShapeshifterCard = False;
        PlayerOwner.ClientMessage("Shapeshifter card shown.");
    }
    else if (CardName == "GAMBIT")
    {
        bHideGambitCard = False;
        PlayerOwner.ClientMessage("Gambit card shown.");
    }
    else if (CardName == "ARTIFICER")
    {
        bHideArtificerCard = False;
        PlayerOwner.ClientMessage("Artificer card shown.");
    }
    else if (CardName == "PREDATOR")
    {
        bHidePredatorCard = False;
        PlayerOwner.ClientMessage("Predator card shown.");
    }
    else if (CardName == "OMEN")
    {
        bHideOmenCard = False;
        PlayerOwner.ClientMessage("Omen card shown.");
    }
    else if (CardName == "HOLLOW")
    {
        bHideHollowCard = False;
        PlayerOwner.ClientMessage("Hollow card shown.");
    }
    else if (CardName == "METRONOME")
    {
        bHideMetronomeCard = False;
        PlayerOwner.ClientMessage("Metronome card shown.");
    }
    else if (CardName == "DETONATOR")
    {
        bHideDetonatorCard = False;
        PlayerOwner.ClientMessage("Detonator card shown.");
    }
    else if (CardName == "ALL")
    {
        bHideShapeshifterCard = False;
        bHideGambitCard = False;
        bHideArtificerCard = False;
        bHidePredatorCard = False;
        bHideOmenCard = False;
        bHideHollowCard = False;
        bHideMetronomeCard = False;
        bHideDetonatorCard = False;
        PlayerOwner.ClientMessage("All HUD cards shown.");
    }
    else
    {
        PlayerOwner.ClientMessage("Unknown card:" @ CardName $ ". Options: Shapeshifter, Gambit, Artificer, Predator, Omen, Hollow, Metronome, Detonator, All");
    }
}

exec function ToggleCryophilitePanel()
{
    local KFPlayerController KFPC;
    local ZTUpgrade_Perk_Cryophilite_Helper CryoHelper;
    local KFPawn OwnerPawn;
    local string CryoStatus;
    
    KFPC = KFPlayerController(class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController());
    if (KFPC != None && KFPC.Pawn != None)
    {
        OwnerPawn = KFPawn(KFPC.Pawn);
        if (OwnerPawn != None)
        {
            CryoHelper = class'ZTUpgrade_Perk_Cryophilite'.static.GetHelper(OwnerPawn);
            if (CryoHelper != None)
            {
                if (CryoHelper.bAbsoluteZeroReady)
                {
                    CryoStatus = "ABSOLUTE ZERO READY! Next shot creates freeze explosion!";
                }
                else if (CryoHelper.bIcicleArrowReady)
                {
                    CryoStatus = "ICICLE ARROW READY! Next shot +200% damage!";
                }
                else
                {
                    CryoStatus = "Progress: " $ CryoHelper.HeadshotKillsToDisplay $ "/10 headshots, " $ CryoHelper.TotalKillsToDisplay $ "/20 kills";
                }
                
                class'ZTMessageManager'.static.SendImportant(KFPC, "CRYOPHILITE STATUS: " $ CryoStatus);
                
                class'ZTMessageManager'.static.SendMinor(KFPC, "Total Headshot Kills: " $ CryoHelper.TotalHeadshotKills);
                class'ZTMessageManager'.static.SendMinor(KFPC, "Total Kills: " $ CryoHelper.TotalKills);
                class'ZTMessageManager'.static.SendMinor(KFPC, "Ice Tips: Precision archery - headshots charge Icicle Arrow, all kills charge Absolute Zero");
            }
            else
            {
                class'ZTMessageManager'.static.SendMinor(KFPC, "Cryophilite perk not active.");
            }
        }
    }
}

function UpdateHydraKills(int CurrentKills, int MaxKills, optional bool bFuryModeTriggered = false)
{
    UpdatePerkTracker("Hydra", CurrentKills, MaxKills, bFuryModeTriggered, 5.0f);
    
    if (bFuryModeTriggered)
    {
        TriggerChainNotification(ChainTitle_HydraBarrage, ChainBody_HydraBarrage, 4.0f);
    }
}

function UpdateWendigoStalkingBonus(int CurrentStalkTime, int MaxStalkTime, optional bool bIsActive = false, optional float DisplayDuration = 8.0f)
{
    local int Index;
    
    Index = FindTrackerIndex("WendigoStalk");
    if (Index != INDEX_NONE)
    {
        PerkTrackers[Index].CurrentValue = CurrentStalkTime;
        PerkTrackers[Index].MaxValue = MaxStalkTime;
        PerkTrackers[Index].bIsActive = bIsActive;
        PerkTrackers[Index].DisplayTime = DisplayDuration;
        PerkTrackers[Index].DisplayText = WendigoStalk_Display;
        
        PerkTrackers[Index].TextColor = MakeColorFromRGB(135, 206, 235, 255);
        PerkTrackers[Index].BackgroundColor = MakeColorFromRGB(47, 79, 79, 180);
    }
}

function UpdateWendigoPerfectAmbush(optional bool bIsReady = false, optional bool bJustTriggered = false, optional float DisplayDuration = 8.0f)
{
    local int Index;
    
    Index = FindTrackerIndex("WendigoAmbush");
    if (Index != INDEX_NONE)
    {
        PerkTrackers[Index].CurrentValue = bIsReady ? 1 : 0;
        PerkTrackers[Index].MaxValue = 1;
        PerkTrackers[Index].bIsActive = bIsReady || bJustTriggered;
        PerkTrackers[Index].DisplayTime = DisplayDuration;
        
        if (bJustTriggered)
        {
            PerkTrackers[Index].DisplayText = Wendigo_AmbushTriggered;
            PerkTrackers[Index].TextColor = MakeColorFromRGB(255, 255, 255, 255);
            PerkTrackers[Index].BackgroundColor = MakeColorFromRGB(100, 150, 200, 200);
        }
        else if (bIsReady)
        {
            PerkTrackers[Index].DisplayText = WendigoAmbush_Display;
            PerkTrackers[Index].TextColor = MakeColorFromRGB(173, 216, 230, 255);
            PerkTrackers[Index].BackgroundColor = MakeColorFromRGB(70, 130, 180, 180);
        }
    }
}

function UpdateWendigoApexStalker(int CurrentTime, int MaxTime, optional bool bIsActive = false, optional float DisplayDuration = 8.0f)
{
    local int Index;
    
    Index = FindTrackerIndex("WendigoApex");
    if (Index != INDEX_NONE)
    {
        PerkTrackers[Index].CurrentValue = CurrentTime;
        PerkTrackers[Index].MaxValue = MaxTime;
        PerkTrackers[Index].bIsActive = (CurrentTime >= 25) || bIsActive;
        PerkTrackers[Index].DisplayTime = DisplayDuration;
        
        if (bIsActive)
        {
            PerkTrackers[Index].DisplayText = Wendigo_ApexHunter;
            PerkTrackers[Index].TextColor = MakeColorFromRGB(240, 248, 255, 255);
            PerkTrackers[Index].BackgroundColor = MakeColorFromRGB(25, 25, 112, 200);
            
            TriggerChainNotification(ChainTitle_WendigoAwakens, ChainBody_WendigoAwakens, 4.0f);
        }
        else
        {
            PerkTrackers[Index].DisplayText = WendigoApex_Display;
            PerkTrackers[Index].TextColor = MakeColorFromRGB(176, 196, 222, 255);
            PerkTrackers[Index].BackgroundColor = MakeColorFromRGB(30, 30, 60, 160);
        }
    }
}

function UpdateArchangelHealing(int CurrentHealing, int MaxHealing, optional bool bMilestoneComplete = false)
{
    UpdatePerkTracker("Archangel", CurrentHealing, MaxHealing, bMilestoneComplete, 6.0f);
    
    if (bMilestoneComplete)
    {
        TriggerChainNotification(ChainTitle_DivineService, ChainBody_DivineService, 4.0f);
    }
}

function UpdateArchangelHealingSummary(int TotalHealing, string HealingSummary)
{
    local int Index;
    
    Index = FindTrackerIndex("ArchangelHealing");
    if (Index != INDEX_NONE && TotalHealing > 0)
    {
        PerkTrackers[Index].CurrentValue = TotalHealing;
        PerkTrackers[Index].MaxValue = 999;
        PerkTrackers[Index].bIsActive = true;
        PerkTrackers[Index].DisplayTime = 12.0f;
        PerkTrackers[Index].DisplayText = HealingSummary;
    }
}

function UpdateMedusaVenom(int CurrentPoisonDamage, int MaxPoisonDamage, int CurrentScales, int MaxScales, bool bFullGorgon, optional bool bTransformationComplete = false)
{
    local int Index;
    
    Index = FindTrackerIndex("Medusa");
    if (Index != INDEX_NONE)
    {
        PerkTrackers[Index].CurrentValue = CurrentPoisonDamage;
        PerkTrackers[Index].MaxValue = MaxPoisonDamage;
        PerkTrackers[Index].bIsActive = (CurrentPoisonDamage > 0 || bTransformationComplete);
        PerkTrackers[Index].DisplayTime = 8.0f;
        
        if (bFullGorgon)
        {
            PerkTrackers[Index].DisplayText = Medusa_FullGorgon;
            PerkTrackers[Index].TextColor = MakeColorFromRGB(255, 215, 0, 255);
            PerkTrackers[Index].BackgroundColor = MakeColorFromRGB(40, 20, 40, 200);
        }
        else
        {
            PerkTrackers[Index].DisplayText = Medusa_Display;
            PerkTrackers[Index].TextColor = MakeColorFromRGB(139, 0, 139, 255);
            PerkTrackers[Index].BackgroundColor = MakeColorFromRGB(25, 10, 25, 180);
        }
    }
    
    Index = FindTrackerIndex("MedusaScales");
    if (Index != INDEX_NONE && (CurrentScales > 0 || bFullGorgon))
    {
        PerkTrackers[Index].CurrentValue = CurrentScales;
        PerkTrackers[Index].MaxValue = MaxScales;
        PerkTrackers[Index].bIsActive = true;
        PerkTrackers[Index].DisplayTime = 12.0f;
        
        if (bFullGorgon)
        {
            PerkTrackers[Index].DisplayText = MedusaScales_FullGorgon;
            PerkTrackers[Index].TextColor = MakeColorFromRGB(255, 215, 0, 255);
            PerkTrackers[Index].BackgroundColor = MakeColorFromRGB(50, 25, 50, 200);
        }
        else if (CurrentScales > 0)
        {
            PerkTrackers[Index].DisplayText = Repl(MedusaScales_Format, "%1", string(CurrentScales * 3));
            PerkTrackers[Index].DisplayText = Repl(PerkTrackers[Index].DisplayText, "%2", string(CurrentScales * 2));
            PerkTrackers[Index].TextColor = MakeColorFromRGB(186, 85, 211, 255);
            PerkTrackers[Index].BackgroundColor = MakeColorFromRGB(30, 15, 30, 180);
        }
    }
    
    if (bTransformationComplete)
    {
        TriggerChainNotification(ChainTitle_GorgonAwakens, ChainBody_GorgonAwakens, 6.0f);
    }
}

function UpdateMedusaProgress(int CurrentPoison, int MaxPoison, optional bool bScaleGained = false)
{
    UpdatePerkTracker("Medusa", CurrentPoison, MaxPoison, bScaleGained, 8.0f);
    
    if (bScaleGained)
    {
        TriggerChainNotification(ChainTitle_SerpentScale, ChainBody_SerpentScale, 4.0f);
    }
}

function InitializeInstantKillNotification()
{
    InstantKillNotif.NotificationText = InstantKill_Text;
    InstantKillNotif.DisplayTime = 0.0f;
    InstantKillNotif.MaxDisplayTime = 2.0f;
    InstantKillNotif.TextColor = MakeColorFromRGB(255, 0, 0, 255);
    InstantKillNotif.bIsActive = false;
    InstantKillNotif.TextScale = 2.0f;
}

function InitializeChainNotification()
{
    ChainNotif.NotificationTitle = "";
    ChainNotif.NotificationText = "";
    ChainNotif.DisplayTime = 0.0f;
    ChainNotif.MaxDisplayTime = 3.0f;
    ChainNotif.TitleColor = MakeColorFromRGB(139, 0, 0, 255);
    ChainNotif.TextColor = MakeColorFromRGB(255, 215, 0, 255);
    ChainNotif.bIsActive = false;
    ChainNotif.TitleScale = 1.5f;
    ChainNotif.TextScale = 1.0f;
}

function InitializeEvolutionPanel()
{
    EvolutionPanel.bShowPanel = false;
    EvolutionPanel.PanelDisplayTime = 0.0f;
    EvolutionPanel.bToggleMode = false;
}

// ===================================================================
// NEW: Notification Feed System Functions
// ===================================================================

function AddNotificationMessage(string Message, Color MessageColor, byte Priority)
{
    local NotificationMessage NewNotification;
    local float DisplayDuration;
    
    `log("ZTHudWrapper: AddNotificationMessage called - Message:" @ Message @ "Priority:" @ Priority);
    
    switch(Priority)
    {
        case 3:
            DisplayDuration = 6.0f;
            break;
        case 2:
            DisplayDuration = 4.0f;
            break;
        case 1:
            DisplayDuration = 3.0f;
            break;
        default:
            DisplayDuration = 4.0f;
            break;
    }
    
    NewNotification.MessageText = Message;
    NewNotification.MessageColor = MessageColor;
    NewNotification.DisplayTime = DisplayDuration;
    NewNotification.MaxDisplayTime = DisplayDuration;
    NewNotification.bIsActive = true;
    NewNotification.Priority = Priority;
    
    NotificationMessages.InsertItem(0, NewNotification);
    
    `log("ZTHudWrapper: Added notification, total messages:" @ NotificationMessages.Length);
    
    while (NotificationMessages.Length > MaxVisibleNotifications)
    {
        NotificationMessages.Remove(MaxVisibleNotifications, NotificationMessages.Length - MaxVisibleNotifications);
    }
}

function UpdateNotificationTimers()
{
    local int i;
    
    for (i = NotificationMessages.Length - 1; i >= 0; i--)
    {
        if (NotificationMessages[i].bIsActive)
        {
            NotificationMessages[i].DisplayTime -= RenderDelta;
            
            if (NotificationMessages[i].DisplayTime <= 0.0f)
            {
                NotificationMessages.Remove(i, 1);
            }
        }
    }
}

function DrawNotificationFeed()
{
    local int i;
    local float XPos, YPos;
    local float Alpha;
    local Color DrawColor;
    local string DisplayText;
    local float TextWidth, TextHeight;
    local float RS, NTS, NSp, Sh;
    
    if (Canvas == None || NotificationMessages.Length == 0)
        return;

    RS = ResScale;
    NTS = NotificationTextScale * RS;
    NSp = NotificationSpacing * RS;
    Sh = FMax(1.0f, 1.0f * RS);
    
    XPos = Canvas.SizeX * NotificationFeedX;
    YPos = Canvas.SizeY * NotificationFeedY;
    
    Canvas.Font = class'KFGameEngine'.Static.GetKFCanvasFont();
    
    for (i = 0; i < NotificationMessages.Length && i < MaxVisibleNotifications; i++)
    {
        if (!NotificationMessages[i].bIsActive)
            continue;
        
        DisplayText = NotificationMessages[i].MessageText;
        
        if (NotificationMessages[i].DisplayTime <= 1.0f)
        {
            Alpha = NotificationMessages[i].DisplayTime;
        }
        else
        {
            Alpha = 1.0f;
        }
        
        Canvas.TextSize(DisplayText, TextWidth, TextHeight, NTS, NTS);
        
        Canvas.SetDrawColor(0, 0, 0, Alpha * 180);
        Canvas.SetPos(XPos + 2 * RS, YPos + 2 * RS);
        Canvas.DrawText(DisplayText, false, NTS, NTS);
        
        Canvas.SetDrawColor(0, 0, 0, Alpha * 220);
        Canvas.SetPos(XPos - Sh, YPos);
        Canvas.DrawText(DisplayText, false, NTS, NTS);
        Canvas.SetPos(XPos + Sh, YPos);
        Canvas.DrawText(DisplayText, false, NTS, NTS);
        Canvas.SetPos(XPos, YPos - Sh);
        Canvas.DrawText(DisplayText, false, NTS, NTS);
        Canvas.SetPos(XPos, YPos + Sh);
        Canvas.DrawText(DisplayText, false, NTS, NTS);
        
        DrawColor = NotificationMessages[i].MessageColor;
        DrawColor.A = Alpha * 255;
        Canvas.SetDrawColor(DrawColor.R, DrawColor.G, DrawColor.B, DrawColor.A);
        Canvas.SetPos(XPos, YPos);
        Canvas.DrawText(DisplayText, false, NTS, NTS);
        
        YPos += (TextHeight * NTS) + NSp;
    }
}

// ===================================================================
// Perk & Achievement Unlock Popup Drawing (Improved Visuals)
// ===================================================================

function DrawPerkUnlockPopup()
{
    local float IconSize, BoxWidth, BoxHeight, BoxX, BoxY;
    local float TextX, TextY, PopupTextScale;
    local float XL, YL;
    local string TitleText, SubText;
    local float DeltaTime;
    local float AnimationProgress;
    local float ScaleFactor, AlphaFactor;
    local float GlowIntensity, GlowPulse;
    local Color TitleColor, NameColor;
    local float TextAlpha;
    local float InnerX, InnerY, InnerW, InnerH;
    local float IconFrameSize;
    local float SepY;
    
    DeltaTime = class'WorldInfo'.static.GetWorldInfo().DeltaSeconds;
    UnlockPopup.DisplayTime -= DeltaTime;
    
    if (UnlockPopup.DisplayTime <= 0.0f)
    {
        UnlockPopup.bIsActive = false;
        UnlockParticles.Length = 0;
        return;
    }
    
    AnimationProgress = 1.0f - (UnlockPopup.DisplayTime / UnlockPopup.MaxDisplayTime);
    
    // Scale-in animation (first 1 second of 8)
    if (AnimationProgress < 0.125f)
    {
        ScaleFactor = 0.8f + (AnimationProgress / 0.125f) * 0.2f;
        AlphaFactor = AnimationProgress / 0.125f;
        GlowIntensity = 1.0f - (AnimationProgress / 0.125f);
    }
    else
    {
        ScaleFactor = 1.0f;
        AlphaFactor = 1.0f;
        GlowIntensity = 0.0f;
    }
    
    // Fade-out during last 1 second
    if (UnlockPopup.DisplayTime < 1.0f)
    {
        AlphaFactor *= UnlockPopup.DisplayTime;
    }
    
    // Continuous subtle glow pulse (sine wave)
    GlowPulse = 0.25f + 0.15f * Sin(AnimationProgress * 25.0f);
    
    // Text alpha (delayed fade-in)
    if (AnimationProgress < 0.0375f)
    {
        TextAlpha = 0.0f;
    }
    else if (AnimationProgress < 0.1f)
    {
        TextAlpha = (AnimationProgress - 0.0375f) / 0.0625f;
    }
    else
    {
        TextAlpha = 1.0f;
    }
    if (UnlockPopup.DisplayTime < 1.0f)
    {
        TextAlpha *= UnlockPopup.DisplayTime;
    }
    
    // --- Box dimensions (larger icon, slightly wider, scaled from 1080p baseline) ---
    IconSize = 192.0f * ResScale * 0.667f * ScaleFactor;
    BoxWidth = 860.0f * ResScale * 0.667f * ScaleFactor;
    BoxHeight = 230.0f * ResScale * 0.667f * ScaleFactor;
    
    BoxX = (Canvas.SizeX - BoxWidth) / 2.0f;
    BoxY = Canvas.SizeY * 0.15f;
    
    // --- Initial burst glow (behind everything) ---
    if (GlowIntensity > 0.0f)
    {
        DrawPopupGlow(BoxX, BoxY, BoxWidth, BoxHeight, GlowIntensity * AlphaFactor, 255, 215, 0);
    }
    
    // --- Layered background ---
    // Outer dark layer
    Canvas.SetDrawColor(5, 5, 12, 230 * AlphaFactor);
    Canvas.SetPos(BoxX, BoxY);
    Canvas.DrawRect(BoxWidth, BoxHeight);
    
    // Inner slightly lighter panel (inset, scaled)
    InnerX = BoxX + 4.0f * ResScale;
    InnerY = BoxY + 4.0f * ResScale;
    InnerW = BoxWidth - 8.0f * ResScale;
    InnerH = BoxHeight - 8.0f * ResScale;
    Canvas.SetDrawColor(15, 15, 28, 210 * AlphaFactor);
    Canvas.SetPos(InnerX, InnerY);
    Canvas.DrawRect(InnerW, InnerH);
    
    // --- Outer border (2px, gold, scaled) ---
    Canvas.SetDrawColor(255, 215, 0, 255 * AlphaFactor);
    DrawBox(BoxX, BoxY, BoxWidth, BoxHeight, 2.0f * ResScale);
    
    // --- Inner border (1px, gold at 40% + pulse, scaled) ---
    Canvas.SetDrawColor(255, 215, 0, (100 + 60 * GlowPulse) * AlphaFactor);
    DrawBox(BoxX + 8.0f * ResScale, BoxY + 8.0f * ResScale, BoxWidth - 16.0f * ResScale, BoxHeight - 16.0f * ResScale, FMax(1.0f, 1.0f * ResScale));
    
    // --- Corner brackets (decorative L-shapes, pulsing) ---
    DrawCornerBrackets(BoxX, BoxY, BoxWidth, BoxHeight, AlphaFactor, GlowPulse, 255, 215, 0);
    
    // --- Icon with frame ---
    if (UnlockPopup.PerkIcon != None)
    {
        IconFrameSize = IconSize + 6.0f * ResScale;
        
        // Icon frame (gold border around icon, scaled)
        Canvas.SetDrawColor(255, 215, 0, (180 + 75 * GlowPulse) * AlphaFactor);
        DrawBox(BoxX + 28.0f * ResScale, BoxY + (BoxHeight - IconFrameSize) / 2.0f, IconFrameSize, IconFrameSize, 2.0f * ResScale);
        
        // Dark background behind icon
        Canvas.SetDrawColor(8, 8, 15, 255 * AlphaFactor);
        Canvas.SetPos(BoxX + 31.0f * ResScale, BoxY + (BoxHeight - IconSize) / 2.0f);
        Canvas.DrawRect(IconSize, IconSize);
        
        // The icon itself
        Canvas.SetDrawColor(255, 255, 255, 255 * AlphaFactor);
        Canvas.SetPos(BoxX + 31.0f * ResScale, BoxY + (BoxHeight - IconSize) / 2.0f);
        Canvas.DrawTile(
            UnlockPopup.PerkIcon,
            IconSize,
            IconSize,
            0, 0,
            UnlockPopup.PerkIcon.SizeX,
            UnlockPopup.PerkIcon.SizeY
        );
    }
    
    // --- Text area ---
    Canvas.Font = class'Engine'.Static.GetLargeFont();
    TitleText = "NEW PERK UNLOCKED!";
    SubText = UnlockPopup.PerkName;
    
    TextX = BoxX + IconSize + 70.0f * ResScale;
    
    // --- Horizontal separator ---
    SepY = BoxY + (BoxHeight / 2.0f) - 2.0f * ResScale;
    DrawHorizontalSeparator(TextX, SepY, BoxWidth - IconSize - 100.0f * ResScale, AlphaFactor * 0.6f, 255, 215, 0);
    
    // --- Title text (above separator, scaled) ---
    PopupTextScale = 1.0f * ScaleFactor * ResScale;
    TitleColor.R = 255;
    TitleColor.G = 215;
    TitleColor.B = 0;
    TitleColor.A = 255 * TextAlpha;
    Canvas.SetDrawColor(TitleColor.R, TitleColor.G, TitleColor.B, TitleColor.A);
    
    Canvas.StrLen(TitleText, XL, YL);
    YL *= PopupTextScale;
    TextY = SepY - YL - 8.0f * ResScale;
    
    Canvas.SetPos(TextX, TextY);
    Canvas.DrawText(TitleText, true, PopupTextScale, PopupTextScale);
    
    // --- Perk name (below separator, scaled) ---
    PopupTextScale = 1.3f * ScaleFactor * ResScale;
    NameColor.R = 255;
    NameColor.G = 255;
    NameColor.B = 255;
    NameColor.A = 255 * TextAlpha;
    Canvas.SetDrawColor(NameColor.R, NameColor.G, NameColor.B, NameColor.A);
    
    TextY = SepY + 10.0f * ResScale;
    
    Canvas.SetPos(TextX, TextY);
    Canvas.DrawText(SubText, true, PopupTextScale, PopupTextScale);
    
    // --- Particles (on top of everything) ---
    UpdateUnlockParticles(DeltaTime);
    DrawUnlockParticles(BoxX + BoxWidth / 2.0f, BoxY + BoxHeight / 2.0f, AlphaFactor);
}

// ===================================================================
// Popup Visual Helpers
// ===================================================================

function DrawPopupGlow(float X, float Y, float Width, float Height, float Intensity, byte R, byte G, byte B)
{
    local float GlowSize;
    local int Alpha;
    
    // Outer soft glow (scaled)
    GlowSize = 25.0f * ResScale * Intensity;
    Alpha = 80 * Intensity;
    Canvas.SetDrawColor(R, G, B, Alpha);
    Canvas.SetPos(X - GlowSize, Y - GlowSize);
    Canvas.DrawRect(Width + GlowSize * 2, Height + GlowSize * 2);
    
    // Mid glow (scaled)
    GlowSize = 12.0f * ResScale * Intensity;
    Alpha = 120 * Intensity;
    Canvas.SetDrawColor(R, G, B, Alpha);
    Canvas.SetPos(X - GlowSize, Y - GlowSize);
    Canvas.DrawRect(Width + GlowSize * 2, Height + GlowSize * 2);
    
    // Inner bright edge (scaled)
    GlowSize = 4.0f * ResScale * Intensity;
    Alpha = 180 * Intensity;
    Canvas.SetDrawColor(R, G, B, Alpha);
    Canvas.SetPos(X - GlowSize, Y - GlowSize);
    Canvas.DrawRect(Width + GlowSize * 2, Height + GlowSize * 2);
}

function DrawCornerBrackets(float X, float Y, float Width, float Height, float Alpha, float PulseAlpha, byte R, byte G, byte B)
{
    local float ArmLength, Thickness, Offset;
    local int BracketAlpha;
    
    ArmLength = 30.0f * ResScale;
    Thickness = FMax(1.0f, 2.0f * ResScale);
    Offset = 12.0f * ResScale;
    BracketAlpha = (180 + 75 * PulseAlpha) * Alpha;
    
    Canvas.SetDrawColor(R, G, B, BracketAlpha);
    
    // Top-left corner
    Canvas.SetPos(X + Offset, Y + Offset);
    Canvas.DrawRect(ArmLength, Thickness);
    Canvas.SetPos(X + Offset, Y + Offset);
    Canvas.DrawRect(Thickness, ArmLength);
    
    // Top-right corner
    Canvas.SetPos(X + Width - Offset - ArmLength, Y + Offset);
    Canvas.DrawRect(ArmLength, Thickness);
    Canvas.SetPos(X + Width - Offset - Thickness, Y + Offset);
    Canvas.DrawRect(Thickness, ArmLength);
    
    // Bottom-left corner
    Canvas.SetPos(X + Offset, Y + Height - Offset - Thickness);
    Canvas.DrawRect(ArmLength, Thickness);
    Canvas.SetPos(X + Offset, Y + Height - Offset - ArmLength);
    Canvas.DrawRect(Thickness, ArmLength);
    
    // Bottom-right corner
    Canvas.SetPos(X + Width - Offset - ArmLength, Y + Height - Offset - Thickness);
    Canvas.DrawRect(ArmLength, Thickness);
    Canvas.SetPos(X + Width - Offset - Thickness, Y + Height - Offset - ArmLength);
    Canvas.DrawRect(Thickness, ArmLength);
}

function DrawHorizontalSeparator(float X, float Y, float Width, float Alpha, byte R, byte G, byte B)
{
    local float FadeWidth;
    local int i, Steps;
    local float StepWidth, StepAlpha;
    
    // Center solid section (60% of width)
    Canvas.SetDrawColor(R, G, B, 200 * Alpha);
    Canvas.SetPos(X + Width * 0.2f, Y);
    Canvas.DrawRect(Width * 0.6f, FMax(1.0f, 1.0f * ResScale));
    
    // Fade edges (20% each side, drawn as gradient steps)
    FadeWidth = Width * 0.2f;
    Steps = 8;
    StepWidth = FadeWidth / Steps;
    
    // Left fade (alpha increases toward center)
    for (i = 0; i < Steps; i++)
    {
        StepAlpha = (200 * Alpha) * (float(i) / float(Steps));
        Canvas.SetDrawColor(R, G, B, StepAlpha);
        Canvas.SetPos(X + StepWidth * i, Y);
        Canvas.DrawRect(StepWidth, FMax(1.0f, 1.0f * ResScale));
    }
    
    // Right fade (alpha decreases toward edge)
    for (i = 0; i < Steps; i++)
    {
        StepAlpha = (200 * Alpha) * (1.0f - float(i) / float(Steps));
        Canvas.SetDrawColor(R, G, B, StepAlpha);
        Canvas.SetPos(X + Width * 0.8f + StepWidth * i, Y);
        Canvas.DrawRect(StepWidth, FMax(1.0f, 1.0f * ResScale));
    }
}

// ===================================================================
// Popup Particle System (Improved)
// ===================================================================

function SpawnUnlockParticles(int Count, optional byte BaseR, optional byte BaseG, optional byte BaseB)
{
    local int i;
    local UnlockParticle NewParticle;
    local float Angle, ColorRand;
    
    // Default to gold if no color specified
    if (BaseR == 0 && BaseG == 0 && BaseB == 0)
    {
        BaseR = 255;
        BaseG = 215;
        BaseB = 0;
    }
    
    for (i = 0; i < Count; i++)
    {
        NewParticle.X = 0;
        NewParticle.Y = 0;
        
        Angle = FRand() * PI * 2.0f;
        NewParticle.VelocityX = Cos(Angle) * (60.0f + FRand() * 140.0f) * ResScale;
        NewParticle.VelocityY = (Sin(Angle) * (60.0f + FRand() * 140.0f) - 180.0f) * ResScale;
        
        // Varied lifetimes for trailing effect
        NewParticle.MaxLife = 1.2f + FRand() * 1.0f;
        NewParticle.Life = NewParticle.MaxLife;
        
        // Larger size range (scaled)
        NewParticle.Size = (5.0f + FRand() * 9.0f) * ResScale;
        
        // Color variation: mix base color with white/warm shifts
        ColorRand = FRand();
        if (ColorRand < 0.35f)
        {
            // Pure white sparks
            NewParticle.ColorR = 255;
            NewParticle.ColorG = 255;
            NewParticle.ColorB = 255;
        }
        else if (ColorRand < 0.65f)
        {
            // Base accent color
            NewParticle.ColorR = BaseR;
            NewParticle.ColorG = BaseG;
            NewParticle.ColorB = BaseB;
        }
        else
        {
            // Warm shifted (lighter/brighter variant)
            NewParticle.ColorR = Min(int(BaseR) + 40, 255);
            NewParticle.ColorG = Min(int(BaseG) + 30, 255);
            NewParticle.ColorB = Min(int(BaseB) + 80, 255);
        }
        
        UnlockParticles.AddItem(NewParticle);
    }
}

function UpdateUnlockParticles(float DeltaTime)
{
    local int i;
    
    for (i = UnlockParticles.Length - 1; i >= 0; i--)
    {
        UnlockParticles[i].X += UnlockParticles[i].VelocityX * DeltaTime;
        UnlockParticles[i].Y += UnlockParticles[i].VelocityY * DeltaTime;
        UnlockParticles[i].VelocityY += 300.0f * ResScale * DeltaTime;
        UnlockParticles[i].Life -= DeltaTime;
        
        if (UnlockParticles[i].Life <= 0.0f)
        {
            UnlockParticles.Remove(i, 1);
        }
    }
}

function DrawUnlockParticles(float ParticleCenterX, float ParticleCenterY, float GlobalAlpha)
{
    local int i;
    local float ParticleAlpha;
    local float X, Y, PSize;
    
    for (i = 0; i < UnlockParticles.Length; i++)
    {
        ParticleAlpha = (UnlockParticles[i].Life / UnlockParticles[i].MaxLife) * GlobalAlpha;
        
        X = ParticleCenterX + UnlockParticles[i].X;
        Y = ParticleCenterY + UnlockParticles[i].Y;
        PSize = UnlockParticles[i].Size;
        
        // Outer colored glow
        Canvas.SetDrawColor(
            UnlockParticles[i].ColorR,
            UnlockParticles[i].ColorG,
            UnlockParticles[i].ColorB,
            180 * ParticleAlpha
        );
        Canvas.SetPos(X - ResScale, Y - ResScale);
        Canvas.DrawRect(PSize + 2.0f * ResScale, PSize + 2.0f * ResScale);
        
        // Bright white core
        Canvas.SetDrawColor(255, 255, 255, 220 * ParticleAlpha);
        Canvas.SetPos(X + PSize * 0.2f, Y + PSize * 0.2f);
        Canvas.DrawRect(PSize * 0.6f, PSize * 0.6f);
    }
}

// ===================================================================
// Perk Unlock Notification Triggers
// ===================================================================

function ShowPerkUnlockNotification(string PerkName, Texture2D PerkIcon)
{
    UnlockPopup.PerkName = PerkName;
    UnlockPopup.PerkIcon = PerkIcon;
    UnlockPopup.DisplayTime = 8.0f;
    UnlockPopup.MaxDisplayTime = 8.0f;
    UnlockPopup.bIsActive = true;
    
    UnlockPopup.TitleColor = MakeColorFromRGB(255, 215, 0, 255);
    UnlockPopup.BackgroundColor = MakeColorFromRGB(0, 0, 0, 230);
    
    // Gold-themed particles
    SpawnUnlockParticles(35, 255, 215, 0);
    
    PlayPerkUnlockSound();
    
    `log("ZTHudWrapper: Showing perk unlock popup for" @ PerkName);
}

function PlayPerkUnlockSound()
{
    PlayerOwner.PlaySoundBase(AkEvent'WW_UI_Menu.Play_UI_Trader_Item_Buy', true);
}

// ===================================================================
// Achievement Unlock Popup Functions
// ===================================================================

function ShowAchievementUnlockNotification(string AchievementName, string Description, Texture2D AchievementIcon)
{
    AchievementPopup.AchievementName = AchievementName;
    AchievementPopup.Description = Description;
    AchievementPopup.AchievementIcon = AchievementIcon;
    AchievementPopup.DisplayTime = 8.0f;
    AchievementPopup.MaxDisplayTime = 8.0f;
    AchievementPopup.bIsActive = true;
    
    AchievementPopup.TitleColor = MakeColorFromRGB(255, 140, 0, 255);
    AchievementPopup.BackgroundColor = MakeColorFromRGB(0, 0, 0, 230);
    
    // Orange-themed particles
    SpawnUnlockParticles(35, 255, 140, 0);
    PlayAchievementUnlockSound();
    
    `log("ZTHudWrapper: Showing achievement unlock popup for" @ AchievementName);
}

function PlayAchievementUnlockSound()
{
    // Different sound from perk unlock
    PlayerOwner.PlaySoundBase(AkEvent'WW_UI_Menu.Play_UI_Trader_Open', true);
}

function DrawAchievementUnlockPopup()
{
    local float IconSize, BoxWidth, BoxHeight, BoxX, BoxY;
    local float TextX, TextY, PopupTextScale;
    local float XL, YL;
    local string TitleText, SubText, DescText;
    local float DeltaTime;
    local float AnimationProgress;
    local float ScaleFactor, AlphaFactor;
    local float GlowIntensity, GlowPulse;
    local Color TitleColor, NameColor, DescColor;
    local float TextAlpha;
    local float InnerX, InnerY, InnerW, InnerH;
    local float IconFrameSize;
    local float SepY;
    
    DeltaTime = class'WorldInfo'.static.GetWorldInfo().DeltaSeconds;
    AchievementPopup.DisplayTime -= DeltaTime;
    
    if (AchievementPopup.DisplayTime <= 0.0f)
    {
        AchievementPopup.bIsActive = false;
        return;
    }
    
    AnimationProgress = 1.0f - (AchievementPopup.DisplayTime / AchievementPopup.MaxDisplayTime);
    
    // Scale-in animation
    if (AnimationProgress < 0.125f)
    {
        ScaleFactor = 0.8f + (AnimationProgress / 0.125f) * 0.2f;
        AlphaFactor = AnimationProgress / 0.125f;
        GlowIntensity = 1.0f - (AnimationProgress / 0.125f);
    }
    else
    {
        ScaleFactor = 1.0f;
        AlphaFactor = 1.0f;
        GlowIntensity = 0.0f;
    }
    
    // Fade-out during last 1 second
    if (AchievementPopup.DisplayTime < 1.0f)
    {
        AlphaFactor *= AchievementPopup.DisplayTime;
    }
    
    // Continuous subtle glow pulse
    GlowPulse = 0.25f + 0.15f * Sin(AnimationProgress * 25.0f);
    
    // Text alpha (delayed fade-in)
    if (AnimationProgress < 0.0375f)
    {
        TextAlpha = 0.0f;
    }
    else if (AnimationProgress < 0.1f)
    {
        TextAlpha = (AnimationProgress - 0.0375f) / 0.0625f;
    }
    else
    {
        TextAlpha = 1.0f;
    }
    if (AchievementPopup.DisplayTime < 1.0f)
    {
        TextAlpha *= AchievementPopup.DisplayTime;
    }
    
    // --- Box dimensions (taller to fit description, scaled from 1080p baseline) ---
    IconSize = 192.0f * ResScale * 0.667f * ScaleFactor;
    BoxWidth = 860.0f * ResScale * 0.667f * ScaleFactor;
    BoxHeight = 270.0f * ResScale * 0.667f * ScaleFactor;
    
    BoxX = (Canvas.SizeX - BoxWidth) / 2.0f;
    BoxY = Canvas.SizeY * 0.35f;
    
    // --- Initial burst glow (orange) ---
    if (GlowIntensity > 0.0f)
    {
        DrawPopupGlow(BoxX, BoxY, BoxWidth, BoxHeight, GlowIntensity * AlphaFactor, 255, 140, 0);
    }
    
    // --- Layered background ---
    Canvas.SetDrawColor(5, 5, 12, 230 * AlphaFactor);
    Canvas.SetPos(BoxX, BoxY);
    Canvas.DrawRect(BoxWidth, BoxHeight);
    
    InnerX = BoxX + 4.0f * ResScale;
    InnerY = BoxY + 4.0f * ResScale;
    InnerW = BoxWidth - 8.0f * ResScale;
    InnerH = BoxHeight - 8.0f * ResScale;
    Canvas.SetDrawColor(15, 15, 28, 210 * AlphaFactor);
    Canvas.SetPos(InnerX, InnerY);
    Canvas.DrawRect(InnerW, InnerH);
    
    // --- Outer border (2px, orange, scaled) ---
    Canvas.SetDrawColor(255, 140, 0, 255 * AlphaFactor);
    DrawBox(BoxX, BoxY, BoxWidth, BoxHeight, 2.0f * ResScale);
    
    // --- Inner border (1px, orange at 40% + pulse, scaled) ---
    Canvas.SetDrawColor(255, 140, 0, (100 + 60 * GlowPulse) * AlphaFactor);
    DrawBox(BoxX + 8.0f * ResScale, BoxY + 8.0f * ResScale, BoxWidth - 16.0f * ResScale, BoxHeight - 16.0f * ResScale, FMax(1.0f, 1.0f * ResScale));
    
    // --- Corner brackets (orange, pulsing) ---
    DrawCornerBrackets(BoxX, BoxY, BoxWidth, BoxHeight, AlphaFactor, GlowPulse, 255, 140, 0);
    
    // --- Icon with frame ---
    if (AchievementPopup.AchievementIcon != None)
    {
        IconFrameSize = IconSize + 6.0f * ResScale;
        
        // Icon frame (orange border, scaled)
        Canvas.SetDrawColor(255, 140, 0, (180 + 75 * GlowPulse) * AlphaFactor);
        DrawBox(BoxX + 28.0f * ResScale, BoxY + (BoxHeight - IconFrameSize) / 2.0f, IconFrameSize, IconFrameSize, 2.0f * ResScale);
        
        // Dark background behind icon
        Canvas.SetDrawColor(8, 8, 15, 255 * AlphaFactor);
        Canvas.SetPos(BoxX + 31.0f * ResScale, BoxY + (BoxHeight - IconSize) / 2.0f);
        Canvas.DrawRect(IconSize, IconSize);
        
        // The icon itself
        Canvas.SetDrawColor(255, 255, 255, 255 * AlphaFactor);
        Canvas.SetPos(BoxX + 31.0f * ResScale, BoxY + (BoxHeight - IconSize) / 2.0f);
        Canvas.DrawTile(
            AchievementPopup.AchievementIcon,
            IconSize,
            IconSize,
            0, 0,
            AchievementPopup.AchievementIcon.SizeX,
            AchievementPopup.AchievementIcon.SizeY
        );
    }
    
    // --- Text area ---
    Canvas.Font = class'Engine'.Static.GetLargeFont();
    TitleText = "ACHIEVEMENT UNLOCKED!";
    SubText = AchievementPopup.AchievementName;
    DescText = AchievementPopup.Description;
    
    TextX = BoxX + IconSize + 70.0f * ResScale;
    
    // --- Horizontal separator (positioned to divide title from content) ---
    SepY = BoxY + (BoxHeight * 0.38f);
    DrawHorizontalSeparator(TextX, SepY, BoxWidth - IconSize - 100.0f * ResScale, AlphaFactor * 0.6f, 255, 140, 0);
    
    // --- Title text (above separator, scaled) ---
    PopupTextScale = 1.0f * ScaleFactor * ResScale;
    TitleColor.R = 255;
    TitleColor.G = 140;
    TitleColor.B = 0;
    TitleColor.A = 255 * TextAlpha;
    Canvas.SetDrawColor(TitleColor.R, TitleColor.G, TitleColor.B, TitleColor.A);
    
    Canvas.StrLen(TitleText, XL, YL);
    YL *= PopupTextScale;
    TextY = SepY - YL - 8.0f * ResScale;
    
    Canvas.SetPos(TextX, TextY);
    Canvas.DrawText(TitleText, true, PopupTextScale, PopupTextScale);
    
    // --- Achievement name (below separator, scaled) ---
    PopupTextScale = 1.2f * ScaleFactor * ResScale;
    NameColor.R = 255;
    NameColor.G = 255;
    NameColor.B = 255;
    NameColor.A = 255 * TextAlpha;
    Canvas.SetDrawColor(NameColor.R, NameColor.G, NameColor.B, NameColor.A);
    
    TextY = SepY + 10.0f * ResScale;
    
    Canvas.SetPos(TextX, TextY);
    Canvas.DrawText(SubText, true, PopupTextScale, PopupTextScale);
    
    // --- Description text (below name, smaller and gray, scaled) ---
    if (DescText != "")
    {
        Canvas.StrLen(SubText, XL, YL);
        YL *= PopupTextScale;
        
        PopupTextScale = 0.85f * ScaleFactor * ResScale;
        DescColor.R = 180;
        DescColor.G = 180;
        DescColor.B = 190;
        DescColor.A = 230 * TextAlpha;
        Canvas.SetDrawColor(DescColor.R, DescColor.G, DescColor.B, DescColor.A);
        
        TextY = SepY + 10.0f * ResScale + YL + 6.0f * ResScale;
        
        Canvas.SetPos(TextX, TextY);
        Canvas.DrawText(DescText, true, PopupTextScale, PopupTextScale);
    }
    
    // --- Particles ---
    UpdateUnlockParticles(DeltaTime);
    DrawUnlockParticles(BoxX + BoxWidth / 2.0f, BoxY + BoxHeight / 2.0f, AlphaFactor);
}

// ===================================================================
// ACTIVE ABILITY DISPLAY FUNCTIONS
// ===================================================================

function UpdateAbilitySlot(int SlotIndex, string AbilityName, bool bHasAbility, optional Texture2D AbilityIcon)
{
    if (SlotIndex < 0 || SlotIndex >= 4)
        return;
    
    AbilitySlots[SlotIndex].bHasAbility = bHasAbility;
    AbilitySlots[SlotIndex].AbilityName = AbilityName;
    AbilitySlots[SlotIndex].AbilityIcon = AbilityIcon;
    
    if (!bHasAbility)
    {
        AbilitySlots[SlotIndex].bIsActive = false;
        AbilitySlots[SlotIndex].bOnCooldown = false;
        AbilitySlots[SlotIndex].RemainingTime = 0.0f;
        AbilitySlots[SlotIndex].MaxTime = 0.0f;
    }
}

function UpdateAbilityState(int SlotIndex, bool bIsActive, bool bOnCooldown, float RemainingTime, float MaxTime)
{
    if (SlotIndex < 0 || SlotIndex >= 4)
        return;
    
    AbilitySlots[SlotIndex].bIsActive = bIsActive;
    AbilitySlots[SlotIndex].bOnCooldown = bOnCooldown;
    AbilitySlots[SlotIndex].RemainingTime = RemainingTime;
    AbilitySlots[SlotIndex].MaxTime = MaxTime;
	
	`log("ZTHudWrapper (CLIENT): UpdateAbilityState slot" @ SlotIndex);
	`log("  RemainingTime:" @ RemainingTime @ "MaxTime:" @ MaxTime);
}



function DrawAbilitySlots()
{
    local int i;
    local float StartX, XPos, YPos;
    local float TotalWidth;
    local float SlotW, SlotH, SlotSp;
    
    if (Canvas == None)
        return;

    SlotW = AbilitySlotWidth * ResScale;
    SlotH = AbilitySlotHeight * ResScale;
    SlotSp = AbilitySlotSpacing * ResScale;
    
    TotalWidth = (SlotW * 4) + (SlotSp * 3);
    
    StartX = (Canvas.SizeX * AbilityDisplayX) - (TotalWidth / 2);
    YPos = Canvas.SizeY * AbilityDisplayY;
    
    for (i = 0; i < 4; i++)
    {
        XPos = StartX + (i * (SlotW + SlotSp));
        DrawSingleAbilitySlot(AbilitySlots[i], XPos, YPos, i + 1, SlotW, SlotH);
    }
}

function DrawSingleAbilitySlot(AbilitySlotDisplay Slot, float X, float Y, int SlotNumber, float SlotW, float SlotH)
{
    local Color SlotColor, TextColor, BarColor;
    local float BarWidth, BarHeight, BarY;
    local float TimePercent;
    local string DisplayText;
    local float TextWidth, TextHeight;
    local float IconSize, IconX, IconY;
    local float TxtSc;
    
    if (Canvas == None)
        return;

    TxtSc = 1.2f * ResScale;
    
    if (!Slot.bHasAbility)
    {
        SlotColor.R = 0;
        SlotColor.G = 0;
        SlotColor.B = 0;
        SlotColor.A = 255;
        
        Canvas.SetDrawColor(SlotColor.R, SlotColor.G, SlotColor.B, SlotColor.A);
        DrawBox(X, Y, SlotW, SlotH, 3.0f * ResScale);
        
        Canvas.SetDrawColor(100, 100, 100, 255);
        Canvas.Font = class'Engine'.Static.GetMediumFont();
        DisplayText = string(SlotNumber);
        Canvas.TextSize(DisplayText, TextWidth, TextHeight, TxtSc, TxtSc);
        Canvas.SetPos(X + (SlotW - TextWidth * TxtSc) / 2, Y + (SlotH - TextHeight * TxtSc) / 2);
        Canvas.DrawText(DisplayText, false, TxtSc, TxtSc);
    }
    else
    {
        if (Slot.bIsActive)
        {
            SlotColor.R = 0;
            SlotColor.G = 255;
            SlotColor.B = 100;
            SlotColor.A = 200;
            TextColor.R = 255;
            TextColor.G = 255;
            TextColor.B = 255;
            TextColor.A = 255;
            BarColor.R = 0;
            BarColor.G = 200;
            BarColor.B = 50;
            BarColor.A = 255;
        }
        else if (Slot.bOnCooldown)
        {
            SlotColor.R = 80;
            SlotColor.G = 80;
            SlotColor.B = 80;
            SlotColor.A = 180;
            TextColor.R = 150;
            TextColor.G = 150;
            TextColor.B = 150;
            TextColor.A = 255;
            BarColor.R = 100;
            BarColor.G = 100;
            BarColor.B = 100;
            BarColor.A = 255;
        }
        else
        {
            SlotColor.R = 100;
            SlotColor.G = 50;
            SlotColor.B = 150;
            SlotColor.A = 200;
            TextColor.R = 255;
            TextColor.G = 255;
            TextColor.B = 255;
            TextColor.A = 255;
            BarColor.R = 120;
            BarColor.G = 60;
            BarColor.B = 180;
            BarColor.A = 255;
        }
        
        Canvas.SetDrawColor(SlotColor.R, SlotColor.G, SlotColor.B, SlotColor.A);
        Canvas.SetPos(X, Y);
        Canvas.DrawRect(SlotW, SlotH);
        
        Canvas.SetDrawColor(0, 0, 0, 255);
        DrawBox(X, Y, SlotW, SlotH, 2.0f * ResScale);
        
        if (Slot.AbilityIcon != None)
        {
            IconSize = SlotH * 0.6f;
            IconX = X + (SlotW - IconSize) / 2;
            IconY = Y + (SlotH - IconSize) / 2;
            
            Canvas.SetDrawColor(255, 255, 255, 255);
            Canvas.SetPos(IconX, IconY);
            Canvas.DrawTexture(Slot.AbilityIcon, IconSize / Slot.AbilityIcon.SizeX);
        }
        
        if ((Slot.bIsActive || Slot.bOnCooldown) && Slot.MaxTime > 0)
        {
            TimePercent = Slot.RemainingTime / Slot.MaxTime;
            BarWidth = SlotW - 10 * ResScale;
            BarHeight = 6.0f * ResScale;
            BarY = Y + SlotH - BarHeight - 5 * ResScale;
            
            Canvas.SetDrawColor(30, 30, 30, 200);
            Canvas.SetPos(X + 5 * ResScale, BarY);
            Canvas.DrawRect(BarWidth, BarHeight);
            
            Canvas.SetDrawColor(BarColor.R, BarColor.G, BarColor.B, BarColor.A);
            Canvas.SetPos(X + 5 * ResScale, BarY);
            Canvas.DrawRect(BarWidth * TimePercent, BarHeight);
        }
        else
        {
            Canvas.SetDrawColor(TextColor.R, TextColor.G, TextColor.B, TextColor.A);
            Canvas.Font = class'Engine'.Static.GetMediumFont();
            DisplayText = string(SlotNumber);
            Canvas.TextSize(DisplayText, TextWidth, TextHeight, ResScale, ResScale);
            Canvas.SetPos(X + (SlotW - TextWidth) / 2, Y + (SlotH - TextHeight) / 2);
            Canvas.DrawText(DisplayText, false, ResScale, ResScale);
        }
    }
}

function DrawBox(float X, float Y, float Width, float Height, float Thickness)
{
    Canvas.SetPos(X, Y);
    Canvas.DrawRect(Width, Thickness);
    Canvas.SetPos(X, Y + Height - Thickness);
    Canvas.DrawRect(Width, Thickness);
    Canvas.SetPos(X, Y);
    Canvas.DrawRect(Thickness, Height);
    Canvas.SetPos(X + Width - Thickness, Y);
    Canvas.DrawRect(Thickness, Height);
}

// ===================================================================
// EXEC FUNCTIONS FOR PLAYER INPUT
// ===================================================================

exec function ToggleSymbiotePanel()
{
    ToggleEvolutionPanel();
}

// ===================================================================
// TOTAL STAT INCREASE PANEL (Phase 1)
// Called from ZTPlayerController.ToggleStats() / ClientToggleStats().
// Flips the local bShowStatPanel flag — DrawHUD picks it up next frame.
// ===================================================================
function ToggleStatPanel()
{
    bShowStatPanel = !bShowStatPanel;
}

exec function ToggleScavengerPanel()
{
    ToggleScavengerAdaptationPanel();
}

exec function ToggleTycoonPanel()
{
    ToggleTycoonPortfolioPanel();
}

exec function ToggleForgeWardenPanel()
{
    ToggleForgeWardenMilestonePanel();
}

exec function ToggleHydraPanel()
{
    local KFPlayerController KFPC;
    local ZTUpgrade_Perk_Hydra_Helper HydraHelper;
    local KFPawn OwnerPawn;
    local string HydraStatus;
    
    KFPC = KFPlayerController(class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController());
    if (KFPC != None && KFPC.Pawn != None)
    {
        OwnerPawn = KFPawn(KFPC.Pawn);
        if (OwnerPawn != None)
        {
            HydraHelper = class'ZTUpgrade_Perk_Hydra'.static.GetHelper(OwnerPawn);
            if (HydraHelper != None)
            {
                if (HydraHelper.bInFuryMode)
                {
                    HydraStatus = "FURY MODE ACTIVE! " $ int(HydraHelper.FuryModeTimer) $ " seconds remaining.";
                }
                else
                {
                    HydraStatus = "Fury Progress: " $ HydraHelper.KillsToDisplay $ "/75 kills";
                }
                
                class'ZTMessageManager'.static.SendImportant(KFPC, "HYDRA STATUS: " $ HydraStatus);
                class'ZTMessageManager'.static.SendMinor(KFPC, "Total Kills: " $ HydraHelper.TotalKills);
            }
            else
            {
                class'ZTMessageManager'.static.SendMinor(KFPC, "Hydra perk not active.");
            }
        }
    }
}

exec function ToggleWendigoPanel()
{
    local KFPlayerController KFPC;
    local ZTUpgrade_Perk_Wendigo_Helper WendigoHelper;
    local KFPawn OwnerPawn;
    local string WendigoStatus;
    
    KFPC = KFPlayerController(class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController());
    if (KFPC != None && KFPC.Pawn != None)
    {
        OwnerPawn = KFPawn(KFPC.Pawn);
        if (OwnerPawn != None)
        {
            WendigoHelper = class'ZTUpgrade_Perk_Wendigo'.static.GetHelper(OwnerPawn);
            if (WendigoHelper != None)
            {
                WendigoStatus = WendigoHelper.GetStalkingSummary();
                class'ZTMessageManager'.static.SendImportant(KFPC, "WENDIGO STATUS: " $ WendigoStatus);
                
                if (WendigoHelper.bApexStalkerActive)
                {
                    class'ZTMessageManager'.static.SendImportant(KFPC, "Apex Stalker: ACTIVE - +35% damage until hit");
                }
                else if (WendigoHelper.bFirstShotReady)
                {
                    class'ZTMessageManager'.static.SendImportant(KFPC, "Perfect Ambush: READY - Next shot +50% damage");
                }
                
                class'ZTMessageManager'.static.SendMinor(KFPC, "Stalking Tips: Wait 5s for damage bonus, 10s for perfect ambush, 30s no damage for Apex Stalker");
            }
            else
            {
                class'ZTMessageManager'.static.SendMinor(KFPC, "Wendigo perk not active.");
            }
        }
    }
}

exec function ToggleArchangelPanel()
{
    local KFPlayerController KFPC;
    local ZTUpgrade_Perk_Archangel_Helper ArchangelHelper;
    local KFPawn OwnerPawn;
    local string ArchangelStatus;
    
    KFPC = KFPlayerController(class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController());
    if (KFPC != None && KFPC.Pawn != None)
    {
        OwnerPawn = KFPawn(KFPC.Pawn);
        if (OwnerPawn != None)
        {
            ArchangelHelper = class'ZTUpgrade_Perk_Archangel'.static.GetHelper(OwnerPawn);
            if (ArchangelHelper != None)
            {
                ArchangelStatus = ArchangelHelper.GetHealingSummary();
                class'ZTMessageManager'.static.SendImportant(KFPC, "ARCHANGEL STATUS: " $ ArchangelStatus);
                
                class'ZTMessageManager'.static.SendMinor(KFPC, "Total Healing Done: " $ ArchangelHelper.TotalHealingDone $ " HP");
                class'ZTMessageManager'.static.SendMinor(KFPC, "Allies Healed: " $ ArchangelHelper.AlliesHealed);
                if (ArchangelHelper.MiracleRecoveries > 0)
                {
                    class'ZTMessageManager'.static.SendMinor(KFPC, "Miracle Recoveries: " $ ArchangelHelper.MiracleRecoveries);
                }
                if (ArchangelHelper.bHealingAuraActive)
                {
                    class'ZTMessageManager'.static.SendImportant(KFPC, "Healing Aura: ACTIVE - Allies within 6m regenerate 1 HP/sec");
                }
                class'ZTMessageManager'.static.SendMinor(KFPC, "Support Tips: Heal allies for milestones, stay near team for bonuses");
            }
            else
            {
                class'ZTMessageManager'.static.SendMinor(KFPC, "Archangel perk not active.");
            }
        }
    }
}

exec function ToggleMedusaPanel()
{
    local KFPlayerController KFPC;
    local ZTUpgrade_Perk_Medusa_Helper MedusaHelper;
    local KFPawn OwnerPawn;
    local string MedusaStatus;
    
    KFPC = KFPlayerController(class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController());
    if (KFPC != None && KFPC.Pawn != None)
    {
        OwnerPawn = KFPawn(KFPC.Pawn);
        if (OwnerPawn != None)
        {
            MedusaHelper = class'ZTUpgrade_Perk_Medusa'.static.GetHelper(OwnerPawn);
            if (MedusaHelper != None)
            {
                MedusaStatus = MedusaHelper.GetVenomStatus();
                class'ZTMessageManager'.static.SendImportant(KFPC, "MEDUSA STATUS: " $ MedusaStatus);
                
                class'ZTMessageManager'.static.SendMinor(KFPC, "Total Poison Damage: " $ MedusaHelper.TotalPoisonDamage);
                if (MedusaHelper.bFullGorgonAchieved)
                {
                    class'ZTMessageManager'.static.SendCritical(KFPC, "Full Gorgon: ACTIVE - Permanent +20% headshot damage");
                }
                else
                {
                    class'ZTMessageManager'.static.SendMinor(KFPC, "Current Bonuses: +" $ (MedusaHelper.CurrentScales * 3) $ "% damage resistance, +" $ (MedusaHelper.CurrentScales * 2) $ "% movement speed");
                }
                class'ZTMessageManager'.static.SendMinor(KFPC, "Venom Tips: All damage applies poison at level 10+, kills spread poison at level 20+");
            }
            else
            {
                class'ZTMessageManager'.static.SendMinor(KFPC, "Medusa perk not active.");
            }
        }
    }
}

exec function ToggleRiotPanel()
{
    local KFPlayerController KFPC;
    local ZTUpgrade_Perk_Riot_Helper RiotHelper;
    local KFPawn OwnerPawn;
    local string RiotStatus;
    local int NearbyCount;
    local bool bMaxBonus;
    
    KFPC = KFPlayerController(class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController());
    if (KFPC != None && KFPC.Pawn != None)
    {
        OwnerPawn = KFPawn(KFPC.Pawn);
        if (OwnerPawn != None)
        {
            RiotHelper = class'ZTUpgrade_Perk_Riot'.static.GetHelper(OwnerPawn);
            if (RiotHelper != None)
            {
                NearbyCount = RiotHelper.GetNearbyEnemyCount();
                bMaxBonus = (NearbyCount >= 5);
                
                if (bMaxBonus)
                {
                    RiotStatus = "RIOT CONTROL ACTIVE! " $ NearbyCount $ " enemies nearby.";
                    class'ZTMessageManager'.static.SendCritical(KFPC, RiotStatus);
                    class'ZTMessageManager'.static.SendImportant(KFPC, "Bonuses: Stumble Immunity, +30% Movement, +20% Attack Speed");
                }
                else if (NearbyCount >= 3)
                {
                    RiotStatus = NearbyCount $ " enemies nearby - Stumble Immunity active!";
                    class'ZTMessageManager'.static.SendImportant(KFPC, "RIOT STATUS: " $ RiotStatus);
                }
                else if (NearbyCount > 0)
                {
                    RiotStatus = NearbyCount $ " enemies nearby - Building bonuses...";
                    class'ZTMessageManager'.static.SendMinor(KFPC, "RIOT STATUS: " $ RiotStatus);
                }
                else
                {
                    RiotStatus = "No enemies nearby - Find a crowd!";
                    class'ZTMessageManager'.static.SendMinor(KFPC, "RIOT STATUS: " $ RiotStatus);
                }
                
                class'ZTMessageManager'.static.SendMinor(KFPC, "Combat Tips: Get surrounded by enemies for maximum power (3+ for stumble immunity, 5+ for max bonuses)");
            }
            else
            {
                class'ZTMessageManager'.static.SendMinor(KFPC, "Riot perk not active.");
            }
        }
    }
}

// ===================================================================
// NEW: AGONY PANEL TOGGLE FUNCTION
// ===================================================================

/**
 * Toggle Agony panel for debugging/info display
 * Shows current ZED time status and cumulative time information
 */
exec function ToggleAgonyPanel()
{
    local KFPlayerController KFPC;
    local ZTUpgrade_Perk_Agony_Helper AgonyHelper;
    local KFPawn OwnerPawn;
    local string StatusMessage;
    
    KFPC = KFPlayerController(class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController());
    if (KFPC != None && KFPC.Pawn != None)
    {
        OwnerPawn = KFPawn(KFPC.Pawn);
        if (OwnerPawn != None)
        {
            AgonyHelper = class'ZTUpgrade_Perk_Agony'.static.GetHelper(OwnerPawn);
            if (AgonyHelper != None)
            {
                // Show current status
                if (AgonyHelper.bZedTimeActive)
                {
                    StatusMessage = "ZED TIME ACTIVE - Agony bonuses active!";
                }
                else
                {
                    StatusMessage = "Standby - Waiting for ZED time...";
                }
                
                class'ZTMessageManager'.static.SendImportant(KFPC, "AGONY STATUS: " $ StatusMessage);
                class'ZTMessageManager'.static.SendMinor(KFPC, "Upgrade Level: " $ AgonyHelper.UpgradeLevel);
                
                if (AgonyHelper.UpgradeLevel >= class'ZTConfig_Capstone'.default.Capstone_Rank2Level)
                {
                    class'ZTMessageManager'.static.SendCritical(
                        KFPC, 
                        "TIME BANKER: " $ int(AgonyHelper.TotalZedTimeSeconds) $ " seconds total | " $ 
                        AgonyHelper.DoshRewardsEarned $ " rewards earned (+" $ (AgonyHelper.DoshRewardsEarned * 500) $ " dosh)"
                    );
                    
                    class'ZTMessageManager'.static.SendMinor(
                        KFPC, 
                        "Next reward in " $ (120 - (int(AgonyHelper.TotalZedTimeSeconds) % 120)) $ " seconds"
                    );
                }
                
                if (AgonyHelper.UpgradeLevel >= class'ZTConfig_Capstone'.default.Capstone_Rank1Level)
                    class'ZTMessageManager'.static.SendMinor(KFPC, "Headshot extensions enabled (30% chance)");
                if (AgonyHelper.UpgradeLevel >= class'ZTConfig_Capstone'.default.Capstone_Rank2Level)
                    class'ZTMessageManager'.static.SendMinor(KFPC, "Time Banker enabled (500 dosh per 120 seconds)");
            }
            else
            {
                class'ZTMessageManager'.static.SendMinor(KFPC, "Agony perk not active.");
            }
        }
    }
}

// ===================================================================
// RESOLUTION SCALING - Auto-detection, Config Loading, Overflow Protection
// ===================================================================

/** Load HUD preferences from client-side INI (ZedternalTempered_Local.ini).
 *  Called once from PostBeginPlay. Values persist across sessions. */
function LoadHudPreferences()
{
    HudScaleMultiplier = class'ZTConfig_HudPreferences'.static.GetHudScaleMultiplier();
    CardStackMaxY = class'ZTConfig_HudPreferences'.static.GetCardStackMaxY();
    CardStackMaxCards = class'ZTConfig_HudPreferences'.static.GetCardStackMaxCards();

    // Initialize rank display preferences (sets defaults on first run)
    class'ZTConfig_HudPreferences'.static.InitRankPrefs();

    bHudPrefsLoaded = true;

    `log("[DK_HUD] Preferences loaded: Multiplier=" $ HudScaleMultiplier
        $ " CardStackMaxY=" $ CardStackMaxY
        $ " CardStackMaxCards=" $ CardStackMaxCards);
}

/** Compute ResScale every frame from Canvas resolution + user multiplier.
 *  Non-linear curve dampens growth above 1080p so 4K doesn't blow up.
 *
 *  Below/at 1080p: linear from 720p baseline (1.0x at 720p, 1.5x at 1080p)
 *  Above 1080p:    1.5 * sqrt(SizeY / 1080) - logarithmic dampening
 *    1440p -> 1.73x, 2160p (4K) -> 2.12x, 2880p (5K) -> 2.45x
 *
 *  Then multiplied by user preference (HudScaleMultiplier, default 1.0). */
function ComputeResScale()
{
    local float ScreenH;

    if (Canvas == None)
        return;

    ScreenH = float(Canvas.SizeY);

    // Non-linear auto curve
    if (ScreenH <= 1080.0f)
        AutoResScale = ScreenH / 720.0f;
    else
        AutoResScale = 1.5f * Sqrt(ScreenH / 1080.0f);

    // Apply user multiplier
    ResScale = AutoResScale * HudScaleMultiplier;

    // Clamp to sane range
    if (ResScale < 0.5f)
        ResScale = 0.5f;
    else if (ResScale > 5.0f)
        ResScale = 5.0f;
}

/** Get resolution tier name for debug/info display. */
static function string GetResolutionTierName(int ScreenHeight)
{
    if (ScreenHeight <= 600)
        return "SD";
    else if (ScreenHeight <= 768)
        return "720p";
    else if (ScreenHeight <= 1080)
        return "1080p";
    else if (ScreenHeight <= 1440)
        return "1440p";
    else if (ScreenHeight <= 2160)
        return "4K";
    else
        return "5K+";
}

// ===================================================================
// POST RENDER - Override to maintain Redacted overlay when bShowHUD is false
// When Redacted is active, bShowHUD=false hides the Flash movie natively
// but also prevents DrawHUD from being called. PostRender still fires,
// so we use it to keep UpdateEventWaveState running and draw the overlay.
// ===================================================================

event PostRender()
{
    super.PostRender();

    // Draw event wave overlays AFTER super (which draws Flash movies + scoreboard).
    // This ensures overlays render ON TOP of the scoreboard and all Flash elements.
    if (Canvas != None && EventWaveOverlayID > 0 && EventWaveAlpha > 0.0f)
    {
        // When Redacted is active, bShowHUD=false so DrawHUD was skipped.
        // We must manually run UpdateEventWaveState here to detect event end.
        if (bRedactedHUDHidden)
        {
            Canvas.Font = class'KFGameEngine'.Static.GetKFCanvasFont();
            UpdateEventWaveState();
        }

        // Draw the overlay effect (RAGE red, Isolation blue, etc.)
        class'ZTEventWave'.static.DrawOverlay(Canvas, EventWaveOverlayID, EventWaveAlpha,
            WorldInfo.TimeSeconds - EventWaveStartTimeLocal);

        // Redacted: draw the REDACTED watermark
        if (EventWaveOverlayID == 19 && EventWaveAlpha > 0.5f)
        {
            DrawRedactedOverlay();
        }

        // Event wave banner
        if (EventWaveBannerTimer > 0.0f)
        {
            DrawEventWaveBanner();
        }

        // X-Men power display (center-left)
        if (EventWaveOverlayID == 23)
        {
            DrawXMenPowerDisplay();
        }
    }

    // Zed-form (transform): hide the Flash survival HUD by clearing bShowHUD
    // (which skips DrawHUD, exactly like REDACTED does) and draw our zed HUD
    // here in PostRender instead, so the normal player HUD no longer overlays
    // it. Restore bShowHUD when we are back in the human body.
    if (Canvas != None && PlayerOwner != None)
    {
        if (KFPawn_Monster(PlayerOwner.Pawn) != None)
        {
            if (bShowHUD)
            {
                bShowHUD = false;
                bZedFormHidHUD = true;
            }
            DrawZedFormHUD();
            DrawPossessionInfo();
        }
        else if (bZedFormHidHUD)
        {
            bShowHUD = !bRedactedHUDHidden;
            bZedFormHidHUD = false;
        }
    }
}

// ===================================================================
// MAIN HUD DRAWING - DrawHUD for perk trackers and notifications
// ===================================================================

event DrawHUD()
{
    local WMGameReplicationInfo WMGRI;
    local int SavedSWID0, SavedSWID1;

    // Guard: temporarily suppress SpecialWaveID for this frame if the
    // class reference is None or the index is out of bounds.
    // Prevents the red "+" artifact from WMGFxHudWrapper drawing empty titles.
    // Restored after super so server replication state is not permanently altered.
    WMGRI = WMGameReplicationInfo(KFGRI);
    if (WMGRI != None)
    {
        SavedSWID0 = WMGRI.SpecialWaveID[0];
        SavedSWID1 = WMGRI.SpecialWaveID[1];

        if (SavedSWID0 != INDEX_NONE)
        {
            if (SavedSWID0 >= WMGRI.SpecialWavesList.Length || WMGRI.SpecialWavesList[SavedSWID0].SpecialWave == None)
                WMGRI.SpecialWaveID[0] = INDEX_NONE;
        }
        if (SavedSWID1 != INDEX_NONE)
        {
            if (SavedSWID1 >= WMGRI.SpecialWavesList.Length || WMGRI.SpecialWavesList[SavedSWID1].SpecialWave == None)
                WMGRI.SpecialWaveID[1] = INDEX_NONE;
        }
    }

    Super.DrawHUD();
    
    if (Canvas != None)
    {
        // Event Wave state update (fade in/out, Isolation, DeadSilence, Paranoia, Redacted)
        UpdateEventWaveState();
        // NOTE: Event wave overlays are drawn in PostRender() so they render
        // on top of the scoreboard and all Flash elements.

        // Compute resolution scale factor (non-linear curve + user multiplier)
        ComputeResScale();

        // REDACTED (Event 19): Black out all HUD areas, skip all DK HUD drawing
        if (EventWaveOverlayID == 19 && EventWaveAlpha > 0.5f)
        {
            DrawRedactedOverlay();
            // Restore SpecialWaveIDs and return
            if (WMGRI != None)
            {
                WMGRI.SpecialWaveID[0] = SavedSWID0;
                WMGRI.SpecialWaveID[1] = SavedSWID1;
            }
            return;
        }

        // Redraw ZedBuff stack counts at bottom-center (covers parent's top-right text)
        DrawZedBuffStackOverrides();

        if (PerkTrackers.Length > 0)
        {
            UpdateTrackerTimers();
            DrawPerkInfoCards();
        }
        
        if (InstantKillNotif.bIsActive)
        {
            UpdateInstantKillTimer();
            DrawInstantKillNotification();
        }
        
        if (ChainNotif.bIsActive)
        {
            UpdateChainNotificationTimer();
            DrawChainNotification();
        }
        
        if (EvolutionPanel.bShowPanel)
        {
            UpdateEvolutionPanelTimer();
            DrawEvolutionPanel();
        }
        
        if (NotificationMessages.Length > 0)
        {
            UpdateNotificationTimers();
            DrawNotificationFeed();
        }
        
        if (AbilitySlots.Length > 0)
        {
            DrawAbilitySlots();
        }
        
        
        // Rebuild display card positions before drawing any cards
        RebuildDisplayCardStack();
        
        // Draw Shapeshifter buff display
        if (ShapeshifterDisplay.bIsActive && !bHideShapeshifterCard)
        {
            DrawShapeshifterDisplay();
        }
        
        // Draw Gambit challenge display
        if (GambitDisplay.bIsActive && !bHideGambitCard)
        {
            DrawGambitDisplay();
        }
        
        // Draw Jekyll & Hyde serum display
        if (HydeDisplay.bIsActive && !bHideHydeCard)
        {
            DrawHydeDisplay();
        }

        // Draw Domain room display
        if (DomainDisplay.bIsActive && !bHideDomainCard)
        {
            DrawDomainDisplay();
        }

        // Draw Speedster blink card (in card stack)
        if (SpeedsterDisplay.bIsActive && !bHideSpeedsterCard)
        {
            DrawSpeedsterCard();
        }

        // Draw Possessor possession card (in card stack)
        if (PossessorDisplay.bIsActive && !bHidePossessorCard)
        {
            DrawPossessorCard();
        }
        
        // Draw Artificer forge display
        if (ArtificerDisplay.bIsActive && !bHideArtificerCard)
        {
            DrawArtificerDisplay();
        }
        
        // Draw Predator card (in card stack)
        if (PredatorDisplay.bIsActive && !bHidePredatorCard)
        {
            DrawPredatorCard();
        }
        
        // Draw Omen prophecy card (in card stack)
        if (OmenDisplay.bIsActive && !bHideOmenCard)
        {
            DrawOmenCard();
        }
        
        // Draw Hollow trial card (in card stack)
        if (HollowDisplay.bIsActive && !bHideHollowCard)
        {
            DrawHollowCard();
        }
        
        // Draw Metronome phase card (in card stack)
        if (MetronomeDisplay.bIsActive && !bHideMetronomeCard)
        {
            DrawMetronomeCard();
        }
        
        // Draw Detonator card (in card stack)
        if (DetonatorDisplay.bIsActive && !bHideDetonatorCard)
        {
            DrawDetonatorCard();
        }
        
        // Draw Gambit buffs overlay (toggled by console command)
        if (bShowGambitBuffs)
        {
            DrawGambitBuffsOverlay();
        }
        
        // Draw Predator trophy overlay (toggled by console command)
        if (bShowPredatorTrophies)
        {
            DrawPredatorTrophyOverlay();
        }
        
        if (UnlockPopup.bIsActive)
        {
            DrawPerkUnlockPopup();
        }
        
        if (AchievementPopup.bIsActive)
        {
            DrawAchievementUnlockPopup();
        }
        
        // Event Wave target player icon (VIP/HotPotato/Highlander/MarkedForDeath)
        if (EventWaveOverlayID == 9 || EventWaveOverlayID == 10 || EventWaveOverlayID == 12 || EventWaveOverlayID == 18)
        {
            DrawEventWaveTargetIcon();
            DrawEventWaveStatusIndicator();
        }

        // Event Wave announcement banner + overlays drawn in PostRender()

        // Dev stat overlay (toggled via console: StatOverlay, cycles Off/Basic/Sources)
        if (StatOverlayMode > 0)
        {
            DrawStatOverlay();
        }

        // Scoreboard drawing is handled by ZTGFxScoreBoardWrapper.PostRender().

        // Draw The Watcher effects (easter egg)
        DrawWatcherEffects();
    }

    // Restore original SpecialWaveID so replication state is not permanently altered.
    // Must be AFTER all DK HUD drawing (including stat overlay) to protect them too.
    if (WMGRI != None)
    {
        WMGRI.SpecialWaveID[0] = SavedSWID0;
        WMGRI.SpecialWaveID[1] = SavedSWID1;
    }
}

function RebuildAppliedStatsSummary()
{
    local KFPlayerController KFPC;

    AppliedStatsLines.Length = 0;
    KFPC = KFPlayerController(PlayerOwner);
    if (KFPC == None)
        return;
    class'ZTStatAggregator'.static.BuildCompactSummary(KFPC, AppliedStatsLines);
}

function NotifyParryStatBuff(bool bActive, float Duration)
{
    bParryStatBuffActive = bActive;
    if (bActive)
        ParryStatBuffExpiresAt = WorldInfo.TimeSeconds + Duration;
    else
        ParryStatBuffExpiresAt = 0.0f;

    AppliedStatsNextRefreshTime = 0.0f;
}

function bool IsParryStatBuffActive()
{
    if (bParryStatBuffActive && WorldInfo.TimeSeconds >= ParryStatBuffExpiresAt)
        bParryStatBuffActive = False;
    return bParryStatBuffActive;
}

function DrawAppliedStatsSummary()
{
    local int i;
    local float XL, YL, X, Y, Scale, LineHeight, MaxWidth, MaxTextHeight, Padding, BoxHeight;

    if (Canvas == None || PlayerOwner == None || bShowScores || PlayerOwner.Pawn == None)
        return;

    if (WorldInfo.TimeSeconds >= AppliedStatsNextRefreshTime)
    {
        RebuildAppliedStatsSummary();
        AppliedStatsNextRefreshTime = WorldInfo.TimeSeconds + 0.25f;
    }

    if (AppliedStatsLines.Length == 0)
        return;

    Canvas.Font = class'KFGameEngine'.static.GetKFCanvasFont();
    Scale = 0.52f * ResScale;
    Padding = 7.0f * ResScale;

    for (i = 0; i < AppliedStatsLines.Length; ++i)
    {
        Canvas.TextSize(AppliedStatsLines[i], XL, YL, Scale, Scale);
        MaxWidth = FMax(MaxWidth, XL);
        MaxTextHeight = FMax(MaxTextHeight, YL);
    }

    LineHeight = MaxTextHeight + 2.0f * ResScale;
    BoxHeight = LineHeight * float(AppliedStatsLines.Length) + Padding;
    X = (float(Canvas.SizeX) - MaxWidth) * 0.5f;
    Y = float(Canvas.SizeY) - BoxHeight - (2.0f * ResScale);

    Canvas.SetDrawColor(5, 8, 12, 145);
    Canvas.SetPos(X - Padding, Y - Padding * 0.5f);
    Canvas.DrawRect(MaxWidth + Padding * 2.0f, BoxHeight);

    for (i = 0; i < AppliedStatsLines.Length; ++i)
    {
        Canvas.TextSize(AppliedStatsLines[i], XL, YL, Scale, Scale);
        DrawTextWithShadow(AppliedStatsLines[i], (float(Canvas.SizeX) - XL) * 0.5f,
            Y + LineHeight * float(i), MakeColor(215, 225, 235, 235), Scale);
    }
}

// ===================================================================
// RANK HUD ELEMENT - Bottom-left corner rank display
// Shows tier icon (with glow for high tiers), rank text, and XP progress bar.
// Hidden when scoreboard is open or when player preference disables it.
// ===================================================================

function DrawRankHUDElement()
{
    local ZTPlayerReplicationInfo DKPRI;
    local KFPlayerController KFPC;
    local int Rank, TierIdx;
    local Color TierColor;
    local Texture2D TierIcon;
    local float IconSize, BarWidth, BarHeight, RankTextScl;
    local float BaseX, BaseY, CurX, CurY;
    local float XL, YL, Progress;
    local int StoredXP;
    local string RankStr;

    // Gate checks
    if (bShowScores)
        return;

    if (!class'ZTConfig_HudPreferences'.static.GetShowRankHUD())
        return;

    KFPC = KFPlayerController(GetALocalPlayerController());
    if (KFPC == None)
        return;

    DKPRI = ZTPlayerReplicationInfo(KFPC.PlayerReplicationInfo);
    if (DKPRI == None)
        return;

    // Rank 0 (fresh install / post-reset) is a legitimate state to display;
    // show the Rookie title with an empty progress bar instead of hiding it.
    Rank = DKPRI.PlayerRank;
    TierIdx = class'ZedternalTempered.ZTRank'.static.GetTierFromRank(Rank);
    TierColor = class'ZedternalTempered.ZTRank'.static.GetTierColor(Rank);
    TierIcon = class'ZedternalTempered.ZTRank'.static.GetTierIcon(Rank);

    // Set font explicitly - prevents size jitter from inherited font state
    Canvas.Font = class'KFGameEngine'.Static.GetKFCanvasFont();

    // Layout dimensions scaled by ResScale (larger for visibility)
    IconSize = 40.0f * ResScale;
    BarWidth = 120.0f * ResScale;
    BarHeight = 4.0f * ResScale;
    RankTextScl = 1.0f * ResScale;

    // Position: bottom-left, just above the XP bar
    BaseX = Canvas.SizeX * 0.015f;
    BaseY = Canvas.SizeY * 0.76f;

    // Draw icon glow effect for higher tiers (behind icon)
    if (TierIdx >= 3)
    {
        DrawIconGlow(BaseX + IconSize * 0.5f, BaseY + IconSize * 0.5f, IconSize, TierIdx, TierColor);
    }

    // Draw tier icon
    if (TierIcon != None)
    {
        Canvas.SetDrawColor(255, 255, 255, 255);
        Canvas.SetPos(BaseX, BaseY);
        Canvas.DrawTexture(TierIcon, IconSize / float(TierIcon.SizeY));
    }

    // Draw rank text to the right of icon
    CurX = BaseX + IconSize + 4.0f * ResScale;
    CurY = BaseY + 2.0f * ResScale;
    // GetRankDisplayString returns "" for rank 0 (used by rank-up
    // announcements where 0 means "don't show"). For the HUD we want
    // a visible label, so use the starting title directly at rank 0.
    if (Rank > 0)
        RankStr = class'ZedternalTempered.ZTRank'.static.GetRankDisplayString(Rank);
    else
        RankStr = class'ZedternalTempered.ZTRank'.static.GetTierDisplayName(0);
    Canvas.TextSize(RankStr, XL, YL, RankTextScl, RankTextScl);

    // Dark shadow for readability on bright maps (draw twice offset)
    Canvas.SetDrawColor(0, 0, 0, 220);
    Canvas.SetPos(CurX + 1.0f * ResScale, CurY + 1.0f * ResScale);
    Canvas.DrawText(RankStr, , RankTextScl, RankTextScl);

    // Actual colored text on top
    Canvas.DrawColor = TierColor;
    Canvas.SetPos(CurX, CurY);
    Canvas.DrawText(RankStr, , RankTextScl, RankTextScl);

    // Draw XP progress bar underneath the text
    StoredXP = class'ZedternalTempered.ZTConfig_Rank'.static.GetStoredXP();
    Progress = class'ZedternalTempered.ZTRank'.static.GetRankProgress(StoredXP);

    CurY = BaseY + IconSize - BarHeight - 1.0f * ResScale;

    // Bar background (dark)
    Canvas.SetDrawColor(20, 20, 20, 180);
    Canvas.SetPos(CurX, CurY);
    Canvas.DrawRect(BarWidth, BarHeight);

    // Bar fill (tier color)
    if (Progress > 0.0f)
    {
        Canvas.SetDrawColor(TierColor.R, TierColor.G, TierColor.B, 200);
        Canvas.SetPos(CurX, CurY);
        Canvas.DrawRect(BarWidth * FClamp(Progress, 0.0f, 1.0f), BarHeight);
    }

    // Bar border (subtle)
    Canvas.SetDrawColor(TierColor.R, TierColor.G, TierColor.B, 60);
    DrawBox(CurX, CurY, BarWidth, BarHeight, FMax(1.0f, ResScale * 0.5f));
}

// ===================================================================
// ICON GLOW EFFECTS - Animated tier-based glow drawn behind rank icons
// CenterX/CenterY = center of the icon
// IconSize = size of the icon being drawn
// TierIdx = 0-9 tier index
// TierColor = the tier's color
// Visible to all players (scoreboard) and local player (HUD element)
// ===================================================================

function DrawIconGlow(float GlowX, float GlowY, float Size, int TierIdx, Color TierCol)
{
    local float T, Pulse, GlowSize, Alpha;
    local float RayAngle, RayLen, RayW, RayX, RayY;
    local int i, NumRays;
    local float DotAngle, DotDist, DotSize;

    T = WorldInfo.TimeSeconds;

    // Tiers 3-4: Subtle pulsing outer glow
    if (TierIdx >= 3)
    {
        Pulse = 0.5f + 0.5f * Sin(T * 2.5f);
        GlowSize = Size * (1.3f + 0.2f * Pulse);
        Alpha = 15.0f + 15.0f * Pulse;

        Canvas.SetDrawColor(TierCol.R, TierCol.G, TierCol.B, byte(Alpha));
        Canvas.SetPos(GlowX - GlowSize * 0.5f, GlowY - GlowSize * 0.5f);
        Canvas.DrawRect(GlowSize, GlowSize);
    }

    // Tiers 5-6: Stronger pulse + faint rotating rays
    if (TierIdx >= 5)
    {
        Pulse = 0.5f + 0.5f * Sin(T * 3.0f);
        GlowSize = Size * (1.5f + 0.3f * Pulse);
        Alpha = 10.0f + 12.0f * Pulse;

        Canvas.SetDrawColor(TierCol.R, TierCol.G, TierCol.B, byte(Alpha));
        Canvas.SetPos(GlowX - GlowSize * 0.5f, GlowY - GlowSize * 0.5f);
        Canvas.DrawRect(GlowSize, GlowSize);

        // Rotating rays (drawn as thin lines radiating outward)
        NumRays = 6;
        RayLen = Size * 0.6f;
        RayW = FMax(1.0f, ResScale);
        Alpha = 20.0f + 15.0f * Pulse;
        Canvas.SetDrawColor(TierCol.R, TierCol.G, TierCol.B, byte(Alpha));

        for (i = 0; i < NumRays; ++i)
        {
            RayAngle = (float(i) / float(NumRays)) * 6.2832f + T * 0.8f;
            RayX = GlowX + Cos(RayAngle) * Size * 0.55f;
            RayY = GlowY + Sin(RayAngle) * Size * 0.55f;
            Canvas.SetPos(RayX, RayY);
            Canvas.DrawRect(RayW, RayLen * (0.5f + 0.5f * Pulse));
        }
    }

    // Tiers 7-9: Full glow + orbiting shimmer dots
    if (TierIdx >= 7)
    {
        Pulse = 0.5f + 0.5f * Sin(T * 4.0f);
        GlowSize = Size * (1.7f + 0.4f * Pulse);
        Alpha = 8.0f + 10.0f * Pulse;

        Canvas.SetDrawColor(TierCol.R, TierCol.G, TierCol.B, byte(Alpha));
        Canvas.SetPos(GlowX - GlowSize * 0.5f, GlowY - GlowSize * 0.5f);
        Canvas.DrawRect(GlowSize, GlowSize);

        // Orbiting shimmer dots
        DotSize = FMax(2.0f, 2.5f * ResScale);
        DotDist = Size * 0.75f;

        for (i = 0; i < 4; ++i)
        {
            DotAngle = (float(i) * 1.5708f) + T * 1.5f;
            Canvas.SetDrawColor(255, 255, 255, byte(40.0f + 30.0f * Sin(T * 5.0f + float(i))));
            Canvas.SetPos(
                GlowX + Cos(DotAngle) * DotDist - DotSize * 0.5f,
                GlowY + Sin(DotAngle) * DotDist - DotSize * 0.5f
            );
            Canvas.DrawRect(DotSize, DotSize);
        }
    }
}

// ===================================================================
// DISPLAY CARD STACKING SYSTEM FUNCTIONS
// ===================================================================

/** Compute pixel height of the Shapeshifter display card based on current mode. */
function float GetShapeshifterCardHeight()
{
    local int i, MimicryActiveCount, MimicryGridRows;

    if (!ShapeshifterDisplay.bIsActive)
        return 0.0f;

    if (ShapeshifterDisplay.bIsMimicry)
    {
        MimicryActiveCount = 0;
        for (i = 0; i < 15; i++)
        {
            if ((ShapeshifterDisplay.BuffMask & (1 << i)) != 0)
                MimicryActiveCount++;
        }

        if (MimicryActiveCount > 0)
        {
            MimicryGridRows = (MimicryActiveCount + 4) / 5;
            // Header icon (64) + gap to grid (12) + first row (24) + additional rows (28 each)
            return (64.0f + 12.0f + 24.0f + (float(MimicryGridRows - 1) * 28.0f)) * ResScale;
        }
        else
        {
            return 64.0f * ResScale;
        }
    }
    else if (ShapeshifterDisplay.Buff2Index >= 0)
    {
        // Two buff icons: icon (64) + gap (16) + icon (64)
        return 144.0f * ResScale;
    }
    else
    {
        // Single buff icon
        return 64.0f * ResScale;
    }
}

/** Compute pixel height of the Gambit display card based on current content. */
function float GetGambitCardHeight()
{
    local float Height;

    if (!GambitDisplay.bIsActive)
        return 0.0f;

    // Base card: name line + desc + progress bar + bar text + padding
    Height = 120.0f;
    if (GambitDisplay.SecondaryInfo != "")
        Height += 18.0f;

    return Height * ResScale;
}

/** Compute pixel height of the Artificer display card based on current mode. */
function float GetArtificerCardHeight()
{
    local float Height;
    local int NumLines;

    if (!ArtificerDisplay.bIsActive)
        return 0.0f;

    switch (ArtificerDisplay.DisplayMode)
    {
        case 0:  return 98.0f * ResScale;    // Progress: name + kills + bar + milestone
        case 1:  return 78.0f * ResScale;    // Reforge unlock: title + name + availability
        case 2:
            // Mastery complete: title(18) + name(14) + gap(6) + N stat lines(14 each) + padding(12)
            NumLines = CountMasteryStatLines(ArtificerDisplay.RollsString);
            if (NumLines < 1)
                NumLines = 1;
            Height = 50.0f + float(NumLines) * 14.0f;
            // Ensure tall enough for icon (48 + 12 padding)
            if (Height < 60.0f)
                Height = 60.0f;
            return Height * ResScale;
        default: return 88.0f * ResScale;
    }
}

/** Compute pixel height of the Predator display card. */
function float GetPredatorCardHeight()
{
    local float Height;
    local int SetsToShow;
    local bool bHasAnyBonus;

    if (!PredatorDisplay.bIsActive)
        return 0.0f;

    // PadY(6) + Title(18) + Gap(4) + TrophySlots(50) + Gap(6) + PadY(6)
    Height = 90.0f;

    // Extra row of trophy slots from Trophy Hoarder skill
    if (PredatorDisplay.MaxSlots > 5)
        Height += 53.0f;  // SlotSz(50) + Gap(3)

    // Up to 3 rarest completed sets
    SetsToShow = Min(PredatorDisplay.CompletedSetsCount, 3);
    if (SetsToShow > 0)
        Height += 2.0f + 4.0f + float(SetsToShow) * 14.0f + 4.0f;

    // Stacking phase header
    if (PredatorDisplay.bStackingPhase)
        Height += 18.0f;

    // Check if any bonuses exist (percentage or flat)
    bHasAnyBonus = PredatorDisplay.AccAllDamage > 0.0f
        || PredatorDisplay.AccLargeZedDamage > 0.0f
        || PredatorDisplay.AccDamageResist > 0.0f
        || PredatorDisplay.AccSpeed > 0.0f
        || PredatorDisplay.AccReload > 0.0f
        || PredatorDisplay.AccMeleeDamage > 0.0f
        || PredatorDisplay.AccMagSize > 0.0f
        || PredatorDisplay.AccWeaponSwitch > 0.0f
        || PredatorDisplay.AccSpareAmmo > 0.0f
        || PredatorDisplay.AccHeadshotDamage > 0.0f
        || PredatorDisplay.StackBonusHP > 0
        || PredatorDisplay.StackBonusArmor > 0
        || PredatorDisplay.StackBonusDosh > 0;

    // Individual bonus lines (each 14px)
    if (bHasAnyBonus)
    {
        if (PredatorDisplay.AccAllDamage > 0.0f) Height += 14.0f;
        if (PredatorDisplay.AccLargeZedDamage > 0.0f) Height += 14.0f;
        if (PredatorDisplay.AccDamageResist > 0.0f) Height += 14.0f;
        if (PredatorDisplay.AccSpeed > 0.0f) Height += 14.0f;
        if (PredatorDisplay.AccReload > 0.0f) Height += 14.0f;
        if (PredatorDisplay.AccMeleeDamage > 0.0f) Height += 14.0f;
        if (PredatorDisplay.AccMagSize > 0.0f) Height += 14.0f;
        if (PredatorDisplay.AccWeaponSwitch > 0.0f) Height += 14.0f;
        if (PredatorDisplay.AccSpareAmmo > 0.0f) Height += 14.0f;
        if (PredatorDisplay.AccHeadshotDamage > 0.0f) Height += 14.0f;
        if (PredatorDisplay.StackBonusHP > 0) Height += 14.0f;
        if (PredatorDisplay.StackBonusArmor > 0) Height += 14.0f;
        if (PredatorDisplay.StackBonusDosh > 0) Height += 14.0f;
    }

    return Height * ResScale;
}

/** Compute pixel height of the Omen prophecy display card. */
function float GetOmenCardHeight()
{
    local float Height;

    if (!OmenDisplay.bIsActive)
        return 0.0f;

    // Compact layout: PadY(5) + Title(14) + Gap(2) + Condition(11)
    Height = 32.0f;

    // Reward line
    if (OmenDisplay.Reward != "")
        Height += 12.0f;

    // Doom line
    if (OmenDisplay.State == 0 && OmenDisplay.Doom != "")
        Height += 11.0f;

    // Whisper line
    if (OmenDisplay.Whisper != "")
        Height += 13.0f;

    // Bottom padding
    Height += 5.0f;

    // Enforce minimum for icon (PadY(5) + Icon(64) + PadY(5) = 74)
    Height = FMax(Height, 74.0f);

    return Height * ResScale;
}

/** Rebuild the display card stack from scratch each frame.
 *  Walks card types in priority order, computes height for each active card,
 *  and assigns a non-overlapping normalized Y position top-to-bottom. */
function RebuildDisplayCardStack()
{
    local DisplayCardSlot Slot;
    local float CurYPx;
    local float GapPx;
    local float StartYPx, MaxYPx, TotalNeeded, AvailableSpace;
    local float TotalCardHeight, TotalGapSpace, NewGapPx;
    local int i;

    ActiveDisplayCards.Length = 0;
    CardStackShrink = 1.0f;

    if (Canvas == None || Canvas.SizeY <= 0)
        return;

    GapPx = DisplayCardGapPx * ResScale;
    StartYPx = DisplayCardBaseY * Canvas.SizeY;
    MaxYPx = CardStackMaxY * Canvas.SizeY;

    // === FIRST PASS: collect all active cards with full-size heights ===

    // --- Priority 1: Shapeshifter ---
    if (ShapeshifterDisplay.bIsActive && !bHideShapeshifterCard)
    {
        Slot.CardType = CARD_SHAPESHIFTER;
        Slot.HeightPx = GetShapeshifterCardHeight();
        Slot.DrawY = 0;
        ActiveDisplayCards.AddItem(Slot);
    }

    // --- Priority 2: Gambit ---
    if (GambitDisplay.bIsActive && !bHideGambitCard)
    {
        Slot.CardType = CARD_GAMBIT;
        Slot.HeightPx = GetGambitCardHeight();
        Slot.DrawY = 0;
        ActiveDisplayCards.AddItem(Slot);
    }

    // --- Priority 3: Artificer ---
    if (ArtificerDisplay.bIsActive && !bHideArtificerCard)
    {
        Slot.CardType = CARD_ARTIFICER;
        Slot.HeightPx = GetArtificerCardHeight();
        Slot.DrawY = 0;
        ActiveDisplayCards.AddItem(Slot);
    }

    // --- Priority 4: Omen ---
    if (OmenDisplay.bIsActive && !bHideOmenCard)
    {
        Slot.CardType = CARD_OMEN;
        Slot.HeightPx = GetOmenCardHeight();
        Slot.DrawY = 0;
        ActiveDisplayCards.AddItem(Slot);
    }

    // --- Priority 5: Predator ---
    if (PredatorDisplay.bIsActive && !bHidePredatorCard)
    {
        Slot.CardType = CARD_PREDATOR;
        Slot.HeightPx = GetPredatorCardHeight();
        Slot.DrawY = 0;
        ActiveDisplayCards.AddItem(Slot);
    }

    // --- Priority 6: Hollow ---
    if (HollowDisplay.bIsActive && !bHideHollowCard)
    {
        Slot.CardType = CARD_HOLLOW;
        Slot.HeightPx = GetHollowCardHeight();
        Slot.DrawY = 0;
        ActiveDisplayCards.AddItem(Slot);
    }

    // --- Priority 7: Metronome ---
    if (MetronomeDisplay.bIsActive && !bHideMetronomeCard)
    {
        Slot.CardType = CARD_METRONOME;
        Slot.HeightPx = GetMetronomeCardHeight();
        Slot.DrawY = 0;
        ActiveDisplayCards.AddItem(Slot);
    }

    // --- Priority 8: Detonator ---
    if (DetonatorDisplay.bIsActive && !bHideDetonatorCard)
    {
        Slot.CardType = CARD_DETONATOR;
        Slot.HeightPx = GetDetonatorCardHeight();
        Slot.DrawY = 0;
        ActiveDisplayCards.AddItem(Slot);
    }

    // --- Priority 9: Jekyll & Hyde serum ---
    if (HydeDisplay.bIsActive && !bHideHydeCard)
    {
        Slot.CardType = CARD_HYDE;
        Slot.HeightPx = GetHydeCardHeight();
        Slot.DrawY = 0;
        ActiveDisplayCards.AddItem(Slot);
    }

    // --- Priority 10: Domain room ---
    if (DomainDisplay.bIsActive && !bHideDomainCard)
    {
        Slot.CardType = CARD_DOMAIN;
        Slot.HeightPx = GetDomainCardHeight();
        Slot.DrawY = 0;
        ActiveDisplayCards.AddItem(Slot);
    }

    // --- Priority 11: Speedster blink ---
    if (SpeedsterDisplay.bIsActive && !bHideSpeedsterCard)
    {
        Slot.CardType = CARD_SPEEDSTER;
        Slot.HeightPx = GetSpeedsterCardHeight();
        Slot.DrawY = 0;
        ActiveDisplayCards.AddItem(Slot);
    }

    // --- Priority 12: Possessor possession ---
    if (PossessorDisplay.bIsActive && !bHidePossessorCard)
    {
        Slot.CardType = CARD_POSSESSOR;
        Slot.HeightPx = GetPossessorCardHeight();
        Slot.DrawY = 0;
        ActiveDisplayCards.AddItem(Slot);
    }

    if (ActiveDisplayCards.Length == 0)
        return;

    // === OVERFLOW PROTECTION ===
    // Step 1: Sum total card heights + gaps
    TotalCardHeight = 0;
    for (i = 0; i < ActiveDisplayCards.Length; i++)
        TotalCardHeight += ActiveDisplayCards[i].HeightPx;

    TotalGapSpace = GapPx * float(ActiveDisplayCards.Length - 1);
    TotalNeeded = TotalCardHeight + TotalGapSpace;
    AvailableSpace = MaxYPx - StartYPx;

    // Step 2: If overflow, compress gaps first (down to 2px minimum)
    if (TotalNeeded > AvailableSpace && AvailableSpace > 0 && ActiveDisplayCards.Length > 1)
    {
        NewGapPx = (AvailableSpace - TotalCardHeight) / float(ActiveDisplayCards.Length - 1);
        if (NewGapPx < 2.0f)
            NewGapPx = 2.0f;
        GapPx = NewGapPx;

        // Step 3: If still overflowing after gap compression, uniformly shrink card heights
        TotalNeeded = TotalCardHeight + (GapPx * float(ActiveDisplayCards.Length - 1));
        if (TotalNeeded > AvailableSpace)
        {
            CardStackShrink = (AvailableSpace - GapPx * float(ActiveDisplayCards.Length - 1)) / TotalCardHeight;
            if (CardStackShrink < 0.5f)
                CardStackShrink = 0.5f;

            for (i = 0; i < ActiveDisplayCards.Length; i++)
                ActiveDisplayCards[i].HeightPx *= CardStackShrink;
        }
    }

    // === LAYOUT PASS: assign Y positions ===
    CurYPx = StartYPx;
    for (i = 0; i < ActiveDisplayCards.Length; i++)
    {
        ActiveDisplayCards[i].DrawY = CurYPx / Canvas.SizeY;
        CurYPx += ActiveDisplayCards[i].HeightPx + GapPx;
    }
}

/** Look up the assigned Y position for a specific card type.
 *  Called by each card's Draw function instead of using a fixed Y var. */
function float GetDisplayCardY(byte CardType)
{
    local int i;

    for (i = 0; i < ActiveDisplayCards.Length; i++)
    {
        if (ActiveDisplayCards[i].CardType == CardType)
            return ActiveDisplayCards[i].DrawY;
    }

    // Fallback: base position if card wasn't registered (shouldn't happen)
    return DisplayCardBaseY;
}

/** Look up the assigned height for a specific card type from the stack.
 *  Returns the potentially-shrunk height so draw functions render at correct size.
 *  If card not found, returns 0 (shouldn't happen for active cards). */
function float GetAssignedCardHeight(byte CardType)
{
    local int i;

    for (i = 0; i < ActiveDisplayCards.Length; i++)
    {
        if (ActiveDisplayCards[i].CardType == CardType)
            return ActiveDisplayCards[i].HeightPx;
    }

    return 0;
}

/** Return the normalized Y just below the last stacked card.
 *  Used by DrawPerkInfoCards to start perk cards below all rich display cards. */
function float GetDisplayCardStackBottomY()
{
    local int Last;
    local float BottomPx;

    if (ActiveDisplayCards.Length == 0 || Canvas == None || Canvas.SizeY <= 0)
        return TrackerStartY;

    Last = ActiveDisplayCards.Length - 1;
    BottomPx = (ActiveDisplayCards[Last].DrawY * Canvas.SizeY)
             + ActiveDisplayCards[Last].HeightPx
             + DisplayCardGapPx * ResScale;

    return BottomPx / Canvas.SizeY;
}

// ===================================================================
// UNIFIED PERK INFO CARDS - Groups old tracker bars into styled cards
//
// Reads from PerkTrackers array (unchanged data source).
// Groups trackers by perk prefix, renders each group as one card.
// Visual style matches rich cards (Gambit, Artificer, etc).
// ===================================================================

/** Map a tracker name to its perk group. Trackers in the same group
 *  render as lines inside a single card. */
function string GetTrackerGroup(string TrackerName)
{
    if (TrackerName == "Reaper") return "Reaper";
    if (TrackerName == "Symbiote" || TrackerName == "SymbioteEvolutions") return "Symbiote";
    if (TrackerName == "Scavenger" || TrackerName == "ScavengerAdaptations") return "Scavenger";
    if (TrackerName == "Tycoon" || TrackerName == "TycoonPortfolio") return "Tycoon";
    if (TrackerName == "ForgeWarden" || TrackerName == "ForgeWardenGrenades") return "ForgeWarden";
    if (TrackerName == "Hydra") return "Hydra";
    if (Left(TrackerName, 7) == "Wendigo") return "Wendigo";
    if (TrackerName == "Archangel" || TrackerName == "ArchangelHealing") return "Archangel";
    if (Left(TrackerName, 6) == "Medusa") return "Medusa";
    if (Left(TrackerName, 11) == "Cryophilite") return "Cryophilite";
    if (TrackerName == "Riot") return "Riot";
    if (TrackerName == "Agony") return "Agony";
    if (Left(TrackerName, 6) == "Cinder") return "Cinder";
    if (Left(TrackerName, 8) == "Hivemind") return "Hivemind";
    if (Left(TrackerName, 8) == "Parasite") return "Parasite";
    // Shapeshifter trackers: skip (has its own rich card)
    if (Left(TrackerName, 12) == "Shapeshifter") return "";
    return TrackerName;
}

/** Main entry: draw all perk trackers as grouped cards.
 *  Called from DrawHUD instead of old DrawPerkTrackers. */
function DrawPerkInfoCards()
{
    local float StartY, CurY, GapPx;
    local int i, j;
    local string GroupName;
    local bool bGroupRendered;

    // Collect unique active groups
    // We iterate PerkTrackers, track which groups we've rendered
    local array<string> RenderedGroups;
    local int LineCount;
    local float CardH;

    if (Canvas == None)
        return;

    StartY = FMax(TrackerStartY, GetDisplayCardStackBottomY());
    CurY = StartY * Canvas.SizeY;
    GapPx = 4.0f * ResScale;

    for (i = 0; i < PerkTrackers.Length; i++)
    {
        if (!PerkTrackers[i].bIsActive)
            continue;

        GroupName = GetTrackerGroup(PerkTrackers[i].PerkName);
        if (GroupName == "")
            continue;

        // Skip if we already rendered this group
        bGroupRendered = false;
        for (j = 0; j < RenderedGroups.Length; j++)
        {
            if (RenderedGroups[j] == GroupName)
            {
                bGroupRendered = true;
                break;
            }
        }
        if (bGroupRendered)
            continue;

        RenderedGroups.AddItem(GroupName);

        // Count lines in this group
        LineCount = CountGroupLines(GroupName);
        CardH = GetPerkInfoCardHeight(LineCount);

        // Draw the card
        DrawPerkGroupCard(GroupName, LineCount, Canvas.SizeX * DisplayCardBaseX, CurY, CardH);
        CurY += CardH + GapPx;
    }
}

/** Count active tracker lines for a perk group. */
function int CountGroupLines(string GroupName)
{
    local int i, Count;

    Count = 0;
    for (i = 0; i < PerkTrackers.Length; i++)
    {
        if (PerkTrackers[i].bIsActive && GetTrackerGroup(PerkTrackers[i].PerkName) == GroupName)
            Count++;
    }

    return Count;
}

/** Get pixel height for a perk info card based on line count. */
function float GetPerkInfoCardHeight(int LineCount)
{
    local float PadY, LineH, IconSz;

    PadY = 6.0f * ResScale;
    LineH = 18.0f * ResScale;
    IconSz = 36.0f * ResScale;

    // PadY + (LineCount * LineH) + PadY, minimum icon height
    return FMax(PadY * 2.0f + float(LineCount) * LineH, IconSz + PadY * 2.0f);
}

/** Draw a single perk group card containing all trackers for that perk. */
function DrawPerkGroupCard(string GroupName, int LineCount, float BoxX, float BoxY, float BoxH)
{
    local float BoxW, PadX, PadY, LineH, IconSz, IconPad;
    local float TextX, CurY;
    local float BarX, BarW, BarH, BarFill;
    local int i;
    local Color AccentColor, TextColor, BarBG;
    local Texture2D Icon;
    local bool bIsTextOnly;
    local string LineText;

    BoxW = 280.0f * ResScale;
    PadX = 8.0f * ResScale;
    PadY = 6.0f * ResScale;
    LineH = 18.0f * ResScale;
    IconSz = 36.0f * ResScale;
    IconPad = 6.0f * ResScale;
    BarH = 4.0f * ResScale;

    TextX = BoxX + PadX + IconSz + IconPad;
    TextColor = MakeColorFromRGB(210, 210, 220, 255);
    BarBG = MakeColorFromRGB(40, 40, 40, 200);

    Canvas.Font = class'KFGameEngine'.Static.GetKFCanvasFont();

    // Get accent color and icon from first tracker in group
    AccentColor = MakeColorFromRGB(180, 180, 180, 255);
    Icon = None;
    for (i = 0; i < PerkTrackers.Length; i++)
    {
        if (PerkTrackers[i].bIsActive && GetTrackerGroup(PerkTrackers[i].PerkName) == GroupName)
        {
            AccentColor = PerkTrackers[i].TextColor;
            Icon = PerkTrackers[i].PerkIcon;
            break;
        }
    }

    // --- Background ---
    Canvas.SetDrawColor(0, 0, 0, 160);
    Canvas.SetPos(BoxX, BoxY);
    Canvas.DrawRect(BoxW, BoxH);

    // --- Border (4 edges) ---
    Canvas.SetDrawColor(AccentColor.R, AccentColor.G, AccentColor.B, 140);
    Canvas.SetPos(BoxX, BoxY);                                Canvas.DrawRect(BoxW, 2.0f * ResScale);
    Canvas.SetPos(BoxX, BoxY + BoxH - 2.0f * ResScale);      Canvas.DrawRect(BoxW, 2.0f * ResScale);
    Canvas.SetPos(BoxX, BoxY);                                Canvas.DrawRect(2.0f * ResScale, BoxH);
    Canvas.SetPos(BoxX + BoxW - 2.0f * ResScale, BoxY);      Canvas.DrawRect(2.0f * ResScale, BoxH);

    // --- Icon (vertically centered) ---
    if (Icon != None)
    {
        Canvas.SetDrawColor(255, 255, 255, 255);
        Canvas.SetPos(BoxX + PadX, BoxY + (BoxH - IconSz) * 0.5f);
        Canvas.DrawTile(Icon, IconSz, IconSz, 0, 0, Icon.SizeX, Icon.SizeY);
    }

    // --- Render each tracker line ---
    CurY = BoxY + PadY;
    for (i = 0; i < PerkTrackers.Length; i++)
    {
        if (!PerkTrackers[i].bIsActive)
            continue;
        if (GetTrackerGroup(PerkTrackers[i].PerkName) != GroupName)
            continue;

        // Determine if this tracker shows as text-only (bonus summary) or progress bar
        bIsTextOnly = (PerkTrackers[i].PerkName ~= "SymbioteEvolutions")
            || (PerkTrackers[i].PerkName ~= "ScavengerAdaptations")
            || (PerkTrackers[i].PerkName ~= "TycoonPortfolio")
            || (PerkTrackers[i].PerkName ~= "ForgeWardenGrenades")
            || (PerkTrackers[i].PerkName ~= "ArchangelHealing")
            || (PerkTrackers[i].PerkName ~= "MedusaScales");

        if (bIsTextOnly)
        {
            // Text-only line (bonus summaries)
            DrawTextWithShadow(PerkTrackers[i].DisplayText, TextX, CurY, TextColor, 0.6f * ResScale);
        }
        else if (PerkTrackers[i].MaxValue > 0)
        {
            // Progress line: "Label: Current/Max" + bar
            LineText = PerkTrackers[i].DisplayText @ string(PerkTrackers[i].CurrentValue) $ "/" $ string(PerkTrackers[i].MaxValue);
            DrawTextWithShadow(LineText, TextX, CurY, AccentColor, 0.6f * ResScale);

            // Mini progress bar below text
            BarX = TextX;
            BarW = (BoxX + BoxW - PadX) - TextX;
            BarFill = FClamp(float(PerkTrackers[i].CurrentValue) / float(PerkTrackers[i].MaxValue), 0.0f, 1.0f);

            Canvas.SetDrawColor(BarBG.R, BarBG.G, BarBG.B, BarBG.A);
            Canvas.SetPos(BarX, CurY + 12.0f * ResScale);
            Canvas.DrawRect(BarW, BarH);

            Canvas.SetDrawColor(AccentColor.R, AccentColor.G, AccentColor.B, 200);
            Canvas.SetPos(BarX, CurY + 12.0f * ResScale);
            Canvas.DrawRect(BarW * BarFill, BarH);
        }
        else
        {
            // Simple text line (status display)
            DrawTextWithShadow(PerkTrackers[i].DisplayText, TextX, CurY, TextColor, 0.6f * ResScale);
        }

        CurY += LineH;
    }
}

function DrawInstantKillNotification()
{
    local float TextWidth, TextHeight;
    local float XPos, YPos;
    local float Alpha, ScalePulse;
    local Color DrawColor;
    
    if (Canvas == None || !InstantKillNotif.bIsActive) return;
    
    Alpha = (InstantKillNotif.DisplayTime / InstantKillNotif.MaxDisplayTime);
    ScalePulse = (InstantKillNotif.TextScale + (Sin(InstantKillNotif.DisplayTime * 10.0f) * 0.2f)) * ResScale;
    
    Canvas.Font = class'Engine'.Static.GetLargeFont();
    Canvas.TextSize(InstantKillNotif.NotificationText, TextWidth, TextHeight, ScalePulse, ScalePulse);
    
    XPos = (Canvas.SizeX - TextWidth * ScalePulse) / 2;
    YPos = (Canvas.SizeY - TextHeight * ScalePulse) / 2;
    
    DrawColor = InstantKillNotif.TextColor;
    DrawColor.A = Alpha * 255;
    
    Canvas.SetDrawColor(0, 0, 0, Alpha * 200);
    Canvas.SetPos(XPos + 3 * ResScale, YPos + 3 * ResScale);
    Canvas.DrawText(InstantKillNotif.NotificationText, true, ScalePulse, ScalePulse);
    
    Canvas.SetDrawColor(0, 0, 0, Alpha * 255);
    Canvas.SetPos(XPos - 2 * ResScale, YPos - 2 * ResScale);
    Canvas.DrawText(InstantKillNotif.NotificationText, true, ScalePulse, ScalePulse);
    Canvas.SetPos(XPos + 2 * ResScale, YPos - 2 * ResScale);
    Canvas.DrawText(InstantKillNotif.NotificationText, true, ScalePulse, ScalePulse);
    Canvas.SetPos(XPos - 2 * ResScale, YPos + 2 * ResScale);
    Canvas.DrawText(InstantKillNotif.NotificationText, true, ScalePulse, ScalePulse);
    Canvas.SetPos(XPos + 2 * ResScale, YPos + 2 * ResScale);
    Canvas.DrawText(InstantKillNotif.NotificationText, true, ScalePulse, ScalePulse);
    
    Canvas.SetDrawColor(DrawColor.R, DrawColor.G, DrawColor.B, DrawColor.A);
    Canvas.SetPos(XPos, YPos);
    Canvas.DrawText(InstantKillNotif.NotificationText, true, ScalePulse, ScalePulse);
}

function DrawChainNotification()
{
    local float TitleWidth, TitleHeight, TextWidth, TextHeight;
    local float XPos, YPos;
    local float Alpha, ScalePulse;
    local Color DrawColor;
    
    if (Canvas == None || !ChainNotif.bIsActive) return;
    
    Alpha = (ChainNotif.DisplayTime / ChainNotif.MaxDisplayTime);
    ScalePulse = (ChainNotif.TitleScale + (Sin(ChainNotif.DisplayTime * 8.0f) * 0.1f)) * ResScale;
    
    Canvas.Font = class'Engine'.Static.GetLargeFont();
    Canvas.TextSize(ChainNotif.NotificationTitle, TitleWidth, TitleHeight, ScalePulse, ScalePulse);
    
    Canvas.Font = class'KFGameEngine'.Static.GetKFCanvasFont();
    Canvas.TextSize(ChainNotif.NotificationText, TextWidth, TextHeight, ChainNotif.TextScale * ResScale, ChainNotif.TextScale * ResScale);
    
    XPos = (Canvas.SizeX - FMax(TitleWidth * ScalePulse, TextWidth * ChainNotif.TextScale * ResScale)) / 2;
    YPos = Canvas.SizeY * 0.25f;
    
    Canvas.SetDrawColor(0, 0, 0, Alpha * 200);
    Canvas.SetPos(XPos + 2 * ResScale, YPos + 2 * ResScale);
    Canvas.DrawText(ChainNotif.NotificationTitle, true, ScalePulse, ScalePulse);
    
    Canvas.SetDrawColor(0, 0, 0, Alpha * 255);
    Canvas.SetPos(XPos - ResScale, YPos - ResScale);
    Canvas.DrawText(ChainNotif.NotificationTitle, true, ScalePulse, ScalePulse);
    Canvas.SetPos(XPos + ResScale, YPos - ResScale);
    Canvas.DrawText(ChainNotif.NotificationTitle, true, ScalePulse, ScalePulse);
    Canvas.SetPos(XPos - ResScale, YPos + ResScale);
    Canvas.DrawText(ChainNotif.NotificationTitle, true, ScalePulse, ScalePulse);
    Canvas.SetPos(XPos + ResScale, YPos + ResScale);
    Canvas.DrawText(ChainNotif.NotificationTitle, true, ScalePulse, ScalePulse);
    
    DrawColor = ChainNotif.TitleColor;
    DrawColor.A = Alpha * 255;
    Canvas.SetDrawColor(DrawColor.R, DrawColor.G, DrawColor.B, DrawColor.A);
    Canvas.SetPos(XPos, YPos);
    Canvas.DrawText(ChainNotif.NotificationTitle, true, ScalePulse, ScalePulse);
    
    if (ChainNotif.NotificationText != "")
    {
        YPos += (TitleHeight * ScalePulse) + 5.0f * ResScale;
        XPos = (Canvas.SizeX - (TextWidth * ChainNotif.TextScale * ResScale)) / 2;
        
        Canvas.SetDrawColor(0, 0, 0, Alpha * 150);
        Canvas.SetPos(XPos + ResScale, YPos + ResScale);
        Canvas.DrawText(ChainNotif.NotificationText, true, ChainNotif.TextScale * ResScale, ChainNotif.TextScale * ResScale);
        
        DrawColor = ChainNotif.TextColor;
        DrawColor.A = Alpha * 255;
        Canvas.SetDrawColor(DrawColor.R, DrawColor.G, DrawColor.B, DrawColor.A);
        Canvas.SetPos(XPos, YPos);
        Canvas.DrawText(ChainNotif.NotificationText, true, ChainNotif.TextScale * ResScale, ChainNotif.TextScale * ResScale);
    }
}

function DrawReaperTracking()
{
}

function DrawEvolutionPanel()
{
    local float PanelX, PanelY, PanelWidth, PanelHeight;
    local float LineHeight, CurrentY;
    local array<string> EvolutionLines;
    local int i, TotalEvolutions;
    local string HeaderText, EvolutionText;
    local ZTUpgrade_Perk_Symbiote_Helper SymbioteHelper;
    local KFPlayerController KFPC;
    local KFPawn OwnerPawn;
    
    if (Canvas == None) return;
    
    KFPC = KFPlayerController(class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController());
    if (KFPC == None || KFPC.Pawn == None) return;
    
    OwnerPawn = KFPawn(KFPC.Pawn);
    if (OwnerPawn == None) return;
    
    SymbioteHelper = class'ZTUpgrade_Perk_Symbiote'.static.GetHelper(OwnerPawn);
    if (SymbioteHelper == None) return;
    
    TotalEvolutions = SymbioteHelper.TotalEvolutions;
    if (TotalEvolutions == 0) return;
    
    BuildEvolutionDisplay(SymbioteHelper, EvolutionLines);
    
    PanelWidth = 350.0f * ResScale;
    LineHeight = 20.0f * ResScale;
    PanelHeight = (EvolutionLines.Length + 2) * LineHeight + 20.0f * ResScale;
    
    PanelX = Canvas.SizeX * 0.05f;
    PanelY = Canvas.SizeY * 0.3f;
    
    DrawPanelBackground(PanelX, PanelY, PanelWidth, PanelHeight);
    
    Canvas.Font = class'KFGameEngine'.Static.GetKFCanvasFont();
    
    HeaderText = "SYMBIOTE EVOLUTIONS (" $ TotalEvolutions $ " total)";
    CurrentY = PanelY + 15.0f * ResScale;
    DrawTextWithShadow(HeaderText, PanelX + 15.0f * ResScale, CurrentY, MakeColorFromRGB(0, 255, 127, 255), 0.9f * ResScale);
    
    CurrentY += LineHeight + 5.0f * ResScale;
    Canvas.SetDrawColor(0, 255, 127, 100);
    Canvas.SetPos(PanelX + 15.0f * ResScale, CurrentY);
    Canvas.DrawRect(PanelWidth - 30.0f * ResScale, 2.0f * ResScale);
    CurrentY += 10.0f * ResScale;
    
    for (i = 0; i < EvolutionLines.Length; i++)
    {
        DrawTextWithShadow(EvolutionLines[i], PanelX + 25.0f * ResScale, CurrentY, MakeColorFromRGB(200, 255, 200, 255), 0.75f * ResScale);
        CurrentY += LineHeight;
    }
    
    if (!EvolutionPanel.bToggleMode)
    {
        EvolutionText = "Use 'ToggleSymbiotePanel' command to toggle this panel";
        DrawTextWithShadow(EvolutionText, PanelX + 15.0f * ResScale, PanelY + PanelHeight - 25.0f * ResScale, MakeColorFromRGB(150, 150, 150, 255), 0.6f * ResScale);
    }
}

function ToggleScavengerAdaptationPanel()
{
    local KFPlayerController KFPC;
    local ZTUpgrade_Perk_Scavenger_Helper ScavengerHelper;
    local KFPawn OwnerPawn;
    local string AdaptationSummary;
    
    KFPC = KFPlayerController(class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController());
    if (KFPC != None && KFPC.Pawn != None)
    {
        OwnerPawn = KFPawn(KFPC.Pawn);
        if (OwnerPawn != None)
        {
            ScavengerHelper = class'ZTUpgrade_Perk_Scavenger'.static.GetHelper(OwnerPawn);
            if (ScavengerHelper != None)
            {
                AdaptationSummary = ScavengerHelper.GetAdaptationSummary();
                class'ZTMessageManager'.static.SendImportant(KFPC, "SCAVENGER STATUS: " $ AdaptationSummary);
            }
            else
            {
                class'ZTMessageManager'.static.SendMinor(KFPC, "Scavenger perk not active.");
            }
        }
    }
}

function ToggleTycoonPortfolioPanel()
{
    local KFPlayerController KFPC;
    local ZTUpgrade_Perk_Tycoon_Helper TycoonHelper;
    local KFPawn OwnerPawn;
    local string PortfolioSummary;
    
    KFPC = KFPlayerController(class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController());
    if (KFPC != None && KFPC.Pawn != None)
    {
        OwnerPawn = KFPawn(KFPC.Pawn);
        if (OwnerPawn != None)
        {
            TycoonHelper = class'ZTUpgrade_Perk_Tycoon'.static.GetHelper(OwnerPawn);
            if (TycoonHelper != None)
            {
                PortfolioSummary = TycoonHelper.GetPortfolioSummary();
                class'ZTMessageManager'.static.SendImportant(KFPC, "TYCOON STATUS: " $ PortfolioSummary);
                
                class'ZTMessageManager'.static.SendMinor(KFPC, TycoonHelper.GetDoshBreakdown());
            }
            else
            {
                class'ZTMessageManager'.static.SendMinor(KFPC, "Tycoon perk not active.");
            }
        }
    }
}

function ToggleForgeWardenMilestonePanel()
{
    local KFPlayerController KFPC;
    local ZTUpgrade_Perk_ForgeWarden_Helper ForgeHelper;
    local KFPawn OwnerPawn;
    local string MilestoneSummary;
    
    KFPC = KFPlayerController(class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController());
    if (KFPC != None && KFPC.Pawn != None)
    {
        OwnerPawn = KFPawn(KFPC.Pawn);
        if (OwnerPawn != None)
        {
            ForgeHelper = class'ZTUpgrade_Perk_ForgeWarden'.static.GetHelper(OwnerPawn);
            if (ForgeHelper != None)
            {
                MilestoneSummary = ForgeHelper.GetMilestoneSummary();
                class'ZTMessageManager'.static.SendImportant(KFPC, "FORGEWARDEN STATUS: " $ MilestoneSummary);
            }
            else
            {
                class'ZTMessageManager'.static.SendMinor(KFPC, "ForgeWarden perk not active.");
            }
        }
    }
}

// ===================================================================
// Chain Notification System Functions
// ===================================================================

function TriggerChainNotification(string Title, string Description, optional float Duration = 3.0f)
{
    ChainNotif.NotificationTitle = Title;
    ChainNotif.NotificationText = Description;
    ChainNotif.bIsActive = true;
    ChainNotif.DisplayTime = Duration;
    ChainNotif.MaxDisplayTime = Duration;
}

// ===================================================================
// TIMER UPDATE FUNCTIONS
// ===================================================================

function UpdateTrackerTimers()
{
    local int i;
    
    for (i = 0; i < PerkTrackers.Length; i++)
    {
        if (PerkTrackers[i].bIsActive && PerkTrackers[i].DisplayTime > 0.0f)
        {
            PerkTrackers[i].DisplayTime -= RenderDelta;
            
            if (PerkTrackers[i].DisplayTime <= 0.0f)
            {
                PerkTrackers[i].bIsActive = false;
            }
        }
    }
}

function UpdateInstantKillTimer()
{
    if (InstantKillNotif.bIsActive && InstantKillNotif.DisplayTime > 0.0f)
    {
        InstantKillNotif.DisplayTime -= RenderDelta;
        
        if (InstantKillNotif.DisplayTime <= 0.0f)
        {
            InstantKillNotif.bIsActive = false;
        }
    }
}

function UpdateChainNotificationTimer()
{
    if (ChainNotif.bIsActive && ChainNotif.DisplayTime > 0.0f)
    {
        ChainNotif.DisplayTime -= RenderDelta;
        
        if (ChainNotif.DisplayTime <= 0.0f)
        {
            ChainNotif.bIsActive = false;
        }
    }
}

function UpdateEvolutionPanelTimer()
{
    if (EvolutionPanel.bShowPanel && !EvolutionPanel.bToggleMode && EvolutionPanel.PanelDisplayTime > 0.0f)
    {
        EvolutionPanel.PanelDisplayTime -= RenderDelta;
        
        if (EvolutionPanel.PanelDisplayTime <= 0.0f)
        {
            HideEvolutionPanel();
        }
    }
}

// ===================================================================
// HELPER & MANAGEMENT FUNCTIONS
// ===================================================================

function BuildEvolutionDisplay(ZTUpgrade_Perk_Symbiote_Helper SymbioteHelper, out array<string> EvolutionLines)
{
    local int i;
    local array<string> UniqueTypes;
    local array<float> TypeTotals;
    local array<int> TypeCounts;
    local int TypeIndex;
    local string DisplayName, LineText;
    
    for (i = 0; i < SymbioteHelper.AccumulatedBonuses.Length; i++)
    {
        TypeIndex = UniqueTypes.Find(SymbioteHelper.AccumulatedBonuses[i].BonusType);
        if (TypeIndex == INDEX_NONE)
        {
            UniqueTypes.AddItem(SymbioteHelper.AccumulatedBonuses[i].BonusType);
            TypeTotals.AddItem(SymbioteHelper.AccumulatedBonuses[i].BonusValue);
            TypeCounts.AddItem(1);
        }
        else
        {
            TypeTotals[TypeIndex] += SymbioteHelper.AccumulatedBonuses[i].BonusValue;
            TypeCounts[TypeIndex]++;
        }
    }
    
    for (i = 0; i < UniqueTypes.Length; i++)
    {
        DisplayName = GetFriendlyEvolutionName(UniqueTypes[i]);
        LineText = DisplayName $ ": +" $ int(TypeTotals[i] * 100) $ "% (" $ TypeCounts[i] $ " evolutions)";
        EvolutionLines.AddItem(LineText);
    }
}

function string GetFriendlyEvolutionName(string BonusType)
{
    if (BonusType ~= "Damage") return "Damage";
    if (BonusType ~= "HeadshotDamage") return "Headshot Damage";
    if (BonusType ~= "MovementSpeed") return "Movement Speed";
    if (BonusType ~= "ReloadSpeed") return "Reload Speed";
    if (BonusType ~= "WeaponSwitchSpeed") return "Weapon Switch Speed";
    if (BonusType ~= "Penetration") return "Penetration";
    if (BonusType ~= "SpareAmmo") return "Spare Ammo";
    if (BonusType ~= "MagazineSize") return "Magazine Size";
    
    return BonusType;
}

function TriggerInstantKillNotification()
{
    InstantKillNotif.bIsActive = true;
    InstantKillNotif.DisplayTime = InstantKillNotif.MaxDisplayTime;
}

function ShowEvolutionPanel(optional bool bToggle = false, optional float Duration = 8.0f)
{
    EvolutionPanel.bShowPanel = true;
    EvolutionPanel.bToggleMode = bToggle;
    
    if (!bToggle)
    {
        EvolutionPanel.PanelDisplayTime = Duration;
    }
    else
    {
        EvolutionPanel.PanelDisplayTime = -1.0f;
    }
}

function HideEvolutionPanel()
{
    EvolutionPanel.bShowPanel = false;
    EvolutionPanel.bToggleMode = false;
    EvolutionPanel.PanelDisplayTime = 0.0f;
}

function ToggleEvolutionPanel()
{
    if (EvolutionPanel.bShowPanel)
    {
        HideEvolutionPanel();
    }
    else
    {
        ShowEvolutionPanel(true);
    }
}

function int FindTrackerIndex(string PerkName)
{
    local int i;
    
    for (i = 0; i < PerkTrackers.Length; i++)
    {
        if (PerkTrackers[i].PerkName ~= PerkName)
        {
            return i;
        }
    }
    
    return INDEX_NONE;
}

function UpdatePerkTracker(string PerkName, int CurrentValue, int MaxValue, optional bool bCompleted = false, optional float DisplayDuration = 5.0f)
{
    local int Index;
    
    Index = FindTrackerIndex(PerkName);
    if (Index != INDEX_NONE)
    {
        PerkTrackers[Index].CurrentValue = CurrentValue;
        PerkTrackers[Index].MaxValue = MaxValue;
        PerkTrackers[Index].bIsActive = (CurrentValue > 0 || bCompleted);
        PerkTrackers[Index].DisplayTime = DisplayDuration;
    }
    else
    {
        `log("Warning: Perk tracker" @ PerkName @ "not found!");
    }
}

function UpdateReaperKills(int CurrentKills, int MaxKills, optional bool bCompleted = false)
{
    UpdatePerkTracker("Reaper", CurrentKills, MaxKills, bCompleted, 5.0f);
}

function UpdateSymbioteEvolution(int CurrentKills, int MaxKills, optional bool bEvolutionComplete = false)
{
    UpdatePerkTracker("Symbiote", CurrentKills, MaxKills, bEvolutionComplete, 5.0f);
}

function UpdateSymbioteEvolutionBonuses(int TotalEvolutions, string BonusSummary)
{
    local int Index;
    
    Index = FindTrackerIndex("SymbioteEvolutions");
    if (Index != INDEX_NONE && TotalEvolutions > 0)
    {
        PerkTrackers[Index].CurrentValue = TotalEvolutions;
        PerkTrackers[Index].MaxValue = 999;
        PerkTrackers[Index].bIsActive = true;
        PerkTrackers[Index].DisplayTime = 10.0f;
        PerkTrackers[Index].DisplayText = BonusSummary;
    }
}

function UpdateScavengerAdaptations(int CurrentKills, int MaxKills, optional bool bAdaptationComplete = false)
{
    UpdatePerkTracker("Scavenger", CurrentKills, MaxKills, bAdaptationComplete, 5.0f);
}

function UpdateScavengerAdaptationBonuses(int TotalAdaptations, string AdaptationSummary)
{
    local int Index;
    
    Index = FindTrackerIndex("ScavengerAdaptations");
    if (Index != INDEX_NONE && TotalAdaptations > 0)
    {
        PerkTrackers[Index].CurrentValue = TotalAdaptations;
        PerkTrackers[Index].MaxValue = 999;
        PerkTrackers[Index].bIsActive = true;
        PerkTrackers[Index].DisplayTime = 10.0f;
        PerkTrackers[Index].DisplayText = AdaptationSummary;
    }
}

function UpdateTycoonPortfolio(int CurrentDosh, int MaxDosh, optional bool bMilestoneComplete = false)
{
    UpdatePerkTracker("Tycoon", CurrentDosh, MaxDosh, bMilestoneComplete, 5.0f);
}

function UpdateTycoonPortfolioBonuses(int TotalMilestones, string PortfolioSummary)
{
    local int Index;
    
    Index = FindTrackerIndex("TycoonPortfolio");
    if (Index != INDEX_NONE && TotalMilestones > 0)
    {
        PerkTrackers[Index].CurrentValue = TotalMilestones;
        PerkTrackers[Index].MaxValue = 999;
        PerkTrackers[Index].bIsActive = true;
        PerkTrackers[Index].DisplayTime = 10.0f;
        PerkTrackers[Index].DisplayText = PortfolioSummary;
    }
}

function UpdateForgeWardenKills(int CurrentKills, int MaxKills, optional bool bMilestoneComplete = false)
{
    UpdatePerkTracker("ForgeWarden", CurrentKills, MaxKills, bMilestoneComplete, 5.0f);
}

function UpdateForgeWardenGrenadeBonuses(int TotalMilestones, string GrenadeSummary)
{
    local int Index;
    
    Index = FindTrackerIndex("ForgeWardenGrenades");
    if (Index != INDEX_NONE && TotalMilestones > 0)
    {
        PerkTrackers[Index].CurrentValue = TotalMilestones;
        PerkTrackers[Index].MaxValue = 999;
        PerkTrackers[Index].bIsActive = true;
        PerkTrackers[Index].DisplayTime = 10.0f;
        PerkTrackers[Index].DisplayText = GrenadeSummary;
    }
}

// ===================================================================
// CINDER PERK TRACKING FUNCTIONS
// ===================================================================


simulated function UpdateCinderTracking(int BurningCount, int FireKills, float PermanentBonus, bool bPhoenix, int UpgradeLevel, optional float PhoenixTimeRemaining = 0.0f)
{
    local int Index;
    local string BonusText;
    
    // Update burning enemy tracker (Level 10+)
    if (UpgradeLevel >= class'ZTConfig_Capstone'.default.Capstone_Rank1Level)
    {
        if (BurningCount > 0)
        {
            if (UpgradeLevel >= class'ZTConfig_Capstone'.default.Capstone_Rank2Level)
                BonusText = "+" $ (BurningCount * 8) $ "% Fire DMG";
            else
                BonusText = "+" $ (BurningCount * 5) $ "% Fire DMG";
            
            UpdatePerkTracker("CinderBurning", BurningCount, 10, false, 6.0f);
            
            // Set bonus text directly
            Index = FindTrackerIndex("CinderBurning");
            if (Index != INDEX_NONE)
            {
                PerkTrackers[Index].DisplayText = "Burning: " $ BonusText;
            }
        }
        else
        {
            UpdatePerkTracker("CinderBurning", 0, 10, false, 6.0f);
        }
    }
    
    // Update fire kills tracker (always show if kills > 0)
    if (FireKills > 0)
    {
        UpdatePerkTracker("CinderKills", FireKills, 1000, false, 8.0f);
        
        if (PermanentBonus > 0)
        {
            BonusText = "+" $ int(PermanentBonus * 100) $ "% Permanent";
            
            // Set bonus text directly
            Index = FindTrackerIndex("CinderKills");
            if (Index != INDEX_NONE)
            {
                PerkTrackers[Index].DisplayText = "Fire Kills: " $ BonusText;
            }
        }
    }
    
    // Update Phoenix Protocol tracker (Level 20+)
    if (UpgradeLevel >= class'ZTConfig_Capstone'.default.Capstone_Rank2Level && bPhoenix)
    {
        // Show countdown timer
        UpdatePerkTracker("CinderPhoenix", int(PhoenixTimeRemaining), 10, true, 10.0f);
        
        // Set custom display text with countdown
        Index = FindTrackerIndex("CinderPhoenix");
        if (Index != INDEX_NONE)
        {
            PerkTrackers[Index].DisplayText = "PHOENIX: " $ int(PhoenixTimeRemaining + 0.5f) $ "s - FULL IMMUNITY";
        }
        
        // Trigger notification only once when it starts (when time is near max)
        if (PhoenixTimeRemaining >= 9.5f)
        {
            TriggerChainNotification("PHOENIX PROTOCOL!", "10 seconds of FULL IMMUNITY - You cannot die!", 5.0f);
        }
    }
}

// ===================================================================
// HIVEMIND PERK TRACKING FUNCTIONS
// ===================================================================

simulated function UpdateHivemindTracking(int TeammatesConnected, int SwarmProgress, int SymbioteStage, bool bSwarmActive, float SwarmTimeRemaining, int UpgradeLevel)
{
    local int Index;
    local string DisplayText;
    local float TeamDamageBonus;
    
    // ===================================================================
    // PERMANENT TETHER DISPLAY - Show from Level 10+ (Neural Network)
    // ===================================================================
    if (UpgradeLevel >= class'ZTConfig_Capstone'.default.Capstone_Rank1Level)
    {
        // Calculate base team damage bonus
        TeamDamageBonus = UpgradeLevel * 2; // +2% per level
        
        if (TeammatesConnected > 0)
        {
            // Show active buff with teammate count
            DisplayText = "Buffing " $ TeammatesConnected $ " allies";
            
            // Show bonus percentages
            DisplayText = DisplayText $ " [+" $ int(TeamDamageBonus) $ "% DMG";
            
            // Level 10+: Add Neural Network bonus info
            if (UpgradeLevel >= class'ZTConfig_Capstone'.default.Capstone_Rank1Level && SymbioteStage > 0)
            {
                DisplayText = DisplayText $ ", +" $ (SymbioteStage * 5) $ "% Neural";
            }
            
            DisplayText = DisplayText $ "]";
        }
        else
        {
            // Show "no allies in range" with potential bonuses
            DisplayText = "No allies in range (10m)";
        }
        
        // Update with very long display time to keep it permanent
        UpdatePerkTracker("HivemindNetwork", TeammatesConnected, 5, true, 999.0f);
        
        Index = FindTrackerIndex("HivemindNetwork");
        if (Index != INDEX_NONE)
        {
            PerkTrackers[Index].DisplayText = DisplayText;
            // Force it to be active even when 0 teammates
            PerkTrackers[Index].bIsActive = true;
        }
    }
    
    // ===================================================================
    // SWARM COLLECTIVE PROGRESS TRACKER (Level 20+)
    // ===================================================================
    if (UpgradeLevel >= class'ZTConfig_Capstone'.default.Capstone_Rank2Level && !bSwarmActive)
    {
        if (SwarmProgress >= 20)
        {
            // Ready to activate - NO BLINKING (bCompleted=false)
            UpdatePerkTracker("HivemindSwarm", 20, 20, false, 10.0f);
            
            Index = FindTrackerIndex("HivemindSwarm");
            if (Index != INDEX_NONE)
            {
                PerkTrackers[Index].DisplayText = "SWARM READY!";
            }
        }
        else if (SwarmProgress > 0)
        {
            // Show progress - fades after 5 seconds of no kills
            UpdatePerkTracker("HivemindSwarm", SwarmProgress, 20, false, 5.0f);
            
            Index = FindTrackerIndex("HivemindSwarm");
            if (Index != INDEX_NONE)
            {
                // Just "Swarm" - the drawing code adds "X/20" automatically
                PerkTrackers[Index].DisplayText = "Swarm";
            }
        }
    }
    
    // ===================================================================
    // SWARM COLLECTIVE ACTIVE TRACKER
    // ===================================================================
    if (UpgradeLevel >= class'ZTConfig_Capstone'.default.Capstone_Rank2Level && bSwarmActive && SwarmTimeRemaining > 0)
    {
        // Display time matches remaining time so it fades immediately when done
        UpdatePerkTracker("HivemindActive", int(SwarmTimeRemaining), 8, true, SwarmTimeRemaining);
        
        Index = FindTrackerIndex("HivemindActive");
        if (Index != INDEX_NONE)
        {
            PerkTrackers[Index].DisplayText = "COLLECTIVE - TEAM BUFF!";
        }
    }
}

// ===================================================================
// PARASITE PERK TRACKING FUNCTIONS
// ===================================================================

simulated function UpdateParasiteTracking(int SiphonedCount, int HarvestProgress, bool bDoubleDrain, float DrainTimeRemaining, int UpgradeLevel, bool bPulseUsed)
{
    local int Index;
    local string BonusText;
    local string DisplayText;
    
    // ===================================================================
    // SIPHON TRACKER - Show from Level 10+ (always visible when active)
    // ===================================================================
    if (UpgradeLevel >= class'ZTConfig_Capstone'.default.Capstone_Rank1Level)
    {
        if (SiphonedCount > 0)
        {
            BonusText = "+" $ (SiphonedCount * 4) $ "% DMG";
            DisplayText = "Siphon: " $ BonusText $ " (" $ SiphonedCount $ "/8)";
        }
        else
        {
            DisplayText = "Siphon: No targets";
        }
        
        // Update with long display time to keep it visible
        UpdatePerkTracker("ParasiteSiphon", SiphonedCount, 8, true, 999.0f);
        
        Index = FindTrackerIndex("ParasiteSiphon");
        if (Index != INDEX_NONE)
        {
            PerkTrackers[Index].DisplayText = DisplayText;
            // Force it to be active even when 0 siphoned
            PerkTrackers[Index].bIsActive = true;
        }
    }
    
    // ===================================================================
    // BLOOD HARVEST PROGRESS TRACKER (Level 20+)
    // ===================================================================
    if (UpgradeLevel >= class'ZTConfig_Capstone'.default.Capstone_Rank2Level && !bPulseUsed)
    {
        if (HarvestProgress >= 20)
        {
            // Ready to trigger
            UpdatePerkTracker("ParasiteHarvest", 20, 20, true, 15.0f);
            
            Index = FindTrackerIndex("ParasiteHarvest");
            if (Index != INDEX_NONE)
            {
                PerkTrackers[Index].DisplayText = "HEMORRHAGE READY!";
            }
        }
        else if (HarvestProgress > 0)
        {
            // Show progress
            UpdatePerkTracker("ParasiteHarvest", HarvestProgress, 20, false, 8.0f);
            
            Index = FindTrackerIndex("ParasiteHarvest");
            if (Index != INDEX_NONE)
            {
                PerkTrackers[Index].DisplayText = "Blood Harvest: " $ HarvestProgress $ "/20";
            }
        }
    }
    
    // ===================================================================
    // DOUBLE LIFE STEAL ACTIVE TRACKER
    // ===================================================================
    if (UpgradeLevel >= class'ZTConfig_Capstone'.default.Capstone_Rank2Level && bDoubleDrain && DrainTimeRemaining > 0)
    {
        UpdatePerkTracker("ParasiteDrain", int(DrainTimeRemaining), 8, true, 10.0f);
        
        Index = FindTrackerIndex("ParasiteDrain");
        if (Index != INDEX_NONE)
        {
            PerkTrackers[Index].DisplayText = "DOUBLE DRAIN: " $ int(DrainTimeRemaining + 0.5f) $ "s";
        }
        
        // Trigger notification only once when it starts
        if (DrainTimeRemaining >= 7.5f)
        {
            TriggerChainNotification("HEMORRHAGE PULSE!", "Double life steal active! Drain your enemies!", 8.0f);
        }
    }
}

// ===================================================================
// SHAPESHIFTER HUD UPDATE FUNCTIONS
// ===================================================================

function UpdateShapeshifterBuff1(int BuffIndex, string BuffName)
{
    local int Index;

    Index = FindTrackerIndex("ShapeshifterBuff1");
    if (Index == INDEX_NONE) return;

    if (BuffIndex >= 0)
    {
        PerkTrackers[Index].bIsActive = true;
        PerkTrackers[Index].DisplayTime = 999.0f;
        PerkTrackers[Index].DisplayText = BuffName;
        PerkTrackers[Index].CurrentValue = 1;
        PerkTrackers[Index].MaxValue = 1;
        PerkTrackers[Index].PerkIcon = GetShapeshifterBuffIcon(BuffIndex);
    }
    else
    {
        PerkTrackers[Index].bIsActive = false;
    }

    HideShapeshifterMimicry();
}

function UpdateShapeshifterBuff2(int BuffIndex, string BuffName)
{
    local int Index;

    Index = FindTrackerIndex("ShapeshifterBuff2");
    if (Index == INDEX_NONE) return;

    if (BuffIndex >= 0)
    {
        PerkTrackers[Index].bIsActive = true;
        PerkTrackers[Index].DisplayTime = 999.0f;
        PerkTrackers[Index].DisplayText = BuffName;
        PerkTrackers[Index].CurrentValue = 1;
        PerkTrackers[Index].MaxValue = 1;
        PerkTrackers[Index].PerkIcon = GetShapeshifterBuffIcon(BuffIndex);
    }
    else
    {
        PerkTrackers[Index].bIsActive = false;
    }
}

function HideShapeshifterBuff2()
{
    local int Index;

    Index = FindTrackerIndex("ShapeshifterBuff2");
    if (Index != INDEX_NONE)
        PerkTrackers[Index].bIsActive = false;
}

function UpdateShapeshifterMimicry(int StackCount, int MaxStacks)
{
    local int Index;

    // Hide normal buff slots
    Index = FindTrackerIndex("ShapeshifterBuff1");
    if (Index != INDEX_NONE)
        PerkTrackers[Index].bIsActive = false;

    Index = FindTrackerIndex("ShapeshifterBuff2");
    if (Index != INDEX_NONE)
        PerkTrackers[Index].bIsActive = false;

    // Show Mimicry tracker
    Index = FindTrackerIndex("ShapeshifterMimicry");
    if (Index != INDEX_NONE)
    {
        PerkTrackers[Index].bIsActive = true;
        PerkTrackers[Index].DisplayTime = 999.0f;
        PerkTrackers[Index].CurrentValue = StackCount;
        PerkTrackers[Index].MaxValue = MaxStacks;
        PerkTrackers[Index].DisplayText = "Mimicry (" $ StackCount $ "/" $ MaxStacks $ ")";
        PerkTrackers[Index].PerkIcon = GetShapeshifterMimicryIcon(StackCount);
    }
}

function HideShapeshifterMimicry()
{
    local int Index;

    Index = FindTrackerIndex("ShapeshifterMimicry");
    if (Index != INDEX_NONE)
        PerkTrackers[Index].bIsActive = false;
}

// ===================================================================
// SHAPESHIFTER ICON LOOKUP FUNCTIONS
// ===================================================================

function Texture2D GetShapeshifterBuffIcon(int BuffIndex)
{
    switch(BuffIndex)
    {
        case 0:  return Texture2D'ZedternalRBPerkpackage_Resources.UI.Icons.Shapeshifter.UI_Buff_Carnage';
        case 1:  return Texture2D'ZedternalRBPerkpackage_Resources.UI.Icons.Shapeshifter.UI_Buff_Executioner';
        case 2:  return Texture2D'ZedternalRBPerkpackage_Resources.UI.Icons.Shapeshifter.UI_Buff_Rampage';
        case 3:  return Texture2D'ZedternalRBPerkpackage_Resources.UI.Icons.Shapeshifter.UI_Buff_Crusher';
        case 4:  return Texture2D'ZedternalRBPerkpackage_Resources.UI.Icons.Shapeshifter.UI_Buff_Berserker';
        case 5:  return Texture2D'ZedternalRBPerkpackage_Resources.UI.Icons.Shapeshifter.UI_Buff_Fortress';
        case 6:  return Texture2D'ZedternalRBPerkpackage_Resources.UI.Icons.Shapeshifter.UI_Buff_Leech';
        case 7:  return Texture2D'ZedternalRBPerkpackage_Resources.UI.Icons.Shapeshifter.UI_Buff_Anchor';
        case 8:  return Texture2D'ZedternalRBPerkpackage_Resources.UI.Icons.Shapeshifter.UI_Buff_Hawk';
        case 9:  return Texture2D'ZedternalRBPerkpackage_Resources.UI.Icons.Shapeshifter.UI_Buff_Speedloader';
        case 10: return Texture2D'ZedternalRBPerkpackage_Resources.UI.Icons.Shapeshifter.UI_Buff_Switchblade';
        case 11: return Texture2D'ZedternalRBPerkpackage_Resources.UI.Icons.Shapeshifter.UI_Buff_Speedfreak';
        case 12: return Texture2D'ZedternalRBPerkpackage_Resources.UI.Icons.Shapeshifter.UI_Buff_Hoarder';
        case 13: return Texture2D'ZedternalRBPerkpackage_Resources.UI.Icons.Shapeshifter.UI_Buff_Drumfire';
        case 14: return Texture2D'ZedternalRBPerkpackage_Resources.UI.Icons.Shapeshifter.UI_Buff_Phantom';
        default: return None;
    }
}

function Texture2D GetShapeshifterMimicryIcon(int StackCount)
{
    local int ClampedStack;

    ClampedStack = Clamp(StackCount, 1, 15);

    switch(ClampedStack)
    {
        case 1:  return Texture2D'ZedternalRBPerkpackage_Resources.UI.Icons.Shapeshifter.UI_Mimicry_01';
        case 2:  return Texture2D'ZedternalRBPerkpackage_Resources.UI.Icons.Shapeshifter.UI_Mimicry_02';
        case 3:  return Texture2D'ZedternalRBPerkpackage_Resources.UI.Icons.Shapeshifter.UI_Mimicry_03';
        case 4:  return Texture2D'ZedternalRBPerkpackage_Resources.UI.Icons.Shapeshifter.UI_Mimicry_04';
        case 5:  return Texture2D'ZedternalRBPerkpackage_Resources.UI.Icons.Shapeshifter.UI_Mimicry_05';
        case 6:  return Texture2D'ZedternalRBPerkpackage_Resources.UI.Icons.Shapeshifter.UI_Mimicry_06';
        case 7:  return Texture2D'ZedternalRBPerkpackage_Resources.UI.Icons.Shapeshifter.UI_Mimicry_07';
        case 8:  return Texture2D'ZedternalRBPerkpackage_Resources.UI.Icons.Shapeshifter.UI_Mimicry_08';
        case 9:  return Texture2D'ZedternalRBPerkpackage_Resources.UI.Icons.Shapeshifter.UI_Mimicry_09';
        case 10: return Texture2D'ZedternalRBPerkpackage_Resources.UI.Icons.Shapeshifter.UI_Mimicry_10';
        case 11: return Texture2D'ZedternalRBPerkpackage_Resources.UI.Icons.Shapeshifter.UI_Mimicry_11';
        case 12: return Texture2D'ZedternalRBPerkpackage_Resources.UI.Icons.Shapeshifter.UI_Mimicry_12';
        case 13: return Texture2D'ZedternalRBPerkpackage_Resources.UI.Icons.Shapeshifter.UI_Mimicry_13';
        case 14: return Texture2D'ZedternalRBPerkpackage_Resources.UI.Icons.Shapeshifter.UI_Mimicry_14';
        case 15: return Texture2D'ZedternalRBPerkpackage_Resources.UI.Icons.Shapeshifter.UI_Mimicry_15';
        default: return None;
    }
}

function AddPerkTracker(string PerkName, string DisplayText, Texture2D PerkIcon, Color TextColor, Color BackgroundColor, int MaxValue)
{
    local PerkTrackerData NewTracker;
    local int Index;
    
    Index = FindTrackerIndex(PerkName);
    if (Index != INDEX_NONE)
    {
        `log("Warning: Perk tracker" @ PerkName @ "already exists!");
        return;
    }
    
    NewTracker.PerkName = PerkName;
    NewTracker.DisplayText = DisplayText;
    NewTracker.PerkIcon = PerkIcon;
    NewTracker.TextColor = TextColor;
    NewTracker.BackgroundColor = BackgroundColor;
    NewTracker.MaxValue = MaxValue;
    NewTracker.CurrentValue = 0;
    NewTracker.bIsActive = false;
    NewTracker.DisplayTime = 0.0f;
    
    PerkTrackers.AddItem(NewTracker);
}

// ===================================================================
// UTILITY FUNCTIONS
// ===================================================================

// ===================================================================
// SHAPESHIFTER BUFF DISPLAY FUNCTIONS
// ===================================================================

/**
 * Called by ZTUpgrade_Perk_Shapeshifter_Helper.ClientUpdateShapeshifterHUD
 * to push buff data into the HUD for rendering.
 */
function UpdateShapeshifterDisplay(
    bool bIsMimicry,
    int Buff1Index, string Buff1Name, string Buff1Desc,
    int Buff2Index, string Buff2Name, string Buff2Desc,
    int StackCount, int MaxStack,
    int BuffMask)
{
    ShapeshifterDisplay.bIsActive = true;
    ShapeshifterDisplay.bIsMimicry = bIsMimicry;
    ShapeshifterDisplay.Buff1Index = Buff1Index;
    ShapeshifterDisplay.Buff1Name = Buff1Name;
    ShapeshifterDisplay.Buff1Desc = Buff1Desc;
    ShapeshifterDisplay.Buff2Index = Buff2Index;
    ShapeshifterDisplay.Buff2Name = Buff2Name;
    ShapeshifterDisplay.Buff2Desc = Buff2Desc;
    ShapeshifterDisplay.MimicryStack = StackCount;
    ShapeshifterDisplay.MimicryMax = MaxStack;
    ShapeshifterDisplay.BuffMask = BuffMask;
}

/** Clear the Shapeshifter display (e.g. on death / perk removed). */
function ClearShapeshifterDisplay()
{
    ShapeshifterDisplay.bIsActive = false;
}

/** Main Shapeshifter HUD draw - 64x64 icons with name + description.
 *  Normal mode:  1-2 large buff icons with names and descriptions.
 *  Mimicry mode: Header line + compact grid of 24x24 collected buff icons (5 per row).
 */
// ===================================================================
// SHAPESHIFTER LOCALIZATION HELPERS
// The Shapeshifter helper (server-side) sends Buff1Index/Buff2Index +
// the formatted English Buff1Desc/Buff2Desc strings via RPC. We use the
// indices to look up the localized buff name, and parse the desc string
// to swap the English stat suffix with the localized one. The numeric
// prefix (e.g. "-3%" or "+1") is locale-neutral and stays as-is.
// ===================================================================
function string GetLocalizedShapeshifterBuffName(int Idx)
{
    switch (Idx)
    {
        case 0:  return ShapeshifterBuff_0;
        case 1:  return ShapeshifterBuff_1;
        case 2:  return ShapeshifterBuff_2;
        case 3:  return ShapeshifterBuff_3;
        case 4:  return ShapeshifterBuff_4;
        case 5:  return ShapeshifterBuff_5;
        case 6:  return ShapeshifterBuff_6;
        case 7:  return ShapeshifterBuff_7;
        case 8:  return ShapeshifterBuff_8;
        case 9:  return ShapeshifterBuff_9;
        case 10: return ShapeshifterBuff_10;
        case 11: return ShapeshifterBuff_11;
        case 12: return ShapeshifterBuff_12;
        case 13: return ShapeshifterBuff_13;
        case 14: return ShapeshifterBuff_14;
        default: return "";
    }
}

function string GetLocalizedShapeshifterStat(int Idx)
{
    switch (Idx)
    {
        case 0:  return ShapeshifterStat_0;
        case 1:  return ShapeshifterStat_1;
        case 2:  return ShapeshifterStat_2;
        case 3:  return ShapeshifterStat_3;
        case 4:  return ShapeshifterStat_4;
        case 5:  return ShapeshifterStat_5;
        case 6:  return ShapeshifterStat_6;
        case 7:  return ShapeshifterStat_7;
        case 8:  return ShapeshifterStat_8;
        case 9:  return ShapeshifterStat_9;
        case 10: return ShapeshifterStat_10;
        case 11: return ShapeshifterStat_11;
        case 12: return ShapeshifterStat_12;
        case 13: return ShapeshifterStat_13;
        case 14: return ShapeshifterStat_14;
        default: return "";
    }
}

// Replace the English stat suffix in Buff1Desc/Buff2Desc with the localized
// version. Format from the helper: "<sign><N>[%] <Stat>" -- the first space
// separates the locale-neutral numeric prefix from the English stat name.
function string LocalizeShapeshifterBuffDesc(int BuffIndex, string OriginalDesc)
{
    local int FirstSpaceIdx;
    local string LocalizedStat;

    LocalizedStat = GetLocalizedShapeshifterStat(BuffIndex);
    if (LocalizedStat == "")
        return OriginalDesc;

    FirstSpaceIdx = InStr(OriginalDesc, " ");
    if (FirstSpaceIdx <= 0)
        return OriginalDesc;

    return Left(OriginalDesc, FirstSpaceIdx) @ LocalizedStat;
}

// Build localized Mimicry-gain popup message. Called from ZTPlayerController's
// reliable client RPC, which receives buff index + helper-formatted desc from
// the server. Substitutes localized buff name + localized desc into the template.
function string FormatShapeshifterMimicryGain(int BuffIndex, string OriginalDesc, int StackCount)
{
    local string Result;

    Result = Shapeshifter_MimicryTemplate;
    Result = Repl(Result, "%1", GetLocalizedShapeshifterBuffName(BuffIndex));
    Result = Repl(Result, "%2", LocalizeShapeshifterBuffDesc(BuffIndex, OriginalDesc));
    Result = Repl(Result, "%3", string(StackCount));
    return Result;
}

// Build localized Shapeshifted (transform) popup message. Buff2Idx == -1 selects
// the single-buff template; otherwise the dual template is used.
function string FormatShapeshifterTransform(int Buff1Idx, string Desc1, int Buff2Idx, string Desc2)
{
    local string Result;

    if (Buff2Idx >= 0)
    {
        Result = Shapeshifter_TransformDualTemplate;
        Result = Repl(Result, "%3", GetLocalizedShapeshifterBuffName(Buff2Idx));
        Result = Repl(Result, "%4", LocalizeShapeshifterBuffDesc(Buff2Idx, Desc2));
    }
    else
    {
        Result = Shapeshifter_TransformSingleTemplate;
    }

    Result = Repl(Result, "%1", GetLocalizedShapeshifterBuffName(Buff1Idx));
    Result = Repl(Result, "%2", LocalizeShapeshifterBuffDesc(Buff1Idx, Desc1));
    return Result;
}

function DrawShapeshifterDisplay()
{
    local float XPos, YPos, IconSz, TxtScale, DescScale;
    local Texture2D BuffIcon;
    local Color NameColor, DescColor, MimicryColor;
    local int i, GridCol;
    local float MiniIconSz, MiniIconGap, GridX, GridY;
    local float RS;

    if (Canvas == None)
        return;

    RS = ResScale;
    IconSz  = ShapeshifterIconSize * RS;  // 64 * RS
    TxtScale = 1.0f * RS;
    DescScale = 0.8f * RS;

    XPos = Canvas.SizeX * DisplayCardBaseX;
    YPos = Canvas.SizeY * GetDisplayCardY(CARD_SHAPESHIFTER);

    NameColor = MakeColorFromRGB(200, 125, 255, 255);   // Shapeshifter purple
    DescColor = MakeColorFromRGB(180, 180, 220, 255);    // Light blue-grey
    MimicryColor = MakeColorFromRGB(255, 160, 0, 255);   // Mimicry orange

    Canvas.Font = class'KFGameEngine'.Static.GetKFCanvasFont();

    if (ShapeshifterDisplay.bIsMimicry)
    {
        // ---- MIMICRY MODE ----
        // Header: Mimicry icon + "Mimicry 5/15"
        BuffIcon = GetMimicryIcon(ShapeshifterDisplay.MimicryStack);

        if (BuffIcon != None)
        {
            Canvas.SetDrawColor(255, 255, 255, 255);
            Canvas.SetPos(XPos, YPos);
            Canvas.DrawTile(BuffIcon, IconSz, IconSz, 0, 0, BuffIcon.SizeX, BuffIcon.SizeY);
        }

        DrawTextWithShadow(
            ShapeshifterMimicry_Display @ ShapeshifterDisplay.MimicryStack $ "/" $ ShapeshifterDisplay.MimicryMax,
            XPos + IconSz + 8 * RS, YPos + 8 * RS, MimicryColor, TxtScale);
        DrawTextWithShadow(
            Shapeshifter_PermanentStacking,
            XPos + IconSz + 8 * RS, YPos + 32 * RS, DescColor, DescScale);

        // Compact grid of collected buff icons below the header
        // 24x24 icons, 4px gap, 5 per row => max 3 rows for 15 buffs
        MiniIconSz = 24.0f * RS;
        MiniIconGap = 4.0f * RS;
        GridX = XPos;
        GridY = YPos + IconSz + 12 * RS;  // Below the main Mimicry icon
        GridCol = 0;

        for (i = 0; i < 15; i++)
        {
            // Only draw collected buffs (check bitmask)
            if ((ShapeshifterDisplay.BuffMask & (1 << i)) != 0)
            {
                BuffIcon = GetShapeshifterIcon(i);
                if (BuffIcon != None)
                {
                    Canvas.SetDrawColor(255, 255, 255, 255);
                    Canvas.SetPos(GridX + (GridCol * (MiniIconSz + MiniIconGap)), GridY);
                    Canvas.DrawTile(BuffIcon, MiniIconSz, MiniIconSz, 0, 0, BuffIcon.SizeX, BuffIcon.SizeY);
                }

                GridCol++;
                if (GridCol >= 5)
                {
                    GridCol = 0;
                    GridY += MiniIconSz + MiniIconGap;
                }
            }
        }
    }
    else
    {
        // ---- NORMAL BUFF MODE ----
        // Buff 1 (always present)
        if (ShapeshifterDisplay.Buff1Index >= 0)
        {
            BuffIcon = GetShapeshifterIcon(ShapeshifterDisplay.Buff1Index);
            if (BuffIcon != None)
            {
                Canvas.SetDrawColor(255, 255, 255, 255);
                Canvas.SetPos(XPos, YPos);
                Canvas.DrawTile(BuffIcon, IconSz, IconSz, 0, 0, BuffIcon.SizeX, BuffIcon.SizeY);
            }

            DrawTextWithShadow(GetLocalizedShapeshifterBuffName(ShapeshifterDisplay.Buff1Index),
                XPos + IconSz + 8 * RS, YPos + 8 * RS, NameColor, TxtScale);
            DrawTextWithShadow(LocalizeShapeshifterBuffDesc(ShapeshifterDisplay.Buff1Index, ShapeshifterDisplay.Buff1Desc),
                XPos + IconSz + 8 * RS, YPos + 32 * RS, DescColor, DescScale);
        }

        // Buff 2 (rank 10-19 only)
        if (ShapeshifterDisplay.Buff2Index >= 0)
        {
            YPos += IconSz + 16 * RS;
            BuffIcon = GetShapeshifterIcon(ShapeshifterDisplay.Buff2Index);
            if (BuffIcon != None)
            {
                Canvas.SetDrawColor(255, 255, 255, 255);
                Canvas.SetPos(XPos, YPos);
                Canvas.DrawTile(BuffIcon, IconSz, IconSz, 0, 0, BuffIcon.SizeX, BuffIcon.SizeY);
            }

            DrawTextWithShadow(GetLocalizedShapeshifterBuffName(ShapeshifterDisplay.Buff2Index),
                XPos + IconSz + 8 * RS, YPos + 8 * RS, NameColor, TxtScale);
            DrawTextWithShadow(LocalizeShapeshifterBuffDesc(ShapeshifterDisplay.Buff2Index, ShapeshifterDisplay.Buff2Desc),
                XPos + IconSz + 8 * RS, YPos + 32 * RS, DescColor, DescScale);
        }
    }
}

/** Map buff index to its 128x128 icon texture. */
function Texture2D GetShapeshifterIcon(int BuffIndex)
{
    switch (BuffIndex)
    {
        case 0:  return Texture2D'ZedternalRBPerkpackage_Resources.Buffs.UI_Buff_Carnage';
        case 1:  return Texture2D'ZedternalRBPerkpackage_Resources.Buffs.UI_Buff_Executioner';
        case 2:  return Texture2D'ZedternalRBPerkpackage_Resources.Buffs.UI_Buff_Rampage';
        case 3:  return Texture2D'ZedternalRBPerkpackage_Resources.Buffs.UI_Buff_Crusher';
        case 4:  return Texture2D'ZedternalRBPerkpackage_Resources.Buffs.UI_Buff_Berserker';
        case 5:  return Texture2D'ZedternalRBPerkpackage_Resources.Buffs.UI_Buff_Fortress';
        case 6:  return Texture2D'ZedternalRBPerkpackage_Resources.Buffs.UI_Buff_Leech';
        case 7:  return Texture2D'ZedternalRBPerkpackage_Resources.Buffs.UI_Buff_Anchor';
        case 8:  return Texture2D'ZedternalRBPerkpackage_Resources.Buffs.UI_Buff_Hawk';
        case 9:  return Texture2D'ZedternalRBPerkpackage_Resources.Buffs.UI_Buff_Speedloader';
        case 10: return Texture2D'ZedternalRBPerkpackage_Resources.Buffs.UI_Buff_Switchblade';
        case 11: return Texture2D'ZedternalRBPerkpackage_Resources.Buffs.UI_Buff_Speedfreak';
        case 12: return Texture2D'ZedternalRBPerkpackage_Resources.Buffs.UI_Buff_Hoarder';
        case 13: return Texture2D'ZedternalRBPerkpackage_Resources.Buffs.UI_Buff_Drumfire';
        case 14: return Texture2D'ZedternalRBPerkpackage_Resources.Buffs.UI_Buff_Phantom';
        default: return None;
    }
}

/** Map Mimicry stack count (1-15) to its dedicated icon. */
function Texture2D GetMimicryIcon(int StackCount)
{
    switch (StackCount)
    {
        case 1:  return Texture2D'ZedternalRBPerkpackage_Resources.Buffs.UI_Mimicry_01';
        case 2:  return Texture2D'ZedternalRBPerkpackage_Resources.Buffs.UI_Mimicry_02';
        case 3:  return Texture2D'ZedternalRBPerkpackage_Resources.Buffs.UI_Mimicry_03';
        case 4:  return Texture2D'ZedternalRBPerkpackage_Resources.Buffs.UI_Mimicry_04';
        case 5:  return Texture2D'ZedternalRBPerkpackage_Resources.Buffs.UI_Mimicry_05';
        case 6:  return Texture2D'ZedternalRBPerkpackage_Resources.Buffs.UI_Mimicry_06';
        case 7:  return Texture2D'ZedternalRBPerkpackage_Resources.Buffs.UI_Mimicry_07';
        case 8:  return Texture2D'ZedternalRBPerkpackage_Resources.Buffs.UI_Mimicry_08';
        case 9:  return Texture2D'ZedternalRBPerkpackage_Resources.Buffs.UI_Mimicry_09';
        case 10: return Texture2D'ZedternalRBPerkpackage_Resources.Buffs.UI_Mimicry_10';
        case 11: return Texture2D'ZedternalRBPerkpackage_Resources.Buffs.UI_Mimicry_11';
        case 12: return Texture2D'ZedternalRBPerkpackage_Resources.Buffs.UI_Mimicry_12';
        case 13: return Texture2D'ZedternalRBPerkpackage_Resources.Buffs.UI_Mimicry_13';
        case 14: return Texture2D'ZedternalRBPerkpackage_Resources.Buffs.UI_Mimicry_14';
        case 15: return Texture2D'ZedternalRBPerkpackage_Resources.Buffs.UI_Mimicry_15';
        default: return Texture2D'ZedternalRBPerkpackage_Resources.Buffs.UI_Mimicry_01';
    }
}

// ===================================================================
// GAMBIT CHALLENGE DISPLAY - Initialize, Update, Clear, Draw
// ===================================================================

/** Initialize Gambit display to inactive state. */
function InitializeGambitDisplay()
{
    GambitDisplay.bIsActive = false;
    GambitDisplay.bCompleted = false;
    GambitDisplay.Rarity = 0;
    GambitDisplay.GambitIndex = 255;
    GambitDisplay.GambitName = "";
    GambitDisplay.Description = "";
    GambitDisplay.ProgressString = "";
    GambitDisplay.SecondaryInfo = "";
    GambitDisplay.Progress = 0;
    GambitDisplay.Target = 0;
    GambitDisplay.Completions = 0;
    GambitDisplay.AccDamage = 0.0f;
    GambitDisplay.AccSpeed = 0.0f;
}

/** Called by Gambit helper to push display data to HUD.
 *  Helper builds all strings client-side and passes them pre-formatted. */
function UpdateGambitDisplay(
    bool bActive, bool bCompleted, byte Rarity, byte InGambitIndex,
    string GambitName, string Desc, string Progress, string Secondary,
    int ProgressVal, int TargetVal, int Completions,
    float AccDmg, float AccSpd)
{
    GambitDisplay.bIsActive = bActive;
    GambitDisplay.bCompleted = bCompleted;
    GambitDisplay.Rarity = Rarity;
    GambitDisplay.GambitIndex = InGambitIndex;
    GambitDisplay.GambitName = GambitName;
    GambitDisplay.Description = Desc;
    GambitDisplay.ProgressString = Progress;
    GambitDisplay.SecondaryInfo = Secondary;
    GambitDisplay.Progress = ProgressVal;
    GambitDisplay.Target = TargetVal;
    GambitDisplay.Completions = Completions;
    GambitDisplay.AccDamage = AccDmg;
    GambitDisplay.AccSpeed = AccSpd;
}

/** Clear the Gambit display (e.g. on death / perk removed). */
function ClearGambitDisplay()
{
    GambitDisplay.bIsActive = false;
}

/** Get rarity color for Gambit display borders and text. */
function Color GetGambitRarityColor(byte Rarity)
{
    switch (Rarity)
    {
        case 0:  return MakeColorFromRGB(200, 200, 200, 255);  // Normal - Light grey
        case 1:  return MakeColorFromRGB(80, 160, 255, 255);   // Rare - Blue
        case 2:  return MakeColorFromRGB(180, 80, 255, 255);   // Legendary - Purple
        case 3:  return MakeColorFromRGB(255, 200, 50, 255);   // Mythic - Gold
        default: return MakeColorFromRGB(200, 200, 200, 255);
    }
}

/** Map gambit index (0-13) to its 128x128 icon texture. */
function Texture2D GetGambitIcon(byte GambitIndex)
{
    switch (GambitIndex)
    {
        case 0:  return Texture2D'ZedternalRBPerkpackage_Resources.Buffs.UI_Gambit_Marksman';
        case 1:  return Texture2D'ZedternalRBPerkpackage_Resources.Buffs.UI_Gambit_BodyCount';
        case 2:  return Texture2D'ZedternalRBPerkpackage_Resources.Buffs.UI_Gambit_IronSkin';
        case 3:  return Texture2D'ZedternalRBPerkpackage_Resources.Buffs.UI_Gambit_Blitz';
        case 4:  return Texture2D'ZedternalRBPerkpackage_Resources.Buffs.UI_Gambit_BigGame';
        case 5:  return Texture2D'ZedternalRBPerkpackage_Resources.Buffs.UI_Gambit_Perfectionist';
        case 6:  return Texture2D'ZedternalRBPerkpackage_Resources.Buffs.UI_Gambit_Untouchable';
        case 7:  return Texture2D'ZedternalRBPerkpackage_Resources.Buffs.UI_Gambit_RapidFire';
        case 8:  return Texture2D'ZedternalRBPerkpackage_Resources.Buffs.UI_Gambit_Desperado';
        case 9:  return Texture2D'ZedternalRBPerkpackage_Resources.Buffs.UI_Gambit_Deadeye';
        case 10: return Texture2D'ZedternalRBPerkpackage_Resources.Buffs.UI_Gambit_Flawless';
        case 11: return Texture2D'ZedternalRBPerkpackage_Resources.Buffs.UI_Gambit_Endurance';
        case 12: return Texture2D'ZedternalRBPerkpackage_Resources.Buffs.UI_Gambit_ImpossibleOdds';
        case 13: return Texture2D'ZedternalRBPerkpackage_Resources.Buffs.UI_Gambit_OneBullet';
        default: return None;
    }
}

/** Main Gambit HUD draw - challenge card with progress bar.
 *  Position: same region as Shapeshifter (top-right). Mutually exclusive.
 *  Layout:
 *    [Rarity-colored border]
 *    | Gambit Name (rarity color)         |
 *    | Description (grey)                 |
 *    | [======progress bar======]         |
 *    | Progress text (white)              |
 *    | Secondary info (light grey)        |
 *    [/border]                             */
// ===================================================================
// GAMBIT LOCALIZATION HELPERS
// The Gambit helper class (ZTUpgrade_Perk_Gambit_Helper) replicates
// GambitIndex/Rarity/Progress/Target/SecondaryParam to the client and
// PushToHUD calls into these helpers to format the card text using
// the active locale's [ZTHudWrapper] section.
// ===================================================================

function string GetLocalizedGambitName(int Idx)
{
    switch (Idx)
    {
        case 0:  return GambitName_0;
        case 1:  return GambitName_1;
        case 2:  return GambitName_2;
        case 3:  return GambitName_3;
        case 4:  return GambitName_4;
        case 5:  return GambitName_5;
        case 6:  return GambitName_6;
        case 7:  return GambitName_7;
        case 8:  return GambitName_8;
        case 9:  return GambitName_9;
        case 10: return GambitName_10;
        case 11: return GambitName_11;
        case 12: return GambitName_12;
        case 13: return GambitName_13;
        default: return "";
    }
}

function string GetLocalizedGambitDesc(int Idx)
{
    switch (Idx)
    {
        case 0:  return GambitDesc_0;
        case 1:  return GambitDesc_1;
        case 2:  return GambitDesc_2;
        case 3:  return GambitDesc_3;
        case 4:  return GambitDesc_4;
        case 5:  return GambitDesc_5;
        case 6:  return GambitDesc_6;
        case 7:  return GambitDesc_7;
        case 8:  return GambitDesc_8;
        case 9:  return GambitDesc_9;
        case 10: return GambitDesc_10;
        case 11: return GambitDesc_11;
        case 12: return GambitDesc_12;
        case 13: return GambitDesc_13;
        default: return "";
    }
}

function string GetLocalizedGambitRarity(byte Rarity)
{
    switch (Rarity)
    {
        case 0: return GambitRarity_Normal;
        case 1: return GambitRarity_Rare;
        case 2: return GambitRarity_Legendary;
        case 3: return GambitRarity_Mythic;
        default: return GambitRarity_Normal;
    }
}

// Build the localized description with %t (target) and %s (secondary) substituted.
function string BuildLocalizedGambitDesc(int Idx, int Target, int SecondaryParam)
{
    local string Desc;
    Desc = GetLocalizedGambitDesc(Idx);
    Desc = Repl(Desc, "%t", string(Target));
    Desc = Repl(Desc, "%s", string(SecondaryParam));
    return Desc;
}

// Build the localized progress string for a given condition type.
// Mirrors the switch in ZTUpgrade_Perk_Gambit_Helper.BuildProgressString.
// ConditionType constants:
//   0=KILL_COUNT, 1=HEADSHOT, 2=MAX_DAMAGE_TAKEN, 3=TIMED_KILLS, 4=LARGE_ZED,
//   5=HEADSHOT_RATIO, 6=ZERO_DAMAGE, 7=RAPID_KILLS, 8=LOW_HP, 9=LARGE_HEADSHOT,
//   10=FLAWLESS, 11=LOW_RELOAD, 12=SIDEARM_LARGE, 13=SINGLE_MAG
function string BuildLocalizedGambitProgress(byte ConditionType, int Progress, int Target, bool bCompleted)
{
    if (bCompleted)
        return Gambit_Progress_Complete;

    switch (ConditionType)
    {
        case 0:  // KILL_COUNT
        case 1:  // HEADSHOT_KILLS
        case 4:  // LARGE_ZED_KILLS
        case 7:  // RAPID_KILLS
        case 8:  // LOW_HP_KILLS
        case 9:  // LARGE_HEADSHOT_KILLS
        case 13: // SINGLE_MAG_KILLS
            return Progress $ " / " $ Target;

        case 2:  // MAX_DAMAGE_TAKEN
            return Progress $ Gambit_Progress_BudgetRemaining;

        case 3:  // TIMED_KILLS
            return Progress $ " / " $ Target @ Gambit_Progress_Kills;

        case 5:  // HEADSHOT_RATIO
        case 10: // FLAWLESS
            return Progress $ " / " $ Target @ Gambit_Progress_Kills;

        case 6:  // ZERO_DAMAGE
            return Progress > 0 ? Gambit_Progress_Clean : Gambit_Progress_Hit;

        case 11: // LOW_RELOAD_KILLS
            return Progress $ " / " $ Target @ Gambit_Progress_Kills;

        case 12: // SIDEARM_LARGE_KILL
            return Progress > 0 ? Gambit_Progress_Done : Gambit_Progress_Waiting;

        default:
            return Progress $ " / " $ Target;
    }
}

// Build the localized secondary info string (e.g. timer countdown, ratios).
function string BuildLocalizedGambitSecondary(byte ConditionType, int Secondary, int SecondaryParam)
{
    switch (ConditionType)
    {
        case 3:  // TIMED_KILLS
            if (Secondary > 0)
                return Secondary $ Gambit_Secondary_SecondsRemaining;
            else
                return Gambit_Secondary_TimeExpired;

        case 5:  // HEADSHOT_RATIO
            return Gambit_Secondary_HSRatio $ Secondary $ Gambit_Secondary_HSRatioNeed
                $ SecondaryParam $ Gambit_Secondary_HSRatioClose;

        case 10: // FLAWLESS
            return Gambit_Secondary_HSPrefix $ (Secondary / 1000) $ Gambit_Secondary_DmgSep
                $ (Secondary % 1000) $ Gambit_Secondary_DmgMax;

        case 11: // LOW_RELOAD_KILLS
            return Gambit_Secondary_Reloads $ Secondary $ " / " $ SecondaryParam;

        default:
            return "";
    }
}

// ===================================================================
// GAMBIT POPUP FORMAT FUNCTIONS
// Called from ZTPlayerController.ClientGambit* RPCs to build localized
// popup messages from server-sent indices.
// ===================================================================

function string FormatGambitStartPopup(byte Rarity, byte GambitIdx, int Target, int SecondaryParam)
{
    local string Result, Desc;

    Desc = BuildLocalizedGambitDesc(int(GambitIdx), Target, SecondaryParam);

    Result = Gambit_StartTemplate;
    Result = Repl(Result, "%1", GetLocalizedGambitRarity(Rarity));
    Result = Repl(Result, "%2", GetLocalizedGambitName(int(GambitIdx)));
    Result = Repl(Result, "%3", Desc);
    return Result;
}

function string FormatGambitAutoComplete(byte GambitIdx)
{
    local string Result;
    Result = Gambit_AutoCompleteTemplate;
    Result = Repl(Result, "%1", GetLocalizedGambitName(int(GambitIdx)));
    return Result;
}

function string FormatGambitExpired(byte GambitIdx)
{
    local string Result;
    Result = Gambit_ExpiredTemplate;
    Result = Repl(Result, "%1", GetLocalizedGambitName(int(GambitIdx)));
    return Result;
}

function string FormatGambitMidWaveComplete(byte GambitIdx)
{
    local string Result;
    Result = Gambit_MidWaveCompleteTemplate;
    Result = Repl(Result, "%1", GetLocalizedGambitName(int(GambitIdx)));
    return Result;
}

// Format the REWARD popup. Server sends already-formatted percentages so we
// just substitute localized component labels ("DMG", "Dosh", etc.).
// DamagePctFmt / SpeedPctFmt are pre-formatted strings like "+5.0%" sent by server.
// Empty string means that component wasn't awarded.
function string FormatGambitReward(string DamagePctFmt, int DoshAmount, string SpeedPctFmt, int CardSharkDosh, int CardSharkStacks)
{
    local string Msg, Reward;

    Msg = "";

    if (DamagePctFmt != "")
        Msg $= DamagePctFmt $ Gambit_Reward_Damage;

    if (DoshAmount > 0)
    {
        if (Msg != "")
            Msg $= " | ";
        Msg $= "+" $ DoshAmount $ Gambit_Reward_Dosh;
    }

    if (SpeedPctFmt != "")
    {
        if (Msg != "")
            Msg $= " | ";
        Msg $= SpeedPctFmt $ Gambit_Reward_Speed;
    }

    if (CardSharkDosh > 0)
    {
        if (Msg != "")
            Msg $= " | ";
        Msg $= "+" $ CardSharkDosh $ Gambit_Reward_CardSharkPrefix
            $ CardSharkStacks $ Gambit_Reward_CardSharkSuffix;
    }

    if (Msg == "")
        Msg = Gambit_Reward_NoReward;

    Reward = Gambit_RewardTemplate;
    Reward = Repl(Reward, "%1", Msg);
    return Reward;
}

function DrawGambitDisplay()
{
    local float BoxX, BoxY, BoxW, BoxH;
    local float PadX, PadY, LineH, SmallLineH;
    local float BarX, BarY, BarW, BarH, BarFill;
    local float CurY, TextX;
    local float IconSz, IconPad;
    local float TxtScale, SmallTxtScale;
    local Color RarityColor, TextColor, SecondaryColor, CompleteColor;
    local Texture2D GambitIcon;

    if (Canvas == None)
        return;

    // --- Fixed sizes (compact card, scaled from 720p baseline) ---
    IconSz = 48.0f * ResScale;
    IconPad = 6.0f * ResScale;
    PadX = 8.0f * ResScale;
    PadY = 6.0f * ResScale;
    LineH = 18.0f * ResScale;
    SmallLineH = 14.0f * ResScale;
    TxtScale = 0.7f * ResScale;
    SmallTxtScale = 0.55f * ResScale;
    BoxW = 280.0f * ResScale;

    // Position: from card stacking system
    BoxX = Canvas.SizeX * DisplayCardBaseX;
    BoxY = Canvas.SizeY * GetDisplayCardY(CARD_GAMBIT);

    // --- Colors ---
    RarityColor = GetGambitRarityColor(GambitDisplay.Rarity);
    TextColor = MakeColorFromRGB(220, 220, 220, 255);
    SecondaryColor = MakeColorFromRGB(160, 160, 160, 255);
    CompleteColor = MakeColorFromRGB(50, 255, 50, 255);

    // Text content starts after icon column
    TextX = BoxX + PadX + IconSz + IconPad;

    // --- Compute box height dynamically ---
    BoxH = PadY * 2.0f;            // Top + bottom padding
    BoxH += LineH;                  // Gambit name
    BoxH += SmallLineH;            // Description
    BoxH += PadY;                  // Gap before progress bar
    BoxH += 8.0f * ResScale;       // Progress bar height
    BoxH += 4.0f * ResScale;       // Gap
    BoxH += SmallLineH;            // Progress text
    if (GambitDisplay.SecondaryInfo != "")
        BoxH += SmallLineH;        // Secondary info

    // Ensure box is tall enough for icon + padding
    if (BoxH < IconSz + PadY * 2.0f)
        BoxH = IconSz + PadY * 2.0f;

    Canvas.Font = class'KFGameEngine'.Static.GetKFCanvasFont();

    // --- Dark background ---
    Canvas.SetDrawColor(0, 0, 0, 160);
    Canvas.SetPos(BoxX, BoxY);
    Canvas.DrawRect(BoxW, BoxH);

    // --- Rarity-colored border (2px, scaled) ---
    Canvas.SetDrawColor(RarityColor.R, RarityColor.G, RarityColor.B, 200);
    Canvas.SetPos(BoxX, BoxY);
    Canvas.DrawRect(BoxW, 2.0f * ResScale);
    Canvas.SetPos(BoxX, BoxY + BoxH - 2.0f * ResScale);
    Canvas.DrawRect(BoxW, 2.0f * ResScale);
    Canvas.SetPos(BoxX, BoxY);
    Canvas.DrawRect(2.0f * ResScale, BoxH);
    Canvas.SetPos(BoxX + BoxW - 2.0f * ResScale, BoxY);
    Canvas.DrawRect(2.0f * ResScale, BoxH);

    // --- Icon (left side, vertically centered in card) ---
    GambitIcon = GetGambitIcon(GambitDisplay.GambitIndex);
    if (GambitIcon != None)
    {
        Canvas.SetDrawColor(255, 255, 255, 255);
        Canvas.SetPos(BoxX + PadX, BoxY + (BoxH - IconSz) * 0.5f);
        Canvas.DrawTile(GambitIcon, IconSz, IconSz, 0, 0, GambitIcon.SizeX, GambitIcon.SizeY);
    }

    // --- Content rendering (right of icon) ---
    CurY = BoxY + PadY;

    // Gambit name (rarity colored, or green COMPLETE!)
    if (GambitDisplay.bCompleted)
        DrawTextWithShadow(Gambit_CompletePrefix @ GambitDisplay.GambitName, TextX, CurY, CompleteColor, TxtScale);
    else
        DrawTextWithShadow(GambitDisplay.GambitName, TextX, CurY, RarityColor, TxtScale);
    CurY += LineH;

    // Description
    DrawTextWithShadow(GambitDisplay.Description, TextX, CurY, TextColor, SmallTxtScale);
    CurY += SmallLineH + PadY;

    // Progress bar (spans from icon right edge to card right edge)
    BarX = TextX;
    BarW = (BoxX + BoxW - PadX) - TextX;
    BarH = 8.0f * ResScale;
    BarY = CurY;

    BarFill = (GambitDisplay.Target > 0) ? FClamp(float(GambitDisplay.Progress) / float(GambitDisplay.Target), 0.0f, 1.0f) : 0.0f;

    // Bar background
    Canvas.SetDrawColor(40, 40, 40, 200);
    Canvas.SetPos(BarX, BarY);
    Canvas.DrawRect(BarW, BarH);

    // Bar fill (green if completed, rarity color otherwise)
    if (GambitDisplay.bCompleted)
        Canvas.SetDrawColor(50, 255, 50, 200);
    else
        Canvas.SetDrawColor(RarityColor.R, RarityColor.G, RarityColor.B, 200);
    Canvas.SetPos(BarX, BarY);
    Canvas.DrawRect(BarW * BarFill, BarH);

    CurY = BarY + BarH + 4.0f * ResScale;

    // Progress text
    DrawTextWithShadow(GambitDisplay.ProgressString, TextX, CurY, TextColor, SmallTxtScale);
    CurY += SmallLineH;

    // Secondary info (if applicable)
    if (GambitDisplay.SecondaryInfo != "")
    {
        DrawTextWithShadow(GambitDisplay.SecondaryInfo, TextX, CurY, SecondaryColor, SmallTxtScale);
        CurY += SmallLineH;
    }
}

// ===================================================================
// GAMBIT BUFFS OVERLAY - toggled via console command "GambitBuffs"
// ===================================================================

/** Console command (no admin required). Toggles the buffs overlay.
 *  Reads replicated vars directly from the local Gambit helper. */
exec function GambitBuffs()
{
    local KFPawn_Human KFPH;
    local ZTUpgrade_Perk_Gambit_Helper H;

    // If already showing, dismiss early
    if (bShowGambitBuffs)
    {
        bShowGambitBuffs = false;
        return;
    }

    // Find local pawn's Gambit helper
    KFPH = KFPawn_Human(PlayerOwner.Pawn);
    if (KFPH == None)
    {
        LocalPlayer(PlayerOwner.Player).ViewportClient.ViewportConsole.OutputText("GambitBuffs: No active pawn");
        return;
    }

    H = None;
    foreach KFPH.ChildActors(class'ZTUpgrade_Perk_Gambit_Helper', H)
    {
        break;
    }

    if (H == None)
    {
        LocalPlayer(PlayerOwner.Player).ViewportClient.ViewportConsole.OutputText("GambitBuffs: Gambit perk not active");
        return;
    }

    // Snapshot replicated values
    GambitBuffData.Completions = H.TotalCompletions;
    GambitBuffData.Dosh = H.AccumulatedDosh;
    GambitBuffData.Damage = H.AccumulatedDamage;
    GambitBuffData.Speed = H.AccumulatedSpeed;
    GambitBuffData.Reload = H.AccumulatedReload;
    GambitBuffData.Recoil = H.AccumulatedRecoil;
    GambitBuffData.MagSize = H.AccumulatedMagSize;
    GambitBuffData.SpareAmmo = H.AccumulatedSpareAmmo;

    bShowGambitBuffs = true;
    GambitBuffsShowTime = WorldInfo.TimeSeconds;
}

/** Format a float bonus as a percentage string, e.g. 0.125 -> "12.5%" */
function string FormatBuffPercent(float Value)
{
    local int Whole, Frac;

    Whole = int(Value * 100.0f);
    Frac = int(Value * 1000.0f) % 10;

    if (Frac > 0)
        return string(Whole) $ "." $ string(Frac) $ "%";
    else
        return string(Whole) $ "%";
}

/** Draw the Gambit buffs overlay - top-left, compact, auto-sizing. */
function DrawGambitBuffsOverlay()
{
    local float BoxX, BoxY, BoxW, BoxH;
    local float PadX, PadY, LineH, CurY;
    local float TxtScale, HeaderScale;
    local Color BGColor, BorderColor, HeaderColor, LabelColor, ValueColor, EmptyColor;
    local int LineCount;
    local float Elapsed, Alpha;

    if (Canvas == None || !bShowGambitBuffs)
        return;

    // Auto-hide after duration
    Elapsed = WorldInfo.TimeSeconds - GambitBuffsShowTime;
    if (Elapsed > GambitBuffsDuration)
    {
        bShowGambitBuffs = false;
        return;
    }

    // Fade out in last 1.0 second
    if (Elapsed > GambitBuffsDuration - 1.0f)
        Alpha = (GambitBuffsDuration - Elapsed) * 255.0f;
    else
        Alpha = 255.0f;

    Alpha = FClamp(Alpha, 0.0f, 255.0f);

    // Layout (scaled from 720p baseline)
    PadX = 10.0f * ResScale;
    PadY = 6.0f * ResScale;
    LineH = 18.0f * ResScale;
    TxtScale = 0.85f * ResScale;
    HeaderScale = 1.0f * ResScale;

    // Colors
    BGColor = MakeColorFromRGB(15, 15, 20, int(Alpha * 0.85f));
    BorderColor = MakeColorFromRGB(255, 200, 50, int(Alpha));        // Gold border
    HeaderColor = MakeColorFromRGB(255, 200, 50, int(Alpha));        // Gold header
    LabelColor = MakeColorFromRGB(180, 180, 180, int(Alpha));        // Grey labels
    ValueColor = MakeColorFromRGB(220, 255, 220, int(Alpha));        // Light green values
    EmptyColor = MakeColorFromRGB(140, 140, 140, int(Alpha));        // Dim grey for empty

    // Count active buff lines
    LineCount = 0;
    if (GambitBuffData.Damage > 0.0f) LineCount++;
    if (GambitBuffData.Speed > 0.0f) LineCount++;
    if (GambitBuffData.Reload > 0.0f) LineCount++;
    if (GambitBuffData.Recoil > 0.0f) LineCount++;
    if (GambitBuffData.MagSize > 0.0f) LineCount++;
    if (GambitBuffData.SpareAmmo > 0.0f) LineCount++;
    if (GambitBuffData.Dosh > 0) LineCount++;

    // Box dimensions
    BoxW = 200.0f * ResScale;
    BoxX = Canvas.SizeX * 0.02f;
    BoxY = Canvas.SizeY * 0.15f;

    // Height: header + completions line + buff lines (or empty message) + padding
    if (LineCount > 0)
        BoxH = PadY * 2.0f + LineH + LineH + (float(LineCount) * LineH);
    else
        BoxH = PadY * 2.0f + LineH + LineH + LineH; // header + completions + "no buffs"

    // --- Draw background ---
    Canvas.SetDrawColor(BGColor.R, BGColor.G, BGColor.B, BGColor.A);
    Canvas.SetPos(BoxX, BoxY);
    Canvas.DrawRect(BoxW, BoxH);

    // --- Draw border (scaled) ---
    Canvas.SetDrawColor(BorderColor.R, BorderColor.G, BorderColor.B, BorderColor.A);
    Canvas.SetPos(BoxX, BoxY);
    Canvas.DrawRect(BoxW, 2.0f * ResScale);
    Canvas.SetPos(BoxX, BoxY + BoxH - 2.0f * ResScale);
    Canvas.DrawRect(BoxW, 2.0f * ResScale);
    Canvas.SetPos(BoxX, BoxY);
    Canvas.DrawRect(2.0f * ResScale, BoxH);
    Canvas.SetPos(BoxX + BoxW - 2.0f * ResScale, BoxY);
    Canvas.DrawRect(2.0f * ResScale, BoxH);

    CurY = BoxY + PadY;

    // --- Header ---
    Canvas.SetDrawColor(HeaderColor.R, HeaderColor.G, HeaderColor.B, HeaderColor.A);
    Canvas.SetPos(BoxX + PadX, CurY);
    Canvas.DrawText(GambitBuffs_Header, true, HeaderScale, HeaderScale);
    CurY += LineH;

    // --- Completions ---
    Canvas.SetDrawColor(LabelColor.R, LabelColor.G, LabelColor.B, LabelColor.A);
    Canvas.SetPos(BoxX + PadX, CurY);
    Canvas.DrawText(GambitBuffs_CompletionsLabel @ string(GambitBuffData.Completions), true, TxtScale, TxtScale);
    CurY += LineH;

    // --- Buff lines (only show non-zero) ---
    if (LineCount == 0)
    {
        Canvas.SetDrawColor(EmptyColor.R, EmptyColor.G, EmptyColor.B, EmptyColor.A);
        Canvas.SetPos(BoxX + PadX, CurY);
        Canvas.DrawText(GambitBuffs_NoBuffs, true, TxtScale, TxtScale);
    }
    else
    {
        if (GambitBuffData.Damage > 0.0f)
        {
            DrawBuffLine(BoxX + PadX, CurY, GambitBuffs_Damage, "+" $ FormatBuffPercent(GambitBuffData.Damage), LabelColor, ValueColor, TxtScale);
            CurY += LineH;
        }
        if (GambitBuffData.Speed > 0.0f)
        {
            DrawBuffLine(BoxX + PadX, CurY, GambitBuffs_Speed, "+" $ FormatBuffPercent(GambitBuffData.Speed), LabelColor, ValueColor, TxtScale);
            CurY += LineH;
        }
        if (GambitBuffData.Reload > 0.0f)
        {
            DrawBuffLine(BoxX + PadX, CurY, GambitBuffs_Reload, "+" $ FormatBuffPercent(GambitBuffData.Reload), LabelColor, ValueColor, TxtScale);
            CurY += LineH;
        }
        if (GambitBuffData.Recoil > 0.0f)
        {
            DrawBuffLine(BoxX + PadX, CurY, GambitBuffs_Recoil, "+" $ FormatBuffPercent(GambitBuffData.Recoil), LabelColor, ValueColor, TxtScale);
            CurY += LineH;
        }
        if (GambitBuffData.MagSize > 0.0f)
        {
            DrawBuffLine(BoxX + PadX, CurY, GambitBuffs_MagSize, "+" $ FormatBuffPercent(GambitBuffData.MagSize), LabelColor, ValueColor, TxtScale);
            CurY += LineH;
        }
        if (GambitBuffData.SpareAmmo > 0.0f)
        {
            DrawBuffLine(BoxX + PadX, CurY, GambitBuffs_SpareAmmo, "+" $ FormatBuffPercent(GambitBuffData.SpareAmmo), LabelColor, ValueColor, TxtScale);
            CurY += LineH;
        }
        if (GambitBuffData.Dosh > 0)
        {
            DrawBuffLine(BoxX + PadX, CurY, GambitBuffs_DoshEarned, "+" $ string(GambitBuffData.Dosh), LabelColor, ValueColor, TxtScale);
            CurY += LineH;
        }
    }
}

// ===================================================================
// ARTIFICER FORGE DISPLAY FUNCTIONS
// ===================================================================

/** Initialize Artificer display to inactive state. */
function InitializeArtificerDisplay()
{
    ArtificerDisplay.bIsActive = false;
    ArtificerDisplay.DisplayMode = 0;
    ArtificerDisplay.Phase = 0;
    ArtificerDisplay.WeaponName = "";
    ArtificerDisplay.KillCount = 0;
    ArtificerDisplay.KillTarget = 100;
    ArtificerDisplay.MilestoneNum = 0;
    ArtificerDisplay.RollsString = "";
    ArtificerDisplay.NotifyTimer = 0.0f;
}

/** Update Artificer progress display (Mode 0 - persistent kill tracking).
 *  Phase 0 = Tracking toward Reforge unlock (orange accent)
 *  Phase 1 = Tracking toward Mastery milestone (gold accent) */
function UpdateArtificerProgress(byte InPhase, string InWeaponName, int InKillCount, int InKillTarget, int InMilestoneNum)
{
    // Always update underlying data so it's current when notifications expire
    ArtificerDisplay.bIsActive = true;
    ArtificerDisplay.Phase = InPhase;
    ArtificerDisplay.WeaponName = InWeaponName;
    ArtificerDisplay.KillCount = InKillCount;
    ArtificerDisplay.KillTarget = InKillTarget;
    ArtificerDisplay.MilestoneNum = InMilestoneNum;

    // Only switch to progress display mode if no notification is active
    if (ArtificerDisplay.DisplayMode > 0 && ArtificerDisplay.NotifyTimer > 0.0f)
        return;

    ArtificerDisplay.DisplayMode = 0;
    ArtificerDisplay.NotifyTimer = 0.0f;
}

/** Show reforge unlock notification (Mode 1 - 3 second popup). */
function ShowArtificerReforgeUnlock(string InWeaponName)
{
    ArtificerDisplay.bIsActive = true;
    ArtificerDisplay.DisplayMode = 1;
    ArtificerDisplay.Phase = 1;  // Weapon is now reforged -> gold phase
    ArtificerDisplay.WeaponName = InWeaponName;
    ArtificerDisplay.NotifyTimer = 5.0f;
}

/** Show mastery milestone completion (Mode 2 - 5 second popup). */
function ShowArtificerMasteryComplete(string InWeaponName, int InMilestoneNum, string InRollsString)
{
    ArtificerDisplay.bIsActive = true;
    ArtificerDisplay.DisplayMode = 2;
    ArtificerDisplay.WeaponName = InWeaponName;
    ArtificerDisplay.MilestoneNum = InMilestoneNum;
    ArtificerDisplay.RollsString = InRollsString;
    ArtificerDisplay.NotifyTimer = 8.0f;
}

/** Clear the Artificer display (e.g. on death / perk removed). */
function ClearArtificerDisplay()
{
    ArtificerDisplay.bIsActive = false;
}

/** Map display mode + phase to its 128x128 icon texture.
 *  Mode 0 (Progress): Phase determines icon (forge vs mastery)
 *  Mode 1 (Reforge Unlock): Anvil icon
 *  Mode 2 (Mastery Complete): Mastery star icon */
function Texture2D GetArtificerIcon(byte Mode)
{
    switch (Mode)
    {
        case 0:
            // Progress mode: icon depends on phase
            if (ArtificerDisplay.Phase == 0)
                return Texture2D'ZedternalRBPerkpackage_Resources.Buffs.UI_Artificer_Forge';
            else
                return Texture2D'ZedternalRBPerkpackage_Resources.Buffs.UI_Artificer_Complete';
        case 1:  return Texture2D'ZedternalRBPerkpackage_Resources.Buffs.UI_Artificer_Anvil';
        case 2:  return Texture2D'ZedternalRBPerkpackage_Resources.Buffs.UI_Artificer_Complete';
        default: return Texture2D'ZedternalRBPerkpackage_Resources.Buffs.UI_Artificer_Forge';
    }
}

/** Get the border color for the current Artificer display mode + phase.
 *  Mode 0: Phase 0 = orange (forging), Phase 1 = gold (mastery tracking)
 *  Mode 1: Gold flash (reforge unlock notification)
 *  Mode 2: Purple flash (mastery milestone notification) */
function Color GetArtificerModeColor(byte Mode)
{
    switch (Mode)
    {
        case 0:
            // Progress mode: phase determines accent color
            if (ArtificerDisplay.Phase == 0)
                return MakeColorFromRGB(220, 140, 40, 200);   // Forge orange
            else
                return MakeColorFromRGB(255, 215, 0, 200);    // Mastery gold
        case 1:  return MakeColorFromRGB(255, 200, 50, 255);   // Reforge gold
        case 2:  return MakeColorFromRGB(180, 80, 255, 255);   // Mastery purple
        default: return MakeColorFromRGB(220, 140, 40, 200);
    }
}

/** Convert a normalized weapon name (e.g. "Rifle_MosinNagant") into a clean
 *  uppercase display name (e.g. "MOSIN NAGANT").
 *  Strips category prefixes, splits CamelCase, preserves HRG prefix. */
static function string GetCleanWeaponName(string NormName)
{
    local string Result, Ch, PrevCh, NextCh;
    local int i, NameLen, UnderscorePos, ChCode, PrevCode, NextCode;

    // Step 1: Strip category prefix (Rifle_, AssaultRifle_, Shotgun_, etc.)
    // Keep "HRG" since it is part of the weapon identity
    UnderscorePos = InStr(NormName, "_");
    if (UnderscorePos != INDEX_NONE)
    {
        if (Left(NormName, 4) ~= "HRG_")
            NormName = "HRG " $ Mid(NormName, 4);
        else
            NormName = Mid(NormName, UnderscorePos + 1);
    }

    // Step 2: CamelCase split, replace remaining underscores with spaces
    Result = "";
    NameLen = Len(NormName);

    for (i = 0; i < NameLen; i++)
    {
        Ch = Mid(NormName, i, 1);

        if (Ch == "_")
        {
            Result = Result $ " ";
            continue;
        }

        if (i > 0)
        {
            PrevCh = Mid(NormName, i - 1, 1);
            if (PrevCh != "_" && PrevCh != " ")
            {
                ChCode = Asc(Ch);
                PrevCode = Asc(PrevCh);

                // Uppercase after lowercase: "MosinNagant" -> "Mosin Nagant"
                if (ChCode >= 65 && ChCode <= 90 && PrevCode >= 97 && PrevCode <= 122)
                    Result = Result $ " ";
                // Digit after letter: "Colt1911" -> "Colt 1911"
                else if (ChCode >= 48 && ChCode <= 57
                    && ((PrevCode >= 65 && PrevCode <= 90) || (PrevCode >= 97 && PrevCode <= 122)))
                    Result = Result $ " ";
                // Letter after digit: "5RAS" -> "5 RAS"
                else if (((ChCode >= 65 && ChCode <= 90) || (ChCode >= 97 && ChCode <= 122))
                    && PrevCode >= 48 && PrevCode <= 57)
                    Result = Result $ " ";
                // Uppercase between uppercase and lowercase: "HRGTeslauncher" -> "HRG Teslauncher"
                else if (ChCode >= 65 && ChCode <= 90
                    && PrevCode >= 65 && PrevCode <= 90
                    && i + 1 < NameLen)
                {
                    NextCh = Mid(NormName, i + 1, 1);
                    NextCode = Asc(NextCh);
                    if (NextCode >= 97 && NextCode <= 122)
                        Result = Result $ " ";
                }
            }
        }

        Result = Result $ Ch;
    }

    return Caps(Result);
}

/** Main Artificer HUD draw - forge card with progress/notification modes.
 *  Uses DisplayCardStack system for Y positioning.
 *
 *  Mode 0 (Progress):   Forge icon + weapon name + kills + bar + milestone
 *  Mode 1 (Reforge):    Anvil icon + "REFORGED!" + weapon name + availability (3s)
 *  Mode 2 (Mastery):    Star icon + milestone title + weapon name + stat rolls (5s) */
function DrawArtificerDisplay()
{
    local float BoxX, BoxY, BoxW, BoxH;
    local float PadX, PadY, LineH, SmallLineH;
    local float BarX, BarW, BarH, BarFill;
    local float CurY, TextX;
    local float IconSz, IconPad;
    local Color BorderColor, TitleColor, TextColor, HighlightColor;
    local Texture2D ArtIcon;
    local byte Mode;
    local float NotifyAlpha;

    if (Canvas == None)
        return;

    Mode = ArtificerDisplay.DisplayMode;

    // --- Update notification timer ---
    if (Mode > 0 && ArtificerDisplay.NotifyTimer > 0.0f)
    {
        ArtificerDisplay.NotifyTimer -= RenderDelta;
        if (ArtificerDisplay.NotifyTimer <= 0.0f)
        {
            // Timer expired - revert to progress mode or hide
            if (ArtificerDisplay.KillCount > 0)
            {
                ArtificerDisplay.DisplayMode = 0;
                Mode = 0;
            }
            else
            {
                ArtificerDisplay.bIsActive = false;
                return;
            }
        }
    }

    // --- Layout constants (compact sizing, scaled from 720p baseline) ---
    PadX = 8.0f * ResScale;
    PadY = 6.0f * ResScale;
    LineH = 18.0f * ResScale;
    SmallLineH = 14.0f * ResScale;
    IconSz = 48.0f * ResScale;
    IconPad = 8.0f * ResScale;
    BoxW = 280.0f * ResScale;

    // Position from card stacking system
    BoxX = Canvas.SizeX * DisplayCardBaseX;
    BoxY = Canvas.SizeY * GetDisplayCardY(CARD_ARTIFICER);

    // --- Colors ---
    BorderColor = GetArtificerModeColor(Mode);
    TitleColor = MakeColorFromRGB(255, 180, 40, 255);
    TextColor = MakeColorFromRGB(220, 220, 220, 255);
    HighlightColor = MakeColorFromRGB(255, 220, 80, 255);

    // Text starts after icon column
    TextX = BoxX + PadX + IconSz + IconPad;

    Canvas.Font = class'KFGameEngine'.Static.GetKFCanvasFont();

    // --- Compute dynamic box height ---
    BoxH = PadY * 2.0f;

    switch (Mode)
    {
        case 0: // Progress
            BoxH += LineH;              // Weapon name
            BoxH += SmallLineH;         // Kill count text
            BoxH += PadY;              // Gap
            BoxH += 6.0f * ResScale;  // Progress bar
            BoxH += 4.0f * ResScale;  // Gap
            BoxH += SmallLineH;         // Milestone text
            break;

        case 1: // Reforge Unlock
            BoxH += LineH;              // "REFORGED!"
            BoxH += SmallLineH;         // Weapon name
            BoxH += SmallLineH;         // "Now available in Trader!"
            break;

        case 2: // Mastery Complete (dynamic height based on stat line count)
            BoxH += LineH;              // "MASTERY #N"
            BoxH += SmallLineH;         // Weapon name
            BoxH += PadY;              // Gap
            BoxH += float(CountMasteryStatLines(ArtificerDisplay.RollsString)) * SmallLineH;
            break;
    }

    // Ensure box tall enough for icon
    if (BoxH < IconSz + PadY * 2.0f)
        BoxH = IconSz + PadY * 2.0f;

    // --- Fade alpha for notifications in last 0.5s ---
    if (Mode > 0 && ArtificerDisplay.NotifyTimer < 0.5f && ArtificerDisplay.NotifyTimer > 0.0f)
        NotifyAlpha = ArtificerDisplay.NotifyTimer / 0.5f;
    else
        NotifyAlpha = 1.0f;

    // --- Background ---
    Canvas.SetDrawColor(0, 0, 0, int(160.0f * NotifyAlpha));
    Canvas.SetPos(BoxX, BoxY);
    Canvas.DrawRect(BoxW, BoxH);

    // --- Border (2px, scaled) ---
    Canvas.SetDrawColor(BorderColor.R, BorderColor.G, BorderColor.B, int(float(BorderColor.A) * NotifyAlpha));
    Canvas.SetPos(BoxX, BoxY);                                Canvas.DrawRect(BoxW, 2.0f * ResScale);
    Canvas.SetPos(BoxX, BoxY + BoxH - 2.0f * ResScale);      Canvas.DrawRect(BoxW, 2.0f * ResScale);
    Canvas.SetPos(BoxX, BoxY);                                Canvas.DrawRect(2.0f * ResScale, BoxH);
    Canvas.SetPos(BoxX + BoxW - 2.0f * ResScale, BoxY);      Canvas.DrawRect(2.0f * ResScale, BoxH);

    // --- Icon ---
    ArtIcon = GetArtificerIcon(Mode);
    if (ArtIcon != None)
    {
        Canvas.SetDrawColor(255, 255, 255, int(255.0f * NotifyAlpha));
        Canvas.SetPos(BoxX + PadX, BoxY + (BoxH - IconSz) * 0.5f);
        Canvas.DrawTile(ArtIcon, IconSz, IconSz, 0, 0, ArtIcon.SizeX, ArtIcon.SizeY);
    }

    // --- Content by mode ---
    CurY = BoxY + PadY;

    switch (Mode)
    {
        case 0: // PROGRESS MODE
            // Phase-dependent title
            if (ArtificerDisplay.Phase == 0)
                DrawTextWithShadow(Artificer_ForgingPrefix @ GetCleanWeaponName(ArtificerDisplay.WeaponName), TextX, CurY, TitleColor, 0.6f * ResScale);
            else
                DrawTextWithShadow(Artificer_MasteryPrefix @ GetCleanWeaponName(ArtificerDisplay.WeaponName), TextX, CurY, MakeColorFromRGB(255, 215, 0, 255), 0.6f * ResScale);
            CurY += LineH;

            // Kill count
            DrawTextWithShadow(Artificer_KillsPrefix @ ArtificerDisplay.KillCount $ " /" @ ArtificerDisplay.KillTarget,
                TextX, CurY, TextColor, 0.6f * ResScale);
            CurY += SmallLineH + PadY;

            // Progress bar
            BarX = TextX;
            BarW = (BoxX + BoxW - PadX) - TextX;
            BarH = 6.0f * ResScale;
            BarFill = (ArtificerDisplay.KillTarget > 0)
                ? FClamp(float(ArtificerDisplay.KillCount) / float(ArtificerDisplay.KillTarget), 0.0f, 1.0f)
                : 0.0f;

            // Bar background
            Canvas.SetDrawColor(40, 40, 40, 200);
            Canvas.SetPos(BarX, CurY);
            Canvas.DrawRect(BarW, BarH);

            // Bar fill (phase-colored: orange for forge, gold for mastery)
            if (ArtificerDisplay.Phase == 0)
                Canvas.SetDrawColor(220, 140, 40, 200);
            else
                Canvas.SetDrawColor(255, 215, 0, 200);
            Canvas.SetPos(BarX, CurY);
            Canvas.DrawRect(BarW * BarFill, BarH);

            CurY += BarH + 4.0f * ResScale;

            // Milestone count (only in Phase 1)
            if (ArtificerDisplay.Phase == 1 && ArtificerDisplay.MilestoneNum > 0)
                DrawTextWithShadow(Artificer_MilestonePrefix @ ArtificerDisplay.MilestoneNum,
                    TextX, CurY, MakeColorFromRGB(160, 160, 160, 255), 0.6f * ResScale);
            else if (ArtificerDisplay.Phase == 0)
                DrawTextWithShadow(Artificer_UnlockReforged,
                    TextX, CurY, MakeColorFromRGB(160, 160, 160, 255), 0.6f * ResScale);
            break;

        case 1: // REFORGE UNLOCK
            DrawTextWithShadow(Chr(9733) @ Artificer_Reforged, TextX, CurY, HighlightColor, 0.75f * ResScale);
            CurY += LineH;

            DrawTextWithShadow(GetCleanWeaponName(ArtificerDisplay.WeaponName), TextX, CurY, TextColor, 0.6f * ResScale);
            CurY += SmallLineH;

            DrawTextWithShadow(Artificer_NowAvailable, TextX, CurY,
                MakeColorFromRGB(120, 255, 120, 255), 0.6f * ResScale);
            break;

        case 2: // MASTERY COMPLETE - parse structured RollsString and draw per-line
            DrawTextWithShadow(Chr(9733) @ Artificer_MasteryNumPrefix $ ArtificerDisplay.MilestoneNum,
                TextX, CurY, MakeColorFromRGB(180, 80, 255, 255), 0.75f * ResScale);
            CurY += LineH;

            DrawTextWithShadow(GetCleanWeaponName(ArtificerDisplay.WeaponName), TextX, CurY, TextColor, 0.6f * ResScale);
            CurY += SmallLineH + PadY;

            // Draw each stat line from the structured string
            DrawMasteryStatLines(TextX, CurY, SmallLineH, ArtificerDisplay.RollsString);
            break;
    }
}

// ===================================================================
// ARTIFICER MASTERY STAT LINE HELPERS
// Structured RollsString format: "StatIdx:TotalPct:NewPct|StatIdx:TotalPct:NewPct|..."
// Example: "0:10:2|4:10:0|6:2:2"
//   0:10:2 = Damage at 10% total, 2% added this milestone (improved)
//   4:10:0 = Recoil at 10% total, nothing new (existing, shown yellow)
//   6:2:2  = Penetration at 2% total, all new (NEW!, shown green)
// ===================================================================

/** Count the number of stat lines in a structured RollsString.
 *  Each "|" separator means one additional entry. Empty string = 0 lines. */
function int CountMasteryStatLines(string RollsStr)
{
    local int Count, i;

    if (Len(RollsStr) == 0)
        return 0;

    Count = 1;
    for (i = 0; i < Len(RollsStr); ++i)
    {
        if (Mid(RollsStr, i, 1) == "|")
            Count += 1;
    }

    return Count;
}

/** Draw all mastery stat lines from a structured RollsString.
 *  Parses each segment and draws with proper color coding:
 *  - Yellow: existing total (e.g. "Damage +10%")
 *  - Green suffix: increment this milestone (e.g. "(+2%)")
 *  - All green with "(NEW!)": stat that appeared for the first time this milestone */
function DrawMasteryStatLines(float StartX, float StartY, float LineStep, string RollsStr)
{
    local float CurY;
    local string Segment, Rest;
    local int PipePos;
    local int StatIdx, TotalPct, NewPct;
    local string StatName, TotalStr, NewStr;
    local Color MasteryYellow, MasteryGreen;
    local float TotalWidth;
    local float ScaledTxt;

    if (Len(RollsStr) == 0)
        return;

    ScaledTxt = 0.6f * ResScale;
    MasteryYellow = MakeColorFromRGB(255, 220, 80, 255);
    MasteryGreen = MakeColorFromRGB(120, 255, 120, 255);
    CurY = StartY;
    Rest = RollsStr;

    while (Len(Rest) > 0)
    {
        // Extract next segment (up to "|" or end of string)
        PipePos = InStr(Rest, "|");
        if (PipePos != INDEX_NONE)
        {
            Segment = Left(Rest, PipePos);
            Rest = Mid(Rest, PipePos + 1);
        }
        else
        {
            Segment = Rest;
            Rest = "";
        }

        // Parse "StatIdx:TotalPct:NewPct"
        if (!ParseMasterySegment(Segment, StatIdx, TotalPct, NewPct))
            continue;

        StatName = class'ZTUpgrade_Perk_Artificer_Helper'.static.GetMasteryStatName(StatIdx);

        if (NewPct > 0 && NewPct >= TotalPct)
        {
            // Entirely new stat this milestone - all green with (NEW!)
            TotalStr = StatName @ "+" $ string(TotalPct) $ "% (NEW!)";
            DrawTextWithShadow(TotalStr, StartX, CurY, MasteryGreen, ScaledTxt);
        }
        else if (NewPct > 0)
        {
            // Existing stat improved - yellow total, green increment
            TotalStr = StatName @ "+" $ string(TotalPct) $ "%";
            NewStr = " (+" $ string(NewPct) $ "%)";

            // Draw yellow base text
            DrawTextWithShadow(TotalStr, StartX, CurY, MasteryYellow, ScaledTxt);

            // Measure width of base text to position the green suffix
            TotalWidth = GetTextWidth(TotalStr, ScaledTxt);

            // Draw green increment suffix
            DrawTextWithShadow(NewStr, StartX + TotalWidth, CurY, MasteryGreen, ScaledTxt);
        }
        else
        {
            // No change this milestone - yellow only (existing accumulated bonus)
            TotalStr = StatName @ "+" $ string(TotalPct) $ "%";
            DrawTextWithShadow(TotalStr, StartX, CurY, MasteryYellow, ScaledTxt);
        }

        CurY += LineStep;
    }
}

/** Parse a single mastery segment "StatIdx:TotalPct:NewPct" into components.
 *  Returns false if the format is invalid. */
function bool ParseMasterySegment(string Segment, out int OutStatIdx, out int OutTotalPct, out int OutNewPct)
{
    local int Colon1, Colon2;
    local string Part1, Part2, Part3;

    // Find first colon
    Colon1 = InStr(Segment, ":");
    if (Colon1 == INDEX_NONE)
        return false;

    Part1 = Left(Segment, Colon1);

    // Find second colon (search in remainder after first colon)
    Colon2 = InStr(Mid(Segment, Colon1 + 1), ":");
    if (Colon2 == INDEX_NONE)
        return false;
    Colon2 += Colon1 + 1;  // Adjust to absolute position

    Part2 = Mid(Segment, Colon1 + 1, Colon2 - Colon1 - 1);
    Part3 = Mid(Segment, Colon2 + 1);

    OutStatIdx = int(Part1);
    OutTotalPct = int(Part2);
    OutNewPct = int(Part3);

    return true;
}

/** Measure the rendered pixel width of a string at a given scale.
 *  Used to position multi-color text segments on the same line. */
function float GetTextWidth(string Text, float Scale)
{
    local float XL, YL;

    if (Canvas == None)
        return 0.f;

    Canvas.Font = class'KFGameEngine'.Static.GetKFCanvasFont();
    Canvas.TextSize(Text, XL, YL);

    return XL * Scale;
}

/** Draw a single buff line: "Label:  +Value" with two colors. */
function DrawBuffLine(float X, float Y, string Label, string Value, Color LblColor, Color ValColor, float Scale)
{
    local float LabelWidth;
    local float XL, YL;

    // Draw label
    Canvas.SetDrawColor(LblColor.R, LblColor.G, LblColor.B, LblColor.A);
    Canvas.SetPos(X, Y);
    Canvas.DrawText(Label $ ":", true, Scale, Scale);

    // Measure label width to position value
    Canvas.TextSize(Label $ ":  ", XL, YL, Scale, Scale);
    LabelWidth = XL;

    // Draw value
    Canvas.SetDrawColor(ValColor.R, ValColor.G, ValColor.B, ValColor.A);
    Canvas.SetPos(X + LabelWidth, Y);
    Canvas.DrawText(Value, true, Scale, Scale);
}

// ===================================================================
// ZED-FORM HUD (transform perk) - Versus-style presentation drawn on Canvas.
// Reads the locally-possessed monster pawn directly (client-side), using the
// same data the stock Versus widgets use: GetLocalizedName(), Health/HealthMax,
// and SpecialMoveCooldowns (icon + localized name + cooldown). No SWF, no RPC -
// the possessed pawn is local to this client. Gated in DrawHUD by
// PlayerOwner.Pawn being a KFPawn_Monster, so it covers the puppet spike now
// and the production transform perk later, for both Endless game modes.
// ===================================================================
// ===================================================================
// Possession HUD (top-right) - shown only while driving a puppet zed via the
// Possessor perk. Brings two survivor-HUD readouts into the zed view that the
// Scaleform HUD hides while transformed:
//   - ZEDS LEFT: the wave's remaining zed count (KFGRI.AIRemaining, the same
//     value the stock wave widget shows).
//   - a possession timer bar draining over the remaining possession time,
//     with a live seconds countdown (mirrors the possession card's bar).
// Called from PostRender's zed-form branch, so it only appears while possessed
// and is independent of DrawZedFormHUD's ability-tray early-return.
// ===================================================================
function DrawPossessionInfo()
{
    local KFGameReplicationInfo GRI;
    local float PanelX, PanelY, PanelW, PanelH, PadX, PadY;
    local float CurY, BarX, BarY, BarW, BarH, Frac, Remaining;
    local float TW, TH;
    local int ZedsLeft, WholeSecs, TenthSecs;
    local string ZedsStr, TimerStr;
    local Color Violet, PanelBg, CountCol;

    if (Canvas == None || PlayerOwner == None)
        return;

    // Only while actually possessing via the perk. The debug PuppetGrab path
    // never pushes a POSSESSING HUD state, so this stays hidden for it.
    if (!PossessorDisplay.bIsActive || PossessorDisplay.State != 1)
        return;

    // DrawHUD (which calls ComputeResScale) is skipped while transformed, but
    // ResScale keeps its last value; recompute only if it was never set.
    if (ResScale <= 0.0f)
        ComputeResScale();

    GRI = KFGRI;
    if (GRI == None)
        GRI = KFGameReplicationInfo(WorldInfo.GRI);

    Violet   = MakeColorFromRGB(180, 90, 230, 255);   // possession accent
    PanelBg  = MakeColorFromRGB(0, 0, 0, 160);
    CountCol = MakeColorFromRGB(255, 235, 120, 255);  // amber zed count

    PadX = 10.0f * ResScale;
    PadY = 8.0f * ResScale;
    PanelW = 240.0f * ResScale;
    PanelH = 84.0f * ResScale;
    PanelX = Canvas.SizeX * 0.985f - PanelW;
    PanelY = Canvas.SizeY * 0.045f;

    Canvas.Font = class'KFGameEngine'.Static.GetKFCanvasFont();

    // Background + violet border (matches the possession card styling).
    Canvas.SetDrawColor(PanelBg.R, PanelBg.G, PanelBg.B, PanelBg.A);
    Canvas.SetPos(PanelX, PanelY);
    Canvas.DrawRect(PanelW, PanelH);

    Canvas.SetDrawColor(Violet.R, Violet.G, Violet.B, 200);
    Canvas.SetPos(PanelX, PanelY);                              Canvas.DrawRect(PanelW, 2.0f * ResScale);
    Canvas.SetPos(PanelX, PanelY + PanelH - 2.0f * ResScale);   Canvas.DrawRect(PanelW, 2.0f * ResScale);
    Canvas.SetPos(PanelX, PanelY);                              Canvas.DrawRect(2.0f * ResScale, PanelH);
    Canvas.SetPos(PanelX + PanelW - 2.0f * ResScale, PanelY);   Canvas.DrawRect(2.0f * ResScale, PanelH);

    CurY = PanelY + PadY;

    // Line 1: zeds remaining in the wave.
    ZedsLeft = 0;
    if (GRI != None)
        ZedsLeft = Max(GRI.AIRemaining, 0);
    ZedsStr = "ZEDS LEFT:" @ string(ZedsLeft);
    DrawTextWithShadow(ZedsStr, PanelX + PadX, CurY, CountCol, 0.75f * ResScale);
    Canvas.TextSize(ZedsStr, TW, TH, 0.75f * ResScale, 0.75f * ResScale);
    CurY += TH + (6.0f * ResScale);

    // Line 2: possession label + live countdown.
    Remaining = FMax(PossessorDisplay.EndTime - WorldInfo.TimeSeconds, 0.0f);
    WholeSecs = int(Remaining);
    TenthSecs = int(Remaining * 10.0f) % 10;
    TimerStr = "POSSESSION - " $ WholeSecs $ "." $ TenthSecs $ "s";
    DrawTextWithShadow(TimerStr, PanelX + PadX, CurY, Violet, 0.55f * ResScale);
    Canvas.TextSize(TimerStr, TW, TH, 0.55f * ResScale, 0.55f * ResScale);
    CurY += TH + (4.0f * ResScale);

    // Line 3: the possession timer bar (drains full -> empty).
    Frac = 0.0f;
    if (PossessorDisplay.Duration > 0.0f)
        Frac = FClamp(Remaining / PossessorDisplay.Duration, 0.0f, 1.0f);

    BarX = PanelX + PadX;
    BarY = CurY;
    BarW = PanelW - (2.0f * PadX);
    BarH = 14.0f * ResScale;

    Canvas.SetDrawColor(40, 40, 40, 200);
    Canvas.SetPos(BarX, BarY);
    Canvas.DrawRect(BarW, BarH);

    Canvas.SetDrawColor(Violet.R, Violet.G, Violet.B, 220);
    Canvas.SetPos(BarX, BarY);
    Canvas.DrawRect(BarW * Frac, BarH);
}

function DrawZedFormHUD()
{
    local KFPawn_Monster ZedPawn;
    local int i, NumShown;
    local float IconSz, Gap, CellW, TrayX, CellX;
    local float NameY, BindY, IconY, CdFrac, CdH, TxScale, TW, TH;
    local float BarX, BarY, BarW, BarH, HpFrac, NameScale, NW, NH;
    local string ZedName, MoveName, LocName, BindLabel;
    local Texture2D Icon;
    local Color White, NameCol, HpCol, BarBg;

    if (Canvas == None || PlayerOwner == None)
        return;

    ZedPawn = KFPawn_Monster(PlayerOwner.Pawn);
    if (ZedPawn == None)
        return;

    Canvas.Font = class'KFGameEngine'.Static.GetKFCanvasFont();
    // Use the HUD's shared resolution scale (class member). DrawHUD - which calls
    // ComputeResScale - is skipped while transformed, but ResScale retains its
    // last value; recompute only if it was somehow never set.
    if (ResScale <= 0.0f)
        ComputeResScale();

    White   = MakeColorFromRGB(255, 255, 255, 255);
    NameCol = MakeColorFromRGB(240, 240, 240, 255);
    HpCol   = MakeColorFromRGB(200, 45, 45, 255);
    BarBg   = MakeColorFromRGB(15, 15, 15, 205);

    // ---- Bottom-left: zed name + health bar (name sits ABOVE the bar) ----
    ZedName = ZedPawn.GetLocalizedName();
    NameScale = 0.9f * ResScale;
    BarW = 230.0f * ResScale;
    BarH = 9.0f * ResScale;
    BarX = Canvas.SizeX * 0.035f;
    BarY = Canvas.SizeY * 0.95f - BarH;

    Canvas.TextSize(ZedName, NW, NH, NameScale, NameScale);
    DrawTextWithShadow(ZedName, BarX, BarY - NH - (6.0f * ResScale), NameCol, NameScale);

    HpFrac = 0.0f;
    if (ZedPawn.HealthMax > 0)
        HpFrac = FClamp(float(ZedPawn.Health) / float(ZedPawn.HealthMax), 0.0f, 1.0f);

    Canvas.SetDrawColor(BarBg.R, BarBg.G, BarBg.B, BarBg.A);
    Canvas.SetPos(BarX, BarY);
    Canvas.DrawRect(BarW, BarH);

    Canvas.SetDrawColor(HpCol.R, HpCol.G, HpCol.B, 255);
    Canvas.SetPos(BarX, BarY);
    Canvas.DrawRect(BarW * HpFrac, BarH);

    Canvas.SetDrawColor(0, 0, 0, 220);
    Canvas.SetPos(BarX, BarY);                Canvas.DrawRect(BarW, 2.0f);
    Canvas.SetPos(BarX, BarY + BarH - 2.0f);  Canvas.DrawRect(BarW, 2.0f);
    Canvas.SetPos(BarX, BarY);                Canvas.DrawRect(2.0f, BarH);
    Canvas.SetPos(BarX + BarW - 2.0f, BarY);  Canvas.DrawRect(2.0f, BarH);

    // ---- Bottom-right: ability tray ----
    IconSz = 56.0f * ResScale;
    Gap = 14.0f * ResScale;
    CellW = IconSz + Gap;
    TxScale = 0.72f * ResScale;

    NumShown = 0;
    for (i = 0; i < ZedPawn.SpecialMoveCooldowns.Length; i++)
    {
        if (ZedPawn.SpecialMoveCooldowns[i].SMHandle != SM_None
            && ZedPawn.SpecialMoveCooldowns[i].bShowOnHud
            && ZedPawn.SpecialMoveCooldowns[i].SpecialMoveIcon != None)
            NumShown++;
    }
    if (NumShown == 0)
        return;

    TrayX = Canvas.SizeX * 0.98f - (NumShown * CellW - Gap);
    NameY = Canvas.SizeY * 0.80f;
    IconY = NameY + (26.0f * ResScale);
    BindY = IconY + IconSz + (4.0f * ResScale);

    CellX = TrayX;
    for (i = 0; i < ZedPawn.SpecialMoveCooldowns.Length; i++)
    {
        if (ZedPawn.SpecialMoveCooldowns[i].SMHandle == SM_None
            || !ZedPawn.SpecialMoveCooldowns[i].bShowOnHud
            || ZedPawn.SpecialMoveCooldowns[i].SpecialMoveIcon == None)
            continue;

        Icon = ZedPawn.SpecialMoveCooldowns[i].SpecialMoveIcon;

        // icon backing plate
        Canvas.SetDrawColor(0, 0, 0, 180);
        Canvas.SetPos(CellX - 4.0f * ResScale, IconY - 4.0f * ResScale);
        Canvas.DrawRect(IconSz + 8.0f * ResScale, IconSz + 8.0f * ResScale);

        // icon
        Canvas.SetDrawColor(255, 255, 255, 255);
        Canvas.SetPos(CellX, IconY);
        Canvas.DrawTile(Icon, IconSz, IconSz, 0, 0, Icon.SizeX, Icon.SizeY);

        // cooldown: dark fill rising from the bottom for the not-ready fraction.
        // Computed inline (mirrors GetSpecialMoveCooldownPercent) because UScript
        // forbids passing a dynamic-array element to that function's out param.
        CdFrac = 0.0f;
        if (ZedPawn.SpecialMoveCooldowns[i].LastUsedTime > 0.0f
            && ZedPawn.SpecialMoveCooldowns[i].CooldownTime > 0.0f)
        {
            CdFrac = 1.0f - FClamp(
                (WorldInfo.TimeSeconds - ZedPawn.SpecialMoveCooldowns[i].LastUsedTime)
                    / ZedPawn.SpecialMoveCooldowns[i].CooldownTime, 0.0f, 1.0f);
        }
        if (CdFrac > 0.01f)
        {
            CdH = IconSz * CdFrac;
            Canvas.SetDrawColor(0, 0, 0, 150);
            Canvas.SetPos(CellX, IconY + IconSz - CdH);
            Canvas.DrawRect(IconSz, CdH);
        }

        // move name (centered above the icon), localized like the stock tray
        MoveName = ZedPawn.SpecialMoveCooldowns[i].NameLocalizationKey;
        if (MoveName != "")
        {
            LocName = Localize("ZedMoves", MoveName, "KFGame");
            if (InStr(LocName, "?") == INDEX_NONE)
                MoveName = LocName;
        }
        Canvas.TextSize(MoveName, TW, TH, TxScale, TxScale);
        DrawTextWithShadow(MoveName, CellX + (IconSz - TW) * 0.5f, NameY, NameCol, TxScale);

        // bind label (centered below the icon). The SM_PlayerZedMove_* handle name
        // IS the default key - e.g. Patriarch: Melee=LMB Minigun=RMB Grab=V Rocket=MMB
        // Heal=Q Mortar=G - so map all six player-zed keys. Taunt/jump/cloak stay blank.
        switch (ZedPawn.SpecialMoveCooldowns[i].SMHandle)
        {
        case SM_PlayerZedMove_LMB: BindLabel = "LMB"; break;
        case SM_PlayerZedMove_RMB: BindLabel = "RMB"; break;
        case SM_PlayerZedMove_MMB: BindLabel = "MMB"; break;
        case SM_PlayerZedMove_V:   BindLabel = "V";   break;
        case SM_PlayerZedMove_Q:   BindLabel = "Q";   break;
        case SM_PlayerZedMove_G:   BindLabel = "G";   break;
        default:                   BindLabel = "";    break;
        }
        Canvas.TextSize(BindLabel, TW, TH, TxScale, TxScale);
        DrawTextWithShadow(BindLabel, CellX + (IconSz - TW) * 0.5f, BindY, White, TxScale);

        CellX += CellW;
    }
}

function DrawTextWithShadow(string Text, float X, float Y, Color TextColor, float Scale)
{
    local float Sh;
    Sh = FMax(1.0f, 2.0f * ResScale);

    // Double shadow for better readability
    Canvas.SetDrawColor(0, 0, 0, 220);
    Canvas.SetPos(X + Sh, Y + Sh);
    Canvas.DrawText(Text, false, Scale, Scale);
    Canvas.SetDrawColor(0, 0, 0, 120);
    Canvas.SetPos(X + Sh * 0.5f, Y + Sh * 0.5f);
    Canvas.DrawText(Text, false, Scale, Scale);
    
    Canvas.SetDrawColor(TextColor.R, TextColor.G, TextColor.B, TextColor.A);
    Canvas.SetPos(X, Y);
    Canvas.DrawText(Text, false, Scale, Scale);
}

function DrawPanelBackground(float X, float Y, float Width, float Height)
{
    local float B;
    B = FMax(1.0f, 2.0f * ResScale);

    Canvas.SetDrawColor(10, 25, 10, 200);
    Canvas.SetPos(X, Y);
    Canvas.DrawRect(Width, Height);
    
    Canvas.SetDrawColor(0, 255, 127, 150);
    Canvas.SetPos(X, Y);
    Canvas.DrawRect(Width, B);
    Canvas.SetPos(X, Y + Height - B);
    Canvas.DrawRect(Width, B);
    Canvas.SetPos(X, Y);
    Canvas.DrawRect(B, Height);
    Canvas.SetPos(X + Width - B, Y);
    Canvas.DrawRect(B, Height);
}

// ===================================================================
// DEV STAT OVERLAY - Real-time weapon + player stat display
// Toggled via console command: StatOverlay
// ===================================================================

simulated function DrawStatOverlay()
{
    local KFPlayerController KFPC;
    local WMPerk WMP;
    local KFWeapon KFW;
    local KFPawn_Human KFPH;
    local float PanelX, PanelY, PanelW, LineH, CurY, Pad;
    local float DefaultRate, ModifiedRate;
    local float DefaultRecoil, ModifiedRecoil;
    local float DefaultSpread, ModifiedSpread;
    local float ReloadScale;
    local float DefaultMelee, ModifiedMelee;
    local int DefaultMag, ActualMag;
    local int DefaultSpare, ActualSpare;
    local float MoveSpeed;
    local float DefaultSwitch, ModifiedSwitch;
    local float ZedTimeMod;
    local WMPawn_Human WMPH;
    local ZTUpgrade_Perk_Shapeshifter_Helper SSHelper;
    local int SSLevel;
    local Color HeaderColor, LabelColor, ValueColor, GoodColor, BadColor, NeutralColor;
    local Color ActiveColor, InactiveColor;
    local string WeaponName;
    local string PctStr;
    local float Pct;
    local string BuffStatusStr;
    local WMPlayerReplicationInfo WMPRI;
    local WMGameReplicationInfo WMGRI;
    local float PassiveDmgFactor;
    local int TestDamage, DefaultTestDamage;
    local int di, dindex;
    local float BeforeVal, SrcPct;
    local float TrackedVal;
    local int BeforeInt;
    local int TrackedInt;
    local string SrcName;
    local Color SrcColor;
    local ZTPlayerReplicationInfo DKPRI;
    local int si, sindex;

    // Locally recomputed passives (WMPerk's are private)
    local float LocalPassiveRateOfFire;
    local float LocalPassiveRecoil;
    local float LocalPassiveSpread;
    local float LocalPassiveReloadRate;
    local float LocalPassiveMeleeSpeed;
    local float LocalPassiveSwitchSpeed;
    local float LocalPassiveMagCapacity;
    local float LocalPassiveSpareAmmo;
    local float LocalPassiveMoveSpeed;

    if (Canvas == None)
        return;

    KFPC = KFPlayerController(GetALocalPlayerController());
    if (KFPC == None || KFPC.Pawn == None)
        return;

    KFPH = KFPawn_Human(KFPC.Pawn);
    WMP = WMPerk(KFPC.CurrentPerk);
    if (KFPH == None || WMP == None)
        return;

    KFW = KFWeapon(KFPH.Weapon);

    // Early assignment for source tracing (used throughout function in sources mode)
    WMPRI = WMPlayerReplicationInfo(KFPC.PlayerReplicationInfo);
    WMGRI = WMGameReplicationInfo(KFPC.WorldInfo.GRI);
    if (StatOverlayMode == 2)
    {
        DKPRI = ZTPlayerReplicationInfo(KFPC.PlayerReplicationInfo);
        SrcColor = MakeColorFromRGB(140, 180, 220, 220);

        // Recompute passive bonuses locally (WMPerk caches them as private)
        // Mirrors WMPerk.ComputePassiveBonuses() logic: all start at 1.0
        LocalPassiveRateOfFire = 1.0f;
        LocalPassiveRecoil = 1.0f;
        LocalPassiveSpread = 1.0f;
        LocalPassiveReloadRate = 1.0f;
        LocalPassiveMeleeSpeed = 1.0f;
        LocalPassiveSwitchSpeed = 1.0f;
        LocalPassiveMagCapacity = 1.0f;
        LocalPassiveSpareAmmo = 1.0f;
        LocalPassiveMoveSpeed = 1.0f;
        if (WMPRI != None && WMGRI != None)
        {
            for (si = 0; si < WMPRI.Purchase_PerkUpgrade.Length; ++si)
            {
                sindex = WMPRI.Purchase_PerkUpgrade[si];
                WMGRI.PerkUpgradesList[sindex].PerkUpgrade.static.ModifyRateOfFirePassive(LocalPassiveRateOfFire, WMPRI.bPerkUpgrade[sindex].level);
                WMGRI.PerkUpgradesList[sindex].PerkUpgrade.static.ModifyRecoilPassive(LocalPassiveRecoil, WMPRI.bPerkUpgrade[sindex].level);
                WMGRI.PerkUpgradesList[sindex].PerkUpgrade.static.ModifySpreadPassive(LocalPassiveSpread, WMPRI.bPerkUpgrade[sindex].level);
                WMGRI.PerkUpgradesList[sindex].PerkUpgrade.static.GetReloadRateScalePassive(LocalPassiveReloadRate, WMPRI.bPerkUpgrade[sindex].level);
                WMGRI.PerkUpgradesList[sindex].PerkUpgrade.static.ModifyMeleeAttackSpeedPassive(LocalPassiveMeleeSpeed, WMPRI.bPerkUpgrade[sindex].level);
                WMGRI.PerkUpgradesList[sindex].PerkUpgrade.static.ModifyWeaponSwitchTimePassive(LocalPassiveSwitchSpeed, WMPRI.bPerkUpgrade[sindex].level);
                WMGRI.PerkUpgradesList[sindex].PerkUpgrade.static.ModifyMagSizeAndNumberPassive(LocalPassiveMagCapacity, WMPRI.bPerkUpgrade[sindex].level);
                WMGRI.PerkUpgradesList[sindex].PerkUpgrade.static.ModifySpareAmmoAmountPassive(LocalPassiveSpareAmmo, WMPRI.bPerkUpgrade[sindex].level);
                WMGRI.PerkUpgradesList[sindex].PerkUpgrade.static.ModifySpeedPassive(LocalPassiveMoveSpeed, WMPRI.bPerkUpgrade[sindex].level);
            }
            for (si = 0; si < WMPRI.Purchase_SkillUpgrade.Length; ++si)
            {
                sindex = WMPRI.Purchase_SkillUpgrade[si];
                WMGRI.SkillUpgradesList[sindex].SkillUpgrade.static.ModifyRateOfFirePassive(LocalPassiveRateOfFire, WMPRI.GetSkillUpgrade(sindex));
                WMGRI.SkillUpgradesList[sindex].SkillUpgrade.static.ModifyRecoilPassive(LocalPassiveRecoil, WMPRI.GetSkillUpgrade(sindex));
                WMGRI.SkillUpgradesList[sindex].SkillUpgrade.static.ModifySpreadPassive(LocalPassiveSpread, WMPRI.GetSkillUpgrade(sindex));
                WMGRI.SkillUpgradesList[sindex].SkillUpgrade.static.GetReloadRateScalePassive(LocalPassiveReloadRate, WMPRI.GetSkillUpgrade(sindex));
                WMGRI.SkillUpgradesList[sindex].SkillUpgrade.static.ModifyMeleeAttackSpeedPassive(LocalPassiveMeleeSpeed, WMPRI.GetSkillUpgrade(sindex));
                WMGRI.SkillUpgradesList[sindex].SkillUpgrade.static.ModifyWeaponSwitchTimePassive(LocalPassiveSwitchSpeed, WMPRI.GetSkillUpgrade(sindex));
                WMGRI.SkillUpgradesList[sindex].SkillUpgrade.static.ModifyMagSizeAndNumberPassive(LocalPassiveMagCapacity, WMPRI.GetSkillUpgrade(sindex));
                WMGRI.SkillUpgradesList[sindex].SkillUpgrade.static.ModifySpareAmmoAmountPassive(LocalPassiveSpareAmmo, WMPRI.GetSkillUpgrade(sindex));
                WMGRI.SkillUpgradesList[sindex].SkillUpgrade.static.ModifySpeedPassive(LocalPassiveMoveSpeed, WMPRI.GetSkillUpgrade(sindex));
            }
            for (si = 0; si < WMPRI.Purchase_EquipmentUpgrade.Length; ++si)
            {
                sindex = WMPRI.Purchase_EquipmentUpgrade[si];
                WMGRI.EquipmentUpgradesList[sindex].EquipmentUpgrade.static.ModifyRateOfFirePassive(LocalPassiveRateOfFire, WMPRI.bEquipmentUpgrade[sindex]);
                WMGRI.EquipmentUpgradesList[sindex].EquipmentUpgrade.static.ModifyRecoilPassive(LocalPassiveRecoil, WMPRI.bEquipmentUpgrade[sindex]);
                WMGRI.EquipmentUpgradesList[sindex].EquipmentUpgrade.static.ModifySpreadPassive(LocalPassiveSpread, WMPRI.bEquipmentUpgrade[sindex]);
                WMGRI.EquipmentUpgradesList[sindex].EquipmentUpgrade.static.GetReloadRateScalePassive(LocalPassiveReloadRate, WMPRI.bEquipmentUpgrade[sindex]);
                WMGRI.EquipmentUpgradesList[sindex].EquipmentUpgrade.static.ModifyMeleeAttackSpeedPassive(LocalPassiveMeleeSpeed, WMPRI.bEquipmentUpgrade[sindex]);
                WMGRI.EquipmentUpgradesList[sindex].EquipmentUpgrade.static.ModifyWeaponSwitchTimePassive(LocalPassiveSwitchSpeed, WMPRI.bEquipmentUpgrade[sindex]);
                WMGRI.EquipmentUpgradesList[sindex].EquipmentUpgrade.static.ModifyMagSizeAndNumberPassive(LocalPassiveMagCapacity, WMPRI.bEquipmentUpgrade[sindex]);
                WMGRI.EquipmentUpgradesList[sindex].EquipmentUpgrade.static.ModifySpareAmmoAmountPassive(LocalPassiveSpareAmmo, WMPRI.bEquipmentUpgrade[sindex]);
                WMGRI.EquipmentUpgradesList[sindex].EquipmentUpgrade.static.ModifySpeedPassive(LocalPassiveMoveSpeed, WMPRI.bEquipmentUpgrade[sindex]);
            }
        }
    }


    // Colors
    HeaderColor = MakeColorFromRGB(255, 200, 50, 255);    // Gold
    LabelColor = MakeColorFromRGB(200, 200, 200, 255);    // Light grey
    ValueColor = MakeColorFromRGB(255, 255, 255, 255);    // White
    GoodColor = MakeColorFromRGB(100, 255, 100, 255);     // Green
    BadColor = MakeColorFromRGB(255, 100, 100, 255);      // Red
    NeutralColor = MakeColorFromRGB(180, 180, 180, 255);  // Grey
    ActiveColor = MakeColorFromRGB(100, 255, 100, 255);    // Green
    InactiveColor = MakeColorFromRGB(100, 100, 100, 255);  // Dark grey

    Canvas.Font = class'KFGameEngine'.Static.GetKFCanvasFont();

    // Panel dimensions
    PanelW = 360.0f;
    LineH = 18.0f;
    Pad = 8.0f;
    PanelX = Canvas.SizeX - PanelW - 10.0f;
    PanelY = 60.0f;
    CurY = PanelY + Pad;

    // Background
    Canvas.SetDrawColor(0, 0, 0, 160);
    Canvas.SetPos(PanelX, PanelY);
    Canvas.DrawRect(PanelW, (StatOverlayMode == 2) ? 2400.0f : 1100.0f, Canvas.DefaultTexture);

    // === HEADER ===
    DrawTextWithShadow((StatOverlayMode == 2) ? "STAT OVERLAY [SOURCES]" : "STAT OVERLAY [DEV]", PanelX + Pad, CurY, HeaderColor, 0.9f);
    CurY += LineH + 4;

    // === WEAPON SECTION ===
    if (KFW != None)
    {
        WeaponName = string(KFW.Class.Name);
        // Strip common prefixes for readability
        WeaponName = Repl(WeaponName, "KFWeap_", "");
        WeaponName = Repl(WeaponName, "WMWeap_", "");
        // Truncate long names to prevent overflow
        if (Len(WeaponName) > 28)
            WeaponName = Left(WeaponName, 28) $ "..";
        DrawTextWithShadow("WPN:" @ WeaponName, PanelX + Pad, CurY, HeaderColor, 0.8f);
        CurY += LineH;

        // --- Fire Rate ---
        DefaultRate = KFW.default.FireInterval[0];
        ModifiedRate = DefaultRate;
        WMP.ModifyRateOfFire(ModifiedRate, KFW);
        DrawStatLine(PanelX + Pad, CurY, "Fire Rate",
            FormatFloat3(DefaultRate) $ "s",
            FormatFloat3(ModifiedRate) $ "s",
            DefaultRate, ModifiedRate, true, LabelColor, GoodColor, BadColor, NeutralColor);

        // Fire Rate source trace
        if (StatOverlayMode == 2 && WMPRI != None && WMGRI != None)
        {
            TrackedVal = DefaultRate;
            BeforeVal = TrackedVal;
            TrackedVal *= LocalPassiveRateOfFire;
            if (Abs(TrackedVal - BeforeVal) > 0.0001f)
            {
                SrcPct = ((TrackedVal / BeforeVal) - 1.0f) * 100.0f;
                CurY = DrawSourceLine(PanelX + Pad, CurY, "Perk Passive", SrcPct, SrcColor);
            }
            for (si = 0; si <= 1; ++si)
            {
                if (WMGRI.SpecialWaveID[si] != INDEX_NONE)
                {
                    BeforeVal = TrackedVal;
                    WMGRI.SpecialWavesList[WMGRI.SpecialWaveID[si]].SpecialWave.static.ModifyRateOfFire(TrackedVal, DefaultRate, KFW);
                    if (Abs(TrackedVal - BeforeVal) > 0.0001f)
                    {
                        SrcPct = ((TrackedVal / BeforeVal) - 1.0f) * 100.0f;
                        SrcName = GetCleanClassName(WMGRI.SpecialWavesList[WMGRI.SpecialWaveID[si]].SpecialWave);
                        CurY = DrawSourceLine(PanelX + Pad, CurY, "SW:" @ SrcName, SrcPct, SrcColor);
                    }
                }
            }
            for (si = 0; si < WMPRI.Purchase_WeaponUpgrade.Length; ++si)
            {
                sindex = WMPRI.Purchase_WeaponUpgrade[si];
                if (WMP.isValidWeapon(WMGRI.WeaponUpgradeSlotsList[sindex].KFWeapon, KFW))
                {
                    BeforeVal = TrackedVal;
                    WMGRI.WeaponUpgradeSlotsList[sindex].WeaponUpgrade.static.ModifyRateOfFire(TrackedVal, DefaultRate, WMPRI.GetWeaponUpgrade(sindex), KFW);
                    if (Abs(TrackedVal - BeforeVal) > 0.0001f)
                    {
                        SrcPct = ((TrackedVal / BeforeVal) - 1.0f) * 100.0f;
                        SrcName = GetCleanClassName(WMGRI.WeaponUpgradeSlotsList[sindex].WeaponUpgrade);
                        CurY = DrawSourceLine(PanelX + Pad, CurY, "Wpn:" @ SrcName, SrcPct, SrcColor);
                    }
                }
            }
            for (si = 0; si < WMPRI.Purchase_PerkUpgrade.Length; ++si)
            {
                sindex = WMPRI.Purchase_PerkUpgrade[si];
                BeforeVal = TrackedVal;
                WMGRI.PerkUpgradesList[sindex].PerkUpgrade.static.ModifyRateOfFire(TrackedVal, DefaultRate, WMPRI.bPerkUpgrade[sindex].level, KFW);
                if (Abs(TrackedVal - BeforeVal) > 0.0001f)
                {
                    SrcPct = ((TrackedVal / BeforeVal) - 1.0f) * 100.0f;
                    SrcName = GetCleanClassName(WMGRI.PerkUpgradesList[sindex].PerkUpgrade);
                    CurY = DrawSourceLine(PanelX + Pad, CurY, "Perk:" @ SrcName, SrcPct, SrcColor);
                }
            }
            for (si = 0; si < WMPRI.Purchase_EquipmentUpgrade.Length; ++si)
            {
                sindex = WMPRI.Purchase_EquipmentUpgrade[si];
                BeforeVal = TrackedVal;
                WMGRI.EquipmentUpgradesList[sindex].EquipmentUpgrade.static.ModifyRateOfFire(TrackedVal, DefaultRate, WMPRI.bEquipmentUpgrade[sindex], KFW);
                if (Abs(TrackedVal - BeforeVal) > 0.0001f)
                {
                    SrcPct = ((TrackedVal / BeforeVal) - 1.0f) * 100.0f;
                    SrcName = GetCleanClassName(WMGRI.EquipmentUpgradesList[sindex].EquipmentUpgrade);
                    CurY = DrawSourceLine(PanelX + Pad, CurY, "Equip:" @ SrcName, SrcPct, SrcColor);
                }
            }
            for (si = 0; si < WMPRI.Purchase_SkillUpgrade.Length; ++si)
            {
                sindex = WMPRI.Purchase_SkillUpgrade[si];
                BeforeVal = TrackedVal;
                WMGRI.SkillUpgradesList[sindex].SkillUpgrade.static.ModifyRateOfFire(TrackedVal, DefaultRate, WMPRI.GetSkillUpgrade(sindex), KFW);
                if (Abs(TrackedVal - BeforeVal) > 0.0001f)
                {
                    SrcPct = ((TrackedVal / BeforeVal) - 1.0f) * 100.0f;
                    SrcName = GetCleanClassName(WMGRI.SkillUpgradesList[sindex].SkillUpgrade);
                    CurY = DrawSourceLine(PanelX + Pad, CurY, "Skill:" @ SrcName, SrcPct, SrcColor);
                }
            }
        }
        CurY += LineH;

        // --- Recoil ---
        DefaultRecoil = 1.0f;
        ModifiedRecoil = DefaultRecoil;
        WMP.ModifyRecoil(ModifiedRecoil, KFW);
        DrawStatLine(PanelX + Pad, CurY, "Recoil",
            FormatFloat2(DefaultRecoil),
            FormatFloat2(ModifiedRecoil),
            DefaultRecoil, ModifiedRecoil, true, LabelColor, GoodColor, BadColor, NeutralColor);

        // Recoil source trace
        if (StatOverlayMode == 2 && WMPRI != None && WMGRI != None)
        {
            TrackedVal = DefaultRecoil;
            BeforeVal = TrackedVal;
            TrackedVal *= LocalPassiveRecoil;
            if (Abs(TrackedVal - BeforeVal) > 0.0001f)
            {
                SrcPct = ((TrackedVal / BeforeVal) - 1.0f) * 100.0f;
                CurY = DrawSourceLine(PanelX + Pad, CurY, "Perk Passive", SrcPct, SrcColor);
            }
            for (si = 0; si <= 1; ++si)
            {
                if (WMGRI.SpecialWaveID[si] != INDEX_NONE)
                {
                    BeforeVal = TrackedVal;
                    WMGRI.SpecialWavesList[WMGRI.SpecialWaveID[si]].SpecialWave.static.ModifyRecoil(TrackedVal, DefaultRecoil, KFW);
                    if (Abs(TrackedVal - BeforeVal) > 0.0001f)
                    {
                        SrcPct = ((TrackedVal / BeforeVal) - 1.0f) * 100.0f;
                        SrcName = GetCleanClassName(WMGRI.SpecialWavesList[WMGRI.SpecialWaveID[si]].SpecialWave);
                        CurY = DrawSourceLine(PanelX + Pad, CurY, "SW:" @ SrcName, SrcPct, SrcColor);
                    }
                }
            }
            for (si = 0; si < WMPRI.Purchase_WeaponUpgrade.Length; ++si)
            {
                sindex = WMPRI.Purchase_WeaponUpgrade[si];
                if (WMP.isValidWeapon(WMGRI.WeaponUpgradeSlotsList[sindex].KFWeapon, KFW))
                {
                    BeforeVal = TrackedVal;
                    WMGRI.WeaponUpgradeSlotsList[sindex].WeaponUpgrade.static.ModifyRecoil(TrackedVal, DefaultRecoil, WMPRI.GetWeaponUpgrade(sindex), KFW);
                    if (Abs(TrackedVal - BeforeVal) > 0.0001f)
                    {
                        SrcPct = ((TrackedVal / BeforeVal) - 1.0f) * 100.0f;
                        SrcName = GetCleanClassName(WMGRI.WeaponUpgradeSlotsList[sindex].WeaponUpgrade);
                        CurY = DrawSourceLine(PanelX + Pad, CurY, "Wpn:" @ SrcName, SrcPct, SrcColor);
                    }
                }
            }
            for (si = 0; si < WMPRI.Purchase_PerkUpgrade.Length; ++si)
            {
                sindex = WMPRI.Purchase_PerkUpgrade[si];
                BeforeVal = TrackedVal;
                WMGRI.PerkUpgradesList[sindex].PerkUpgrade.static.ModifyRecoil(TrackedVal, DefaultRecoil, WMPRI.bPerkUpgrade[sindex].level, KFW);
                if (Abs(TrackedVal - BeforeVal) > 0.0001f)
                {
                    SrcPct = ((TrackedVal / BeforeVal) - 1.0f) * 100.0f;
                    SrcName = GetCleanClassName(WMGRI.PerkUpgradesList[sindex].PerkUpgrade);
                    CurY = DrawSourceLine(PanelX + Pad, CurY, "Perk:" @ SrcName, SrcPct, SrcColor);
                }
            }
            for (si = 0; si < WMPRI.Purchase_EquipmentUpgrade.Length; ++si)
            {
                sindex = WMPRI.Purchase_EquipmentUpgrade[si];
                BeforeVal = TrackedVal;
                WMGRI.EquipmentUpgradesList[sindex].EquipmentUpgrade.static.ModifyRecoil(TrackedVal, DefaultRecoil, WMPRI.bEquipmentUpgrade[sindex], KFW);
                if (Abs(TrackedVal - BeforeVal) > 0.0001f)
                {
                    SrcPct = ((TrackedVal / BeforeVal) - 1.0f) * 100.0f;
                    SrcName = GetCleanClassName(WMGRI.EquipmentUpgradesList[sindex].EquipmentUpgrade);
                    CurY = DrawSourceLine(PanelX + Pad, CurY, "Equip:" @ SrcName, SrcPct, SrcColor);
                }
            }
            for (si = 0; si < WMPRI.Purchase_SkillUpgrade.Length; ++si)
            {
                sindex = WMPRI.Purchase_SkillUpgrade[si];
                BeforeVal = TrackedVal;
                WMGRI.SkillUpgradesList[sindex].SkillUpgrade.static.ModifyRecoil(TrackedVal, DefaultRecoil, WMPRI.GetSkillUpgrade(sindex), KFW);
                if (Abs(TrackedVal - BeforeVal) > 0.0001f)
                {
                    SrcPct = ((TrackedVal / BeforeVal) - 1.0f) * 100.0f;
                    SrcName = GetCleanClassName(WMGRI.SkillUpgradesList[sindex].SkillUpgrade);
                    CurY = DrawSourceLine(PanelX + Pad, CurY, "Skill:" @ SrcName, SrcPct, SrcColor);
                }
            }
        }
        CurY += LineH;

        // --- Spread ---
        DefaultSpread = 1.0f;
        ModifiedSpread = DefaultSpread;
        WMP.ModifySpread(ModifiedSpread);
        DrawStatLine(PanelX + Pad, CurY, "Spread",
            FormatFloat2(DefaultSpread),
            FormatFloat2(ModifiedSpread),
            DefaultSpread, ModifiedSpread, true, LabelColor, GoodColor, BadColor, NeutralColor);

        // Spread source trace
        if (StatOverlayMode == 2 && WMPRI != None && WMGRI != None)
        {
            TrackedVal = DefaultSpread;
            BeforeVal = TrackedVal;
            TrackedVal *= LocalPassiveSpread;
            if (Abs(TrackedVal - BeforeVal) > 0.0001f)
            {
                SrcPct = ((TrackedVal / BeforeVal) - 1.0f) * 100.0f;
                CurY = DrawSourceLine(PanelX + Pad, CurY, "Perk Passive", SrcPct, SrcColor);
            }
            for (si = 0; si <= 1; ++si)
            {
                if (WMGRI.SpecialWaveID[si] != INDEX_NONE)
                {
                    BeforeVal = TrackedVal;
                    WMGRI.SpecialWavesList[WMGRI.SpecialWaveID[si]].SpecialWave.static.ModifySpread(TrackedVal, DefaultSpread, KFW);
                    if (Abs(TrackedVal - BeforeVal) > 0.0001f)
                    {
                        SrcPct = ((TrackedVal / BeforeVal) - 1.0f) * 100.0f;
                        SrcName = GetCleanClassName(WMGRI.SpecialWavesList[WMGRI.SpecialWaveID[si]].SpecialWave);
                        CurY = DrawSourceLine(PanelX + Pad, CurY, "SW:" @ SrcName, SrcPct, SrcColor);
                    }
                }
            }
            for (si = 0; si < WMPRI.Purchase_WeaponUpgrade.Length; ++si)
            {
                sindex = WMPRI.Purchase_WeaponUpgrade[si];
                if (WMP.isValidWeapon(WMGRI.WeaponUpgradeSlotsList[sindex].KFWeapon, KFW))
                {
                    BeforeVal = TrackedVal;
                    WMGRI.WeaponUpgradeSlotsList[sindex].WeaponUpgrade.static.ModifySpread(TrackedVal, DefaultSpread, WMPRI.GetWeaponUpgrade(sindex), KFW);
                    if (Abs(TrackedVal - BeforeVal) > 0.0001f)
                    {
                        SrcPct = ((TrackedVal / BeforeVal) - 1.0f) * 100.0f;
                        SrcName = GetCleanClassName(WMGRI.WeaponUpgradeSlotsList[sindex].WeaponUpgrade);
                        CurY = DrawSourceLine(PanelX + Pad, CurY, "Wpn:" @ SrcName, SrcPct, SrcColor);
                    }
                }
            }
            for (si = 0; si < WMPRI.Purchase_PerkUpgrade.Length; ++si)
            {
                sindex = WMPRI.Purchase_PerkUpgrade[si];
                BeforeVal = TrackedVal;
                WMGRI.PerkUpgradesList[sindex].PerkUpgrade.static.ModifySpread(TrackedVal, DefaultSpread, WMPRI.bPerkUpgrade[sindex].level, KFW);
                if (Abs(TrackedVal - BeforeVal) > 0.0001f)
                {
                    SrcPct = ((TrackedVal / BeforeVal) - 1.0f) * 100.0f;
                    SrcName = GetCleanClassName(WMGRI.PerkUpgradesList[sindex].PerkUpgrade);
                    CurY = DrawSourceLine(PanelX + Pad, CurY, "Perk:" @ SrcName, SrcPct, SrcColor);
                }
            }
            for (si = 0; si < WMPRI.Purchase_EquipmentUpgrade.Length; ++si)
            {
                sindex = WMPRI.Purchase_EquipmentUpgrade[si];
                BeforeVal = TrackedVal;
                WMGRI.EquipmentUpgradesList[sindex].EquipmentUpgrade.static.ModifySpread(TrackedVal, DefaultSpread, WMPRI.bEquipmentUpgrade[sindex], KFW);
                if (Abs(TrackedVal - BeforeVal) > 0.0001f)
                {
                    SrcPct = ((TrackedVal / BeforeVal) - 1.0f) * 100.0f;
                    SrcName = GetCleanClassName(WMGRI.EquipmentUpgradesList[sindex].EquipmentUpgrade);
                    CurY = DrawSourceLine(PanelX + Pad, CurY, "Equip:" @ SrcName, SrcPct, SrcColor);
                }
            }
            for (si = 0; si < WMPRI.Purchase_SkillUpgrade.Length; ++si)
            {
                sindex = WMPRI.Purchase_SkillUpgrade[si];
                BeforeVal = TrackedVal;
                WMGRI.SkillUpgradesList[sindex].SkillUpgrade.static.ModifySpread(TrackedVal, DefaultSpread, WMPRI.GetSkillUpgrade(sindex), KFW);
                if (Abs(TrackedVal - BeforeVal) > 0.0001f)
                {
                    SrcPct = ((TrackedVal / BeforeVal) - 1.0f) * 100.0f;
                    SrcName = GetCleanClassName(WMGRI.SkillUpgradesList[sindex].SkillUpgrade);
                    CurY = DrawSourceLine(PanelX + Pad, CurY, "Skill:" @ SrcName, SrcPct, SrcColor);
                }
            }
        }
        CurY += LineH;

        // --- Reload Rate ---
        ReloadScale = WMP.GetReloadRateScale(KFW);
        DrawStatLine(PanelX + Pad, CurY, "Reload Scale",
            "1.00",
            FormatFloat2(ReloadScale),
            1.0f, ReloadScale, true, LabelColor, GoodColor, BadColor, NeutralColor);

        // Reload Scale source trace
        if (StatOverlayMode == 2 && WMPRI != None && WMGRI != None)
        {
            TrackedVal = 1.0f;
            BeforeVal = TrackedVal;
            TrackedVal = LocalPassiveReloadRate;
            if (Abs(TrackedVal - BeforeVal) > 0.0001f)
            {
                SrcPct = ((TrackedVal / BeforeVal) - 1.0f) * 100.0f;
                CurY = DrawSourceLine(PanelX + Pad, CurY, "Perk Passive", SrcPct, SrcColor);
            }
            for (si = 0; si <= 1; ++si)
            {
                if (WMGRI.SpecialWaveID[si] != INDEX_NONE)
                {
                    BeforeVal = TrackedVal;
                    WMGRI.SpecialWavesList[WMGRI.SpecialWaveID[si]].SpecialWave.static.GetReloadRateScale(TrackedVal, KFW, KFPH);
                    if (Abs(TrackedVal - BeforeVal) > 0.0001f)
                    {
                        SrcPct = ((TrackedVal / BeforeVal) - 1.0f) * 100.0f;
                        SrcName = GetCleanClassName(WMGRI.SpecialWavesList[WMGRI.SpecialWaveID[si]].SpecialWave);
                        CurY = DrawSourceLine(PanelX + Pad, CurY, "SW:" @ SrcName, SrcPct, SrcColor);
                    }
                }
            }
            for (si = 0; si < WMPRI.Purchase_WeaponUpgrade.Length; ++si)
            {
                sindex = WMPRI.Purchase_WeaponUpgrade[si];
                if (WMP.isValidWeapon(WMGRI.WeaponUpgradeSlotsList[sindex].KFWeapon, KFW))
                {
                    BeforeVal = TrackedVal;
                    WMGRI.WeaponUpgradeSlotsList[sindex].WeaponUpgrade.static.GetReloadRateScale(TrackedVal, WMPRI.GetWeaponUpgrade(sindex), KFW, KFPH);
                    if (Abs(TrackedVal - BeforeVal) > 0.0001f)
                    {
                        SrcPct = ((TrackedVal / BeforeVal) - 1.0f) * 100.0f;
                        SrcName = GetCleanClassName(WMGRI.WeaponUpgradeSlotsList[sindex].WeaponUpgrade);
                        CurY = DrawSourceLine(PanelX + Pad, CurY, "Wpn:" @ SrcName, SrcPct, SrcColor);
                    }
                }
            }
            for (si = 0; si < WMPRI.Purchase_PerkUpgrade.Length; ++si)
            {
                sindex = WMPRI.Purchase_PerkUpgrade[si];
                BeforeVal = TrackedVal;
                WMGRI.PerkUpgradesList[sindex].PerkUpgrade.static.GetReloadRateScale(TrackedVal, WMPRI.bPerkUpgrade[sindex].level, KFW, KFPH);
                if (Abs(TrackedVal - BeforeVal) > 0.0001f)
                {
                    SrcPct = ((TrackedVal / BeforeVal) - 1.0f) * 100.0f;
                    SrcName = GetCleanClassName(WMGRI.PerkUpgradesList[sindex].PerkUpgrade);
                    CurY = DrawSourceLine(PanelX + Pad, CurY, "Perk:" @ SrcName, SrcPct, SrcColor);
                }
            }
            for (si = 0; si < WMPRI.Purchase_EquipmentUpgrade.Length; ++si)
            {
                sindex = WMPRI.Purchase_EquipmentUpgrade[si];
                BeforeVal = TrackedVal;
                WMGRI.EquipmentUpgradesList[sindex].EquipmentUpgrade.static.GetReloadRateScale(TrackedVal, WMPRI.bEquipmentUpgrade[sindex], KFW, KFPH);
                if (Abs(TrackedVal - BeforeVal) > 0.0001f)
                {
                    SrcPct = ((TrackedVal / BeforeVal) - 1.0f) * 100.0f;
                    SrcName = GetCleanClassName(WMGRI.EquipmentUpgradesList[sindex].EquipmentUpgrade);
                    CurY = DrawSourceLine(PanelX + Pad, CurY, "Equip:" @ SrcName, SrcPct, SrcColor);
                }
            }
            for (si = 0; si < WMPRI.Purchase_SkillUpgrade.Length; ++si)
            {
                sindex = WMPRI.Purchase_SkillUpgrade[si];
                BeforeVal = TrackedVal;
                WMGRI.SkillUpgradesList[sindex].SkillUpgrade.static.GetReloadRateScale(TrackedVal, WMPRI.GetSkillUpgrade(sindex), KFW, KFPH);
                if (Abs(TrackedVal - BeforeVal) > 0.0001f)
                {
                    SrcPct = ((TrackedVal / BeforeVal) - 1.0f) * 100.0f;
                    SrcName = GetCleanClassName(WMGRI.SkillUpgradesList[sindex].SkillUpgrade);
                    CurY = DrawSourceLine(PanelX + Pad, CurY, "Skill:" @ SrcName, SrcPct, SrcColor);
                }
            }
            // Roguelike reload bonus
            if (DKPRI != None && DKPRI.GetRoguelikeReloadMult() > 0.001f)
            {
                CurY = DrawSourceLine(PanelX + Pad, CurY, "Roguelike", -DKPRI.GetRoguelikeReloadMult() * 100.0f, MakeColorFromRGB(180, 120, 255, 220));
            }
        }
        CurY += LineH;

        // --- Melee Attack Speed ---
        DefaultMelee = 1.0f;
        ModifiedMelee = DefaultMelee;
        WMP.ModifyMeleeAttackSpeed(ModifiedMelee, KFW);
        DrawStatLine(PanelX + Pad, CurY, "Melee Speed",
            FormatFloat2(DefaultMelee),
            FormatFloat2(ModifiedMelee),
            DefaultMelee, ModifiedMelee, true, LabelColor, GoodColor, BadColor, NeutralColor);

        // Melee Speed source trace
        if (StatOverlayMode == 2 && WMPRI != None && WMGRI != None)
        {
            TrackedVal = DefaultMelee;
            BeforeVal = TrackedVal;
            TrackedVal *= LocalPassiveMeleeSpeed;
            if (Abs(TrackedVal - BeforeVal) > 0.0001f)
            {
                SrcPct = ((TrackedVal / BeforeVal) - 1.0f) * 100.0f;
                CurY = DrawSourceLine(PanelX + Pad, CurY, "Perk Passive", SrcPct, SrcColor);
            }
            for (si = 0; si <= 1; ++si)
            {
                if (WMGRI.SpecialWaveID[si] != INDEX_NONE)
                {
                    BeforeVal = TrackedVal;
                    WMGRI.SpecialWavesList[WMGRI.SpecialWaveID[si]].SpecialWave.static.ModifyMeleeAttackSpeed(TrackedVal, DefaultMelee, KFW);
                    if (Abs(TrackedVal - BeforeVal) > 0.0001f)
                    {
                        SrcPct = ((TrackedVal / BeforeVal) - 1.0f) * 100.0f;
                        SrcName = GetCleanClassName(WMGRI.SpecialWavesList[WMGRI.SpecialWaveID[si]].SpecialWave);
                        CurY = DrawSourceLine(PanelX + Pad, CurY, "SW:" @ SrcName, SrcPct, SrcColor);
                    }
                }
            }
            for (si = 0; si < WMPRI.Purchase_WeaponUpgrade.Length; ++si)
            {
                sindex = WMPRI.Purchase_WeaponUpgrade[si];
                if (WMP.isValidWeapon(WMGRI.WeaponUpgradeSlotsList[sindex].KFWeapon, KFW))
                {
                    BeforeVal = TrackedVal;
                    WMGRI.WeaponUpgradeSlotsList[sindex].WeaponUpgrade.static.ModifyMeleeAttackSpeed(TrackedVal, DefaultMelee, WMPRI.GetWeaponUpgrade(sindex), KFW);
                    if (Abs(TrackedVal - BeforeVal) > 0.0001f)
                    {
                        SrcPct = ((TrackedVal / BeforeVal) - 1.0f) * 100.0f;
                        SrcName = GetCleanClassName(WMGRI.WeaponUpgradeSlotsList[sindex].WeaponUpgrade);
                        CurY = DrawSourceLine(PanelX + Pad, CurY, "Wpn:" @ SrcName, SrcPct, SrcColor);
                    }
                }
            }
            for (si = 0; si < WMPRI.Purchase_PerkUpgrade.Length; ++si)
            {
                sindex = WMPRI.Purchase_PerkUpgrade[si];
                BeforeVal = TrackedVal;
                WMGRI.PerkUpgradesList[sindex].PerkUpgrade.static.ModifyMeleeAttackSpeed(TrackedVal, DefaultMelee, WMPRI.bPerkUpgrade[sindex].level, KFW);
                if (Abs(TrackedVal - BeforeVal) > 0.0001f)
                {
                    SrcPct = ((TrackedVal / BeforeVal) - 1.0f) * 100.0f;
                    SrcName = GetCleanClassName(WMGRI.PerkUpgradesList[sindex].PerkUpgrade);
                    CurY = DrawSourceLine(PanelX + Pad, CurY, "Perk:" @ SrcName, SrcPct, SrcColor);
                }
            }
            for (si = 0; si < WMPRI.Purchase_EquipmentUpgrade.Length; ++si)
            {
                sindex = WMPRI.Purchase_EquipmentUpgrade[si];
                BeforeVal = TrackedVal;
                WMGRI.EquipmentUpgradesList[sindex].EquipmentUpgrade.static.ModifyMeleeAttackSpeed(TrackedVal, DefaultMelee, WMPRI.bEquipmentUpgrade[sindex], KFW);
                if (Abs(TrackedVal - BeforeVal) > 0.0001f)
                {
                    SrcPct = ((TrackedVal / BeforeVal) - 1.0f) * 100.0f;
                    SrcName = GetCleanClassName(WMGRI.EquipmentUpgradesList[sindex].EquipmentUpgrade);
                    CurY = DrawSourceLine(PanelX + Pad, CurY, "Equip:" @ SrcName, SrcPct, SrcColor);
                }
            }
            for (si = 0; si < WMPRI.Purchase_SkillUpgrade.Length; ++si)
            {
                sindex = WMPRI.Purchase_SkillUpgrade[si];
                BeforeVal = TrackedVal;
                WMGRI.SkillUpgradesList[sindex].SkillUpgrade.static.ModifyMeleeAttackSpeed(TrackedVal, DefaultMelee, WMPRI.GetSkillUpgrade(sindex), KFW);
                if (Abs(TrackedVal - BeforeVal) > 0.0001f)
                {
                    SrcPct = ((TrackedVal / BeforeVal) - 1.0f) * 100.0f;
                    SrcName = GetCleanClassName(WMGRI.SkillUpgradesList[sindex].SkillUpgrade);
                    CurY = DrawSourceLine(PanelX + Pad, CurY, "Skill:" @ SrcName, SrcPct, SrcColor);
                }
            }
        }
        CurY += LineH;

        // --- Weapon Switch Speed ---
        DefaultSwitch = 1.0f;
        ModifiedSwitch = DefaultSwitch;
        WMP.ModifyWeaponSwitchTime(ModifiedSwitch);
        DrawStatLine(PanelX + Pad, CurY, "Switch Speed",
            FormatFloat2(DefaultSwitch),
            FormatFloat2(ModifiedSwitch),
            DefaultSwitch, ModifiedSwitch, true, LabelColor, GoodColor, BadColor, NeutralColor);

        // Switch Speed source trace
        if (StatOverlayMode == 2 && WMPRI != None && WMGRI != None)
        {
            TrackedVal = DefaultSwitch;
            BeforeVal = TrackedVal;
            TrackedVal *= LocalPassiveSwitchSpeed;
            if (Abs(TrackedVal - BeforeVal) > 0.0001f)
            {
                SrcPct = ((TrackedVal / BeforeVal) - 1.0f) * 100.0f;
                CurY = DrawSourceLine(PanelX + Pad, CurY, "Perk Passive", SrcPct, SrcColor);
            }
            for (si = 0; si <= 1; ++si)
            {
                if (WMGRI.SpecialWaveID[si] != INDEX_NONE)
                {
                    BeforeVal = TrackedVal;
                    WMGRI.SpecialWavesList[WMGRI.SpecialWaveID[si]].SpecialWave.static.ModifyWeaponSwitchTime(TrackedVal, DefaultSwitch, KFW);
                    if (Abs(TrackedVal - BeforeVal) > 0.0001f)
                    {
                        SrcPct = ((TrackedVal / BeforeVal) - 1.0f) * 100.0f;
                        SrcName = GetCleanClassName(WMGRI.SpecialWavesList[WMGRI.SpecialWaveID[si]].SpecialWave);
                        CurY = DrawSourceLine(PanelX + Pad, CurY, "SW:" @ SrcName, SrcPct, SrcColor);
                    }
                }
            }
            for (si = 0; si < WMPRI.Purchase_WeaponUpgrade.Length; ++si)
            {
                sindex = WMPRI.Purchase_WeaponUpgrade[si];
                if (WMP.isValidWeapon(WMGRI.WeaponUpgradeSlotsList[sindex].KFWeapon, KFW))
                {
                    BeforeVal = TrackedVal;
                    WMGRI.WeaponUpgradeSlotsList[sindex].WeaponUpgrade.static.ModifyWeaponSwitchTime(TrackedVal, DefaultSwitch, WMPRI.GetWeaponUpgrade(sindex), KFW);
                    if (Abs(TrackedVal - BeforeVal) > 0.0001f)
                    {
                        SrcPct = ((TrackedVal / BeforeVal) - 1.0f) * 100.0f;
                        SrcName = GetCleanClassName(WMGRI.WeaponUpgradeSlotsList[sindex].WeaponUpgrade);
                        CurY = DrawSourceLine(PanelX + Pad, CurY, "Wpn:" @ SrcName, SrcPct, SrcColor);
                    }
                }
            }
            for (si = 0; si < WMPRI.Purchase_PerkUpgrade.Length; ++si)
            {
                sindex = WMPRI.Purchase_PerkUpgrade[si];
                BeforeVal = TrackedVal;
                WMGRI.PerkUpgradesList[sindex].PerkUpgrade.static.ModifyWeaponSwitchTime(TrackedVal, DefaultSwitch, WMPRI.bPerkUpgrade[sindex].level, KFW);
                if (Abs(TrackedVal - BeforeVal) > 0.0001f)
                {
                    SrcPct = ((TrackedVal / BeforeVal) - 1.0f) * 100.0f;
                    SrcName = GetCleanClassName(WMGRI.PerkUpgradesList[sindex].PerkUpgrade);
                    CurY = DrawSourceLine(PanelX + Pad, CurY, "Perk:" @ SrcName, SrcPct, SrcColor);
                }
            }
            for (si = 0; si < WMPRI.Purchase_EquipmentUpgrade.Length; ++si)
            {
                sindex = WMPRI.Purchase_EquipmentUpgrade[si];
                BeforeVal = TrackedVal;
                WMGRI.EquipmentUpgradesList[sindex].EquipmentUpgrade.static.ModifyWeaponSwitchTime(TrackedVal, DefaultSwitch, WMPRI.bEquipmentUpgrade[sindex], KFW);
                if (Abs(TrackedVal - BeforeVal) > 0.0001f)
                {
                    SrcPct = ((TrackedVal / BeforeVal) - 1.0f) * 100.0f;
                    SrcName = GetCleanClassName(WMGRI.EquipmentUpgradesList[sindex].EquipmentUpgrade);
                    CurY = DrawSourceLine(PanelX + Pad, CurY, "Equip:" @ SrcName, SrcPct, SrcColor);
                }
            }
            for (si = 0; si < WMPRI.Purchase_SkillUpgrade.Length; ++si)
            {
                sindex = WMPRI.Purchase_SkillUpgrade[si];
                BeforeVal = TrackedVal;
                WMGRI.SkillUpgradesList[sindex].SkillUpgrade.static.ModifyWeaponSwitchTime(TrackedVal, DefaultSwitch, WMPRI.GetSkillUpgrade(sindex), KFW);
                if (Abs(TrackedVal - BeforeVal) > 0.0001f)
                {
                    SrcPct = ((TrackedVal / BeforeVal) - 1.0f) * 100.0f;
                    SrcName = GetCleanClassName(WMGRI.SkillUpgradesList[sindex].SkillUpgrade);
                    CurY = DrawSourceLine(PanelX + Pad, CurY, "Skill:" @ SrcName, SrcPct, SrcColor);
                }
            }
        }
        CurY += LineH;

        // --- ZED Time Fire Rate Modifier ---
        ZedTimeMod = WMP.GetZedTimeModifier(KFW);
        DrawTextWithShadow("ZED Time Mod", PanelX + Pad, CurY, LabelColor, 0.75f);
        DrawTextWithShadow("+" $ string(int(ZedTimeMod * 100)) $ "%",
            PanelX + Pad + 140, CurY,
            (ZedTimeMod > 0.005f) ? GoodColor : NeutralColor, 0.75f);
        CurY += LineH;

        // --- Magazine Size ---
        DefaultMag = KFW.default.MagazineCapacity[0];
        ActualMag = KFW.MagazineCapacity[0];
        Pct = (DefaultMag > 0) ? ((float(ActualMag) / float(DefaultMag)) - 1.0f) * 100.0f : 0.0f;
        PctStr = FormatPctString(Pct);
        DrawTextWithShadow("Mag Size", PanelX + Pad, CurY, LabelColor, 0.75f);
        DrawTextWithShadow(string(DefaultMag) @ ">" @ string(ActualMag),
            PanelX + Pad + 140, CurY, ValueColor, 0.75f);
        DrawTextWithShadow(PctStr, PanelX + Pad + 280, CurY,
            (Pct > 0.5f) ? GoodColor : ((Pct < -0.5f) ? BadColor : NeutralColor), 0.75f);

        // Mag Size source trace
        if (StatOverlayMode == 2 && WMPRI != None && WMGRI != None && DefaultMag > 0)
        {
            TrackedInt = DefaultMag;
            BeforeInt = TrackedInt;
            TrackedInt = Round(float(TrackedInt) * LocalPassiveMagCapacity);
            if (TrackedInt != BeforeInt)
            {
                SrcPct = ((float(TrackedInt) / float(BeforeInt)) - 1.0f) * 100.0f;
                CurY = DrawSourceLine(PanelX + Pad, CurY, "Perk Passive", SrcPct, SrcColor);
            }
            for (si = 0; si <= 1; ++si)
            {
                if (WMGRI.SpecialWaveID[si] != INDEX_NONE)
                {
                    BeforeInt = TrackedInt;
                    WMGRI.SpecialWavesList[WMGRI.SpecialWaveID[si]].SpecialWave.static.ModifyMagSizeAndNumber(TrackedInt, DefaultMag, KFW);
                    if (TrackedInt != BeforeInt)
                    {
                        SrcPct = ((float(TrackedInt) / float(BeforeInt)) - 1.0f) * 100.0f;
                        SrcName = GetCleanClassName(WMGRI.SpecialWavesList[WMGRI.SpecialWaveID[si]].SpecialWave);
                        CurY = DrawSourceLine(PanelX + Pad, CurY, "SW:" @ SrcName, SrcPct, SrcColor);
                    }
                }
            }
            for (si = 0; si < WMPRI.Purchase_WeaponUpgrade.Length; ++si)
            {
                sindex = WMPRI.Purchase_WeaponUpgrade[si];
                if (WMP.isValidWeapon(WMGRI.WeaponUpgradeSlotsList[sindex].KFWeapon, KFW))
                {
                    BeforeInt = TrackedInt;
                    WMGRI.WeaponUpgradeSlotsList[sindex].WeaponUpgrade.static.ModifyMagSizeAndNumber(TrackedInt, DefaultMag, WMPRI.GetWeaponUpgrade(sindex), KFW);
                    if (TrackedInt != BeforeInt)
                    {
                        SrcPct = ((float(TrackedInt) / float(BeforeInt)) - 1.0f) * 100.0f;
                        SrcName = GetCleanClassName(WMGRI.WeaponUpgradeSlotsList[sindex].WeaponUpgrade);
                        CurY = DrawSourceLine(PanelX + Pad, CurY, "Wpn:" @ SrcName, SrcPct, SrcColor);
                    }
                }
            }
            for (si = 0; si < WMPRI.Purchase_PerkUpgrade.Length; ++si)
            {
                sindex = WMPRI.Purchase_PerkUpgrade[si];
                BeforeInt = TrackedInt;
                WMGRI.PerkUpgradesList[sindex].PerkUpgrade.static.ModifyMagSizeAndNumber(TrackedInt, DefaultMag, WMPRI.bPerkUpgrade[sindex].level, KFW);
                if (TrackedInt != BeforeInt)
                {
                    SrcPct = ((float(TrackedInt) / float(BeforeInt)) - 1.0f) * 100.0f;
                    SrcName = GetCleanClassName(WMGRI.PerkUpgradesList[sindex].PerkUpgrade);
                    CurY = DrawSourceLine(PanelX + Pad, CurY, "Perk:" @ SrcName, SrcPct, SrcColor);
                }
            }
            for (si = 0; si < WMPRI.Purchase_EquipmentUpgrade.Length; ++si)
            {
                sindex = WMPRI.Purchase_EquipmentUpgrade[si];
                BeforeInt = TrackedInt;
                WMGRI.EquipmentUpgradesList[sindex].EquipmentUpgrade.static.ModifyMagSizeAndNumber(TrackedInt, DefaultMag, WMPRI.bEquipmentUpgrade[sindex], KFW);
                if (TrackedInt != BeforeInt)
                {
                    SrcPct = ((float(TrackedInt) / float(BeforeInt)) - 1.0f) * 100.0f;
                    SrcName = GetCleanClassName(WMGRI.EquipmentUpgradesList[sindex].EquipmentUpgrade);
                    CurY = DrawSourceLine(PanelX + Pad, CurY, "Equip:" @ SrcName, SrcPct, SrcColor);
                }
            }
            for (si = 0; si < WMPRI.Purchase_SkillUpgrade.Length; ++si)
            {
                sindex = WMPRI.Purchase_SkillUpgrade[si];
                BeforeInt = TrackedInt;
                WMGRI.SkillUpgradesList[sindex].SkillUpgrade.static.ModifyMagSizeAndNumber(TrackedInt, DefaultMag, WMPRI.GetSkillUpgrade(sindex), KFW);
                if (TrackedInt != BeforeInt)
                {
                    SrcPct = ((float(TrackedInt) / float(BeforeInt)) - 1.0f) * 100.0f;
                    SrcName = GetCleanClassName(WMGRI.SkillUpgradesList[sindex].SkillUpgrade);
                    CurY = DrawSourceLine(PanelX + Pad, CurY, "Skill:" @ SrcName, SrcPct, SrcColor);
                }
            }
        }
        CurY += LineH;

        // --- Spare Ammo ---
        DefaultSpare = KFW.default.SpareAmmoCapacity[0];
        ActualSpare = KFW.SpareAmmoCapacity[0];
        Pct = (DefaultSpare > 0) ? ((float(ActualSpare) / float(DefaultSpare)) - 1.0f) * 100.0f : 0.0f;
        PctStr = FormatPctString(Pct);
        DrawTextWithShadow("Spare Ammo", PanelX + Pad, CurY, LabelColor, 0.75f);
        DrawTextWithShadow(string(DefaultSpare) @ ">" @ string(ActualSpare),
            PanelX + Pad + 140, CurY, ValueColor, 0.75f);
        DrawTextWithShadow(PctStr, PanelX + Pad + 280, CurY,
            (Pct > 0.5f) ? GoodColor : ((Pct < -0.5f) ? BadColor : NeutralColor), 0.75f);

        // Spare Ammo source trace
        if (StatOverlayMode == 2 && WMPRI != None && WMGRI != None && DefaultSpare > 0)
        {
            TrackedInt = DefaultSpare;
            BeforeInt = TrackedInt;
            TrackedInt = Round(float(TrackedInt) * LocalPassiveSpareAmmo);
            if (TrackedInt != BeforeInt)
            {
                SrcPct = ((float(TrackedInt) / float(BeforeInt)) - 1.0f) * 100.0f;
                CurY = DrawSourceLine(PanelX + Pad, CurY, "Perk Passive", SrcPct, SrcColor);
            }
            for (si = 0; si <= 1; ++si)
            {
                if (WMGRI.SpecialWaveID[si] != INDEX_NONE)
                {
                    BeforeInt = TrackedInt;
                    WMGRI.SpecialWavesList[WMGRI.SpecialWaveID[si]].SpecialWave.static.ModifySpareAmmoAmount(TrackedInt, DefaultSpare, KFW);
                    if (TrackedInt != BeforeInt)
                    {
                        SrcPct = ((float(TrackedInt) / float(BeforeInt)) - 1.0f) * 100.0f;
                        SrcName = GetCleanClassName(WMGRI.SpecialWavesList[WMGRI.SpecialWaveID[si]].SpecialWave);
                        CurY = DrawSourceLine(PanelX + Pad, CurY, "SW:" @ SrcName, SrcPct, SrcColor);
                    }
                }
            }
            for (si = 0; si < WMPRI.Purchase_WeaponUpgrade.Length; ++si)
            {
                sindex = WMPRI.Purchase_WeaponUpgrade[si];
                if (WMP.isValidWeapon(WMGRI.WeaponUpgradeSlotsList[sindex].KFWeapon, KFW))
                {
                    BeforeInt = TrackedInt;
                    WMGRI.WeaponUpgradeSlotsList[sindex].WeaponUpgrade.static.ModifySpareAmmoAmount(TrackedInt, DefaultSpare, WMPRI.GetWeaponUpgrade(sindex), KFW);
                    if (TrackedInt != BeforeInt)
                    {
                        SrcPct = ((float(TrackedInt) / float(BeforeInt)) - 1.0f) * 100.0f;
                        SrcName = GetCleanClassName(WMGRI.WeaponUpgradeSlotsList[sindex].WeaponUpgrade);
                        CurY = DrawSourceLine(PanelX + Pad, CurY, "Wpn:" @ SrcName, SrcPct, SrcColor);
                    }
                }
            }
            for (si = 0; si < WMPRI.Purchase_PerkUpgrade.Length; ++si)
            {
                sindex = WMPRI.Purchase_PerkUpgrade[si];
                BeforeInt = TrackedInt;
                WMGRI.PerkUpgradesList[sindex].PerkUpgrade.static.ModifySpareAmmoAmount(TrackedInt, DefaultSpare, WMPRI.bPerkUpgrade[sindex].level, KFW);
                if (TrackedInt != BeforeInt)
                {
                    SrcPct = ((float(TrackedInt) / float(BeforeInt)) - 1.0f) * 100.0f;
                    SrcName = GetCleanClassName(WMGRI.PerkUpgradesList[sindex].PerkUpgrade);
                    CurY = DrawSourceLine(PanelX + Pad, CurY, "Perk:" @ SrcName, SrcPct, SrcColor);
                }
            }
            for (si = 0; si < WMPRI.Purchase_EquipmentUpgrade.Length; ++si)
            {
                sindex = WMPRI.Purchase_EquipmentUpgrade[si];
                BeforeInt = TrackedInt;
                WMGRI.EquipmentUpgradesList[sindex].EquipmentUpgrade.static.ModifySpareAmmoAmount(TrackedInt, DefaultSpare, WMPRI.bEquipmentUpgrade[sindex], KFW);
                if (TrackedInt != BeforeInt)
                {
                    SrcPct = ((float(TrackedInt) / float(BeforeInt)) - 1.0f) * 100.0f;
                    SrcName = GetCleanClassName(WMGRI.EquipmentUpgradesList[sindex].EquipmentUpgrade);
                    CurY = DrawSourceLine(PanelX + Pad, CurY, "Equip:" @ SrcName, SrcPct, SrcColor);
                }
            }
            for (si = 0; si < WMPRI.Purchase_SkillUpgrade.Length; ++si)
            {
                sindex = WMPRI.Purchase_SkillUpgrade[si];
                BeforeInt = TrackedInt;
                WMGRI.SkillUpgradesList[sindex].SkillUpgrade.static.ModifySpareAmmoAmount(TrackedInt, DefaultSpare, WMPRI.GetSkillUpgrade(sindex), KFW);
                if (TrackedInt != BeforeInt)
                {
                    SrcPct = ((float(TrackedInt) / float(BeforeInt)) - 1.0f) * 100.0f;
                    SrcName = GetCleanClassName(WMGRI.SkillUpgradesList[sindex].SkillUpgrade);
                    CurY = DrawSourceLine(PanelX + Pad, CurY, "Skill:" @ SrcName, SrcPct, SrcColor);
                }
            }
            // Roguelike ammo bonus
            if (DKPRI != None && DKPRI.GetRoguelikeAmmoMult() > 0.001f)
            {
                CurY = DrawSourceLine(PanelX + Pad, CurY, "Roguelike", DKPRI.GetRoguelikeAmmoMult() * 100.0f, MakeColorFromRGB(180, 120, 255, 220));
            }
        }
        CurY += LineH;

        // --- Damage (Passive Multiplier) ---
        // Recompute by walking all purchased upgrades' ModifyDamageGivenPassive
        // WMPRI/WMGRI assigned earlier for source tracing
        PassiveDmgFactor = 1.0f;
        if (WMPRI != None && WMGRI != None)
        {
            for (di = 0; di < WMPRI.Purchase_PerkUpgrade.Length; ++di)
            {
                dindex = WMPRI.Purchase_PerkUpgrade[di];
                WMGRI.PerkUpgradesList[dindex].PerkUpgrade.static.ModifyDamageGivenPassive(PassiveDmgFactor, WMPRI.bPerkUpgrade[dindex].level);
            }
            for (di = 0; di < WMPRI.Purchase_SkillUpgrade.Length; ++di)
            {
                dindex = WMPRI.Purchase_SkillUpgrade[di];
                WMGRI.SkillUpgradesList[dindex].SkillUpgrade.static.ModifyDamageGivenPassive(PassiveDmgFactor, WMPRI.GetSkillUpgrade(dindex));
            }
            for (di = 0; di < WMPRI.Purchase_EquipmentUpgrade.Length; ++di)
            {
                dindex = WMPRI.Purchase_EquipmentUpgrade[di];
                WMGRI.EquipmentUpgradesList[dindex].EquipmentUpgrade.static.ModifyDamageGivenPassive(PassiveDmgFactor, WMPRI.bEquipmentUpgrade[dindex]);
            }
        }
        DrawStatLine(PanelX + Pad, CurY, "Dmg (Passive)",
            FormatFloat2(1.0f),
            FormatFloat2(PassiveDmgFactor),
            1.0f, PassiveDmgFactor, false, LabelColor, GoodColor, BadColor, NeutralColor);

        // Damage Passive source trace
        if (StatOverlayMode == 2 && WMPRI != None && WMGRI != None)
        {
            TrackedVal = 1.0f;
            for (si = 0; si < WMPRI.Purchase_PerkUpgrade.Length; ++si)
            {
                sindex = WMPRI.Purchase_PerkUpgrade[si];
                BeforeVal = TrackedVal;
                WMGRI.PerkUpgradesList[sindex].PerkUpgrade.static.ModifyDamageGivenPassive(TrackedVal, WMPRI.bPerkUpgrade[sindex].level);
                if (Abs(TrackedVal - BeforeVal) > 0.0001f)
                {
                    SrcPct = ((TrackedVal / BeforeVal) - 1.0f) * 100.0f;
                    SrcName = GetCleanClassName(WMGRI.PerkUpgradesList[sindex].PerkUpgrade);
                    CurY = DrawSourceLine(PanelX + Pad, CurY, "Perk:" @ SrcName, SrcPct, SrcColor);
                }
            }
            for (si = 0; si < WMPRI.Purchase_SkillUpgrade.Length; ++si)
            {
                sindex = WMPRI.Purchase_SkillUpgrade[si];
                BeforeVal = TrackedVal;
                WMGRI.SkillUpgradesList[sindex].SkillUpgrade.static.ModifyDamageGivenPassive(TrackedVal, WMPRI.GetSkillUpgrade(sindex));
                if (Abs(TrackedVal - BeforeVal) > 0.0001f)
                {
                    SrcPct = ((TrackedVal / BeforeVal) - 1.0f) * 100.0f;
                    SrcName = GetCleanClassName(WMGRI.SkillUpgradesList[sindex].SkillUpgrade);
                    CurY = DrawSourceLine(PanelX + Pad, CurY, "Skill:" @ SrcName, SrcPct, SrcColor);
                }
            }
            for (si = 0; si < WMPRI.Purchase_EquipmentUpgrade.Length; ++si)
            {
                sindex = WMPRI.Purchase_EquipmentUpgrade[si];
                BeforeVal = TrackedVal;
                WMGRI.EquipmentUpgradesList[sindex].EquipmentUpgrade.static.ModifyDamageGivenPassive(TrackedVal, WMPRI.bEquipmentUpgrade[sindex]);
                if (Abs(TrackedVal - BeforeVal) > 0.0001f)
                {
                    SrcPct = ((TrackedVal / BeforeVal) - 1.0f) * 100.0f;
                    SrcName = GetCleanClassName(WMGRI.EquipmentUpgradesList[sindex].EquipmentUpgrade);
                    CurY = DrawSourceLine(PanelX + Pad, CurY, "Equip:" @ SrcName, SrcPct, SrcColor);
                }
            }
            // Roguelike damage bonus
            if (DKPRI != None && DKPRI.GetRoguelikeDamageMult() > 0.001f)
            {
                CurY = DrawSourceLine(PanelX + Pad, CurY, "Roguelike", DKPRI.GetRoguelikeDamageMult() * 100.0f, MakeColorFromRGB(180, 120, 255, 220));
            }
        }
        CurY += LineH;

        // --- Damage (Per-Hit Estimate) ---
        // Simulates the full ModifyDamageGiven pipeline with test value 10000.
        // Passes KFPC as instigator so helper-based perks can resolve.
        // Passes current KFW so weapon-specific checks work.
        // Target-conditional bonuses (headshot, large zed, damage type) won't fire.
        TestDamage = 10000;
        DefaultTestDamage = TestDamage;
        TestDamage = Round(float(DefaultTestDamage) * PassiveDmgFactor);
        if (WMPRI != None && WMGRI != None)
        {
            // Special waves
            for (di = 0; di <= 1; ++di)
            {
                if (WMGRI.SpecialWaveID[di] != INDEX_NONE)
                    WMGRI.SpecialWavesList[WMGRI.SpecialWaveID[di]].SpecialWave.static.ModifyDamageGiven(TestDamage, DefaultTestDamage, None, None, KFPC, None, 0, KFW);
            }
            // Weapon upgrades (weapon-specific, needs isValidWeapon check)
            for (di = 0; di < WMPRI.Purchase_WeaponUpgrade.Length; ++di)
            {
                dindex = WMPRI.Purchase_WeaponUpgrade[di];
                if (WMP.isValidWeapon(WMGRI.WeaponUpgradeSlotsList[dindex].KFWeapon, KFW))
                    WMGRI.WeaponUpgradeSlotsList[dindex].WeaponUpgrade.static.ModifyDamageGiven(TestDamage, DefaultTestDamage, WMPRI.GetWeaponUpgrade(dindex), None, None, KFPC, None, 0, KFW);
            }
            // Perk upgrades
            for (di = 0; di < WMPRI.Purchase_PerkUpgrade.Length; ++di)
            {
                dindex = WMPRI.Purchase_PerkUpgrade[di];
                WMGRI.PerkUpgradesList[dindex].PerkUpgrade.static.ModifyDamageGiven(TestDamage, DefaultTestDamage, WMPRI.bPerkUpgrade[dindex].level, None, None, KFPC, None, 0, KFW);
            }
            // Equipment upgrades
            for (di = 0; di < WMPRI.Purchase_EquipmentUpgrade.Length; ++di)
            {
                dindex = WMPRI.Purchase_EquipmentUpgrade[di];
                WMGRI.EquipmentUpgradesList[dindex].EquipmentUpgrade.static.ModifyDamageGiven(TestDamage, DefaultTestDamage, WMPRI.bEquipmentUpgrade[dindex], None, None, KFPC, None, 0, KFW);
            }
            // Skill upgrades
            for (di = 0; di < WMPRI.Purchase_SkillUpgrade.Length; ++di)
            {
                dindex = WMPRI.Purchase_SkillUpgrade[di];
                WMGRI.SkillUpgradesList[dindex].SkillUpgrade.static.ModifyDamageGiven(TestDamage, DefaultTestDamage, WMPRI.GetSkillUpgrade(dindex), None, None, KFPC, None, 0, KFW);
            }
        }
        DrawStatLine(PanelX + Pad, CurY, "Dmg (Per-Hit)",
            "10000",
            string(TestDamage),
            10000.0f, float(TestDamage), false, LabelColor, GoodColor, BadColor, NeutralColor);

        // Damage Per-Hit source trace
        if (StatOverlayMode == 2 && WMPRI != None && WMGRI != None)
        {
            TrackedVal = float(Round(float(DefaultTestDamage) * PassiveDmgFactor));
            // Special waves
            for (si = 0; si <= 1; ++si)
            {
                if (WMGRI.SpecialWaveID[si] != INDEX_NONE)
                {
                    BeforeInt = int(TrackedVal);
                    BeforeVal = TrackedVal;
                    WMGRI.SpecialWavesList[WMGRI.SpecialWaveID[si]].SpecialWave.static.ModifyDamageGiven(BeforeInt, DefaultTestDamage, None, None, KFPC, None, 0, KFW);
                    TrackedVal = float(BeforeInt);
                    if (Abs(TrackedVal - BeforeVal) > 0.5f)
                    {
                        SrcPct = ((TrackedVal / BeforeVal) - 1.0f) * 100.0f;
                        SrcName = GetCleanClassName(WMGRI.SpecialWavesList[WMGRI.SpecialWaveID[si]].SpecialWave);
                        CurY = DrawSourceLine(PanelX + Pad, CurY, "SW:" @ SrcName, SrcPct, SrcColor);
                    }
                }
            }
            // Weapon upgrades
            for (si = 0; si < WMPRI.Purchase_WeaponUpgrade.Length; ++si)
            {
                sindex = WMPRI.Purchase_WeaponUpgrade[si];
                if (WMP.isValidWeapon(WMGRI.WeaponUpgradeSlotsList[sindex].KFWeapon, KFW))
                {
                    BeforeInt = int(TrackedVal);
                    BeforeVal = TrackedVal;
                    WMGRI.WeaponUpgradeSlotsList[sindex].WeaponUpgrade.static.ModifyDamageGiven(BeforeInt, DefaultTestDamage, WMPRI.GetWeaponUpgrade(sindex), None, None, KFPC, None, 0, KFW);
                    TrackedVal = float(BeforeInt);
                    if (Abs(TrackedVal - BeforeVal) > 0.5f)
                    {
                        SrcPct = ((TrackedVal / BeforeVal) - 1.0f) * 100.0f;
                        SrcName = GetCleanClassName(WMGRI.WeaponUpgradeSlotsList[sindex].WeaponUpgrade);
                        CurY = DrawSourceLine(PanelX + Pad, CurY, "Wpn:" @ SrcName, SrcPct, SrcColor);
                    }
                }
            }
            // Perk upgrades
            for (si = 0; si < WMPRI.Purchase_PerkUpgrade.Length; ++si)
            {
                sindex = WMPRI.Purchase_PerkUpgrade[si];
                BeforeInt = int(TrackedVal);
                BeforeVal = TrackedVal;
                WMGRI.PerkUpgradesList[sindex].PerkUpgrade.static.ModifyDamageGiven(BeforeInt, DefaultTestDamage, WMPRI.bPerkUpgrade[sindex].level, None, None, KFPC, None, 0, KFW);
                TrackedVal = float(BeforeInt);
                if (Abs(TrackedVal - BeforeVal) > 0.5f)
                {
                    SrcPct = ((TrackedVal / BeforeVal) - 1.0f) * 100.0f;
                    SrcName = GetCleanClassName(WMGRI.PerkUpgradesList[sindex].PerkUpgrade);
                    CurY = DrawSourceLine(PanelX + Pad, CurY, "Perk:" @ SrcName, SrcPct, SrcColor);
                }
            }
            // Equipment upgrades
            for (si = 0; si < WMPRI.Purchase_EquipmentUpgrade.Length; ++si)
            {
                sindex = WMPRI.Purchase_EquipmentUpgrade[si];
                BeforeInt = int(TrackedVal);
                BeforeVal = TrackedVal;
                WMGRI.EquipmentUpgradesList[sindex].EquipmentUpgrade.static.ModifyDamageGiven(BeforeInt, DefaultTestDamage, WMPRI.bEquipmentUpgrade[sindex], None, None, KFPC, None, 0, KFW);
                TrackedVal = float(BeforeInt);
                if (Abs(TrackedVal - BeforeVal) > 0.5f)
                {
                    SrcPct = ((TrackedVal / BeforeVal) - 1.0f) * 100.0f;
                    SrcName = GetCleanClassName(WMGRI.EquipmentUpgradesList[sindex].EquipmentUpgrade);
                    CurY = DrawSourceLine(PanelX + Pad, CurY, "Equip:" @ SrcName, SrcPct, SrcColor);
                }
            }
            // Skill upgrades
            for (si = 0; si < WMPRI.Purchase_SkillUpgrade.Length; ++si)
            {
                sindex = WMPRI.Purchase_SkillUpgrade[si];
                BeforeInt = int(TrackedVal);
                BeforeVal = TrackedVal;
                WMGRI.SkillUpgradesList[sindex].SkillUpgrade.static.ModifyDamageGiven(BeforeInt, DefaultTestDamage, WMPRI.GetSkillUpgrade(sindex), None, None, KFPC, None, 0, KFW);
                TrackedVal = float(BeforeInt);
                if (Abs(TrackedVal - BeforeVal) > 0.5f)
                {
                    SrcPct = ((TrackedVal / BeforeVal) - 1.0f) * 100.0f;
                    SrcName = GetCleanClassName(WMGRI.SkillUpgradesList[sindex].SkillUpgrade);
                    CurY = DrawSourceLine(PanelX + Pad, CurY, "Skill:" @ SrcName, SrcPct, SrcColor);
                }
            }
            // Roguelike damage
            if (DKPRI != None && DKPRI.GetRoguelikeDamageMult() > 0.001f)
            {
                CurY = DrawSourceLine(PanelX + Pad, CurY, "Roguelike (Dmg)", DKPRI.GetRoguelikeDamageMult() * 100.0f, MakeColorFromRGB(180, 120, 255, 220));
            }
            if (DKPRI != None && DKPRI.GetRoguelikeLargeZedDamage() > 0.001f)
            {
                CurY = DrawSourceLine(PanelX + Pad, CurY, "Roguelike (LgZed)", DKPRI.GetRoguelikeLargeZedDamage() * 100.0f, MakeColorFromRGB(180, 120, 255, 220));
            }
        }
        CurY += LineH;

    }
    else
    {
        DrawTextWithShadow("WEAPON: None", PanelX + Pad, CurY, LabelColor, 0.8f);
        CurY += LineH;
    }

    // Divider
    CurY += 6;

    // === PLAYER SECTION ===
    DrawTextWithShadow("PLAYER", PanelX + Pad, CurY, HeaderColor, 0.8f);
    CurY += LineH;

    // Health
    DrawTextWithShadow("Health", PanelX + Pad, CurY, LabelColor, 0.75f);
    DrawTextWithShadow(KFPH.Health $ "/" $ KFPH.HealthMax,
        PanelX + Pad + 140, CurY, ValueColor, 0.75f);

        // Health source trace
        if (StatOverlayMode == 2 && DKPRI != None)
        {
            if (DKPRI.GetRoguelikeHealthBonus() != 0)
                CurY = DrawSourceLine(PanelX + Pad, CurY, "Roguelike (+HP)", float(DKPRI.GetRoguelikeHealthBonus()), MakeColorFromRGB(180, 120, 255, 220));
            if (DKPRI.GetRoguelikeHealthPenaltyPct() > 0.001f)
                CurY = DrawSourceLine(PanelX + Pad, CurY, "Roguelike (Glass)", -DKPRI.GetRoguelikeHealthPenaltyPct() * 100.0f, MakeColorFromRGB(255, 100, 100, 220));
        }
    CurY += LineH;

    // Armor (use Zedternal values instead of KF2 native 0-255 display range)
    WMPH = WMPawn_Human(KFPH);
    if (WMPH != None)
    {
        DrawTextWithShadow("Armor", PanelX + Pad, CurY, LabelColor, 0.75f);
        DrawTextWithShadow(WMPH.ZedternalArmor $ "/" $ WMPH.ZedternalMaxArmor,
            PanelX + Pad + 140, CurY, ValueColor, 0.75f);
    }
    else
    {
        DrawTextWithShadow("Armor", PanelX + Pad, CurY, LabelColor, 0.75f);
        DrawTextWithShadow(KFPH.Armor $ "/" $ KFPH.MaxArmor,
            PanelX + Pad + 140, CurY, ValueColor, 0.75f);
    }
    CurY += LineH;

        // Armor source trace
        if (StatOverlayMode == 2 && DKPRI != None && DKPRI.GetRoguelikeArmorBonus() != 0)
        {
            CurY = DrawSourceLine(PanelX + Pad, CurY, "Roguelike (+Armor)", float(DKPRI.GetRoguelikeArmorBonus()), MakeColorFromRGB(180, 120, 255, 220));
        }

    // Movement Speed (call perk's ModifySpeed with base ground speed)
    MoveSpeed = KFPH.default.GroundSpeed;
    WMP.ModifySpeed(MoveSpeed);
    Pct = ((MoveSpeed / KFPH.default.GroundSpeed) - 1.0f) * 100.0f;
    PctStr = FormatPctString(Pct);
    DrawTextWithShadow("Move Speed", PanelX + Pad, CurY, LabelColor, 0.75f);
    DrawTextWithShadow(string(int(KFPH.default.GroundSpeed)) @ ">" @ string(int(MoveSpeed)),
        PanelX + Pad + 140, CurY, ValueColor, 0.75f);
    DrawTextWithShadow(PctStr, PanelX + Pad + 280, CurY,
        (Pct > 0.5f) ? GoodColor : ((Pct < -0.5f) ? BadColor : NeutralColor), 0.75f);
    CurY += LineH;

        // Move Speed source trace
        if (StatOverlayMode == 2 && WMPRI != None && WMGRI != None)
        {
            TrackedVal = KFPH.default.GroundSpeed;
            BeforeVal = TrackedVal;
            TrackedVal *= LocalPassiveMoveSpeed;
            if (Abs(TrackedVal - BeforeVal) > 0.1f)
            {
                SrcPct = ((TrackedVal / BeforeVal) - 1.0f) * 100.0f;
                CurY = DrawSourceLine(PanelX + Pad, CurY, "Perk Passive", SrcPct, SrcColor);
            }
            for (si = 0; si <= 1; ++si)
            {
                if (WMGRI.SpecialWaveID[si] != INDEX_NONE)
                {
                    BeforeVal = TrackedVal;
                    WMGRI.SpecialWavesList[WMGRI.SpecialWaveID[si]].SpecialWave.static.ModifySpeed(TrackedVal, KFPH.default.GroundSpeed, KFPH);
                    if (Abs(TrackedVal - BeforeVal) > 0.1f)
                    {
                        SrcPct = ((TrackedVal / BeforeVal) - 1.0f) * 100.0f;
                        SrcName = GetCleanClassName(WMGRI.SpecialWavesList[WMGRI.SpecialWaveID[si]].SpecialWave);
                        CurY = DrawSourceLine(PanelX + Pad, CurY, "SW:" @ SrcName, SrcPct, SrcColor);
                    }
                }
            }
            for (si = 0; si < WMPRI.Purchase_PerkUpgrade.Length; ++si)
            {
                sindex = WMPRI.Purchase_PerkUpgrade[si];
                BeforeVal = TrackedVal;
                WMGRI.PerkUpgradesList[sindex].PerkUpgrade.static.ModifySpeed(TrackedVal, KFPH.default.GroundSpeed, WMPRI.bPerkUpgrade[sindex].level, KFPH);
                if (Abs(TrackedVal - BeforeVal) > 0.1f)
                {
                    SrcPct = ((TrackedVal / BeforeVal) - 1.0f) * 100.0f;
                    SrcName = GetCleanClassName(WMGRI.PerkUpgradesList[sindex].PerkUpgrade);
                    CurY = DrawSourceLine(PanelX + Pad, CurY, "Perk:" @ SrcName, SrcPct, SrcColor);
                }
            }
            for (si = 0; si < WMPRI.Purchase_EquipmentUpgrade.Length; ++si)
            {
                sindex = WMPRI.Purchase_EquipmentUpgrade[si];
                BeforeVal = TrackedVal;
                WMGRI.EquipmentUpgradesList[sindex].EquipmentUpgrade.static.ModifySpeed(TrackedVal, KFPH.default.GroundSpeed, WMPRI.bEquipmentUpgrade[sindex], KFPH);
                if (Abs(TrackedVal - BeforeVal) > 0.1f)
                {
                    SrcPct = ((TrackedVal / BeforeVal) - 1.0f) * 100.0f;
                    SrcName = GetCleanClassName(WMGRI.EquipmentUpgradesList[sindex].EquipmentUpgrade);
                    CurY = DrawSourceLine(PanelX + Pad, CurY, "Equip:" @ SrcName, SrcPct, SrcColor);
                }
            }
            for (si = 0; si < WMPRI.Purchase_SkillUpgrade.Length; ++si)
            {
                sindex = WMPRI.Purchase_SkillUpgrade[si];
                BeforeVal = TrackedVal;
                WMGRI.SkillUpgradesList[sindex].SkillUpgrade.static.ModifySpeed(TrackedVal, KFPH.default.GroundSpeed, WMPRI.GetSkillUpgrade(sindex), KFPH);
                if (Abs(TrackedVal - BeforeVal) > 0.1f)
                {
                    SrcPct = ((TrackedVal / BeforeVal) - 1.0f) * 100.0f;
                    SrcName = GetCleanClassName(WMGRI.SkillUpgradesList[sindex].SkillUpgrade);
                    CurY = DrawSourceLine(PanelX + Pad, CurY, "Skill:" @ SrcName, SrcPct, SrcColor);
                }
            }
            // Roguelike speed bonus/penalty
            if (DKPRI != None)
            {
                if (DKPRI.GetRoguelikeSpeedMult() > 0.001f)
                    CurY = DrawSourceLine(PanelX + Pad, CurY, "Roguelike (+Spd)", DKPRI.GetRoguelikeSpeedMult() * 100.0f, MakeColorFromRGB(180, 120, 255, 220));
                if (DKPRI.GetRoguelikeSpeedPenaltyPct() > 0.001f)
                    CurY = DrawSourceLine(PanelX + Pad, CurY, "Roguelike (Sumo)", -DKPRI.GetRoguelikeSpeedPenaltyPct() * 100.0f, MakeColorFromRGB(255, 100, 100, 220));
            }
        }

    // Actual pawn ground speed (runtime)
    DrawTextWithShadow("Ground Spd", PanelX + Pad, CurY, LabelColor, 0.75f);
    DrawTextWithShadow(string(int(KFPH.GroundSpeed)) @ "u/s",
        PanelX + Pad + 140, CurY, ValueColor, 0.75f);
    CurY += LineH;

    // Weight
    if (KFInventoryManager(KFPH.InvManager) != None)
    {
        DrawTextWithShadow("Weight", PanelX + Pad, CurY, LabelColor, 0.75f);
        DrawTextWithShadow(
            string(KFInventoryManager(KFPH.InvManager).CurrentCarryBlocks) $ "/" $
            string(KFInventoryManager(KFPH.InvManager).MaxCarryBlocks),
            PanelX + Pad + 140, CurY, ValueColor, 0.75f);
        CurY += LineH;
    }

    // Divider
    CurY += 6;

    // === SHAPESHIFTER BUFF STATUS ===
    // Try to find a Shapeshifter helper on the local pawn
    SSHelper = class'ZTUpgrade_Perk_Shapeshifter'.static.GetHelper(KFPH);
    if (SSHelper != None)
    {
        DrawTextWithShadow("SHAPESHIFTER BUFFS", PanelX + Pad, CurY, HeaderColor, 0.8f);
        CurY += LineH;

        SSLevel = SSHelper.CurrentPerkLevel;
        DrawTextWithShadow("Perk Level:" @ string(SSLevel), PanelX + Pad, CurY, LabelColor, 0.75f);
        CurY += LineH;

        // Show each active buff as a stat line with computed value
        // --- Offense ---
        if (SSHelper.IsBuffActive(0))
        {
            BuffStatusStr = "+" $ string(int(class'ZTUpgrade_Perk_Shapeshifter'.default.Buff_Carnage_PerLevel * SSLevel * 100)) $ "% all damage";
            DrawTextWithShadow("Carnage", PanelX + Pad, CurY, LabelColor, 0.7f);
            DrawTextWithShadow(BuffStatusStr, PanelX + Pad + 140, CurY, ActiveColor, 0.7f);
            CurY += LineH;
        }
        if (SSHelper.IsBuffActive(1))
        {
            BuffStatusStr = "+" $ string(int(class'ZTUpgrade_Perk_Shapeshifter'.default.Buff_Executioner_PerLevel * SSLevel * 100)) $ "% headshot dmg";
            DrawTextWithShadow("Executioner", PanelX + Pad, CurY, LabelColor, 0.7f);
            DrawTextWithShadow(BuffStatusStr, PanelX + Pad + 140, CurY, ActiveColor, 0.7f);
            CurY += LineH;
        }
        if (SSHelper.IsBuffActive(2))
        {
            BuffStatusStr = "+" $ string(int(class'ZTUpgrade_Perk_Shapeshifter'.default.Buff_Rampage_PerLevel * SSLevel * 100)) $ "% fire rate";
            DrawTextWithShadow("Rampage", PanelX + Pad, CurY, LabelColor, 0.7f);
            DrawTextWithShadow(BuffStatusStr, PanelX + Pad + 140, CurY, ActiveColor, 0.7f);
            CurY += LineH;
        }
        if (SSHelper.IsBuffActive(3))
        {
            BuffStatusStr = "+" $ string(int(class'ZTUpgrade_Perk_Shapeshifter'.default.Buff_Crusher_PerLevel * SSLevel * 100)) $ "% heavy melee";
            DrawTextWithShadow("Crusher", PanelX + Pad, CurY, LabelColor, 0.7f);
            DrawTextWithShadow(BuffStatusStr, PanelX + Pad + 140, CurY, ActiveColor, 0.7f);
            CurY += LineH;
        }
        if (SSHelper.IsBuffActive(4))
        {
            BuffStatusStr = "+" $ string(int(class'ZTUpgrade_Perk_Shapeshifter'.default.Buff_Berserker_PerLevel * SSLevel * 100)) $ "% melee speed";
            DrawTextWithShadow("Berserker", PanelX + Pad, CurY, LabelColor, 0.7f);
            DrawTextWithShadow(BuffStatusStr, PanelX + Pad + 140, CurY, ActiveColor, 0.7f);
            CurY += LineH;
        }

        // --- Defense ---
        if (SSHelper.IsBuffActive(5))
        {
            BuffStatusStr = "-" $ string(int(class'ZTUpgrade_Perk_Shapeshifter'.default.Buff_Fortress_PerLevel * SSLevel * 100)) $ "% dmg taken";
            DrawTextWithShadow("Fortress", PanelX + Pad, CurY, LabelColor, 0.7f);
            DrawTextWithShadow(BuffStatusStr, PanelX + Pad + 140, CurY, MakeColorFromRGB(100, 180, 255, 255), 0.7f);
            CurY += LineH;
        }
        if (SSHelper.IsBuffActive(6))
        {
            BuffStatusStr = "+" $ string(class'ZTUpgrade_Perk_Shapeshifter'.default.Buff_Leech_PerLevel * SSLevel) $ " HP on kill";
            DrawTextWithShadow("Leech", PanelX + Pad, CurY, LabelColor, 0.7f);
            DrawTextWithShadow(BuffStatusStr, PanelX + Pad + 140, CurY, MakeColorFromRGB(100, 180, 255, 255), 0.7f);
            CurY += LineH;
        }

        // --- Handling ---
        if (SSHelper.IsBuffActive(7))
        {
            BuffStatusStr = "-" $ string(int(class'ZTUpgrade_Perk_Shapeshifter'.default.Buff_Anchor_PerLevel * SSLevel * 100)) $ "% recoil";
            DrawTextWithShadow("Anchor", PanelX + Pad, CurY, LabelColor, 0.7f);
            DrawTextWithShadow(BuffStatusStr, PanelX + Pad + 140, CurY, MakeColorFromRGB(255, 200, 100, 255), 0.7f);
            CurY += LineH;
        }
        if (SSHelper.IsBuffActive(8))
        {
            BuffStatusStr = "-" $ string(int(class'ZTUpgrade_Perk_Shapeshifter'.default.Buff_Hawk_PerLevel * SSLevel * 100)) $ "% spread";
            DrawTextWithShadow("Hawk", PanelX + Pad, CurY, LabelColor, 0.7f);
            DrawTextWithShadow(BuffStatusStr, PanelX + Pad + 140, CurY, MakeColorFromRGB(255, 200, 100, 255), 0.7f);
            CurY += LineH;
        }
        if (SSHelper.IsBuffActive(9))
        {
            BuffStatusStr = "+" $ string(int(class'ZTUpgrade_Perk_Shapeshifter'.default.Buff_Speedloader_PerLevel * SSLevel * 100)) $ "% reload spd";
            DrawTextWithShadow("Speedloader", PanelX + Pad, CurY, LabelColor, 0.7f);
            DrawTextWithShadow(BuffStatusStr, PanelX + Pad + 140, CurY, MakeColorFromRGB(255, 200, 100, 255), 0.7f);
            CurY += LineH;
        }
        if (SSHelper.IsBuffActive(10))
        {
            BuffStatusStr = "+" $ string(int(class'ZTUpgrade_Perk_Shapeshifter'.default.Buff_Switchblade_PerLevel * SSLevel * 100)) $ "% switch spd";
            DrawTextWithShadow("Switchblade", PanelX + Pad, CurY, LabelColor, 0.7f);
            DrawTextWithShadow(BuffStatusStr, PanelX + Pad + 140, CurY, MakeColorFromRGB(255, 200, 100, 255), 0.7f);
            CurY += LineH;
        }

        // --- Utility ---
        if (SSHelper.IsBuffActive(11))
        {
            BuffStatusStr = "+" $ string(int(class'ZTUpgrade_Perk_Shapeshifter'.default.Buff_Speedfreak_PerLevel * SSLevel * 100)) $ "% move speed";
            DrawTextWithShadow("Speedfreak", PanelX + Pad, CurY, LabelColor, 0.7f);
            DrawTextWithShadow(BuffStatusStr, PanelX + Pad + 140, CurY, MakeColorFromRGB(180, 255, 180, 255), 0.7f);
            CurY += LineH;
        }
        if (SSHelper.IsBuffActive(12))
        {
            BuffStatusStr = "+" $ string(int(class'ZTUpgrade_Perk_Shapeshifter'.default.Buff_Hoarder_PerLevel * SSLevel * 100)) $ "% spare ammo";
            DrawTextWithShadow("Hoarder", PanelX + Pad, CurY, LabelColor, 0.7f);
            DrawTextWithShadow(BuffStatusStr, PanelX + Pad + 140, CurY, MakeColorFromRGB(180, 255, 180, 255), 0.7f);
            CurY += LineH;
        }
        if (SSHelper.IsBuffActive(13))
        {
            BuffStatusStr = "+" $ string(int(class'ZTUpgrade_Perk_Shapeshifter'.default.Buff_Drumfire_PerLevel * SSLevel * 100)) $ "% mag size";
            DrawTextWithShadow("Drumfire", PanelX + Pad, CurY, LabelColor, 0.7f);
            DrawTextWithShadow(BuffStatusStr, PanelX + Pad + 140, CurY, MakeColorFromRGB(180, 255, 180, 255), 0.7f);
            CurY += LineH;
        }
        if (SSHelper.IsBuffActive(14))
        {
            BuffStatusStr = "+" $ string(int(class'ZTUpgrade_Perk_Shapeshifter'.default.Buff_Phantom_PerLevel * SSLevel * 100)) $ "% ZED fire rate";
            DrawTextWithShadow("Phantom", PanelX + Pad, CurY, LabelColor, 0.7f);
            DrawTextWithShadow(BuffStatusStr, PanelX + Pad + 140, CurY, MakeColorFromRGB(180, 255, 180, 255), 0.7f);
            CurY += LineH;
        }

        // Mimicry status + buff mask debug
        CurY += 4;
        DrawTextWithShadow("Mask:" @ string(SSHelper.ReplicatedBuffMask), PanelX + Pad, CurY, InactiveColor, 0.7f);
        if (SSHelper.bMimicryActive)
        {
            DrawTextWithShadow("MIMICRY" @ SSHelper.MimicryStackCount $ "/15", PanelX + Pad + 140, CurY, MakeColorFromRGB(255, 160, 0, 255), 0.75f);
        }
        CurY += LineH;
    }

    // === ROGUELIKE STATS (Sources mode only) ===
    if (StatOverlayMode == 2 && DKPRI != None && DKPRI.GetTotalRoguelikeUpgrades() > 0)
    {
        CurY += 6;
        DrawTextWithShadow("ROGUELIKE BUFFS (" $ string(DKPRI.GetTotalRoguelikeUpgrades()) $ " upgrades)", PanelX + Pad, CurY, MakeColorFromRGB(180, 120, 255, 255), 0.8f);
        CurY += LineH;

        if (DKPRI.GetRoguelikeDamageMult() > 0.001f)
        {
            DrawTextWithShadow("  Damage", PanelX + Pad, CurY, LabelColor, 0.65f);
            DrawTextWithShadow("+" $ FormatFloat2(DKPRI.GetRoguelikeDamageMult() * 100.0f) $ "%", PanelX + Pad + 180, CurY, GoodColor, 0.65f);
            CurY += 15;
        }
        if (DKPRI.GetRoguelikeDamageResist() > 0.001f)
        {
            DrawTextWithShadow("  Resist", PanelX + Pad, CurY, LabelColor, 0.65f);
            DrawTextWithShadow("+" $ FormatFloat2(DKPRI.GetRoguelikeDamageResist() * 100.0f) $ "%", PanelX + Pad + 180, CurY, GoodColor, 0.65f);
            CurY += 15;
        }
        if (DKPRI.GetRoguelikeLargeZedDamage() > 0.001f)
        {
            DrawTextWithShadow("  Large Zed", PanelX + Pad, CurY, LabelColor, 0.65f);
            DrawTextWithShadow("+" $ FormatFloat2(DKPRI.GetRoguelikeLargeZedDamage() * 100.0f) $ "%", PanelX + Pad + 180, CurY, GoodColor, 0.65f);
            CurY += 15;
        }
        if (DKPRI.GetRoguelikeOpportunistDamage() > 0.001f)
        {
            DrawTextWithShadow("  Opportunist", PanelX + Pad, CurY, LabelColor, 0.65f);
            DrawTextWithShadow("+" $ FormatFloat2(DKPRI.GetRoguelikeOpportunistDamage() * 100.0f) $ "%", PanelX + Pad + 180, CurY, GoodColor, 0.65f);
            CurY += 15;
        }
        if (DKPRI.GetRoguelikeDuelistDamage() > 0.001f)
        {
            DrawTextWithShadow("  Duelist", PanelX + Pad, CurY, LabelColor, 0.65f);
            DrawTextWithShadow("+" $ FormatFloat2(DKPRI.GetRoguelikeDuelistDamage() * 100.0f) $ "%", PanelX + Pad + 180, CurY, GoodColor, 0.65f);
            CurY += 15;
        }
        if (DKPRI.GetRoguelikeLastRoundDamage() > 0.001f)
        {
            DrawTextWithShadow("  Last Round", PanelX + Pad, CurY, LabelColor, 0.65f);
            DrawTextWithShadow("+" $ FormatFloat2(DKPRI.GetRoguelikeLastRoundDamage() * 100.0f) $ "%", PanelX + Pad + 180, CurY, GoodColor, 0.65f);
            CurY += 15;
        }
        if (DKPRI.GetRoguelikeLuck() > 0.001f)
        {
            DrawTextWithShadow("  Luck", PanelX + Pad, CurY, LabelColor, 0.65f);
            DrawTextWithShadow("+" $ FormatFloat2(DKPRI.GetRoguelikeLuck() * 100.0f) $ "%", PanelX + Pad + 180, CurY, MakeColorFromRGB(255, 215, 0, 220), 0.65f);
            CurY += 15;
        }
        if (DKPRI.GetRoguelikeWaveStartDosh() > 0)
        {
            DrawTextWithShadow("  Wealthy", PanelX + Pad, CurY, LabelColor, 0.65f);
            DrawTextWithShadow("+" $ string(DKPRI.GetRoguelikeWaveStartDosh()) @ "dosh/wave", PanelX + Pad + 180, CurY, MakeColorFromRGB(255, 215, 0, 220), 0.65f);
            CurY += 15;
        }
    }
}

/** Draw a single stat comparison line: Label   Default > Modified   +XX% */
simulated function DrawStatLine(
    float X, float Y,
    string Label, string DefaultStr, string ModifiedStr,
    float DefaultVal, float ModifiedVal, bool bLowerIsBetter,
    Color LblColor, Color GoodCol, Color BadCol, Color NeutralCol)
{
    local float Pct;
    local string PctStr;
    local Color PctColor;

    Pct = (DefaultVal != 0.0f) ? ((ModifiedVal / DefaultVal) - 1.0f) * 100.0f : 0.0f;
    PctStr = FormatPctString(Pct);

    // Determine color based on whether lower or higher is better
    if (Abs(Pct) < 0.5f)
        PctColor = NeutralCol;
    else if (bLowerIsBetter)
        PctColor = (Pct < 0.0f) ? GoodCol : BadCol;
    else
        PctColor = (Pct > 0.0f) ? GoodCol : BadCol;

    DrawTextWithShadow(Label, X, Y, LblColor, 0.75f);
    DrawTextWithShadow(DefaultStr @ ">" @ ModifiedStr, X + 140, Y, MakeColorFromRGB(255, 255, 255, 255), 0.75f);
    DrawTextWithShadow(PctStr, X + 280, Y, PctColor, 0.75f);
}

/** Format a float to 3 decimal places. */
simulated function string FormatFloat3(float Value)
{
    local int Whole, Frac;
    Whole = int(Value);
    Frac = int((Value - float(Whole)) * 1000.0f + 0.5f);
    if (Frac >= 1000) { Whole += 1; Frac -= 1000; }
    if (Frac < 10)
        return string(Whole) $ ".00" $ string(Frac);
    else if (Frac < 100)
        return string(Whole) $ ".0" $ string(Frac);
    else
        return string(Whole) $ "." $ string(Frac);
}

/** Format a float to 2 decimal places. */
simulated function string FormatFloat2(float Value)
{
    local int Whole, Frac;
    Whole = int(Value);
    Frac = int((Value - float(Whole)) * 100.0f + 0.5f);
    if (Frac >= 100) { Whole += 1; Frac -= 100; }
    if (Frac < 10)
        return string(Whole) $ ".0" $ string(Frac);
    else
        return string(Whole) $ "." $ string(Frac);
}

/** Format a percentage: +12.3% or -5.0% */
simulated function string FormatPctString(float Pct)
{
    local string Sign;
    local int WholePct, FracPct;

    if (Abs(Pct) < 0.5f)
        return "---";

    if (Pct > 0)
        Sign = "+";
    else
    {
        Sign = "-";
        Pct = -Pct;
    }

    WholePct = int(Pct);
    FracPct = int((Pct - float(WholePct)) * 10.0f + 0.5f);
    if (FracPct >= 10) { WholePct += 1; FracPct -= 10; }

    return Sign $ string(WholePct) $ "." $ string(FracPct) $ "%";
}

/** Draw an indented source attribution line. Returns the new Y position. */
simulated function float DrawSourceLine(float X, float Y, string SourceName, float DeltaPct, Color SrcColor)
{
    local string PctStr;
    if (Abs(DeltaPct) < 0.05f)
        return Y;
    PctStr = FormatPctString(DeltaPct);
    DrawTextWithShadow("  " $ SourceName, X + 10, Y, SrcColor, 0.65f);
    DrawTextWithShadow(PctStr, X + 240, Y, SrcColor, 0.65f);
    return Y + 15.0f;
}

/** Extract a clean display name from an upgrade or special wave class. */
simulated function string GetCleanClassName(class InClass)
{
    local string ClsName;
    if (InClass == None)
        return "???";
    ClsName = string(InClass.Name);
    ClsName = Repl(ClsName, "ZTUpgrade_Perk_", "");
    ClsName = Repl(ClsName, "ZTUpgrade_Skill_", "");
    ClsName = Repl(ClsName, "WMUpgrade_Perk_", "");
    ClsName = Repl(ClsName, "WMUpgrade_Skill_", "");
    ClsName = Repl(ClsName, "WMUpgrade_Equipment_", "");
    ClsName = Repl(ClsName, "WMUpgrade_Weapon_", "");
    ClsName = Repl(ClsName, "WMSpecialWave_", "");
    ClsName = Repl(ClsName, "DKSpecialWave_", "");
    return ClsName;
}

function UpdateHydeDisplay(byte InState, float InDuration, int InCharges, int InMaxCharges)
{
    HydeDisplay.bIsActive = true;
    HydeDisplay.State = InState;
    HydeDisplay.Duration = InDuration;
    HydeDisplay.EndTime = WorldInfo.TimeSeconds + InDuration;
    HydeDisplay.Charges = InCharges;
    HydeDisplay.MaxCharges = InMaxCharges;
}

function ClearHydeDisplay()
{
    HydeDisplay.bIsActive = false;
}

function float GetHydeCardHeight()
{
    local float PadY, BarH, GapTB, GapBT;
    local float TitleH, ChargeH, ReadyH, XL;

    if (!HydeDisplay.bIsActive || Canvas == None)
        return 0.0f;

    PadY  = 8.0f  * ResScale;
    BarH  = 14.0f * ResScale;
    GapTB = 6.0f  * ResScale;
    GapBT = 8.0f  * ResScale;

    // Height is derived from real font metrics (TextSize) so the box always
    // contains its text at any font/resolution. Fixed line heights
    // under-budgeted the KF canvas font and clipped the bottom line.
    Canvas.Font = class'KFGameEngine'.Static.GetKFCanvasFont();

    if (HydeDisplay.State == 2)
    {
        Canvas.TextSize("MR. HYDE", XL, TitleH, 0.9f * ResScale, 0.9f * ResScale);
        Canvas.TextSize("Serum:0/0", XL, ChargeH, 0.8f * ResScale, 0.8f * ResScale);
        return PadY + TitleH + GapTB + BarH + GapBT + ChargeH + PadY;
    }

    Canvas.TextSize("HYDE SERUM", XL, ReadyH, 0.85f * ResScale, 0.85f * ResScale);
    return PadY + ReadyH + PadY;
}

function DrawHydeDisplay()
{
    local float BoxX, BoxY, BoxW, BoxH, PadX, PadY;
    local float BarH, GapTB, GapBT;
    local float TitleH, XL, CurY;
    local float BarX, BarY, BarW, Frac;
    local Color TitleColor, TextColor, BarBack, BarFillC;
    local string ChargeStr;

    if (Canvas == None)
        return;

    PadX  = 12.0f * ResScale;
    PadY  = 8.0f  * ResScale;
    BarH  = 14.0f * ResScale;
    GapTB = 6.0f  * ResScale;   // gap title -> bar
    GapBT = 8.0f  * ResScale;   // gap bar -> charge text
    BoxW  = 300.0f * ResScale;

    // Position from the card-stack system (no longer fixed to the top slot)
    BoxX = Canvas.SizeX * DisplayCardBaseX;
    BoxY = Canvas.SizeY * GetDisplayCardY(CARD_HYDE);
    BoxH = GetHydeCardHeight();

    TitleColor = MakeColorFromRGB(220, 40, 40, 255);
    TextColor  = MakeColorFromRGB(230, 210, 210, 255);

    Canvas.Font = class'KFGameEngine'.Static.GetKFCanvasFont();
    ChargeStr = "Serum:" @ HydeDisplay.Charges $ "/" $ HydeDisplay.MaxCharges;

    if (HydeDisplay.State == 2)
    {
        // Measure the real title height so the bar/charge never overlap it.
        Canvas.TextSize("MR. HYDE", XL, TitleH, 0.9f * ResScale, 0.9f * ResScale);

        // --- Transformed: draining red meter ---
        Canvas.SetDrawColor(0, 0, 0, 170);
        Canvas.SetPos(BoxX, BoxY);
        Canvas.DrawRect(BoxW, BoxH);

        Canvas.SetDrawColor(170, 20, 20, 220);
        Canvas.SetPos(BoxX, BoxY);                          Canvas.DrawRect(BoxW, 2.0f * ResScale);
        Canvas.SetPos(BoxX, BoxY + BoxH - 2.0f * ResScale); Canvas.DrawRect(BoxW, 2.0f * ResScale);
        Canvas.SetPos(BoxX, BoxY);                          Canvas.DrawRect(2.0f * ResScale, BoxH);
        Canvas.SetPos(BoxX + BoxW - 2.0f * ResScale, BoxY); Canvas.DrawRect(2.0f * ResScale, BoxH);

        CurY = BoxY + PadY;
        DrawTextWithShadow("MR. HYDE", BoxX + PadX, CurY, TitleColor, 0.9f * ResScale);
        CurY += TitleH + GapTB;

        Frac = 0.0f;
        if (HydeDisplay.Duration > 0.0f)
            Frac = (HydeDisplay.EndTime - WorldInfo.TimeSeconds) / HydeDisplay.Duration;
        Frac = FClamp(Frac, 0.0f, 1.0f);

        BarX = BoxX + PadX;
        BarY = CurY;
        BarW = BoxW - PadX * 2.0f;

        BarBack = MakeColorFromRGB(40, 10, 10, 200);
        Canvas.SetDrawColor(BarBack.R, BarBack.G, BarBack.B, BarBack.A);
        Canvas.SetPos(BarX, BarY);
        Canvas.DrawRect(BarW, BarH);

        BarFillC = MakeColorFromRGB(230, 40, 40, 235);
        Canvas.SetDrawColor(BarFillC.R, BarFillC.G, BarFillC.B, BarFillC.A);
        Canvas.SetPos(BarX, BarY);
        Canvas.DrawRect(BarW * Frac, BarH);

        CurY += BarH + GapBT;
        DrawTextWithShadow(ChargeStr, BoxX + PadX, CurY, TextColor, 0.8f * ResScale);
    }
    else
    {
        // --- Ready (Jekyll): slim charges readout ---
        Canvas.SetDrawColor(0, 0, 0, 140);
        Canvas.SetPos(BoxX, BoxY);
        Canvas.DrawRect(BoxW, BoxH);

        Canvas.SetDrawColor(170, 20, 20, 180);
        Canvas.SetPos(BoxX, BoxY);                          Canvas.DrawRect(BoxW, 2.0f * ResScale);
        Canvas.SetPos(BoxX, BoxY + BoxH - 2.0f * ResScale); Canvas.DrawRect(BoxW, 2.0f * ResScale);

        DrawTextWithShadow("HYDE SERUM   " $ ChargeStr, BoxX + PadX, BoxY + PadY, TitleColor, 0.85f * ResScale);
    }
}

// ===================================================================
// DOMAIN CARD
// ===================================================================

function UpdateDomainDisplay(byte InState, float InDuration)
{
    DomainDisplay.bIsActive = true;
    DomainDisplay.State = InState;
    DomainDisplay.Duration = InDuration;
    DomainDisplay.EndTime = WorldInfo.TimeSeconds + InDuration;
}

function ClearDomainDisplay()
{
    DomainDisplay.bIsActive = false;
}

// Box width is measured from the real strings (at the real scales) so text can
// never protrude, at any resolution or font. Every state is measured so the
// card keeps one constant width and does not jump when its state changes. The
// FMax floor only ever widens past the text, never clips it.
function float GetDomainCardWidth()
{
    local float PadX, MinW, MaxTextW, XL, YL;

    if (Canvas == None)
        return 300.0f * ResScale;

    PadX = 12.0f * ResScale;
    MinW = 200.0f * ResScale;

    Canvas.Font = class'KFGameEngine'.Static.GetKFCanvasFont();

    MaxTextW = 0.0f;

    Canvas.TextSize("DOMAIN   READY", XL, YL, 0.85f * ResScale, 0.85f * ResScale);
    if (XL > MaxTextW)
        MaxTextW = XL;

    Canvas.TextSize("DOMAIN", XL, YL, 0.9f * ResScale, 0.9f * ResScale);
    if (XL > MaxTextW)
        MaxTextW = XL;

    // Widest plausible info line: longer label, double space, 3-digit timer.
    Canvas.TextSize("Cooldown  000s", XL, YL, 0.8f * ResScale, 0.8f * ResScale);
    if (XL > MaxTextW)
        MaxTextW = XL;

    return FMax(MinW, PadX + MaxTextW + PadX);
}

function float GetDomainCardHeight()
{
    local float PadY, BarH, GapTB, GapBT;
    local float TitleH, InfoH, ReadyH, XL;

    if (!DomainDisplay.bIsActive || Canvas == None)
        return 0.0f;

    PadY  = 8.0f  * ResScale;
    BarH  = 14.0f * ResScale;
    GapTB = 6.0f  * ResScale;
    GapBT = 8.0f  * ResScale;

    Canvas.Font = class'KFGameEngine'.Static.GetKFCanvasFont();

    // Ready: slim single-line readout.
    if (DomainDisplay.State == 0)
    {
        Canvas.TextSize("DOMAIN   READY", XL, ReadyH, 0.85f * ResScale, 0.85f * ResScale);
        return PadY + ReadyH + PadY;
    }

    // Active / Cooldown: title + bar + info line.
    Canvas.TextSize("DOMAIN", XL, TitleH, 0.9f * ResScale, 0.9f * ResScale);
    Canvas.TextSize("Cooldown 00s", XL, InfoH, 0.8f * ResScale, 0.8f * ResScale);
    return PadY + TitleH + GapTB + BarH + GapBT + InfoH + PadY;
}

function DrawDomainDisplay()
{
    local float BoxX, BoxY, BoxW, BoxH, PadX, PadY;
    local float BarH, GapTB, GapBT;
    local float TitleH, XL, CurY;
    local float BarX, BarY, BarW, Frac, Remain;
    local Color TitleColor, TextColor, BarBack, BarFillC, BorderC;
    local string InfoStr;

    if (Canvas == None)
        return;

    PadX  = 12.0f * ResScale;
    PadY  = 8.0f  * ResScale;
    BarH  = 14.0f * ResScale;
    GapTB = 6.0f  * ResScale;
    GapBT = 8.0f  * ResScale;
    BoxW  = GetDomainCardWidth();

    // Right-anchor to where a standard 300-wide card's right edge sits, so the
    // (narrower, measured-width) Domain card lines up flush-right with the rest
    // of the card stack instead of floating toward the middle.
    BoxX = (Canvas.SizeX * DisplayCardBaseX) + (300.0f * ResScale) - BoxW;
    BoxY = Canvas.SizeY * GetDisplayCardY(CARD_DOMAIN);
    BoxH = GetDomainCardHeight();

    TitleColor = MakeColorFromRGB(21, 215, 250, 255);   // domain cyan
    TextColor  = MakeColorFromRGB(220, 230, 235, 255);

    Canvas.Font = class'KFGameEngine'.Static.GetKFCanvasFont();

    // --- Ready: slim cyan readout ---
    if (DomainDisplay.State == 0)
    {
        Canvas.SetDrawColor(0, 0, 0, 140);
        Canvas.SetPos(BoxX, BoxY);
        Canvas.DrawRect(BoxW, BoxH);

        Canvas.SetDrawColor(21, 160, 200, 180);
        Canvas.SetPos(BoxX, BoxY);                          Canvas.DrawRect(BoxW, 2.0f * ResScale);
        Canvas.SetPos(BoxX, BoxY + BoxH - 2.0f * ResScale); Canvas.DrawRect(BoxW, 2.0f * ResScale);

        DrawTextWithShadow("DOMAIN   READY", BoxX + PadX, BoxY + PadY, TitleColor, 0.85f * ResScale);
        return;
    }

    // --- Active or Cooldown: title + draining bar + info ---
    Remain = DomainDisplay.EndTime - WorldInfo.TimeSeconds;
    if (Remain < 0.0f)
        Remain = 0.0f;

    Frac = 0.0f;
    if (DomainDisplay.Duration > 0.0f)
        Frac = Remain / DomainDisplay.Duration;
    Frac = FClamp(Frac, 0.0f, 1.0f);

    if (DomainDisplay.State == 1)
    {
        // Active: room duration draining (green)
        BarBack  = MakeColorFromRGB(10, 40, 30, 200);
        BarFillC = MakeColorFromRGB(40, 220, 120, 235);
        BorderC  = MakeColorFromRGB(40, 200, 120, 220);
        InfoStr  = "Active  " $ int(Remain + 0.99f) $ "s";
    }
    else
    {
        // Cooldown: recharge draining (orange)
        BarBack  = MakeColorFromRGB(40, 25, 10, 200);
        BarFillC = MakeColorFromRGB(240, 150, 40, 235);
        BorderC  = MakeColorFromRGB(210, 130, 40, 220);
        InfoStr  = "Cooldown  " $ int(Remain + 0.99f) $ "s";
    }

    Canvas.TextSize("DOMAIN", XL, TitleH, 0.9f * ResScale, 0.9f * ResScale);

    // Background
    Canvas.SetDrawColor(0, 0, 0, 170);
    Canvas.SetPos(BoxX, BoxY);
    Canvas.DrawRect(BoxW, BoxH);

    // Border
    Canvas.SetDrawColor(BorderC.R, BorderC.G, BorderC.B, BorderC.A);
    Canvas.SetPos(BoxX, BoxY);                          Canvas.DrawRect(BoxW, 2.0f * ResScale);
    Canvas.SetPos(BoxX, BoxY + BoxH - 2.0f * ResScale); Canvas.DrawRect(BoxW, 2.0f * ResScale);
    Canvas.SetPos(BoxX, BoxY);                          Canvas.DrawRect(2.0f * ResScale, BoxH);
    Canvas.SetPos(BoxX + BoxW - 2.0f * ResScale, BoxY); Canvas.DrawRect(2.0f * ResScale, BoxH);

    CurY = BoxY + PadY;
    DrawTextWithShadow("DOMAIN", BoxX + PadX, CurY, TitleColor, 0.9f * ResScale);
    CurY += TitleH + GapTB;

    BarX = BoxX + PadX;
    BarY = CurY;
    BarW = BoxW - PadX * 2.0f;

    Canvas.SetDrawColor(BarBack.R, BarBack.G, BarBack.B, BarBack.A);
    Canvas.SetPos(BarX, BarY);
    Canvas.DrawRect(BarW, BarH);

    Canvas.SetDrawColor(BarFillC.R, BarFillC.G, BarFillC.B, BarFillC.A);
    Canvas.SetPos(BarX, BarY);
    Canvas.DrawRect(BarW * Frac, BarH);

    CurY += BarH + GapBT;
    DrawTextWithShadow(InfoStr, BoxX + PadX, CurY, TextColor, 0.8f * ResScale);
}

static function ZTHudWrapper GetReaperHUD(PlayerController PC)
{
    if (PC != None && PC.myHUD != None)
        return ZTHudWrapper(PC.myHUD);
    return None;
}

static function Color MakeColorFromRGB(int R, int G, int B, optional int A = 255)
{
    local Color NewColor;
    NewColor.R = R;
    NewColor.G = G;
    NewColor.B = B;
    NewColor.A = A;
    return NewColor;
}

// ===================================================================
// CINDER TRACKER RENDERING
// ===================================================================



// ===================================================================
// THE WATCHER - Easter Egg System Functions
// ===================================================================

function InitializeWatcherSystem()
{
    WatcherState.bIsActive = false;
    WatcherState.CurrentStage = 0;
    WatcherState.VignetteIntensity = 0.0f;
    WatcherState.StaticIntensity = 0.0f;
    WatcherState.bShowSubliminal = false;
    WatcherState.SubliminalTimer = 0.0f;
    WatcherState.SubliminalText = "";
    WatcherState.SubliminalPosX = 0.5f;
    WatcherState.SubliminalPosY = 0.5f;
    WatcherState.bScreenDim = false;
    WatcherState.DimTimer = 0.0f;
    WatcherState.bColorInvert = false;
    WatcherState.InvertTimer = 0.0f;
    WatcherState.ScanLineY = 0.0f;
    WatcherState.bShowScanLine = false;
    WatcherState.HeartbeatTimer = 0.0f;
    WatcherState.AmbientTimer = 0.0f;
    
    WatcherEyeColorOuter = MakeColorFromRGB(80, 0, 0, 255);
    WatcherEyeColorSclera = MakeColorFromRGB(220, 200, 200, 255);
    WatcherEyeColorIris = MakeColorFromRGB(150, 0, 0, 255);
    WatcherEyeColorPupil = MakeColorFromRGB(0, 0, 0, 255);
    
    WatcherSubliminalMessages.Length = 0;
    WatcherSubliminalMessages.AddItem(Watcher_Subliminal_1);
    WatcherSubliminalMessages.AddItem(Watcher_Subliminal_2);
    WatcherSubliminalMessages.AddItem(Watcher_Subliminal_3);
    WatcherSubliminalMessages.AddItem(Watcher_Subliminal_4);
    WatcherSubliminalMessages.AddItem(Watcher_Subliminal_5);
    WatcherSubliminalMessages.AddItem(Watcher_Subliminal_6);
    WatcherSubliminalMessages.AddItem(Watcher_Subliminal_7);
    WatcherSubliminalMessages.AddItem(Watcher_Subliminal_8);
    
    WatcherEyeCount = 0;
    
    `log("ZTHudWrapper: Watcher system initialized");
}


function UpdateWatcherEffects(
    bool bActive,
    int Stage,
    float Vignette,
    bool bStaticFlash,
    bool bSubliminal,
    string SubText,
    float SubX,
    float SubY,
    bool bDim,
    bool bInvert,
    bool bScan,
    float ScanY
)
{
    WatcherState.bIsActive = bActive;
    WatcherState.CurrentStage = Stage;
    WatcherState.VignetteIntensity = Vignette;
    
    if (bStaticFlash)
    {
        WatcherState.StaticIntensity = 0.5f + (float(Stage) * 0.1f);
    }
    else
    {
        WatcherState.StaticIntensity = 0.0f;
    }
    
    if (bSubliminal && !WatcherState.bShowSubliminal)
    {
        WatcherState.bShowSubliminal = true;
        WatcherState.SubliminalTimer = 0.15f;
        WatcherState.SubliminalText = SubText;
        WatcherState.SubliminalPosX = SubX;
        WatcherState.SubliminalPosY = SubY;
    }
    
    if (bDim && !WatcherState.bScreenDim)
    {
        WatcherState.bScreenDim = true;
        WatcherState.DimTimer = 0.3f;
    }
    
    if (bInvert && !WatcherState.bColorInvert)
    {
        WatcherState.bColorInvert = true;
        WatcherState.InvertTimer = 0.1f;
    }
    
    WatcherState.bShowScanLine = bScan;
    WatcherState.ScanLineY = ScanY;
}

function UpdateWatcherEye(
    int EyeIndex,
    float PosX,
    float PosY,
    float Size,
    float Alpha,
    float PupilOffX,
    float PupilOffY,
    bool bBlinkingState,
    float BlinkTime
)
{
    if (EyeIndex < 0 || EyeIndex >= 16)
        return;
    
    if (EyeIndex >= WatcherEyeCount)
    {
        WatcherEyeCount = EyeIndex + 1;
    }
    
    WatcherEyePosX[EyeIndex] = PosX;
    WatcherEyePosY[EyeIndex] = PosY;
    WatcherEyeSize[EyeIndex] = Size;
    WatcherEyeAlpha[EyeIndex] = Alpha;
    WatcherEyePupilX[EyeIndex] = PupilOffX;
    WatcherEyePupilY[EyeIndex] = PupilOffY;
    if (bBlinkingState)
    {
        WatcherEyeBlinking[EyeIndex] = 1;
    }
    else
    {
        WatcherEyeBlinking[EyeIndex] = 0;
    }
    WatcherEyeBlinkTimer[EyeIndex] = BlinkTime;
}

function ClearWatcherEyes()
{
    WatcherEyeCount = 0;
}

function SetWatcherEyeCount(int Count)
{
    WatcherEyeCount = Clamp(Count, 0, 16);
}

function DrawWatcherEffects()
{
    local int i;
    
    if (!WatcherState.bIsActive || Canvas == None)
        return;
    
    if (WatcherState.bShowSubliminal)
    {
        WatcherState.SubliminalTimer -= RenderDelta;
        if (WatcherState.SubliminalTimer <= 0.0f)
            WatcherState.bShowSubliminal = false;
    }
    
    if (WatcherState.bScreenDim)
    {
        WatcherState.DimTimer -= RenderDelta;
        if (WatcherState.DimTimer <= 0.0f)
            WatcherState.bScreenDim = false;
    }
    
    if (WatcherState.bColorInvert)
    {
        WatcherState.InvertTimer -= RenderDelta;
        if (WatcherState.InvertTimer <= 0.0f)
            WatcherState.bColorInvert = false;
    }
    
    if (WatcherState.VignetteIntensity > 0.0f)
    {
        DrawWatcherVignette(WatcherState.VignetteIntensity);
    }
    
    if (WatcherState.bScreenDim)
    {
        DrawWatcherDim();
    }
    
    if (WatcherState.StaticIntensity > 0.0f)
    {
        DrawWatcherStatic(WatcherState.StaticIntensity);
    }
    
    if (WatcherState.bShowScanLine)
    {
        DrawWatcherScanLine(WatcherState.ScanLineY);
    }
    
    for (i = 0; i < WatcherEyeCount; i++)
    {
        if (WatcherEyeAlpha[i] > 0.01f)
        {
            DrawWatcherEyeByIndex(i);
        }
    }
    
    if (WatcherState.bShowSubliminal)
    {
        DrawWatcherSubliminal(WatcherState.SubliminalText, WatcherState.SubliminalPosX, WatcherState.SubliminalPosY);
    }
    
    if (WatcherState.bColorInvert)
    {
        DrawWatcherInvert();
    }
}

function DrawWatcherVignette(float Intensity)
{
    local float EdgeSize;
    local int Alpha;
    local int i;
    local float StepSize;
    local float CurrentAlpha;
    
    if (Canvas == None) return;
    
    EdgeSize = Canvas.SizeX * 0.25f;
    Alpha = int(Intensity * 180);
    
    StepSize = EdgeSize / 20.0f;
    
    for (i = 0; i < 20; i++)
    {
        CurrentAlpha = Alpha * (1.0f - (float(i) / 20.0f));
        Canvas.SetDrawColor(0, 0, 0, int(CurrentAlpha));
        
        Canvas.SetPos(0, i * StepSize);
        Canvas.DrawRect(Canvas.SizeX, StepSize);
        
        Canvas.SetPos(0, Canvas.SizeY - ((i + 1) * StepSize));
        Canvas.DrawRect(Canvas.SizeX, StepSize);
        
        Canvas.SetPos(i * StepSize, 0);
        Canvas.DrawRect(StepSize, Canvas.SizeY);
        
        Canvas.SetPos(Canvas.SizeX - ((i + 1) * StepSize), 0);
        Canvas.DrawRect(StepSize, Canvas.SizeY);
    }
}

function DrawWatcherEyeByIndex(int EyeIdx)
{
    local float ScreenX, ScreenY;
    local float BaseSize;
    local float OuterSize, ScleraSize, IrisSize, PupilSize, HighlightSize;
    local float PupilOffX, PupilOffY;
    local int EyeAlpha;
    local float BlinkScale;
    
    if (Canvas == None || EyeIdx < 0 || EyeIdx >= WatcherEyeCount) return;
    
    ScreenX = WatcherEyePosX[EyeIdx] * Canvas.SizeX;
    ScreenY = WatcherEyePosY[EyeIdx] * Canvas.SizeY;
    
    BaseSize = 40.0f * WatcherEyeSize[EyeIdx];
    OuterSize = BaseSize * 1.2f;
    ScleraSize = BaseSize;
    IrisSize = BaseSize * 0.5f;
    PupilSize = BaseSize * 0.25f;
    HighlightSize = BaseSize * 0.1f;
    
    PupilOffX = (0.5f - WatcherEyePosX[EyeIdx]) * BaseSize * 0.2f + WatcherEyePupilX[EyeIdx];
    PupilOffY = (0.5f - WatcherEyePosY[EyeIdx]) * BaseSize * 0.2f + WatcherEyePupilY[EyeIdx];
    
    EyeAlpha = int(WatcherEyeAlpha[EyeIdx] * 255);
    
    BlinkScale = 1.0f;
    if (WatcherEyeBlinking[EyeIdx] != 0)
    {
        BlinkScale = 0.1f + (Abs(Sin(WatcherEyeBlinkTimer[EyeIdx] * 20.0f)) * 0.9f);
    }
    
    Canvas.SetDrawColor(WatcherEyeColorOuter.R, WatcherEyeColorOuter.G, WatcherEyeColorOuter.B, EyeAlpha);
    DrawWatcherEllipse(ScreenX, ScreenY, OuterSize, OuterSize * 0.6f * BlinkScale);
    
    Canvas.SetDrawColor(WatcherEyeColorSclera.R, WatcherEyeColorSclera.G, WatcherEyeColorSclera.B, EyeAlpha);
    DrawWatcherEllipse(ScreenX, ScreenY, ScleraSize, ScleraSize * 0.5f * BlinkScale);
    
    Canvas.SetDrawColor(WatcherEyeColorIris.R, WatcherEyeColorIris.G, WatcherEyeColorIris.B, EyeAlpha);
    DrawWatcherCircle(ScreenX + PupilOffX, ScreenY + (PupilOffY * BlinkScale), IrisSize * 0.5f);
    
    Canvas.SetDrawColor(WatcherEyeColorPupil.R, WatcherEyeColorPupil.G, WatcherEyeColorPupil.B, EyeAlpha);
    DrawWatcherCircle(ScreenX + PupilOffX, ScreenY + (PupilOffY * BlinkScale), PupilSize * 0.5f);
    
    Canvas.SetDrawColor(255, 255, 255, int(EyeAlpha * 0.8f));
    DrawWatcherCircle(ScreenX + PupilOffX - (BaseSize * 0.15f), ScreenY + (PupilOffY * BlinkScale) - (BaseSize * 0.1f), HighlightSize);
}

function DrawWatcherEllipse(float EllipseX, float EllipseY, float RadiusX, float RadiusY)
{
    local int i;
    local float YOffset, HalfWidth;
    local int Steps;
    
    Steps = 20;
    
    for (i = -Steps; i <= Steps; i++)
    {
        YOffset = (float(i) / float(Steps)) * RadiusY;
        HalfWidth = RadiusX * Sqrt(1.0f - Square(YOffset / RadiusY));
        
        Canvas.SetPos(EllipseX - HalfWidth, EllipseY + YOffset);
        Canvas.DrawRect(HalfWidth * 2.0f, RadiusY / float(Steps) + 1);
    }
}

function DrawWatcherCircle(float CircleX, float CircleY, float Radius)
{
    DrawWatcherEllipse(CircleX, CircleY, Radius, Radius);
}

function DrawWatcherStatic(float Intensity)
{
    local int i;
    local float X, Y, W, H;
    local int Alpha;
    local int NumRects;
    
    if (Canvas == None) return;
    
    Alpha = int(Intensity * 100);
    NumRects = int(200 * Intensity);
    
    for (i = 0; i < NumRects; i++)
    {
        X = FRand() * Canvas.SizeX;
        Y = FRand() * Canvas.SizeY;
        W = 2.0f + (FRand() * 8.0f);
        H = 1.0f + (FRand() * 3.0f);
        
        if (FRand() > 0.5f)
        {
            Canvas.SetDrawColor(255, 255, 255, Alpha);
        }
        else
        {
            Canvas.SetDrawColor(0, 0, 0, Alpha);
        }
        
        Canvas.SetPos(X, Y);
        Canvas.DrawRect(W, H);
    }
}

function DrawWatcherSubliminal(string Text, float NormX, float NormY)
{
    local float TextW, TextH;
    local float X, Y;
    local float Alpha;
    
    if (Canvas == None || Len(Text) == 0) return;
    
    Canvas.Font = class'KFGameEngine'.static.GetKFCanvasFont();
    Canvas.TextSize(Text, TextW, TextH);
    
    X = (NormX * Canvas.SizeX) - (TextW * 0.5f);
    Y = (NormY * Canvas.SizeY) - (TextH * 0.5f);
    
    Alpha = 150 + (FRand() * 105);
    
    Canvas.SetDrawColor(200, 0, 0, int(Alpha));
    Canvas.SetPos(X, Y);
    Canvas.DrawText(Text, false, 1.5f, 1.5f);
}

function DrawWatcherScanLine(float YPos)
{
    local float ScreenY;
    
    if (Canvas == None) return;
    
    ScreenY = YPos * Canvas.SizeY;
    
    Canvas.SetDrawColor(255, 255, 255, 30);
    Canvas.SetPos(0, ScreenY - 2);
    Canvas.DrawRect(Canvas.SizeX, 4);
    
    Canvas.SetDrawColor(255, 255, 255, 60);
    Canvas.SetPos(0, ScreenY - 1);
    Canvas.DrawRect(Canvas.SizeX, 2);
}

function DrawWatcherDim()
{
    if (Canvas == None) return;
    
    Canvas.SetDrawColor(0, 0, 0, 100);
    Canvas.SetPos(0, 0);
    Canvas.DrawRect(Canvas.SizeX, Canvas.SizeY);
}

function DrawWatcherInvert()
{
    if (Canvas == None) return;
    
    Canvas.SetDrawColor(255, 255, 255, 200);
    Canvas.SetPos(0, 0);
    Canvas.DrawRect(Canvas.SizeX, Canvas.SizeY);
}


// ===================================================================
// PREDATOR TROPHY DISPLAY SYSTEM
// ===================================================================

function InitializePredatorDisplay()
{
    local int i;

    PredatorDisplay.bIsActive = False;
    for (i = 0; i < 11; ++i)
        PredatorDisplay.TrophyCount[i] = 0;
    PredatorDisplay.TotalTrophies = 0;
    PredatorDisplay.CompletedSets = 0;
    PredatorDisplay.CompletedSetsCount = 0;
    PredatorDisplay.bTrophyMaster = False;
    PredatorDisplay.bStackingPhase = False;
    PredatorDisplay.AccAllDamage = 0.0f;
    PredatorDisplay.AccLargeZedDamage = 0.0f;
    PredatorDisplay.AccDamageResist = 0.0f;
    PredatorDisplay.AccSpeed = 0.0f;
    PredatorDisplay.AccReload = 0.0f;
    PredatorDisplay.AccMeleeDamage = 0.0f;
    PredatorDisplay.AccMagSize = 0.0f;
    PredatorDisplay.AccWeaponSwitch = 0.0f;
    PredatorDisplay.AccSpareAmmo = 0.0f;
    PredatorDisplay.AccHeadshotDamage = 0.0f;
    PredatorDisplay.StackBonusHP = 0;
    PredatorDisplay.StackBonusArmor = 0;
    PredatorDisplay.StackBonusDosh = 0;
    PredatorDisplay.bCanNotBeGrabbed = False;
    PredatorDisplay.bCanSeeEnemyHealth = False;
}

function UpdatePredatorDisplay(
    byte InTrophyCount[11],
    byte InTotalTrophies,
    int InCompletedSets,
    byte InCompletedSetsCount,
    bool InTrophyMaster,
    bool InStackingPhase,
    float InAccAllDamage,
    float InAccLargeZedDamage,
    float InAccDamageResist,
    float InAccSpeed,
    float InAccReload,
    float InAccMeleeDamage,
    float InAccMagSize,
    float InAccWeaponSwitch,
    float InAccSpareAmmo,
    float InAccHeadshotDamage,
    int InStackBonusHP,
    int InStackBonusArmor,
    int InStackBonusDosh,
    bool InCanNotBeGrabbed,
    bool InCanSeeEnemyHealth,
    byte InMaxSlots)
{
    local int i;

    PredatorDisplay.bIsActive = True;

    for (i = 0; i < 11; ++i)
        PredatorDisplay.TrophyCount[i] = InTrophyCount[i];

    PredatorDisplay.TotalTrophies = InTotalTrophies;
    PredatorDisplay.CompletedSets = InCompletedSets;
    PredatorDisplay.CompletedSetsCount = InCompletedSetsCount;
    PredatorDisplay.bTrophyMaster = InTrophyMaster;
    PredatorDisplay.bStackingPhase = InStackingPhase;
    PredatorDisplay.AccAllDamage = InAccAllDamage;
    PredatorDisplay.AccLargeZedDamage = InAccLargeZedDamage;
    PredatorDisplay.AccDamageResist = InAccDamageResist;
    PredatorDisplay.AccSpeed = InAccSpeed;
    PredatorDisplay.AccReload = InAccReload;
    PredatorDisplay.AccMeleeDamage = InAccMeleeDamage;
    PredatorDisplay.AccMagSize = InAccMagSize;
    PredatorDisplay.AccWeaponSwitch = InAccWeaponSwitch;
    PredatorDisplay.AccSpareAmmo = InAccSpareAmmo;
    PredatorDisplay.AccHeadshotDamage = InAccHeadshotDamage;
    PredatorDisplay.StackBonusHP = InStackBonusHP;
    PredatorDisplay.StackBonusArmor = InStackBonusArmor;
    PredatorDisplay.StackBonusDosh = InStackBonusDosh;
    PredatorDisplay.bCanNotBeGrabbed = InCanNotBeGrabbed;
    PredatorDisplay.bCanSeeEnemyHealth = InCanSeeEnemyHealth;
    PredatorDisplay.MaxSlots = InMaxSlots;

    if (PredatorDisplay.MaxSlots < 5)
        PredatorDisplay.MaxSlots = 5;

    // Recompute all bonus values from raw set/trophy data.
    // This ensures the card ONLY shows Predator-sourced bonuses,
    // immune to contamination from roguelike upgrades or other systems.
    RecomputePredatorBonuses();
}

/** Compute Predator card bonuses purely from CompletedSets bitmask and
 *  TrophyCount data. Mirrors Helper's RecalculateAllBonuses logic but
 *  runs entirely on the HUD side with no external dependencies. */
function RecomputePredatorBonuses()
{
    local float M;
    local int Sets;
    local int BossStacks, EffStacks;

    // Trophy Master doubles set bonuses
    M = PredatorDisplay.bTrophyMaster ? 2.0f : 1.0f;
    Sets = PredatorDisplay.CompletedSets;

    // Zero everything
    PredatorDisplay.AccAllDamage = 0.0f;
    PredatorDisplay.AccLargeZedDamage = 0.0f;
    PredatorDisplay.AccDamageResist = 0.0f;
    PredatorDisplay.AccSpeed = 0.0f;
    PredatorDisplay.AccReload = 0.0f;
    PredatorDisplay.AccMeleeDamage = 0.0f;
    PredatorDisplay.AccMagSize = 0.0f;
    PredatorDisplay.AccWeaponSwitch = 0.0f;
    PredatorDisplay.AccSpareAmmo = 0.0f;
    PredatorDisplay.AccHeadshotDamage = 0.0f;
    PredatorDisplay.StackBonusHP = 0;
    PredatorDisplay.StackBonusArmor = 0;
    PredatorDisplay.StackBonusDosh = 0;
    PredatorDisplay.bCanNotBeGrabbed = False;
    PredatorDisplay.bCanSeeEnemyHealth = False;

    // --- SET BONUSES ---

    // Tier 1 pairs
    if ((Sets & (1 << 0)) != 0)  // Swarm Breaker
        PredatorDisplay.AccAllDamage += 0.10f * M;
    if ((Sets & (1 << 1)) != 0)  // Blade Collector
        PredatorDisplay.AccMeleeDamage += 0.25f * M;
    if ((Sets & (1 << 2)) != 0)  // Freak Show
        PredatorDisplay.AccDamageResist += 0.25f * M;
    if ((Sets & (1 << 3)) != 0)  // Salvage Run
        PredatorDisplay.AccReload += 0.25f * M;
    if ((Sets & (1 << 4)) != 0)  // Big Game
        PredatorDisplay.AccLargeZedDamage += 0.25f * M;

    // Tier 2 triples
    if ((Sets & (1 << 5)) != 0)  // Full Sweep
        PredatorDisplay.AccMagSize += 0.30f * M;
    if ((Sets & (1 << 6)) != 0)  // Night Stalker
        PredatorDisplay.AccWeaponSwitch += 0.40f * M;
    if ((Sets & (1 << 7)) != 0)  // Brute Force
        PredatorDisplay.AccAllDamage += 0.20f * M;

    // Tier 3: King Slayer (Boss+FP)
    if ((Sets & (1 << 8)) != 0)
    {
        PredatorDisplay.AccAllDamage += 0.50f * M;
        PredatorDisplay.AccDamageResist += 0.30f * M;
        PredatorDisplay.bCanNotBeGrabbed = True;
    }

    // Tier 3: Apex Predator (Boss+Scrake)
    if ((Sets & (1 << 9)) != 0)
    {
        PredatorDisplay.AccAllDamage += 0.40f * M;
        PredatorDisplay.AccSpeed += 0.30f * M;
        PredatorDisplay.bCanSeeEnemyHealth = True;
    }

    // Tier 3: Trophy Wall (Boss+Trash)
    if ((Sets & (1 << 10)) != 0)
    {
        PredatorDisplay.AccAllDamage += 0.30f * M;
        PredatorDisplay.AccSpareAmmo += 0.50f * M;
        PredatorDisplay.AccReload += 0.30f * M;
    }

    // Tier 4: Legendary Hunter (Boss+Boss)
    if ((Sets & (1 << 11)) != 0)
    {
        PredatorDisplay.AccAllDamage += 0.75f * M;
        PredatorDisplay.AccDamageResist += 0.50f * M;
        PredatorDisplay.AccSpeed += 0.50f * M;
        PredatorDisplay.bCanNotBeGrabbed = True;
        PredatorDisplay.bCanSeeEnemyHealth = True;
    }

    // --- STACKING BONUSES ---
    if (PredatorDisplay.bStackingPhase)
    {
        BossStacks = int(PredatorDisplay.TrophyCount[10]);

        // Clot -> Dosh
        EffStacks = int(PredatorDisplay.TrophyCount[0]) + BossStacks;
        if (EffStacks > 0) PredatorDisplay.StackBonusDosh = EffStacks * 1;

        // Crawler -> Speed
        EffStacks = int(PredatorDisplay.TrophyCount[1]) + BossStacks;
        if (EffStacks > 0) PredatorDisplay.AccSpeed += float(EffStacks) * 0.01f;

        // Gorefast -> Melee
        EffStacks = int(PredatorDisplay.TrophyCount[2]) + BossStacks;
        if (EffStacks > 0) PredatorDisplay.AccMeleeDamage += float(EffStacks) * 0.01f;

        // Stalker -> MagSize
        EffStacks = int(PredatorDisplay.TrophyCount[3]) + BossStacks;
        if (EffStacks > 0) PredatorDisplay.AccMagSize += float(EffStacks) * 0.01f;

        // Bloat -> HP
        EffStacks = int(PredatorDisplay.TrophyCount[4]) + BossStacks;
        if (EffStacks > 0) PredatorDisplay.StackBonusHP = EffStacks * 1;

        // Husk -> Resist
        EffStacks = int(PredatorDisplay.TrophyCount[5]) + BossStacks;
        if (EffStacks > 0) PredatorDisplay.AccDamageResist += float(EffStacks) * 0.01f;

        // Siren -> SpareAmmo
        EffStacks = int(PredatorDisplay.TrophyCount[6]) + BossStacks;
        if (EffStacks > 0) PredatorDisplay.AccSpareAmmo += float(EffStacks) * 0.05f;

        // EDAR -> Headshot
        EffStacks = int(PredatorDisplay.TrophyCount[7]) + BossStacks;
        if (EffStacks > 0) PredatorDisplay.AccHeadshotDamage = float(EffStacks) * 0.10f;

        // Scrake -> Armor
        EffStacks = int(PredatorDisplay.TrophyCount[8]) + BossStacks;
        if (EffStacks > 0) PredatorDisplay.StackBonusArmor = EffStacks * 5;

        // FP -> AllDamage
        EffStacks = int(PredatorDisplay.TrophyCount[9]) + BossStacks;
        if (EffStacks > 0) PredatorDisplay.AccAllDamage += float(EffStacks) * 0.10f;
    }
}

function ClearPredatorDisplay()
{
    PredatorDisplay.bIsActive = False;
}

// ===================================================================
// PREDATOR CARD - Compact display card for the card stack system
//
// Shows: icon + title + 5 trophy inventory slots + up to 3 rarest sets + bonus summary
// Full trophy grid + all sets available via console command: PredatorTrophies
// ===================================================================

function DrawPredatorCard()
{
    local float BoxX, BoxY, BoxW, BoxH;
    local float PadX, PadY, LineH, SmallLineH;
    local float CurY, ContentX, ContentW;
    local float TxtScale, SmallTxtScale;
    local float SlotSz, SlotGap;
    local float SlotIconSz;
    local int SlotIdx, CatIdx, CatRemain;
    local int SetsShown, SetIdx;
    local Color PredGoldColor, SecondaryColor, CompleteColor, StackColor;
    local Color SlotColor;
    local string SetsRightText;
    local float SetsW, SetsH;
    local string CountStr;
    local float CountW, CountH;
    local bool bHasAnyBonus;

    if (Canvas == None)
        return;

    // --- Fixed sizes (scaled from 720p baseline) ---
    PadX = 8.0f * ResScale;
    PadY = 6.0f * ResScale;
    LineH = 18.0f * ResScale;
    SmallLineH = 14.0f * ResScale;
    TxtScale = 0.7f * ResScale;
    SmallTxtScale = 0.55f * ResScale;
    BoxW = 280.0f * ResScale;

    SlotSz = 50.0f * ResScale;
    SlotGap = 3.0f * ResScale;
    SlotIconSz = 40.0f * ResScale;

    // Position from card stacking system
    BoxX = Canvas.SizeX * DisplayCardBaseX;
    BoxY = Canvas.SizeY * GetDisplayCardY(CARD_PREDATOR);
    BoxH = GetPredatorCardHeight();

    // --- Colors ---
    PredGoldColor = MakeColorFromRGB(204, 136, 0, 255);
    SecondaryColor = MakeColorFromRGB(160, 160, 160, 255);
    CompleteColor = MakeColorFromRGB(50, 255, 50, 255);
    StackColor = MakeColorFromRGB(100, 200, 255, 255);

    // No perk icon - full inner width available
    ContentX = BoxX + PadX;
    ContentW = BoxW - PadX * 2.0f;

    Canvas.Font = class'KFGameEngine'.Static.GetKFCanvasFont();

    // --- Dark background ---
    Canvas.SetDrawColor(0, 0, 0, 160);
    Canvas.SetPos(BoxX, BoxY);
    Canvas.DrawRect(BoxW, BoxH);

    // --- Amber border (2px, scaled) ---
    Canvas.SetDrawColor(PredGoldColor.R, PredGoldColor.G, PredGoldColor.B, 200);
    Canvas.SetPos(BoxX, BoxY);
    Canvas.DrawRect(BoxW, 2.0f * ResScale);
    Canvas.SetPos(BoxX, BoxY + BoxH - 2.0f * ResScale);
    Canvas.DrawRect(BoxW, 2.0f * ResScale);
    Canvas.SetPos(BoxX, BoxY);
    Canvas.DrawRect(2.0f * ResScale, BoxH);
    Canvas.SetPos(BoxX + BoxW - 2.0f * ResScale, BoxY);
    Canvas.DrawRect(2.0f * ResScale, BoxH);

    // --- Row 1: Title + status right-aligned ---
    CurY = BoxY + PadY;
    DrawTextWithShadow(Predator_Title, ContentX, CurY, PredGoldColor, TxtScale);

    if (PredatorDisplay.bStackingPhase)
    {
        SetsRightText = Predator_Stacking;
        if (PredatorDisplay.bTrophyMaster)
            SetsRightText $= " (2x)";
        Canvas.TextSize(SetsRightText, SetsW, SetsH, SmallTxtScale, SmallTxtScale);
        DrawTextWithShadow(SetsRightText,
            BoxX + BoxW - PadX - SetsW,
            CurY + 2.0f, StackColor, SmallTxtScale);
    }
    else
    {
        SetsRightText = Predator_SetsLabel @ string(PredatorDisplay.CompletedSetsCount) $ "/3";
        if (PredatorDisplay.bTrophyMaster)
            SetsRightText $= " (2x)";
        Canvas.TextSize(SetsRightText, SetsW, SetsH, SmallTxtScale, SmallTxtScale);
        DrawTextWithShadow(SetsRightText,
            BoxX + BoxW - PadX - SetsW,
            CurY + 2.0f, SecondaryColor, SmallTxtScale);
    }
    CurY += LineH + 4.0f * ResScale;

    // --- Row 2: Trophy Inventory Slots (5 base + extras from Trophy Hoarder) ---
    // In stacking phase: show categories with counts, stacked slots show "xN"
    // In set phase: show individual trophies as before
    // Extra slots (6th, 7th) wrap to a second row below
    SlotIdx = 0;
    for (CatIdx = 0; CatIdx < 11; ++CatIdx)
    {
        if (SlotIdx >= int(PredatorDisplay.MaxSlots))
            break;

        CatRemain = int(PredatorDisplay.TrophyCount[CatIdx]);

        if (PredatorDisplay.bStackingPhase)
        {
            // Stacking phase: one slot per category, show stack count
            if (CatRemain > 0)
            {
                DrawPredatorTrophySlot(
                    ContentX + 1.0f + float(SlotIdx % 5) * (SlotSz + SlotGap),
                    CurY + float(SlotIdx / 5) * (SlotSz + 3.0f),
                    SlotSz, SlotIconSz, CatIdx, True);

                // Draw stack count overlay (bottom-right corner)
                if (CatRemain > 1)
                {
                    CountStr = "x" $ string(CatRemain);
                    Canvas.TextSize(CountStr, CountW, CountH, 0.45f * ResScale, 0.45f * ResScale);
                    DrawTextWithShadow(CountStr,
                        ContentX + 1.0f + float(SlotIdx % 5) * (SlotSz + SlotGap) + SlotSz - CountW - 2.0f,
                        CurY + float(SlotIdx / 5) * (SlotSz + 3.0f) + SlotSz - CountH - 1.0f,
                        MakeColorFromRGB(255, 255, 100, 255), 0.45f * ResScale);
                }

                SlotIdx += 1;
            }
        }
        else
        {
            // Set phase: each trophy takes one slot
            while (CatRemain > 0 && SlotIdx < int(PredatorDisplay.MaxSlots))
            {
                DrawPredatorTrophySlot(
                    ContentX + 1.0f + float(SlotIdx % 5) * (SlotSz + SlotGap),
                    CurY + float(SlotIdx / 5) * (SlotSz + 3.0f),
                    SlotSz, SlotIconSz, CatIdx, True);
                SlotIdx += 1;
                CatRemain -= 1;
            }
        }
    }

    // Draw remaining empty slots
    while (SlotIdx < int(PredatorDisplay.MaxSlots))
    {
        DrawPredatorTrophySlot(
            ContentX + 1.0f + float(SlotIdx % 5) * (SlotSz + SlotGap),
            CurY + float(SlotIdx / 5) * (SlotSz + 3.0f),
            SlotSz, SlotIconSz, -1, False);
        SlotIdx += 1;
    }

    // Advance CurY past all trophy rows
    if (PredatorDisplay.MaxSlots > 5)
        CurY += SlotSz * 2.0f + 3.0f * ResScale + PadY;
    else
        CurY += SlotSz + PadY;

    // --- Row 3: Up to 3 rarest completed sets (highest index first) ---
    if (PredatorDisplay.CompletedSetsCount > 0)
    {
        // Thin divider
        Canvas.SetDrawColor(100, 100, 100, 120);
        Canvas.SetPos(ContentX, CurY);
        Canvas.DrawRect(ContentW, 2.0f * ResScale);
        CurY += 2.0f * ResScale + 4.0f * ResScale;

        SetsShown = 0;
        for (SetIdx = 11; SetIdx >= 0; --SetIdx)
        {
            if (SetsShown >= 3)
                break;

            if ((PredatorDisplay.CompletedSets & (1 << SetIdx)) != 0)
            {
                SlotColor = GetPredatorSetTierColor(SetIdx);
                DrawTextWithShadow("-" @ GetPredatorSetName(SetIdx),
                    ContentX, CurY, SlotColor, SmallTxtScale);

                // Draw recipe in dimmer color to the right of set name
                Canvas.TextSize("-" @ GetPredatorSetName(SetIdx), SetsW, SetsH, SmallTxtScale, SmallTxtScale);
                DrawTextWithShadow("(" $ GetPredatorSetRecipe(SetIdx) $ ")",
                    ContentX + SetsW + 4.0f * ResScale, CurY,
                    MakeColorFromRGB(SlotColor.R / 2, SlotColor.G / 2, SlotColor.B / 2, 200),
                    SmallTxtScale);

                CurY += SmallLineH;
                SetsShown += 1;
            }
        }

        CurY += 4.0f;
    }

    // --- Stacking phase label ---
    if (PredatorDisplay.bStackingPhase)
    {
        DrawTextWithShadow(Predator_EndlessHunt, ContentX, CurY, StackColor, SmallTxtScale);
        CurY += LineH;
    }

    // --- Bonus lines (combined set + stacking bonuses) ---
    bHasAnyBonus = PredatorDisplay.AccAllDamage > 0.0f
        || PredatorDisplay.AccLargeZedDamage > 0.0f
        || PredatorDisplay.AccDamageResist > 0.0f
        || PredatorDisplay.AccSpeed > 0.0f
        || PredatorDisplay.AccReload > 0.0f
        || PredatorDisplay.AccMeleeDamage > 0.0f
        || PredatorDisplay.AccMagSize > 0.0f
        || PredatorDisplay.AccWeaponSwitch > 0.0f
        || PredatorDisplay.AccSpareAmmo > 0.0f
        || PredatorDisplay.AccHeadshotDamage > 0.0f
        || PredatorDisplay.StackBonusHP > 0
        || PredatorDisplay.StackBonusArmor > 0
        || PredatorDisplay.StackBonusDosh > 0;

    if (bHasAnyBonus)
    {
        if (PredatorDisplay.AccAllDamage > 0.0f)
        {
            DrawTextWithShadow("+" $ PredatorFormatPercent(PredatorDisplay.AccAllDamage) @ Predator_AllDamage,
                ContentX, CurY, CompleteColor, SmallTxtScale);
            CurY += SmallLineH;
        }
        if (PredatorDisplay.AccLargeZedDamage > 0.0f)
        {
            DrawTextWithShadow("+" $ PredatorFormatPercent(PredatorDisplay.AccLargeZedDamage) @ Predator_LargeZedDamage,
                ContentX, CurY, CompleteColor, SmallTxtScale);
            CurY += SmallLineH;
        }
        if (PredatorDisplay.AccHeadshotDamage > 0.0f)
        {
            DrawTextWithShadow("+" $ PredatorFormatPercent(PredatorDisplay.AccHeadshotDamage) @ Predator_HeadshotDamage,
                ContentX, CurY, StackColor, SmallTxtScale);
            CurY += SmallLineH;
        }
        if (PredatorDisplay.AccDamageResist > 0.0f)
        {
            DrawTextWithShadow("-" $ PredatorFormatPercent(PredatorDisplay.AccDamageResist) @ Predator_DamageTaken,
                ContentX, CurY, CompleteColor, SmallTxtScale);
            CurY += SmallLineH;
        }
        if (PredatorDisplay.AccSpeed > 0.0f)
        {
            DrawTextWithShadow("+" $ PredatorFormatPercent(PredatorDisplay.AccSpeed) @ Predator_MovementSpeed,
                ContentX, CurY, CompleteColor, SmallTxtScale);
            CurY += SmallLineH;
        }
        if (PredatorDisplay.AccReload > 0.0f)
        {
            DrawTextWithShadow("+" $ PredatorFormatPercent(PredatorDisplay.AccReload) @ Predator_ReloadSpeed,
                ContentX, CurY, CompleteColor, SmallTxtScale);
            CurY += SmallLineH;
        }
        if (PredatorDisplay.AccMeleeDamage > 0.0f)
        {
            DrawTextWithShadow("+" $ PredatorFormatPercent(PredatorDisplay.AccMeleeDamage) @ Predator_MeleeDamage,
                ContentX, CurY, CompleteColor, SmallTxtScale);
            CurY += SmallLineH;
        }
        if (PredatorDisplay.AccMagSize > 0.0f)
        {
            DrawTextWithShadow("+" $ PredatorFormatPercent(PredatorDisplay.AccMagSize) @ Predator_MagazineSize,
                ContentX, CurY, CompleteColor, SmallTxtScale);
            CurY += SmallLineH;
        }
        if (PredatorDisplay.AccWeaponSwitch > 0.0f)
        {
            DrawTextWithShadow("+" $ PredatorFormatPercent(PredatorDisplay.AccWeaponSwitch) @ Predator_WeaponSwitch,
                ContentX, CurY, CompleteColor, SmallTxtScale);
            CurY += SmallLineH;
        }
        if (PredatorDisplay.AccSpareAmmo > 0.0f)
        {
            DrawTextWithShadow("+" $ PredatorFormatPercent(PredatorDisplay.AccSpareAmmo) @ Predator_SpareAmmo,
                ContentX, CurY, CompleteColor, SmallTxtScale);
            CurY += SmallLineH;
        }
        if (PredatorDisplay.StackBonusHP > 0)
        {
            DrawTextWithShadow("+" $ string(PredatorDisplay.StackBonusHP) @ Predator_MaxHP,
                ContentX, CurY, StackColor, SmallTxtScale);
            CurY += SmallLineH;
        }
        if (PredatorDisplay.StackBonusArmor > 0)
        {
            DrawTextWithShadow("+" $ string(PredatorDisplay.StackBonusArmor) @ Predator_MaxArmor,
                ContentX, CurY, StackColor, SmallTxtScale);
            CurY += SmallLineH;
        }
        if (PredatorDisplay.StackBonusDosh > 0)
        {
            DrawTextWithShadow("+" $ string(PredatorDisplay.StackBonusDosh) @ Predator_DoshPerWave,
                ContentX, CurY, StackColor, SmallTxtScale);
            CurY += SmallLineH;
        }
    }
}

/** Draw a single trophy inventory slot (filled or empty). */
function DrawPredatorTrophySlot(float X, float Y, float Size, float IconSize,
    int CategoryIndex, bool bFilled)
{
    local Color CatColor;
    local Texture2D Icon;

    if (bFilled && CategoryIndex >= 0)
    {
        CatColor = GetTrophyCategoryColor(CategoryIndex);

        // Tinted dark background
        Canvas.SetDrawColor(CatColor.R / 5, CatColor.G / 5, CatColor.B / 5, 200);
        Canvas.SetPos(X, Y);
        Canvas.DrawRect(Size, Size);

        // Category-colored border
        Canvas.SetDrawColor(CatColor.R, CatColor.G, CatColor.B, 220);
        DrawPredatorCellBorder(X, Y, Size, Size);

        // Category icon centered
        Icon = GetTrophyIcon(CategoryIndex);
        if (Icon != None)
        {
            Canvas.SetDrawColor(255, 255, 255, 255);
            Canvas.SetPos(X + (Size - IconSize) * 0.5f, Y + (Size - IconSize) * 0.5f);
            Canvas.DrawTile(Icon, IconSize, IconSize, 0, 0, Icon.SizeX, Icon.SizeY);
        }
    }
    else
    {
        // Empty slot: dark interior
        Canvas.SetDrawColor(15, 15, 15, 140);
        Canvas.SetPos(X, Y);
        Canvas.DrawRect(Size, Size);

        // Dim outline
        Canvas.SetDrawColor(50, 50, 50, 100);
        DrawPredatorCellBorder(X, Y, Size, Size);
    }
}

/** Get the Predator perk icon for the compact card (base rank icon). */
function Texture2D GetPredatorPerkIcon()
{
    return Texture2D'ZedternalRBPerkpackage_Resources.Buffs.UI_Card_Predator';
}

// ===================================================================
// PREDATOR TROPHY OVERLAY - toggled via console command "PredatorTrophies"
// ===================================================================

/** Console command (no admin required). Toggles the trophy detail overlay. */
exec function PredatorTrophies()
{
    if (bShowPredatorTrophies)
    {
        bShowPredatorTrophies = false;
        return;
    }

    if (!PredatorDisplay.bIsActive)
    {
        LocalPlayer(PlayerOwner.Player).ViewportClient.ViewportConsole.OutputText("PredatorTrophies: Predator perk not active");
        return;
    }

    bShowPredatorTrophies = true;
    PredatorTrophiesShowTime = WorldInfo.TimeSeconds;
}

/** Draw the full Predator trophy overlay - top-left, detailed grid + bonuses.
 *  Auto-dismisses after PredatorTrophiesDuration seconds. */
function DrawPredatorTrophyOverlay()
{
    local float Elapsed, Alpha;
    local float BoxX, BoxY, BoxW, BoxH;
    local float PadX, PadY, CurY;
    local float CellW, CellH, CellPad;
    local float IconSz;
    local float TxtScale, SmallScale, CountScale;
    local float LineH, SmallLineH;
    local float CellX, CellY;
    local int i;
    local Color CellColor, TextColor, PredGoldColor, CompletedColor;
    local byte Count;
    local bool bHasAnyBonus;
    local Texture2D TrophyIcon;
    local string CountStr;
    local float CountW, CountH;
    local byte AlphaByte;

    if (Canvas == None || !bShowPredatorTrophies)
        return;

    // Auto-dismiss timer
    Elapsed = WorldInfo.TimeSeconds - PredatorTrophiesShowTime;
    if (Elapsed > PredatorTrophiesDuration)
    {
        bShowPredatorTrophies = false;
        return;
    }

    // Fade out in last second
    if (Elapsed > PredatorTrophiesDuration - 1.0f)
        Alpha = (PredatorTrophiesDuration - Elapsed);
    else
        Alpha = 1.0f;

    AlphaByte = byte(FClamp(Alpha * 255.0f, 0.0f, 255.0f));

    Canvas.Font = class'KFGameEngine'.Static.GetKFCanvasFont();

    // --- Fixed sizes (compact grid, scaled from 720p baseline) ---
    PadX = 8.0f * ResScale;
    PadY = 6.0f * ResScale;
    IconSz = 24.0f * ResScale;
    CellW = 28.0f * ResScale;
    CellH = 38.0f * ResScale;
    CellPad = 4.0f * ResScale;
    TxtScale = 0.7f * ResScale;
    SmallScale = 0.55f * ResScale;
    CountScale = 0.5f * ResScale;
    LineH = 18.0f * ResScale;
    SmallLineH = 14.0f * ResScale;

    BoxW = PadX * 2.0f + (CellW + CellPad) * 11.0f - CellPad;

    // Position: top-left area (like GambitBuffs)
    BoxX = Canvas.SizeX * 0.02f;
    BoxY = Canvas.SizeY * 0.15f;

    TextColor = MakeColorFromRGB(220, 220, 220, AlphaByte);
    PredGoldColor = MakeColorFromRGB(204, 136, 0, AlphaByte);
    CompletedColor = MakeColorFromRGB(50, 255, 50, AlphaByte);

    // --- Compute total box height ---
    BoxH = PadY + LineH;                    // Header
    BoxH += CellH + PadY;                  // Single row of 11 icons
    if (PredatorDisplay.CompletedSetsCount > 0)
    {
        BoxH += 2.0f * ResScale + PadY + SmallLineH;  // Divider + Sets header
        for (i = 0; i < 12; ++i)
        {
            if ((PredatorDisplay.CompletedSets & (1 << i)) != 0)
                BoxH += SmallLineH;
        }
        BoxH += PadY;
    }
    bHasAnyBonus = PredatorDisplay.AccAllDamage > 0.0f
        || PredatorDisplay.AccLargeZedDamage > 0.0f
        || PredatorDisplay.AccDamageResist > 0.0f
        || PredatorDisplay.AccSpeed > 0.0f
        || PredatorDisplay.AccReload > 0.0f
        || PredatorDisplay.AccMeleeDamage > 0.0f
        || PredatorDisplay.AccMagSize > 0.0f
        || PredatorDisplay.AccWeaponSwitch > 0.0f
        || PredatorDisplay.AccSpareAmmo > 0.0f
        || PredatorDisplay.AccHeadshotDamage > 0.0f
        || PredatorDisplay.StackBonusHP > 0
        || PredatorDisplay.StackBonusArmor > 0
        || PredatorDisplay.StackBonusDosh > 0
        || PredatorDisplay.bCanNotBeGrabbed
        || PredatorDisplay.bCanSeeEnemyHealth;
    if (bHasAnyBonus)
    {
        BoxH += 2.0f * ResScale + PadY + SmallLineH;  // Divider + Bonuses header
        if (PredatorDisplay.AccAllDamage > 0.0f) BoxH += SmallLineH;
        if (PredatorDisplay.AccLargeZedDamage > 0.0f) BoxH += SmallLineH;
        if (PredatorDisplay.AccDamageResist > 0.0f) BoxH += SmallLineH;
        if (PredatorDisplay.AccSpeed > 0.0f) BoxH += SmallLineH;
        if (PredatorDisplay.AccReload > 0.0f) BoxH += SmallLineH;
        if (PredatorDisplay.AccMeleeDamage > 0.0f) BoxH += SmallLineH;
        if (PredatorDisplay.AccMagSize > 0.0f) BoxH += SmallLineH;
        if (PredatorDisplay.AccWeaponSwitch > 0.0f) BoxH += SmallLineH;
        if (PredatorDisplay.AccSpareAmmo > 0.0f) BoxH += SmallLineH;
        if (PredatorDisplay.AccHeadshotDamage > 0.0f) BoxH += SmallLineH;
        if (PredatorDisplay.StackBonusHP > 0) BoxH += SmallLineH;
        if (PredatorDisplay.StackBonusArmor > 0) BoxH += SmallLineH;
        if (PredatorDisplay.StackBonusDosh > 0) BoxH += SmallLineH;
        if (PredatorDisplay.bCanNotBeGrabbed) BoxH += SmallLineH;
        if (PredatorDisplay.bCanSeeEnemyHealth) BoxH += SmallLineH;
    }
    BoxH += PadY;

    CurY = BoxY;

    // --- Background ---
    Canvas.SetDrawColor(0, 0, 0, byte(FClamp(Alpha * 180.0f, 0.0f, 180.0f)));
    Canvas.SetPos(BoxX, BoxY);
    Canvas.DrawRect(BoxW, BoxH);

    // --- Border (scaled) ---
    Canvas.SetDrawColor(PredGoldColor.R, PredGoldColor.G, PredGoldColor.B, AlphaByte);
    Canvas.SetPos(BoxX, BoxY);                              Canvas.DrawRect(BoxW, 2.0f * ResScale);
    Canvas.SetPos(BoxX, BoxY + BoxH - 2.0f * ResScale);    Canvas.DrawRect(BoxW, 2.0f * ResScale);
    Canvas.SetPos(BoxX, BoxY);                              Canvas.DrawRect(2.0f * ResScale, BoxH);
    Canvas.SetPos(BoxX + BoxW - 2.0f * ResScale, BoxY);    Canvas.DrawRect(2.0f * ResScale, BoxH);

    // --- Header ---
    CurY += PadY;
    DrawTextWithShadow(PredatorOverlay_TitlePrefix $ string(PredatorDisplay.TotalTrophies) $ ")"
        $ (PredatorDisplay.bTrophyMaster ? " [Trophy Master]" : ""),
        BoxX + PadX, CurY, PredGoldColor, TxtScale);
    CurY += LineH;

    // --- Trophy grid: single row of 11 mini icons ---
    for (i = 0; i < 11; ++i)
    {
        Count = PredatorDisplay.TrophyCount[i];
        CellColor = GetTrophyCategoryColor(i);
        TrophyIcon = GetTrophyIcon(i);

        CellX = BoxX + PadX + float(i) * (CellW + CellPad);
        CellY = CurY;

        // Cell background
        if (Count > 0)
            Canvas.SetDrawColor(CellColor.R / 4, CellColor.G / 4, CellColor.B / 4,
                byte(FClamp(Alpha * 200.0f, 0.0f, 200.0f)));
        else
            Canvas.SetDrawColor(15, 15, 15, byte(FClamp(Alpha * 150.0f, 0.0f, 150.0f)));

        Canvas.SetPos(CellX, CellY);
        Canvas.DrawRect(CellW, CellH);

        // Cell border if collected
        if (Count > 0)
        {
            Canvas.SetDrawColor(CellColor.R, CellColor.G, CellColor.B, AlphaByte);
            DrawPredatorCellBorder(CellX, CellY, CellW, CellH);
        }

        // Trophy icon (24px centered in cell)
        if (TrophyIcon != None)
        {
            if (Count > 0)
                Canvas.SetDrawColor(255, 255, 255, AlphaByte);
            else
                Canvas.SetDrawColor(60, 60, 60, byte(FClamp(Alpha * 100.0f, 0.0f, 100.0f)));

            Canvas.SetPos(CellX + (CellW - IconSz) * 0.5f, CellY + 2.0f * ResScale);
            Canvas.DrawTile(TrophyIcon, IconSz, IconSz,
                0, 0, TrophyIcon.SizeX, TrophyIcon.SizeY);
        }

        // Count text below icon
        if (Count > 0)
        {
            CountStr = "x" $ string(Count);
            Canvas.TextSize(CountStr, CountW, CountH, CountScale, CountScale);
            DrawTextWithShadow(CountStr,
                CellX + (CellW - CountW) * 0.5f,
                CellY + IconSz + 4.0f * ResScale,
                MakeColorFromRGB(CellColor.R, CellColor.G, CellColor.B, AlphaByte), CountScale);
        }
    }

    CurY += CellH + PadY;

    // --- Completed Sets ---
    if (PredatorDisplay.CompletedSetsCount > 0)
    {
        Canvas.SetDrawColor(100, 100, 100, byte(FClamp(Alpha * 150.0f, 0.0f, 150.0f)));
        Canvas.SetPos(BoxX + PadX, CurY);
        Canvas.DrawRect(BoxW - PadX * 2.0f, 2.0f * ResScale);
        CurY += PadY;

        DrawTextWithShadow(PredatorOverlay_SetsPrefix @ string(PredatorDisplay.CompletedSetsCount) @ PredatorOverlay_SetsCompleted
            $ (PredatorDisplay.bTrophyMaster ? " (2x)" : ""),
            BoxX + PadX, CurY, PredGoldColor, SmallScale);
        CurY += SmallLineH;

        for (i = 0; i < 12; ++i)
        {
            if ((PredatorDisplay.CompletedSets & (1 << i)) != 0)
            {
                DrawTextWithShadow("  " $ "-" @ GetPredatorSetName(i),
                    BoxX + PadX, CurY,
                    MakeColorFromRGB(GetPredatorSetTierColor(i).R, GetPredatorSetTierColor(i).G, GetPredatorSetTierColor(i).B, AlphaByte),
                    SmallScale);
                CurY += SmallLineH;
            }
        }

        CurY += PadY;
    }

    // --- Active Bonuses ---
    if (bHasAnyBonus)
    {
        Canvas.SetDrawColor(100, 100, 100, byte(FClamp(Alpha * 150.0f, 0.0f, 150.0f)));
        Canvas.SetPos(BoxX + PadX, CurY);
        Canvas.DrawRect(BoxW - PadX * 2.0f, 2.0f * ResScale);
        CurY += PadY;

        DrawTextWithShadow(PredatorOverlay_BonusesHeader, BoxX + PadX, CurY, TextColor, SmallScale);
        CurY += SmallLineH;

        if (PredatorDisplay.AccAllDamage > 0.0f)
        {
            DrawTextWithShadow("  +" $ PredatorFormatPercent(PredatorDisplay.AccAllDamage) @ Predator_AllDamage,
                BoxX + PadX, CurY, CompletedColor, SmallScale);
            CurY += SmallLineH;
        }
        if (PredatorDisplay.AccLargeZedDamage > 0.0f)
        {
            DrawTextWithShadow("  +" $ PredatorFormatPercent(PredatorDisplay.AccLargeZedDamage) @ Predator_LargeZedDamage,
                BoxX + PadX, CurY, CompletedColor, SmallScale);
            CurY += SmallLineH;
        }
        if (PredatorDisplay.AccDamageResist > 0.0f)
        {
            DrawTextWithShadow("  -" $ PredatorFormatPercent(PredatorDisplay.AccDamageResist) @ Predator_DamageTaken,
                BoxX + PadX, CurY, CompletedColor, SmallScale);
            CurY += SmallLineH;
        }
        if (PredatorDisplay.AccSpeed > 0.0f)
        {
            DrawTextWithShadow("  +" $ PredatorFormatPercent(PredatorDisplay.AccSpeed) @ Predator_MovementSpeed,
                BoxX + PadX, CurY, CompletedColor, SmallScale);
            CurY += SmallLineH;
        }
        if (PredatorDisplay.AccReload > 0.0f)
        {
            DrawTextWithShadow("  +" $ PredatorFormatPercent(PredatorDisplay.AccReload) @ Predator_ReloadSpeed,
                BoxX + PadX, CurY, CompletedColor, SmallScale);
            CurY += SmallLineH;
        }
        if (PredatorDisplay.AccMeleeDamage > 0.0f)
        {
            DrawTextWithShadow("  +" $ PredatorFormatPercent(PredatorDisplay.AccMeleeDamage) @ Predator_MeleeDamage,
                BoxX + PadX, CurY, CompletedColor, SmallScale);
            CurY += SmallLineH;
        }
        if (PredatorDisplay.AccMagSize > 0.0f)
        {
            DrawTextWithShadow("  +" $ PredatorFormatPercent(PredatorDisplay.AccMagSize) @ Predator_MagazineSize,
                BoxX + PadX, CurY, CompletedColor, SmallScale);
            CurY += SmallLineH;
        }
        if (PredatorDisplay.AccWeaponSwitch > 0.0f)
        {
            DrawTextWithShadow("  +" $ PredatorFormatPercent(PredatorDisplay.AccWeaponSwitch) @ Predator_WeaponSwitch,
                BoxX + PadX, CurY, CompletedColor, SmallScale);
            CurY += SmallLineH;
        }
        if (PredatorDisplay.AccSpareAmmo > 0.0f)
        {
            DrawTextWithShadow("  +" $ PredatorFormatPercent(PredatorDisplay.AccSpareAmmo) @ Predator_SpareAmmo,
                BoxX + PadX, CurY, CompletedColor, SmallScale);
            CurY += SmallLineH;
        }
        if (PredatorDisplay.AccHeadshotDamage > 0.0f)
        {
            DrawTextWithShadow("  +" $ PredatorFormatPercent(PredatorDisplay.AccHeadshotDamage) @ Predator_HeadshotDamage,
                BoxX + PadX, CurY, MakeColorFromRGB(100, 200, 255, AlphaByte), SmallScale);
            CurY += SmallLineH;
        }
        if (PredatorDisplay.StackBonusHP > 0)
        {
            DrawTextWithShadow("  +" $ string(PredatorDisplay.StackBonusHP) @ Predator_MaxHP,
                BoxX + PadX, CurY, MakeColorFromRGB(100, 200, 255, AlphaByte), SmallScale);
            CurY += SmallLineH;
        }
        if (PredatorDisplay.StackBonusArmor > 0)
        {
            DrawTextWithShadow("  +" $ string(PredatorDisplay.StackBonusArmor) @ Predator_MaxArmor,
                BoxX + PadX, CurY, MakeColorFromRGB(100, 200, 255, AlphaByte), SmallScale);
            CurY += SmallLineH;
        }
        if (PredatorDisplay.StackBonusDosh > 0)
        {
            DrawTextWithShadow("  +" $ string(PredatorDisplay.StackBonusDosh) @ Predator_DoshPerWave,
                BoxX + PadX, CurY, MakeColorFromRGB(100, 200, 255, AlphaByte), SmallScale);
            CurY += SmallLineH;
        }
        if (PredatorDisplay.bCanNotBeGrabbed)
        {
            DrawTextWithShadow("  " $ "-" @ Predator_GrabImmunity,
                BoxX + PadX, CurY, PredGoldColor, SmallScale);
            CurY += SmallLineH;
        }
        if (PredatorDisplay.bCanSeeEnemyHealth)
        {
            DrawTextWithShadow("  " $ "-" @ Predator_SeeEnemyHealth,
                BoxX + PadX, CurY, PredGoldColor, SmallScale);
            CurY += SmallLineH;
        }
    }
}

// ===================================================================
// PREDATOR HELPER FUNCTIONS
// ===================================================================

function Texture2D GetTrophyIcon(int Index)
{
    switch (Index)
    {
        case 0:  return Texture2D'ZedternalRBPerkpackage_Resources.Buffs.UI_Trophy_Clot';
        case 1:  return Texture2D'ZedternalRBPerkpackage_Resources.Buffs.UI_Trophy_Crawler';
        case 2:  return Texture2D'ZedternalRBPerkpackage_Resources.Buffs.UI_Trophy_Gorefast';
        case 3:  return Texture2D'ZedternalRBPerkpackage_Resources.Buffs.UI_Trophy_Stalker';
        case 4:  return Texture2D'ZedternalRBPerkpackage_Resources.Buffs.UI_Trophy_Bloat';
        case 5:  return Texture2D'ZedternalRBPerkpackage_Resources.Buffs.UI_Trophy_Husk';
        case 6:  return Texture2D'ZedternalRBPerkpackage_Resources.Buffs.UI_Trophy_Siren';
        case 7:  return Texture2D'ZedternalRBPerkpackage_Resources.Buffs.UI_Trophy_EDAR';
        case 8:  return Texture2D'ZedternalRBPerkpackage_Resources.Buffs.UI_Trophy_Scrake';
        case 9:  return Texture2D'ZedternalRBPerkpackage_Resources.Buffs.UI_Trophy_Fleshpound';
        case 10: return Texture2D'ZedternalRBPerkpackage_Resources.Buffs.UI_Trophy_Boss';
        default: return None;
    }
}

function Color GetTrophyCategoryColor(int Index)
{
    switch (Index)
    {
        case 0:  return MakeColorFromRGB(255, 255, 180, 255);   // Clot - pale yellow
        case 1:  return MakeColorFromRGB(100, 200, 50, 255);    // Crawler - green
        case 2:  return MakeColorFromRGB(220, 50, 50, 255);     // Gorefast - red
        case 3:  return MakeColorFromRGB(150, 100, 200, 255);   // Stalker - purple
        case 4:  return MakeColorFromRGB(100, 180, 80, 255);    // Bloat - bile green
        case 5:  return MakeColorFromRGB(255, 150, 50, 255);    // Husk - orange
        case 6:  return MakeColorFromRGB(200, 100, 200, 255);   // Siren - pink
        case 7:  return MakeColorFromRGB(80, 180, 255, 255);    // EDAR - cyan
        case 8:  return MakeColorFromRGB(200, 200, 200, 255);   // Scrake - steel
        case 9:  return MakeColorFromRGB(255, 200, 50, 255);    // FP - gold
        case 10: return MakeColorFromRGB(255, 50, 50, 255);     // Boss - blood red
        default: return MakeColorFromRGB(150, 150, 150, 255);
    }
}

function string GetPredatorSetName(int SetIndex)
{
    switch (SetIndex)
    {
        case 0:  return Predator_Set0;
        case 1:  return Predator_Set1;
        case 2:  return Predator_Set2;
        case 3:  return Predator_Set3;
        case 4:  return Predator_Set4;
        case 5:  return Predator_Set5;
        case 6:  return Predator_Set6;
        case 7:  return Predator_Set7;
        case 8:  return Predator_Set8;
        case 9:  return Predator_Set9;
        case 10: return Predator_Set10;
        case 11: return Predator_Set11;
        default: return Predator_SetUnknown;
    }
}

function Color GetPredatorSetTierColor(int SetIndex)
{
    if (SetIndex <= 4)
        return MakeColorFromRGB(200, 200, 200, 255);       // T1 - White
    else if (SetIndex <= 7)
        return MakeColorFromRGB(80, 160, 255, 255);        // T2 - Blue
    else if (SetIndex <= 10)
        return MakeColorFromRGB(180, 80, 255, 255);        // T3 - Purple
    else
        return MakeColorFromRGB(255, 200, 50, 255);        // T4 - Gold
}

/** Get short trophy composition label for a set (e.g. "Clot+Crawler") */
function string GetPredatorSetRecipe(int SetIndex)
{
    switch (SetIndex)
    {
        case 0:  return "Clot+Crawler";
        case 1:  return "Gorefast+Stalker";
        case 2:  return "Siren+Husk";
        case 3:  return "EDAR+Bloat";
        case 4:  return "Scrake+FP";
        case 5:  return "Clot+Gore+Crawler";
        case 6:  return "Stalker+Siren+EDAR";
        case 7:  return "Husk+Scrake+FP";
        case 8:  return "Boss+FP";
        case 9:  return "Boss+Scrake";
        case 10: return "Boss+Trash";
        case 11: return "Boss+Boss";
        default: return "";
    }
}

function string PredatorFormatPercent(float Value)
{
    return string(int(Value * 100.0f)) $ "%";
}

function DrawPredatorCellBorder(float X, float Y, float W, float H)
{
    local float B;
    B = FMax(1.0f, 2.0f * ResScale);
    Canvas.SetPos(X, Y);                  Canvas.DrawRect(W, B);
    Canvas.SetPos(X, Y + H - B);          Canvas.DrawRect(W, B);
    Canvas.SetPos(X, Y);                  Canvas.DrawRect(B, H);
    Canvas.SetPos(X + W - B, Y);          Canvas.DrawRect(B, H);
}


// ===================================================================
// OMEN LOCALIZATION HELPERS
// The Omen helper class (ZTUpgrade_Perk_Omen_Helper) replicates
// ProphecyIndex/Tier/IconIndex/SubState + raw reward float values to the
// client via ClientUpdateOmenHUD RPC. The client-side switch in that RPC
// uses these helpers to format the card text using the active locale's
// [ZTHudWrapper] section. Doom values are computed as -2x of reward values
// to mirror the server-side BuildDoomString formula (now dead code).
// ===================================================================

function string GetLocalizedOmenName(int Idx)
{
    switch (Idx)
    {
        case 0:  return OmenName_0;
        case 1:  return OmenName_1;
        case 2:  return OmenName_2;
        case 3:  return OmenName_3;
        case 4:  return OmenName_4;
        case 5:  return OmenName_5;
        case 6:  return OmenName_6;
        case 7:  return OmenName_7;
        case 8:  return OmenName_8;
        case 9:  return OmenName_9;
        case 10: return OmenName_10;
        case 11: return OmenName_11;
        case 12: return OmenName_12;
        case 13: return OmenName_13;
        case 14: return OmenName_14;
        case 15: return OmenName_15;
        case 16: return OmenName_16;
        case 17: return OmenName_17;
        case 18: return OmenName_18;
        default: return "";
    }
}

function string GetLocalizedOmenDesc(int Idx)
{
    switch (Idx)
    {
        case 0:  return OmenDesc_0;
        case 1:  return OmenDesc_1;
        case 2:  return OmenDesc_2;
        case 3:  return OmenDesc_3;
        case 4:  return OmenDesc_4;
        case 5:  return OmenDesc_5;
        case 6:  return OmenDesc_6;
        case 7:  return OmenDesc_7;
        case 8:  return OmenDesc_8;
        case 9:  return OmenDesc_9;
        case 10: return OmenDesc_10;
        case 11: return OmenDesc_11;
        case 12: return OmenDesc_12;
        case 13: return OmenDesc_13;
        case 14: return OmenDesc_14;
        case 15: return OmenDesc_15;
        case 16: return OmenDesc_16;
        case 17: return OmenDesc_17;
        case 18: return OmenDesc_18;
        default: return "";
    }
}

function string GetLocalizedOmenWhisper(int Idx)
{
    switch (Idx)
    {
        case 0:  return OmenWhisper_0;
        case 1:  return OmenWhisper_1;
        case 2:  return OmenWhisper_2;
        case 3:  return OmenWhisper_3;
        case 4:  return OmenWhisper_4;
        case 5:  return OmenWhisper_5;
        case 6:  return OmenWhisper_6;
        case 7:  return OmenWhisper_7;
        case 8:  return OmenWhisper_8;
        case 9:  return OmenWhisper_9;
        case 10: return OmenWhisper_10;
        case 11: return OmenWhisper_11;
        case 12: return OmenWhisper_12;
        case 13: return OmenWhisper_13;
        case 14: return OmenWhisper_14;
        case 15: return OmenWhisper_15;
        case 16: return OmenWhisper_16;
        case 17: return OmenWhisper_17;
        case 18: return OmenWhisper_18;
        default: return "";
    }
}

// Build the localized REWARD string from raw reward values. Mirrors the
// original BuildRewardString format: "+N% <Stat> +N% <Stat> ..." with
// trailing-space separators. Each stat suffix is locale-specific.
function string BuildLocalizedOmenReward(float RewardDmg, float RewardHSDmg, float RewardDR,
    float RewardReload, float RewardSpeed, int RewardHP, int RewardArmor)
{
    local string S;
    S = "";
    if (RewardDmg > 0.0f)    S $= "+" $ int(RewardDmg * 100.0f)    $ "%" $ Omen_Stat_Damage;
    if (RewardHSDmg > 0.0f)  S $= "+" $ int(RewardHSDmg * 100.0f)  $ "%" $ Omen_Stat_HSDamage;
    if (RewardDR > 0.0f)     S $= "+" $ int(RewardDR * 100.0f)     $ "%" $ Omen_Stat_DR;
    if (RewardReload > 0.0f) S $= "+" $ int(RewardReload * 100.0f) $ "%" $ Omen_Stat_Reload;
    if (RewardSpeed > 0.0f)  S $= "+" $ int(RewardSpeed * 100.0f)  $ "%" $ Omen_Stat_Speed;
    if (RewardHP > 0)        S $= "+" $ RewardHP                          $ Omen_Stat_HP;
    if (RewardArmor > 0)     S $= "+" $ RewardArmor                       $ Omen_Stat_Armor;
    return S;
}

// Build the localized DOOM string. Same shape as reward, but values are
// negated and doubled (matches the server's original "-N% " $ int(val*200)
// formula for percentages and "val * 2" for HP/Armor flat values).
function string BuildLocalizedOmenDoom(float RewardDmg, float RewardHSDmg, float RewardDR,
    float RewardReload, float RewardSpeed, int RewardHP, int RewardArmor)
{
    local string S;
    S = "";
    if (RewardDmg > 0.0f)    S $= "-" $ int(RewardDmg * 200.0f)    $ "%" $ Omen_Stat_Damage;
    if (RewardHSDmg > 0.0f)  S $= "-" $ int(RewardHSDmg * 200.0f)  $ "%" $ Omen_Stat_HSDamage;
    if (RewardDR > 0.0f)     S $= "-" $ int(RewardDR * 200.0f)     $ "%" $ Omen_Stat_DR;
    if (RewardReload > 0.0f) S $= "-" $ int(RewardReload * 200.0f) $ "%" $ Omen_Stat_Reload;
    if (RewardSpeed > 0.0f)  S $= "-" $ int(RewardSpeed * 200.0f)  $ "%" $ Omen_Stat_Speed;
    if (RewardHP > 0)        S $= "-" $ (RewardHP * 2)                    $ Omen_Stat_HP;
    if (RewardArmor > 0)     S $= "-" $ (RewardArmor * 2)                 $ Omen_Stat_Armor;
    return S;
}

// ===================================================================
// OMEN PROPHECY DISPLAY - Update / Clear / Toggle
// ===================================================================

function UpdateOmenDisplay(string InTitle, string InCondition, string InReward,
    string InDoom, string InWhisper, byte InTier, byte InState, byte InIconIndex)
{
    OmenDisplay.bIsActive = True;
    OmenDisplay.Title = InTitle;
    OmenDisplay.Condition = InCondition;
    OmenDisplay.Reward = InReward;
    OmenDisplay.Doom = InDoom;
    OmenDisplay.Whisper = InWhisper;
    OmenDisplay.Tier = InTier;
    OmenDisplay.State = InState;
    OmenDisplay.IconIndex = InIconIndex;

    // Transient states (blessing/doom/deny fate) auto-clear after 4 seconds
    if (InState > 0)
        OmenDisplay.StateTimer = WorldInfo.TimeSeconds + 4.0f;
    else
        OmenDisplay.StateTimer = 0.0f;
}

function ClearOmenDisplay()
{
    OmenDisplay.bIsActive = False;
}

exec function ToggleOmenCard()
{
    bHideOmenCard = !bHideOmenCard;
    if (bHideOmenCard)
        AddNotificationMessage("Omen card hidden", MakeColorFromRGB(180, 100, 220, 255), 1);
    else
        AddNotificationMessage("Omen card visible", MakeColorFromRGB(180, 100, 220, 255), 1);
}

// ===================================================================
// ZEDBUFF STACK COUNT OVERRIDE
// Post-pass: covers parent's top-right "xN" text, redraws at bottom-center
// ===================================================================

function DrawZedBuffStackOverrides()
{
    local WMGameReplicationInfo WMGRI;
    local int i, nb, total;
    local Texture2D buffIcon;
    local float iconFactor, iconRenderedSz;
    local float X, Y;
    local float OldTxtX, OldTxtY;
    local float CoverW, CoverH;
    local float BadgeX, BadgeY, BadgeW, BadgeH, BadgePad;
    local float TxtW, TxtH, TxtScale, OldTxtScale;
    local string buffStack;

    WMGRI = WMGameReplicationInfo(WorldInfo.GRI);
    if (WMGRI == None || !WMGRI.bTraderIsOpen)
        return;

    // Count active buffs (same as parent)
    total = 0;
    for (i = 0; i < WMGRI.ZedBuffsList.Length; ++i)
    {
        if (WMGRI.ActiveZedBuffs[i] > 0)
            ++total;
    }

    if (total == 0)
        return;

    Canvas.Font = class'KFGameEngine'.Static.GetKFCanvasFont();
    TxtScale = 0.7f;
    OldTxtScale = 0.9f;

    nb = 0;
    for (i = 0; i < WMGRI.ZedBuffsList.Length; ++i)
    {
        if (WMGRI.ActiveZedBuffs[i] > 0)
        {
            if (WMGRI.ActiveZedBuffs[i] > 1)
            {
                buffIcon = WMGRI.ZedBuffsList[i].ZedBuff.default.buffIcon;
                iconFactor = 0.0474072f * Canvas.SizeX / float(buffIcon.SizeX);
                iconRenderedSz = float(buffIcon.SizeX) * iconFactor;

                // Compute icon position (same formula as parent)
                Y = Canvas.SizeY * 0.022f;
                X = Canvas.SizeX * 0.5f - (iconRenderedSz * (0.5f * float(total) - float(nb)));

                buffStack = "x" $ string(WMGRI.ActiveZedBuffs[i]);

                // --- Cover parent's old top-right text ---
                // Parent draws at: X + (buffIcon.SizeX / 5), Y with scale 0.9
                OldTxtX = X + float(buffIcon.SizeX) / 5.0f;
                OldTxtY = Y;
                Canvas.StrLen(buffStack, CoverW, CoverH);
                CoverW *= OldTxtScale;
                CoverH *= OldTxtScale;
                // Dark rect to hide parent text (with margin for shadow/outlines)
                Canvas.SetDrawColor(0, 0, 0, 220);
                Canvas.SetPos(OldTxtX - 3.0f, OldTxtY - 2.0f);
                Canvas.DrawRect(CoverW + 6.0f, CoverH + 4.0f);
                // Redraw icon on top of cover so it looks clean
                if (i == zedBuffIndex)
                {
                    Canvas.SetPos(X + 1, Y - 1);
                    Canvas.SetDrawColor(238, 238, 238, 255);
                    Canvas.DrawTexture(buffIcon, iconFactor);
                }
                else
                {
                    Canvas.SetPos(X, Y);
                    Canvas.SetDrawColor(160, 160, 160, 255);
                    Canvas.DrawTexture(buffIcon, iconFactor);
                }

                // --- Draw new badge at bottom-center ---
                Canvas.StrLen(buffStack, TxtW, TxtH);
                TxtW *= TxtScale;
                TxtH *= TxtScale;
                BadgePad = 2.0f * ResScale;
                BadgeW = TxtW + BadgePad * 2.0f;
                BadgeH = TxtH + BadgePad;
                BadgeX = X + (iconRenderedSz - BadgeW) * 0.5f;
                BadgeY = Y + iconRenderedSz - BadgeH - 1.0f;

                // Badge background
                Canvas.SetDrawColor(0, 0, 0, 200);
                Canvas.SetPos(BadgeX, BadgeY);
                Canvas.DrawRect(BadgeW, BadgeH);

                // Badge border (thin red top line)
                Canvas.SetDrawColor(225, 20, 20, 180);
                Canvas.SetPos(BadgeX, BadgeY);
                Canvas.DrawRect(BadgeW, 1.0f);
                Canvas.SetPos(BadgeX, BadgeY + BadgeH - 1.0f);
                Canvas.DrawRect(BadgeW, 1.0f);

                // Badge text shadow
                Canvas.SetDrawColor(0, 0, 0, 255);
                Canvas.SetPos(BadgeX + BadgePad - 1.0f, BadgeY + BadgePad * 0.5f + 1.0f);
                Canvas.DrawText(buffStack, True, TxtScale, TxtScale);
                // Badge text
                Canvas.SetDrawColor(225, 40, 40, 255);
                Canvas.SetPos(BadgeX + BadgePad, BadgeY + BadgePad * 0.5f);
                Canvas.DrawText(buffStack, True, TxtScale, TxtScale);
            }

            ++nb;
        }
    }
}

// ===================================================================
// OMEN - Prophecy icon lookup
// ===================================================================

function Texture2D GetProphecyIcon(byte Index)
{
    switch (Index)
    {
        // Tier 1
        case 0:  return Texture2D'ZedternalRBPerkpackage_Resources.Buffs.UI_Omen_MarksmanOath';
        case 1:  return Texture2D'ZedternalRBPerkpackage_Resources.Buffs.UI_Omen_IronDiscipline';
        case 2:  return Texture2D'ZedternalRBPerkpackage_Resources.Buffs.UI_Omen_Unwavering';
        case 3:  return Texture2D'ZedternalRBPerkpackage_Resources.Buffs.UI_Omen_Stoneskin';
        case 4:  return Texture2D'ZedternalRBPerkpackage_Resources.Buffs.UI_Omen_CloseQuarters';
        case 5:  return Texture2D'ZedternalRBPerkpackage_Resources.Buffs.UI_Omen_Grounded';
        case 6:  return Texture2D'ZedternalRBPerkpackage_Resources.Buffs.UI_Omen_Unyielding';
        case 7:  return Texture2D'ZedternalRBPerkpackage_Resources.Buffs.UI_Omen_Untouched';
        // Tier 2
        case 8:  return Texture2D'ZedternalRBPerkpackage_Resources.Buffs.UI_Omen_PacifistParadox';
        case 9:  return Texture2D'ZedternalRBPerkpackage_Resources.Buffs.UI_Omen_OneMagazine';
        case 10: return Texture2D'ZedternalRBPerkpackage_Resources.Buffs.UI_Omen_TunnelVision';
        case 11: return Texture2D'ZedternalRBPerkpackage_Resources.Buffs.UI_Omen_BlindFaith';
        case 12: return Texture2D'ZedternalRBPerkpackage_Resources.Buffs.UI_Omen_VowOfStillness';
        case 13: return Texture2D'ZedternalRBPerkpackage_Resources.Buffs.UI_Omen_Disarmed';
        // Tier 3
        case 14: return Texture2D'ZedternalRBPerkpackage_Resources.Buffs.UI_Omen_Executioner';
        case 15: return Texture2D'ZedternalRBPerkpackage_Resources.Buffs.UI_Omen_Ascetic';
        case 16: return Texture2D'ZedternalRBPerkpackage_Resources.Buffs.UI_Omen_Silence';
        case 17: return Texture2D'ZedternalRBPerkpackage_Resources.Buffs.UI_Omen_TriggerDiscipline';
        case 18: return Texture2D'ZedternalRBPerkpackage_Resources.Buffs.UI_Omen_LoneWolf';
        default: return None;
    }
}

// ===================================================================
// OMEN CARD - Compact prophecy display for the card stack system
//
// Shows: tier indicator + prophecy name + condition + reward/doom
// States: active (purple), blessing (gold), doom (red), deny fate (cyan)
// ===================================================================

function DrawOmenCard()
{
    local float BoxX, BoxY, BoxW, BoxH;
    local float CurY, PadX, PadY, TextX;
    local float IconSz, IconPad, IconX, IconY;
    local Color TitleColor, CondColor, RewardColor, DoomColor, WhisperColor, BorderColor;
    local Color IconTint;
    local float TierBarW;
    local float TxtScale, SmallTxtScale, TinyTxtScale;
    local string TierLabel;
    local Texture2D ProphecyIcon;

    if (Canvas == None || !OmenDisplay.bIsActive)
        return;

    // Auto-clear transient states
    if (OmenDisplay.State > 0 && OmenDisplay.StateTimer > 0.0f
        && WorldInfo.TimeSeconds >= OmenDisplay.StateTimer)
    {
        OmenDisplay.bIsActive = False;
        return;
    }

    Canvas.Font = class'KFGameEngine'.Static.GetKFCanvasFont();

    // --- Layout constants (720p baseline) ---
    PadX = 8.0f * ResScale;
    PadY = 5.0f * ResScale;
    TierBarW = 4.0f * ResScale;
    IconSz = 64.0f * ResScale;
    IconPad = 6.0f * ResScale;
    BoxW = 280.0f * ResScale;
    TxtScale = 0.65f * ResScale;
    SmallTxtScale = 0.5f * ResScale;
    TinyTxtScale = 0.42f * ResScale;

    // Position from card stack
    BoxX = Canvas.SizeX * DisplayCardBaseX;
    BoxY = Canvas.SizeY * GetDisplayCardY(CARD_OMEN);
    BoxH = GetOmenCardHeight();

    // --- Fetch icon ---
    ProphecyIcon = GetProphecyIcon(OmenDisplay.IconIndex);

    // --- Color scheme based on state ---
    switch (OmenDisplay.State)
    {
        case 0: // Active prophecy
            TitleColor = MakeColorFromRGB(180, 100, 220, 255);
            CondColor = MakeColorFromRGB(220, 220, 220, 255);
            RewardColor = MakeColorFromRGB(120, 220, 120, 255);
            DoomColor = MakeColorFromRGB(200, 80, 80, 255);
            WhisperColor = MakeColorFromRGB(140, 120, 180, 200);
            BorderColor = MakeColorFromRGB(120, 60, 180, 200);
            IconTint = MakeColorFromRGB(255, 255, 255, 255);
            break;
        case 1: // Blessing complete
            TitleColor = MakeColorFromRGB(255, 215, 0, 255);
            CondColor = MakeColorFromRGB(255, 215, 0, 255);
            RewardColor = MakeColorFromRGB(120, 220, 120, 255);
            DoomColor = MakeColorFromRGB(220, 220, 220, 255);
            WhisperColor = MakeColorFromRGB(255, 215, 0, 200);
            BorderColor = MakeColorFromRGB(200, 170, 0, 200);
            IconTint = MakeColorFromRGB(255, 215, 0, 255);
            break;
        case 2: // Doom
            TitleColor = MakeColorFromRGB(220, 50, 50, 255);
            CondColor = MakeColorFromRGB(220, 80, 80, 255);
            RewardColor = MakeColorFromRGB(220, 220, 220, 255);
            DoomColor = MakeColorFromRGB(220, 50, 50, 255);
            WhisperColor = MakeColorFromRGB(180, 60, 60, 200);
            BorderColor = MakeColorFromRGB(180, 30, 30, 200);
            IconTint = MakeColorFromRGB(220, 50, 50, 255);
            break;
        case 3: // Deny Fate
            TitleColor = MakeColorFromRGB(0, 220, 220, 255);
            CondColor = MakeColorFromRGB(0, 220, 220, 255);
            RewardColor = MakeColorFromRGB(220, 220, 220, 255);
            DoomColor = MakeColorFromRGB(220, 220, 220, 255);
            WhisperColor = MakeColorFromRGB(0, 180, 180, 200);
            BorderColor = MakeColorFromRGB(0, 160, 160, 200);
            IconTint = MakeColorFromRGB(0, 220, 220, 255);
            break;
        default:
            TitleColor = MakeColorFromRGB(180, 100, 220, 255);
            CondColor = MakeColorFromRGB(220, 220, 220, 255);
            RewardColor = MakeColorFromRGB(120, 220, 120, 255);
            DoomColor = MakeColorFromRGB(200, 80, 80, 255);
            WhisperColor = MakeColorFromRGB(140, 120, 180, 200);
            BorderColor = MakeColorFromRGB(120, 60, 180, 200);
            IconTint = MakeColorFromRGB(255, 255, 255, 255);
            break;
    }

    // --- Background ---
    Canvas.SetDrawColor(0, 0, 0, 170);
    Canvas.SetPos(BoxX, BoxY);
    Canvas.DrawRect(BoxW, BoxH);

    // --- Tier bar (left edge, colored by tier) ---
    switch (OmenDisplay.Tier)
    {
        case 1:
            Canvas.SetDrawColor(180, 100, 220, 220);
            TierLabel = "I";
            break;
        case 2:
            Canvas.SetDrawColor(220, 160, 40, 220);
            TierLabel = "II";
            break;
        case 3:
            Canvas.SetDrawColor(220, 50, 50, 220);
            TierLabel = "III";
            break;
        default:
            Canvas.SetDrawColor(180, 100, 220, 220);
            TierLabel = "?";
            break;
    }
    Canvas.SetPos(BoxX, BoxY);
    Canvas.DrawRect(TierBarW, BoxH);

    // --- Border ---
    Canvas.SetDrawColor(BorderColor.R, BorderColor.G, BorderColor.B, BorderColor.A);
    Canvas.SetPos(BoxX, BoxY);                               Canvas.DrawRect(BoxW, 2.0f * ResScale);
    Canvas.SetPos(BoxX, BoxY + BoxH - 2.0f * ResScale);     Canvas.DrawRect(BoxW, 2.0f * ResScale);
    Canvas.SetPos(BoxX, BoxY);                               Canvas.DrawRect(2.0f * ResScale, BoxH);
    Canvas.SetPos(BoxX + BoxW - 2.0f * ResScale, BoxY);     Canvas.DrawRect(2.0f * ResScale, BoxH);

    // --- Icon (left side, vertically centered, state-tinted) ---
    IconX = BoxX + TierBarW + PadX;
    IconY = BoxY + (BoxH - IconSz) * 0.5f;

    if (ProphecyIcon != None)
    {
        Canvas.SetDrawColor(IconTint.R, IconTint.G, IconTint.B, IconTint.A);
        Canvas.SetPos(IconX, IconY);
        Canvas.DrawTile(ProphecyIcon, IconSz, IconSz, 0, 0, ProphecyIcon.SizeX, ProphecyIcon.SizeY);
    }
    else
    {
        Canvas.SetDrawColor(IconTint.R, IconTint.G, IconTint.B, 60);
        Canvas.SetPos(IconX, IconY);
        Canvas.DrawRect(IconSz, IconSz);
    }

    // --- Text area (right of icon) ---
    TextX = IconX + IconSz + IconPad;
    CurY = BoxY + PadY;

    // --- Title line: "[Tier] ProphecyName" ---
    DrawTextWithShadow("[" $ TierLabel $ "] " $ OmenDisplay.Title, TextX, CurY, TitleColor, TxtScale);
    CurY += 14.0f * ResScale + 2.0f * ResScale;

    // --- Condition / status line ---
    DrawTextWithShadow(OmenDisplay.Condition, TextX, CurY, CondColor, SmallTxtScale);
    CurY += 11.0f * ResScale;

    // --- Reward line (if present) ---
    if (OmenDisplay.Reward != "")
    {
        CurY += 1.0f * ResScale;
        DrawTextWithShadow(OmenDisplay.Reward, TextX, CurY, RewardColor, SmallTxtScale);
        CurY += 11.0f * ResScale;
    }

    // --- Doom line (active state only) ---
    if (OmenDisplay.State == 0 && OmenDisplay.Doom != "")
    {
        DrawTextWithShadow(Omen_DoomPrefix $ OmenDisplay.Doom, TextX, CurY, DoomColor, SmallTxtScale);
        CurY += 11.0f * ResScale;
    }

    // --- Whisper line (Level 10+ flavor text) ---
    if (OmenDisplay.Whisper != "")
    {
        CurY += 2.0f * ResScale;
        DrawTextWithShadow(OmenDisplay.Whisper, TextX, CurY, WhisperColor, TinyTxtScale);
    }
}


// ===================================================================
// GFX ABILITY BAR SYSTEM - Initialization, Tick, and Cleanup
// ===================================================================

// ===================================================================
// HOLLOW TRIAL DISPLAY SYSTEM
// Shows weapon trial conditions, progress bars, and unlock notifications.
// Three modes:
//   0 = Progress tracking (persistent, shows condition + bar)
//   1 = Condition complete flash (3s popup)
//   2 = Weapon unlocked flash (5s popup)
// ===================================================================

function InitializeHollowDisplay()
{
    HollowDisplay.bIsActive = false;
    HollowDisplay.DisplayMode = 0;
    HollowDisplay.WeaponName = "";
    HollowDisplay.ActiveCondition = 0;
    HollowDisplay.Progress = 0;
    HollowDisplay.Target = 1;
    HollowDisplay.bIsMelee = 0;
    HollowDisplay.NotifyTimer = 0.0f;
    HollowDisplay.CompletedIdx = 0;
}

/** Update Hollow progress display (Mode 0 - persistent condition tracking).
 *  ActiveCondition 0-4 = which trial, 5 (NUM_CONDITIONS) = all done. */
function UpdateHollowProgress(string InWeaponName, byte InActiveCondition, int InProgress, int InTarget, byte InIsMelee)
{
    HollowDisplay.bIsActive = true;
    HollowDisplay.WeaponName = InWeaponName;
    HollowDisplay.ActiveCondition = InActiveCondition;
    HollowDisplay.Progress = InProgress;
    HollowDisplay.Target = Max(InTarget, 1);
    HollowDisplay.bIsMelee = InIsMelee;

    // Only switch to progress mode if no notification is active
    if (HollowDisplay.DisplayMode > 0 && HollowDisplay.NotifyTimer > 0.0f)
        return;

    HollowDisplay.DisplayMode = 0;
    HollowDisplay.NotifyTimer = 0.0f;
}

/** Condition completed flash (Mode 1 - 3 second popup). */
function ShowHollowConditionComplete(string InWeaponName, byte InConditionIdx)
{
    HollowDisplay.bIsActive = true;
    HollowDisplay.DisplayMode = 1;
    HollowDisplay.WeaponName = InWeaponName;
    HollowDisplay.CompletedIdx = InConditionIdx;
    HollowDisplay.NotifyTimer = 3.0f;
}

/** Weapon fully unlocked flash (Mode 2 - 5 second popup). */
function ShowHollowWeaponUnlock(string InWeaponName)
{
    HollowDisplay.bIsActive = true;
    HollowDisplay.DisplayMode = 2;
    HollowDisplay.WeaponName = InWeaponName;
    HollowDisplay.NotifyTimer = 5.0f;
}

/** Clear the Hollow display. */
function ClearHollowDisplay()
{
    HollowDisplay.bIsActive = false;
}

/** Store a shatter threshold for a weapon (received from server via RPC). */
function SetHollowShatterThreshold(string InWeaponName, float InThreshold)
{
    local SShatterCache Entry;
    local int i;

    // Update existing entry if present
    for (i = 0; i < HollowShatterCache.Length; ++i)
    {
        if (HollowShatterCache[i].NormName == InWeaponName)
        {
            HollowShatterCache[i].Threshold = InThreshold;
            return;
        }
    }

    // New entry
    Entry.NormName = InWeaponName;
    Entry.Threshold = InThreshold;
    HollowShatterCache.AddItem(Entry);
}

/** Look up cached shatter threshold for a weapon. Returns 0.0 if not found. */
function float GetCachedShatterThreshold(string NormName)
{
    local int i;

    for (i = 0; i < HollowShatterCache.Length; ++i)
    {
        if (HollowShatterCache[i].NormName == NormName)
            return HollowShatterCache[i].Threshold;
    }

    return 0.0f;
}

/** Return condition label for a given condition index.
 *  Must match AdvanceCondition in ZTUpgrade_Perk_Hollow_Helper. */
function string GetHollowConditionLabel(byte CondIdx, byte bMelee)
{
    switch (CondIdx)
    {
        case 0: return Hollow_Cond_Headshot;
        case 1: return Hollow_Cond_TotalKills;
        case 2: return Hollow_Cond_Collateral;
        case 3:
            if (bMelee != 0)
                return Hollow_Cond_Melee;
            else
                return Hollow_Cond_Rapid;
        case 4: return Hollow_Cond_LargeZed;
        default: return Hollow_Cond_Complete;
    }
}

/** Map condition index to icon texture. 128x128 source, drawn at 64px. */
function Texture2D GetHollowConditionIcon(byte CondIdx, byte bMelee, byte Mode)
{
    // Notification mode icons override condition icons
    if (Mode == 1)
        return Texture2D'ZedternalRBPerkpackage_Resources.Buffs.UI_Hollow_ConditionComplete';
    if (Mode == 2)
        return Texture2D'ZedternalRBPerkpackage_Resources.Buffs.UI_Hollow_WeaponUnlock';

    switch (CondIdx)
    {
        case 0: return Texture2D'ZedternalRBPerkpackage_Resources.Buffs.UI_Hollow_Headshot';
        case 1: return Texture2D'ZedternalRBPerkpackage_Resources.Buffs.UI_Hollow_TotalKills';
        case 2: return Texture2D'ZedternalRBPerkpackage_Resources.Buffs.UI_Hollow_Collateral';
        case 3:
            if (bMelee != 0)
                return Texture2D'ZedternalRBPerkpackage_Resources.Buffs.UI_Hollow_MeleeKills';
            else
                return Texture2D'ZedternalRBPerkpackage_Resources.Buffs.UI_Hollow_RapidKills';
        case 4: return Texture2D'ZedternalRBPerkpackage_Resources.Buffs.UI_Hollow_LargeZed';
        default: return Texture2D'ZedternalRBPerkpackage_Resources.Buffs.UI_Hollow_ConditionComplete';
    }
}

/** Get card pixel height based on display mode.
 *  Matches Artificer card sizing pattern (ResScale-based). */
function float GetHollowCardHeight()
{
    local float PadY, LineH, SmallLineH, IconSz, BarH;

    if (!HollowDisplay.bIsActive)
        return 0.0f;

    PadY = 6.0f * ResScale;
    LineH = 18.0f * ResScale;
    SmallLineH = 14.0f * ResScale;
    IconSz = 48.0f * ResScale;
    BarH = 6.0f * ResScale;

    switch (HollowDisplay.DisplayMode)
    {
        case 0:  // Progress: title + condition + gap + bar + gap
            return FMax(PadY * 2.0f + LineH + SmallLineH + PadY + BarH + 4.0f * ResScale, IconSz + PadY * 2.0f);
        case 1:  // Condition complete: title + condition name
            return FMax(PadY * 2.0f + LineH + SmallLineH, IconSz + PadY * 2.0f);
        case 2:  // Weapon unlock: title + weapon name
            return FMax(PadY * 2.0f + LineH + SmallLineH, IconSz + PadY * 2.0f);
        default:
            return IconSz + PadY * 2.0f;
    }
}

/** Main draw function for the Hollow trial card.
 *  Matches Artificer card sizing: ResScale-based, 0.6f text,
 *  48px icon, 280px width, GetCleanWeaponName for display. */
function DrawHollowCard()
{
    local float BoxX, BoxY, BoxW, BoxH;
    local float PadX, PadY, LineH, SmallLineH;
    local float CurY, TextX;
    local float IconSz, IconPad;
    local float BarX, BarW, BarH, BarFill;
    local Texture2D Icon;
    local Color TitleColor, TextColor, AccentColor, BorderColor;
    local byte Mode;
    local string CondLabel, CleanName;
    local float NotifyAlpha;

    if (Canvas == None)
        return;

    Mode = HollowDisplay.DisplayMode;

    // --- Update notification timer ---
    if (Mode > 0 && HollowDisplay.NotifyTimer > 0.0f)
    {
        HollowDisplay.NotifyTimer -= RenderDelta;
        if (HollowDisplay.NotifyTimer <= 0.0f)
        {
            // Timer expired - revert to progress mode or hide
            if (HollowDisplay.ActiveCondition < 5)
            {
                HollowDisplay.DisplayMode = 0;
                Mode = 0;
            }
            else
            {
                HollowDisplay.bIsActive = false;
                return;
            }
        }
    }

    // --- Layout: match Artificer card sizing ---
    PadX = 8.0f * ResScale;
    PadY = 6.0f * ResScale;
    LineH = 18.0f * ResScale;
    SmallLineH = 14.0f * ResScale;
    IconSz = 48.0f * ResScale;
    IconPad = 8.0f * ResScale;
    BoxW = 280.0f * ResScale;

    // Normalized position from card stacking system
    BoxX = Canvas.SizeX * DisplayCardBaseX;
    BoxY = Canvas.SizeY * GetDisplayCardY(CARD_HOLLOW);
    BoxH = GetHollowCardHeight();

    // Text column starts after icon
    TextX = BoxX + PadX + IconSz + IconPad;

    // --- Colors: purple/void theme ---
    TitleColor = MakeColorFromRGB(180, 130, 255, 255);
    TextColor = MakeColorFromRGB(220, 220, 220, 255);
    AccentColor = MakeColorFromRGB(160, 80, 240, 255);
    BorderColor = MakeColorFromRGB(120, 60, 180, 200);

    // --- Fade alpha for notifications in last 0.5s ---
    if (Mode > 0 && HollowDisplay.NotifyTimer < 0.5f && HollowDisplay.NotifyTimer > 0.0f)
        NotifyAlpha = HollowDisplay.NotifyTimer / 0.5f;
    else
        NotifyAlpha = 1.0f;

    // Clean weapon name for display
    CleanName = GetCleanWeaponName(HollowDisplay.WeaponName);

    Canvas.Font = class'KFGameEngine'.Static.GetKFCanvasFont();

    // --- Background ---
    Canvas.SetDrawColor(0, 0, 0, int(160.0f * NotifyAlpha));
    Canvas.SetPos(BoxX, BoxY);
    Canvas.DrawRect(BoxW, BoxH);

    // --- Border (4 edges, 2px scaled) ---
    Canvas.SetDrawColor(BorderColor.R, BorderColor.G, BorderColor.B, int(float(BorderColor.A) * NotifyAlpha));
    Canvas.SetPos(BoxX, BoxY);                                Canvas.DrawRect(BoxW, 2.0f * ResScale);
    Canvas.SetPos(BoxX, BoxY + BoxH - 2.0f * ResScale);      Canvas.DrawRect(BoxW, 2.0f * ResScale);
    Canvas.SetPos(BoxX, BoxY);                                Canvas.DrawRect(2.0f * ResScale, BoxH);
    Canvas.SetPos(BoxX + BoxW - 2.0f * ResScale, BoxY);      Canvas.DrawRect(2.0f * ResScale, BoxH);

    // --- Icon (vertically centered) ---
    Icon = GetHollowConditionIcon(HollowDisplay.ActiveCondition, HollowDisplay.bIsMelee, Mode);
    if (Icon != None)
    {
        Canvas.SetDrawColor(255, 255, 255, int(255.0f * NotifyAlpha));
        Canvas.SetPos(BoxX + PadX, BoxY + (BoxH - IconSz) * 0.5f);
        Canvas.DrawTile(Icon, IconSz, IconSz, 0, 0, Icon.SizeX, Icon.SizeY);
    }

    CurY = BoxY + PadY;

    switch (Mode)
    {
        // ===== MODE 0: Progress Tracking =====
        case 0:
            // Title: weapon name
            DrawTextWithShadow(CleanName, TextX, CurY, TitleColor, 0.6f * ResScale);
            CurY += LineH;

            // Condition label + count
            if (HollowDisplay.ActiveCondition < 5)
            {
                CondLabel = GetHollowConditionLabel(HollowDisplay.ActiveCondition, HollowDisplay.bIsMelee);
                DrawTextWithShadow(CondLabel $ ":" @ string(HollowDisplay.Progress) $ "/" $ string(HollowDisplay.Target),
                    TextX, CurY, TextColor, 0.55f * ResScale);
                CurY += SmallLineH + PadY;

                // Progress bar
                BarX = TextX;
                BarW = (BoxX + BoxW - PadX) - TextX;
                BarH = 6.0f * ResScale;
                BarFill = FClamp(float(HollowDisplay.Progress) / float(HollowDisplay.Target), 0.0f, 1.0f);

                Canvas.SetDrawColor(40, 40, 40, 200);
                Canvas.SetPos(BarX, CurY);
                Canvas.DrawRect(BarW, BarH);

                Canvas.SetDrawColor(AccentColor.R, AccentColor.G, AccentColor.B, 200);
                Canvas.SetPos(BarX, CurY);
                Canvas.DrawRect(BarW * BarFill, BarH);
            }
            else
            {
                // All Trials Complete - show shatter threshold if available
                if (HollowDisplay.Progress > 0)
                {
                    // Progress contains threshold * 1000 (e.g. 350 = 35.0%)
                    DrawTextWithShadow(Hollow_CallOfVoid @ string(HollowDisplay.Progress / 10) $ "." $ string(HollowDisplay.Progress % 10) $ "%",
                        TextX, CurY, AccentColor, 0.55f * ResScale);
                }
                else
                {
                    DrawTextWithShadow(Hollow_AllTrialsComplete, TextX, CurY, AccentColor, 0.55f * ResScale);
                }
            }
            break;

        // ===== MODE 1: Condition Complete =====
        case 1:
            CondLabel = GetHollowConditionLabel(HollowDisplay.CompletedIdx, HollowDisplay.bIsMelee);

            DrawTextWithShadow(Hollow_TrialComplete, TextX, CurY, AccentColor, 0.6f * ResScale);
            CurY += LineH;

            DrawTextWithShadow(CondLabel @ "-" @ CleanName, TextX, CurY, TextColor, 0.55f * ResScale);
            break;

        // ===== MODE 2: Weapon Unlocked =====
        case 2:
            DrawTextWithShadow(Hollow_WeaponUnlocked, TextX, CurY, TitleColor, 0.6f * ResScale);
            CurY += LineH;

            DrawTextWithShadow(Hollow_Prefix @ CleanName, TextX, CurY, TextColor, 0.55f * ResScale);
            break;
    }
}

// ===================================================================
// METRONOME PHASE DISPLAY - Card Stack System
// ===================================================================

/** Update Metronome display data (called by helper RPC). */
function UpdateMetronomeCard(
    byte Phase,
    byte PhaseTimePct,
    byte SyncKills,
    byte SyncTarget,
    byte S0, byte S1, byte S2, byte S3,
    bool bHarmony,
    byte HarmPhase,
    bool bCrescendo)
{
    MetronomeDisplay.bIsActive = true;
    MetronomeDisplay.CurrentPhase = Phase;
    MetronomeDisplay.PhaseTimePct = PhaseTimePct;
    MetronomeDisplay.SyncKills = SyncKills;
    MetronomeDisplay.SyncTarget = SyncTarget;
    MetronomeDisplay.Stacks_0 = S0;
    MetronomeDisplay.Stacks_1 = S1;
    MetronomeDisplay.Stacks_2 = S2;
    MetronomeDisplay.Stacks_3 = S3;
    MetronomeDisplay.bHarmonyActive = bHarmony;
    MetronomeDisplay.HarmonyPhase = HarmPhase;
    MetronomeDisplay.bCrescendoActive = bCrescendo;
}

/** Clear Metronome display. */
function ClearMetronomeCard()
{
    MetronomeDisplay.bIsActive = false;
}

/** Compute pixel height of Metronome card. */
function float GetMetronomeCardHeight()
{
    // PadY(6) + PhaseName(18) + TimeBar(8) + gap(4) + SyncLine(14) + gap(4)
    // + StacksHeader(14) + StacksRow(14) + PadY(6) = 88
    // Icon column: 64 + 2*PadY(12) = 76 - card governed by text height
    local float Height;

    if (!MetronomeDisplay.bIsActive)
        return 0.0f;

    Height = 88.0f;

    if (MetronomeDisplay.bHarmonyActive || MetronomeDisplay.bCrescendoActive)
        Height += 16.0f;

    return Height * ResScale;
}

/** Get phase display name. */
function string GetMetronomePhaseName(byte Phase)
{
    switch (Phase)
    {
        case 0: return Metronome_Phase_Assault;
        case 1: return Metronome_Phase_Tempo;
        case 2: return Metronome_Phase_Momentum;
        case 3: return Metronome_Phase_Bastion;
        default: return Metronome_Phase_Unknown;
    }
}

/** Get phase sync condition hint. */
function string GetMetronomeSyncHint(byte Phase)
{
    switch (Phase)
    {
        case 0: return Metronome_Sync_Headshot;
        case 1: return Metronome_Sync_Rapid;
        case 2: return Metronome_Sync_Moving;
        case 3: return Metronome_Sync_Close;
        default: return "";
    }
}

/** Get phase primary color. */
function Color GetMetronomePhaseColor(byte Phase)
{
    switch (Phase)
    {
        case 0: return MakeColorFromRGB(255, 68, 68, 255);     // Red - Assault
        case 1: return MakeColorFromRGB(68, 221, 255, 255);    // Cyan - Tempo
        case 2: return MakeColorFromRGB(68, 255, 68, 255);     // Green - Momentum
        case 3: return MakeColorFromRGB(255, 170, 34, 255);    // Orange - Bastion
        default: return MakeColorFromRGB(200, 200, 200, 255);
    }
}

/** Get phase icon Texture2D asset. */
function Texture2D GetMetronomePhaseIcon(byte Phase)
{
    switch (Phase)
    {
        case 0: return Texture2D'ZedternalRBPerkpackage_Resources.Buffs.UI_Metronome_Phase_Assault';
        case 1: return Texture2D'ZedternalRBPerkpackage_Resources.Buffs.UI_Metronome_Phase_Tempo';
        case 2: return Texture2D'ZedternalRBPerkpackage_Resources.Buffs.UI_Metronome_Phase_Momentum';
        case 3: return Texture2D'ZedternalRBPerkpackage_Resources.Buffs.UI_Metronome_Phase_Bastion';
        default: return None;
    }
}

/** Draw the Metronome HUD card. */
function DrawMetronomeCard()
{
    local float BoxX, BoxY, BoxW, BoxH;
    local float PadX, PadY, LineH, SmallLineH;
    local float BarX, BarW, BarH, BarFill;
    local float CurY, TextX;
    local float IconSz, IconPad;
    local float IndicatorSz, IndicatorX;
    local Color PhaseColor, TextColor, DimColor, CrescendoColor, IndColor;
    local string SyncText;
    local Texture2D PhaseIcon;
    local byte i;
    local int StackVal;

    if (Canvas == None)
        return;

    // --- Layout constants (guide-standard sizes, scaled) ---
    PadX = 8.0f * ResScale;
    PadY = 6.0f * ResScale;
    LineH = 18.0f * ResScale;
    SmallLineH = 14.0f * ResScale;
    IconSz = 64.0f * ResScale;     // Guide standard: 128px source rendered at 64px
    IconPad = 8.0f * ResScale;
    IndicatorSz = 10.0f * ResScale; // Small colored squares for phase stacks
    BoxW = 280.0f * ResScale;

    // Position from card stacking system
    BoxX = Canvas.SizeX * DisplayCardBaseX;
    BoxY = Canvas.SizeY * GetDisplayCardY(CARD_METRONOME);
    BoxH = GetMetronomeCardHeight();

    // Colors
    PhaseColor = GetMetronomePhaseColor(MetronomeDisplay.CurrentPhase);
    TextColor = MakeColorFromRGB(220, 220, 220, 255);
    DimColor = MakeColorFromRGB(140, 140, 140, 255);
    CrescendoColor = MakeColorFromRGB(255, 255, 100, 255);

    TextX = BoxX + PadX + IconSz + IconPad;

    Canvas.Font = class'KFGameEngine'.Static.GetKFCanvasFont();

    // --- Background ---
    if (MetronomeDisplay.bCrescendoActive)
        Canvas.SetDrawColor(30, 30, 10, 180);
    else
        Canvas.SetDrawColor(0, 0, 0, 160);
    Canvas.SetPos(BoxX, BoxY);
    Canvas.DrawRect(BoxW, BoxH);

    // --- Border (2px, phase-colored) ---
    if (MetronomeDisplay.bCrescendoActive)
        Canvas.SetDrawColor(CrescendoColor.R, CrescendoColor.G, CrescendoColor.B, 220);
    else
        Canvas.SetDrawColor(PhaseColor.R, PhaseColor.G, PhaseColor.B, 200);

    Canvas.SetPos(BoxX, BoxY);                                Canvas.DrawRect(BoxW, 2.0f * ResScale);
    Canvas.SetPos(BoxX, BoxY + BoxH - 2.0f * ResScale);      Canvas.DrawRect(BoxW, 2.0f * ResScale);
    Canvas.SetPos(BoxX, BoxY);                                Canvas.DrawRect(2.0f * ResScale, BoxH);
    Canvas.SetPos(BoxX + BoxW - 2.0f * ResScale, BoxY);      Canvas.DrawRect(2.0f * ResScale, BoxH);

    // --- Main Icon: current phase (64px, vertically centered, inside card) ---
    PhaseIcon = GetMetronomePhaseIcon(MetronomeDisplay.CurrentPhase);
    if (PhaseIcon != None)
    {
        Canvas.SetDrawColor(255, 255, 255, 255);
        Canvas.SetPos(BoxX + PadX, BoxY + (BoxH - IconSz) * 0.5f);
        Canvas.DrawTile(PhaseIcon, IconSz, IconSz, 0, 0, PhaseIcon.SizeX, PhaseIcon.SizeY);
    }

    // --- Phase Name ---
    CurY = BoxY + PadY;

    if (MetronomeDisplay.bCrescendoActive)
    {
        DrawTextWithShadow(Metronome_Crescendo, TextX, CurY, CrescendoColor, 0.65f * ResScale);
    }
    else
    {
        DrawTextWithShadow(GetMetronomePhaseName(MetronomeDisplay.CurrentPhase), TextX, CurY, PhaseColor, 0.65f * ResScale);
    }
    CurY += LineH;

    // --- Phase Timer Bar ---
    BarX = TextX;
    BarW = (BoxX + BoxW - PadX) - TextX;
    BarH = 8.0f * ResScale;
    BarFill = FClamp(float(MetronomeDisplay.PhaseTimePct) / 100.0f, 0.0f, 1.0f);

    Canvas.SetDrawColor(40, 40, 40, 200);
    Canvas.SetPos(BarX, CurY);
    Canvas.DrawRect(BarW, BarH);

    if (MetronomeDisplay.bCrescendoActive)
        Canvas.SetDrawColor(CrescendoColor.R, CrescendoColor.G, CrescendoColor.B, 200);
    else
        Canvas.SetDrawColor(PhaseColor.R, PhaseColor.G, PhaseColor.B, 200);
    Canvas.SetPos(BarX, CurY);
    Canvas.DrawRect(BarW * BarFill, BarH);

    CurY += BarH + 4.0f * ResScale;

    // --- Sync Kill Counter ---
    SyncText = Metronome_SyncLabel @ MetronomeDisplay.SyncKills $ "/" $ MetronomeDisplay.SyncTarget
        @ "-" @ GetMetronomeSyncHint(MetronomeDisplay.CurrentPhase);

    if (MetronomeDisplay.SyncKills >= MetronomeDisplay.SyncTarget)
        DrawTextWithShadow(SyncText, TextX, CurY, PhaseColor, 0.55f * ResScale);
    else
        DrawTextWithShadow(SyncText, TextX, CurY, TextColor, 0.55f * ResScale);

    CurY += SmallLineH + 4.0f * ResScale;

    // --- Permanent Stacks: labeled header ---
    DrawTextWithShadow(Metronome_RhythmBonus, TextX, CurY, DimColor, 0.5f * ResScale);
    CurY += SmallLineH;

    // --- Permanent Stacks: 4 colored squares with +N labels ---
    // Each entry: [colored square] +N   spaced evenly across text area
    IndicatorX = TextX;
    for (i = 0; i < 4; i++)
    {
        switch (i)
        {
            case 0: StackVal = MetronomeDisplay.Stacks_0; break;
            case 1: StackVal = MetronomeDisplay.Stacks_1; break;
            case 2: StackVal = MetronomeDisplay.Stacks_2; break;
            case 3: StackVal = MetronomeDisplay.Stacks_3; break;
        }

        // Colored square indicator
        IndColor = GetMetronomePhaseColor(i);
        if (i == MetronomeDisplay.CurrentPhase)
            Canvas.SetDrawColor(IndColor.R, IndColor.G, IndColor.B, 230);
        else
            Canvas.SetDrawColor(IndColor.R, IndColor.G, IndColor.B, 120);

        Canvas.SetPos(IndicatorX, CurY + 2.0f * ResScale);
        Canvas.DrawRect(IndicatorSz, IndicatorSz);

        // +N text next to the square
        DrawTextWithShadow("+" $ StackVal, IndicatorX + IndicatorSz + 2.0f * ResScale, CurY, DimColor, 0.45f * ResScale);

        // Advance X for next indicator (evenly spaced across text area)
        IndicatorX += 38.0f * ResScale;
    }

    CurY += SmallLineH;

    // --- Harmony / Crescendo Status Line ---
    if (MetronomeDisplay.bCrescendoActive)
    {
        DrawTextWithShadow(Metronome_AllPhases, TextX, CurY, CrescendoColor, 0.55f * ResScale);
    }
    else if (MetronomeDisplay.bHarmonyActive && MetronomeDisplay.HarmonyPhase < 4)
    {
        DrawTextWithShadow(Metronome_HarmonyPrefix $ GetMetronomePhaseName(MetronomeDisplay.HarmonyPhase),
            TextX, CurY, GetMetronomePhaseColor(MetronomeDisplay.HarmonyPhase), 0.5f * ResScale);
    }
}

// ===================================================================
// DETONATOR DISPLAY - Card Stack System
// ===================================================================

/** Update Detonator display data (called by helper RPC).
 *  Server builds all primitive values; client just renders. */
function UpdateDetonatorDisplay(
    bool bActive,
    bool bWindowActive,
    byte PerkLvl,
    int Counter,
    int Threshold,
    byte SecondsLeft,
    byte MaxSeconds,
    int ApexBank)
{
    DetonatorDisplay.bIsActive = bActive;
    DetonatorDisplay.bWindowActive = bWindowActive;
    DetonatorDisplay.PerkLevel = PerkLvl;
    DetonatorDisplay.Counter = Counter;
    DetonatorDisplay.Threshold = Threshold;
    DetonatorDisplay.SecondsLeft = SecondsLeft;
    DetonatorDisplay.MaxSeconds = MaxSeconds;
    DetonatorDisplay.ApexBank = ApexBank;
}

/** Clear Detonator display (e.g. on death / perk removed). */
function ClearDetonatorDisplay()
{
    DetonatorDisplay.bIsActive = false;
}

/** Compute pixel height of the Detonator card. */
function float GetDetonatorCardHeight()
{
    local float Height;

    if (!DetonatorDisplay.bIsActive)
        return 0.0f;

    // PadY(6) + Title(18) + ProgressBar(10) + Gap(4) + ProgressText(14)
    // + PadY(6) = 58 (content). Min 78 to fit 64px icon column with padding.
    Height = 78.0f;

    // Extra line for Apex Charge bank if any pre-charge is banked.
    if (DetonatorDisplay.ApexBank > 0)
        Height += 14.0f;

    return Height * ResScale;
}

/** Get Detonator icon for current mode (charging vs active). */
function Texture2D GetDetonatorIcon()
{
    if (DetonatorDisplay.bWindowActive)
        return Texture2D'ZedternalRBPerkpackage_Resources.Buffs.UI_Detonator_Active';

    return Texture2D'ZedternalRBPerkpackage_Resources.Buffs.UI_Detonator_Charging';
}

/** Draw the Detonator HUD card. */
function DrawDetonatorCard()
{
    local float BoxX, BoxY, BoxW, BoxH;
    local float PadX, PadY, LineH, SmallLineH;
    local float BarX, BarW, BarH, BarFill;
    local float CurY, TextX;
    local float IconSz, IconPad;
    local Color AccentColor, TextColor, DimColor;
    local Texture2D Icon;
    local string Title, ProgressText, BankText;

    if (Canvas == None)
        return;

    // --- Layout constants (guide-standard sizes, scaled) ---
    PadX = 8.0f * ResScale;
    PadY = 6.0f * ResScale;
    LineH = 18.0f * ResScale;
    SmallLineH = 14.0f * ResScale;
    IconSz = 64.0f * ResScale;
    IconPad = 8.0f * ResScale;
    BoxW = 280.0f * ResScale;
    BarH = 10.0f * ResScale;

    // Position from card stacking system
    BoxX = Canvas.SizeX * DisplayCardBaseX;
    BoxY = Canvas.SizeY * GetDisplayCardY(CARD_DETONATOR);
    BoxH = GetDetonatorCardHeight();

    // --- Colors: orange charging / red active ---
    if (DetonatorDisplay.bWindowActive)
        AccentColor = MakeColorFromRGB(255, 60, 60, 255);
    else
        AccentColor = MakeColorFromRGB(255, 140, 50, 255);

    TextColor = MakeColorFromRGB(220, 220, 220, 255);
    DimColor = MakeColorFromRGB(160, 160, 160, 255);

    TextX = BoxX + PadX + IconSz + IconPad;

    Canvas.Font = class'KFGameEngine'.Static.GetKFCanvasFont();

    // --- Background ---
    Canvas.SetDrawColor(0, 0, 0, 160);
    Canvas.SetPos(BoxX, BoxY);
    Canvas.DrawRect(BoxW, BoxH);

    // --- Border (2px, accent-colored) ---
    Canvas.SetDrawColor(AccentColor.R, AccentColor.G, AccentColor.B, 200);
    Canvas.SetPos(BoxX, BoxY);                                Canvas.DrawRect(BoxW, 2.0f * ResScale);
    Canvas.SetPos(BoxX, BoxY + BoxH - 2.0f * ResScale);      Canvas.DrawRect(BoxW, 2.0f * ResScale);
    Canvas.SetPos(BoxX, BoxY);                                Canvas.DrawRect(2.0f * ResScale, BoxH);
    Canvas.SetPos(BoxX + BoxW - 2.0f * ResScale, BoxY);      Canvas.DrawRect(2.0f * ResScale, BoxH);

    // --- Icon (left, vertically centered) ---
    Icon = GetDetonatorIcon();
    if (Icon != None)
    {
        Canvas.SetDrawColor(255, 255, 255, 255);
        Canvas.SetPos(BoxX + PadX, BoxY + (BoxH - IconSz) * 0.5f);
        Canvas.DrawTile(Icon, IconSz, IconSz, 0, 0, Icon.SizeX, Icon.SizeY);
    }

    // --- Title ---
    CurY = BoxY + PadY;
    if (DetonatorDisplay.bWindowActive)
        Title = Detonator_Active;
    else
        Title = Detonator_Title;
    DrawTextWithShadow(Title, TextX, CurY, AccentColor, 0.7f * ResScale);
    CurY += LineH;

    // --- Progress / countdown bar ---
    BarX = TextX;
    BarW = (BoxX + BoxW - PadX) - TextX;

    if (DetonatorDisplay.bWindowActive)
    {
        BarFill = (DetonatorDisplay.MaxSeconds > 0)
            ? FClamp(float(DetonatorDisplay.SecondsLeft) / float(DetonatorDisplay.MaxSeconds), 0.0f, 1.0f)
            : 0.0f;
    }
    else
    {
        BarFill = (DetonatorDisplay.Threshold > 0)
            ? FClamp(float(DetonatorDisplay.Counter) / float(DetonatorDisplay.Threshold), 0.0f, 1.0f)
            : 0.0f;
    }

    // Bar background
    Canvas.SetDrawColor(40, 40, 40, 200);
    Canvas.SetPos(BarX, CurY);
    Canvas.DrawRect(BarW, BarH);

    // Bar fill
    Canvas.SetDrawColor(AccentColor.R, AccentColor.G, AccentColor.B, 200);
    Canvas.SetPos(BarX, CurY);
    Canvas.DrawRect(BarW * BarFill, BarH);

    CurY += BarH + 4.0f * ResScale;

    // --- Status text ---
    if (DetonatorDisplay.bWindowActive)
        ProgressText = Detonator_WindowLabel @ DetonatorDisplay.SecondsLeft $ Detonator_SecondsRemaining;
    else
        ProgressText = Detonator_ChargeLabel @ DetonatorDisplay.Counter $ "/" $ DetonatorDisplay.Threshold @ Detonator_KillsSuffix;

    DrawTextWithShadow(ProgressText, TextX, CurY, TextColor, 0.55f * ResScale);
    CurY += SmallLineH;

    // --- Apex Charge bank line (if any) ---
    if (DetonatorDisplay.ApexBank > 0)
    {
        BankText = Detonator_ApexBankLabel $ DetonatorDisplay.ApexBank;
        DrawTextWithShadow(BankText, TextX, CurY, DimColor, 0.5f * ResScale);
    }
}

/**
 * Cleanup on destruction
 */
event Destroyed()
{
    super.Destroyed();
}

// ===================================================================
// EVENT WAVE OVERLAY - State machine and banner rendering
// ===================================================================

function UpdateEventWaveState()
{
    local ZTGameReplicationInfo DKGRI;
    local byte GRIID;
    local float DT;

    DKGRI = ZTGameReplicationInfo(KFGRI);
    if (DKGRI == None)
    {
        EventWaveOverlayID = 0;
        EventWaveAlpha = 0.f;
        return;
    }

    GRIID = DKGRI.ActiveEventWaveID;
    DT = WorldInfo.DeltaSeconds;

    // New OR CHANGED event. Tracking GRIID even when a previous event's ID
    // is still showing prevents a stale client effect (e.g. Paranoia phantom
    // sounds) from sticking if the client ever misses the brief
    // ActiveEventWaveID==0 window between waves. The per-effect "!= X" cleanups
    // below then switch the previous effect off on the next tick.
    if (GRIID > 0 && GRIID != EventWaveOverlayID && !bEventWaveFadingOut)
    {
        EventWaveOverlayID = GRIID;
        EventWaveStartTimeLocal = WorldInfo.TimeSeconds;
        EventWaveBannerTimer = EVENT_BANNER_DURATION;
    }
    // Event ended - begin fade out
    else if (GRIID == 0 && EventWaveOverlayID > 0 && !bEventWaveFadingOut)
    {
        bEventWaveFadingOut = True;
    }

    // Fade logic
    if (bEventWaveFadingOut)
    {
        EventWaveAlpha -= DT / EVENT_FADE_OUT_TIME;
        if (EventWaveAlpha <= 0.f)
        {
            EventWaveAlpha = 0.f;
            EventWaveOverlayID = 0;
            bEventWaveFadingOut = False;
        }
    }
    else if (EventWaveOverlayID > 0)
    {
        if (EventWaveAlpha < 1.f)
        {
            EventWaveAlpha += DT / EVENT_FADE_IN_TIME;
            if (EventWaveAlpha > 1.f)
                EventWaveAlpha = 1.f;
        }
    }

    // Banner countdown
    if (EventWaveBannerTimer > 0.f)
    {
        EventWaveBannerTimer -= DT;
        if (EventWaveBannerTimer < 0.f)
            EventWaveBannerTimer = 0.f;
    }

    // === ISOLATION (Event 7): Hide/unhide other players ===
    if (EventWaveOverlayID == 7 && !bIsolationActive && EventWaveAlpha >= 0.5f)
    {
        SetOtherPlayersHidden(True);
        bIsolationActive = True;
    }
    else if (EventWaveOverlayID != 7 && bIsolationActive)
    {
        SetOtherPlayersHidden(False);
        bIsolationActive = False;
    }

    // === DEAD SILENCE (Event 11): Mute/restore audio ===
    if (EventWaveOverlayID == 11 && !bDeadSilenceActive && EventWaveAlpha >= 0.5f)
    {
        MuteGameAudio();
        bDeadSilenceActive = True;
    }
    else if (EventWaveOverlayID != 11 && bDeadSilenceActive)
    {
        RestoreGameAudio();
        bDeadSilenceActive = False;
    }

    // === PARANOIA (Event 17): Play fake zed sounds ===
    if (EventWaveOverlayID == 17 && EventWaveAlpha >= 0.5f)
    {
        ParanoiaSoundTimer -= DT;
        if (ParanoiaSoundTimer <= 0.f)
        {
            PlayParanoiaSound();
            ParanoiaSoundTimer = 0.5f + FRand() * 2.f;
        }
    }

    // === REDACTED (Event 19): Hide/show Flash HUD via bShowHUD ===
    if (EventWaveOverlayID == 19 && !bRedactedHUDHidden && EventWaveAlpha >= 0.5f)
    {
        bShowHUD = false;
        bRedactedHUDHidden = True;
    }
    else if (EventWaveOverlayID != 19 && bRedactedHUDHidden)
    {
        bShowHUD = true;
        bRedactedHUDHidden = False;
    }
}

function DrawEventWaveBanner()
{
    local string EventName, EventDesc;
    local Color EventColor;
    local Texture2D EventIcon;
    local float W, BannerAlpha, BannerY, SlideProgress;
    local float IconSz, PadX, PadY, TextGap;
    local float BgTop, BgH;
    local float SubTitleH, NameH, DescH;
    local float TotalTextH, ContentCenterY;
    local float BannerCenterX, BlockW, IconX, TextX, CurY;
    local float TempW, TempH;
    local byte A;

    if (EventWaveOverlayID == 0 || EventWaveBannerTimer <= 0.f)
        return;

    W = Canvas.SizeX;

    EventName = class'ZTConfig_EventWave'.static.GetEventName(EventWaveOverlayID);
    EventDesc = class'ZTConfig_EventWave'.static.GetEventDescription(EventWaveOverlayID);
    EventColor = class'ZTEventWave'.static.GetEventColor(EventWaveOverlayID);
    EventIcon = class'ZTEventWave'.static.GetEventIcon(EventWaveOverlayID);

    // Fixed pixel sizes
    IconSz = 48.0f;
    PadX = 12.0f;
    PadY = 10.0f;
    TextGap = 4.0f;

    // Fade: full alpha for first (DURATION-1)s, fade out in last 1s
    if (EventWaveBannerTimer > 1.0f)
        BannerAlpha = 1.0f;
    else
        BannerAlpha = EventWaveBannerTimer;

    // Measure text heights (fixed scales)
    Canvas.Font = class'KFGameEngine'.Static.GetKFCanvasFont();

    Canvas.TextSize(EventWave_Subtitle, TempW, SubTitleH, 0.7f, 0.7f);
    Canvas.TextSize(Caps(EventName), TempW, NameH, 1.0f, 1.0f);
    if (EventDesc != "")
    {
        Canvas.TextSize(EventDesc, TempW, DescH, 0.75f, 0.75f);
    }
    else
    {
        DescH = 0.0f;
    }

    // Total content height: subtitle + name + description + gaps
    TotalTextH = SubTitleH + TextGap + NameH;
    if (DescH > 0.0f)
        TotalTextH += TextGap + DescH;

    // Background height: fits icon or text column, whichever is taller
    BgH = FMax(IconSz, TotalTextH) + PadY * 2.0f;

    // Slide in from top (0.5s slide)
    if (EventWaveBannerTimer > (EVENT_BANNER_DURATION - 0.5f))
    {
        SlideProgress = (EVENT_BANNER_DURATION - EventWaveBannerTimer) / 0.5f;
        BannerY = -BgH + (Canvas.SizeY * 0.08f + BgH) * SlideProgress;
    }
    else
    {
        BannerY = Canvas.SizeY * 0.08f;
    }

    BgTop = BannerY;
    A = byte(BannerAlpha * 255.0f);

    // Background bar (full width)
    Canvas.SetPos(0, BgTop);
    Canvas.SetDrawColor(0, 0, 0, byte(170.0f * BannerAlpha));
    Canvas.DrawRect(W, BgH);

    // Color accent line at top of bar
    Canvas.SetPos(0, BgTop);
    Canvas.SetDrawColor(EventColor.R, EventColor.G, EventColor.B, byte(220.0f * BannerAlpha));
    Canvas.DrawRect(W, 2.0f);

    // Color accent line at bottom of bar
    Canvas.SetPos(0, BgTop + BgH - 2.0f);
    Canvas.SetDrawColor(EventColor.R, EventColor.G, EventColor.B, byte(150.0f * BannerAlpha));
    Canvas.DrawRect(W, 2.0f);

    // Center the icon+text block horizontally
    // Measure the widest text line for block width
    Canvas.TextSize(Caps(EventName), BlockW, TempH, 1.0f, 1.0f);
    BlockW = IconSz + PadX + BlockW;
    BannerCenterX = (W - BlockW) * 0.5f;
    IconX = BannerCenterX;
    TextX = IconX + IconSz + PadX;

    // Vertically center the content within the bar
    ContentCenterY = BgTop + (BgH - FMax(IconSz, TotalTextH)) * 0.5f;

    // Icon
    if (EventIcon != None)
    {
        Canvas.SetPos(IconX, ContentCenterY + (FMax(IconSz, TotalTextH) - IconSz) * 0.5f);
        Canvas.SetDrawColor(255, 255, 255, A);
        Canvas.DrawTile(EventIcon, IconSz, IconSz, 0, 0, EventIcon.SizeX, EventIcon.SizeY);
    }

    // Text column starts vertically centered
    CurY = ContentCenterY + (FMax(IconSz, TotalTextH) - TotalTextH) * 0.5f;

    // "EVENT WAVE" subtitle
    DrawTextWithShadow(EventWave_Subtitle, TextX, CurY, MakeColorFromRGB(180, 180, 180, byte(200.0f * BannerAlpha)), 0.7f);
    CurY += SubTitleH + TextGap;

    // Event name in event color
    DrawTextWithShadow(Caps(EventName), TextX, CurY, MakeColorFromRGB(EventColor.R, EventColor.G, EventColor.B, A), 1.0f);
    CurY += NameH + TextGap;

    // Description in light grey
    if (EventDesc != "")
    {
        DrawTextWithShadow(EventDesc, TextX, CurY, MakeColorFromRGB(200, 200, 200, byte(180.0f * BannerAlpha)), 0.75f);
    }
}

// ===================================================================
// ISOLATION - Hide/show other player pawns
// ===================================================================

function SetOtherPlayersHidden(bool bHide)
{
    local KFPawn_Human KFPH;
    local Pawn MyPawn;

    MyPawn = None;
    if (KFPlayerOwner != None)
        MyPawn = KFPlayerOwner.Pawn;

    foreach WorldInfo.AllPawns(class'KFPawn_Human', KFPH)
    {
        if (KFPH != MyPawn && KFPH.Health > 0)
        {
            KFPH.SetHidden(bHide);
            if (KFPH.WeaponAttachment != None)
                KFPH.WeaponAttachment.SetHidden(bHide);
        }
    }
}

// ===================================================================
// DEAD SILENCE - Mute game audio, restore on end
// Uses console command to zero SFX volume. Restores to 1.0 on end.
// TODO: Add heartbeat SoundCue loop via ZTSoundManager registration
// ===================================================================

function MuteGameAudio()
{
    if (KFPlayerOwner != None)
    {
        KFPlayerOwner.ConsoleCommand("SetAudioGroupVolume SFX 0.0");
        KFPlayerOwner.ConsoleCommand("SetAudioGroupVolume Dialog 0.0");
    }
}

function RestoreGameAudio()
{
    if (KFPlayerOwner != None)
    {
        KFPlayerOwner.ConsoleCommand("SetAudioGroupVolume SFX 1.0");
        KFPlayerOwner.ConsoleCommand("SetAudioGroupVolume Dialog 1.0");
    }
}

// ===================================================================
// PARANOIA - Fake zed audio from random directions
// Plays Fleshpound rage, Scrake chainsaw, Siren screams, boss sounds
// from phantom positions around the player
// ===================================================================


function LoadParanoiaSounds()
{
    if (bParanoiaSoundsLoaded)
        return;

    // === FLESHPOUND ===
    // NOTE: Play_FleshPound_Rage_Start removed — state-start AkEvent, loops until Stop
    ParanoiaSounds.AddItem(AkEvent'ww_zed_fleshpound_2.Play_Fleshpound_Pound');
    ParanoiaSounds.AddItem(AkEvent'ww_zed_fleshpound_2.Play_FP_Charge');
    ParanoiaSounds.AddItem(AkEvent'ww_zed_fleshpound_2.Play_King_FP_Rage_Hit');

    // === SCRAKE ===
    // NOTE: ZED_Scrake_SFX_Chainsaw_Idle_LP removed — looping AkEvent that never stops

    // === HANS VOLTER ===
    // NOTE: Play_HANS_Breathing_Base removed — looping AkEvent that never stops
    ParanoiaSounds.AddItem(AkEvent'WW_VOX_NPC_HansVolter.Play_HANS_BreathHurt_Base');
    ParanoiaSounds.AddItem(AkEvent'WW_ZED_Hans.Play_Hans_Intro_Land');
    ParanoiaSounds.AddItem(AkEvent'WW_ZED_Hans.Play_Hans_Shield_Break');
    ParanoiaSounds.AddItem(AkEvent'WW_ZED_Hans.ZED_Hans_SFX_Grenade_Poison');

    // === PATRIARCH ===
    // NOTE: Play_Patriarch_Cloak removed — state-start AkEvent, loops until uncloak
    ParanoiaSounds.AddItem(AkEvent'WW_ZED_Patriarch.Play_Pat_Intro_Roar');

    // === ABOMINATION ===
    ParanoiaSounds.AddItem(AkEvent'WW_ZED_Abomination.Play_Abomination_Intro_Land');
    ParanoiaSounds.AddItem(AkEvent'WW_ZED_Abomination.Play_Abomination_Bile_Spawn');
    ParanoiaSounds.AddItem(AkEvent'WW_ZED_Abomination.Play_Abomination_AOE_Explo');

    // === MATRIARCH ===
    // NOTE: Play_Matriarch_SFX_Cloak removed — state-start AkEvent, loops until uncloak
    ParanoiaSounds.AddItem(AkEvent'WW_ZED_Matriarch.Play_Matriarch_SFX_Shield_Break');

    // === HUSK / EXPLOSIONS ===
    ParanoiaSounds.AddItem(AkEvent'WW_WEP_Husk_Cannon.Play_WEP_Husk_Cannon_3P_Fire');
    ParanoiaSounds.AddItem(AkEvent'WW_ZED_Husk.ZED_Husk_SFX_Ranged_Shot_Impact');
    ParanoiaSounds.AddItem(AkEvent'WW_WEP_EXP_Dynamite.Play_WEP_EXP_Dynamite_Explosion');

    bParanoiaSoundsLoaded = True;
    `log("[DK_EVENTWAVE] Paranoia: Loaded" @ ParanoiaSounds.Length @ "phantom sounds");
}

function PlayParanoiaSound()
{
    local int SoundIdx;

    if (KFPlayerOwner == None || KFPlayerOwner.Pawn == None)
        return;

    if (!bParanoiaSoundsLoaded)
        LoadParanoiaSounds();

    if (ParanoiaSounds.Length == 0)
        return;

    // Pick a random sound and play on player's pawn
    // No visible source = pure paranoia. Directional upgrade via helper actor later.
    SoundIdx = Rand(ParanoiaSounds.Length);
    KFPlayerOwner.Pawn.PlayAkEvent(ParanoiaSounds[SoundIdx]);
}

// ===================================================================
// REDACTED - Black out all HUD elements
// Draws opaque rects over known KF2 HUD positions
// ===================================================================

function DrawRedactedOverlay()
{
    local float W, H, A;
    local float TextW, TextH;

    W = Canvas.SizeX;
    H = Canvas.SizeY;
    A = FMin(EventWaveAlpha, 1.0f);

    // Flash HUD is already hidden via KFGXHUDManager._visible = false
    // Just draw a subtle atmospheric effect

    // Subtle edge darkening (4 bars along edges)
    Canvas.SetDrawColor(0, 0, 0, byte(40.0f * A));
    Canvas.SetPos(0, 0);
    Canvas.DrawRect(W, H * 0.03f);        // Top strip
    Canvas.SetPos(0, H * 0.97f);
    Canvas.DrawRect(W, H * 0.03f);        // Bottom strip
    Canvas.SetPos(0, 0);
    Canvas.DrawRect(W * 0.02f, H);        // Left strip
    Canvas.SetPos(W * 0.98f, 0);
    Canvas.DrawRect(W * 0.02f, H);        // Right strip

    // Faint "REDACTED" watermark in center
    Canvas.Font = class'KFGameEngine'.Static.GetKFCanvasFont();
    Canvas.TextSize(EventWave_Redacted, TextW, TextH, 2.0f, 2.0f);
    Canvas.SetPos((W - TextW) * 0.5f + 2.0f, (H - TextH) * 0.5f + 2.0f);
    Canvas.SetDrawColor(0, 0, 0, byte(30.0f * A));
    Canvas.DrawText(EventWave_Redacted, false, 2.0f, 2.0f);
    Canvas.SetPos((W - TextW) * 0.5f, (H - TextH) * 0.5f);
    Canvas.SetDrawColor(40, 40, 40, byte(25.0f * A));
    Canvas.DrawText(EventWave_Redacted, false, 2.0f, 2.0f);
}

// ===================================================================
// EVENT WAVE TARGET ICON - Draw marker above the target player
// Used by VIP (crown), Hot Potato (bomb), Highlander (sword),
// Marked for Death (skull)
// ===================================================================

function DrawEventWaveTargetIcon()
{
    local ZTGameReplicationInfo DKGRI;
    local PlayerReplicationInfo TargetPRI;
    local KFPawn_Human TargetPawn;
    local KFPlayerController KFPC;
    local vector ScreenPos, WorldPos;
    local float IconSize;
    local string Label;
    local Color LabelColor;
    local float TextW, TextH, NTS;

    DKGRI = ZTGameReplicationInfo(KFGRI);
    if (DKGRI == None || DKGRI.EventWaveTargetPRI == None)
        return;

    TargetPRI = DKGRI.EventWaveTargetPRI;

    // Find the target pawn
    foreach WorldInfo.AllControllers(class'KFPlayerController', KFPC)
    {
        if (KFPC.PlayerReplicationInfo == TargetPRI && KFPC.Pawn != None)
        {
            TargetPawn = KFPawn_Human(KFPC.Pawn);
            break;
        }
    }

    if (TargetPawn == None || !TargetPawn.IsAliveAndWell())
        return;

    // Project world position to screen
    WorldPos = TargetPawn.Location;
    WorldPos.Z += TargetPawn.CylinderComponent.CollisionHeight + 40.f;
    ScreenPos = Canvas.Project(WorldPos);

    // Off screen check
    if (ScreenPos.X < 0 || ScreenPos.X > Canvas.SizeX || ScreenPos.Y < 0 || ScreenPos.Y > Canvas.SizeY)
        return;

    NTS = ResScale;
    IconSize = 24.f * NTS;

    // Pick label based on event
    switch (EventWaveOverlayID)
    {
        case 9:  Label = EventWave_TargetVIP; LabelColor = MakeColor(255, 215, 0, 255); break;
        case 10: Label = "!!!"; LabelColor = MakeColor(255, 100, 30, 255); break;
        case 12: Label = EventWave_TargetActive; LabelColor = MakeColor(200, 170, 50, 255); break;
        case 18: Label = EventWave_TargetMarked; LabelColor = MakeColor(255, 50, 50, 255); break;
        default: return;
    }

    // Draw background pip
    Canvas.SetPos(ScreenPos.X - IconSize * 0.5f, ScreenPos.Y - IconSize);
    Canvas.SetDrawColor(0, 0, 0, 180);
    Canvas.DrawRect(IconSize, IconSize * 0.6f);

    // Draw label text
    Canvas.Font = class'KFGameEngine'.Static.GetKFCanvasFont();
    Canvas.TextSize(Label, TextW, TextH, NTS * 0.6f, NTS * 0.6f);
    Canvas.SetPos(ScreenPos.X - TextW * 0.5f, ScreenPos.Y - IconSize * 0.85f);
    Canvas.SetDrawColor(LabelColor.R, LabelColor.G, LabelColor.B, 255);
    Canvas.DrawText(Label, false, NTS * 0.6f, NTS * 0.6f);
}

// ===================================================================
// EVENT WAVE STATUS INDICATOR - persistent, always-visible HUD readout
// Unlike DrawEventWaveTargetIcon (over-head marker, only when on-screen),
// this is a fixed screen-space line: current target + swap countdown shown
// regardless of line of sight, plus a prominent self-callout when the local
// player IS the target. Covers VIP(9)/HotPotato(10)/Highlander(12)/Marked(18).
// ===================================================================

function DrawEventWaveStatusIndicator()
{
    local ZTGameReplicationInfo DKGRI;
    local PlayerReplicationInfo TargetPRI, LocalPRI;
    local KFPlayerController LocalPC;
    local bool bLocalIsTarget;
    local string EventLabel, TargetLine, SelfLine;
    local Color EventCol, SelfCol;
    local float NTS, X, Y, LineW, LineH, BoxW, BoxH, PadX, PadY;
    local int Remaining;

    DKGRI = ZTGameReplicationInfo(KFGRI);
    if (DKGRI == None || DKGRI.EventWaveTargetPRI == None)
        return;

    TargetPRI = DKGRI.EventWaveTargetPRI;

    switch (EventWaveOverlayID)
    {
        case 9:  EventLabel = EventWave_HudVIP;        EventCol = MakeColor(255, 215, 0, 255);  break;
        case 10: EventLabel = EventWave_HudPotato;     EventCol = MakeColor(255, 100, 30, 255); break;
        case 12: EventLabel = EventWave_HudHighlander; EventCol = MakeColor(200, 170, 50, 255); break;
        case 18: EventLabel = EventWave_HudMarked;     EventCol = MakeColor(255, 50, 50, 255);  break;
        default: return;
    }

    // Detect an auto-swap (replicated target changed) and stamp the time
    // locally, so the countdown does not depend on server/client clocks.
    if (TargetPRI != CachedEventTargetPRI)
    {
        CachedEventTargetPRI = TargetPRI;
        CachedEventSwapTime = WorldInfo.TimeSeconds;
    }

    LocalPC = KFPlayerController(class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController());
    if (LocalPC != None)
        LocalPRI = LocalPC.PlayerReplicationInfo;
    bLocalIsTarget = (LocalPRI != None && LocalPRI == TargetPRI);

    NTS = ResScale;
    PadX = 10.0f * NTS;
    PadY = 5.0f * NTS;
    Canvas.Font = class'KFGameEngine'.Static.GetKFCanvasFont();

    // --- Persistent target line: "HOT POTATO: Name  (7s)" ---
    TargetLine = EventLabel $ ": " $ TargetPRI.PlayerName;
    if (DKGRI.EventSwapInterval > 0)
    {
        Remaining = int(float(DKGRI.EventSwapInterval) - (WorldInfo.TimeSeconds - CachedEventSwapTime));
        if (Remaining < 0)
            Remaining = 0;
        TargetLine = TargetLine $ "  (" $ Remaining $ "s)";
    }

    Canvas.TextSize(TargetLine, LineW, LineH, NTS * 0.8f, NTS * 0.8f);
    BoxW = LineW + PadX * 2.0f;
    BoxH = LineH + PadY * 2.0f;
    X = (Canvas.SizeX - BoxW) * 0.5f;
    Y = Canvas.SizeY * 0.16f;

    Canvas.SetPos(X, Y);
    Canvas.SetDrawColor(0, 0, 0, 170);
    Canvas.DrawRect(BoxW, BoxH);
    Canvas.SetPos(X, Y);
    Canvas.SetDrawColor(EventCol.R, EventCol.G, EventCol.B, 220);
    Canvas.DrawRect(BoxW, FMax(1.0f, 2.0f * NTS));

    DrawTextWithShadow(TargetLine, X + PadX, Y + PadY, MakeColor(EventCol.R, EventCol.G, EventCol.B, 255), NTS * 0.8f);

    // --- Self callout: only when the local player is the target ---
    if (bLocalIsTarget)
    {
        switch (EventWaveOverlayID)
        {
            case 9:  SelfLine = EventWave_SelfVIP;        SelfCol = MakeColor(255, 215, 0, 255);  break;
            case 10: SelfLine = EventWave_SelfPotato;     SelfCol = MakeColor(255, 100, 30, 255); break;
            case 12: SelfLine = EventWave_SelfHighlander; SelfCol = MakeColor(200, 170, 50, 255); break;
            case 18: SelfLine = EventWave_SelfMarked;     SelfCol = MakeColor(255, 50, 50, 255);  break;
            default: return;
        }

        Canvas.TextSize(SelfLine, LineW, LineH, NTS, NTS);
        BoxW = LineW + PadX * 2.0f;
        BoxH = LineH + PadY * 2.0f;
        X = (Canvas.SizeX - BoxW) * 0.5f;
        Y = Canvas.SizeY * 0.22f;

        Canvas.SetPos(X, Y);
        Canvas.SetDrawColor(0, 0, 0, 190);
        Canvas.DrawRect(BoxW, BoxH);
        Canvas.SetPos(X, Y);
        Canvas.SetDrawColor(SelfCol.R, SelfCol.G, SelfCol.B, 230);
        Canvas.DrawRect(BoxW, FMax(1.0f, 2.0f * NTS));

        DrawTextWithShadow(SelfLine, X + PadX, Y + PadY, MakeColor(SelfCol.R, SelfCol.G, SelfCol.B, 255), NTS);
    }
}

// ===================================================================
// X-MEN POWER HUD DISPLAY — Center-left of screen
// Shows the player's assigned superpower name + description
// ===================================================================

function DrawXMenPowerDisplay()
{
    local ZTPlayerController DKPC;
    local float XMScale, X, Y, PadX, PadY;
    local float NameW, NameH, DescW, DescH, BoxW, BoxH;
    local float NameScale, DescScale;

    DKPC = ZTPlayerController(GetALocalPlayerController());
    if (DKPC == None || DKPC.XMenPowerName == "")
    {
        return;
    }

    XMScale = Canvas.SizeY / 720.0f;
    NameScale = XMScale * 1.2f;
    DescScale = XMScale * 0.7f;
    PadX = 12.0f * XMScale;
    PadY = 8.0f * XMScale;

    Canvas.Font = class'KFGameEngine'.Static.GetKFCanvasFont();

    // Measure text
    Canvas.TextSize(DKPC.XMenPowerName, NameW, NameH, NameScale, NameScale);
    Canvas.TextSize(DKPC.XMenPowerDesc, DescW, DescH, DescScale, DescScale);

    BoxW = FMax(NameW, DescW) + PadX * 2;
    BoxH = NameH + DescH + PadY * 3;

    // Position: center-left (10% from left edge, vertically centered)
    X = Canvas.SizeX * 0.03f;
    Y = (Canvas.SizeY - BoxH) * 0.5f;

    // Draw background
    Canvas.SetPos(X, Y);
    Canvas.SetDrawColor(0, 0, 0, 160);
    Canvas.DrawRect(BoxW, BoxH);

    // Draw gold border (top and bottom lines)
    Canvas.SetDrawColor(255, 220, 0, 200);
    Canvas.SetPos(X, Y);
    Canvas.DrawRect(BoxW, 2.0f * XMScale);
    Canvas.SetPos(X, Y + BoxH - 2.0f * XMScale);
    Canvas.DrawRect(BoxW, 2.0f * XMScale);

    // Draw power name (gold, larger)
    Canvas.SetDrawColor(255, 220, 0, 255);
    Canvas.SetPos(X + PadX, Y + PadY);
    Canvas.DrawText(DKPC.XMenPowerName, false, NameScale, NameScale);

    // Draw power description (white, smaller)
    Canvas.SetDrawColor(220, 220, 220, 255);
    Canvas.SetPos(X + PadX, Y + PadY + NameH + PadY * 0.5f);
    Canvas.DrawText(DKPC.XMenPowerDesc, false, DescScale, DescScale);
}

// ===================================================================
// SPEEDSTER "BLINK STRIKE" CARD - Card Stack System
//
// Three states mirroring Domain's card. Pushed from the perk helper via its
// ClientSpeedsterHUD RPC -> UpdateSpeedsterDisplay / ClearSpeedsterDisplay.
// The bar animates locally off EndTime/Duration so it is smooth regardless
// of RPC cadence.
//
// NOTE: to go live this card must also be registered in the card-stack
// builder (so it gets a stacked slot/height) and called from the card draw
// dispatch -- same two spots Domain/Hyde are wired into.
// ===================================================================

function UpdateSpeedsterDisplay(byte InState, float InDuration)
{
    SpeedsterDisplay.bIsActive = True;
    SpeedsterDisplay.State = InState;
    SpeedsterDisplay.Duration = InDuration;
    SpeedsterDisplay.EndTime = WorldInfo.TimeSeconds + InDuration;
}

function ClearSpeedsterDisplay()
{
    SpeedsterDisplay.bIsActive = False;
}

function float GetSpeedsterCardHeight()
{
    local float PadY, BarH, GapTB, GapBT, IconSz;
    local float TitleH, LabelH, XL, TextStackH, IconStackH;

    if (!SpeedsterDisplay.bIsActive || Canvas == None)
        return 0.0f;

    PadY   = 6.0f  * ResScale;
    BarH   = 10.0f * ResScale;
    GapTB  = 6.0f  * ResScale;   // title -> bar
    GapBT  = 4.0f  * ResScale;   // bar -> state label
    IconSz = 64.0f * ResScale;

    // Height is derived from real font metrics (TextSize) so the box always
    // contains its text at any font/resolution. The old fixed line height
    // under-budgeted the KF canvas font and clipped the bottom line. The box
    // is the taller of the text stack and the 64px icon stack.
    Canvas.Font = class'KFGameEngine'.Static.GetKFCanvasFont();
    Canvas.TextSize("BLINK STRIKE", XL, TitleH, 0.7f * ResScale, 0.7f * ResScale);
    Canvas.TextSize("RECHARGING", XL, LabelH, 0.55f * ResScale, 0.55f * ResScale);

    TextStackH = PadY + TitleH + GapTB + BarH + GapBT + LabelH + PadY;
    IconStackH = IconSz + 2.0f * PadY;

    return FMax(TextStackH, IconStackH);
}

function DrawSpeedsterCard()
{
    local float BoxX, BoxY, BoxW, BoxH;
    local float PadX, PadY, GapTB, GapBT, TitleH, XL;
    local float BarX, BarW, BarH, Frac, Remaining;
    local float CurY, TextX, IconSz, IconPad;
    local Color AccentColor, TextColor;
    local Texture2D Icon;
    local string StateLabel;

    if (Canvas == None || !SpeedsterDisplay.bIsActive)
        return;

    PadX = 8.0f * ResScale;
    PadY = 6.0f * ResScale;
    GapTB = 6.0f * ResScale;
    GapBT = 4.0f * ResScale;
    IconSz = 64.0f * ResScale;
    IconPad = 8.0f * ResScale;
    BoxW = 280.0f * ResScale;
    BarH = 10.0f * ResScale;

    // Position from the card stacking system.
    BoxX = Canvas.SizeX * DisplayCardBaseX;
    BoxY = Canvas.SizeY * GetDisplayCardY(CARD_SPEEDSTER);
    BoxH = GetSpeedsterCardHeight();

    // State -> accent color + label.
    switch (SpeedsterDisplay.State)
    {
        case 1: // Active (dashing)
            AccentColor = MakeColorFromRGB(80, 230, 120, 255);  // green
            StateLabel = "DASHING";
            break;
        case 2: // Cooldown
            AccentColor = MakeColorFromRGB(255, 140, 50, 255);  // orange
            StateLabel = "RECHARGING";
            break;
        default: // Ready
            AccentColor = MakeColorFromRGB(60, 200, 230, 255);  // cyan
            StateLabel = "READY";
            break;
    }
    TextColor = MakeColorFromRGB(220, 220, 220, 255);
    TextX = BoxX + PadX + IconSz + IconPad;

    Canvas.Font = class'KFGameEngine'.Static.GetKFCanvasFont();

    // Background.
    Canvas.SetDrawColor(0, 0, 0, 160);
    Canvas.SetPos(BoxX, BoxY);
    Canvas.DrawRect(BoxW, BoxH);

    // Border (2px, accent-colored).
    Canvas.SetDrawColor(AccentColor.R, AccentColor.G, AccentColor.B, 200);
    Canvas.SetPos(BoxX, BoxY);                                Canvas.DrawRect(BoxW, 2.0f * ResScale);
    Canvas.SetPos(BoxX, BoxY + BoxH - 2.0f * ResScale);      Canvas.DrawRect(BoxW, 2.0f * ResScale);
    Canvas.SetPos(BoxX, BoxY);                                Canvas.DrawRect(2.0f * ResScale, BoxH);
    Canvas.SetPos(BoxX + BoxW - 2.0f * ResScale, BoxY);      Canvas.DrawRect(2.0f * ResScale, BoxH);

    // Icon (Speedfreak rank-0 card icon).
    Icon = Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Daredevil_Rank_0';
    if (Icon != None)
    {
        Canvas.SetDrawColor(255, 255, 255, 255);
        Canvas.SetPos(BoxX + PadX, BoxY + (BoxH - IconSz) * 0.5f);
        Canvas.DrawTile(Icon, IconSz, IconSz, 0, 0, Icon.SizeX, Icon.SizeY);
    }

    // Title.
    CurY = BoxY + PadY;
    Canvas.TextSize("BLINK STRIKE", XL, TitleH, 0.7f * ResScale, 0.7f * ResScale);
    DrawTextWithShadow("BLINK STRIKE", TextX, CurY, AccentColor, 0.7f * ResScale);
    CurY += TitleH + GapTB;

    // Bar.
    BarX = TextX;
    BarW = (BoxX + BoxW - PadX) - TextX;

    if (SpeedsterDisplay.State == 0)
    {
        Frac = 1.0f;   // Ready: full bar
    }
    else
    {
        Remaining = SpeedsterDisplay.EndTime - WorldInfo.TimeSeconds;
        if (SpeedsterDisplay.Duration > 0.0f)
            Frac = FClamp(Remaining / SpeedsterDisplay.Duration, 0.0f, 1.0f);
        else
            Frac = 0.0f;
    }

    Canvas.SetDrawColor(40, 40, 40, 200);
    Canvas.SetPos(BarX, CurY);
    Canvas.DrawRect(BarW, BarH);

    Canvas.SetDrawColor(AccentColor.R, AccentColor.G, AccentColor.B, 200);
    Canvas.SetPos(BarX, CurY);
    Canvas.DrawRect(BarW * Frac, BarH);

    CurY += BarH + GapBT;

    // State label.
    DrawTextWithShadow(StateLabel, TextX, CurY, TextColor, 0.55f * ResScale);
}

// ===================================================================
// POSSESSOR "POSSESSION" CARD - Card Stack System
//
// Three states mirroring Speedster's card. Pushed from the perk helper via
// its ClientPossessorHUD RPC -> UpdatePossessorDisplay / ClearPossessorDisplay.
// While possessing, the bar AND a live remaining-seconds readout tick in
// real time off the locally recorded EndTime, so the countdown is smooth
// regardless of RPC cadence.
// ===================================================================

function UpdatePossessorDisplay(byte InState, float InDuration)
{
    PossessorDisplay.bIsActive = True;
    PossessorDisplay.State = InState;
    PossessorDisplay.Duration = InDuration;
    PossessorDisplay.EndTime = WorldInfo.TimeSeconds + InDuration;
}

function ClearPossessorDisplay()
{
    PossessorDisplay.bIsActive = False;
}

function float GetPossessorCardHeight()
{
    local float PadY, BarH, GapTB, GapBT, IconSz;
    local float TitleH, LabelH, XL, TextStackH, IconStackH;

    if (!PossessorDisplay.bIsActive || Canvas == None)
        return 0.0f;

    PadY   = 6.0f  * ResScale;
    BarH   = 10.0f * ResScale;
    GapTB  = 6.0f  * ResScale;   // title -> bar
    GapBT  = 4.0f  * ResScale;   // bar -> state label
    IconSz = 64.0f * ResScale;

    // Height derived from real font metrics (TextSize) so the box always
    // contains its text at any font/resolution (same fix as Speedster's
    // card). The box is the taller of the text stack and the icon stack.
    Canvas.Font = class'KFGameEngine'.Static.GetKFCanvasFont();
    Canvas.TextSize("POSSESSION", XL, TitleH, 0.7f * ResScale, 0.7f * ResScale);
    Canvas.TextSize("RECHARGING", XL, LabelH, 0.55f * ResScale, 0.55f * ResScale);

    TextStackH = PadY + TitleH + GapTB + BarH + GapBT + LabelH + PadY;
    IconStackH = IconSz + 2.0f * PadY;

    return FMax(TextStackH, IconStackH);
}

function DrawPossessorCard()
{
    local float BoxX, BoxY, BoxW, BoxH;
    local float PadX, PadY, GapTB, GapBT, TitleH, XL;
    local float BarX, BarW, BarH, Frac, Remaining;
    local float CurY, TextX, IconSz, IconPad;
    local Color AccentColor, TextColor;
    local Texture2D Icon;
    local string StateLabel;
    local int WholeSecs, TenthSecs;

    if (Canvas == None || !PossessorDisplay.bIsActive)
        return;

    PadX = 8.0f * ResScale;
    PadY = 6.0f * ResScale;
    GapTB = 6.0f * ResScale;
    GapBT = 4.0f * ResScale;
    IconSz = 64.0f * ResScale;
    IconPad = 8.0f * ResScale;
    BoxW = 280.0f * ResScale;
    BarH = 10.0f * ResScale;

    // Position from the card stacking system.
    BoxX = Canvas.SizeX * DisplayCardBaseX;
    BoxY = Canvas.SizeY * GetDisplayCardY(CARD_POSSESSOR);
    BoxH = GetPossessorCardHeight();

    // Remaining time in the current phase, ticking locally in real time.
    Remaining = FMax(PossessorDisplay.EndTime - WorldInfo.TimeSeconds, 0.0f);

    // State -> accent color + label. While possessing, the label carries a
    // live seconds countdown (one decimal).
    switch (PossessorDisplay.State)
    {
        case 1: // Possessing (timer draining)
            AccentColor = MakeColorFromRGB(180, 90, 230, 255);  // violet
            WholeSecs = int(Remaining);
            TenthSecs = int(Remaining * 10.0f) % 10;
            StateLabel = "POSSESSING - " $ WholeSecs $ "." $ TenthSecs $ "s";
            break;
        case 2: // Cooldown
            AccentColor = MakeColorFromRGB(255, 140, 50, 255);  // orange
            StateLabel = "RECHARGING";
            break;
        default: // Ready
            AccentColor = MakeColorFromRGB(60, 200, 230, 255);  // cyan
            StateLabel = "READY";
            break;
    }
    TextColor = MakeColorFromRGB(220, 220, 220, 255);
    TextX = BoxX + PadX + IconSz + IconPad;

    Canvas.Font = class'KFGameEngine'.Static.GetKFCanvasFont();

    // Background.
    Canvas.SetDrawColor(0, 0, 0, 160);
    Canvas.SetPos(BoxX, BoxY);
    Canvas.DrawRect(BoxW, BoxH);

    // Border (2px, accent-colored).
    Canvas.SetDrawColor(AccentColor.R, AccentColor.G, AccentColor.B, 200);
    Canvas.SetPos(BoxX, BoxY);                                Canvas.DrawRect(BoxW, 2.0f * ResScale);
    Canvas.SetPos(BoxX, BoxY + BoxH - 2.0f * ResScale);      Canvas.DrawRect(BoxW, 2.0f * ResScale);
    Canvas.SetPos(BoxX, BoxY);                                Canvas.DrawRect(2.0f * ResScale, BoxH);
    Canvas.SetPos(BoxX + BoxW - 2.0f * ResScale, BoxY);      Canvas.DrawRect(2.0f * ResScale, BoxH);

    // Icon (Possessor rank-0 card icon).
    Icon = Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Shapeshifter_Rank_0';
    if (Icon != None)
    {
        Canvas.SetDrawColor(255, 255, 255, 255);
        Canvas.SetPos(BoxX + PadX, BoxY + (BoxH - IconSz) * 0.5f);
        Canvas.DrawTile(Icon, IconSz, IconSz, 0, 0, Icon.SizeX, Icon.SizeY);
    }

    // Title.
    CurY = BoxY + PadY;
    Canvas.TextSize("POSSESSION", XL, TitleH, 0.7f * ResScale, 0.7f * ResScale);
    DrawTextWithShadow("POSSESSION", TextX, CurY, AccentColor, 0.7f * ResScale);
    CurY += TitleH + GapTB;

    // Bar - drains in real time while possessing / recharging.
    BarX = TextX;
    BarW = (BoxX + BoxW - PadX) - TextX;

    if (PossessorDisplay.State == 0)
    {
        Frac = 1.0f;   // Ready: full bar
    }
    else
    {
        if (PossessorDisplay.Duration > 0.0f)
            Frac = FClamp(Remaining / PossessorDisplay.Duration, 0.0f, 1.0f);
        else
            Frac = 0.0f;
    }

    Canvas.SetDrawColor(40, 40, 40, 200);
    Canvas.SetPos(BarX, CurY);
    Canvas.DrawRect(BarW, BarH);

    Canvas.SetDrawColor(AccentColor.R, AccentColor.G, AccentColor.B, 200);
    Canvas.SetPos(BarX, CurY);
    Canvas.DrawRect(BarW * Frac, BarH);

    CurY += BarH + GapBT;

    // State label (with the live countdown while possessing).
    DrawTextWithShadow(StateLabel, TextX, CurY, TextColor, 0.55f * ResScale);
}

defaultproperties
{
    HUDClass=Class'ZedternalReborn.WMGFxMoviePlayer_HUD'
    backgroundIcon=Texture2D'ZedternalReborn_Resource.ZedBuffs.UI_ZedBuff_Background'
    zedBuffIndex=INDEX_NONE
    bgFactor=0
    SupplierThirdUsableColor=(R=192, G=160, B=0, A=192)
    
    // Resolution scaling (defaults before config loads)
    HudScaleMultiplier=1.0f
    CardStackMaxY=0.82f
    CardStackMaxCards=4
    CardStackShrink=1.0f
    bHudPrefsLoaded=false
    
    TrackerStartX=0.75f
    TrackerStartY=0.25f
    TrackerSpacing=0.08f
    TrackerWidth=200.0f
    TrackerHeight=40.0f
    TextScale=0.8f
    
    NotificationFeedX=0.02f
    NotificationFeedY=0.30f
    NotificationSpacing=5.0f
    NotificationMaxWidth=600.0f
    NotificationTextScale=0.75f
    MaxVisibleNotifications=8
    
    AbilityDisplayX=0.5f
    AbilityDisplayY=0.85f
    AbilitySlotWidth=70.0f
    AbilitySlotHeight=70.0f
    AbilitySlotSpacing=15.0f
    
    
    // Shapeshifter Display Position (legacy, actual position from card stack)
    ShapeshifterDisplayX=0.75f
    ShapeshifterDisplayY=0.15f
    ShapeshifterIconSize=64.0f
    
    // Gambit Display Position (legacy, actual position from card stack)
    GambitDisplayX=0.75f
    GambitDisplayY=0.15f
    
    // Display Card Stacking System
    DisplayCardBaseX=0.75f
    DisplayCardBaseY=0.15f
    DisplayCardGapPx=12.0f
    
    // Gambit Buffs Overlay
    bShowGambitBuffs=false
    GambitBuffsDuration=5.0f
    
    // Dev stat overlay (off by default, toggle via console: StatOverlay cycles Off/Basic/Sources)
    StatOverlayMode=0

    // Player-facing stat panel (off by default, toggle via mutate stats or bindable ToggleStats)
    bShowStatPanel=false
    
    // Event Wave Overlay
    EventWaveOverlayID=0
    EventWaveAlpha=0.0
    EventWaveStartTimeLocal=0.0
    EventWaveBannerTimer=0.0
    bEventWaveFadingOut=false
    bIsolationActive=false
    bDeadSilenceActive=false
    bRedactedHUDHidden=false
    ParanoiaSoundTimer=5.0
    bParanoiaSoundsLoaded=False
    
    // Predator Trophy Overlay
    bShowPredatorTrophies=false
    PredatorTrophiesDuration=8.0f
    
    // Omen Card
    bHideOmenCard=False
    
    // Metronome Card
    bHideMetronomeCard=False

    // ===================================================================
    // LOCALIZED HUD STRINGS
    // English defaults live ONLY in KFGame/Localization/INT/ZedternalTempered.int
    // under [ZTHudWrapper]. UE3 forbids `localized` vars in defaultproperties
    // (silently drops them with an Import-failed warning), so this block stays empty.
    // Edit translations via ZU_AddDKMessagesSection.py.
    // ===================================================================

    Name="Default__ZTHudWrapper"
}
