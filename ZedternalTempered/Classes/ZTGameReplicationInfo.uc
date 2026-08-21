// ===================================================================
// ZTGameReplicationInfo - Extends WMGameReplicationInfo
// Adds Reforged weapon unlock bitmask for Artificer perk system
// Adds Perk Reroll settings for client replication
// UPDATED: Extended trader weapon replication from 512 -> 1024
//   AllowedWeaponsRepArray_C/D and KFWeaponDefPath_C/D
// UPDATED: Retry-on-DynamicLoadObject-None for Perk/Skill/Weapon upgrade
//   sync. Best-effort loading; with the Option-2 slot replication below,
//   a permanently failed load no longer desyncs slot indices (the slot
//   simply carries WeaponUpgrade=None and is hidden by the UPG menu).
// UPDATED: SyncTimer cap raised from 40 -> 120 ticks (6 min) so large
//   pools have room for both rep array settle and chunked generation.
// UPDATED: Weapon upgrade slot cap raised 8192 -> 16384
//   (SlotUpgIdx_33..64 added; pairs with bWeaponUpgrade_33..64 in
//   ZTPlayerReplicationInfo and DK_MAX_WEAPON_UPGRADES=16384 in the
//   GameInfo classes).
//
// ============== OPTION 2: REPLICATED SLOT COMPOSITION ==============
// The old design had the client REGENERATE WeaponUpgradeSlotsList from
// the replicated seed (chunked RNG replay). Any divergence between the
// server build and the client replay (DynamicLoadObject timing, upgrade
// classes that fail to load, weapons skipped client-side) shifted flat
// slot indices and/or desynced the seeded RNG -- producing the
// "purchases but no in-game effect" bug and random per-weapon upgrade
// counts in the UPG menu.
//
// New design: the SERVER records the actual slot composition at build
// time and replicates it as raw bytes:
//   - SlotUpgIdx_1..64[256]  : per-slot index into WeaponUpgradesList
//                              (16384 slots max, 1 byte each)
//   - WeaponSlotCnt_1..4[256]: per-weapon slot count, in AllowedWeapons
//                              order (1024 weapons max, 1 byte each)
//   - SlotDataChecksum       : sum(slot bytes) + sum(cnt bytes) + 7
//                              (the +7 guarantees nonzero once set, so
//                              "not yet replicated" is detectable)
// The client builds WeaponUpgradeSlotsList purely from this data:
// no RNG, no compatibility checks, no load-order sensitivity. A weapon
// or upgrade class that fails to load leaves a None entry AT THE
// CORRECT INDEX -- alignment between server and client can never break.
// ===================================================================
class ZTGameReplicationInfo extends WMGameReplicationInfo;

// ===================================================================
// EXTENDED TRADER WEAPON REPLICATION (512 -> 1024)
// Parent has _A[256] + _B[256] = 512 slots.
// We add _C[256] + _D[256] = 512 more, total 1024.
// ===================================================================

var AllowedWeaponRepStruct AllowedWeaponsRepArray_C[256];
var AllowedWeaponRepStruct AllowedWeaponsRepArray_D[256];
var string KFWeaponDefPath_C[256];
var string KFWeaponDefPath_D[256];

// Sync flags for new arrays
var bool bAllowedWeaponsSynced_C;
var bool bAllowedWeaponsSynced_D;
var bool bTraderWeaponsSynced_C;
var bool bTraderWeaponsSynced_D;

// ===================================================================
// OPTION 2 -- REPLICATED WEAPON UPGRADE SLOT COMPOSITION
// ===================================================================

// Per-slot upgrade index (index into WeaponUpgradesList, 0..255).
// Flat slot index s maps to SlotUpgIdx_<s/256 + 1>[s % 256].
var byte SlotUpgIdx_1[256];
var byte SlotUpgIdx_2[256];
var byte SlotUpgIdx_3[256];
var byte SlotUpgIdx_4[256];
var byte SlotUpgIdx_5[256];
var byte SlotUpgIdx_6[256];
var byte SlotUpgIdx_7[256];
var byte SlotUpgIdx_8[256];
var byte SlotUpgIdx_9[256];
var byte SlotUpgIdx_10[256];
var byte SlotUpgIdx_11[256];
var byte SlotUpgIdx_12[256];
var byte SlotUpgIdx_13[256];
var byte SlotUpgIdx_14[256];
var byte SlotUpgIdx_15[256];
var byte SlotUpgIdx_16[256];
var byte SlotUpgIdx_17[256];
var byte SlotUpgIdx_18[256];
var byte SlotUpgIdx_19[256];
var byte SlotUpgIdx_20[256];
var byte SlotUpgIdx_21[256];
var byte SlotUpgIdx_22[256];
var byte SlotUpgIdx_23[256];
var byte SlotUpgIdx_24[256];
var byte SlotUpgIdx_25[256];
var byte SlotUpgIdx_26[256];
var byte SlotUpgIdx_27[256];
var byte SlotUpgIdx_28[256];
var byte SlotUpgIdx_29[256];
var byte SlotUpgIdx_30[256];
var byte SlotUpgIdx_31[256];
var byte SlotUpgIdx_32[256];
var byte SlotUpgIdx_33[256];
var byte SlotUpgIdx_34[256];
var byte SlotUpgIdx_35[256];
var byte SlotUpgIdx_36[256];
var byte SlotUpgIdx_37[256];
var byte SlotUpgIdx_38[256];
var byte SlotUpgIdx_39[256];
var byte SlotUpgIdx_40[256];
var byte SlotUpgIdx_41[256];
var byte SlotUpgIdx_42[256];
var byte SlotUpgIdx_43[256];
var byte SlotUpgIdx_44[256];
var byte SlotUpgIdx_45[256];
var byte SlotUpgIdx_46[256];
var byte SlotUpgIdx_47[256];
var byte SlotUpgIdx_48[256];
var byte SlotUpgIdx_49[256];
var byte SlotUpgIdx_50[256];
var byte SlotUpgIdx_51[256];
var byte SlotUpgIdx_52[256];
var byte SlotUpgIdx_53[256];
var byte SlotUpgIdx_54[256];
var byte SlotUpgIdx_55[256];
var byte SlotUpgIdx_56[256];
var byte SlotUpgIdx_57[256];
var byte SlotUpgIdx_58[256];
var byte SlotUpgIdx_59[256];
var byte SlotUpgIdx_60[256];
var byte SlotUpgIdx_61[256];
var byte SlotUpgIdx_62[256];
var byte SlotUpgIdx_63[256];
var byte SlotUpgIdx_64[256];
var byte SlotUpgIdx_65[256];
var byte SlotUpgIdx_66[256];
var byte SlotUpgIdx_67[256];
var byte SlotUpgIdx_68[256];
var byte SlotUpgIdx_69[256];
var byte SlotUpgIdx_70[256];
var byte SlotUpgIdx_71[256];
var byte SlotUpgIdx_72[256];
var byte SlotUpgIdx_73[256];
var byte SlotUpgIdx_74[256];
var byte SlotUpgIdx_75[256];
var byte SlotUpgIdx_76[256];
var byte SlotUpgIdx_77[256];
var byte SlotUpgIdx_78[256];
var byte SlotUpgIdx_79[256];
var byte SlotUpgIdx_80[256];
var byte SlotUpgIdx_81[256];
var byte SlotUpgIdx_82[256];
var byte SlotUpgIdx_83[256];
var byte SlotUpgIdx_84[256];
var byte SlotUpgIdx_85[256];
var byte SlotUpgIdx_86[256];
var byte SlotUpgIdx_87[256];
var byte SlotUpgIdx_88[256];
var byte SlotUpgIdx_89[256];
var byte SlotUpgIdx_90[256];
var byte SlotUpgIdx_91[256];
var byte SlotUpgIdx_92[256];
var byte SlotUpgIdx_93[256];
var byte SlotUpgIdx_94[256];
var byte SlotUpgIdx_95[256];
var byte SlotUpgIdx_96[256];
var byte SlotUpgIdx_97[256];
var byte SlotUpgIdx_98[256];
var byte SlotUpgIdx_99[256];
var byte SlotUpgIdx_100[256];
var byte SlotUpgIdx_101[256];
var byte SlotUpgIdx_102[256];
var byte SlotUpgIdx_103[256];
var byte SlotUpgIdx_104[256];
var byte SlotUpgIdx_105[256];
var byte SlotUpgIdx_106[256];
var byte SlotUpgIdx_107[256];
var byte SlotUpgIdx_108[256];
var byte SlotUpgIdx_109[256];
var byte SlotUpgIdx_110[256];
var byte SlotUpgIdx_111[256];
var byte SlotUpgIdx_112[256];
var byte SlotUpgIdx_113[256];
var byte SlotUpgIdx_114[256];
var byte SlotUpgIdx_115[256];
var byte SlotUpgIdx_116[256];
var byte SlotUpgIdx_117[256];
var byte SlotUpgIdx_118[256];
var byte SlotUpgIdx_119[256];
var byte SlotUpgIdx_120[256];
var byte SlotUpgIdx_121[256];
var byte SlotUpgIdx_122[256];
var byte SlotUpgIdx_123[256];
var byte SlotUpgIdx_124[256];
var byte SlotUpgIdx_125[256];
var byte SlotUpgIdx_126[256];
var byte SlotUpgIdx_127[256];
var byte SlotUpgIdx_128[256];
var byte SlotUpgIdx_129[256];
var byte SlotUpgIdx_130[256];
var byte SlotUpgIdx_131[256];
var byte SlotUpgIdx_132[256];
var byte SlotUpgIdx_133[256];
var byte SlotUpgIdx_134[256];
var byte SlotUpgIdx_135[256];
var byte SlotUpgIdx_136[256];
var byte SlotUpgIdx_137[256];
var byte SlotUpgIdx_138[256];
var byte SlotUpgIdx_139[256];
var byte SlotUpgIdx_140[256];
var byte SlotUpgIdx_141[256];
var byte SlotUpgIdx_142[256];
var byte SlotUpgIdx_143[256];
var byte SlotUpgIdx_144[256];
var byte SlotUpgIdx_145[256];
var byte SlotUpgIdx_146[256];
var byte SlotUpgIdx_147[256];
var byte SlotUpgIdx_148[256];
var byte SlotUpgIdx_149[256];
var byte SlotUpgIdx_150[256];
var byte SlotUpgIdx_151[256];
var byte SlotUpgIdx_152[256];
var byte SlotUpgIdx_153[256];
var byte SlotUpgIdx_154[256];
var byte SlotUpgIdx_155[256];
var byte SlotUpgIdx_156[256];
var byte SlotUpgIdx_157[256];
var byte SlotUpgIdx_158[256];
var byte SlotUpgIdx_159[256];
var byte SlotUpgIdx_160[256];
var byte SlotUpgIdx_161[256];
var byte SlotUpgIdx_162[256];
var byte SlotUpgIdx_163[256];
var byte SlotUpgIdx_164[256];
var byte SlotUpgIdx_165[256];
var byte SlotUpgIdx_166[256];
var byte SlotUpgIdx_167[256];
var byte SlotUpgIdx_168[256];
var byte SlotUpgIdx_169[256];
var byte SlotUpgIdx_170[256];
var byte SlotUpgIdx_171[256];
var byte SlotUpgIdx_172[256];
var byte SlotUpgIdx_173[256];
var byte SlotUpgIdx_174[256];
var byte SlotUpgIdx_175[256];
var byte SlotUpgIdx_176[256];
var byte SlotUpgIdx_177[256];
var byte SlotUpgIdx_178[256];
var byte SlotUpgIdx_179[256];
var byte SlotUpgIdx_180[256];
var byte SlotUpgIdx_181[256];
var byte SlotUpgIdx_182[256];
var byte SlotUpgIdx_183[256];
var byte SlotUpgIdx_184[256];
var byte SlotUpgIdx_185[256];
var byte SlotUpgIdx_186[256];
var byte SlotUpgIdx_187[256];
var byte SlotUpgIdx_188[256];
var byte SlotUpgIdx_189[256];
var byte SlotUpgIdx_190[256];
var byte SlotUpgIdx_191[256];
var byte SlotUpgIdx_192[256];
var byte SlotUpgIdx_193[256];
var byte SlotUpgIdx_194[256];
var byte SlotUpgIdx_195[256];
var byte SlotUpgIdx_196[256];
var byte SlotUpgIdx_197[256];
var byte SlotUpgIdx_198[256];
var byte SlotUpgIdx_199[256];
var byte SlotUpgIdx_200[256];

// Per-weapon slot count, in AllowedWeaponsList order.
// Weapon index w maps to WeaponSlotCnt_<w/256 + 1>[w % 256].
var byte WeaponSlotCnt_1[256];
var byte WeaponSlotCnt_2[256];
var byte WeaponSlotCnt_3[256];
var byte WeaponSlotCnt_4[256];

// sum(all slot bytes) + sum(all cnt bytes) + 7. Always >= 7 once the
// server has finalized; 0 means "not yet replicated".
var int SlotDataChecksum;

// SERVER-ONLY recording buffers, appended during weapon list build by
// ZTGameInfo_Endless / ZTGameInfo_Endless_AllWeapons. Copied into the
// paged rep arrays by FinalizeSlotData(). Not replicated.
var array<byte> ServerSlotUpgIdxRecord;
var array<byte> ServerWeaponSlotCntRecord;

// Client-side: set once IsSlotDataComplete() has passed, so the chunked
// builder doesn't re-sum the slot bytes every tick.
var bool bSlotDataVerified;

// ----- Client self-heal state for slot-composition resync (see SyncTimer) -----
// SyncTimer re-requests roster 11 (slot composition) when the base data is
// synced but the weapon-upgrade build is stalled waiting on slot bytes that
// never fully arrived. INDEX_NONE = not yet armed.
var int SlotResyncNextTick;     // next SyncCounter tick at which to (re)request roster 11
var int SyncTimeoutExtensions;  // bounded count of 6-min budget extensions granted

// Grace before the FIRST resync (lets a still-streaming roster 11 finish
// naturally) and interval between subsequent resyncs, in SyncTimer ticks
// (3.0s each). Bounded number of full-budget extensions before giving up.
const SLOT_RESYNC_GRACE        = 10;  // ~30s grace after sync before first resend
const SLOT_RESYNC_INTERVAL     = 8;   // ~24s between resend attempts
const MAX_SYNC_TIMEOUT_EXTENDS = 3;   // up to 3 extra 6-min windows

// Maximum slots carried by the paged arrays above. Must match
// DK_MAX_WEAPON_UPGRADES in the GameInfo classes and the paged
// purchase arrays in ZTPlayerReplicationInfo.
const DK_SLOT_PAGES_MAX = 51200;

// ===================================================================
// CHUNKED WEAPON UPGRADE SLOT BUILD (client)
// Building up to 16384 slots involves up to 1024 DynamicLoadObject
// calls for the weapon classes. We keep the chunked SyncTimer pattern
// to spread that cost: WEAPON_UPG_GEN_CHUNK weapons per tick.
// ===================================================================

const WEAPON_UPG_GEN_CHUNK = 100;

// How many SyncTimer ticks (3s each) to retry a weapon class that fails
// DynamicLoadObject before inserting placeholder slots for it. With
// Option 2, placeholder slots keep index alignment intact -- the weapon
// just shows no upgrades on this client (and it cannot be held either,
// since its class never loaded).
const WEAPON_LOAD_MAX_STALLS = 20;

// Safety valve for the atomic build below: if the slot list still does not
// match the server's authoritative count after this many SyncTimer ticks, the
// client commits its best-effort build (with a loud error) instead of looping
// forever. The mainline case commits the instant the build matches exactly.
const WEAPON_UPG_BUILD_DEADLINE = 100;

// Persistent state for chunked build (reset each time a build starts).
var int WeaponUpgGenIndex;       // Next weapon index to process
var int WeaponUpgGenUpgCounter;  // Global slot cursor (slots emitted so far)
var int WeaponUpgGenStallIdx;    // Weapon index we are currently stalled on (INDEX_NONE = none)
var int WeaponUpgGenStallCount;  // Ticks spent stalled on that weapon

// ===================================================================
// RETRY-ON-LOAD-FAILURE STATE
// DynamicLoadObject can transiently fail (package not yet loaded,
// referenced asset stream pending). Parent's sync functions mark
// bDone=True unconditionally, burning the slot with WeaponUpgrade=None.
// We retry up to MAX_LOAD_ATTEMPTS times (3s per SyncTimer tick).
// With Option 2 slot replication, a final give-up is SAFE: the slot
// entry keeps the correct index and simply carries a None class.
// ===================================================================

const MAX_LOAD_ATTEMPTS = 5;

var byte PerkUpgradeLoadAttempts[256];
var byte WeaponUpgradeLoadAttempts[256];
var byte SkillUpgradeLoadAttempts[1024]; // Flat, indexed by shifted = i + 256 * indexMultiplier

// ===================================================================
// REFORGED WEAPON UNLOCK BITMASK
// MOVED to ZTPlayerReplicationInfo (per-player). The unlock flags used to
// live here on the shared GRI, which leaked Artificer reforge unlocks to
// every player. ReforgedStartIndex stays -- it is the shared weapon-list
// layout boundary, identical for every player.
// ===================================================================

var int ReforgedStartIndex;

// ===================================================================
// PERK REROLL SETTINGS
// ===================================================================

var bool bAllowPerkReroll;
var int PerkRerollBaseCost;
var float PerkRerollMultiplier;

// ===================================================================
// PERK LIMIT / CAPSTONE LIMITS
// Replicated so ZTUI_UPGMenu can pre-check purchases client-side.
// Without this the menu's optimistic update fakes a successful buy
// (ghost perk level, fake dosh deduction, skill unlock roll) whenever
// the server rejects via ZTPlayerController.BuyPerkUpgrade.
// Pushed by ZTGameInfo_Endless.PostBeginPlay from ZTConfig_PerkLimit
// and ZTConfig_Capstone.
// ===================================================================

var int MaxDifferentPerks;
var bool bProgressivePerkUnlock;
var int CapstoneR1Level;
var int CapstoneR2Level;
var int CapstoneMaxR1;
var int CapstoneMaxR2;

// ===================================================================
// DELUXE SKILL UPGRADE (pushed by ZTGameInfo_Endless from
// ZTConfig_DeluxeUpgrade). Replicated so ZTUI_UPGMenu can build and
// gate the on-demand Deluxe upgrade rows client-side.
// ===================================================================
var bool bDeluxeUpgradeEnabled;
var int DeluxeMinPerkLevel;
var int DeluxeUpgradeCost;
var bool bDeluxeTargetedSelection;

// Client-local one-shot guard: set True once the replicated capstone levels
// have been pushed into ZTConfig_Capstone's class defaults (see Tick). Not
// replicated.
var bool bCapstoneSyncedToConfig;

// ===================================================================
// EVENT WAVE SYSTEM
// ===================================================================

var repnotify byte ActiveEventWaveID;    // 0=none, 1-19=event type
var float EventWaveStartTime;            // WorldInfo.TimeSeconds when event started (server-side, for Eclipse)
var PlayerReplicationInfo EventWaveTargetPRI;  // Target player for VIP/HotPotato/Highlander/MarkedForDeath
var byte EventSwapInterval;                    // Auto-swap period (s) for the HUD countdown; 0 = no countdown (VIP/none)

replication
{
    if (bNetDirty)
        AllowedWeaponsRepArray_C, AllowedWeaponsRepArray_D,
        KFWeaponDefPath_C, KFWeaponDefPath_D,
        // Slot composition (SlotUpgIdx_1..64, WeaponSlotCnt_1..4, SlotDataChecksum)
        // now travels over the reliable ZTBulkSync stream (BR_SlotComposition) --
        // NOT this static-array path. The paged arrays silently dropped at scale
        // (15k+ bytes), handing each client a different partial slice and desyncing
        // weapon-upgrade counts (host 13, friend 2). See ZTPlayerController's
        // ServerSendSlotCompositionChunk / ClientReceiveSlotCompositionChunk.
        ReforgedStartIndex,
        bAllowPerkReroll, PerkRerollBaseCost, PerkRerollMultiplier,
        MaxDifferentPerks, bProgressivePerkUnlock, CapstoneR1Level, CapstoneR2Level, CapstoneMaxR1, CapstoneMaxR2,
        bDeluxeUpgradeEnabled, DeluxeMinPerkLevel, DeluxeUpgradeCost, bDeluxeTargetedSelection,
        ActiveEventWaveID, EventWaveTargetPRI, EventSwapInterval;
}

// ===================================================================
// SYNC TIMER OVERRIDE  (BULK SYNC + LEGACY-FALLBACK ARCHITECTURE)
// ===================================================================
// Server side: keep the legacy flow. Parent's ProcessAllSyncData reads
//   from server-populated rep arrays into XList[], which is consumed by
//   GenerateDataFromSyncData (CheckAndSetTraderItems, SetWeaponPickupList,
//   GenerateWeaponUpgrades).
//
// Client side: ALSO runs the legacy flow as a safety net. Bulk sync runs
//   concurrently in the background and may flip bAllDataSynced earlier
//   via OnBulkSyncComplete, but if any chunk RPCs drop (which they do in
//   the current UE3 setup for non-empty struct-array payloads), the
//   legacy rep-array flow is what actually populates the trader.
//
// SyncCounter timeout (120 ticks / 6 min) preserved on server for the
// chunked weapon-upgrade build pass.
// ===================================================================

simulated function SyncTimer()
{
    local ZTPlayerController DKPC;

    ++SyncCounter;

    if (!bAllDataSynced)
        ProcessAllSyncData();
    else if (!bAllDataGenerated)
        GenerateDataFromSyncData();
    else
        ClearTimer(NameOf(SyncTimer));

    // CLIENT SELF-HEAL: base rosters are synced but the weapon-upgrade build is
    // stalled because roster 11 (slot composition) never fully arrived. Roster
    // 11 rides the reliable bulk-sync stream only; a dropped chunk or transient
    // server-send stall leaves IsSlotDataComplete() false forever, so the trader
    // shows no weapon upgrades. Ask the server to re-stream just roster 11 -- the
    // generation branch above then finishes the build once the bytes land.
    // Armed with a grace period so a still-streaming roster 11 finishes naturally
    // first; throttled thereafter; self-terminates once bAllDataGenerated flips.
    if (WorldInfo.NetMode == NM_Client && bAllDataSynced && !bAllDataGenerated
        && !IsSlotDataComplete())
    {
        if (SlotResyncNextTick == INDEX_NONE)
        {
            SlotResyncNextTick = SyncCounter + SLOT_RESYNC_GRACE;
        }
        else if (SyncCounter >= SlotResyncNextTick)
        {
            DKPC = ZTPlayerController(GetALocalPlayerController());
            if (DKPC != None)
            {
                DKPC.RequestSlotResync();
                `log("[DK_UPGSLOTS] Slot data incomplete at tick" @ SyncCounter
                    @ "(checksum" @ SlotDataChecksum @ "numSlots" @ NumberOfWeaponUpgradeSlots
                    @ ") -- requested roster-11 resync");
            }
            SlotResyncNextTick = SyncCounter + SLOT_RESYNC_INTERVAL;
        }
    }

    if (SyncCounter > 120)
    {
        if (!bAllDataSynced || !bAllDataGenerated)
        {
            `log("ZR Error: DK Failed to sync and process all data from server for game replication after 120 ticks (6 min)"
                @ "| bAllDataSynced=" $ bAllDataSynced
                @ "bAllDataGenerated=" $ bAllDataGenerated
                @ "bSetWeaponUpgradeSlotsList=" $ bSetWeaponUpgradeSlotsList
                @ "IsSlotDataComplete=" $ IsSlotDataComplete()
                @ "NumWpnUpgSlots=" $ NumberOfWeaponUpgradeSlots
                @ "NumAllowedWpns=" $ NumberOfAllowedWeapons
                @ "SlotDataChecksum=" $ SlotDataChecksum);

            // Self-heal: do NOT abandon the trader forever. If the only thing
            // missing is the slot composition, keep the timer alive for a few
            // more budgets so a late resync can still complete the build.
            if (WorldInfo.NetMode == NM_Client && bAllDataSynced && !bAllDataGenerated
                && SyncTimeoutExtensions < MAX_SYNC_TIMEOUT_EXTENDS)
            {
                ++SyncTimeoutExtensions;
                SyncCounter = 0;            // restart the 6-min budget
                SlotResyncNextTick = 0;     // force an immediate resync next tick
                `log("[DK_UPGSLOTS] Extending sync window (" $ SyncTimeoutExtensions $ "/" $ MAX_SYNC_TIMEOUT_EXTENDS
                    $ ") and retrying slot resync");
                return; // keep timer running
            }
        }

        ClearTimer(NameOf(SyncTimer));
    }
}

// ===================================================================
// FULL OVERRIDE -- ProcessAllSyncData
// Extends parent sync loop with C/D for allowed weapons + trader items.
// Runs on BOTH server and client (client uses it as the legacy fallback
// when bulk sync RPCs drop).
// ===================================================================

simulated function ProcessAllSyncData()
{
    // Sync Allowed Weapons (A-D)
    if (!bAllowedWeaponsSynced_A)
        DKSyncAllowedWeapons(AllowedWeaponsRepArray_A, 0);

    if (!bAllowedWeaponsSynced_B)
        DKSyncAllowedWeapons(AllowedWeaponsRepArray_B, 1);

    if (!bAllowedWeaponsSynced_C)
        DKSyncAllowedWeapons(AllowedWeaponsRepArray_C, 2);

    if (!bAllowedWeaponsSynced_D)
        DKSyncAllowedWeapons(AllowedWeaponsRepArray_D, 3);

    // Sync Trader Weapons (A-D)
    if (!bTraderWeaponsSynced_A)
        DKSyncWeaponTraderItems(KFWeaponDefPath_A, 0);

    if (!bTraderWeaponsSynced_B)
        DKSyncWeaponTraderItems(KFWeaponDefPath_B, 1);

    if (!bTraderWeaponsSynced_C)
        DKSyncWeaponTraderItems(KFWeaponDefPath_C, 2);

    if (!bTraderWeaponsSynced_D)
        DKSyncWeaponTraderItems(KFWeaponDefPath_D, 3);

    // Sync Starting Weapons
    if (!bStartingWeaponsSynced)
        SyncAllStartingWeapons();

    // Sync Perk Upgrades (DK override with retry logic)
    if (!bPerkUpgradesSynced)
        SyncAllPerkUpgrades();

    // Sync Skill Upgrades (DK override with retry logic)
    if (!bSkillUpgradesSynced_A)
        SyncAllSkillUpgrades(SkillUpgradesRepArray_A, 0);

    if (!bSkillUpgradesSynced_B)
        SyncAllSkillUpgrades(SkillUpgradesRepArray_B, 1);

    if (!bSkillUpgradesSynced_C)
        SyncAllSkillUpgrades(SkillUpgradesRepArray_C, 2);

    if (!bSkillUpgradesSynced_D)
        SyncAllSkillUpgrades(SkillUpgradesRepArray_D, 3);

    // Sync Weapon Upgrades (DK override with retry logic)
    if (!bWeaponUpgradesSynced)
        SyncAllWeaponUpgrades();

    // Sync Equipment Upgrades
    if (!bEquipmentUpgradesSynced)
        SyncAllEquipmentUpgrades();

    // Sync Sidearms
    if (!bSidearmItemsSynced)
        SyncAllSidearmItems();

    // Sync Grenades
    if (!bGrenadeItemsSynced)
        SyncAllGrenadeItems();

    // Sync Special Waves
    if (!bSpecialWavesSynced)
        SyncAllSpecialWaves();

    // Sync Zed Buffs
    if (!bZedBuffsSynced)
        SyncAllZedBuffs();

    // Check all sync flags including extended C/D
    if (bAllowedWeaponsSynced_A && bAllowedWeaponsSynced_B
        && bAllowedWeaponsSynced_C && bAllowedWeaponsSynced_D
        && bTraderWeaponsSynced_A && bTraderWeaponsSynced_B
        && bTraderWeaponsSynced_C && bTraderWeaponsSynced_D
        && bStartingWeaponsSynced && bPerkUpgradesSynced
        && bSkillUpgradesSynced_A && bSkillUpgradesSynced_B
        && bSkillUpgradesSynced_C && bSkillUpgradesSynced_D
        && bWeaponUpgradesSynced && bEquipmentUpgradesSynced
        && bSidearmItemsSynced && bGrenadeItemsSynced
        && bSpecialWavesSynced && bZedBuffsSynced)
    {
        bAllDataSynced = True;
        `log("ZR Info: All base data received from server for game replication (DK extended)");
    }
}

// ===================================================================
// FULL OVERRIDE -- SyncAllPerkUpgrades
// Retry-on-None pattern. Only mark bDone when DynamicLoadObject returns
// a non-None class (or after MAX_LOAD_ATTEMPTS retries). Only set the
// synced flag when all expected entries are bDone.
// ===================================================================

simulated function SyncAllPerkUpgrades()
{
    local int i;
    local class<WMUpgrade_Perk> LoadedClass;
    local bool bAllDone;

    if (NumberOfPerkUpgrades == INDEX_NONE)
        return;

    if (PerkUpgradesList.Length == 0)
        PerkUpgradesList.Length = NumberOfPerkUpgrades;

    if (NumberOfPerkUpgrades > 0)
    {
        for (i = 0; i < 256; ++i)
        {
            if (!PerkUpgradesRepArray[i].bValid)
                break; //base case

            if (!PerkUpgradesList[i].bDone)
            {
                LoadedClass = class<WMUpgrade_Perk>(DynamicLoadObject(PerkUpgradesRepArray[i].PerkPathName, class'Class'));

                if (LoadedClass != None)
                {
                    PerkUpgradesList[i].PerkUpgrade = LoadedClass;
                    PerkUpgradesList[i].bDone = True;
                }
                else
                {
                    ++PerkUpgradeLoadAttempts[i];
                    if (PerkUpgradeLoadAttempts[i] >= MAX_LOAD_ATTEMPTS)
                    {
                        `log("ZR Warning: DKGRI gave up loading perk upgrade [" $ i $ "] " $ PerkUpgradesRepArray[i].PerkPathName $ " after " $ MAX_LOAD_ATTEMPTS $ " retries");
                        PerkUpgradesList[i].PerkUpgrade = None;
                        PerkUpgradesList[i].bDone = True;
                    }
                }
            }
        }
    }

    // Only mark synced when outer loop reached expected count AND all entries bDone
    if (i == NumberOfPerkUpgrades)
    {
        bAllDone = True;
        for (i = 0; i < NumberOfPerkUpgrades; ++i)
        {
            if (!PerkUpgradesList[i].bDone)
            {
                bAllDone = False;
                break;
            }
        }
        if (bAllDone)
            bPerkUpgradesSynced = True;
    }
}

// ===================================================================
// FULL OVERRIDE -- SyncAllSkillUpgrades
// Retry-on-None pattern. Uses general expectedCount formula for sync
// flag (works correctly at any scale, unlike parent's hardcoded checks).
// ===================================================================

simulated function SyncAllSkillUpgrades(const out SkillUpgradeRepStruct SkillUpgradesRepArray[256], int indexMultiplier)
{
    local int i, shifted, j, expectedCount, blockStart, blockEnd;
    local class<WMUpgrade_Skill> LoadedClass;
    local bool bAllDone;

    if (NumberOfSkillUpgrades == INDEX_NONE)
        return;

    if (SkillUpgradesList.Length == 0)
        SkillUpgradesList.Length = NumberOfSkillUpgrades;

    if (NumberOfSkillUpgrades > 0)
    {
        for (i = 0; i < 256; ++i)
        {
            shifted = i + 256 * indexMultiplier;

            if (!SkillUpgradesRepArray[i].bValid)
                break; //base case

            if (!SkillUpgradesList[shifted].bDone)
            {
                LoadedClass = class<WMUpgrade_Skill>(DynamicLoadObject(SkillUpgradesRepArray[i].SkillPathName, class'Class'));
                SkillUpgradesList[shifted].PerkPathName = SkillUpgradesRepArray[i].PerkPathName;

                if (LoadedClass != None)
                {
                    SkillUpgradesList[shifted].SkillUpgrade = LoadedClass;
                    SkillUpgradesList[shifted].bDone = True;
                }
                else
                {
                    ++SkillUpgradeLoadAttempts[shifted];
                    if (SkillUpgradeLoadAttempts[shifted] >= MAX_LOAD_ATTEMPTS)
                    {
                        `log("ZR Warning: DKGRI gave up loading skill upgrade [" $ shifted $ "] " $ SkillUpgradesRepArray[i].SkillPathName $ " after " $ MAX_LOAD_ATTEMPTS $ " retries (block " $ indexMultiplier $ ")");
                        SkillUpgradesList[shifted].SkillUpgrade = None;
                        SkillUpgradesList[shifted].bDone = True;
                    }
                }
            }
        }
    }

    // General expectedCount formula: how many entries should this block contain?
    expectedCount = Min(256, Max(0, NumberOfSkillUpgrades - 256 * indexMultiplier));

    // Synced when loop processed expected count AND all block entries bDone
    if (i >= expectedCount)
    {
        bAllDone = True;
        blockStart = 256 * indexMultiplier;
        blockEnd = blockStart + expectedCount;

        for (j = blockStart; j < blockEnd; ++j)
        {
            if (!SkillUpgradesList[j].bDone)
            {
                bAllDone = False;
                break;
            }
        }

        if (bAllDone)
        {
            switch (indexMultiplier)
            {
                case 0: bSkillUpgradesSynced_A = True; break;
                case 1: bSkillUpgradesSynced_B = True; break;
                case 2: bSkillUpgradesSynced_C = True; break;
                case 3: bSkillUpgradesSynced_D = True; break;
            }
        }
    }
}

// ===================================================================
// FULL OVERRIDE -- SyncAllWeaponUpgrades
// Retry-on-None pattern. With Option 2 slot replication a final
// give-up is safe (the slot keeps its index, just with a None class),
// but retrying still maximizes the number of usable upgrade entries.
// ===================================================================

simulated function SyncAllWeaponUpgrades()
{
    local int i;
    local class<WMUpgrade_Weapon> LoadedClass;
    local bool bAllDone;

    if (NumberOfWeaponUpgrades == INDEX_NONE)
        return;

    if (WeaponUpgradesList.Length == 0)
        WeaponUpgradesList.Length = NumberOfWeaponUpgrades;

    if (NumberOfWeaponUpgrades > 0)
    {
        for (i = 0; i < 256; ++i)
        {
            if (!WeaponUpgradesRepArray[i].bValid)
                break; //base case

            if (!WeaponUpgradesList[i].bDone)
            {
                LoadedClass = class<WMUpgrade_Weapon>(DynamicLoadObject(WeaponUpgradesRepArray[i].WeaponUpgPathName, class'Class'));

                // Price/level data is safe to copy regardless of class load outcome
                WeaponUpgradesList[i].PriceUnit = WeaponUpgradesRepArray[i].PriceUnit;
                WeaponUpgradesList[i].PriceMultiplier = WeaponUpgradesRepArray[i].PriceMultiplier;
                WeaponUpgradesList[i].MaxLevel = WeaponUpgradesRepArray[i].MaxLevel;
                WeaponUpgradesList[i].bIsStatic = WeaponUpgradesRepArray[i].bIsStatic;

                if (LoadedClass != None)
                {
                    WeaponUpgradesList[i].WeaponUpgrade = LoadedClass;
                    WeaponUpgradesList[i].bDone = True;
                }
                else
                {
                    ++WeaponUpgradeLoadAttempts[i];
                    if (WeaponUpgradeLoadAttempts[i] >= MAX_LOAD_ATTEMPTS)
                    {
                        `log("ZR Warning: DKGRI gave up loading weapon upgrade [" $ i $ "] " $ WeaponUpgradesRepArray[i].WeaponUpgPathName $ " after " $ MAX_LOAD_ATTEMPTS $ " retries. Slots referencing it stay aligned but are hidden on this client.");
                        WeaponUpgradesList[i].WeaponUpgrade = None;
                        WeaponUpgradesList[i].bDone = True;
                    }
                }
            }
        }
    }

    // Only mark synced when outer loop reached expected count AND all entries bDone
    if (i == NumberOfWeaponUpgrades)
    {
        bAllDone = True;
        for (i = 0; i < NumberOfWeaponUpgrades; ++i)
        {
            if (!WeaponUpgradesList[i].bDone)
            {
                bAllDone = False;
                break;
            }
        }
        if (bAllDone)
            bWeaponUpgradesSynced = True;
    }
}

// ===================================================================
// FULL OVERRIDE -- SyncAllowedWeapons
// Uses general expectedCount formula for correct sync flag handling
// at any weapon count (works correctly beyond 512)
// ===================================================================

simulated function DKSyncAllowedWeapons(const out AllowedWeaponRepStruct AllowedWeaponsRepArray[256], int indexMultiplier)
{
    local int i, shifted, expectedCount;

    if (NumberOfAllowedWeapons == INDEX_NONE)
        return;

    if (AllowedWeaponsList.Length == 0)
        AllowedWeaponsList.Length = NumberOfAllowedWeapons;

    if (NumberOfAllowedWeapons > 0)
    {
        for (i = 0; i < 256; ++i)
        {
            shifted = i + 256 * indexMultiplier;

            if (!AllowedWeaponsRepArray[i].bValid)
                break;

            if (!AllowedWeaponsList[shifted].bDone)
            {
                AllowedWeaponsList[shifted].KFWeaponPath = AllowedWeaponsRepArray[i].WeaponPathName;
                AllowedWeaponsList[shifted].WeaponName = name(GetItemName(AllowedWeaponsRepArray[i].WeaponPathName));
                AllowedWeaponsList[shifted].BuyPrice = AllowedWeaponsRepArray[i].BuyPrice;
                AllowedWeaponsList[shifted].bDone = True;
            }
        }
    }

    // How many entries should this block contain?
    // Block M covers indices [M*256 .. min((M+1)*256, total) - 1]
    expectedCount = Min(256, Max(0, NumberOfAllowedWeapons - 256 * indexMultiplier));

    // Synced when we processed at least that many entries
    if (i >= expectedCount)
    {
        switch (indexMultiplier)
        {
            case 0: bAllowedWeaponsSynced_A = True; break;
            case 1: bAllowedWeaponsSynced_B = True; break;
            case 2: bAllowedWeaponsSynced_C = True; break;
            case 3: bAllowedWeaponsSynced_D = True; break;
        }
    }
}

// ===================================================================
// FULL OVERRIDE -- SyncWeaponTraderItems
// Uses general expectedCount formula for correct sync flag handling
// at any weapon count (works correctly beyond 512)
// ===================================================================

simulated function DKSyncWeaponTraderItems(const out string KFWeaponDefPath[256], int indexMultiplier)
{
    local int i, shifted, expectedCount;

    if (NumberOfTraderWeapons == INDEX_NONE)
        return;

    if (TraderItems == None || TraderItems.SaleItems.Length == 0)
    {
        TraderItems = new class'WMGFxObject_TraderItems';
        TraderItems.SaleItems.Length = NumberOfTraderWeapons;
    }

    if (NumberOfTraderWeapons > 0)
    {
        for (i = 0; i < 256; ++i)
        {
            shifted = i + 256 * indexMultiplier;

            if (KFWeaponDefPath[i] == "")
                break;

            if (TraderItems.SaleItems[shifted].ItemID == INDEX_NONE)
            {
                TraderItems.SaleItems[shifted].WeaponDef = class<KFWeaponDefinition>(DynamicLoadObject(KFWeaponDefPath[i], class'Class'));
                TraderItems.SaleItems[shifted].ItemID = shifted;
            }
        }
    }

    // How many entries should this block contain?
    expectedCount = Min(256, Max(0, NumberOfTraderWeapons - 256 * indexMultiplier));

    // Synced when we processed at least that many entries
    if (i >= expectedCount)
    {
        switch (indexMultiplier)
        {
            case 0: bTraderWeaponsSynced_A = True; break;
            case 1: bTraderWeaponsSynced_B = True; break;
            case 2: bTraderWeaponsSynced_C = True; break;
            case 3: bTraderWeaponsSynced_D = True; break;
        }
    }
}

// ===================================================================
// OPTION 2 -- SLOT DATA ACCESSORS (paged byte arrays)
// ===================================================================

simulated function byte GetSlotUpgIdx(int index)
{
    local int div, shifted;

    div = index / 256;
    shifted = index - div * 256;

    switch (div)
    {
        case 0:  return SlotUpgIdx_1[shifted];
        case 1:  return SlotUpgIdx_2[shifted];
        case 2:  return SlotUpgIdx_3[shifted];
        case 3:  return SlotUpgIdx_4[shifted];
        case 4:  return SlotUpgIdx_5[shifted];
        case 5:  return SlotUpgIdx_6[shifted];
        case 6:  return SlotUpgIdx_7[shifted];
        case 7:  return SlotUpgIdx_8[shifted];
        case 8:  return SlotUpgIdx_9[shifted];
        case 9:  return SlotUpgIdx_10[shifted];
        case 10: return SlotUpgIdx_11[shifted];
        case 11: return SlotUpgIdx_12[shifted];
        case 12: return SlotUpgIdx_13[shifted];
        case 13: return SlotUpgIdx_14[shifted];
        case 14: return SlotUpgIdx_15[shifted];
        case 15: return SlotUpgIdx_16[shifted];
        case 16: return SlotUpgIdx_17[shifted];
        case 17: return SlotUpgIdx_18[shifted];
        case 18: return SlotUpgIdx_19[shifted];
        case 19: return SlotUpgIdx_20[shifted];
        case 20: return SlotUpgIdx_21[shifted];
        case 21: return SlotUpgIdx_22[shifted];
        case 22: return SlotUpgIdx_23[shifted];
        case 23: return SlotUpgIdx_24[shifted];
        case 24: return SlotUpgIdx_25[shifted];
        case 25: return SlotUpgIdx_26[shifted];
        case 26: return SlotUpgIdx_27[shifted];
        case 27: return SlotUpgIdx_28[shifted];
        case 28: return SlotUpgIdx_29[shifted];
        case 29: return SlotUpgIdx_30[shifted];
        case 30: return SlotUpgIdx_31[shifted];
        case 31: return SlotUpgIdx_32[shifted];
        case 32: return SlotUpgIdx_33[shifted];
        case 33: return SlotUpgIdx_34[shifted];
        case 34: return SlotUpgIdx_35[shifted];
        case 35: return SlotUpgIdx_36[shifted];
        case 36: return SlotUpgIdx_37[shifted];
        case 37: return SlotUpgIdx_38[shifted];
        case 38: return SlotUpgIdx_39[shifted];
        case 39: return SlotUpgIdx_40[shifted];
        case 40: return SlotUpgIdx_41[shifted];
        case 41: return SlotUpgIdx_42[shifted];
        case 42: return SlotUpgIdx_43[shifted];
        case 43: return SlotUpgIdx_44[shifted];
        case 44: return SlotUpgIdx_45[shifted];
        case 45: return SlotUpgIdx_46[shifted];
        case 46: return SlotUpgIdx_47[shifted];
        case 47: return SlotUpgIdx_48[shifted];
        case 48: return SlotUpgIdx_49[shifted];
        case 49: return SlotUpgIdx_50[shifted];
        case 50: return SlotUpgIdx_51[shifted];
        case 51: return SlotUpgIdx_52[shifted];
        case 52: return SlotUpgIdx_53[shifted];
        case 53: return SlotUpgIdx_54[shifted];
        case 54: return SlotUpgIdx_55[shifted];
        case 55: return SlotUpgIdx_56[shifted];
        case 56: return SlotUpgIdx_57[shifted];
        case 57: return SlotUpgIdx_58[shifted];
        case 58: return SlotUpgIdx_59[shifted];
        case 59: return SlotUpgIdx_60[shifted];
        case 60: return SlotUpgIdx_61[shifted];
        case 61: return SlotUpgIdx_62[shifted];
        case 62: return SlotUpgIdx_63[shifted];
        case 63: return SlotUpgIdx_64[shifted];
        case 64: return SlotUpgIdx_65[shifted];
        case 65: return SlotUpgIdx_66[shifted];
        case 66: return SlotUpgIdx_67[shifted];
        case 67: return SlotUpgIdx_68[shifted];
        case 68: return SlotUpgIdx_69[shifted];
        case 69: return SlotUpgIdx_70[shifted];
        case 70: return SlotUpgIdx_71[shifted];
        case 71: return SlotUpgIdx_72[shifted];
        case 72: return SlotUpgIdx_73[shifted];
        case 73: return SlotUpgIdx_74[shifted];
        case 74: return SlotUpgIdx_75[shifted];
        case 75: return SlotUpgIdx_76[shifted];
        case 76: return SlotUpgIdx_77[shifted];
        case 77: return SlotUpgIdx_78[shifted];
        case 78: return SlotUpgIdx_79[shifted];
        case 79: return SlotUpgIdx_80[shifted];
        case 80: return SlotUpgIdx_81[shifted];
        case 81: return SlotUpgIdx_82[shifted];
        case 82: return SlotUpgIdx_83[shifted];
        case 83: return SlotUpgIdx_84[shifted];
        case 84: return SlotUpgIdx_85[shifted];
        case 85: return SlotUpgIdx_86[shifted];
        case 86: return SlotUpgIdx_87[shifted];
        case 87: return SlotUpgIdx_88[shifted];
        case 88: return SlotUpgIdx_89[shifted];
        case 89: return SlotUpgIdx_90[shifted];
        case 90: return SlotUpgIdx_91[shifted];
        case 91: return SlotUpgIdx_92[shifted];
        case 92: return SlotUpgIdx_93[shifted];
        case 93: return SlotUpgIdx_94[shifted];
        case 94: return SlotUpgIdx_95[shifted];
        case 95: return SlotUpgIdx_96[shifted];
        case 96: return SlotUpgIdx_97[shifted];
        case 97: return SlotUpgIdx_98[shifted];
        case 98: return SlotUpgIdx_99[shifted];
        case 99: return SlotUpgIdx_100[shifted];
        case 100: return SlotUpgIdx_101[shifted];
        case 101: return SlotUpgIdx_102[shifted];
        case 102: return SlotUpgIdx_103[shifted];
        case 103: return SlotUpgIdx_104[shifted];
        case 104: return SlotUpgIdx_105[shifted];
        case 105: return SlotUpgIdx_106[shifted];
        case 106: return SlotUpgIdx_107[shifted];
        case 107: return SlotUpgIdx_108[shifted];
        case 108: return SlotUpgIdx_109[shifted];
        case 109: return SlotUpgIdx_110[shifted];
        case 110: return SlotUpgIdx_111[shifted];
        case 111: return SlotUpgIdx_112[shifted];
        case 112: return SlotUpgIdx_113[shifted];
        case 113: return SlotUpgIdx_114[shifted];
        case 114: return SlotUpgIdx_115[shifted];
        case 115: return SlotUpgIdx_116[shifted];
        case 116: return SlotUpgIdx_117[shifted];
        case 117: return SlotUpgIdx_118[shifted];
        case 118: return SlotUpgIdx_119[shifted];
        case 119: return SlotUpgIdx_120[shifted];
        case 120: return SlotUpgIdx_121[shifted];
        case 121: return SlotUpgIdx_122[shifted];
        case 122: return SlotUpgIdx_123[shifted];
        case 123: return SlotUpgIdx_124[shifted];
        case 124: return SlotUpgIdx_125[shifted];
        case 125: return SlotUpgIdx_126[shifted];
        case 126: return SlotUpgIdx_127[shifted];
        case 127: return SlotUpgIdx_128[shifted];
        case 128: return SlotUpgIdx_129[shifted];
        case 129: return SlotUpgIdx_130[shifted];
        case 130: return SlotUpgIdx_131[shifted];
        case 131: return SlotUpgIdx_132[shifted];
        case 132: return SlotUpgIdx_133[shifted];
        case 133: return SlotUpgIdx_134[shifted];
        case 134: return SlotUpgIdx_135[shifted];
        case 135: return SlotUpgIdx_136[shifted];
        case 136: return SlotUpgIdx_137[shifted];
        case 137: return SlotUpgIdx_138[shifted];
        case 138: return SlotUpgIdx_139[shifted];
        case 139: return SlotUpgIdx_140[shifted];
        case 140: return SlotUpgIdx_141[shifted];
        case 141: return SlotUpgIdx_142[shifted];
        case 142: return SlotUpgIdx_143[shifted];
        case 143: return SlotUpgIdx_144[shifted];
        case 144: return SlotUpgIdx_145[shifted];
        case 145: return SlotUpgIdx_146[shifted];
        case 146: return SlotUpgIdx_147[shifted];
        case 147: return SlotUpgIdx_148[shifted];
        case 148: return SlotUpgIdx_149[shifted];
        case 149: return SlotUpgIdx_150[shifted];
        case 150: return SlotUpgIdx_151[shifted];
        case 151: return SlotUpgIdx_152[shifted];
        case 152: return SlotUpgIdx_153[shifted];
        case 153: return SlotUpgIdx_154[shifted];
        case 154: return SlotUpgIdx_155[shifted];
        case 155: return SlotUpgIdx_156[shifted];
        case 156: return SlotUpgIdx_157[shifted];
        case 157: return SlotUpgIdx_158[shifted];
        case 158: return SlotUpgIdx_159[shifted];
        case 159: return SlotUpgIdx_160[shifted];
        case 160: return SlotUpgIdx_161[shifted];
        case 161: return SlotUpgIdx_162[shifted];
        case 162: return SlotUpgIdx_163[shifted];
        case 163: return SlotUpgIdx_164[shifted];
        case 164: return SlotUpgIdx_165[shifted];
        case 165: return SlotUpgIdx_166[shifted];
        case 166: return SlotUpgIdx_167[shifted];
        case 167: return SlotUpgIdx_168[shifted];
        case 168: return SlotUpgIdx_169[shifted];
        case 169: return SlotUpgIdx_170[shifted];
        case 170: return SlotUpgIdx_171[shifted];
        case 171: return SlotUpgIdx_172[shifted];
        case 172: return SlotUpgIdx_173[shifted];
        case 173: return SlotUpgIdx_174[shifted];
        case 174: return SlotUpgIdx_175[shifted];
        case 175: return SlotUpgIdx_176[shifted];
        case 176: return SlotUpgIdx_177[shifted];
        case 177: return SlotUpgIdx_178[shifted];
        case 178: return SlotUpgIdx_179[shifted];
        case 179: return SlotUpgIdx_180[shifted];
        case 180: return SlotUpgIdx_181[shifted];
        case 181: return SlotUpgIdx_182[shifted];
        case 182: return SlotUpgIdx_183[shifted];
        case 183: return SlotUpgIdx_184[shifted];
        case 184: return SlotUpgIdx_185[shifted];
        case 185: return SlotUpgIdx_186[shifted];
        case 186: return SlotUpgIdx_187[shifted];
        case 187: return SlotUpgIdx_188[shifted];
        case 188: return SlotUpgIdx_189[shifted];
        case 189: return SlotUpgIdx_190[shifted];
        case 190: return SlotUpgIdx_191[shifted];
        case 191: return SlotUpgIdx_192[shifted];
        case 192: return SlotUpgIdx_193[shifted];
        case 193: return SlotUpgIdx_194[shifted];
        case 194: return SlotUpgIdx_195[shifted];
        case 195: return SlotUpgIdx_196[shifted];
        case 196: return SlotUpgIdx_197[shifted];
        case 197: return SlotUpgIdx_198[shifted];
        case 198: return SlotUpgIdx_199[shifted];
        case 199: return SlotUpgIdx_200[shifted];
        default: return 0;
    }
}

simulated function SetSlotUpgIdx(int index, byte v)
{
    local int div, shifted;

    div = index / 256;
    shifted = index - div * 256;

    switch (div)
    {
        case 0:  SlotUpgIdx_1[shifted] = v;  break;
        case 1:  SlotUpgIdx_2[shifted] = v;  break;
        case 2:  SlotUpgIdx_3[shifted] = v;  break;
        case 3:  SlotUpgIdx_4[shifted] = v;  break;
        case 4:  SlotUpgIdx_5[shifted] = v;  break;
        case 5:  SlotUpgIdx_6[shifted] = v;  break;
        case 6:  SlotUpgIdx_7[shifted] = v;  break;
        case 7:  SlotUpgIdx_8[shifted] = v;  break;
        case 8:  SlotUpgIdx_9[shifted] = v;  break;
        case 9:  SlotUpgIdx_10[shifted] = v; break;
        case 10: SlotUpgIdx_11[shifted] = v; break;
        case 11: SlotUpgIdx_12[shifted] = v; break;
        case 12: SlotUpgIdx_13[shifted] = v; break;
        case 13: SlotUpgIdx_14[shifted] = v; break;
        case 14: SlotUpgIdx_15[shifted] = v; break;
        case 15: SlotUpgIdx_16[shifted] = v; break;
        case 16: SlotUpgIdx_17[shifted] = v; break;
        case 17: SlotUpgIdx_18[shifted] = v; break;
        case 18: SlotUpgIdx_19[shifted] = v; break;
        case 19: SlotUpgIdx_20[shifted] = v; break;
        case 20: SlotUpgIdx_21[shifted] = v; break;
        case 21: SlotUpgIdx_22[shifted] = v; break;
        case 22: SlotUpgIdx_23[shifted] = v; break;
        case 23: SlotUpgIdx_24[shifted] = v; break;
        case 24: SlotUpgIdx_25[shifted] = v; break;
        case 25: SlotUpgIdx_26[shifted] = v; break;
        case 26: SlotUpgIdx_27[shifted] = v; break;
        case 27: SlotUpgIdx_28[shifted] = v; break;
        case 28: SlotUpgIdx_29[shifted] = v; break;
        case 29: SlotUpgIdx_30[shifted] = v; break;
        case 30: SlotUpgIdx_31[shifted] = v; break;
        case 31: SlotUpgIdx_32[shifted] = v; break;
        case 32: SlotUpgIdx_33[shifted] = v; break;
        case 33: SlotUpgIdx_34[shifted] = v; break;
        case 34: SlotUpgIdx_35[shifted] = v; break;
        case 35: SlotUpgIdx_36[shifted] = v; break;
        case 36: SlotUpgIdx_37[shifted] = v; break;
        case 37: SlotUpgIdx_38[shifted] = v; break;
        case 38: SlotUpgIdx_39[shifted] = v; break;
        case 39: SlotUpgIdx_40[shifted] = v; break;
        case 40: SlotUpgIdx_41[shifted] = v; break;
        case 41: SlotUpgIdx_42[shifted] = v; break;
        case 42: SlotUpgIdx_43[shifted] = v; break;
        case 43: SlotUpgIdx_44[shifted] = v; break;
        case 44: SlotUpgIdx_45[shifted] = v; break;
        case 45: SlotUpgIdx_46[shifted] = v; break;
        case 46: SlotUpgIdx_47[shifted] = v; break;
        case 47: SlotUpgIdx_48[shifted] = v; break;
        case 48: SlotUpgIdx_49[shifted] = v; break;
        case 49: SlotUpgIdx_50[shifted] = v; break;
        case 50: SlotUpgIdx_51[shifted] = v; break;
        case 51: SlotUpgIdx_52[shifted] = v; break;
        case 52: SlotUpgIdx_53[shifted] = v; break;
        case 53: SlotUpgIdx_54[shifted] = v; break;
        case 54: SlotUpgIdx_55[shifted] = v; break;
        case 55: SlotUpgIdx_56[shifted] = v; break;
        case 56: SlotUpgIdx_57[shifted] = v; break;
        case 57: SlotUpgIdx_58[shifted] = v; break;
        case 58: SlotUpgIdx_59[shifted] = v; break;
        case 59: SlotUpgIdx_60[shifted] = v; break;
        case 60: SlotUpgIdx_61[shifted] = v; break;
        case 61: SlotUpgIdx_62[shifted] = v; break;
        case 62: SlotUpgIdx_63[shifted] = v; break;
        case 63: SlotUpgIdx_64[shifted] = v; break;
        case 64: SlotUpgIdx_65[shifted] = v; break;
        case 65: SlotUpgIdx_66[shifted] = v; break;
        case 66: SlotUpgIdx_67[shifted] = v; break;
        case 67: SlotUpgIdx_68[shifted] = v; break;
        case 68: SlotUpgIdx_69[shifted] = v; break;
        case 69: SlotUpgIdx_70[shifted] = v; break;
        case 70: SlotUpgIdx_71[shifted] = v; break;
        case 71: SlotUpgIdx_72[shifted] = v; break;
        case 72: SlotUpgIdx_73[shifted] = v; break;
        case 73: SlotUpgIdx_74[shifted] = v; break;
        case 74: SlotUpgIdx_75[shifted] = v; break;
        case 75: SlotUpgIdx_76[shifted] = v; break;
        case 76: SlotUpgIdx_77[shifted] = v; break;
        case 77: SlotUpgIdx_78[shifted] = v; break;
        case 78: SlotUpgIdx_79[shifted] = v; break;
        case 79: SlotUpgIdx_80[shifted] = v; break;
        case 80: SlotUpgIdx_81[shifted] = v; break;
        case 81: SlotUpgIdx_82[shifted] = v; break;
        case 82: SlotUpgIdx_83[shifted] = v; break;
        case 83: SlotUpgIdx_84[shifted] = v; break;
        case 84: SlotUpgIdx_85[shifted] = v; break;
        case 85: SlotUpgIdx_86[shifted] = v; break;
        case 86: SlotUpgIdx_87[shifted] = v; break;
        case 87: SlotUpgIdx_88[shifted] = v; break;
        case 88: SlotUpgIdx_89[shifted] = v; break;
        case 89: SlotUpgIdx_90[shifted] = v; break;
        case 90: SlotUpgIdx_91[shifted] = v; break;
        case 91: SlotUpgIdx_92[shifted] = v; break;
        case 92: SlotUpgIdx_93[shifted] = v; break;
        case 93: SlotUpgIdx_94[shifted] = v; break;
        case 94: SlotUpgIdx_95[shifted] = v; break;
        case 95: SlotUpgIdx_96[shifted] = v; break;
        case 96: SlotUpgIdx_97[shifted] = v; break;
        case 97: SlotUpgIdx_98[shifted] = v; break;
        case 98: SlotUpgIdx_99[shifted] = v; break;
        case 99: SlotUpgIdx_100[shifted] = v; break;
        case 100: SlotUpgIdx_101[shifted] = v; break;
        case 101: SlotUpgIdx_102[shifted] = v; break;
        case 102: SlotUpgIdx_103[shifted] = v; break;
        case 103: SlotUpgIdx_104[shifted] = v; break;
        case 104: SlotUpgIdx_105[shifted] = v; break;
        case 105: SlotUpgIdx_106[shifted] = v; break;
        case 106: SlotUpgIdx_107[shifted] = v; break;
        case 107: SlotUpgIdx_108[shifted] = v; break;
        case 108: SlotUpgIdx_109[shifted] = v; break;
        case 109: SlotUpgIdx_110[shifted] = v; break;
        case 110: SlotUpgIdx_111[shifted] = v; break;
        case 111: SlotUpgIdx_112[shifted] = v; break;
        case 112: SlotUpgIdx_113[shifted] = v; break;
        case 113: SlotUpgIdx_114[shifted] = v; break;
        case 114: SlotUpgIdx_115[shifted] = v; break;
        case 115: SlotUpgIdx_116[shifted] = v; break;
        case 116: SlotUpgIdx_117[shifted] = v; break;
        case 117: SlotUpgIdx_118[shifted] = v; break;
        case 118: SlotUpgIdx_119[shifted] = v; break;
        case 119: SlotUpgIdx_120[shifted] = v; break;
        case 120: SlotUpgIdx_121[shifted] = v; break;
        case 121: SlotUpgIdx_122[shifted] = v; break;
        case 122: SlotUpgIdx_123[shifted] = v; break;
        case 123: SlotUpgIdx_124[shifted] = v; break;
        case 124: SlotUpgIdx_125[shifted] = v; break;
        case 125: SlotUpgIdx_126[shifted] = v; break;
        case 126: SlotUpgIdx_127[shifted] = v; break;
        case 127: SlotUpgIdx_128[shifted] = v; break;
        case 128: SlotUpgIdx_129[shifted] = v; break;
        case 129: SlotUpgIdx_130[shifted] = v; break;
        case 130: SlotUpgIdx_131[shifted] = v; break;
        case 131: SlotUpgIdx_132[shifted] = v; break;
        case 132: SlotUpgIdx_133[shifted] = v; break;
        case 133: SlotUpgIdx_134[shifted] = v; break;
        case 134: SlotUpgIdx_135[shifted] = v; break;
        case 135: SlotUpgIdx_136[shifted] = v; break;
        case 136: SlotUpgIdx_137[shifted] = v; break;
        case 137: SlotUpgIdx_138[shifted] = v; break;
        case 138: SlotUpgIdx_139[shifted] = v; break;
        case 139: SlotUpgIdx_140[shifted] = v; break;
        case 140: SlotUpgIdx_141[shifted] = v; break;
        case 141: SlotUpgIdx_142[shifted] = v; break;
        case 142: SlotUpgIdx_143[shifted] = v; break;
        case 143: SlotUpgIdx_144[shifted] = v; break;
        case 144: SlotUpgIdx_145[shifted] = v; break;
        case 145: SlotUpgIdx_146[shifted] = v; break;
        case 146: SlotUpgIdx_147[shifted] = v; break;
        case 147: SlotUpgIdx_148[shifted] = v; break;
        case 148: SlotUpgIdx_149[shifted] = v; break;
        case 149: SlotUpgIdx_150[shifted] = v; break;
        case 150: SlotUpgIdx_151[shifted] = v; break;
        case 151: SlotUpgIdx_152[shifted] = v; break;
        case 152: SlotUpgIdx_153[shifted] = v; break;
        case 153: SlotUpgIdx_154[shifted] = v; break;
        case 154: SlotUpgIdx_155[shifted] = v; break;
        case 155: SlotUpgIdx_156[shifted] = v; break;
        case 156: SlotUpgIdx_157[shifted] = v; break;
        case 157: SlotUpgIdx_158[shifted] = v; break;
        case 158: SlotUpgIdx_159[shifted] = v; break;
        case 159: SlotUpgIdx_160[shifted] = v; break;
        case 160: SlotUpgIdx_161[shifted] = v; break;
        case 161: SlotUpgIdx_162[shifted] = v; break;
        case 162: SlotUpgIdx_163[shifted] = v; break;
        case 163: SlotUpgIdx_164[shifted] = v; break;
        case 164: SlotUpgIdx_165[shifted] = v; break;
        case 165: SlotUpgIdx_166[shifted] = v; break;
        case 166: SlotUpgIdx_167[shifted] = v; break;
        case 167: SlotUpgIdx_168[shifted] = v; break;
        case 168: SlotUpgIdx_169[shifted] = v; break;
        case 169: SlotUpgIdx_170[shifted] = v; break;
        case 170: SlotUpgIdx_171[shifted] = v; break;
        case 171: SlotUpgIdx_172[shifted] = v; break;
        case 172: SlotUpgIdx_173[shifted] = v; break;
        case 173: SlotUpgIdx_174[shifted] = v; break;
        case 174: SlotUpgIdx_175[shifted] = v; break;
        case 175: SlotUpgIdx_176[shifted] = v; break;
        case 176: SlotUpgIdx_177[shifted] = v; break;
        case 177: SlotUpgIdx_178[shifted] = v; break;
        case 178: SlotUpgIdx_179[shifted] = v; break;
        case 179: SlotUpgIdx_180[shifted] = v; break;
        case 180: SlotUpgIdx_181[shifted] = v; break;
        case 181: SlotUpgIdx_182[shifted] = v; break;
        case 182: SlotUpgIdx_183[shifted] = v; break;
        case 183: SlotUpgIdx_184[shifted] = v; break;
        case 184: SlotUpgIdx_185[shifted] = v; break;
        case 185: SlotUpgIdx_186[shifted] = v; break;
        case 186: SlotUpgIdx_187[shifted] = v; break;
        case 187: SlotUpgIdx_188[shifted] = v; break;
        case 188: SlotUpgIdx_189[shifted] = v; break;
        case 189: SlotUpgIdx_190[shifted] = v; break;
        case 190: SlotUpgIdx_191[shifted] = v; break;
        case 191: SlotUpgIdx_192[shifted] = v; break;
        case 192: SlotUpgIdx_193[shifted] = v; break;
        case 193: SlotUpgIdx_194[shifted] = v; break;
        case 194: SlotUpgIdx_195[shifted] = v; break;
        case 195: SlotUpgIdx_196[shifted] = v; break;
        case 196: SlotUpgIdx_197[shifted] = v; break;
        case 197: SlotUpgIdx_198[shifted] = v; break;
        case 198: SlotUpgIdx_199[shifted] = v; break;
        case 199: SlotUpgIdx_200[shifted] = v; break;
        default: break;
    }
}

simulated function byte GetWeaponSlotCnt(int index)
{
    local int div, shifted;

    div = index / 256;
    shifted = index - div * 256;

    switch (div)
    {
        case 0:  return WeaponSlotCnt_1[shifted];
        case 1:  return WeaponSlotCnt_2[shifted];
        case 2:  return WeaponSlotCnt_3[shifted];
        case 3:  return WeaponSlotCnt_4[shifted];
        default: return 0;
    }
}

simulated function SetWeaponSlotCnt(int index, byte v)
{
    local int div, shifted;

    div = index / 256;
    shifted = index - div * 256;

    switch (div)
    {
        case 0: WeaponSlotCnt_1[shifted] = v; break;
        case 1: WeaponSlotCnt_2[shifted] = v; break;
        case 2: WeaponSlotCnt_3[shifted] = v; break;
        case 3: WeaponSlotCnt_4[shifted] = v; break;
        default: break;
    }
}

// ===================================================================
// OPTION 2 -- SERVER FINALIZE
// Called by ZTGameInfo_Endless / _AllWeapons from RepGameInfoLowPriority
// after the weapon list build is complete. Copies the recording buffers
// into the paged rep arrays and computes the checksum. Idempotent.
// ===================================================================

function FinalizeSlotData()
{
    local int i, sumSlots, sumCnts, cntTotal;

    sumSlots = 0;
    sumCnts = 0;
    cntTotal = 0;

    for (i = 0; i < ServerSlotUpgIdxRecord.Length && i < DK_SLOT_PAGES_MAX; ++i)
    {
        SetSlotUpgIdx(i, ServerSlotUpgIdxRecord[i]);
        sumSlots += ServerSlotUpgIdxRecord[i];
    }

    for (i = 0; i < ServerWeaponSlotCntRecord.Length && i < 1024; ++i)
    {
        SetWeaponSlotCnt(i, ServerWeaponSlotCntRecord[i]);
        sumCnts += ServerWeaponSlotCntRecord[i];
        cntTotal += ServerWeaponSlotCntRecord[i];
    }

    SlotDataChecksum = sumSlots + sumCnts + 7;
    bForceNetUpdate = True;

    `log("[DK_UPGSLOTS] FinalizeSlotData:" @ Min(ServerSlotUpgIdxRecord.Length, DK_SLOT_PAGES_MAX) @ "slot bytes,"
        @ Min(ServerWeaponSlotCntRecord.Length, 1024) @ "weapon counts, checksum" @ SlotDataChecksum);

    // Consistency checks -- these should NEVER fire. If they do, a slot
    // creation site is missing its recording calls.
    if (cntTotal != WeaponUpgradeSlotsList.Length)
        `log("[DK_UPGSLOTS] ERROR: per-weapon count sum (" $ cntTotal $ ") !=  WeaponUpgradeSlotsList.Length (" $ WeaponUpgradeSlotsList.Length $ ") -- recording is incomplete, clients WILL desync!");

    if (ServerSlotUpgIdxRecord.Length != WeaponUpgradeSlotsList.Length)
        `log("[DK_UPGSLOTS] ERROR: slot record length (" $ ServerSlotUpgIdxRecord.Length $ ") != WeaponUpgradeSlotsList.Length (" $ WeaponUpgradeSlotsList.Length $ ") -- recording is incomplete, clients WILL desync!");

    if (ServerWeaponSlotCntRecord.Length != AllowedWeaponsList.Length)
        `log("[DK_UPGSLOTS] Info: weapon count records (" $ ServerWeaponSlotCntRecord.Length $ ") vs AllowedWeaponsList (" $ AllowedWeaponsList.Length $ ") -- mismatch is expected only when the weapon list was truncated to" @ 1024);

    // ---------------------------------------------------------------
    // Per-weapon eligible-upgrade-count dump (server-authoritative).
    // For each trader weapon this is the RAW slot count AFTER the
    // compatibility intersection AND the per-weapon cap. NOTE: weapons that
    // have Hollow upgrades show FEWER in the trader, because the UPG menu
    // hides Hollow upgrades until the player owns the gating skill -- so for
    // those, trader count < this number. Grep [DK_UPGSLOTS_DUMP].
    // ---------------------------------------------------------------
    for (i = 0; i < ServerWeaponSlotCntRecord.Length && i < AllowedWeaponsList.Length; ++i)
    {
        `log("[DK_UPGSLOTS_DUMP] #" $ i $ ":" @ AllowedWeaponsList[i].KFWeaponPath @ "->" @ int(ServerWeaponSlotCntRecord[i]) @ "upgrade(s)");
    }
}

// ===================================================================
// OPTION 2 -- CLIENT ARRIVAL GATE
// True once the replicated slot data has fully arrived. Both checks are
// monotone under partial arrival (bytes default to 0 and only ever
// increase the sums), so equality implies completeness:
//   1. sum(counts) == NumberOfWeaponUpgradeSlots
//   2. sum(slots) + sum(counts) + 7 == SlotDataChecksum (which is 0
//      until the server-side int itself has arrived, and always >= 7
//      after, so a not-yet-arrived checksum can never falsely match)
// ===================================================================

simulated function bool IsSlotDataComplete()
{
    local int i, sumSlots, sumCnts;

    if (bSlotDataVerified)
        return True;

    if (NumberOfWeaponUpgradeSlots == INDEX_NONE || NumberOfAllowedWeapons == INDEX_NONE)
        return False;

    if (SlotDataChecksum < 7)
        return False;

    sumCnts = 0;
    for (i = 0; i < 1024; ++i)
    {
        sumCnts += GetWeaponSlotCnt(i);
    }

    if (sumCnts != NumberOfWeaponUpgradeSlots)
        return False;

    sumSlots = 0;
    for (i = 0; i < NumberOfWeaponUpgradeSlots; ++i)
    {
        sumSlots += GetSlotUpgIdx(i);
    }

    if (sumSlots + sumCnts + 7 != SlotDataChecksum)
        return False;

    bSlotDataVerified = True;
    `log("[DK_UPGSLOTS] Client slot data verified:" @ NumberOfWeaponUpgradeSlots @ "slots, checksum" @ SlotDataChecksum);
    return True;
}

// ===================================================================
// OPTION 2 -- DATA-DRIVEN GenerateWeaponUpgrades (full override)
// Builds WeaponUpgradeSlotsList purely from the replicated slot data.
// No RNG, no compatibility checks. Chunked (WEAPON_UPG_GEN_CHUNK
// weapons per SyncTimer tick) to spread DynamicLoadObject cost.
//
// Weapon classes that fail to load are retried for up to
// WEAPON_LOAD_MAX_STALLS ticks, then their slots are emitted as
// placeholders (KFWeapon=None). Placeholders keep every later slot at
// the correct flat index -- alignment with the server can never break.
// The ZTUI_UPGMenu already skips entries with KFWeapon == None.
// ===================================================================

simulated function GenerateWeaponUpgrades()
{
    local int i, x, cnt, u, chunkEnd, weaponTotal;
    local class<KFWeapon> KFW;

    // Prerequisites
    if (NumberOfWeaponUpgradeSlots == INDEX_NONE)
        return; //Not yet replicated

    if (NumberOfAllowedWeapons == INDEX_NONE)
        return; //Not yet replicated

    if (!bWeaponUpgradesSynced)
        return; //Upgrade class list still loading

    if (!IsSlotDataComplete())
        return; //Slot composition bytes still arriving

    weaponTotal = Min(NumberOfAllowedWeapons, AllowedWeaponsList.Length);

    // First call of this build run: reset state
    if (WeaponUpgGenIndex == 0 && WeaponUpgradeSlotsList.Length == 0)
    {
        WeaponUpgGenUpgCounter = 0;
        WeaponUpgGenStallIdx = INDEX_NONE;
        WeaponUpgGenStallCount = 0;
        `log("[DK_UPGSLOTS] Client slot build started (" $ weaponTotal $ " weapons," @ NumberOfWeaponUpgradeSlots @ "slots, chunk size " $ WEAPON_UPG_GEN_CHUNK $ ")");
    }

    chunkEnd = Min(WeaponUpgGenIndex + WEAPON_UPG_GEN_CHUNK, weaponTotal);

    for (i = WeaponUpgGenIndex; i < chunkEnd; ++i)
    {
        cnt = GetWeaponSlotCnt(i);
        if (cnt == 0)
        {
            continue; //Weapon has no upgrade slots
        }

        KFW = class<KFWeapon>(DynamicLoadObject(AllowedWeaponsList[i].KFWeaponPath, class'Class'));
        if (KFW == None)
        {
            if (WeaponUpgGenStallIdx != i)
            {
                WeaponUpgGenStallIdx = i;
                WeaponUpgGenStallCount = 0;
            }
            ++WeaponUpgGenStallCount;

            if (WeaponUpgGenStallCount < WEAPON_LOAD_MAX_STALLS)
            {
                // Halt at this weapon and retry next SyncTimer tick.
                // NEVER skip: skipping is what used to shift slot indices.
                WeaponUpgGenIndex = i;
                return;
            }

            `log("[DK_UPGSLOTS] WARNING: weapon class" @ AllowedWeaponsList[i].KFWeaponPath @ "failed to load after" @ WEAPON_LOAD_MAX_STALLS @ "retries -- emitting" @ cnt @ "placeholder slots (index alignment preserved)");
            // Fall through with KFW == None: placeholder slots.
        }
        else if (WeaponUpgGenStallIdx == i)
        {
            WeaponUpgGenStallIdx = INDEX_NONE;
            WeaponUpgGenStallCount = 0;
        }

        for (x = 0; x < cnt; ++x)
        {
            if (WeaponUpgGenUpgCounter >= NumberOfWeaponUpgradeSlots)
            {
                `log("[DK_UPGSLOTS] ERROR: slot cursor exceeded NumberOfWeaponUpgradeSlots at weapon" @ i @ "-- replicated counts are inconsistent!");
                break;
            }

            u = GetSlotUpgIdx(WeaponUpgGenUpgCounter);
            DKAddSlotFromData(KFW, u, AllowedWeaponsList[i].BuyPrice);
            ++WeaponUpgGenUpgCounter;
        }
    }

    // Advance persistent index for next tick
    WeaponUpgGenIndex = chunkEnd;

    // All weapons processed for this pass.
    if (WeaponUpgGenIndex >= weaponTotal)
    {
        // ATOMIC COMMIT: only publish a slot list that EXACTLY matches the
        // server's authoritative count. If the build is short (data still
        // arriving on a faster path, or a weapon class not yet loaded), discard
        // it and rebuild from scratch next tick. The parent gates
        // bAllDataGenerated on bSetWeaponUpgradeSlotsList, so NOT setting the
        // flag here guarantees we are re-driven until we converge -- every
        // client lands on the same definitive list instead of committing a
        // timing-dependent short one (the root cause of "different players see
        // different upgrade counts").
        if (WeaponUpgradeSlotsList.Length == NumberOfWeaponUpgradeSlots)
        {
            bSetWeaponUpgradeSlotsList = True;
            WeaponUpgGenIndex = 0;
            `log("[DK_UPGSLOTS] Client slot build complete:" @ WeaponUpgradeSlotsList.Length @ "slots (matches server)");
        }
        else if (SyncCounter >= WEAPON_UPG_BUILD_DEADLINE)
        {
            // Data never completed within the deadline. Commit best-effort so
            // the trader still populates (consistent with the server's record),
            // and log loudly -- inspect the server's [DK_UPGSLOTS] recording lines.
            bSetWeaponUpgradeSlotsList = True;
            WeaponUpgGenIndex = 0;
            `log("[DK_UPGSLOTS] ERROR: client built" @ WeaponUpgradeSlotsList.Length @ "slots but server has" @ NumberOfWeaponUpgradeSlots @ "after deadline -- committing best-effort (DESYNC; inspect server recording)");
        }
        else
        {
            // Mismatch and still within the deadline: throw the partial build
            // away and start over next tick (flag stays unset => we get re-driven).
            `log("[DK_UPGSLOTS] Slot build mismatch (" $ WeaponUpgradeSlotsList.Length $ "/" $ NumberOfWeaponUpgradeSlots $ ") -- discarding partial build and retrying");
            WeaponUpgradeSlotsList.Length = 0;
            WeaponUpgGenIndex = 0;
            WeaponUpgGenUpgCounter = 0;
            WeaponUpgGenStallIdx = INDEX_NONE;
            WeaponUpgGenStallCount = 0;
        }
    }
    // else: return without setting the flag -- SyncTimer will call us again next tick
}

// Builds one slot entry from replicated data. Mirrors the parent's
// AddWeaponUpgrade price math, with None-guards for placeholder slots.
simulated function DKAddSlotFromData(class<KFWeapon> KFW, int u, int BuyPrice)
{
    local WeaponUpgradeSlotStruct WepUpg;
    local int PU;
    local float PM;

    WepUpg.KFWeapon = KFW;

    PU = 0;
    PM = 0.f;

    if (u >= 0 && u < WeaponUpgradesList.Length)
    {
        WepUpg.WeaponUpgrade = WeaponUpgradesList[u].WeaponUpgrade; //May be None if load gave up -- slot stays aligned, menu hides it
        PU = WeaponUpgradesList[u].PriceUnit;
        PM = WeaponUpgradesList[u].PriceMultiplier;
        WepUpg.MaxLevel = WeaponUpgradesList[u].MaxLevel;
    }
    else
    {
        WepUpg.WeaponUpgrade = None;
        WepUpg.MaxLevel = 0;
        `log("[DK_UPGSLOTS] WARNING: replicated upgrade index" @ u @ "out of range (WeaponUpgradesList.Length=" $ WeaponUpgradesList.Length $ ")");
    }

    if (PU == 0)
        WepUpg.BasePrice = 0;
    else
    {
        if (KFW != None && KFW.default.DualClass != None) // is a dual weapon
            WepUpg.BasePrice = Max(PU, Round(float(BuyPrice) * 2 * PM / float(PU)) * PU);
        else
            WepUpg.BasePrice = Max(PU, Round(float(BuyPrice) * PM / float(PU)) * PU);
    }

    WepUpg.bDone = True;

    WeaponUpgradeSlotsList.AddItem(WepUpg);
}

// ===================================================================
// BITMASK READ (delegates to the local player's per-player PRI mask)
// The unlock flags moved to ZTPlayerReplicationInfo. This GRI accessor is
// only meaningful client-side (trader filter / HUD), so it reads the LOCAL
// player's PRI. On a dedicated server with no local PC it returns False;
// the server buy path does not gate on this (display filter only).
// ===================================================================

simulated function ZTPlayerReplicationInfo GetLocalDKPRI()
{
    local PlayerController PC;

    PC = GetALocalPlayerController();
    if (PC == None)
        return None;

    return ZTPlayerReplicationInfo(PC.PlayerReplicationInfo);
}

simulated function bool IsReforgedBitSet(int BitIndex)
{
    local ZTPlayerReplicationInfo DKPRI;

    DKPRI = GetLocalDKPRI();
    if (DKPRI == None)
        return False;

    return DKPRI.IsReforgedBitSet(BitIndex);
}

// ===================================================================
// ITEM ALLOWED OVERRIDE
// ===================================================================

simulated function bool IsItemAllowed(STraderItem Item)
{
    local int i, BitIndex;
    local string ClassName;

    // DK FIX: Precious early-return REMOVED. Precious weapon variants are
    // allowed again (ZR parity) - the post-build removal pass in
    // ZTGameInfo_Endless desynced the weapon-upgrade lists between
    // server and client. ClassName is still needed for the Reforged check.
    ClassName = string(Item.ClassName);

    // Reforged weapons are gated by the per-player Artificer unlock bitmask,
    // NOT by AllowedWeaponsList membership. This MUST run before
    // super.IsItemAllowed(): reforged weapons ARE in AllowedWeaponsList, so
    // super would return True and leak every reforged weapon into the trader
    // regardless of unlock state. (That leak is also why they showed up at all
    // in Endless while AllWeapons -- which gates correctly -- hid them.)
    // Mirrors ZTGameReplicationInfo_AllWeapons.IsItemAllowed.
    if (Len(ClassName) > 8 && Right(ClassName, 8) ~= "Reforged")
    {
        if (ReforgedStartIndex > 0)
        {
            for (i = ReforgedStartIndex; i < AllowedWeaponsList.Length; ++i)
            {
                if (Item.ClassName == AllowedWeaponsList[i].WeaponName
                    || Item.SingleClassName == AllowedWeaponsList[i].WeaponName)
                {
                    BitIndex = i - ReforgedStartIndex;
                    return IsReforgedBitSet(BitIndex);
                }
            }
        }
        return False;
    }

    if (super.IsItemAllowed(Item))
        return True;

    return False;
}

// ===================================================================
// HELPERS
// ===================================================================

simulated function int FindReforgedBitIndex(name WeaponName)
{
    local int i;

    for (i = ReforgedStartIndex; i < AllowedWeaponsList.Length; ++i)
    {
        if (WeaponName == AllowedWeaponsList[i].WeaponName)
            return i - ReforgedStartIndex;
    }

    return INDEX_NONE;
}

simulated function int GetTotalReforgedUnlocked()
{
    local int i, Count, TotalReforged;

    TotalReforged = AllowedWeaponsList.Length - ReforgedStartIndex;
    for (i = 0; i < TotalReforged; ++i)
    {
        if (IsReforgedBitSet(i))
            ++Count;
    }

    return Count;
}

// ===================================================================
// CLIENT-SIDE SPECIAL WAVE ID SUPPRESSION
// SpecialWaveID (byte, replicates instantly) arrives on client before
// SpecialWavesList (built via SyncAllSpecialWaves + DynamicLoadObject).
// WMPerk checks SpecialWaveID != INDEX_NONE then accesses
// SpecialWavesList[SpecialWaveID[i]] => OOB on empty array (1800+ hits).
// Fix: Force SpecialWaveID to INDEX_NONE on client until sync is done.
// ===================================================================

simulated event Tick(float DeltaTime)
{
    super.Tick(DeltaTime);

    // CAPSTONE CLIENT SYNC: perk capstone gates read
    // class'ZTConfig_Capstone'.default.Capstone_RankXLevel directly. On a client
    // with no server INI those defaults are 0, so capstone-gated effects (the
    // simulated / client-side ones especially) would fire from level 1. The real
    // thresholds replicate here on the GRI, so push them into the config class
    // defaults once - making every inline read correct on the client for both
    // default and custom capstone levels. Client-only; server/host already have
    // the correct config from the INI.
    //
    // Pre-replication fallback: before CapstoneR1Level arrives, seed 10/20 in
    // code so gates don't read 0 during the join window. (Assigning a config
    // var's .default at runtime is fine - InitializeConfig does the same; the
    // codebase rule only forbids config vars inside defaultproperties blocks.)
    if (!bCapstoneSyncedToConfig && WorldInfo.NetMode == NM_Client
        && class'ZTConfig_Capstone'.default.Capstone_Rank1Level <= 0)
    {
        class'ZTConfig_Capstone'.default.Capstone_Rank1Level = 10;
        class'ZTConfig_Capstone'.default.Capstone_Rank2Level = 20;
    }

    if (!bCapstoneSyncedToConfig && CapstoneR1Level > 0 && WorldInfo.NetMode == NM_Client)
    {
        class'ZTConfig_Capstone'.default.Capstone_Rank1Level = CapstoneR1Level;
        class'ZTConfig_Capstone'.default.Capstone_Rank2Level = CapstoneR2Level;
        bCapstoneSyncedToConfig = True;
    }

    // Suppress SpecialWaveID when SpecialWavesList is empty or class is None.
    // On dedicated server clients: list is empty until SyncAllSpecialWaves
    //   completes DynamicLoadObject for all entries. Suppress until then.
    // On listen server / solo: list is populated by server code directly,
    //   so Length > 0 and this guard does not fire (real special waves work).
    // This replaces the old bSpecialWavesSynced check which didn't account
    //   for listen server where bSpecialWavesSynced is never set True.
    if (SpecialWaveID[0] != INDEX_NONE)
    {
        if (SpecialWaveID[0] >= SpecialWavesList.Length)
            SpecialWaveID[0] = INDEX_NONE;
        else if (SpecialWavesList[SpecialWaveID[0]].SpecialWave == None)
            SpecialWaveID[0] = INDEX_NONE;
    }
    if (SpecialWaveID[1] != INDEX_NONE)
    {
        if (SpecialWaveID[1] >= SpecialWavesList.Length)
            SpecialWaveID[1] = INDEX_NONE;
        else if (SpecialWavesList[SpecialWaveID[1]].SpecialWave == None)
            SpecialWaveID[1] = INDEX_NONE;
    }
}

// ===================================================================
// MUSIC SUPPRESSION DURING EVENT WAVES
// Prevents KF2 native music from playing when an event wave is active.
// KF2's OneSecondLoop calls PlayNewMusicTrack when MusicComp stops --
// this override blocks that entirely during event waves.
// ===================================================================

simulated function PlayNewMusicTrack(optional bool bGameStateChanged, optional bool bForceAmbient)
{
    if (ActiveEventWaveID != 0)
    {
        // Kill any music that's already playing
        if (MusicComp != None && MusicComp.IsPlaying())
        {
            MusicComp.StopEvents();
        }
        return;
    }

    Super.PlayNewMusicTrack(bGameStateChanged, bForceAmbient);
}

// ===================================================================
// =====================================================================
//
//  BULK SYNC INGEST  (called from ZTPlayerController after each roster
//                     completes, runs DynamicLoadObject and populates
//                     XList[] just like the legacy Sync* functions did)
//
// =====================================================================
// ===================================================================

// ---------------------------------------------------------------------
// CLIENT-SIDE Sync*() SUPPRESSION
// ---------------------------------------------------------------------
// Note: We do NOT add per-function NetMode gates to the existing
// SyncAllPerkUpgrades / SyncAllSkillUpgrades / SyncAllWeaponUpgrades /
// DKSyncAllowedWeapons / DKSyncWeaponTraderItems overrides because
// those overrides were already declared earlier in this file (extending
// trader replication 512->1024 + retry-on-load-failure logic).
// Adding new declarations would conflict with the existing ones.
//
// Instead, the client-side suppression happens at a single chokepoint:
// ProcessAllSyncData is NM_Client-gated to early-return. Since that's
// the only caller of all the Sync*() functions, none of them ever fire
// on the client.
//
// The remaining parent Sync* functions (StartingWeapons, EquipmentUpgrades,
// Sidearms, Grenades, SpecialWaves, ZedBuffs) likewise only run from
// ProcessAllSyncData and are correctly suppressed.

// ---------------------------------------------------------------------
// INGEST FUNCTIONS — MOVED TO ZTPlayerController.uc
// ---------------------------------------------------------------------
// UE3 forbids cross-class struct references in function parameter lists
// (e.g. array<ZTPlayerController.FBulkX>), so the ingest functions and
// their RecvBuf_X buffers must live in the same class as the FBulkX
// struct definitions: ZTPlayerController. Functions are now in
// ZTPlayerController.uc; each takes a ZTGameReplicationInfo parameter
// and writes directly to its lists.

// ---------------------------------------------------------------------
// COMPLETION HANDSHAKE
// ---------------------------------------------------------------------
// Called from ZTPlayerController.ClientBulkSyncComplete after all 11
// rosters have been delivered AND ingested. Sets bAllDataSynced=true
// and immediately runs GenerateDataFromSyncData so the trader populates
// without waiting for the next 0.5s SyncTimer tick.

simulated function OnBulkSyncComplete()
{
    // Step 1 fix: do NOT force bAllDataSynced=true and do NOT call
    //   GenerateDataFromSyncData() here. The legacy ProcessAllSyncData
    //   flow is the source of truth for bAllDataSynced -- it flips the
    //   flag only when ALL per-roster sync flags are set, which only
    //   happens when XList[] is actually populated.
    //
    // If we forced the flag here, GenerateDataFromSyncData() would run
    //   against empty XList[] (because bulk sync chunk RPCs are dropping
    //   in the current UE3 setup -- see Step 1 diagnosis), producing an
    //   empty trader. Letting the legacy flow drive the flag means we
    //   only generate after lists are populated from rep arrays.
    //
    // Bulk sync ingest (when chunks DO arrive) sets per-roster flags
    //   directly on DKGRI; the legacy ProcessAllSyncData notices the
    //   flag is already true for that roster and skips it. So the two
    //   flows compose cleanly: whichever populates a roster first wins,
    //   and bAllDataSynced flips when both flows together have covered
    //   every roster.
    `log("[DK_BULKSYNC] OnBulkSyncComplete -- bulk sync handshake received (no-op; legacy flow controls bAllDataSynced)");
}

defaultproperties
{
    ReforgedStartIndex=0

    bAllowPerkReroll=False
    PerkRerollBaseCost=500
    PerkRerollMultiplier=1.5f

    MaxDifferentPerks=0
    bProgressivePerkUnlock=False
    bDeluxeUpgradeEnabled=False
    DeluxeMinPerkLevel=10
    DeluxeUpgradeCost=1500
    bDeluxeTargetedSelection=False
    CapstoneR1Level=0
    CapstoneR2Level=0
    CapstoneMaxR1=0
    CapstoneMaxR2=0

    bAllowedWeaponsSynced_C=False
    bAllowedWeaponsSynced_D=False
    bTraderWeaponsSynced_C=False
    bTraderWeaponsSynced_D=False

    ActiveEventWaveID=0
    EventWaveStartTime=0.0
    EventSwapInterval=0

    SlotDataChecksum=0
    bSlotDataVerified=False
    SlotResyncNextTick=-1
    SyncTimeoutExtensions=0

    WeaponUpgGenIndex=0
    WeaponUpgGenUpgCounter=0
    WeaponUpgGenStallIdx=-1
    WeaponUpgGenStallCount=0

    Name="Default__ZTGameReplicationInfo"
}
