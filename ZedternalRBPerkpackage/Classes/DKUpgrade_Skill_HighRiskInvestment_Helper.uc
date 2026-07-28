class DKUpgrade_Skill_HighRiskInvestment_Helper extends Info
    transient;

var KFPawn_Human Player;
var bool bDeluxe;
var int UpgradeLevel;
var int LastKnownDosh;
var float DoshCheckInterval;
var float LastDoshCheckTime;
var const float InvestmentChance;

function PostBeginPlay()
{
    super.PostBeginPlay();

    Player = KFPawn_Human(Owner);
    if (Player == None || Player.Health <= 0)
        Destroy();
    else
    {
        LastKnownDosh = GetCurrentPlayerDosh();
        LastDoshCheckTime = Player.WorldInfo.TimeSeconds;
        SetTimer(DoshCheckInterval, True);
    }
}

function Timer()
{
    local float CurrentTime;
    
    if (Player == None || Player.Health <= 0)
    {
        Destroy();
        return;
    }
    
    CurrentTime = Player.WorldInfo.TimeSeconds;
    
    // Check for dosh changes (purchases)
    if (CurrentTime - LastDoshCheckTime >= DoshCheckInterval)
    {
        CheckForLargePurchases();
        LastDoshCheckTime = CurrentTime;
    }
}

function CheckForLargePurchases()
{
    local int CurrentDosh, DoshSpent, MinAmount;
    local KFPlayerController KFPC;
    local KFPlayerReplicationInfo KFPRI;
    
    CurrentDosh = GetCurrentPlayerDosh();
    DoshSpent = LastKnownDosh - CurrentDosh;
    
    if (DoshSpent > 0)
    {
        // Get minimum purchase amount based on upgrade level
        MinAmount = class'DKUpgrade_Skill_HighRiskInvestment'.default.MinPurchaseAmount[UpgradeLevel - 1];
        
        if (DoshSpent >= MinAmount)
        {
            // Roll for investment return
            if (FRand() <= InvestmentChance)
            {
                // SUCCESS! Get investment back
                KFPC = KFPlayerController(Player.Controller);
                if (KFPC != None)
                {
                    KFPRI = KFPlayerReplicationInfo(KFPC.PlayerReplicationInfo);
                    if (KFPRI != None)
                    {
                        KFPRI.AddDosh(DoshSpent);
                        // Critical - investment success (rare, major payout)
                        class'DKMessageManager'.static.SendCritical(KFPC, "HIGH RISK INVESTMENT PAID OFF! +" $ DoshSpent $ " Dosh return!");
                    }
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

defaultproperties
{
    bDeluxe=False
    UpgradeLevel=1
    DoshCheckInterval=0.5f
    InvestmentChance=0.10f  // 10% chance

    Name="Default__DKUpgrade_Skill_HighRiskInvestment_Helper"
}