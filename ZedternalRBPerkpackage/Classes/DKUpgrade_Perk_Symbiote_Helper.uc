class DKUpgrade_Perk_Symbiote_Helper extends Info
    transient;

// Evolution tracking (100 kills = 1 evolution)
var byte KillsToDisplay;               // Current kills for UI display (0-100)
var int TotalKills;                    // Total kill count 
var int TotalEvolutions;               // Number of evolutions gained
var const byte MaxKillsToDisplay;      // Maximum kills to display on UI (100)
var const float KillDisplayDuration;   // How long to show kill count after last kill

// Evolution bonus storage
struct EvolutionBonus
{
    var string BonusType;      // Type of bonus (e.g., "Damage", "ReloadSpeed")
    var float BonusValue;      // Value of the bonus
    var string DisplayName;    // Friendly name for display
};

var array<EvolutionBonus> AccumulatedBonuses;  // All bonuses gained
var const array<string> PossibleEvolutions;    // Possible evolution types
var const array<float> EvolutionValues;        // Corresponding values for each evolution
var const array<string> EvolutionDisplayNames; // Display names for each evolution

// Sound events for feedback
var const name SymbioteSoundRTPCName;
var const AkEvent KillTrackSound;      // Sound when tracking kills
var const AkEvent EvolutionSound;      // Sound when evolution occurs

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
    
    // Check if we hit 100 kills - trigger random evolution!
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
                    // Apply random evolution immediately
                    ApplyRandomEvolution(KFPC);
                }
            }
        }
        
        // Reset display counter and show the evolution feedback
        KillsToDisplay = 0;
        UpdateKillDisplay(KillsToDisplay, True);
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

// Apply a random evolution immediately
function ApplyRandomEvolution(KFPlayerController KFPC)
{
    local EvolutionBonus NewBonus;
    local string EvolutionMessage;
    local DKHudWrapper SymbioteHUD;
    local int RandomIndex;
    
    if (PossibleEvolutions.Length == 0)
        return;
    
    // Pick a random evolution
    RandomIndex = Rand(PossibleEvolutions.Length);
    
    // Increase evolution counter
    TotalEvolutions++;
    
    // Apply the random evolution
    NewBonus.BonusType = PossibleEvolutions[RandomIndex];
    NewBonus.BonusValue = EvolutionValues[RandomIndex];
    NewBonus.DisplayName = EvolutionDisplayNames[RandomIndex];
    
    // Add to accumulated bonuses
    AccumulatedBonuses.AddItem(NewBonus);
    
    // Show evolution message
    EvolutionMessage = "SYMBIOTE EVOLUTION #" $ TotalEvolutions $ ": +" $ 
                       Round(NewBonus.BonusValue * 100) $ "% " $ NewBonus.DisplayName $ "!";
    
    if (KFPC != None)
    {
        KFPC.ClientMessage(EvolutionMessage, 'CriticalEvent');
        
        // Show evolution panel
        SymbioteHUD = class'DKHudWrapper'.static.GetReaperHUD(KFPC);
        if (SymbioteHUD != None)
        {
            SymbioteHUD.ShowEvolutionPanel(false, 8.0f);
        }
        
        // Play evolution sound
        if (EvolutionSound != None)
            KFPC.PlayRMEffect(EvolutionSound, SymbioteSoundRTPCName, TotalEvolutions);
    }
    
    // Update HUD to show new evolution bonuses
    UpdateEvolutionDisplay();
}

// Update HUD display tracking
reliable client function UpdateKillDisplay(byte Kills, bool bEvolutionComplete)
{
    local KFPlayerController KFPC;
    local DKHudWrapper SymbioteHUD;
    local AkEvent TempAkEvent;

    KFPC = KFPlayerController(GetALocalPlayerController());
    if (KFPC == None)
        return;

    // Try to get our custom HUD
    SymbioteHUD = class'DKHudWrapper'.static.GetReaperHUD(KFPC);
    if (SymbioteHUD != None)
    {
        // Use our custom HUD to display Symbiote evolution progress
        SymbioteHUD.UpdateSymbioteEvolution(Kills, MaxKillsToDisplay, bEvolutionComplete);
    }
    else if (KFPC.MyGFxHUD != None)
    {
        // Fallback: Use standard rhythm counter if custom HUD not available
        KFPC.UpdateRhythmCounterWidget(Kills, MaxKillsToDisplay);
    }

    // Play appropriate sound effects for feedback
    if (bEvolutionComplete)
        TempAkEvent = EvolutionSound;
    else if (Kills > 0)
        TempAkEvent = KillTrackSound;

    if (TempAkEvent != None)
        KFPC.PlayRMEffect(TempAkEvent, SymbioteSoundRTPCName, Kills);
}

// Update HUD to show evolution bonuses
reliable client function UpdateEvolutionDisplay()
{
    local KFPlayerController KFPC;
    local DKHudWrapper SymbioteHUD;
    local string EvolutionSummary;

    KFPC = KFPlayerController(GetALocalPlayerController());
    if (KFPC == None)
        return;

    SymbioteHUD = class'DKHudWrapper'.static.GetReaperHUD(KFPC);
    if (SymbioteHUD != None && TotalEvolutions > 0)
    {
        // Show evolution summary on a separate tracker
        EvolutionSummary = GetEvolutionSummary();
        SymbioteHUD.UpdateSymbioteEvolutionBonuses(TotalEvolutions, EvolutionSummary);
    }
}

// Get current evolution bonus for a specific type
function float GetEvolutionBonus(string BonusType)
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

// Get a summary of all evolution bonuses for HUD display
function string GetEvolutionSummary()
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
    Summary = "Evolutions: " $ TotalEvolutions;
    for (i = 0; i < BonusTypes.Length; i++)
    {
        Summary $= " | " $ BonusTypes[i] $ ": +" $ int(BonusTotals[i] * 100) $ "%";
    }
    
    return Summary;
}

defaultproperties
{
    MaxKillsToDisplay=100          // Track kills up to 100 for evolution
    KillDisplayDuration=5.0f       // Show kill counter for 5 seconds after last kill
    
    // IMPROVED DEDUPLICATION SETTINGS
    KillDedupeWindow=0.1f          // Very short window - just prevent same-frame double counting
    CleanupInterval=2.0f           // Clean up old records every 2 seconds
    LastCleanupTime=0.0f           // Initialize cleanup timer
    
    // Possible evolution types and their values
    PossibleEvolutions(0)="Damage"
    PossibleEvolutions(1)="HeadshotDamage"
    PossibleEvolutions(2)="MovementSpeed"
    PossibleEvolutions(3)="ReloadSpeed"
    PossibleEvolutions(4)="WeaponSwitchSpeed"
    PossibleEvolutions(5)="Penetration"
    PossibleEvolutions(6)="SpareAmmo"
    PossibleEvolutions(7)="MagazineSize"
    
    // Corresponding values (as decimal percentages)
    EvolutionValues(0)=0.03f       // +3% Damage
    EvolutionValues(1)=0.05f       // +5% Headshot Damage
    EvolutionValues(2)=0.03f       // +3% Movement Speed
    EvolutionValues(3)=0.05f       // +5% Reload Speed
    EvolutionValues(4)=0.05f       // +5% Weapon Switch Speed
    EvolutionValues(5)=0.10f       // +10% Penetration
    EvolutionValues(6)=0.05f       // +5% Spare Ammo
    EvolutionValues(7)=0.05f       // +5% Magazine Size
    
    // Display names for UI
    EvolutionDisplayNames(0)="DMG"
    EvolutionDisplayNames(1)="HS-DMG"
    EvolutionDisplayNames(2)="SPD"
    EvolutionDisplayNames(3)="RLD"
    EvolutionDisplayNames(4)="SWT"
    EvolutionDisplayNames(5)="PEN"
    EvolutionDisplayNames(6)="AMO"
    EvolutionDisplayNames(7)="MAG"
    
    // Sound configuration - using valid sound events
    SymbioteSoundRTPCName="Symbiote_Evolution"
    KillTrackSound=AkEvent'WW_UI_PlayerCharacter.Play_R_Method_Hit'       // Sound when tracking kills
    EvolutionSound=AkEvent'WW_UI_PlayerCharacter.Play_R_Method_Top'       // Sound when evolution occurs
    
    Name="Default__DKUpgrade_Perk_Symbiote_Helper"
}