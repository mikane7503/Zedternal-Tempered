class DKUpgrade_Perk_Cryophilite_Helper extends Info
    transient;

// Kill tracking for Level 10 and Level 20 milestones
var byte HeadshotKillsToDisplay;       // Current headshot kills for UI display (0-10)
var byte TotalKillsToDisplay;          // Current total kills for UI display (0-20)
var int TotalHeadshotKills;            // Total headshot kill count (for reference)
var int TotalKills;                    // Total kill count (for reference)

// NEW: Progress toward next milestone (resets after each milestone)
var byte HeadshotProgressToNextMilestone; // Headshots toward next Icicle Arrow (0-10)
var byte TotalProgressToNextMilestone;     // Kills toward next Absolute Zero (0-20)

var bool bIcicleArrowReady;            // Level 10 ready flag
var bool bAbsoluteZeroReady;           // Level 20 ready flag

// Milestone thresholds are config-driven:
// [ZedternalRBPerkpackage.DKUpgrade_Perk_Cryophilite]
// HeadshotKillsRequired / TotalKillsRequired
var const float KillDisplayDuration;   // How long to show kill count after last kill

// Sound events for feedback
var const name CryoSoundRTPCName;
var const AkEvent KillTrackSound;      // Sound when tracking kills
var const AkEvent IcicleArrowSound;    // Sound when Icicle Arrow is ready
var const AkEvent AbsoluteZeroSound;   // Sound when Absolute Zero is ready

// IMPROVED DEDUPLICATION SYSTEM (copied from Reaper)
struct KillRecord
{
    var KFPawn_Monster Monster;
    var float KillTime;
    var vector KillLocation;
};

var array<KillRecord> RecentKills;
var const float KillDedupeWindow;      // Short window for deduplication
var const float CleanupInterval;       // How often to clean old records
var float LastCleanupTime;             // When we last cleaned up

function PostBeginPlay()
{
    super.PostBeginPlay();

    if (Owner == None)
        Destroy();
    
    LastCleanupTime = Owner.WorldInfo.TimeSeconds;
}

function Timer()
{
    if (Owner == None)
    {
        Destroy();
        return;
    }

    // Hide kill counters after period of inactivity
    if (HeadshotKillsToDisplay > 0 || TotalKillsToDisplay > 0)
    {
        HeadshotKillsToDisplay = 0;
        TotalKillsToDisplay = 0;
        UpdateKillDisplay(HeadshotKillsToDisplay, TotalKillsToDisplay, False, False, 1);
    }
}

// IMPROVED: Called when any kill happens with better deduplication
function TrackKill(bool bIsHeadshot, optional KFPawn_Monster KilledMonster, optional bool bAbilityWasConsumed = false, optional int CurrentUpgradeLevel = 1)
{
    local float CurrentTime;
    local KillRecord NewRecord;
    local int i;
    local bool bIsDuplicate;
    
    CurrentTime = Owner.WorldInfo.TimeSeconds;
    
    // Clean up old records periodically
    if (CurrentTime - LastCleanupTime > CleanupInterval)
    {
        CleanupOldKills(CurrentTime);
        LastCleanupTime = CurrentTime;
    }
    
    // Check for duplicate kills in recent window
    if (KilledMonster != None)
    {
        bIsDuplicate = False;
        for (i = 0; i < RecentKills.Length; i++)
        {
            if (RecentKills[i].Monster == KilledMonster && 
                (CurrentTime - RecentKills[i].KillTime) <= KillDedupeWindow)
            {
                bIsDuplicate = True;
                break;
            }
        }
        
        if (bIsDuplicate)
            return;
        
        // Record this kill
        NewRecord.Monster = KilledMonster;
        NewRecord.KillTime = CurrentTime;
        NewRecord.KillLocation = KilledMonster.Location;
        RecentKills.AddItem(NewRecord);
    }
    
    // If an ability was consumed this kill, don't count toward next milestone
    if (bAbilityWasConsumed)
    {
        // Just update the HUD display without incrementing counters
        UpdateKillDisplay(HeadshotKillsToDisplay, TotalKillsToDisplay, bIcicleArrowReady, bAbsoluteZeroReady, CurrentUpgradeLevel);
        return;
    }
    
    // Always increment total counters for reference
    TotalKills++;
    if (bIsHeadshot)
    {
        TotalHeadshotKills++;
    }
    
    // Track progress toward next milestones (only if not already ready AND if level is high enough)
    if (!bAbsoluteZeroReady && CurrentUpgradeLevel >= class'DKConfig_Capstone'.default.Capstone_Rank2Level)
    {
        TotalProgressToNextMilestone++;
        TotalKillsToDisplay = Min(TotalProgressToNextMilestone, class'DKUpgrade_Perk_Cryophilite'.default.TotalKillsRequired);
    }
    
    if (bIsHeadshot && !bIcicleArrowReady && CurrentUpgradeLevel >= class'DKConfig_Capstone'.default.Capstone_Rank1Level)
    {
        HeadshotProgressToNextMilestone++;
        HeadshotKillsToDisplay = Min(HeadshotProgressToNextMilestone, class'DKUpgrade_Perk_Cryophilite'.default.HeadshotKillsRequired);
    }
    
    // Check for milestone readiness
    CheckMilestoneReadiness(CurrentUpgradeLevel);
    
    // Update HUD display (pass upgrade level for visibility checks)
    UpdateKillDisplay(HeadshotKillsToDisplay, TotalKillsToDisplay, bIcicleArrowReady, bAbsoluteZeroReady, CurrentUpgradeLevel);
    
    // Reset timer for display duration
    ClearTimer();
    SetTimer(KillDisplayDuration, False);
}

function CheckMilestoneReadiness(optional int CurrentUpgradeLevel = 1)
{
    local bool bWasIcicleReady, bWasAbsoluteReady;
    
    bWasIcicleReady = bIcicleArrowReady;
    bWasAbsoluteReady = bAbsoluteZeroReady;
    
    // Check Level 10: Icicle Arrow (when progress reaches 10 AND level is 10+)
    if (!bIcicleArrowReady && HeadshotProgressToNextMilestone >= class'DKUpgrade_Perk_Cryophilite'.default.HeadshotKillsRequired && CurrentUpgradeLevel >= class'DKConfig_Capstone'.default.Capstone_Rank1Level)
    {
        bIcicleArrowReady = True;
        if (!bWasIcicleReady)
        {
            PlayMilestoneSound(IcicleArrowSound);
        }
    }
    
    // Check Level 20: Absolute Zero (when progress reaches 20 AND level is 20)
    if (!bAbsoluteZeroReady && TotalProgressToNextMilestone >= class'DKUpgrade_Perk_Cryophilite'.default.TotalKillsRequired && CurrentUpgradeLevel >= class'DKConfig_Capstone'.default.Capstone_Rank2Level)
    {
        bAbsoluteZeroReady = True;
        if (!bWasAbsoluteReady)
        {
            PlayMilestoneSound(AbsoluteZeroSound);
        }
    }
}

function ConsumeIcicleArrow()
{
    bIcicleArrowReady = False;
    // Reset progress toward next milestone
    HeadshotProgressToNextMilestone = 0;
    HeadshotKillsToDisplay = 0;
    UpdateKillDisplay(HeadshotKillsToDisplay, TotalKillsToDisplay, bIcicleArrowReady, bAbsoluteZeroReady, 1); // Use default level parameter
}

function ConsumeAbsoluteZero()
{
    bAbsoluteZeroReady = False;
    // Reset progress toward next milestone
    TotalProgressToNextMilestone = 0;
    TotalKillsToDisplay = 0;
    UpdateKillDisplay(HeadshotKillsToDisplay, TotalKillsToDisplay, bIcicleArrowReady, bAbsoluteZeroReady, 1); // Use default level parameter
}

// Notification functions
function ShowIcicleArrowNotification()
{
    local KFPlayerController KFPC;
    
    KFPC = KFPlayerController(GetALocalPlayerController());
    if (KFPC != None)
    {
        KFPC.ClientMessage("ICICLE ARROW FIRED! (+500% Damage)", 'CriticalEvent');
    }
}

function ShowAbsoluteZeroNotification()
{
    local KFPlayerController KFPC;
    
    KFPC = KFPlayerController(GetALocalPlayerController());
    if (KFPC != None)
    {
        KFPC.ClientMessage("ABSOLUTE ZERO! Freeze explosion triggered!", 'CriticalEvent');
    }
}

function PlayMilestoneSound(AkEvent SoundToPlay)
{
    local KFPlayerController KFPC;
    
    KFPC = KFPlayerController(GetALocalPlayerController());
    if (KFPC != None && SoundToPlay != None)
    {
        KFPC.PlayRMEffect(SoundToPlay, CryoSoundRTPCName, 1.0f);
    }
}

// Cleanup old kill records to prevent memory bloat
function CleanupOldKills(float CurrentTime)
{
    local array<KillRecord> NewRecentKills;
    local int i;
    
    for (i = 0; i < RecentKills.Length; i++)
    {
        if ((CurrentTime - RecentKills[i].KillTime) <= KillDedupeWindow * 3.0f)
        {
            NewRecentKills.AddItem(RecentKills[i]);
        }
    }
    
    RecentKills = NewRecentKills;
}

// FIXED: Main UI update function using HUD integration - now takes optional CurrentUpgradeLevel parameter
reliable client function UpdateKillDisplay(byte HeadshotKills, byte TotalKillsDisplay, bool bIcicleReady, bool bAbsoluteReady, optional int CurrentUpgradeLevel = 1)
{
    local KFPlayerController KFPC;
    local AkEvent TempAkEvent;
    local DKHudWrapper CryoHUD;

    KFPC = KFPlayerController(GetALocalPlayerController());
    if (KFPC == None)
        return;

    // Try to get our custom HUD
    CryoHUD = class'DKHudWrapper'.static.GetReaperHUD(KFPC);
    if (CryoHUD != None)
    {
        // Use our custom HUD to display Cryophilite progress - pass the upgrade level
        CryoHUD.UpdateCryophiliteTrackers(HeadshotKills, TotalKillsDisplay, bIcicleReady, bAbsoluteReady, CurrentUpgradeLevel);
    }
    else if (KFPC.MyGFxHUD != None)
    {
        // Fallback: Use standard rhythm counter if custom HUD not available
        KFPC.UpdateRhythmCounterWidget(TotalKillsDisplay, class'DKUpgrade_Perk_Cryophilite'.default.TotalKillsRequired);
    }

    // Play appropriate sound effects for feedback
    if (bIcicleReady || bAbsoluteReady)
        TempAkEvent = IcicleArrowSound;
    else if (HeadshotKills > 0 || TotalKills > 0)
        TempAkEvent = KillTrackSound;

    if (TempAkEvent != None)
        KFPC.PlayRMEffect(TempAkEvent, CryoSoundRTPCName, TotalKills);
}

defaultproperties
{
    HeadshotKillsToDisplay=0
    TotalKillsToDisplay=0
    TotalHeadshotKills=0
    TotalKills=0
    HeadshotProgressToNextMilestone=0
    TotalProgressToNextMilestone=0
    bIcicleArrowReady=false
    bAbsoluteZeroReady=false
    
    KillDisplayDuration=5.0f       // Show kill counters for 5 seconds after last kill
    
    // IMPROVED DEDUPLICATION SETTINGS
    KillDedupeWindow=0.1f          // Very short window - just prevent same-frame double counting
    CleanupInterval=2.0f           // Clean up old records every 2 seconds
    LastCleanupTime=0.0f           // Initialize cleanup timer
    
    // Sound configuration
    CryoSoundRTPCName="Cryophilite_Progress"
    KillTrackSound=AkEvent'WW_UI_PlayerCharacter.Play_R_Method_Hit'      // Sound when tracking kills
    IcicleArrowSound=AkEvent'WW_UI_PlayerCharacter.Play_R_Method_Top'    // Sound for Icicle Arrow ready
    AbsoluteZeroSound=AkEvent'WW_UI_PlayerCharacter.Play_R_Method_Top'   // Sound for Absolute Zero ready
    
    Name="Default__DKUpgrade_Perk_Cryophilite_Helper"
}