class DKUpgrade_Perk_Medusa_Helper extends Info
    transient;

// Toxic Metamorphosis tracking (2500 poison damage = 1 scale)
var int PoisonDamageToDisplay;          // Current poison damage for UI display (0-2500)
var int TotalPoisonDamage;              // Total poison damage dealt
var const int DamagePerScale;           // Poison damage needed per scale (2500)
var const int MaxScales;                // Maximum scales before transformation (6)
var const float DisplayDuration;        // How long to show tracker after poison damage

// Serpent Scales progression
var int CurrentScales;                  // Current number of scales (0-6)
var bool bFullGorgonAchieved;          // Whether Full Gorgon transformation has been achieved
var float PermanentPoisonBonus;         // Permanent poison DoT bonus from Full Gorgon (+100%)

// Sound events for feedback
var const name MedusaSoundRTPCName;
var const AkEvent PoisonTrackSound;     // Sound when tracking poison damage
var const AkEvent ScaleGainSound;       // Sound when gaining a scale
var const AkEvent FullGorgonSound;      // Sound when achieving Full Gorgon

// ENHANCED DEDUPLICATION SYSTEM for poison damage tracking
struct PoisonRecord
{
    var KFPawn_Monster Monster;
    var float PoisonTime;
    var vector PoisonLocation;
    var int PoisonDamage;
    var int TickCount;                  // NEW: Track how many ticks from this monster we've seen
};

var array<PoisonRecord> RecentPoison;
var const float PoisonDedupeWindow;     // Window for deduplication
var const float CleanupInterval;        // How often to clean old records
var float LastCleanupTime;              // When we last cleaned up
var const int MaxTicksPerMonster;       // NEW: Maximum ticks we expect per poisoned monster (5 ticks for 5 seconds)

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

    // Hide poison tracker after period of inactivity
    if (PoisonDamageToDisplay > 0)
    {
        PoisonDamageToDisplay = 0;
        UpdatePoisonDisplay(PoisonDamageToDisplay, CurrentScales, False);
    }
}

// FIXED: Enhanced poison damage tracking with per-tick validation
function TrackActualPoisonDamage(int ActualPoisonDamage, optional KFPawn_Monster PoisonedMonster)
{
    local float CurrentTime;
    local PoisonRecord NewRecord;
    local int OldScales, ExistingRecordIndex;
    local bool bShouldTrack;
    
    CurrentTime = Owner.WorldInfo.TimeSeconds;
    
    // Clean up old records periodically
    if (CurrentTime - LastCleanupTime > CleanupInterval)
    {
        CleanupOldPoison(CurrentTime);
        LastCleanupTime = CurrentTime;
    }
    
    bShouldTrack = true;
    
    // Enhanced validation: Check if this is a legitimate poison tick
    if (PoisonedMonster != None)
    {
        ExistingRecordIndex = FindPoisonRecord(PoisonedMonster);
        
        if (ExistingRecordIndex != INDEX_NONE)
        {
            // We've seen this monster before - check tick count
            if (RecentPoison[ExistingRecordIndex].TickCount >= MaxTicksPerMonster)
            {
                // This monster has already delivered all expected ticks
                bShouldTrack = false;
            }
            else
            {
                // Valid tick from known monster
                RecentPoison[ExistingRecordIndex].TickCount++;
                RecentPoison[ExistingRecordIndex].PoisonTime = CurrentTime;
                RecentPoison[ExistingRecordIndex].PoisonDamage += ActualPoisonDamage;
            }
        }
        else
        {
            // First tick from new monster
            NewRecord.Monster = PoisonedMonster;
            NewRecord.PoisonTime = CurrentTime;
            NewRecord.PoisonLocation = PoisonedMonster.Location;
            NewRecord.PoisonDamage = ActualPoisonDamage;
            NewRecord.TickCount = 1;
            RecentPoison.AddItem(NewRecord);
        }
    }
    
    // FIXED: Only track damage if it's a valid tick (should be 2 damage per tick)
    if (bShouldTrack && ActualPoisonDamage > 0)
    {
        // Validate the damage amount - should be around 2 per tick
        if (ActualPoisonDamage > 10)
        {
            // Suspicious - might be total damage instead of per-tick
            `log("Medusa Helper: Suspicious poison damage amount:" @ ActualPoisonDamage @ "- might be total damage instead of per-tick");
            // Scale it down to expected per-tick amount
            ActualPoisonDamage = 2;
        }
        
        ClearTimer('HidePoisonDisplay'); // Clear the hide display timer
        
        // Store old scale count to check for progression
        OldScales = CurrentScales;
        
        // Increase total poison damage with validated per-tick damage
        TotalPoisonDamage += ActualPoisonDamage;
        
        // Calculate current progress toward next scale (0-2500 cycle)
        PoisonDamageToDisplay = TotalPoisonDamage % DamagePerScale;
        if (PoisonDamageToDisplay == 0 && TotalPoisonDamage > 0)
            PoisonDamageToDisplay = DamagePerScale; // Show 2500 instead of 0
        
        // Calculate current scale count
        if (!bFullGorgonAchieved)
        {
            CurrentScales = Min(TotalPoisonDamage / DamagePerScale, MaxScales);
            
            // Check if we gained a new scale
            if (CurrentScales > OldScales && CurrentScales < MaxScales)
            {
                // Gained a new scale
                ShowScaleGainNotification(CurrentScales);
                PlayScaleGainSound();
            }
            
            // Check if we achieved Full Gorgon (6 scales)
            if (CurrentScales >= MaxScales && !bFullGorgonAchieved)
            {
                TriggerFullGorgonTransformation();
            }
        }
        
        // Update UI display
        UpdatePoisonDisplay(PoisonDamageToDisplay, CurrentScales, False);
        
        // Set timer to hide tracker after inactivity
        SetTimer(DisplayDuration, False, 'HidePoisonDisplay');
    }
}

// Find existing poison record for a monster
function int FindPoisonRecord(KFPawn_Monster Monster)
{
    local int i;
    
    for (i = 0; i < RecentPoison.Length; i++)
    {
        if (RecentPoison[i].Monster == Monster)
        {
            return i;
        }
    }
    
    return INDEX_NONE;
}

// Legacy function - kept for compatibility but now just calls the actual tracking
function TrackPoisonDamage(int PoisonDamage, optional KFPawn_Monster PoisonedMonster)
{
    // For now, just call the actual tracking function
    // This maintains compatibility with any existing code that calls this
    TrackActualPoisonDamage(PoisonDamage, PoisonedMonster);
}

// Check if this monster had poison tracked recently
function bool IsRecentPoison(KFPawn_Monster Monster, float CurrentTime)
{
    local int i;
    local float TimeDiff;
    
    for (i = 0; i < RecentPoison.Length; i++)
    {
        // Check if it's the same monster reference
        if (RecentPoison[i].Monster == Monster)
        {
            TimeDiff = CurrentTime - RecentPoison[i].PoisonTime;
            if (TimeDiff <= PoisonDedupeWindow)
            {
                return true; // Same monster poisoned very recently
            }
        }
    }
    
    return false;
}

// Enhanced cleanup - remove expired poison records
function CleanupOldPoison(float CurrentTime)
{
    local int i;
    local array<PoisonRecord> NewRecentPoison;
    
    // Keep only recent poison records (within the last 6 seconds to account for full DoT duration)
    for (i = 0; i < RecentPoison.Length; i++)
    {
        if ((CurrentTime - RecentPoison[i].PoisonTime) <= 6.0f)
        {
            NewRecentPoison.AddItem(RecentPoison[i]);
        }
    }
    
    RecentPoison = NewRecentPoison;
}

// Timer function to hide poison display
function HidePoisonDisplay()
{
    if (PoisonDamageToDisplay > 0)
    {
        PoisonDamageToDisplay = 0;
        UpdatePoisonDisplay(PoisonDamageToDisplay, CurrentScales, False);
    }
}

// Show scale gain notification
function ShowScaleGainNotification(int ScaleCount)
{
    local KFPlayerController KFPC;
    local DKHudWrapper MedusaHUD;
    
    // Get the player controller
    KFPC = KFPlayerController(GetALocalPlayerController());
    if (KFPC != None)
    {
        // Show chat message for scale gain
        KFPC.ClientMessage("SERPENT SCALE GAINED! (" $ ScaleCount $ "/" $ MaxScales $ ") +3% Damage Resistance, +2% Speed", 'CriticalEvent');
        
        // Trigger the HUD chain notification
        MedusaHUD = class'DKHudWrapper'.static.GetReaperHUD(KFPC);
        if (MedusaHUD != None)
        {
            MedusaHUD.TriggerChainNotification("SERPENT SCALE!", "Growing stronger... +" $ (ScaleCount * 3) $ "% resistance, +" $ (ScaleCount * 2) $ "% speed", 4.0f);
        }
    }
}

// Trigger Full Gorgon transformation
function TriggerFullGorgonTransformation()
{
    local KFPlayerController KFPC;
    local KFPawn_Human OwnerPawn;
    local DKHudWrapper MedusaHUD;
    
    // Set transformation flags
    bFullGorgonAchieved = true;
    PermanentPoisonBonus = 1.0f; // +100% poison DoT damage (doubles damage)
    CurrentScales = 0; // Reset scales
    
    // Get the owner pawn and then the controller
    OwnerPawn = KFPawn_Human(Owner);
    if (OwnerPawn != None)
    {
        KFPC = KFPlayerController(OwnerPawn.Controller);
        if (KFPC != None)
        {
            // Show transformation message
            KFPC.ClientMessage("*** FULL GORGON TRANSFORMATION ACHIEVED! ***", 'CriticalEvent');
            KFPC.ClientMessage("Serpent scales shed - Gained permanent +100% poison damage!", 'CriticalEvent');
            
            // Show dramatic HUD notification
            MedusaHUD = class'DKHudWrapper'.static.GetReaperHUD(KFPC);
            if (MedusaHUD != None)
            {
                MedusaHUD.TriggerChainNotification("FULL GORGON!", "Transformation complete! Double poison damage!", 6.0f);
            }
        }
    }
    
    // Reset display counter and show the transformation feedback
    PoisonDamageToDisplay = 0;
    UpdatePoisonDisplay(PoisonDamageToDisplay, CurrentScales, True);
    
    // Play special transformation sound
    PlayFullGorgonSound();
}

// Get current status summary
function string GetVenomStatus()
{
    local string StatusText;
    
    if (bFullGorgonAchieved)
    {
        StatusText = "FULL GORGON - Permanent +100% poison damage. Poison Progress: " $ PoisonDamageToDisplay $ "/" $ DamagePerScale;
    }
    else
    {
        StatusText = "Serpent Scales: " $ CurrentScales $ "/" $ MaxScales $ " (+" $ (CurrentScales * 3) $ "% resistance, +" $ (CurrentScales * 2) $ "% speed). Progress: " $ PoisonDamageToDisplay $ "/" $ DamagePerScale;
    }
    
    return StatusText;
}

// Play scale gain sound
function PlayScaleGainSound()
{
    local KFPlayerController KFPC;
    
    KFPC = KFPlayerController(GetALocalPlayerController());
    if (KFPC != None)
    {
        KFPC.PlayRMEffect(ScaleGainSound, MedusaSoundRTPCName, CurrentScales);
    }
}

// Play Full Gorgon transformation sound
function PlayFullGorgonSound()
{
    local KFPlayerController KFPC;
    
    KFPC = KFPlayerController(GetALocalPlayerController());
    if (KFPC != None)
    {
        // Play a special "transformation" sound effect
        KFPC.PlayRMEffect(FullGorgonSound, MedusaSoundRTPCName, MaxScales);
    }
}

function ResetVenomCounter()
{
    // Reset poison tracking
    ClearTimer();
    RecentPoison.Length = 0;
    TotalPoisonDamage = 0;
    PoisonDamageToDisplay = 0;
    CurrentScales = 0;
    bFullGorgonAchieved = false;
    PermanentPoisonBonus = 0.0f;
    UpdatePoisonDisplay(PoisonDamageToDisplay, CurrentScales, False);
}

// Main UI update function for poison tracking
reliable client function UpdatePoisonDisplay(int PoisonProgress, int Scales, optional bool bTransformationComplete = False)
{
    local KFPlayerController KFPC;
    local AkEvent TempAkEvent;
    local DKHudWrapper MedusaHUD;

    KFPC = KFPlayerController(GetALocalPlayerController());

    if (KFPC == None)
        return;

    // Try to get our custom HUD
    MedusaHUD = class'DKHudWrapper'.static.GetReaperHUD(KFPC);
    if (MedusaHUD != None)
    {
        // Use our custom HUD to display Medusa progress with icon
        MedusaHUD.UpdateMedusaVenom(PoisonProgress, DamagePerScale, Scales, MaxScales, bFullGorgonAchieved, bTransformationComplete);
    }
    else if (KFPC.MyGFxHUD != None)
    {
        // Fallback: Use standard rhythm counter if custom HUD not available
        KFPC.UpdateRhythmCounterWidget(PoisonProgress, DamagePerScale);
    }

    // Feedback sound only on the Full Gorgon milestone. The per-tick
    // PoisonTrackSound used to fire on EVERY poison tick from EVERY zed, which
    // is constant audio spam once several poison weapons are in play (reported
    // "poison sound too loud"). Scale-gain and transformation still have their
    // own one-shot sounds via PlayScaleGainSound / PlayFullGorgonSound.
    if (bTransformationComplete)
        TempAkEvent = FullGorgonSound;

    if (TempAkEvent != None)
        KFPC.PlayRMEffect(TempAkEvent, MedusaSoundRTPCName, PoisonProgress);
}

defaultproperties
{
    PoisonDamageToDisplay=0
    TotalPoisonDamage=0
    DamagePerScale=2500            // 2500 poison damage per scale
    MaxScales=6                    // 6 scales maximum before transformation
    DisplayDuration=8.0f           // Show poison tracker for 8 seconds after last poison damage
    
    // Serpent Scales progression
    CurrentScales=0
    bFullGorgonAchieved=false
    PermanentPoisonBonus=0.0f
    
    // ENHANCED DEDUPLICATION SETTINGS
    PoisonDedupeWindow=0.03f       // 30ms - minimal window to catch same-event duplicates only
    CleanupInterval=3.0f           // Clean up old records every 3 seconds
    LastCleanupTime=0.0f           // Initialize cleanup timer
    MaxTicksPerMonster=5           // NEW: Maximum expected ticks per poisoned monster (5 seconds * 1 tick/sec)
    
    // Sound configuration
    MedusaSoundRTPCName="Medusa_Venom"
    PoisonTrackSound=AkEvent'WW_UI_PlayerCharacter.Play_R_Method_Hit'      // Sound when tracking poison
    ScaleGainSound=AkEvent'WW_UI_PlayerCharacter.Play_R_Method_Top'        // Sound for scale gain
    FullGorgonSound=AkEvent'WW_UI_PlayerCharacter.Play_R_Method_Top'       // Sound for Full Gorgon (reuse scale sound)
    
    Name="Default__DKUpgrade_Perk_Medusa_Helper"
}