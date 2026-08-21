class ZTUpgrade_Skill_MercenaryContract_Helper extends Info transient;

var KFPawn_Human Player;
var bool bDeluxe;
var int UpgradeLevel;
var class<KFPawn_Monster> LastKilledZedType;
var int ConsecutiveKills;

function PostBeginPlay()
{
    super.PostBeginPlay();

    Player = KFPawn_Human(Owner);
    if (Player == None || Player.Health <= 0)
        Destroy();
    else
    {
        ConsecutiveKills = 0;
        LastKilledZedType = None;
    }
}

function OnEnemyKilled(KFPawn_Monster KilledZed)
{
    local KFPlayerController KFPC;
    local KFPlayerReplicationInfo KFPRI;
    local class<KFPawn_Monster> CurrentZedType;
    local int KillsNeeded, DoshReward;
    
    if (KilledZed == None) return;
    
    CurrentZedType = KilledZed.Class;
    
    // Check if this is the same type as last kill
    if (LastKilledZedType == CurrentZedType)
    {
        ConsecutiveKills++;
    }
    else
    {
        // Different type, reset counter
        ConsecutiveKills = 1;
        LastKilledZedType = CurrentZedType;
    }
    
    // Check if we've reached the required consecutive kills
    KillsNeeded = class'ZTUpgrade_Skill_MercenaryContract'.default.KillsRequired[UpgradeLevel - 1];
    
    if (ConsecutiveKills >= KillsNeeded)
    {
        // Contract completed! Give reward
        DoshReward = class'ZTUpgrade_Skill_MercenaryContract'.default.DoshReward[UpgradeLevel - 1];
        
        KFPC = KFPlayerController(Player.Controller);
        if (KFPC != None)
        {
            KFPRI = KFPlayerReplicationInfo(KFPC.PlayerReplicationInfo);
            if (KFPRI != None)
            {
                KFPRI.AddDosh(DoshReward);
                class'ZTMessageManager'.static.SendCritical(KFPC, "MERCENARY CONTRACT COMPLETED! +" $ DoshReward $ " Dosh for " $ KillsNeeded $ " " $ GetZedTypeName(CurrentZedType) $ " kills!");
            }
        }
        
        // Reset for next contract
        ConsecutiveKills = 0;
        LastKilledZedType = None;
    }
}

function string GetZedTypeName(class<KFPawn_Monster> ZedType)
{
    local string ZedName, CleanName;
    
    ZedName = string(ZedType);
    
    // Extract just the zed name from the full class path
    if (InStr(ZedName, "KFPawn_Zed") != -1)
    {
        CleanName = Mid(ZedName, InStr(ZedName, "KFPawn_Zed") + 10);
    }
    else if (InStr(ZedName, "WMPawn_Zed") != -1)
    {
        CleanName = Mid(ZedName, InStr(ZedName, "WMPawn_Zed") + 10);
    }
    else if (InStr(ZedName, "Zed") != -1)
    {
        CleanName = Mid(ZedName, InStr(ZedName, "Zed") + 3);
    }
    else
    {
        CleanName = ZedName; // Fallback to full name
    }
    
    // Handle special cases for cleaner names
    if (CleanName ~= "BloatKing")
        CleanName = "Bloat King";
    else if (CleanName ~= "FleshpoundKing")
        CleanName = "Fleshpound King";
    else if (CleanName ~= "FleshpoundMini")
        CleanName = "Quarter Pound";
    else if (CleanName ~= "HuskCannon")
        CleanName = "Husk Cannon";
    else if (CleanName ~= "DAR_EMP")
        CleanName = "E.D.A.R Trapper";
    else if (CleanName ~= "DAR_Laser")
        CleanName = "E.D.A.R Blaster";
    else if (CleanName ~= "DAR_Rocket")
        CleanName = "E.D.A.R Bomber";
    
    return CleanName;
}

// Reset on wave end
function WaveEnd()
{
    ConsecutiveKills = 0;
    LastKilledZedType = None;
}

defaultproperties
{
    bDeluxe=False
    UpgradeLevel=1
    ConsecutiveKills=0
    LastKilledZedType=None

    Name="Default__ZTUpgrade_Skill_MercenaryContract_Helper"
}