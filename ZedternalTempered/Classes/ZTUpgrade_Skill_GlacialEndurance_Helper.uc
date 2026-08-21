class ZTUpgrade_Skill_GlacialEndurance_Helper extends Info transient;

var KFPawn_Human Player;
var bool bDeluxe, bInExtendedZedTime;
var int UpgradeLevel;
var float BaseZedTimeEnd;
var const float Update;
var const array<float> ExtensionDuration;

function PostBeginPlay()
{
    super.PostBeginPlay();

    Player = KFPawn_Human(Owner);
    if (Player == None || Player.Health <= 0)
        Destroy();
    else
    {
        SetTimer(Update, True);
        bInExtendedZedTime = False;
    }
}

function Timer()
{
    local float CurrentTime;
    local KFGameInfo KFGI;

    if (Player == None || Player.Health <= 0)
    {
        Destroy();
        return;
    }

    CurrentTime = Player.WorldInfo.TimeSeconds;
    KFGI = KFGameInfo(Player.WorldInfo.Game);

    // Check if we're in Zed Time
    if (Player.WorldInfo.TimeDilation < 1.0f)
    {
        // If we just entered Zed Time, record when base Zed Time should end
        if (!bInExtendedZedTime && BaseZedTimeEnd == 0.0f)
        {
            // Estimate when base Zed Time would end without our extension
            BaseZedTimeEnd = CurrentTime + (KFGI != None ? KFGI.ZedTimeRemaining : 3.0f) - default.ExtensionDuration[UpgradeLevel - 1];
        }
        
        // Check if we're in the extended portion
        if (BaseZedTimeEnd > 0.0f && CurrentTime >= BaseZedTimeEnd)
        {
            bInExtendedZedTime = True;
        }
    }
    else
    {
        // Reset when Zed Time ends
        bInExtendedZedTime = False;
        BaseZedTimeEnd = 0.0f;
    }
}

defaultproperties
{
    bDeluxe=False
    bInExtendedZedTime=False
    UpgradeLevel=1
    BaseZedTimeEnd=0.0f
    Update=0.1f
    ExtensionDuration(0)=2.0f
    ExtensionDuration(1)=4.0f

    Name="Default__ZTUpgrade_Skill_GlacialEndurance_Helper"
}