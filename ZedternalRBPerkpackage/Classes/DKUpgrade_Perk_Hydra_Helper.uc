class DKUpgrade_Perk_Hydra_Helper extends Info
    transient;

// Kill tracking for Fury Mode (75 kills = Fury Mode trigger)
var byte KillsToDisplay;               // Current kills for UI display (0-75)
var int TotalKills;                    // Total kill count 
var const byte MaxKillsToDisplay;      // Maximum kills to display on UI (75)
var const float KillDisplayDuration;   // How long to show kill count after last kill

// Fury Mode state management (UPDATED: No infinite ammo, focus on damage + fire rate)
var bool bInFuryMode;                  // Whether player is currently in fury mode
var float FuryModeTimer;               // Remaining fury mode time
var const float FuryModeDuration;      // Duration of fury mode
var const name FuryModeTimerName;      // Timer name for fury mode

// Sound events for feedback
var const name HydraSoundRTPCName;
var const AkEvent KillTrackSound;      // Sound when tracking kills
var const AkEvent FuryModeStartSound;  // Sound when fury mode starts
var const AkEvent TwinStrikeSound;     // Sound when twin strike triggers

// Deduplication system (same as Reaper)
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
    bInFuryMode = false;
    FuryModeTimer = 0.0f;
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

// Called when any kill happens with deduplication
function TrackKill(optional KFPawn_Monster KilledMonster)
{
    local KFPlayerController KFPC;
    local KFPawn_Human OwnerPawn;
    local float CurrentTime;
    local KillRecord NewRecord;
    
    CurrentTime = Owner.WorldInfo.TimeSeconds;
    
    // Clean up old records periodically
    if (CurrentTime - LastCleanupTime > CleanupInterval)
    {
        CleanupOldKills(CurrentTime);
        LastCleanupTime = CurrentTime;
    }
    
    // Check for duplicate kills
    if (KilledMonster != None && IsRecentKill(KilledMonster, CurrentTime))
    {
        return; // Skip this - already counted
    }
    
    // Add this monster to recently killed list
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
    
    // Calculate kills to display (0-75 cycle)
    KillsToDisplay = TotalKills % MaxKillsToDisplay;
    if (KillsToDisplay == 0)
        KillsToDisplay = MaxKillsToDisplay; // Show 75 instead of 0
    
    // Check if we hit 75 kills - trigger Fury Mode!
    if (TotalKills > 0 && (TotalKills % MaxKillsToDisplay) == 0)
    {
        // FIXED: Only trigger if not already in fury mode (prevents multiple activations)
        if (!bInFuryMode)
        {
            // Trigger Fury Mode
            StartFuryMode();
            
            // Reset display counter and show the fury mode feedback
            KillsToDisplay = 0;
            UpdateKillDisplay(KillsToDisplay, True);
            
            // Get the owner pawn and then the controller for messaging
            OwnerPawn = KFPawn_Human(Owner);
            if (OwnerPawn != None)
            {
                KFPC = KFPlayerController(OwnerPawn.Controller);
                if (KFPC != None)
                {
                    // FIXED: Only send message once per fury mode activation
                    KFPC.ClientMessage("HYDRA BARRAGE ACTIVATED! " $ int(FuryModeDuration) $ " seconds of +100% fire rate + triple damage! (" $ TotalKills $ " total kills)");
                }
            }
        }
    }
    else
    {
        // Normal kill tracking - update UI
        UpdateKillDisplay(KillsToDisplay, False);
        
        // Set timer to hide counter after inactivity
        SetTimer(KillDisplayDuration, False, 'HideKillDisplay');
    }
}

// UPDATED: Start Fury Mode with damage + fire rate bonuses (no infinite ammo)
function StartFuryMode()
{
    local KFPlayerController KFPC;
    
    bInFuryMode = true;
    FuryModeTimer = FuryModeDuration;
    
    // Start the fury mode timer
    SetTimer(FuryModeDuration, False, FuryModeTimerName);
    
    // Play fury mode start sound
    KFPC = KFPlayerController(GetALocalPlayerController());
    if (KFPC != None)
    {
        KFPC.PlayRMEffect(FuryModeStartSound, HydraSoundRTPCName, 100);
    }
    
    // Show fury mode chain notification
    ShowFuryModeNotification();
}

// End Fury Mode
function EndFuryMode()
{
    local KFPlayerController KFPC;
    
    bInFuryMode = false;
    FuryModeTimer = 0.0f;
    
    // Clear the timer
    ClearTimer(FuryModeTimerName);
    
    // Notify player
    KFPC = KFPlayerController(GetALocalPlayerController());
    if (KFPC != None)
    {
        KFPC.ClientMessage("Hydra Barrage ended.", 'Event');
    }
}

// Timer function for fury mode end
function FuryModeEnd()
{
    EndFuryMode();
}

// UPDATED: Show fury mode chain notification with new bonuses
function ShowFuryModeNotification()
{
    local KFPlayerController KFPC;
    local DKHudWrapper HydraHUD;
    
    KFPC = KFPlayerController(GetALocalPlayerController());
    if (KFPC != None)
    {
        // Trigger the HUD chain notification for fury mode
        HydraHUD = class'DKHudWrapper'.static.GetReaperHUD(KFPC);
        if (HydraHUD != None)
        {
            HydraHUD.TriggerChainNotification("HYDRA BARRAGE!", "8 seconds of double fire rate + triple damage!", 4.0f);
        }
    }
}

// Show twin strike notification
function ShowTwinStrikeNotification()
{
    local KFPlayerController KFPC;
    
    KFPC = KFPlayerController(GetALocalPlayerController());
    if (KFPC != None)
    {
        // Play twin strike sound
        KFPC.PlayRMEffect(TwinStrikeSound, HydraSoundRTPCName, 50);
        
        // Show chat message
        KFPC.ClientMessage("TWIN STRIKE! Double damage!", 'Event');
    }
}

// Check if this monster was killed recently (same as Reaper)
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
        
        // Also check for monsters at the same location
        if (Monster != None)
        {
            LocationDiff = VSize(RecentKills[i].KillLocation - Monster.Location);
            TimeDiff = CurrentTime - RecentKills[i].KillTime;
            
            if (LocationDiff < 50.0f && TimeDiff <= KillDedupeWindow)
            {
                return true;
            }
        }
    }
    
    return false;
}

// Clean up only old kill records
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

function ResetKillCounter()
{
    // Reset kill tracking
    ClearTimer();
    ClearTimer(FuryModeTimerName);
    RecentKills.Length = 0;
    TotalKills = 0;
    KillsToDisplay = 0;
    bInFuryMode = false;
    FuryModeTimer = 0.0f;
    UpdateKillDisplay(KillsToDisplay, False);
}

// Main UI update function using HUD integration
reliable client function UpdateKillDisplay(byte KillCount, optional bool bFuryModeTriggered = False)
{
    local KFPlayerController KFPC;
    local AkEvent TempAkEvent;
    local DKHudWrapper HydraHUD;

    KFPC = KFPlayerController(GetALocalPlayerController());

    if (KFPC == None)
        return;

    // Try to get our custom HUD
    HydraHUD = class'DKHudWrapper'.static.GetReaperHUD(KFPC);
    if (HydraHUD != None)
    {
        // Use our custom HUD to display Hydra kills with icon
        HydraHUD.UpdateHydraKills(KillCount, MaxKillsToDisplay, bFuryModeTriggered);
    }
    else if (KFPC.MyGFxHUD != None)
    {
        // Fallback: Use standard rhythm counter if custom HUD not available
        KFPC.UpdateRhythmCounterWidget(KillCount, MaxKillsToDisplay);
    }

    // Play appropriate sound effects for feedback
    if (bFuryModeTriggered)
        TempAkEvent = FuryModeStartSound;
    else if (KillCount > 0)
        TempAkEvent = KillTrackSound;

    if (TempAkEvent != None)
        KFPC.PlayRMEffect(TempAkEvent, HydraSoundRTPCName, KillCount);
}

defaultproperties
{
    KillsToDisplay=0
    TotalKills=0
    MaxKillsToDisplay=75           // Track kills up to 75 for fury mode
    KillDisplayDuration=5.0f       // Show kill counter for 5 seconds after last kill
    FuryModeDuration=8.0f          // 8 seconds of fury mode
    FuryModeTimerName=FuryModeEnd  // No quotes for name properties
    
    // Deduplication settings (MINIMAL: Only catches true duplicates within same frame/tick)
    KillDedupeWindow=0.03f         // 30ms - minimal window to catch same-event duplicates only
    CleanupInterval=2.0f           // Clean up old records every 2 seconds
    LastCleanupTime=0.0f
    
    // Fury mode state (UPDATED: Focus on damage + fire rate bonuses)
    bInFuryMode=false
    FuryModeTimer=0.0f
    
    // Sound configuration
    HydraSoundRTPCName="Hydra_Kills"
    KillTrackSound=AkEvent'WW_UI_PlayerCharacter.Play_R_Method_Hit'      // Sound when tracking kills
    FuryModeStartSound=AkEvent'WW_UI_PlayerCharacter.Play_R_Method_Top'  // Sound for fury mode start
    TwinStrikeSound=AkEvent'WW_UI_PlayerCharacter.Play_R_Method_Hit'     // Sound for twin strikes
    
    Name="Default__DKUpgrade_Perk_Hydra_Helper"
}