class ZTUpgrade_Perk_ForgeWarden_Helper extends Info transient;

// Fire/Explosive kill tracking for milestone system (25 kills = +1 grenade restored)
var byte KillsToDisplay;               // Current kills for UI display (0-25)
var int TotalFireExplosiveKills;       // Total fire/explosive kill count
var int TotalGrenadesRestored;         // Total grenades restored from milestones
var const byte MaxKillsToDisplay;      // Maximum kills to display on UI (25)
var const float KillDisplayDuration;   // How long to show kill count after last kill

// Player reference for grenade restoration
var KFPawn_Human Player;
var KFInventoryManager KFIM;

// Sound events for feedback
var const name ForgeWardenSoundRTPCName;
var const AkEvent KillTrackSound;         // Sound when tracking kills
var const AkEvent MilestoneCompleteSound; // Sound when completing milestone
var const AkEvent BurningGroundSound;     // Sound when creating burning ground

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
    
    // Set up player references for grenade restoration
    Player = KFPawn_Human(Owner);
    if (Player == None || Player.Health <= 0 || Player.InvManager == None)
        Destroy();
    else
        KFIM = KFInventoryManager(Player.InvManager);
    
    LastCleanupTime = Owner.WorldInfo.TimeSeconds;
}

function Timer()
{
    if (Player == None || Player.Health <= 0 || KFIM == None)
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

// Called when a fire/explosive kill happens
function TrackFireExplosiveKill(optional KFPawn_Monster KilledMonster)
{
    local KFPlayerController KFPC;
    local float CurrentTime;
    local KillRecord NewRecord;
    
    CurrentTime = Owner.WorldInfo.TimeSeconds;
    
    // Clean up old records periodically
    if (CurrentTime - LastCleanupTime > CleanupInterval)
    {
        CleanupOldKills(CurrentTime);
        LastCleanupTime = CurrentTime;
    }
    
    // Check for duplicates
    if (KilledMonster != None && IsRecentKill(KilledMonster, CurrentTime))
    {
        return; // Skip this - already counted this specific monster recently
    }
    
    // Add this monster to recently killed list
    if (KilledMonster != None)
    {
        NewRecord.Monster = KilledMonster;
        NewRecord.KillTime = CurrentTime;
        NewRecord.KillLocation = KilledMonster.Location;
        RecentKills.AddItem(NewRecord);
    }
    
    ClearTimer('HideKillDisplay');
    
    // Increase total kill count
    TotalFireExplosiveKills++;
    
    // Calculate kills to display (0-25 cycle)
    KillsToDisplay = TotalFireExplosiveKills % MaxKillsToDisplay;
    if (KillsToDisplay == 0)
        KillsToDisplay = MaxKillsToDisplay; // Show 25 instead of 0
    
    // Check if we hit milestone - restore a grenade!
    if (TotalFireExplosiveKills > 0 && (TotalFireExplosiveKills % MaxKillsToDisplay) == 0)
    {
        // Check if player and inventory are still valid
        if (Player == None || Player.Health <= 0 || KFIM == None)
        {
            Destroy();
            return;
        }
        
        // Restore a grenade to the player
        KFIM.AddGrenades(1);
        TotalGrenadesRestored++;
        
        // Get the player controller for feedback
        KFPC = KFPlayerController(Player.Controller);
        if (KFPC != None)
        {
            // Show completion message
            KFPC.ClientMessage("FORGE MASTERY MILESTONE! +1 Grenade Restored! (" $ TotalGrenadesRestored $ " total restored, " $ TotalFireExplosiveKills $ " kills)");
        }
        
        // Reset display counter and show the milestone feedback
        KillsToDisplay = 0;
        UpdateKillDisplay(KillsToDisplay, True);
        
        // Play milestone complete sound
        PlayMilestoneCompleteSound();
    }
    else
    {
        // Normal kill tracking - update UI
        UpdateKillDisplay(KillsToDisplay, False);
        
        // Set timer to hide counter after inactivity
        SetTimer(KillDisplayDuration, False, 'HideKillDisplay');
    }
}

// Check if this monster was killed recently (same deduplication logic as Reaper)
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
                return true;
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

// Clean up old kill records
function CleanupOldKills(float CurrentTime)
{
    local int i;
    local array<KillRecord> NewRecentKills;
    
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

// Create burning ground patch at specified location (Level 20 Molten Core ability)
function CreateBurningGround(vector SpawnLocation)
{
    local ZUTBurningGroundPatch BurningPatch;
    local KFPlayerController KFPC;
    
    if (Owner == None || Owner.WorldInfo == None) return;
    
    // Spawn the burning ground patch
    BurningPatch = Owner.Spawn(class'ZUTBurningGroundPatch', Owner,, SpawnLocation);
    if (BurningPatch != None)
    {
        // Set the patch owner for damage attribution
        BurningPatch.SetOwner(Owner);
        
        // Play burning ground creation sound
        KFPC = KFPlayerController(GetALocalPlayerController());
        if (KFPC != None)
        {
            KFPC.PlayRMEffect(BurningGroundSound, ForgeWardenSoundRTPCName, 255);
        }
    }
}

// Get summary of current milestone progress
function string GetMilestoneSummary()
{
    local string Summary;
    local int ProgressToNext;
    
    ProgressToNext = MaxKillsToDisplay - (TotalFireExplosiveKills % MaxKillsToDisplay);
    if (ProgressToNext == MaxKillsToDisplay) ProgressToNext = 0;
    
    Summary = TotalGrenadesRestored $ " grenades restored (" $ TotalFireExplosiveKills $ " total kills)";
    if (ProgressToNext > 0)
    {
        Summary = Summary $ ", " $ ProgressToNext $ " kills until next grenade";
    }
    
    return Summary;
}

function ResetMilestoneCounter()
{
    ClearTimer();
    RecentKills.Length = 0;
    TotalFireExplosiveKills = 0;
    TotalGrenadesRestored = 0;
    KillsToDisplay = 0;
    UpdateKillDisplay(KillsToDisplay, False);
}

// Play sound when completing milestone
function PlayMilestoneCompleteSound()
{
    local KFPlayerController KFPC;
    
    KFPC = KFPlayerController(GetALocalPlayerController());
    if (KFPC != None)
    {
        KFPC.PlayRMEffect(MilestoneCompleteSound, ForgeWardenSoundRTPCName, MaxKillsToDisplay);
    }
}

// Main UI update function using ZTHudWrapper
reliable client function UpdateKillDisplay(byte KillCount, optional bool bMilestoneComplete = False)
{
    local KFPlayerController KFPC;
    local AkEvent TempAkEvent;
    local ZTHudWrapper ForgeHUD;

    KFPC = KFPlayerController(GetALocalPlayerController());

    if (KFPC == None)
        return;

    // Try to get our custom HUD
    ForgeHUD = class'ZTHudWrapper'.static.GetReaperHUD(KFPC);
    if (ForgeHUD != None)
    {
        // Use our custom HUD to display ForgeWarden kills with icon
        ForgeHUD.UpdateForgeWardenKills(KillCount, MaxKillsToDisplay, bMilestoneComplete);
    }
    else if (KFPC.MyGFxHUD != None)
    {
        // Fallback: Use standard rhythm counter if custom HUD not available
        KFPC.UpdateRhythmCounterWidget(KillCount, MaxKillsToDisplay);
    }

    // Play appropriate sound effects for feedback
    if (bMilestoneComplete)
        TempAkEvent = MilestoneCompleteSound;
    else if (KillCount > 0)
        TempAkEvent = KillTrackSound;

    if (TempAkEvent != None)
        KFPC.PlayRMEffect(TempAkEvent, ForgeWardenSoundRTPCName, KillCount);
}

defaultproperties
{
    KillsToDisplay=0
    TotalFireExplosiveKills=0
    TotalGrenadesRestored=0
    MaxKillsToDisplay=25           // Track kills up to 25 for grenade milestone
    KillDisplayDuration=5.0f       // Show kill counter for 5 seconds after last kill
    
    // UPDATED DEDUPLICATION SETTINGS - Standardized to 30ms
    KillDedupeWindow=0.03f         // 30ms - minimal window to catch same-event duplicates only
    CleanupInterval=2.0f           // Clean up old records every 2 seconds
    LastCleanupTime=0.0f           // Initialize cleanup timer
    
    // Sound configuration
    ForgeWardenSoundRTPCName="ForgeWarden_Kills"
    KillTrackSound=AkEvent'WW_UI_PlayerCharacter.Play_R_Method_Hit'      // Sound when tracking kills
    MilestoneCompleteSound=AkEvent'WW_UI_PlayerCharacter.Play_R_Method_Top' // Sound for milestone complete
    BurningGroundSound=AkEvent'WW_UI_PlayerCharacter.Play_R_Method_Hit'     // Simple sound for burning ground
    
    Name="Default__ZTUpgrade_Perk_ForgeWarden_Helper"
}