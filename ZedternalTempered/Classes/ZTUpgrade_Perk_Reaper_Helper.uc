class ZTUpgrade_Perk_Reaper_Helper extends Info transient;

// Soul harvesting tracking (100 kills = 100 dosh)
var byte KillsToDisplay;               // Current kills for UI display (0-100)
var int TotalKills;                    // Total kill count 
var const byte MaxKillsToDisplay;      // Maximum kills to display on UI (100)
var const int DoshReward;              // Dosh reward per 100 kills
var const float KillDisplayDuration;   // How long to show kill count after last kill

// Sound events for feedback
var const name ReaperSoundRTPCName;
var const AkEvent KillTrackSound;      // Sound when tracking kills
var const AkEvent HarvestCompleteSound; // Sound when completing 100 kills
var const AkEvent InstantKillSound;    // Sound when instant kill triggers

// IMPROVED DEDUPLICATION SYSTEM
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

    // Hide kill counter after period of inactivity
    if (KillsToDisplay > 0)
    {
        KillsToDisplay = 0;
        UpdateKillDisplay(KillsToDisplay, False);
    }
}

// IMPROVED: Called when any kill happens with better deduplication
function TrackKill(optional KFPawn_Monster KilledMonster)
{
    local KFPlayerController KFPC;
    local KFPlayerReplicationInfo KFPRI;
    local KFPawn_Human OwnerPawn;
    local float CurrentTime;
    local KillRecord NewRecord;
    
    CurrentTime = Owner.WorldInfo.TimeSeconds;
    
    // Clean up old records periodically instead of on every kill
    if (CurrentTime - LastCleanupTime > CleanupInterval)
    {
        CleanupOldKills(CurrentTime);
        LastCleanupTime = CurrentTime;
    }
    
    // If we have monster info, check if we already counted this specific monster recently
    if (KilledMonster != None && IsRecentKill(KilledMonster, CurrentTime))
    {
        return; // Skip this - already counted this specific monster recently
    }
    
    // Add this monster to recently killed list with timestamp
    if (KilledMonster != None)
    {
        NewRecord.Monster = KilledMonster;
        NewRecord.KillTime = CurrentTime;
        NewRecord.KillLocation = KilledMonster.Location;
        RecentKills.AddItem(NewRecord);
    }
    
    ClearTimer('HideKillDisplay'); // Clear the hide display timer
    
    // Increase total kill count
    TotalKills++;
    
    // Calculate kills to display (0-100 cycle)
    KillsToDisplay = TotalKills % MaxKillsToDisplay;
    if (KillsToDisplay == 0)
        KillsToDisplay = MaxKillsToDisplay; // Show 100 instead of 0
    
    // Check if we hit 100 kills - reward player with dosh!
    if (TotalKills > 0 && (TotalKills % MaxKillsToDisplay) == 0)
    {
        // Get the owner pawn and then the controller
        OwnerPawn = KFPawn_Human(Owner);
        if (OwnerPawn != None)
        {
            KFPC = KFPlayerController(OwnerPawn.Controller);
            if (KFPC != None)
            {
                KFPRI = KFPlayerReplicationInfo(KFPC.PlayerReplicationInfo);
                if (KFPRI != None)
                {
                    // Give 100 dosh as reward
                    KFPRI.AddDosh(DoshReward);
                    
                    // Show completion message
                    KFPC.ClientMessage("SOUL HARVEST COMPLETE! +" $ DoshReward $ " Dosh! (" $ TotalKills $ " total kills)");
                }
            }
        }
        
        // Reset display counter and show the reward feedback
        KillsToDisplay = 0;
        UpdateKillDisplay(KillsToDisplay, True);
        
        // Play special harvest complete sound
        PlayHarvestCompleteSound();
    }
    else
    {
        // Normal kill tracking - update UI
        UpdateKillDisplay(KillsToDisplay, False);
        
        // Set timer to hide counter after inactivity
        SetTimer(KillDisplayDuration, False, 'HideKillDisplay');
    }
}

// IMPROVED: Check if this monster was killed recently
function bool IsRecentKill(KFPawn_Monster Monster, float CurrentTime)
{
    local int i;
    local float TimeDiff;
    local float LocationDiff;
    
    for (i = 0; i < RecentKills.Length; i++)
    {
        // Check if it's the same monster reference
        if (RecentKills[i].Monster == Monster)
        {
            TimeDiff = CurrentTime - RecentKills[i].KillTime;
            if (TimeDiff <= KillDedupeWindow)
            {
                return true; // Same monster killed very recently
            }
        }
        
        // Also check for monsters at the same location (in case references get recycled)
        if (Monster != None)
        {
            LocationDiff = VSize(RecentKills[i].KillLocation - Monster.Location);
            TimeDiff = CurrentTime - RecentKills[i].KillTime;
            
            // If killed at nearly same location within dedup window, probably same monster
            if (LocationDiff < 50.0f && TimeDiff <= KillDedupeWindow)
            {
                return true;
            }
        }
    }
    
    return false;
}

// IMPROVED: Clean up only old kill records
function CleanupOldKills(float CurrentTime)
{
    local int i;
    local array<KillRecord> NewRecentKills;
    
    // Keep only recent kills (within the last second)
    for (i = 0; i < RecentKills.Length; i++)
    {
        if ((CurrentTime - RecentKills[i].KillTime) <= 1.0f)
        {
            NewRecentKills.AddItem(RecentKills[i]);
        }
    }
    
    RecentKills = NewRecentKills;
}

// Timer function to hide kill display
function HideKillDisplay()
{
    if (KillsToDisplay > 0)
    {
        KillsToDisplay = 0;
        UpdateKillDisplay(KillsToDisplay, False);
    }
}

// Function to show instant kill notification without affecting kill count
function ShowInstantKillNotification()
{
    local KFPlayerController KFPC;
    local ZTHudWrapper ReaperHUD;
    
    // Get the player controller
    KFPC = KFPlayerController(GetALocalPlayerController());
    if (KFPC != None)
    {
        // Play special instant kill sound
        KFPC.PlayRMEffect(InstantKillSound, ReaperSoundRTPCName, 255);
        
        // Show chat message for dramatic effect
        KFPC.ClientMessage("DEATH'S TOUCH: Instant kill!", 'CriticalEvent');
        
        // Trigger the HUD instant kill notification
        ReaperHUD = class'ZTHudWrapper'.static.GetReaperHUD(KFPC);
        if (ReaperHUD != None)
        {
            ReaperHUD.TriggerInstantKillNotification();
        }
    }
}

// Function to track instant kills with special notification (keeping for backwards compatibility)
function TrackInstantKill()
{
    // Just show the notification - the normal TrackKill() will handle the count
    ShowInstantKillNotification();
}

function DecreaseSoulCounter()
{
    // No longer needed - kills don't fade
}

function ResetSoulCounter()
{
    // Reset kill tracking
    ClearTimer();
    RecentKills.Length = 0;
    TotalKills = 0;
    KillsToDisplay = 0;
    UpdateKillDisplay(KillsToDisplay, False);
}

// Play special sound when completing 100 kills
function PlayHarvestCompleteSound()
{
    local KFPlayerController KFPC;
    
    KFPC = KFPlayerController(GetALocalPlayerController());
    if (KFPC != None)
    {
        // Play a special "completed" sound effect
        KFPC.PlayRMEffect(HarvestCompleteSound, ReaperSoundRTPCName, MaxKillsToDisplay);
    }
}

// CANVAS APPROACH: Main UI update function using simple canvas drawing
reliable client function UpdateKillDisplay(byte KillCount, optional bool bHarvestComplete = False)
{
    local KFPlayerController KFPC;
    local AkEvent TempAkEvent;
    local ZTHudWrapper ReaperHUD;

    KFPC = KFPlayerController(GetALocalPlayerController());

    if (KFPC == None)
        return;

    // Try to get our custom HUD
    ReaperHUD = class'ZTHudWrapper'.static.GetReaperHUD(KFPC);
    if (ReaperHUD != None)
    {
        // Use our custom HUD to display Reaper kills with icon
        ReaperHUD.UpdateReaperKills(KillCount, MaxKillsToDisplay, bHarvestComplete);
    }
    else if (KFPC.MyGFxHUD != None)
    {
        // Fallback: Use standard rhythm counter if custom HUD not available
        KFPC.UpdateRhythmCounterWidget(KillCount, MaxKillsToDisplay);
    }

    // Play appropriate sound effects for feedback
    if (bHarvestComplete)
        TempAkEvent = HarvestCompleteSound;
    else if (KillCount > 0)
        TempAkEvent = KillTrackSound;

    if (TempAkEvent != None)
        KFPC.PlayRMEffect(TempAkEvent, ReaperSoundRTPCName, KillCount);
}

defaultproperties
{
    KillsToDisplay=0
    TotalKills=0
    MaxKillsToDisplay=100          // Track kills up to 100
    DoshReward=100                 // Give 100 dosh per harvest
    KillDisplayDuration=5.0f       // Show kill counter for 5 seconds after last kill
    
    // IMPROVED DEDUPLICATION SETTINGS
    KillDedupeWindow=0.1f          // Very short window - just prevent same-frame double counting
    CleanupInterval=2.0f           // Clean up old records every 2 seconds
    LastCleanupTime=0.0f           // Initialize cleanup timer
    
    // Sound configuration
    ReaperSoundRTPCName="Reaper_Kills"
    KillTrackSound=AkEvent'WW_UI_PlayerCharacter.Play_R_Method_Hit'      // Sound when tracking kills
    HarvestCompleteSound=AkEvent'WW_UI_PlayerCharacter.Play_R_Method_Top' // Sound for 100 kills complete
    InstantKillSound=AkEvent'WW_UI_PlayerCharacter.Play_R_Method_Top'     // Sound for instant kills (reuse harvest sound)
    
    Name="Default__ZTUpgrade_Perk_Reaper_Helper"
}