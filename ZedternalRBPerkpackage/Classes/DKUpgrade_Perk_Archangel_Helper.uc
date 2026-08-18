class DKUpgrade_Perk_Archangel_Helper extends Info
    transient;

// Divine service tracking (healing performance and ally support)
var int HealingToDisplay;              // Current healing progress for UI display (0-500)
var int TotalHealingDone;              // Total healing points provided
var int AlliesHealed;                  // Number of different allies healed
var int MiracleRecoveries;             // Number of miracle recoveries triggered
var int CurrentPerkLevel;              // Track current perk level for abilities
var const int MaxHealingToDisplay;     // Maximum healing to display on UI (500)
var const int HealingMilestone;        // Healing points needed for milestone
var const float HealingDisplayDuration; // How long to show healing count after last heal

// Healing aura system (Level 10+)
var bool bHealingAuraActive;           // Whether healing aura is currently active
var float LastAuraHealTime;            // Last time aura healing was applied
var const float AuraHealInterval;      // How often aura healing ticks (1 second)

// Sound events for feedback
var const name ArchangelSoundRTPCName;
var const AkEvent HealTrackSound;      // Sound when tracking healing
var const AkEvent MilestoneCompleteSound; // Sound when completing healing milestone
var const AkEvent MiracleRecoverySound; // Sound when miracle recovery triggers
var const AkEvent HealingAuraSound;    // Sound for healing aura

// Ally tracking for proximity bonuses
struct AllyRecord
{
    var KFPawn_Human AllyPawn;
    var float LastSeenTime;
};

var array<AllyRecord> NearbyAllies;
var const float AllyTrackingInterval;  // How often to update ally list
var float LastAllyUpdate;              // Last time we updated ally list

function PostBeginPlay()
{
    super.PostBeginPlay();

    if (Owner == None)
        Destroy();
    
    LastAuraHealTime = Owner.WorldInfo.TimeSeconds;
    LastAllyUpdate = Owner.WorldInfo.TimeSeconds;
    CurrentPerkLevel = 0; // Initialize perk level
    
    // Set up repeating timer for healing aura and ally tracking
    SetTimer(1.0f, true, 'ProcessPeriodicHealing');
}

function Timer()
{
    if (Owner == None)
    {
        Destroy();
        return;
    }

    // Hide healing counter after period of inactivity
    if (HealingToDisplay > 0)
    {
        HealingToDisplay = 0;
        UpdateHealingDisplay(HealingToDisplay, False);
    }
}

// Function to update perk level (called from main perk class)
function SetPerkLevel(int NewLevel)
{
    CurrentPerkLevel = NewLevel;
    
    // Update healing aura status based on perk level
    bHealingAuraActive = (CurrentPerkLevel >= class'DKConfig_Capstone'.default.Capstone_Rank1Level);
}

// Called when player heals someone (main tracking function)
function TrackHealing(int HealingAmount, optional KFPawn_Human HealedAlly)
{
    local KFPlayerController KFPC;
    local KFPlayerReplicationInfo KFPRI;
    local KFPawn_Human OwnerPawn;
    
    ClearTimer('HideHealingDisplay'); // Clear the hide display timer
    
    // Add to total healing done
    TotalHealingDone += HealingAmount;
    
    // Track unique allies healed
    if (HealedAlly != None && HealedAlly != Owner)
    {
        // Could implement ally tracking here if needed
        AlliesHealed++;
    }
    
    // Calculate healing to display (show actual progress toward 500 HP milestone)
    HealingToDisplay = TotalHealingDone % HealingMilestone;
    
    // Check if we hit a healing milestone
    if (TotalHealingDone > 0 && (TotalHealingDone % HealingMilestone) == 0)
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
                    // Give 75 dosh as reward for healing service
                    KFPRI.AddDosh(75);
                    
                    // Show completion message
                    KFPC.ClientMessage("DIVINE SERVICE COMPLETE! +75 Dosh! (" $ TotalHealingDone $ " total healing)");
                }
            }
        }
        
        // Reset display counter and show the reward feedback
        HealingToDisplay = 0;
        UpdateHealingDisplay(HealingToDisplay, True);
        
        // Play special milestone complete sound
        PlayMilestoneCompleteSound();
    }
    else
    {
        // Normal healing tracking - update UI
        UpdateHealingDisplay(HealingToDisplay, False);
        
        // Set timer to hide counter after inactivity
        SetTimer(HealingDisplayDuration, False, 'HideHealingDisplay');
    }
}

// Called when miracle recovery is triggered
function TriggerMiracleRecovery(KFPawn_Human TargetPawn)
{
    local KFPlayerController KFPC;
    local DKHudWrapper ArchangelHUD;
    
    MiracleRecoveries++;
    
    // Fully heal the target
    if (TargetPawn != None)
    {
        TargetPawn.Health = TargetPawn.HealthMax;
        
        // Get the player controller
        KFPC = KFPlayerController(GetALocalPlayerController());
        if (KFPC != None)
        {
            // Play special miracle recovery sound
            KFPC.PlayRMEffect(MiracleRecoverySound, ArchangelSoundRTPCName, 255);
            
            // Show dramatic message
            KFPC.ClientMessage("MIRACLE RECOVERY: " $ TargetPawn.PlayerReplicationInfo.PlayerName $ " fully healed!", 'CriticalEvent');
            
            // Trigger special chain notification through HUD
            ArchangelHUD = class'DKHudWrapper'.static.GetReaperHUD(KFPC);
            if (ArchangelHUD != None)
            {
                ArchangelHUD.TriggerChainNotification("DIVINE INTERVENTION!", "Miracle recovery granted to " $ TargetPawn.PlayerReplicationInfo.PlayerName, 4.0f);
            }
        }
    }
}

// Periodic timer for healing aura and ally tracking
function ProcessPeriodicHealing()
{
    local float CurrentTime;
    
    if (Owner == None) return;
    
    CurrentTime = Owner.WorldInfo.TimeSeconds;
    
    // Update nearby allies list
    if (CurrentTime - LastAllyUpdate >= AllyTrackingInterval)
    {
        UpdateNearbyAllies();
        LastAllyUpdate = CurrentTime;
    }
    
    // Apply healing aura if active (Level 10+)
    if (bHealingAuraActive && CurrentTime - LastAuraHealTime >= AuraHealInterval)
    {
        ApplyHealingAura();
        LastAuraHealTime = CurrentTime;
    }
}

// Apply healing aura to nearby allies (Level 10+)
function ApplyHealingAura()
{
    local int i;
    local KFPawn_Human AllyPawn;
    local float HealingAmount;
    local bool bHealedSomeone;
    
    // Config-driven: server owners tune this via
    // [ZedternalRBPerkpackage.DKUpgrade_Perk_Archangel] Level10AuraHealing
    HealingAmount = class'DKUpgrade_Perk_Archangel'.default.Level10AuraHealing;
    bHealedSomeone = false;
    
    // Heal all nearby allies
    for (i = 0; i < NearbyAllies.Length; i++)
    {
        AllyPawn = NearbyAllies[i].AllyPawn;
        if (AllyPawn != None && AllyPawn.Health < AllyPawn.HealthMax && AllyPawn != Owner)
        {
            AllyPawn.Health = FMin(AllyPawn.Health + HealingAmount, AllyPawn.HealthMax);
            bHealedSomeone = true;
            
            // Track this healing (but don't count it toward milestone to avoid spam)
            // TrackHealing(int(HealingAmount), AllyPawn);
        }
    }
    
    // Play gentle healing aura sound if we healed someone
    if (bHealedSomeone)
    {
        PlayHealingAuraSound();
    }
}

// Update nearby allies list for proximity bonuses
function UpdateNearbyAllies()
{
    local KFPawn_Human OwnerPawn, AllyPawn;
    local float Distance;
    local AllyRecord NewRecord;
    local float CurrentTime;
    
    OwnerPawn = KFPawn_Human(Owner);
    if (OwnerPawn == None) return;
    
    CurrentTime = Owner.WorldInfo.TimeSeconds;
    NearbyAllies.Length = 0; // Clear old list
    
    // Find all human pawns in the game
    foreach OwnerPawn.WorldInfo.DynamicActors(class'KFPawn_Human', AllyPawn)
    {
        if (AllyPawn != OwnerPawn && AllyPawn.Health > 0)
        {
            Distance = VSize(AllyPawn.Location - OwnerPawn.Location);
            if (Distance <= class'DKUpgrade_Perk_Archangel'.default.AllyProximityRange)
            {
                NewRecord.AllyPawn = AllyPawn;
                NewRecord.LastSeenTime = CurrentTime;
                NearbyAllies.AddItem(NewRecord);
            }
        }
    }
}

// Get count of nearby allies for bonuses
function int GetNearbyAlliesCount()
{
    return NearbyAllies.Length;
}

// Update healing aura status (called from perk) - kept for compatibility
function UpdateHealingAura(int UpgradeLevel)
{
    bHealingAuraActive = (UpgradeLevel >= class'DKConfig_Capstone'.default.Capstone_Rank1Level);
}

// Timer function to hide healing display
function HideHealingDisplay()
{
    if (HealingToDisplay > 0)
    {
        HealingToDisplay = 0;
        UpdateHealingDisplay(HealingToDisplay, False);
    }
}

function ResetHealingCounter()
{
    // Reset healing tracking
    ClearTimer();
    TotalHealingDone = 0;
    AlliesHealed = 0;
    MiracleRecoveries = 0;
    HealingToDisplay = 0;
    NearbyAllies.Length = 0;
    UpdateHealingDisplay(HealingToDisplay, False);
}

// Play special sound when completing healing milestone
function PlayMilestoneCompleteSound()
{
    local KFPlayerController KFPC;
    
    KFPC = KFPlayerController(GetALocalPlayerController());
    if (KFPC != None)
    {
        KFPC.PlayRMEffect(MilestoneCompleteSound, ArchangelSoundRTPCName, MaxHealingToDisplay);
    }
}

// Play gentle healing aura sound
function PlayHealingAuraSound()
{
    local KFPlayerController KFPC;
    
    KFPC = KFPlayerController(GetALocalPlayerController());
    if (KFPC != None)
    {
        KFPC.PlayRMEffect(HealingAuraSound, ArchangelSoundRTPCName, 50); // Quieter for aura
    }
}

// Get summary of healing performance for panels
function string GetHealingSummary()
{
    local string Summary;
    
    Summary = "Healing: " $ TotalHealingDone $ "HP";
    if (MiracleRecoveries > 0)
        Summary $= " | Miracles: " $ MiracleRecoveries;
    if (bHealingAuraActive)
        Summary $= " | Aura: Active";
    if (GetNearbyAlliesCount() > 0)
        Summary $= " | Allies: " $ GetNearbyAlliesCount();
    
    return Summary;
}

// Main UI update function using HUD wrapper
reliable client function UpdateHealingDisplay(byte HealingCount, optional bool bMilestoneComplete = False)
{
    local KFPlayerController KFPC;
    local AkEvent TempAkEvent;
    local DKHudWrapper ArchangelHUD;

    KFPC = KFPlayerController(GetALocalPlayerController());

    if (KFPC == None)
        return;

    // Try to get our custom HUD
    ArchangelHUD = class'DKHudWrapper'.static.GetReaperHUD(KFPC);
    if (ArchangelHUD != None)
    {
        // Use our custom HUD to display Archangel healing with icon
        ArchangelHUD.UpdateArchangelHealing(HealingCount, MaxHealingToDisplay, bMilestoneComplete);
    }
    else if (KFPC.MyGFxHUD != None)
    {
        // Fallback: Use standard rhythm counter if custom HUD not available
        KFPC.UpdateRhythmCounterWidget(HealingCount, MaxHealingToDisplay);
    }

    // Play appropriate sound effects for feedback
    if (bMilestoneComplete)
        TempAkEvent = MilestoneCompleteSound;
    else if (HealingCount > 0)
        TempAkEvent = HealTrackSound;

    if (TempAkEvent != None)
        KFPC.PlayRMEffect(TempAkEvent, ArchangelSoundRTPCName, HealingCount);
}

defaultproperties
{
    HealingToDisplay=0
    TotalHealingDone=0
    AlliesHealed=0
    MiracleRecoveries=0
    CurrentPerkLevel=0
    MaxHealingToDisplay=500        // FIX: Changed from 100 to 500 to match milestone
    HealingMilestone=500           // 500 HP healed per milestone
    HealingDisplayDuration=6.0f    // Show healing counter for 6 seconds after last heal
    
    // Healing aura settings
    bHealingAuraActive=false
    AuraHealInterval=1.0f          // Heal every 1 second
    
    // Ally tracking settings
    AllyTrackingInterval=0.5f      // Update ally list every 0.5 seconds
    LastAllyUpdate=0.0f
    
    // Sound configuration
    ArchangelSoundRTPCName="Archangel_Healing"
    HealTrackSound=AkEvent'WW_UI_PlayerCharacter.Play_R_Method_Hit'        // Sound when tracking healing
    MilestoneCompleteSound=AkEvent'WW_UI_PlayerCharacter.Play_R_Method_Top' // Sound for milestone complete
    MiracleRecoverySound=AkEvent'WW_UI_PlayerCharacter.Play_R_Method_Top'   // Sound for miracle recovery
    HealingAuraSound=AkEvent'WW_UI_PlayerCharacter.Play_R_Method_Hit'       // Gentle sound for aura
    
    Name="Default__DKUpgrade_Perk_Archangel_Helper"
}