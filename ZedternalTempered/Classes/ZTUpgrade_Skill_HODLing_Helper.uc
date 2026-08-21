class ZTUpgrade_Skill_HODLing_Helper extends Info transient;

var KFPawn_Human Player;
var bool bDeluxe;
var int UpgradeLevel;
var int LastKnownDosh;
var float HODLStartTime;
var float HODLDuration;
var bool bCurrentlyHODLing;
var bool bWaveInProgress;
var float DoshCheckInterval;

function PostBeginPlay()
{
    super.PostBeginPlay();

    Player = KFPawn_Human(Owner);
    if (Player == None || Player.Health <= 0)
        Destroy();
    else
    {
        LastKnownDosh = GetCurrentPlayerDosh();
        bCurrentlyHODLing = false;
        bWaveInProgress = true; // Assume wave is in progress initially
        HODLDuration = class'ZTUpgrade_Skill_HODLing'.default.HODLDuration[UpgradeLevel - 1];
        SetTimer(DoshCheckInterval, True);
    }
}

function Timer()
{
    if (Player == None || Player.Health <= 0)
    {
        Destroy();
        return;
    }
    
    CheckHODLStatus();
}

function CheckHODLStatus()
{
    local int CurrentDosh;
    local float CurrentTime, ElapsedHODLTime, RemainingTime;
    local KFPlayerController KFPC;
    local KFPlayerReplicationInfo KFPRI;
    local int InterestAmount;
    
    CurrentDosh = GetCurrentPlayerDosh();
    CurrentTime = Player.WorldInfo.TimeSeconds;
    
    // Check if dosh decreased (spending detected)
    if (CurrentDosh < LastKnownDosh)
    {
        // Spending detected - reset HODL
        if (bCurrentlyHODLing)
        {
            KFPC = KFPlayerController(Player.Controller);
            if (KFPC != None)
            {
                // Important - HODL broken (significant state change)
                class'ZTMessageManager'.static.SendImportant(KFPC, "HODL BROKEN! Spending detected - HODL timer reset");
            }
        }
        
        bCurrentlyHODLing = false;
        HODLStartTime = CurrentTime;
    }
    else if (CurrentDosh > LastKnownDosh)
    {
        // Dosh increased (not spending, probably earning) - continue/start HODL
        if (!bCurrentlyHODLing)
        {
            bCurrentlyHODLing = true;
            HODLStartTime = CurrentTime;
        }
    }
    else if (!bCurrentlyHODLing)
    {
        // Same dosh amount and not currently HODLing - start HODL
        bCurrentlyHODLing = true;
        HODLStartTime = CurrentTime;
    }
    
    // Check HODL completion (only during active waves)
    if (bCurrentlyHODLing && bWaveInProgress)
    {
        ElapsedHODLTime = CurrentTime - HODLStartTime;
        
        if (ElapsedHODLTime >= HODLDuration)
        {
            // HODL completed! Pay interest
            InterestAmount = int(float(CurrentDosh) * class'ZTUpgrade_Skill_HODLing'.default.InterestRate);
            
            if (InterestAmount > 0)
            {
                KFPC = KFPlayerController(Player.Controller);
                if (KFPC != None)
                {
                    KFPRI = KFPlayerReplicationInfo(KFPC.PlayerReplicationInfo);
                    if (KFPRI != None)
                    {
                        KFPRI.AddDosh(InterestAmount);
                        // Critical - HODL completion (major achievement)
                        class'ZTMessageManager'.static.SendCritical(KFPC, "HODL COMPLETED! +" $ InterestAmount $ " Dosh interest (50% of " $ CurrentDosh $ ")");
                    }
                }
            }
            
            // Reset HODL for next cycle
            bCurrentlyHODLing = false;
            HODLStartTime = CurrentTime;
        }
        else
        {
            // Show progress occasionally
            RemainingTime = HODLDuration - ElapsedHODLTime;
            if (int(RemainingTime) % 60 == 0 && int(RemainingTime) <= 300) // Show every minute in last 5 minutes
            {
                KFPC = KFPlayerController(Player.Controller);
                if (KFPC != None)
                {
                    // Minor - progress tracking
                    class'ZTMessageManager'.static.SendMinor(KFPC, "HODL Progress: " $ int(RemainingTime) $ " seconds remaining for 50% interest");
                }
            }
        }
    }
    
    LastKnownDosh = CurrentDosh;
}

function int GetCurrentPlayerDosh()
{
    local KFPlayerController KFPC;
    local KFPlayerReplicationInfo KFPRI;
    
    if (Player == None) return 0;
    
    KFPC = KFPlayerController(Player.Controller);
    if (KFPC == None) return 0;
    
    KFPRI = KFPlayerReplicationInfo(KFPC.PlayerReplicationInfo);
    if (KFPRI == None) return 0;
    
    return KFPRI.Score;
}

// Pause HODL timer between waves
function WaveEnd()
{
    bWaveInProgress = false;
}

// Resume HODL timer when wave starts
function WaveStart()
{
    bWaveInProgress = true;
    // Reset start time to current time to account for break between waves
    if (bCurrentlyHODLing)
    {
        HODLStartTime = Player.WorldInfo.TimeSeconds;
    }
}

defaultproperties
{
    bDeluxe=False
    UpgradeLevel=1
    DoshCheckInterval=1.0f
    bCurrentlyHODLing=False
    bWaveInProgress=True

    Name="Default__ZTUpgrade_Skill_HODLing_Helper"
}