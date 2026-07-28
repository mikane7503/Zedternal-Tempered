class DKUpgrade_Skill_ProfitSharing_Helper extends Info
    transient;

var KFPawn_Human Player;
var bool bDeluxe;
var int UpgradeLevel;
var int KillCount;
var const int KillsRequired;

function PostBeginPlay()
{
    super.PostBeginPlay();

    Player = KFPawn_Human(Owner);
    if (Player == None || Player.Health <= 0)
        Destroy();
    else
        KillCount = 0;
}

function OnEnemyKilled()
{
    local KFPlayerController KFPC;
    local KFPlayerController TeammatePCs;
    local KFPlayerReplicationInfo TeammatePRI;
    local int DoshToGive;
    
    KillCount++;
    
    if (KillCount >= KillsRequired)
    {
        // Reset counter
        KillCount = 0;
        
        // Get dosh amount based on upgrade level
        DoshToGive = class'DKUpgrade_Skill_ProfitSharing'.default.DoshPerTeammate[UpgradeLevel - 1];
        
        // Get player controller
        KFPC = KFPlayerController(Player.Controller);
        if (KFPC != None)
        {
            // Give dosh to all teammates
            foreach Player.WorldInfo.AllControllers(class'KFPlayerController', TeammatePCs)
            {
                if (TeammatePCs != KFPC) // Don't give to self
                {
                    TeammatePRI = KFPlayerReplicationInfo(TeammatePCs.PlayerReplicationInfo);
                    if (TeammatePRI != None)
                    {
                        TeammatePRI.AddDosh(DoshToGive);
                        // Important - teammates receiving dosh
                        class'DKMessageManager'.static.SendImportant(TeammatePCs, "PROFIT SHARING: +" $ DoshToGive $ " Dosh from " $ KFPC.PlayerReplicationInfo.PlayerName);
                    }
                }
            }
            
            // Critical - profit sharer activating major team benefit
            class'DKMessageManager'.static.SendCritical(KFPC, "PROFIT SHARING ACTIVATED: Gave " $ DoshToGive $ " Dosh to all teammates!");
        }
    }
}

// Clean up when wave ends
function WaveEnd()
{
    KillCount = 0; // Reset for next wave
}

defaultproperties
{
    bDeluxe=False
    UpgradeLevel=1
    KillsRequired=25
    KillCount=0

    Name="Default__DKUpgrade_Skill_ProfitSharing_Helper"
}