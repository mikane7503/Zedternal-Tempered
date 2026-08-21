class ZTUpgrade_Skill_TaxLoopholes_Helper extends Info transient;

var KFPawn_Human Player;
var bool bDeluxe;
var int UpgradeLevel;
var int LastKnownDosh;
var int TotalDoshSpent;
var int LastRefundMilestone;
var float DoshCheckInterval;

// EXPLOIT FIX: Throw buffer — always active regardless of trader state.
// Any dosh decrease is tracked here. If dosh comes back up (pickup),
// the buffer absorbs it AND retroactively un-counts that amount from
// TotalDoshSpent so that throw-then-pickup loops never feed milestones.
// Buffer clears when the trader closes (= wave start) via bWasTraderOpen.
var int ThrowBuffer;

// Tracks trader state from previous poll to detect the close transition.
var bool bWasTraderOpen;

function PostBeginPlay()
{
    super.PostBeginPlay();

    Player = KFPawn_Human(Owner);
    if (Player == None || Player.Health <= 0)
        Destroy();
    else
    {
        LastKnownDosh = GetCurrentPlayerDosh();
        TotalDoshSpent = 0;
        LastRefundMilestone = 0;
        ThrowBuffer = 0;
        bWasTraderOpen = IsTraderOpen();
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

    CheckForSpending();
}

function bool IsTraderOpen()
{
    local KFGameReplicationInfo KFGRI;

    KFGRI = KFGameReplicationInfo(Player.WorldInfo.GRI);
    return (KFGRI != None && KFGRI.bTraderIsOpen);
}

function CheckForSpending()
{
    local int CurrentDosh, DoshDelta;
    local int SpendingThreshold, RefundAmount;
    local int NewMilestones, RefundsToGive, i;
    local int AbsorbAmount, UncountAmount;
    local bool bCurrentTraderOpen;
    local KFPlayerController KFPC;
    local KFPlayerReplicationInfo KFPRI;

    bCurrentTraderOpen = IsTraderOpen();

    // Detect trader-close transition (= wave start).
    // Clear ThrowBuffer so accumulated purchase/throw buffer from trader time
    // does not wrongly un-count spending tracked in future waves.
    if (bWasTraderOpen && !bCurrentTraderOpen)
    {
        `log("TaxLoopholes: Trader closed (wave start) — clearing ThrowBuffer of" @ ThrowBuffer);
        ThrowBuffer = 0;
    }
    bWasTraderOpen = bCurrentTraderOpen;

    CurrentDosh = GetCurrentPlayerDosh();
    DoshDelta = LastKnownDosh - CurrentDosh; // Positive = dosh was lost

    if (DoshDelta > 0)
    {
        // Dosh decreased — throw, purchase, or otherwise.
        // Buffer it unconditionally; if it comes back (pickup) we un-count it.
        ThrowBuffer += DoshDelta;
        TotalDoshSpent += DoshDelta;

        // Check for new milestones
        SpendingThreshold = class'ZTUpgrade_Skill_TaxLoopholes'.default.SpendingThreshold;
        NewMilestones = TotalDoshSpent / SpendingThreshold;

        if (NewMilestones > LastRefundMilestone)
        {
            RefundsToGive = NewMilestones - LastRefundMilestone;
            RefundAmount = class'ZTUpgrade_Skill_TaxLoopholes'.default.TaxRefundAmount[UpgradeLevel - 1];

            KFPC = KFPlayerController(Player.Controller);
            if (KFPC != None)
            {
                KFPRI = KFPlayerReplicationInfo(KFPC.PlayerReplicationInfo);
                if (KFPRI != None)
                {
                    for (i = 0; i < RefundsToGive; i++)
                    {
                        NotifyTycoonOfExternalDosh(KFPC, RefundAmount);
                        KFPRI.AddDosh(RefundAmount);
                    }

                    if (RefundsToGive == 1)
                        class'ZTMessageManager'.static.SendCritical(KFPC, "TAX LOOPHOLE ACTIVATED! +" $ RefundAmount $ " Dosh refund (milestone " $ NewMilestones $ ")");
                    else
                        class'ZTMessageManager'.static.SendCritical(KFPC, "TAX LOOPHOLES ACTIVATED! +" $ (RefundAmount * RefundsToGive) $ " Dosh refunds (" $ RefundsToGive $ " milestones)");

                    class'ZTMessageManager'.static.SendMinor(KFPC, "Total Spent: " $ TotalDoshSpent $ " | Next Refund at: " $ ((NewMilestones + 1) * SpendingThreshold));
                }
            }

            LastRefundMilestone = NewMilestones;
        }
    }
    else if (DoshDelta < 0)
    {
        // Dosh increased — could be a kill, a pickup, or a weapon sale.
        // If ThrowBuffer > 0, some or all of this increase is returning thrown
        // dosh. Absorb from the buffer and un-count the same amount from
        // TotalDoshSpent so the throw never contributes to milestones.
        if (ThrowBuffer > 0)
        {
            AbsorbAmount = Min(-DoshDelta, ThrowBuffer);
            ThrowBuffer -= AbsorbAmount;

            // Un-count the absorbed amount from spending so milestone progress
            // is correctly reversed for the throw portion.
            UncountAmount = Min(AbsorbAmount, TotalDoshSpent);
            TotalDoshSpent -= UncountAmount;

            // If we crossed milestone boundaries downward, walk LastRefundMilestone
            // back to match so we don't double-fire milestones later.
            SpendingThreshold = class'ZTUpgrade_Skill_TaxLoopholes'.default.SpendingThreshold;
            LastRefundMilestone = TotalDoshSpent / SpendingThreshold;

            `log("TaxLoopholes: Pickup absorbed" @ AbsorbAmount @ "from ThrowBuffer — TotalDoshSpent reduced to" @ TotalDoshSpent);
        }
    }

    LastKnownDosh = CurrentDosh;
}

// If the player also has Tycoon active, register the incoming dosh so the
// Tycoon helper ignores it and does not count it toward Portfolio Growth.
function NotifyTycoonOfExternalDosh(KFPlayerController KFPC, int Amount)
{
    local ZTUpgrade_Perk_Tycoon_Helper TycoonHelper;

    if (KFPC == None || Amount <= 0 || KFPC.Pawn == None) return;

    foreach KFPC.Pawn.ChildActors(class'ZTUpgrade_Perk_Tycoon_Helper', TycoonHelper)
    {
        TycoonHelper.ExpectedTycoonDosh += Amount;
        TycoonHelper.bIgnoreNextDoshIncrease = true;
        break;
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

function WaveEnd()
{
    // Tax tracking persists across waves - no reset needed
}

defaultproperties
{
    bDeluxe=False
    UpgradeLevel=1
    DoshCheckInterval=0.5f
    TotalDoshSpent=0
    LastRefundMilestone=0
    ThrowBuffer=0
    bWasTraderOpen=false

    Name="Default__ZTUpgrade_Skill_TaxLoopholes_Helper"
}
