class DKUpgrade_Skill_SnakesCoil_Helper extends Info
    transient;

var bool bSpeedBoostActive;
var float SpeedBoostDuration;
var const float MaxSpeedBoostDuration;

function PostBeginPlay()
{
    super.PostBeginPlay();

    if (Owner == None)
        Destroy();
        
    bSpeedBoostActive = false;
    SpeedBoostDuration = 0.0f;
}

function Timer()
{
    if (Owner == None)
    {
        Destroy();
        return;
    }

    // Update speed boost timer
    if (bSpeedBoostActive)
    {
        SpeedBoostDuration -= 1.0f;
        
        if (SpeedBoostDuration <= 0.0f)
        {
            bSpeedBoostActive = false;
            ShowSpeedBoostEnd();
        }
    }
}

function TriggerSpeedBoost()
{
    local KFPlayerController KFPC;
    
    bSpeedBoostActive = true;
    SpeedBoostDuration = MaxSpeedBoostDuration;
    
    // Show notification (Important - buff activation)
    KFPC = KFPlayerController(GetALocalPlayerController());
    if (KFPC != None)
    {
        class'DKMessageManager'.static.SendImportant(KFPC, "Snake's Coil: Speed boost activated! +" $ int(SpeedBoostDuration) $ " seconds");
    }
    
    // Start timer if not already running
    if (!IsTimerActive())
    {
        SetTimer(1.0f, True);
    }
}

function ShowSpeedBoostEnd()
{
    local KFPlayerController KFPC;
    
    KFPC = KFPlayerController(GetALocalPlayerController());
    if (KFPC != None)
    {
        // Minor - buff expiration
        class'DKMessageManager'.static.SendMinor(KFPC, "Snake's Coil: Speed boost ended");
    }
}

defaultproperties
{
    bSpeedBoostActive=false
    SpeedBoostDuration=0.0f
    MaxSpeedBoostDuration=5.0f      // 5 seconds of speed boost
    
    Name="Default__DKUpgrade_Skill_SnakesCoil_Helper"
}