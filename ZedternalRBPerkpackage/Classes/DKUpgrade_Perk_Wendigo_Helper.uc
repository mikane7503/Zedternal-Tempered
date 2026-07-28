class DKUpgrade_Perk_Wendigo_Helper extends Info
    transient;

// Stalking tracking variables
var float LastFireTime;                    // When player last fired a weapon
var float LastDamageTime;                  // When player last took damage
var bool bFirstShotReady;                  // Whether perfect ambush shot is ready
var bool bApexStalkerActive;               // Whether apex stalker bonus is currently active
var int LastKnownHealth;                   // For tracking damage taken
var int CurrentPerkLevel;                  // Track current perk level for HUD display

// Display tracking for HUD
var float StalkTimeToDisplay;              // Current stalking time for UI display
var float DamageTimeToDisplay;             // Current time since damage for UI display
var bool bShowStalkerDisplay;              // Whether to show the tracker on HUD


// Constants for timing
var const float UpdateInterval;            // How often to update display (0.5 seconds)
var const float DisplayDuration;           // How long to show tracker after action (8 seconds)

function PostBeginPlay()
{
    local KFPawn_Human OwnerPawn;
    
    super.PostBeginPlay();

    if (Owner == None)
        Destroy();
    
    // Initialize timing
    LastFireTime = Owner.WorldInfo.TimeSeconds;
    LastDamageTime = Owner.WorldInfo.TimeSeconds;
    bFirstShotReady = true;
    bApexStalkerActive = false;
    bShowStalkerDisplay = false;
    CurrentPerkLevel = 0; // Initialize perk level
    
    // Initialize health tracking
    OwnerPawn = KFPawn_Human(Owner);
    if (OwnerPawn != None)
    {
        LastKnownHealth = OwnerPawn.Health;
    }
    
    // Start update timer
    SetTimer(UpdateInterval, true, 'UpdateStalkerTracking');
}

function Timer()
{
    if (Owner == None)
    {
        Destroy();
        return;
    }

    // Timer is handled by UpdateStalkerTracking function
}

// Function to update perk level (called from main perk class)
function SetPerkLevel(int NewLevel)
{
    CurrentPerkLevel = NewLevel;
}

// Regular update function to refresh HUD display
function UpdateStalkerTracking()
{
    local float CurrentTime, TimeSinceLastFire, TimeSinceLastDamage;
    local bool bShowTracker;
    local KFPawn_Human OwnerPawn;
    local int CurrentHealth;
    
    if (Owner == None) return;
    
    CurrentTime = Owner.WorldInfo.TimeSeconds;
    TimeSinceLastFire = CurrentTime - LastFireTime;
    TimeSinceLastDamage = CurrentTime - LastDamageTime;
    
    // Check for health changes to detect damage taken
    OwnerPawn = KFPawn_Human(Owner);
    if (OwnerPawn != None)
    {
        CurrentHealth = OwnerPawn.Health;
        if (CurrentHealth < LastKnownHealth)
        {
            // Player took damage - update last damage time and break apex stalker
            LastDamageTime = CurrentTime;
            bApexStalkerActive = false;
            TimeSinceLastDamage = 0.0f; // Reset since we just took damage
        }
        LastKnownHealth = CurrentHealth;
    }
    
    // Update perfect ambush readiness (only if level 10+)
    if (CurrentPerkLevel >= class'DKConfig_Capstone'.default.Capstone_Rank1Level && TimeSinceLastFire >= 10.0f && !bFirstShotReady)
    {
        bFirstShotReady = true;
    }
    
    // Check if we should show the tracker (show if stalking or recently active)
    bShowTracker = (TimeSinceLastFire >= 3.0f || TimeSinceLastDamage >= 25.0f || bApexStalkerActive);
    
    if (bShowTracker)
    {
        StalkTimeToDisplay = TimeSinceLastFire;
        DamageTimeToDisplay = TimeSinceLastDamage;
        bShowStalkerDisplay = true;
        
        // Update HUD display
        UpdateStalkerDisplay(TimeSinceLastFire, TimeSinceLastDamage, false, bApexStalkerActive);
    }
    else if (bShowStalkerDisplay)
    {
        // Hide tracker when not relevant
        bShowStalkerDisplay = false;
        UpdateStalkerDisplay(0.0f, 0.0f, false, false);
    }
}

// Function to show perfect ambush notification
// DK FIX: was using GetALocalPlayerController() (always None on dedicated
// servers) -- now routes through the owning controller's replicated channel.
function ShowPerfectAmbushNotification()
{
    local DKPlayerController DKPC;
    
    DKPC = GetOwnerController();
    if (DKPC == None) return;
    
    class'DKMessageManager'.static.SendCritical(DKPC, "PERFECT AMBUSH: Prey eliminated!");
    DKPC.ClientWendigoChainNotification("PERFECT AMBUSH!", "Predator's patience rewarded", 3.0f);
}

// Function to show apex stalker activation
// DK FIX: same GetALocalPlayerController() problem as above.
function ShowApexStalkerNotification()
{
    local DKPlayerController DKPC;
    
    DKPC = GetOwnerController();
    if (DKPC == None) return;
    
    class'DKMessageManager'.static.SendCritical(DKPC, "APEX STALKER: Ultimate predator awakened!");
    DKPC.ClientWendigoChainNotification("APEX STALKER!", "Untouchable hunter emerges", 4.0f);
}

// Resolve the owning player's DKPlayerController (server-side).
function DKPlayerController GetOwnerController()
{
    local Pawn P;

    P = Pawn(Owner);
    if (P != None)
        return DKPlayerController(P.Controller);

    return None;
}

// Computes tracker states server-side and ships them to the owning client
// via DKPlayerController.ClientUpdateWendigoTrackers.
// DK FIX: this was a 'reliable client' function on this non-replicated Info
// (RemoteRole=ROLE_None) -- such RPCs are silently dropped on dedicated
// servers, so no Wendigo tracker or capstone indicator ever reached the
// player. It is now a plain server-side function that routes through the
// owning DKPlayerController's replicated channel. The capstone level gates
// below read the server's DKConfig_Capstone INI values, so the trackers
// follow whatever levels the admin configured.
function UpdateStalkerDisplay(float TimeSinceLastFire, float TimeSinceLastDamage, optional bool bPerfectAmbushTriggered = false, optional bool bApexStalkerState = false)
{
    local DKPlayerController DKPC;
    local byte AmbushState, ApexState;

    DKPC = GetOwnerController();
    if (DKPC == None) return;

    // Perfect ambush state (level-gated by the configured Rank 1 level)
    AmbushState = 0;
    if (CurrentPerkLevel >= class'DKConfig_Capstone'.default.Capstone_Rank1Level)
    {
        if (bPerfectAmbushTriggered)
            AmbushState = 2;
        else if (bFirstShotReady && TimeSinceLastFire >= 10.0f)
            AmbushState = 1;
    }

    // Apex stalker state (level-gated by the configured Rank 2 level)
    ApexState = 0;
    if (CurrentPerkLevel >= class'DKConfig_Capstone'.default.Capstone_Rank2Level)
    {
        if (bApexStalkerState)
            ApexState = 2;
        else if (TimeSinceLastDamage >= 25.0f)
            ApexState = 1;
    }

    DKPC.ClientUpdateWendigoTrackers(int(TimeSinceLastFire), (TimeSinceLastFire >= 5.0f), AmbushState, int(FMin(TimeSinceLastDamage, 30.0f)), ApexState);
}

// Get status summary for toggle panel
function string GetStalkingSummary()
{
    local float CurrentTime, TimeSinceLastFire, TimeSinceLastDamage;
    local string StatusText;
    
    if (Owner == None) return "Wendigo inactive";
    
    CurrentTime = Owner.WorldInfo.TimeSeconds;
    TimeSinceLastFire = CurrentTime - LastFireTime;
    TimeSinceLastDamage = CurrentTime - LastDamageTime;
    
    if (bApexStalkerActive && CurrentPerkLevel >= class'DKConfig_Capstone'.default.Capstone_Rank2Level)
    {
        StatusText = "APEX STALKER ACTIVE (+150% damage)";
    }
    else if (TimeSinceLastDamage >= 25.0f && CurrentPerkLevel >= class'DKConfig_Capstone'.default.Capstone_Rank2Level)
    {
        StatusText = "Approaching Apex (" $ int(FMin(TimeSinceLastDamage, 30.0f)) $ "/30s)";
    }
    else if (bFirstShotReady && TimeSinceLastFire >= 10.0f && CurrentPerkLevel >= class'DKConfig_Capstone'.default.Capstone_Rank1Level)
    {
        StatusText = "Perfect Ambush Ready (" $ int(TimeSinceLastFire) $ "s)";
    }
    else if (TimeSinceLastFire >= 5.0f)
    {
        StatusText = "Stalking Bonus Active (" $ int(TimeSinceLastFire) $ "s)";
    }
    else
    {
        StatusText = "Patience required (" $ int(5.0f - TimeSinceLastFire) $ "s)";
    }
    
    return StatusText;
}

function ResetStalkerTracking()
{
    // Reset all tracking
    ClearTimer();
    LastFireTime = Owner.WorldInfo.TimeSeconds;
    LastDamageTime = Owner.WorldInfo.TimeSeconds;
    bFirstShotReady = true;
    bApexStalkerActive = false;
    bShowStalkerDisplay = false;
    
    // Hide display
    UpdateStalkerDisplay(0.0f, 0.0f, false, false);
    
    // Restart timer
    SetTimer(UpdateInterval, true, 'UpdateStalkerTracking');
}

defaultproperties
{
    LastFireTime=0.0f
    LastDamageTime=0.0f
    bFirstShotReady=true
    bApexStalkerActive=false
    bShowStalkerDisplay=false
    CurrentPerkLevel=0
    
    // Update and display settings
    UpdateInterval=0.5f            // Update display every 0.5 seconds
    DisplayDuration=8.0f           // Show tracker for 8 seconds after action
    
    
    Name="Default__DKUpgrade_Perk_Wendigo_Helper"
}