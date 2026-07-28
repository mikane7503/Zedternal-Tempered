class DKUpgrade_Perk_Artificer_Helper extends Info;

// ===================================================================
// ARTIFICER HELPER — Per-Player State Manager
//
// Tracks weapon kills, manages reforge unlocks, handles mastery
// milestones with random stat rolls, and computes resonance bonuses.
// Spawned as a child actor of the owning KFPawn_Human.
//
// HUD Integration: Uses reliable client RPCs to push display data
// to DKHudWrapper via GetReaperHUD() (follows Gambit/Shapeshifter pattern).
// Two-phase card: Phase 0 = Reforge unlock tracking, Phase 1 = Mastery tracking.
// Only one card on screen at a time; transitions when reforge unlocks.
//
// Sound Integration: Uses DKSoundManager + DKPlayerController.ClientPlayBuffSound()
// for client-side audio feedback.
// ===================================================================

// Current perk level (updated by main perk class each damage call)
var int PerkLevel;

// ===================================================================
// WEAPON KILL TRACKING
// Key: normalized weapon name (e.g. "AssaultRifle_AK12")
// Value: total kills with that weapon this match
// ===================================================================

struct SWeaponKillEntry
{
    var string NormName;        // Normalized weapon identifier
    var int Kills;              // Lifetime kills this match
    var bool bReforgeUnlocked;  // Whether we already triggered the reforge unlock
    var int ReforgeKillCount;   // Kill count at the moment reforge was unlocked (mastery starts from here)
};
var array<SWeaponKillEntry> WeaponKills;

// ===================================================================
// MASTERY SYSTEM (Level 10+)
// Tracks accumulated random stat bonuses per weapon from milestones
// ===================================================================

// 7 stat indices:
// 0 = Damage, 1 = ReloadSpeed, 2 = MagSize, 3 = SpareAmmo
// 4 = Recoil, 5 = Spread, 6 = Penetration
const NUM_MASTERY_STATS = 7;

struct SMasteryEntry
{
    var string NormName;                // Normalized weapon identifier
    var int MilestonesCompleted;        // How many 100-kill milestones hit
    var float MasteryBonus_0;           // Damage bonus accumulated
    var float MasteryBonus_1;           // ReloadSpeed bonus accumulated
    var float MasteryBonus_2;           // MagSize bonus accumulated
    var float MasteryBonus_3;           // SpareAmmo bonus accumulated
    var float MasteryBonus_4;           // Recoil bonus accumulated
    var float MasteryBonus_5;           // Spread bonus accumulated
    var float MasteryBonus_6;           // Penetration bonus accumulated
};
var array<SMasteryEntry> MasteryData;

// Number of unique weapons that have at least 1 mastery milestone
// Used for Resonance cross-weapon bonus calculation
var int MasteredWeaponCount;

// ===================================================================
// KILL DEDUPLICATION
// ===================================================================

struct SKillRecord
{
    var KFPawn_Monster Monster;
    var float KillTime;
};
var array<SKillRecord> RecentKills;
var const float KillDedupeWindow;
var float LastCleanupTime;

// ===================================================================
// PLAYER REFERENCES
// ===================================================================

var KFPawn_Human Player;
var KFPlayerController PlayerPC;

// ===================================================================
// HUD DISPLAY STATE (tracked server-side for RPC updates)
// ===================================================================

// Name of the weapon currently being tracked for display
var string CurrentDisplayWeapon;

// ===================================================================
// INITIALIZATION
// ===================================================================

function PostBeginPlay()
{
    super.PostBeginPlay();

    if (Owner == None)
    {
        Destroy();
        return;
    }

    Player = KFPawn_Human(Owner);
    if (Player == None || Player.Health <= 0)
    {
        Destroy();
        return;
    }

    PlayerPC = KFPlayerController(Player.Controller);
    LastCleanupTime = Owner.WorldInfo.TimeSeconds;
}

// ===================================================================
// KILL TRACKING — Called from DKUpgrade_Perk_Artificer.ModifyDamageGiven
// ===================================================================

// ===================================================================
// CONFIRMED KILL — Called from GameInfo.Killed() via DKUpgrade_Perk_Artificer.NotifyZedKilled
// This is the authoritative entry point. Weapon already resolved to NormName.
// ===================================================================

function NotifyConfirmedKill(string NormName, bool bIsReforged)
{
    local int KillIdx, KillCount, Threshold;
    local SWeaponKillEntry TempEntry;

    if (Player == None)
        return;

    // Find or create kill entry
    KillIdx = FindOrCreateKillEntry(NormName);

    // Auto-unlock for weapons without a Reforged variant (custom weapons)
    if (!WeaponKills[KillIdx].bReforgeUnlocked && !class'DKUpgrade_Perk_Artificer'.static.HasReforgedVariant(NormName))
    {
        TempEntry = WeaponKills[KillIdx];
        TempEntry.bReforgeUnlocked = True;
        TempEntry.ReforgeKillCount = 0;
        WeaponKills[KillIdx] = TempEntry;
        `log("[DK_ARTIFICER] Auto-unlocked mastery for custom weapon" @ NormName @ "(no Reforged variant)");
    }

    // Level 20 Resonance: Reforged weapon kills count double
    if (PerkLevel >= class'DKConfig_Capstone'.default.Capstone_Rank2Level && bIsReforged)
        WeaponKills[KillIdx].Kills += 2;
    else
        WeaponKills[KillIdx].Kills += 1;

    KillCount = WeaponKills[KillIdx].Kills;
    `log("[DK_ARTIFICER] Kill confirmed:" @ NormName @ "=" @ KillCount
        @ "(Reforged=" $ bIsReforged $ ", PerkLevel=" $ PerkLevel $ ")");

    // === REFORGE UNLOCK CHECK (Level 1+) ===
    if (!WeaponKills[KillIdx].bReforgeUnlocked)
    {
        Threshold = class'DKUpgrade_Perk_Artificer'.static.GetReforgeThresholdForLevel(PerkLevel);
        if (KillCount >= Threshold)
        {
            TempEntry = WeaponKills[KillIdx];
            TempEntry.ReforgeKillCount = KillCount;
            TempEntry.bReforgeUnlocked = True;
            WeaponKills[KillIdx] = TempEntry;

            `log("[DK_ARTIFICER] REFORGE TRIGGERED for" @ NormName
                @ "at KillCount=" @ KillCount
                @ "| ReforgeKillCount stored=" @ WeaponKills[KillIdx].ReforgeKillCount
                @ "| bReforgeUnlocked=" @ WeaponKills[KillIdx].bReforgeUnlocked);

            TriggerReforgeUnlock(NormName);
        }
    }

    // === MASTERY MILESTONE CHECK (Level 10+) ===
    if (PerkLevel >= class'DKConfig_Capstone'.default.Capstone_Rank1Level)
    {
        CheckMasteryMilestone(NormName, KillCount);
    }

    // Update HUD with current progress
    CurrentDisplayWeapon = NormName;
    SendProgressUpdate(NormName, KillCount);
}

// LEGACY: TrackWeaponKill kept for backwards compatibility but now routes through NotifyConfirmedKill
function TrackWeaponKill(KFWeapon KFW, KFPawn_Monster KilledMonster)
{
    local string NormName;
    local int KillIdx, KillCount, Threshold;
    local bool bIsReforged;
    local float CurrentTime;
    local SKillRecord NewRecord;
    local SWeaponKillEntry TempEntry;

    if (KFW == None || KilledMonster == None || Player == None)
        return;

    // Deduplication check
    CurrentTime = Owner.WorldInfo.TimeSeconds;
    if (IsRecentKill(KilledMonster, CurrentTime))
        return;

    // Record for deduplication
    NewRecord.Monster = KilledMonster;
    NewRecord.KillTime = CurrentTime;
    RecentKills.AddItem(NewRecord);

    // Periodic cleanup
    if (CurrentTime - LastCleanupTime > 2.0f)
    {
        CleanupOldKills(CurrentTime);
        LastCleanupTime = CurrentTime;
    }

    // Skip Hollow weapon variants — they are a separate perk system
    if (class'DKUpgrade_Perk_Artificer'.static.IsHollowWeapon(KFW))
        return;

    // Normalize weapon name
    NormName = class'DKUpgrade_Perk_Artificer'.static.NormalizeWeaponName(string(KFW.Class.Name));
    bIsReforged = class'DKUpgrade_Perk_Artificer'.static.IsReforgedWeapon(KFW);

    // DEBUG: Log Resonance double-count check so we can verify it fires
    if (PerkLevel >= class'DKConfig_Capstone'.default.Capstone_Rank2Level)
    {
        `log("ZR Artificer [Resonance]: ClassName=" @ string(KFW.Class.Name)
            @ "IsReforged=" @ bIsReforged
            @ "PerkLevel=" @ PerkLevel);
    }

    // Find or create kill entry
    KillIdx = FindOrCreateKillEntry(NormName);

    // Auto-unlock for weapons without a Reforged variant (custom weapons)
    // This lets mastery count from kill 0 instead of gating behind a threshold
    if (!WeaponKills[KillIdx].bReforgeUnlocked && !class'DKUpgrade_Perk_Artificer'.static.HasReforgedVariant(NormName))
    {
        TempEntry = WeaponKills[KillIdx];
        TempEntry.bReforgeUnlocked = True;
        TempEntry.ReforgeKillCount = 0;
        WeaponKills[KillIdx] = TempEntry;
        `log("ZR Artificer: Auto-unlocked mastery for custom weapon" @ NormName @ "(no Reforged variant)");
    }

    // Level 20 Resonance: Reforged weapon kills count double
    if (PerkLevel >= class'DKConfig_Capstone'.default.Capstone_Rank2Level && bIsReforged)
        WeaponKills[KillIdx].Kills += 2;
    else
        WeaponKills[KillIdx].Kills += 1;

    KillCount = WeaponKills[KillIdx].Kills;
    `log("ZR Artificer: Kill tracked for" @ NormName @ "=" @ KillCount
        @ "(Reforged=" $ bIsReforged $ ", PerkLevel=" $ PerkLevel $ ")");

    // === REFORGE UNLOCK CHECK (Level 1+) ===
    if (!WeaponKills[KillIdx].bReforgeUnlocked)
    {
        Threshold = class'DKUpgrade_Perk_Artificer'.static.GetReforgeThresholdForLevel(PerkLevel);
        if (KillCount >= Threshold)
        {
            // FIX: Use local struct copy to ensure both fields persist atomically
            // UE3 can have issues with multiple struct-in-array member writes
            TempEntry = WeaponKills[KillIdx];
            TempEntry.ReforgeKillCount = KillCount;
            TempEntry.bReforgeUnlocked = True;
            WeaponKills[KillIdx] = TempEntry;

            `log("ZR Artificer: REFORGE TRIGGERED for" @ NormName
                @ "at KillCount=" @ KillCount
                @ "| ReforgeKillCount stored=" @ WeaponKills[KillIdx].ReforgeKillCount
                @ "| bReforgeUnlocked=" @ WeaponKills[KillIdx].bReforgeUnlocked);

            TriggerReforgeUnlock(NormName);
        }
    }

    // === MASTERY MILESTONE CHECK (Level 10+) ===
    if (PerkLevel >= class'DKConfig_Capstone'.default.Capstone_Rank1Level)
    {
        CheckMasteryMilestone(NormName, KillCount);
    }

    // Update HUD with current progress AFTER all state changes
    // This ensures Phase, MilestoneNum, and KillTarget are all up-to-date
    CurrentDisplayWeapon = NormName;
    SendProgressUpdate(NormName, KillCount);
}

// ===================================================================
// REFORGE UNLOCK — Tells the GRI to set the bitmask bit
// ===================================================================

function TriggerReforgeUnlock(string NormName)
{
    local DKGameReplicationInfo DKGRI;
    local DKPlayerReplicationInfo DKPRI;
    local name ReforgedWeapName;
    local int BitIndex;

    DKGRI = DKGameReplicationInfo(Owner.WorldInfo.GRI);
    if (DKGRI == None)
    {
        `log("ZR Artificer ERROR: GRI is not DKGameReplicationInfo, cannot unlock reforged weapon");
        return;
    }

    // Per-player unlock state now lives on the owning player's PRI, not the
    // shared GRI -- this is what stops unlocks leaking to other players.
    if (PlayerPC != None)
        DKPRI = DKPlayerReplicationInfo(PlayerPC.PlayerReplicationInfo);

    if (DKPRI == None)
    {
        `log("ZR Artificer ERROR: No DKPlayerReplicationInfo for player, cannot unlock reforged weapon");
        return;
    }

    // Build the expected Reforged weapon class name from the normalized name
    // "AssaultRifle_AK12" -> "DKWeap_AssaultRifle_AK12_Reforged"
    ReforgedWeapName = name("DKWeap_" $ NormName $ "_Reforged");

    // Look up the bit index in the GRI's shared AllowedWeaponsList layout
    BitIndex = DKGRI.FindReforgedBitIndex(ReforgedWeapName);
    if (BitIndex == INDEX_NONE)
    {
        `log("ZR Artificer WARNING: Could not find Reforged weapon in AllowedWeaponsList:" @ string(ReforgedWeapName));
        return;
    }

    // Set the bit on THIS player's PRI
    if (DKPRI.UnlockReforgedWeapon(BitIndex))
    {
        `log("ZR Artificer: REFORGED UNLOCKED:" @ string(ReforgedWeapName) @ "(bit" @ BitIndex $ ")");

        // Send unlock notification to client HUD + play sound
        ClientShowReforgeUnlock(NormName);
        PlayArtificerSound('Artificer_Reforge_Unlock');

        // Send to notification feed via DKMessageManager
        if (PlayerPC != None)
            class'DKMessageManager'.static.SendImportant(PlayerPC, "Artificer: Reforged" @ NormName @ "unlocked!");
    }
}

// ===================================================================
// MASTERY MILESTONE — Random stat rolls on 100-kill milestones
// Milestones are computed from kills AFTER reforge, not total kills.
// ===================================================================

function CheckMasteryMilestone(string NormName, int KillCount)
{
    local int MasteryIdx, MilestonesNow, MilestonesWas, NewMilestones;
    local int MilestoneKills, RollCount, i, j, StatIdx, k;
    local int MasteryKills;
    local float BonusPerRoll;
    local string RollsStr, FeedStr;
    // Per-stat trackers for what was added THIS milestone (7 stats, no bool arrays)
    local float NewBonus_0, NewBonus_1, NewBonus_2, NewBonus_3;
    local float NewBonus_4, NewBonus_5, NewBonus_6;
    local float TotalVal, NewVal;
    local int TotalPct, NewPct;

    MilestoneKills = class'DKUpgrade_Perk_Artificer'.default.MasteryMilestoneKills;
    if (MilestoneKills <= 0)
        return;

    // Mastery kills = total kills minus kills at reforge unlock
    // If not yet reforged, mastery kills is 0 (no milestones possible)
    MasteryKills = KillCount - GetReforgeKillCount(NormName);
    if (MasteryKills <= 0)
        return;

    MilestonesNow = MasteryKills / MilestoneKills;

    // Find or create mastery entry
    MasteryIdx = FindOrCreateMasteryEntry(NormName);
    MilestonesWas = MasteryData[MasteryIdx].MilestonesCompleted;

    // Any new milestones?
    NewMilestones = MilestonesNow - MilestonesWas;
    if (NewMilestones <= 0)
        return;

    // How many rolls per milestone at current perk level
    RollCount = class'DKUpgrade_Perk_Artificer'.static.GetMasteryRollCount(PerkLevel);
    BonusPerRoll = class'DKUpgrade_Perk_Artificer'.default.MasteryBonusPerRoll;

    // Process each new milestone
    for (i = 0; i < NewMilestones; ++i)
    {
        // Reset per-stat new-bonus trackers for this milestone
        NewBonus_0 = 0.f;
        NewBonus_1 = 0.f;
        NewBonus_2 = 0.f;
        NewBonus_3 = 0.f;
        NewBonus_4 = 0.f;
        NewBonus_5 = 0.f;
        NewBonus_6 = 0.f;

        for (j = 0; j < RollCount; ++j)
        {
            // Random stat from 0-6
            StatIdx = Rand(NUM_MASTERY_STATS);
            ApplyMasteryRoll(MasteryIdx, StatIdx, BonusPerRoll);

            // Track what was added this milestone per stat
            switch (StatIdx)
            {
                case 0: NewBonus_0 += BonusPerRoll; break;
                case 1: NewBonus_1 += BonusPerRoll; break;
                case 2: NewBonus_2 += BonusPerRoll; break;
                case 3: NewBonus_3 += BonusPerRoll; break;
                case 4: NewBonus_4 += BonusPerRoll; break;
                case 5: NewBonus_5 += BonusPerRoll; break;
                case 6: NewBonus_6 += BonusPerRoll; break;
            }

            `log("ZR Artificer: Mastery roll for" @ NormName @ "-> stat" @ StatIdx @ "+" $ BonusPerRoll);
        }

        // Build structured RollsStr: "StatIdx:TotalPct:NewPct|..."
        // Includes ALL stats with total > 0 for this weapon (not just new rolls)
        // so the HUD can display the full mastery snapshot with highlights.
        RollsStr = "";
        FeedStr = "";

        for (k = 0; k < NUM_MASTERY_STATS; ++k)
        {
            // Get total accumulated bonus for this stat (already includes this milestone's rolls)
            TotalVal = GetMasteryBonusByIndex(MasteryIdx, k);

            // Get the new amount added this milestone
            switch (k)
            {
                case 0: NewVal = NewBonus_0; break;
                case 1: NewVal = NewBonus_1; break;
                case 2: NewVal = NewBonus_2; break;
                case 3: NewVal = NewBonus_3; break;
                case 4: NewVal = NewBonus_4; break;
                case 5: NewVal = NewBonus_5; break;
                case 6: NewVal = NewBonus_6; break;
                default: NewVal = 0.f; break;
            }

            // Only include stats that have any accumulated bonus
            if (TotalVal > 0.f)
            {
                TotalPct = int(TotalVal * 100.f + 0.5f);
                NewPct = int(NewVal * 100.f + 0.5f);

                if (RollsStr != "")
                    RollsStr $= "|";
                RollsStr $= string(k) $ ":" $ string(TotalPct) $ ":" $ string(NewPct);

                // Build human-readable version for notification feed
                if (FeedStr != "")
                    FeedStr $= ", ";
                if (NewPct > 0)
                    FeedStr $= GetMasteryStatName(k) @ "+" $ TotalPct $ "%(+" $ NewPct $ "%)";
                else
                    FeedStr $= GetMasteryStatName(k) @ "+" $ TotalPct $ "%";
            }
        }

        // Track milestone count
        MasteryData[MasteryIdx].MilestonesCompleted += 1;

        // Update mastered weapon count (first milestone on this weapon)
        if (MilestonesWas == 0 && i == 0)
            MasteredWeaponCount += 1;

        // Send mastery notification to client HUD + play sound
        // RollsStr is the structured format for the HUD parser
        ClientShowMasteryComplete(NormName, MilestonesWas + i + 1, RollsStr);
        PlayArtificerSound('Artificer_Mastery_Milestone');

        // Send human-readable version to notification feed via DKMessageManager
        if (PlayerPC != None)
            class'DKMessageManager'.static.SendCritical(PlayerPC, "Artificer: Mastery #" $ (MilestonesWas + i + 1) @ "on" @ NormName @ "-" @ FeedStr);
    }
}

// Apply a single random stat roll to a mastery entry
function ApplyMasteryRoll(int MasteryIdx, int StatIdx, float BonusAmount)
{
    switch (StatIdx)
    {
        case 0: MasteryData[MasteryIdx].MasteryBonus_0 += BonusAmount; break;
        case 1: MasteryData[MasteryIdx].MasteryBonus_1 += BonusAmount; break;
        case 2: MasteryData[MasteryIdx].MasteryBonus_2 += BonusAmount; break;
        case 3: MasteryData[MasteryIdx].MasteryBonus_3 += BonusAmount; break;
        case 4: MasteryData[MasteryIdx].MasteryBonus_4 += BonusAmount; break;
        case 5: MasteryData[MasteryIdx].MasteryBonus_5 += BonusAmount; break;
        case 6: MasteryData[MasteryIdx].MasteryBonus_6 += BonusAmount; break;
    }
}

/** Read a mastery bonus by array index + stat index.
 *  Used by CheckMasteryMilestone to build the structured display string
 *  after rolls have been applied (avoids redundant name lookup). */
function float GetMasteryBonusByIndex(int MasteryIdx, int StatIdx)
{
    if (MasteryIdx < 0 || MasteryIdx >= MasteryData.Length)
        return 0.f;

    switch (StatIdx)
    {
        case 0: return MasteryData[MasteryIdx].MasteryBonus_0;
        case 1: return MasteryData[MasteryIdx].MasteryBonus_1;
        case 2: return MasteryData[MasteryIdx].MasteryBonus_2;
        case 3: return MasteryData[MasteryIdx].MasteryBonus_3;
        case 4: return MasteryData[MasteryIdx].MasteryBonus_4;
        case 5: return MasteryData[MasteryIdx].MasteryBonus_5;
        case 6: return MasteryData[MasteryIdx].MasteryBonus_6;
        default: return 0.f;
    }
}

/** Map stat index to human-readable name for HUD display. */
static function string GetMasteryStatName(int StatIdx)
{
    switch (StatIdx)
    {
        case 0: return "Damage";
        case 1: return "Reload";
        case 2: return "MagSize";
        case 3: return "Ammo";
        case 4: return "Recoil";
        case 5: return "Spread";
        case 6: return "Penetration";
        default: return "???";
    }
}

// ===================================================================
// MASTERY BONUS QUERIES — Called from main perk class static functions
// ===================================================================

function float GetMasteryBonus(string NormName, int StatIdx)
{
    local int i;

    for (i = 0; i < MasteryData.Length; ++i)
    {
        if (MasteryData[i].NormName == NormName)
        {
            switch (StatIdx)
            {
                case 0: return MasteryData[i].MasteryBonus_0;
                case 1: return MasteryData[i].MasteryBonus_1;
                case 2: return MasteryData[i].MasteryBonus_2;
                case 3: return MasteryData[i].MasteryBonus_3;
                case 4: return MasteryData[i].MasteryBonus_4;
                case 5: return MasteryData[i].MasteryBonus_5;
                case 6: return MasteryData[i].MasteryBonus_6;
            }
        }
    }

    return 0.f;
}

// Level 20 Resonance: +1% damage per mastered weapon (weapons with at least 1 milestone)
function float GetResonanceBonus()
{
    return float(MasteredWeaponCount) * class'DKUpgrade_Perk_Artificer'.default.ResonanceCrossBonus;
}

// Get total kills for a normalized weapon name
function int GetWeaponKills(string NormName)
{
    local int i;

    for (i = 0; i < WeaponKills.Length; ++i)
    {
        if (WeaponKills[i].NormName == NormName)
            return WeaponKills[i].Kills;
    }

    return 0;
}

// Get the kill count at the moment reforge was unlocked for a weapon
function int GetReforgeKillCount(string NormName)
{
    local int i;

    for (i = 0; i < WeaponKills.Length; ++i)
    {
        if (WeaponKills[i].NormName == NormName)
            return WeaponKills[i].ReforgeKillCount;
    }

    return 0;
}

// Get milestones completed for a normalized weapon name
function int GetMilestonesCompleted(string NormName)
{
    local int i;

    for (i = 0; i < MasteryData.Length; ++i)
    {
        if (MasteryData[i].NormName == NormName)
            return MasteryData[i].MilestonesCompleted;
    }

    return 0;
}

// ===================================================================
// RECHECK ALL THRESHOLDS
// Called when perk is first acquired or level changes to catch
// any weapons that already meet the new (lower) threshold
// ===================================================================

function RecheckAllThresholds()
{
    local int i, Threshold;
    local DKGameReplicationInfo DKGRI;
    local SWeaponKillEntry TempEntry;

    DKGRI = DKGameReplicationInfo(Owner.WorldInfo.GRI);
    if (DKGRI == None)
        return;

    Threshold = class'DKUpgrade_Perk_Artificer'.static.GetReforgeThresholdForLevel(PerkLevel);

    for (i = 0; i < WeaponKills.Length; ++i)
    {
        if (!WeaponKills[i].bReforgeUnlocked && WeaponKills[i].Kills >= Threshold)
        {
            // FIX: Use local struct copy for atomic write
            TempEntry = WeaponKills[i];
            TempEntry.ReforgeKillCount = TempEntry.Kills;
            TempEntry.bReforgeUnlocked = True;
            WeaponKills[i] = TempEntry;

            TriggerReforgeUnlock(WeaponKills[i].NormName);
        }
    }
}

// ===================================================================
// HUD INTEGRATION — Server builds data, sends via reliable client RPC
// Follows Gambit/Shapeshifter pattern:
//   Server -> ClientRPC -> DKHudWrapper (DIRECT, no intermediary)
//
// Two-phase card system:
//   Phase 0 = Reforge Unlock tracking (orange/amber accent)
//   Phase 1 = Mastery Progress tracking (gold accent)
//   Only one card on screen at a time. Transitions when reforge unlocks.
//
// Mastery counter:
//   Kills shown are relative to reforge unlock point.
//   0/100 -> 100/100 (milestone fires) -> 101/200 -> 200/200 etc.
// ===================================================================

/** Send kill progress update to client HUD.
 *  Determines Phase automatically based on reforge unlock state.
 *  For Phase 1 (mastery), sends kills relative to reforge point. */
function SendProgressUpdate(string NormName, int KillCount)
{
    local int MilestoneKills, MilestoneNum, KillTarget, KillIdx;
    local int MasteryKills, ReforgeKills;
    local bool bReforged;
    local byte Phase;
    local SWeaponKillEntry TempEntry;

    MilestoneKills = class'DKUpgrade_Perk_Artificer'.default.MasteryMilestoneKills;
    if (MilestoneKills <= 0)
        MilestoneKills = 100;

    MilestoneNum = GetMilestonesCompleted(NormName);

    // Determine phase: has this weapon been reforged yet?
    bReforged = False;
    KillIdx = FindKillEntry(NormName);
    if (KillIdx != INDEX_NONE)
        bReforged = WeaponKills[KillIdx].bReforgeUnlocked;

    if (!bReforged)
    {
        // Phase 0: tracking toward reforge unlock threshold
        Phase = 0;
        KillTarget = class'DKUpgrade_Perk_Artificer'.static.GetReforgeThresholdForLevel(PerkLevel);

        // Send raw kill count for Phase 0
        ClientUpdateArtificerProgress(Phase, NormName, KillCount, KillTarget, MilestoneNum);
    }
    else
    {
        // Mastery card only appears at Level 10+
        // Below 10: explicitly clear so a stale card doesn't persist
        if (PerkLevel < class'DKConfig_Capstone'.default.Capstone_Rank1Level)
        {
            ClientClearArtificerHUD();
            return;
        }

        // Phase 1: tracking toward next mastery milestone
        // Display kills relative to reforge point so counter starts at 0/100
        Phase = 1;
        ReforgeKills = GetReforgeKillCount(NormName);

        // SAFETY: If ReforgeKillCount is 0 but weapon IS reforged, the stored value
        // was lost (UE3 struct-in-array write issue). Derive from threshold and fix it.
        // Skip for custom weapons (no Reforged variant) where 0 is intentional.
        if (ReforgeKills <= 0 && KillIdx != INDEX_NONE && class'DKUpgrade_Perk_Artificer'.static.HasReforgedVariant(NormName))
        {
            ReforgeKills = class'DKUpgrade_Perk_Artificer'.static.GetReforgeThresholdForLevel(PerkLevel);
            `log("ZR Artificer WARNING: ReforgeKillCount was 0 for reforged weapon" @ NormName
                @ "- recovering with threshold=" @ ReforgeKills);

            // Fix the stored value so this only happens once
            TempEntry = WeaponKills[KillIdx];
            TempEntry.ReforgeKillCount = ReforgeKills;
            WeaponKills[KillIdx] = TempEntry;
        }

        MasteryKills = KillCount - ReforgeKills;
        if (MasteryKills < 0)
            MasteryKills = 0;

        KillTarget = (MilestoneNum + 1) * MilestoneKills;

        // Send mastery-relative kills for Phase 1
        ClientUpdateArtificerProgress(Phase, NormName, MasteryKills, KillTarget, MilestoneNum);
    }
}

// ===================================================================
// RELIABLE CLIENT RPCs — Each calls DKHudWrapper DIRECTLY
// (per HUD_Element_Guide: no simulated intermediary functions)
// ===================================================================

/** Progress update — called on every kill. Phase determines card style. */
reliable client function ClientUpdateArtificerProgress(
    byte Phase,
    string InWeaponName,
    int InKillCount,
    int InKillTarget,
    int InMilestoneNum)
{
    local KFPlayerController KFPC;
    local DKHudWrapper HUD;

    KFPC = KFPlayerController(GetALocalPlayerController());
    if (KFPC == None || KFPC.myHUD == None)
        return;

    HUD = DKHudWrapper(KFPC.myHUD);
    if (HUD != None)
        HUD.UpdateArtificerProgress(Phase, InWeaponName, InKillCount, InKillTarget, InMilestoneNum);
}

/** Reforge unlock flash notification. */
reliable client function ClientShowReforgeUnlock(string InWeaponName)
{
    local KFPlayerController KFPC;
    local DKHudWrapper HUD;

    KFPC = KFPlayerController(GetALocalPlayerController());
    if (KFPC == None || KFPC.myHUD == None)
        return;

    HUD = DKHudWrapper(KFPC.myHUD);
    if (HUD != None)
        HUD.ShowArtificerReforgeUnlock(InWeaponName);
}

/** Mastery milestone flash notification with stat rolls. */
reliable client function ClientShowMasteryComplete(string InWeaponName, int InMilestoneNum, string InRollsString)
{
    local KFPlayerController KFPC;
    local DKHudWrapper HUD;

    KFPC = KFPlayerController(GetALocalPlayerController());
    if (KFPC == None || KFPC.myHUD == None)
        return;

    HUD = DKHudWrapper(KFPC.myHUD);
    if (HUD != None)
        HUD.ShowArtificerMasteryComplete(InWeaponName, InMilestoneNum, InRollsString);
}

/** Clear display (e.g. on death / perk removed). */
reliable client function ClientClearArtificerHUD()
{
    local KFPlayerController KFPC;
    local DKHudWrapper HUD;

    KFPC = KFPlayerController(GetALocalPlayerController());
    if (KFPC == None || KFPC.myHUD == None)
        return;

    HUD = DKHudWrapper(KFPC.myHUD);
    if (HUD != None)
        HUD.ClearArtificerDisplay();
}

// ===================================================================
// SOUND PLAYBACK — Route through DKSoundManager + ClientPlayBuffSound
// Follows Gambit pattern exactly.
// ===================================================================

/** Play an Artificer sound by registered name ID.
 *  Looks up via DKSoundManager, plays via DKPlayerController client RPC. */
function PlayArtificerSound(name SoundID)
{
    local DKPlayerController DKPC;
    local DKMutator Mut;
    local SoundCue Sound;

    if (Player == None || Player.Controller == None)
        return;

    DKPC = DKPlayerController(Player.Controller);
    if (DKPC == None)
        return;

    Mut = class'DKSoundManager'.static.GetMutator(WorldInfo);
    if (Mut == None)
        return;

    Sound = class'DKSoundManager'.static.GetSound(Mut, SoundID);
    if (Sound != None)
        DKPC.ClientPlayBuffSound(Sound);
}

// ===================================================================
// ARRAY HELPERS
// ===================================================================

/** Read-only lookup — returns INDEX_NONE if not found. */
function int FindKillEntry(string NormName)
{
    local int i;

    for (i = 0; i < WeaponKills.Length; ++i)
    {
        if (WeaponKills[i].NormName == NormName)
            return i;
    }

    return INDEX_NONE;
}

function int FindOrCreateKillEntry(string NormName)
{
    local int i;
    local SWeaponKillEntry NewEntry;

    for (i = 0; i < WeaponKills.Length; ++i)
    {
        if (WeaponKills[i].NormName == NormName)
            return i;
    }

    // Create new entry
    NewEntry.NormName = NormName;
    NewEntry.Kills = 0;
    NewEntry.bReforgeUnlocked = False;
    NewEntry.ReforgeKillCount = 0;
    WeaponKills.AddItem(NewEntry);
    return WeaponKills.Length - 1;
}

function int FindOrCreateMasteryEntry(string NormName)
{
    local int i;
    local SMasteryEntry NewEntry;

    for (i = 0; i < MasteryData.Length; ++i)
    {
        if (MasteryData[i].NormName == NormName)
            return i;
    }

    // Create new entry
    NewEntry.NormName = NormName;
    NewEntry.MilestonesCompleted = 0;
    NewEntry.MasteryBonus_0 = 0.f;
    NewEntry.MasteryBonus_1 = 0.f;
    NewEntry.MasteryBonus_2 = 0.f;
    NewEntry.MasteryBonus_3 = 0.f;
    NewEntry.MasteryBonus_4 = 0.f;
    NewEntry.MasteryBonus_5 = 0.f;
    NewEntry.MasteryBonus_6 = 0.f;
    MasteryData.AddItem(NewEntry);
    return MasteryData.Length - 1;
}

// ===================================================================
// KILL DEDUPLICATION
// ===================================================================

function bool IsRecentKill(KFPawn_Monster Monster, float CurrentTime)
{
    local int i;

    for (i = 0; i < RecentKills.Length; ++i)
    {
        if (RecentKills[i].Monster == Monster && (CurrentTime - RecentKills[i].KillTime) <= KillDedupeWindow)
            return True;
    }

    return False;
}

function CleanupOldKills(float CurrentTime)
{
    local int i;
    local array<SKillRecord> Cleaned;

    for (i = 0; i < RecentKills.Length; ++i)
    {
        if ((CurrentTime - RecentKills[i].KillTime) <= 1.0f)
            Cleaned.AddItem(RecentKills[i]);
    }

    RecentKills = Cleaned;
}

defaultproperties
{
    // Replication settings for reliable client RPCs (Gambit/Shapeshifter pattern)
    RemoteRole=ROLE_SimulatedProxy
    bAlwaysRelevant=False
    bOnlyRelevantToOwner=True
    bHidden=True
    bCollideActors=False
    bBlockActors=False

    PerkLevel=0
    MasteredWeaponCount=0

    KillDedupeWindow=0.03f      // 30ms — catch same-frame duplicates only
    LastCleanupTime=0.0f

    CurrentDisplayWeapon=""

    Name="Default__DKUpgrade_Perk_Artificer_Helper"
}
