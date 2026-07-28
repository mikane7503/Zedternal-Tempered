class DKUpgrade_Skill_HouseEdge_Helper extends Info
    transient;

var KFPawn_Human Player;
var bool bDeluxe;
var int UpgradeLevel;
var int KillCountThisWave;

function PostBeginPlay()
{
    super.PostBeginPlay();

    Player = KFPawn_Human(Owner);
    if (Player == None || Player.Health <= 0)
        Destroy();
    else
        KillCountThisWave = 0;
}

function OnEnemyKilled()
{
    local int SlotTrigger;
    
    KillCountThisWave++;
    
    SlotTrigger = class'DKUpgrade_Skill_HouseEdge'.default.SlotMachineTrigger[UpgradeLevel - 1];
    
    if (KillCountThisWave >= SlotTrigger)
    {
        // Reset counter and trigger slot machine
        KillCountThisWave = 0;
        TriggerSlotMachine();
    }
}

function TriggerSlotMachine()
{
    local float RandomRoll;
    local int WinAmount;
    local string WinMessage;
    local KFPlayerController KFPC;
    local KFPlayerReplicationInfo KFPRI;
    
    RandomRoll = FRand(); // 0.0 to 1.0
    
    if (bDeluxe)
    {
        // Deluxe odds: 60% nothing, 25% +50, 10% +150, 5% +300
        if (RandomRoll <= 0.60f)
        {
            // 60% - Nothing
            WinAmount = 0;
            WinMessage = "SLOT MACHINE: No payout this time. Better luck next spin!";
        }
        else if (RandomRoll <= 0.85f)
        {
            // 25% - Small win
            WinAmount = 50;
            WinMessage = "SLOT MACHINE WINNER! +50 Dosh!";
        }
        else if (RandomRoll <= 0.95f)
        {
            // 10% - Medium win
            WinAmount = 150;
            WinMessage = "SLOT MACHINE BIG WIN! +150 Dosh!";
        }
        else
        {
            // 5% - Jackpot
            WinAmount = 300;
            WinMessage = "SLOT MACHINE JACKPOT! +300 Dosh!";
        }
    }
    else
    {
        // Basic odds: 80% nothing, 15% +50, 4% +150, 1% +300
        if (RandomRoll <= 0.80f)
        {
            // 80% - Nothing
            WinAmount = 0;
            WinMessage = "SLOT MACHINE: No payout this time. Better luck next spin!";
        }
        else if (RandomRoll <= 0.95f)
        {
            // 15% - Small win
            WinAmount = 50;
            WinMessage = "SLOT MACHINE WINNER! +50 Dosh!";
        }
        else if (RandomRoll <= 0.99f)
        {
            // 4% - Medium win
            WinAmount = 150;
            WinMessage = "SLOT MACHINE BIG WIN! +150 Dosh!";
        }
        else
        {
            // 1% - Jackpot
            WinAmount = 300;
            WinMessage = "SLOT MACHINE JACKPOT! +300 Dosh!";
        }
    }
    
    // Give dosh if won
    KFPC = KFPlayerController(Player.Controller);
    if (KFPC != None)
    {
        if (WinAmount > 0)
        {
            KFPRI = KFPlayerReplicationInfo(KFPC.PlayerReplicationInfo);
            if (KFPRI != None)
            {
                KFPRI.AddDosh(WinAmount);
            }
            // Critical - jackpot/big wins, Important - small wins
            if (WinAmount >= 150)
            {
                class'DKMessageManager'.static.SendCritical(KFPC, WinMessage);
            }
            else
            {
                class'DKMessageManager'.static.SendImportant(KFPC, WinMessage);
            }
        }
        else
        {
            // Minor - no win notification
            class'DKMessageManager'.static.SendMinor(KFPC, WinMessage);
        }
    }
}

// Reset on wave end
function WaveEnd()
{
    KillCountThisWave = 0;
}

defaultproperties
{
    bDeluxe=False
    UpgradeLevel=1
    KillCountThisWave=0

    Name="Default__DKUpgrade_Skill_HouseEdge_Helper"
}