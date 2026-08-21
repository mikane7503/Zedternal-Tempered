class ZTUpgrade_Perk_Scavenger_Helper extends Info transient;

// Field adaptation tracking (50 kills = 1 adaptation)
var byte KillsToDisplay;               // Current kills for UI display (0-50)
var int TotalKills;                    // Total kill count 
var int TotalAdaptations;              // Number of adaptations gained
var const byte MaxKillsToDisplay;      // Maximum kills to display on UI (50)
var const float KillDisplayDuration;   // How long to show kill count after last kill

// Field adaptation bonus storage
struct AdaptationBonus
{
    var string BonusType;      // Type of bonus ("SpareAmmo" or "MagazineSize")
    var float BonusValue;      // Value of the bonus
    var string DisplayName;    // Friendly name for display
};

var array<AdaptationBonus> AccumulatedBonuses;  // All bonuses gained
var const array<string> PossibleAdaptations;    // Possible adaptation types (SpareAmmo, MagazineSize)
var const array<float> AdaptationValues;        // Corresponding values for each adaptation
var const array<string> AdaptationDisplayNames; // Display names for each adaptation

// Sound events for feedback
var const name ScavengerSoundRTPCName;
var const AkEvent KillTrackSound;      // Sound when tracking kills
var const AkEvent AdaptationSound;     // Sound when adaptation occurs
var const AkEvent AmmoScavengeSound;   // Sound when finding ammo

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
function TrackKill(optional KFPawn_Monster KilledMonster, optional int UpgradeLevel = 0)
{
    local KFPlayerController KFPC;
    local KFPlayerReplicationInfo KFPRI;
    local KFPawn_Human OwnerPawn;
    local KFWeapon CurrentWeapon;
    local bool bScavengedAmmo;
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
    
    // Get the owner pawn and controller for various checks
    OwnerPawn = KFPawn_Human(Owner);
    if (OwnerPawn != None)
    {
        KFPC = KFPlayerController(OwnerPawn.Controller);
        if (KFPC != None)
        {
            KFPRI = KFPlayerReplicationInfo(KFPC.PlayerReplicationInfo);
        }
    }
    
    // Level 10+ Ammo Scavenging - 10% chance to find ammo
    if (UpgradeLevel >= class'ZTConfig_Capstone'.default.Capstone_Rank1Level && KFPC != None && OwnerPawn != None)
    {
        if (FRand() <= class'ZTUpgrade_Perk_Scavenger'.default.AmmoScavengeChance)
        {
            CurrentWeapon = KFWeapon(OwnerPawn.Weapon);
            if (CurrentWeapon != None)
            {
                // Add spare ammo to current weapon
                CurrentWeapon.AddAmmo(class'ZTUpgrade_Perk_Scavenger'.default.AmmoScavengeAmount);
                
                // Show scavenging message
                KFPC.ClientMessage("AMMO SCAVENGED! Found " $ class'ZTUpgrade_Perk_Scavenger'.default.AmmoScavengeAmount $ " spare ammo!", 'Event');
                
                // Play scavenge sound
                if (AmmoScavengeSound != None)
                    KFPC.PlayRMEffect(AmmoScavengeSound, ScavengerSoundRTPCName, class'ZTUpgrade_Perk_Scavenger'.default.AmmoScavengeAmount);
                
                bScavengedAmmo = true;
            }
        }
    }
    
    ClearTimer('HideKillDisplay'); // Clear the hide display timer
    
    // Increase total kill count
    TotalKills++;
    
    // Calculate kills to display (0-50 cycle)
    KillsToDisplay = TotalKills % MaxKillsToDisplay;
    if (KillsToDisplay == 0)
        KillsToDisplay = MaxKillsToDisplay; // Show 50 instead of 0
    
    // Check if we hit 50 kills - trigger field adaptation!
    if (TotalKills > 0 && (TotalKills % MaxKillsToDisplay) == 0)
    {
        if (KFPC != None && KFPRI != None)
        {
            // Trigger field adaptation
            ApplyFieldAdaptation(KFPC);
        }
        
        // Reset display counter and show the adaptation feedback
        KillsToDisplay = 0;
        UpdateKillDisplay(KillsToDisplay, True);
    }
    else
    {
        // Normal kill tracking - update UI (only if we didn't scavenge ammo to avoid spam)
        if (!bScavengedAmmo)
        {
            UpdateKillDisplay(KillsToDisplay, False);
        }
        
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

// Apply a random field adaptation bonus
function ApplyFieldAdaptation(KFPlayerController KFPC)
{
    local AdaptationBonus NewBonus;
    local string AdaptationMessage;
    local ZTHudWrapper ScavengerHUD;
    local int RandomIndex;
    
    // Increase adaptation counter
    TotalAdaptations++;
    
    // Pick random adaptation from the two options
    RandomIndex = Rand(PossibleAdaptations.Length);
    
    NewBonus.BonusType = PossibleAdaptations[RandomIndex];
    NewBonus.BonusValue = AdaptationValues[RandomIndex];
    NewBonus.DisplayName = AdaptationDisplayNames[RandomIndex];
    
    // Add to accumulated bonuses
    AccumulatedBonuses.AddItem(NewBonus);
    
    // Show adaptation message
    AdaptationMessage = "FIELD ADAPTATION #" $ TotalAdaptations $ ": +" $ 
                       Round(NewBonus.BonusValue * 100) $ "% " $ NewBonus.DisplayName $ "!";
    
    if (KFPC != None)
    {
        KFPC.ClientMessage(AdaptationMessage, 'CriticalEvent');
        
        // Show adaptation panel using the HUD system
        ScavengerHUD = class'ZTHudWrapper'.static.GetReaperHUD(KFPC);
        if (ScavengerHUD != None)
        {
            // Show evolution panel for the adaptation (reuses existing system)
            ScavengerHUD.ShowEvolutionPanel(false, 8.0f);
        }
        
        // Play adaptation sound
        if (AdaptationSound != None)
            KFPC.PlayRMEffect(AdaptationSound, ScavengerSoundRTPCName, TotalAdaptations);
    }
    
    // Update HUD to show new adaptation bonuses
    UpdateAdaptationDisplay();
}

// Update HUD display tracking
reliable client function UpdateKillDisplay(byte Kills, bool bAdaptationComplete)
{
    local KFPlayerController KFPC;
    local ZTHudWrapper ScavengerHUD;
    local AkEvent TempAkEvent;

    KFPC = KFPlayerController(GetALocalPlayerController());
    if (KFPC == None)
        return;

    // Try to get our custom HUD
    ScavengerHUD = class'ZTHudWrapper'.static.GetReaperHUD(KFPC);
    if (ScavengerHUD != None)
    {
        // Use our custom HUD to display Scavenger field adaptation progress
        ScavengerHUD.UpdateScavengerAdaptations(Kills, MaxKillsToDisplay, bAdaptationComplete);
    }
    else if (KFPC.MyGFxHUD != None)
    {
        // Fallback: Use standard rhythm counter if custom HUD not available
        KFPC.UpdateRhythmCounterWidget(Kills, MaxKillsToDisplay);
    }

    // Play appropriate sound effects for feedback
    if (bAdaptationComplete)
        TempAkEvent = AdaptationSound;
    else if (Kills > 0)
        TempAkEvent = KillTrackSound;

    if (TempAkEvent != None)
        KFPC.PlayRMEffect(TempAkEvent, ScavengerSoundRTPCName, Kills);
}

// Update HUD to show adaptation bonuses
reliable client function UpdateAdaptationDisplay()
{
    local KFPlayerController KFPC;
    local ZTHudWrapper ScavengerHUD;
    local string AdaptationSummary;

    KFPC = KFPlayerController(GetALocalPlayerController());
    if (KFPC == None)
        return;

    ScavengerHUD = class'ZTHudWrapper'.static.GetReaperHUD(KFPC);
    if (ScavengerHUD != None && TotalAdaptations > 0)
    {
        // Show adaptation summary on the adaptations tracker
        AdaptationSummary = GetAdaptationSummary();
        ScavengerHUD.UpdateScavengerAdaptationBonuses(TotalAdaptations, AdaptationSummary);
    }
}

// Get current adaptation bonus for a specific type
function float GetAdaptationBonus(string BonusType)
{
    local int i;
    local float TotalBonus;
    
    TotalBonus = 0.0f;
    
    // Sum all bonuses of this type
    for (i = 0; i < AccumulatedBonuses.Length; i++)
    {
        if (AccumulatedBonuses[i].BonusType ~= BonusType)
        {
            TotalBonus += AccumulatedBonuses[i].BonusValue;
        }
    }
    
    return TotalBonus;
}

// Get a summary of all adaptation bonuses for HUD display
function string GetAdaptationSummary()
{
    local int i;
    local string Summary;
    local array<string> BonusTypes;
    local array<float> BonusTotals;
    local int TypeIndex;
    
    // Consolidate bonuses by type
    for (i = 0; i < AccumulatedBonuses.Length; i++)
    {
        TypeIndex = BonusTypes.Find(AccumulatedBonuses[i].BonusType);
        if (TypeIndex == INDEX_NONE)
        {
            BonusTypes.AddItem(AccumulatedBonuses[i].BonusType);
            BonusTotals.AddItem(AccumulatedBonuses[i].BonusValue);
        }
        else
        {
            BonusTotals[TypeIndex] += AccumulatedBonuses[i].BonusValue;
        }
    }
    
    // Build summary string
    Summary = "Adaptations: " $ TotalAdaptations;
    for (i = 0; i < BonusTypes.Length; i++)
    {
        Summary $= " | " $ BonusTypes[i] $ ": +" $ int(BonusTotals[i] * 100) $ "%";
    }
    
    return Summary;
}

// Play adaptation completion sound
reliable client function PlayAdaptationSound()
{
    local KFPlayerController KFPC;

    KFPC = KFPlayerController(GetALocalPlayerController());
    if (KFPC != None && AdaptationSound != None)
    {
        KFPC.PlayRMEffect(AdaptationSound, ScavengerSoundRTPCName, TotalAdaptations);
    }
}

defaultproperties
{
    MaxKillsToDisplay=50           // Track kills up to 50 for field adaptation
    KillDisplayDuration=5.0f       // Show kill counter for 5 seconds after last kill
    
    // UPDATED DEDUPLICATION SETTINGS - Standardized to 30ms
    KillDedupeWindow=0.03f         // 30ms - minimal window to catch same-event duplicates only
    CleanupInterval=2.0f           // Clean up old records every 2 seconds
    LastCleanupTime=0.0f           // Initialize cleanup timer
    
    // Possible adaptation types - only 2 options for Scavenger
    PossibleAdaptations(0)="SpareAmmo"
    PossibleAdaptations(1)="MagazineSize"
    
    // Corresponding values (as decimal percentages)
    AdaptationValues(0)=0.05f      // +5% Spare Ammo
    AdaptationValues(1)=0.05f      // +5% Magazine Size
    
    // Display names for UI
    AdaptationDisplayNames(0)="Spare Ammo"
    AdaptationDisplayNames(1)="Magazine Size"
    
    // Sound configuration - using valid sound events
    ScavengerSoundRTPCName="Scavenger_Adaptation"
    KillTrackSound=AkEvent'WW_UI_PlayerCharacter.Play_R_Method_Hit'       // Sound when tracking kills
    AdaptationSound=AkEvent'WW_UI_PlayerCharacter.Play_R_Method_Top'      // Sound when adaptation occurs
    AmmoScavengeSound=AkEvent'WW_UI_PlayerCharacter.Play_R_Method_Hit'    // Sound when finding ammo
    
    Name="Default__ZTUpgrade_Perk_Scavenger_Helper"
}