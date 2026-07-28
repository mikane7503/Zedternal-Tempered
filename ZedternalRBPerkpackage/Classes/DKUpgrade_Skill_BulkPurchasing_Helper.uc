class DKUpgrade_Skill_BulkPurchasing_Helper extends Info
    transient;

var KFPawn_Human Player;
var bool bDeluxe;
var int UpgradeLevel;
var int LastKnownDosh;
var array<int> PurchasesThisTraderVisit;
var bool bInTraderRange;
var float TraderCheckInterval;
var float LastTraderCheck;

function PostBeginPlay()
{
    super.PostBeginPlay();

    Player = KFPawn_Human(Owner);
    if (Player == None || Player.Health <= 0)
        Destroy();
    else
    {
        LastKnownDosh = GetCurrentPlayerDosh();
        SetTimer(TraderCheckInterval, True);
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
    
    // Check trader proximity and purchases
    if (CurrentTime - LastTraderCheck >= TraderCheckInterval)
    {
        CheckTraderProximityAndPurchases();
        LastTraderCheck = CurrentTime;
    }
}

function CheckTraderProximityAndPurchases()
{
    local bool bWasInRange, bCurrentlyInRange;
    local int CurrentDosh, DoshSpent;
    
    bWasInRange = bInTraderRange;
    bCurrentlyInRange = IsNearTrader();
    
    CurrentDosh = GetCurrentPlayerDosh();
    DoshSpent = LastKnownDosh - CurrentDosh;
    
    // Check if player entered trader range
    if (!bWasInRange && bCurrentlyInRange)
    {
        // Entered trader - reset purchase tracking
        PurchasesThisTraderVisit.Length = 0;
    }
    
    // Check if player left trader range
    if (bWasInRange && !bCurrentlyInRange)
    {
        // Left trader - apply bulk discount if applicable
        ApplyBulkDiscount();
        PurchasesThisTraderVisit.Length = 0;
    }
    
    // Track purchases while in trader range
    if (bCurrentlyInRange && DoshSpent > 0)
    {
        PurchasesThisTraderVisit.AddItem(DoshSpent);
    }
    
    bInTraderRange = bCurrentlyInRange;
    LastKnownDosh = CurrentDosh;
}

function bool IsNearTrader()
{
    local KFTraderTrigger Trader;
    local float DistanceSq;
    
    // Find nearest trader
    foreach Player.WorldInfo.DynamicActors(class'KFTraderTrigger', Trader)
    {
        DistanceSq = VSizeSQ(Player.Location - Trader.Location);
        if (DistanceSq <= Square(500.0f)) // Trader proximity range
        {
            return true;
        }
    }
    
    return false;
}

function ApplyBulkDiscount()
{
    local int TotalPurchases, i;
    local float RefundRate, TotalRefund;
    local KFPlayerController KFPC;
    local KFPlayerReplicationInfo KFPRI;
    
    TotalPurchases = PurchasesThisTraderVisit.Length;
    
    if (TotalPurchases <= 1) return; // No bulk discount for single purchases
    
    // Calculate refund: percentage off each additional item (skip first item)
    RefundRate = class'DKUpgrade_Skill_BulkPurchasing'.default.RefundPercentage[UpgradeLevel - 1];
    TotalRefund = 0.0f;
    
    // Start from index 1 to skip the first purchase (no discount on first item)
    for (i = 1; i < PurchasesThisTraderVisit.Length; i++)
    {
        TotalRefund += float(PurchasesThisTraderVisit[i]) * RefundRate;
    }
    
    if (TotalRefund >= 1.0f)
    {
        KFPC = KFPlayerController(Player.Controller);
        if (KFPC != None)
        {
            KFPRI = KFPlayerReplicationInfo(KFPC.PlayerReplicationInfo);
            if (KFPRI != None)
            {
                KFPRI.AddDosh(int(TotalRefund));
                class'DKMessageManager'.static.SendImportant(KFPC, "BULK PURCHASING DISCOUNT: +" $ int(TotalRefund) $ " Dosh refund (" $ RefundRate*100 $ "% off " $ (TotalPurchases-1) $ " additional items)");
            }
        }
    }
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

// Reset on wave end
function WaveEnd()
{
    PurchasesThisTraderVisit.Length = 0;
}

defaultproperties
{
    bDeluxe=False
    UpgradeLevel=1
    TraderCheckInterval=0.5f
    bInTraderRange=False

    Name="Default__DKUpgrade_Skill_BulkPurchasing_Helper"
}