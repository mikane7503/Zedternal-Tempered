class DKUpgrade_Skill_SymphonyOfSlaughter_Helper extends Info;

var array<float> KillTimestamps;
var bool bSpeedBoostActive;
var float CurrentSpeedBoost;

function PostBeginPlay()
{
    super.PostBeginPlay();
    
    if (Owner == None)
        Destroy();
    
    bSpeedBoostActive = false;
    CurrentSpeedBoost = 0.0f;
}

function RegisterKill(int KillsRequired, float KillWindow, float SpeedBoost, float BoostDuration)
{
    local float CurrentTime;
    local int i;
    local array<float> ValidKills;
    local KFPlayerController KFPC;
    
    if (Owner == None)
        return;
    
    CurrentTime = Owner.WorldInfo.TimeSeconds;
    
    // Add this kill
    KillTimestamps.AddItem(CurrentTime);
    
    // Filter to only kills within the window
    for (i = 0; i < KillTimestamps.Length; i++)
    {
        if ((CurrentTime - KillTimestamps[i]) <= KillWindow)
        {
            ValidKills.AddItem(KillTimestamps[i]);
        }
    }
    KillTimestamps = ValidKills;
    
    // Check if we hit the threshold
    if (KillTimestamps.Length >= KillsRequired && !bSpeedBoostActive)
    {
        // Activate speed boost
        bSpeedBoostActive = true;
        CurrentSpeedBoost = SpeedBoost;
        
        // Clear kill timestamps
        KillTimestamps.Length = 0;
        
        // Set timer to end boost
        SetTimer(BoostDuration, false, 'EndSpeedBoost');
        
        // DK FIX: force a speed recompute so the boost applies immediately.
        // GroundSpeed otherwise only updates on weapon switch.
        if (KFPawn(Owner) != None)
            KFPawn(Owner).UpdateGroundSpeed();
        
        // Notify player
        KFPC = KFPlayerController(Pawn(Owner).Controller);
        if (KFPC != None)
        {
            KFPC.ClientMessage("Symphony of Slaughter! +" $ int(SpeedBoost * 100) $ "% speed for " $ int(BoostDuration) $ "s!", 'Event');
        }
    }
}

function EndSpeedBoost()
{
    local KFPlayerController KFPC;
    
    bSpeedBoostActive = false;
    CurrentSpeedBoost = 0.0f;
    
    if (Owner != None)
    {
        // DK FIX: drop the boost immediately instead of keeping the speed
        // until the next weapon switch.
        if (KFPawn(Owner) != None)
            KFPawn(Owner).UpdateGroundSpeed();
        
        KFPC = KFPlayerController(Pawn(Owner).Controller);
        if (KFPC != None)
        {
            KFPC.ClientMessage("Symphony of Slaughter ended.", 'Event');
        }
    }
}

defaultproperties
{
    bSpeedBoostActive=false
    CurrentSpeedBoost=0.0f
    
    Name="Default__DKUpgrade_Skill_SymphonyOfSlaughter_Helper"
}
