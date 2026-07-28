class DKUpgrade_Perk_Hollow_Helper extends Info;

// ===================================================================
// HOLLOW HELPER — Per-Player Condition Tracker
//
// Tracks per-weapon condition progress through 5 sequential stages.
// Manages collateral kill detection (time-window based) and
// rapid kill detection (rolling window). Fires reliable client RPCs
// for HUD updates and unlock notifications.
//
// Follows Artificer/Gambit/Shapeshifter helper pattern exactly.
// ===================================================================

const NUM_CONDITIONS = 5;

var int PerkLevel;

// Behavior mod constants
const CHAIN_LIGHTNING_RADIUS = 500.0f;
const CHAIN_LIGHTNING_MAX_TARGETS = 3;
const CHAIN_LIGHTNING_DAMAGE_PCT = 0.25f;
const DETONATION_RADIUS = 500.0f;
const DETONATION_DAMAGE = 200;
const STUMBLE_RADIUS = 400.0f;
const STUMBLE_DAMAGE = 1;

// ===================================================================
// PER-WEAPON TRACKING
// ===================================================================

struct SHollowWeaponEntry
{
    var string NormName;
    var byte ActiveCondition;       // 0-4 = in progress, 5 = all complete
    var int CurrentProgress;        // Progress toward active condition target
    var byte bIsMelee;              // 1 = melee weapon, 0 = ranged (byte, no bool arrays)
};
var array<SHollowWeaponEntry> WeaponProgress;

// Weapons that have been fully unlocked (Hollow variant available)
// This array is replicated to client via RPCs for trader filtering
var array<string> UnlockedWeapons;

// ===================================================================
// COLLATERAL KILL TRACKING (per-weapon, time-window based)
// Only tracks for the most recent weapon — you can only fire one at a time
// ===================================================================

var string CollateralWeapon;        // NormName of weapon in current burst
var float BurstStartTime;           // When the current burst began
var int BurstKillCount;             // Kills in current burst window
var byte bBurstCounted;             // 1 = already counted one collateral event this burst

// ===================================================================
// RAPID KILL TRACKING (rolling window of recent kill timestamps)
// ===================================================================

struct SRapidKillRecord
{
    var string NormName;
    var float KillTime;
};
var array<SRapidKillRecord> RapidKillLog;

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

// Current weapon being tracked for HUD display
var string CurrentDisplayWeapon;
var byte bCurrentIsHollow;           // 1 = currently displaying a Hollow weapon

// Client-side cache of unlocked weapons (populated via RPCs)
// Used by DKGFxTraderContainer_Store for per-player filtering
var array<string> ClientUnlockCache;

// ===================================================================
// LEVEL 10: CALL OF THE VOID — Shatter Point System
// Each unlocked Hollow weapon gets a random HP threshold (20-40%).
// When a hit brings a zed below threshold, it dies instantly.
// Bosses: half effectiveness (a 30% roll becomes 15% vs bosses).
// ===================================================================

struct SShatterEntry
{
    var string NormName;
    var float Threshold;        // 0.20 to 0.40 for normal zeds
};
var array<SShatterEntry> ShatterThresholds;

// ===================================================================
// LEVEL 20: VOID MASTERY — Per-Unlock Scaling
// +1% damage to ALL Hollow weapons per unique weapon unlocked.
// Trial condition targets halved at Level 20.
// ===================================================================

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

    // Re-send all unlocks to client (handles respawn/reconnect)
    ResendAllUnlocks();

    // Start weapon watch — polls every 0.25s to detect weapon switches
    // and update HUD card immediately on equip (not just on kills)
    SetTimer(0.25f, true, 'TickWeaponWatch');
}

// ===================================================================
// KILL TRACKING — Entry point from DKUpgrade_Perk_Hollow.ModifyDamageGiven
// ===================================================================

function TrackWeaponKill(KFWeapon KFW, KFPawn_Monster KilledMonster, int HitZoneIdx, class<KFDamageType> DamageType)
{
    if (KFW == None)
        return;

    TrackWeaponKillByName(
        class'DKUpgrade_Perk_Hollow'.static.NormalizeWeaponName(string(KFW.Class.Name)),
        class'DKUpgrade_Perk_Hollow'.static.IsMeleeWeapon(KFW),
        KilledMonster, HitZoneIdx, DamageType);
}

// DK FIX: name-based core so weapon-originated indirect damage (afterburn /
// bleed DoT ticks, which carry no KFWeapon reference) can still credit
// kills. The perk resolves the name from the damage type's WeaponDef.
function TrackWeaponKillByName(string NormName, bool bIsMelee, KFPawn_Monster KilledMonster, int HitZoneIdx, class<KFDamageType> DamageType)
{
    local int EntryIdx;
    local float CurrentTime;
    local SKillRecord NewRecord;
    local bool bIsHeadshot, bIsLargeZed;
    local bool bIsCollateral, bIsRapid;

    if (NormName == "" || KilledMonster == None || Player == None)
        return;

    // Deduplication
    CurrentTime = Owner.WorldInfo.TimeSeconds;
    if (IsRecentKill(KilledMonster, CurrentTime))
        return;

    NewRecord.Monster = KilledMonster;
    NewRecord.KillTime = CurrentTime;
    RecentKills.AddItem(NewRecord);

    // Periodic cleanup
    if (CurrentTime - LastCleanupTime > 2.0f)
    {
        CleanupOldKills(CurrentTime);
        CleanupOldRapidKills(CurrentTime);
        LastCleanupTime = CurrentTime;
    }

    // Find or create weapon entry
    EntryIdx = FindOrCreateWeaponEntry(NormName, bIsMelee);

    // If already fully unlocked, nothing to track — clear HUD for this weapon
    if (WeaponProgress[EntryIdx].ActiveCondition >= NUM_CONDITIONS)
    {
        CurrentDisplayWeapon = NormName;
        ClientClearHollowHUD();
        return;
    }

    // === DETECT KILL PROPERTIES ===
    // DK FIX: also credit a headshot when the zed is already headless at the
    // moment of death -- covers decapitate-then-finish and decap bleed-out
    // kills, which never report HZI_Head on the killing damage event.
    bIsHeadshot = (HitZoneIdx == 0) || KilledMonster.IsHeadless(); // HZI_Head or decapitated
    bIsLargeZed = class'DKUpgrade_Perk_Hollow'.static.IsLargeZed(KilledMonster);
    bIsCollateral = DetectCollateralKill(NormName, CurrentTime);
    bIsRapid = DetectRapidKill(NormName, CurrentTime, bIsMelee);

    // === ADVANCE ACTIVE CONDITION ===
    AdvanceCondition(EntryIdx, bIsHeadshot, bIsLargeZed, bIsMelee, bIsCollateral, bIsRapid);

    // Update HUD
    CurrentDisplayWeapon = NormName;
    SendProgressUpdate(NormName, EntryIdx);
}

// ===================================================================
// CONDITION ADVANCEMENT
// ===================================================================

function AdvanceCondition(int EntryIdx, bool bHeadshot, bool bLargeZed, bool bMelee, bool bCollateral, bool bRapid)
{
    local byte ActiveCond;
    local int Target;
    local bool bCountsForCondition;
    local SHollowWeaponEntry TempEntry;

    ActiveCond = WeaponProgress[EntryIdx].ActiveCondition;
    if (ActiveCond >= NUM_CONDITIONS)
        return;

    // DK FIX: weapons that physically cannot score headshots (streaming /
    // pure-explosive) skip the Headshot Kills condition and start on
    // condition 1 (Total Kills). Also migrates entries already stuck on 0.
    if (ActiveCond == 0 && !class'DKUpgrade_Perk_Hollow'.static.CanHeadshot(WeaponProgress[EntryIdx].NormName))
    {
        WeaponProgress[EntryIdx].ActiveCondition = 1;
        WeaponProgress[EntryIdx].CurrentProgress = 0;
        ActiveCond = 1;
    }

    // Check if this kill counts for the active condition
    bCountsForCondition = False;
    switch (ActiveCond)
    {
        case 0: // Headshot Kills
            bCountsForCondition = bHeadshot;
            break;
        case 1: // Total Kills
            bCountsForCondition = True;
            break;
        case 2: // Collateral Kills
            bCountsForCondition = bCollateral;
            break;
        case 3: // Rapid Kills (ranged) or Melee Kills (melee)
            if (WeaponProgress[EntryIdx].bIsMelee == 1)
                bCountsForCondition = True; // All kills are melee for melee weapons
            else
                bCountsForCondition = bRapid;
            break;
        case 4: // Large Zed Kills
            bCountsForCondition = bLargeZed;
            break;
    }

    if (!bCountsForCondition)
        return;

    // Use struct copy for safe modification
    TempEntry = WeaponProgress[EntryIdx];
    TempEntry.CurrentProgress += 1;

    // Check if condition is complete
    Target = class'DKUpgrade_Perk_Hollow'.static.GetConditionTarget(
        ActiveCond, TempEntry.bIsMelee == 1);

    // Level 20 Void Mastery: halve all condition targets
    if (PerkLevel >= class'DKConfig_Capstone'.default.Capstone_Rank2Level)
        Target = Max(Target / 2, 1);

    if (TempEntry.CurrentProgress >= Target)
    {
        // Condition complete!
        `log("ZR Hollow: Condition" @ ActiveCond @ "COMPLETE for" @ TempEntry.NormName
            @ "(" $ TempEntry.CurrentProgress $ "/" $ Target $ ")");

        // Notify client of condition completion
        ClientShowConditionComplete(TempEntry.NormName, ActiveCond);
        PlayHollowSound('Hollow_Condition_Complete');

        // Advance to next condition
        TempEntry.ActiveCondition += 1;
        TempEntry.CurrentProgress = 0;

        // Check if ALL conditions are now complete
        if (TempEntry.ActiveCondition >= NUM_CONDITIONS)
        {
            WeaponProgress[EntryIdx] = TempEntry;
            TriggerHollowUnlock(TempEntry.NormName);
            return;
        }
    }

    WeaponProgress[EntryIdx] = TempEntry;
}

// ===================================================================
// COLLATERAL KILL DETECTION
// Time-window approach: kills within 0.05s = same shot
// Returns True once per burst when burst reaches 2+ kills
// ===================================================================

function bool DetectCollateralKill(string NormName, float CurrentTime)
{
    local float Window;

    Window = class'DKUpgrade_Perk_Hollow'.default.CollateralWindow;

    // Different weapon or outside window? Start new burst
    if (CollateralWeapon != NormName || (CurrentTime - BurstStartTime) > Window)
    {
        // Before resetting, no need to finalize — we count at the moment
        // the burst hits 2 kills, not after
        CollateralWeapon = NormName;
        BurstStartTime = CurrentTime;
        BurstKillCount = 1;
        bBurstCounted = 0;
        return False;
    }

    // Same weapon, within window
    BurstKillCount += 1;

    // First time burst reaches 2+ kills = 1 collateral event
    if (BurstKillCount >= 2 && bBurstCounted == 0)
    {
        bBurstCounted = 1;
        return True;
    }

    return False;
}

// ===================================================================
// RAPID KILL DETECTION
// Rolling window: if 2+ other kills from same weapon in last 4 seconds,
// this kill qualifies as a rapid kill.
// For melee weapons, this function is not used (all kills count).
// ===================================================================

function bool DetectRapidKill(string NormName, float CurrentTime, bool bIsMelee)
{
    local SRapidKillRecord NewRecord;
    local int i, Count;
    local float Window;
    local int Threshold;

    // Melee weapons don't use rapid kill — condition 3 is "melee kills"
    if (bIsMelee)
        return False;

    Window = class'DKUpgrade_Perk_Hollow'.default.RapidKillWindow;
    Threshold = class'DKUpgrade_Perk_Hollow'.default.RapidKillThreshold;

    // Add this kill to the log
    NewRecord.NormName = NormName;
    NewRecord.KillTime = CurrentTime;
    RapidKillLog.AddItem(NewRecord);

    // Count kills from the same weapon within the window (including this one)
    Count = 0;
    for (i = 0; i < RapidKillLog.Length; ++i)
    {
        if (RapidKillLog[i].NormName == NormName
            && (CurrentTime - RapidKillLog[i].KillTime) <= Window)
        {
            Count += 1;
        }
    }

    // This kill counts as rapid if there are Threshold+ kills in the window
    return (Count >= Threshold);
}

// ===================================================================
// HOLLOW UNLOCK — Makes the weapon available in trader for this player
// ===================================================================

function TriggerHollowUnlock(string NormName)
{
    local SShatterEntry NewShatter;

    `log("ZR Hollow: ALL CONDITIONS COMPLETE - HOLLOW UNLOCKED for" @ NormName);

    // Add to unlocked list
    UnlockedWeapons.AddItem(NormName);

    // Generate Call of the Void shatter threshold (Level 10+)
    if (PerkLevel >= class'DKConfig_Capstone'.default.Capstone_Rank1Level)
    {
        NewShatter.NormName = NormName;
        // Random threshold between 20% and 40%
        NewShatter.Threshold = 0.20f + (FRand() * 0.20f);
        ShatterThresholds.AddItem(NewShatter);

        `log("ZR Hollow: Call of the Void - " $ NormName @ "shatter threshold:" @ NewShatter.Threshold);

        // Send threshold to client for HUD display
        ClientReceiveShatterThreshold(NormName, NewShatter.Threshold);
    }

    // Notify client: HUD flash + sound + trader unlock
    ClientNotifyHollowUnlock(NormName);
    PlayHollowSound('Hollow_Weapon_Unlock');

    // Notification feed
    if (PlayerPC != None)
        class'DKMessageManager'.static.SendCritical(PlayerPC,
            "Hollow:" @ NormName @ "variant unlocked!");
}


// Check if a weapon has been unlocked for this player
function bool IsWeaponUnlocked(string NormName)
{
    local int i;

    for (i = 0; i < UnlockedWeapons.Length; ++i)
    {
        if (UnlockedWeapons[i] == NormName)
            return True;
    }

    return False;
}

/** Get the number of unique Hollow weapons unlocked.
 *  Used by Void Mastery (Level 20) for per-unlock damage scaling. */
function int GetUnlockCount()
{
    return UnlockedWeapons.Length;
}

/** Get the shatter threshold for a weapon.
 *  Returns 0.0 if weapon has no threshold (not unlocked, or perk < L10). */
function float GetShatterThreshold(string NormName)
{
    local int i;

    for (i = 0; i < ShatterThresholds.Length; ++i)
    {
        if (ShatterThresholds[i].NormName == NormName)
            return ShatterThresholds[i].Threshold;
    }

    return 0.0f;
}

// Re-send all unlocks + shatter thresholds on spawn/reconnect
function ResendAllUnlocks()
{
    local int i;

    for (i = 0; i < UnlockedWeapons.Length; ++i)
    {
        ClientReceiveUnlockSync(UnlockedWeapons[i]);
    }

    // Also resend shatter thresholds for HUD display
    for (i = 0; i < ShatterThresholds.Length; ++i)
    {
        ClientReceiveShatterThreshold(
            ShatterThresholds[i].NormName,
            ShatterThresholds[i].Threshold);
    }
}

// ===================================================================
// BEHAVIOR MOD SYSTEM — On-Kill Effects
//
// Called from DKUpgrade_Perk_Hollow.ModifyDamageGiven when a Hollow
// weapon gets a kill. Executes the weapon's assigned behavior mod.
//
// Chain Lightning: zap up to 3 nearby zeds for 25% of kill damage
// Detonation: deal 200 damage to all zeds in a 500 unit radius
// Stumble Engine: massive stumble on all nearby zeds on kill
//
// Uses Parasite Helper's TakeDamage + AllPawns pattern.
// No recursion risk: TakeDamage bypasses the WM perk pipeline.
// ===================================================================

/** Entry point for on-kill behavior mods.
 *  Called from DKUpgrade_Perk_Hollow.ModifyDamageGiven on Hollow weapon kills. */
function ApplyOnKillBehaviorMod(KFWeapon KFW, KFPawn_Monster KilledZed, int KillDamage)
{
    local string NormName, ModType;

    if (KFW == None || KilledZed == None || Player == None || PlayerPC == None)
        return;

    NormName = class'DKUpgrade_Perk_Hollow'.static.NormalizeWeaponName(string(KFW.Class.Name));
    ModType = class'DKHollowWeaponData'.static.GetBehaviorMod(NormName);

    if (ModType == "")
        return;

    if (ModType == "chainlightning")
        ApplyChainLightning(KilledZed, KillDamage);
    else if (ModType == "detonation")
        ApplyDetonation(KilledZed);
    else if (ModType == "stumbleengine")
        ApplyStumbleExplosion(KilledZed);
}

/** Chain Lightning: On kill, zap up to 3 nearby zeds for 25% of the killing blow. */
function ApplyChainLightning(KFPawn_Monster KilledZed, int KillDamage)
{
    local KFPawn_Monster KFPM;
    local int ChainDmg;
    local int HitCount;
    local float RadiusSq, DistSq;

    ChainDmg = Max(int(float(KillDamage) * CHAIN_LIGHTNING_DAMAGE_PCT), 10);
    RadiusSq = CHAIN_LIGHTNING_RADIUS * CHAIN_LIGHTNING_RADIUS;
    HitCount = 0;

    foreach Player.WorldInfo.AllPawns(class'KFPawn_Monster', KFPM)
    {
        if (HitCount >= CHAIN_LIGHTNING_MAX_TARGETS)
            break;

        if (KFPM == KilledZed || !KFPM.IsAliveAndWell())
            continue;

        DistSq = VSizeSq(KFPM.Location - KilledZed.Location);
        if (DistSq <= RadiusSq)
        {
            KFPM.TakeDamage(
                ChainDmg,
                PlayerPC,
                KFPM.Location,
                vect(0,0,0),
                class'DamageType'
            );
            HitCount++;
        }
    }
}

/** Detonation: On kill, deal fixed AoE damage to all zeds in radius. */
function ApplyDetonation(KFPawn_Monster KilledZed)
{
    local KFPawn_Monster KFPM;
    local float RadiusSq, DistSq;

    RadiusSq = DETONATION_RADIUS * DETONATION_RADIUS;

    foreach Player.WorldInfo.AllPawns(class'KFPawn_Monster', KFPM)
    {
        if (KFPM == KilledZed || !KFPM.IsAliveAndWell())
            continue;

        DistSq = VSizeSq(KFPM.Location - KilledZed.Location);
        if (DistSq <= RadiusSq)
        {
            KFPM.TakeDamage(
                DETONATION_DAMAGE,
                PlayerPC,
                KFPM.Location,
                vect(0,0,0),
                class'DamageType'
            );
        }
    }
}

/** Stumble Engine: On kill, deal tiny damage to nearby zeds to trigger stumble. */
function ApplyStumbleExplosion(KFPawn_Monster KilledZed)
{
    local KFPawn_Monster KFPM;
    local float RadiusSq, DistSq;

    RadiusSq = STUMBLE_RADIUS * STUMBLE_RADIUS;

    foreach Player.WorldInfo.AllPawns(class'KFPawn_Monster', KFPM)
    {
        if (KFPM == KilledZed || !KFPM.IsAliveAndWell())
            continue;

        DistSq = VSizeSq(KFPM.Location - KilledZed.Location);
        if (DistSq <= RadiusSq)
        {
            KFPM.TakeDamage(
                STUMBLE_DAMAGE,
                PlayerPC,
                KFPM.Location,
                Normal(KFPM.Location - KilledZed.Location) * 50000.0f,
                class'DamageType'
            );
        }
    }
}


// ===================================================================
// DEBUG / TESTING - Force complete trials
// ===================================================================

/** Force-complete all trials for a specific weapon and trigger unlock.
 *  Called from DKPlayerController exec command. */
function ForceCompleteWeapon(string NormName, bool bIsMelee)
{
    local int EntryIdx;

    if (IsWeaponUnlocked(NormName))
    {
        if (PlayerPC != None)
            PlayerPC.ClientMessage("Hollow:" @ NormName @ "already unlocked.");
        return;
    }

    EntryIdx = FindOrCreateWeaponEntry(NormName, bIsMelee);
    if (EntryIdx < 0 || EntryIdx >= WeaponProgress.Length)
        return;

    // Set all conditions complete
    WeaponProgress[EntryIdx].ActiveCondition = NUM_CONDITIONS;
    WeaponProgress[EntryIdx].CurrentProgress = 0;

    // Trigger the unlock flow (shatter threshold, RPCs, HUD, sound)
    TriggerHollowUnlock(NormName);

    // Force TickWeaponWatch to re-evaluate on next tick
    // Without this, it early-returns (NormName == CurrentDisplayWeapon)
    // and the HUD reverts to stale data after the notification expires
    CurrentDisplayWeapon = "";
    bCurrentIsHollow = 0;

    if (PlayerPC != None)
        PlayerPC.ClientMessage("Hollow: Force-completed all trials for" @ NormName);
}

/** Force-complete ALL weapons that have Hollow variants. */
function ForceCompleteAll()
{
    local int i, Count;
    local string NormName;
    local int EntryIdx;

    Count = 0;
    for (i = 0; i < class'DKHollowWeaponData'.static.GetHollowWeaponCount(); i++)
    {
        NormName = class'DKHollowWeaponData'.static.GetHollowNormName(i);
        if (NormName == "" || IsWeaponUnlocked(NormName))
            continue;

        EntryIdx = FindOrCreateWeaponEntry(NormName, false);
        if (EntryIdx >= 0 && EntryIdx < WeaponProgress.Length)
        {
            WeaponProgress[EntryIdx].ActiveCondition = NUM_CONDITIONS;
            WeaponProgress[EntryIdx].CurrentProgress = 0;
            TriggerHollowUnlock(NormName);
            Count++;
        }
    }

    // Force TickWeaponWatch to re-evaluate
    CurrentDisplayWeapon = "";
    bCurrentIsHollow = 0;

    if (PlayerPC != None)
        PlayerPC.ClientMessage("Hollow: Force-completed" @ Count @ "weapons.");
}

// ===================================================================
// WEAPON WATCH — Polls current weapon to update HUD on equip
// ===================================================================

/** Called every 0.25s. Detects weapon switches and updates HUD card.
 *  Shows card when equipping a weapon with an incomplete Hollow trial.
 *  Hides card when equipping a weapon without a Hollow variant or
 *  one that has already completed all trials. */
function TickWeaponWatch()
{
    local KFWeapon KFW;
    local string NormName;
    local bool bIsMelee;
    local int EntryIdx;
    local byte ActiveCond;
    local int Progress, Target;
    local byte bMeleeByte;
    local byte bIsHollowVariant;

    if (Player == None || Player.Health <= 0)
        return;

    // If Hollow weapon system is disabled, skip all trial tracking display
    if (!class'DKConfig_HollowWeapons'.static.IsEnabled())
    {
        if (CurrentDisplayWeapon != "")
        {
            CurrentDisplayWeapon = "";
            bCurrentIsHollow = 0;
            ClientClearHollowHUD();
        }
        return;
    }

    KFW = KFWeapon(Player.Weapon);
    if (KFW == None)
    {
        // No weapon equipped — clear display if we had one
        if (CurrentDisplayWeapon != "")
        {
            CurrentDisplayWeapon = "";
            bCurrentIsHollow = 0;
            ClientClearHollowHUD();
        }
        return;
    }

    NormName = class'DKUpgrade_Perk_Hollow'.static.NormalizeWeaponName(string(KFW.Class.Name));
    if (class'DKUpgrade_Perk_Hollow'.static.IsHollowWeapon(KFW))
        bIsHollowVariant = 1;
    else
        bIsHollowVariant = 0;

    // Same weapon AND same variant type as before - no change needed
    if (NormName == CurrentDisplayWeapon && bIsHollowVariant == bCurrentIsHollow)
        return;

    CurrentDisplayWeapon = NormName;
    bCurrentIsHollow = bIsHollowVariant;

    // Hollow weapons themselves don't show trial cards - only base weapons do.
    if (bIsHollowVariant == 1)
    {
        // Show shatter threshold if unlocked, otherwise clear
        if (PerkLevel >= class'DKConfig_Capstone'.default.Capstone_Rank1Level && GetShatterThreshold(NormName) > 0.f)
        {
            ClientUpdateHollowProgress(NormName, NUM_CONDITIONS,
                int(GetShatterThreshold(NormName) * 1000.0f), 0, 0);
        }
        else
        {
            ClientClearHollowHUD();
        }
        return;
    }

    // Check if this weapon has a Hollow variant at all
    if (!class'DKHollowWeaponData'.static.HasHollowVariant(NormName))
    {
        ClientClearHollowHUD();
        return;
    }

    // If weapon is already unlocked, no trial card — ever
    if (IsWeaponUnlocked(NormName))
    {
        ClientClearHollowHUD();
        return;
    }

    bIsMelee = class'DKUpgrade_Perk_Hollow'.static.IsMeleeWeapon(KFW);

    // Find or create the tracking entry for this weapon
    EntryIdx = FindOrCreateWeaponEntry(NormName, bIsMelee);
    if (EntryIdx < 0 || EntryIdx >= WeaponProgress.Length)
    {
        ClientClearHollowHUD();
        return;
    }

    ActiveCond = WeaponProgress[EntryIdx].ActiveCondition;
    bMeleeByte = WeaponProgress[EntryIdx].bIsMelee;

    // If all conditions are complete, show shatter threshold (L10+) or hide
    if (ActiveCond >= NUM_CONDITIONS)
    {
        if (PerkLevel >= class'DKConfig_Capstone'.default.Capstone_Rank1Level && GetShatterThreshold(NormName) > 0.f)
        {
            // Show "Call of the Void: Shatter XX%" on the card
            // Send with ActiveCondition=NUM_CONDITIONS so HUD knows it's complete
            // Encode threshold as Progress (int percentage * 100 for precision)
            ClientUpdateHollowProgress(NormName, NUM_CONDITIONS,
                int(GetShatterThreshold(NormName) * 1000.0f), 0, bMeleeByte);
        }
        else
        {
            ClientClearHollowHUD();
        }
        return;
    }

    // Active trial — send progress to HUD
    Progress = WeaponProgress[EntryIdx].CurrentProgress;
    Target = class'DKUpgrade_Perk_Hollow'.static.GetConditionTarget(ActiveCond, bMeleeByte == 1);
    if (PerkLevel >= class'DKConfig_Capstone'.default.Capstone_Rank2Level)
        Target = Max(Target / 2, 1);
    ClientUpdateHollowProgress(NormName, ActiveCond, Progress, Target, bMeleeByte);
}

// ===================================================================
// HUD PROGRESS UPDATE
// ===================================================================

function SendProgressUpdate(string NormName, int EntryIdx)
{
    local byte ActiveCond;
    local int Progress, Target;
    local byte bMelee;

    if (EntryIdx < 0 || EntryIdx >= WeaponProgress.Length)
        return;

    ActiveCond = WeaponProgress[EntryIdx].ActiveCondition;
    Progress = WeaponProgress[EntryIdx].CurrentProgress;
    bMelee = WeaponProgress[EntryIdx].bIsMelee;

    if (ActiveCond >= NUM_CONDITIONS)
    {
        // Fully complete
        ClientUpdateHollowProgress(NormName, NUM_CONDITIONS, 0, 0, bMelee);
    }
    else
    {
        Target = class'DKUpgrade_Perk_Hollow'.static.GetConditionTarget(ActiveCond, bMelee == 1);
        if (PerkLevel >= class'DKConfig_Capstone'.default.Capstone_Rank2Level)
            Target = Max(Target / 2, 1);
        ClientUpdateHollowProgress(NormName, ActiveCond, Progress, Target, bMelee);
    }
}

// ===================================================================
// RELIABLE CLIENT RPCs
// ===================================================================

/** Progress update — shows current condition + progress on HUD card */
reliable client function ClientUpdateHollowProgress(
    string InWeaponName,
    byte InActiveCondition,
    int InProgress,
    int InTarget,
    byte InIsMelee)
{
    local KFPlayerController KFPC;
    local DKHudWrapper HUD;

    KFPC = KFPlayerController(GetALocalPlayerController());
    if (KFPC == None || KFPC.myHUD == None)
        return;

    HUD = DKHudWrapper(KFPC.myHUD);
    if (HUD != None)
        HUD.UpdateHollowProgress(InWeaponName, InActiveCondition, InProgress, InTarget, InIsMelee);
}

/** Condition completion flash notification */
reliable client function ClientShowConditionComplete(string InWeaponName, byte InConditionIdx)
{
    local KFPlayerController KFPC;
    local DKHudWrapper HUD;

    KFPC = KFPlayerController(GetALocalPlayerController());
    if (KFPC == None || KFPC.myHUD == None)
        return;

    HUD = DKHudWrapper(KFPC.myHUD);
    if (HUD != None)
        HUD.ShowHollowConditionComplete(InWeaponName, InConditionIdx);
}

/** Full unlock notification — weapon is now available in trader */
reliable client function ClientNotifyHollowUnlock(string InWeaponName)
{
    local KFPlayerController KFPC;
    local DKHudWrapper HUD;

    KFPC = KFPlayerController(GetALocalPlayerController());
    if (KFPC == None || KFPC.myHUD == None)
        return;

    HUD = DKHudWrapper(KFPC.myHUD);
    if (HUD != None)
        HUD.ShowHollowWeaponUnlock(InWeaponName);

    // Add to client-side unlock cache for trader filtering
    AddToClientUnlockCache(InWeaponName);
}

/** Sync unlock state on respawn/reconnect (no HUD flash, just cache update) */
reliable client function ClientReceiveUnlockSync(string InWeaponName)
{
    AddToClientUnlockCache(InWeaponName);
}

/** Clear HUD display */
reliable client function ClientClearHollowHUD()
{
    local KFPlayerController KFPC;
    local DKHudWrapper HUD;

    KFPC = KFPlayerController(GetALocalPlayerController());
    if (KFPC == None || KFPC.myHUD == None)
        return;

    HUD = DKHudWrapper(KFPC.myHUD);
    if (HUD != None)
        HUD.ClearHollowDisplay();
}

/** Receive shatter threshold from server for HUD display.
 *  Called on unlock and on respawn/reconnect. */
reliable client function ClientReceiveShatterThreshold(string InWeaponName, float InThreshold)
{
    local KFPlayerController KFPC;
    local DKHudWrapper HUD;

    KFPC = KFPlayerController(GetALocalPlayerController());
    if (KFPC == None || KFPC.myHUD == None)
        return;

    HUD = DKHudWrapper(KFPC.myHUD);
    if (HUD != None)
        HUD.SetHollowShatterThreshold(InWeaponName, InThreshold);
}

// ===================================================================
// CLIENT-SIDE UNLOCK CACHE
// Used by DKGFxTraderContainer_Store for per-player filtering
// ===================================================================

simulated function AddToClientUnlockCache(string NormName)
{
    local int i;

    // Check for duplicates
    for (i = 0; i < ClientUnlockCache.Length; ++i)
    {
        if (ClientUnlockCache[i] == NormName)
            return;
    }

    ClientUnlockCache.AddItem(NormName);
}

// Called by trader store filter to check if a Hollow weapon is unlocked
simulated function bool IsWeaponUnlockedClient(string NormName)
{
    local int i;

    for (i = 0; i < ClientUnlockCache.Length; ++i)
    {
        if (ClientUnlockCache[i] == NormName)
            return True;
    }

    return False;
}

// ===================================================================
// SOUND PLAYBACK
// ===================================================================

function PlayHollowSound(name SoundID)
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

function int FindWeaponEntry(string NormName)
{
    local int i;

    for (i = 0; i < WeaponProgress.Length; ++i)
    {
        if (WeaponProgress[i].NormName == NormName)
            return i;
    }

    return INDEX_NONE;
}

function int FindOrCreateWeaponEntry(string NormName, bool bIsMelee)
{
    local int i;
    local SHollowWeaponEntry NewEntry;

    for (i = 0; i < WeaponProgress.Length; ++i)
    {
        if (WeaponProgress[i].NormName == NormName)
            return i;
    }

    NewEntry.NormName = NormName;
    NewEntry.ActiveCondition = 0;
    NewEntry.CurrentProgress = 0;
    if (bIsMelee)
        NewEntry.bIsMelee = 1;
    else
        NewEntry.bIsMelee = 0;
    WeaponProgress.AddItem(NewEntry);
    return WeaponProgress.Length - 1;
}

// ===================================================================
// KILL DEDUPLICATION
// ===================================================================

function bool IsRecentKill(KFPawn_Monster Monster, float CurrentTime)
{
    local int i;

    for (i = 0; i < RecentKills.Length; ++i)
    {
        if (RecentKills[i].Monster == Monster
            && (CurrentTime - RecentKills[i].KillTime) <= KillDedupeWindow)
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

function CleanupOldRapidKills(float CurrentTime)
{
    local int i;
    local float Window;
    local array<SRapidKillRecord> Cleaned;

    Window = class'DKUpgrade_Perk_Hollow'.default.RapidKillWindow + 1.0f;

    for (i = 0; i < RapidKillLog.Length; ++i)
    {
        if ((CurrentTime - RapidKillLog[i].KillTime) <= Window)
            Cleaned.AddItem(RapidKillLog[i]);
    }

    RapidKillLog = Cleaned;
}

defaultproperties
{
    RemoteRole=ROLE_SimulatedProxy
    bAlwaysRelevant=False
    bOnlyRelevantToOwner=True
    bHidden=True
    bCollideActors=False
    bBlockActors=False

    PerkLevel=0

    KillDedupeWindow=0.03f
    LastCleanupTime=0.0f

    CollateralWeapon=""
    BurstStartTime=0.0f
    BurstKillCount=0
    bBurstCounted=0

    CurrentDisplayWeapon=""

    Name="Default__DKUpgrade_Perk_Hollow_Helper"
}
