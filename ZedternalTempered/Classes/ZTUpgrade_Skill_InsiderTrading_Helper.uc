class ZTUpgrade_Skill_InsiderTrading_Helper extends Info transient;

var KFPawn_Human Player;
var bool bDeluxe;
var int UpgradeLevel;
var array< class<KFPawn_Monster> > ZedTypesKilledThisWave;

function PostBeginPlay()
{
    super.PostBeginPlay();

    Player = KFPawn_Human(Owner);
    if (Player == None || Player.Health <= 0)
        Destroy();
    else
        ZedTypesKilledThisWave.Length = 0;
}

function OnEnemyKilled(KFPawn_Monster KilledZed)
{
    local class<KFPawn_Monster> ZedType;
    
    if (KilledZed == None) return;
    
    ZedType = KilledZed.Class;
    
    // Add to our list if not already present
    if (ZedTypesKilledThisWave.Find(ZedType) == INDEX_NONE)
    {
        ZedTypesKilledThisWave.AddItem(ZedType);
    }
}

function PayoutWaveBonus()
{
    local KFPlayerController KFPC;
    local KFPlayerReplicationInfo KFPRI;
    local int DoshPerType, TotalBonus;
    local string ZedTypesList;
    local int i;
    
    if (ZedTypesKilledThisWave.Length == 0) return;
    
    // Calculate bonus
    DoshPerType = class'ZTUpgrade_Skill_InsiderTrading'.default.DoshPerZedType[UpgradeLevel - 1];
    TotalBonus = ZedTypesKilledThisWave.Length * DoshPerType;
    
    // Give bonus dosh
    KFPC = KFPlayerController(Player.Controller);
    if (KFPC != None)
    {
        KFPRI = KFPlayerReplicationInfo(KFPC.PlayerReplicationInfo);
        if (KFPRI != None)
        {
            KFPRI.AddDosh(TotalBonus);
            
            // Build message with zed types
            ZedTypesList = "";
            for (i = 0; i < ZedTypesKilledThisWave.Length; i++)
            {
                if (i > 0) ZedTypesList $= ", ";
                ZedTypesList $= GetZedTypeName(ZedTypesKilledThisWave[i]);
            }
            
            class'ZTMessageManager'.static.SendCritical(KFPC, "INSIDER TRADING PAYOUT: +" $ TotalBonus $ " Dosh for " $ ZedTypesKilledThisWave.Length $ " types (" $ ZedTypesList $ ")");
        }
    }
    
    // Reset for next wave
    ZedTypesKilledThisWave.Length = 0;
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

defaultproperties
{
    bDeluxe=False
    UpgradeLevel=1

    Name="Default__ZTUpgrade_Skill_InsiderTrading_Helper"
}