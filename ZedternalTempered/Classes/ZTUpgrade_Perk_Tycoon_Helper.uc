class ZTUpgrade_Perk_Tycoon_Helper extends Info transient;

var int TycoonUpgradeLevel;

// Wealth accumulation tracking (2500 dosh earned = +50 bonus per wave)
var int DoshToDisplay;
var int TotalDoshEarned;
var int TotalPortfolioMilestones;
var const int MaxDoshToDisplay;
var const int BonusDoshPerMilestone;
var const float DoshDisplayDuration;

// Dosh polling system
var int LastKnownDosh;
var float DoshCheckInterval;
var float LastDoshCheckTime;
var bool bIgnoreNextDoshIncrease;
var int ExpectedTycoonDosh;

// EXPLOIT FIX: Throw buffer — always active regardless of trader state.
// Any dosh decrease (throw OR purchase) is added to this buffer.
// Any real dosh increase first absorbs from the buffer before being counted
// toward portfolio milestones, neutralising throw-then-pickup cycles everywhere.
// The buffer is cleared when the trader closes (= wave start) so that
// purchase-accumulated buffer from trader time never bleeds into the wave.
var int ThrowBuffer;

// Tracks trader state from the previous poll to detect the close transition.
var bool bWasTraderOpen;

// Wealth source tracking
var int DoshFromStipends;
var int DoshFromInterest;
var int DoshFromTakeovers;
var int DoshFromRefunds;

// Sound events
var const name TycoonSoundRTPCName;
var const AkEvent DoshTrackSound;
var const AkEvent MilestoneSound;
var const AkEvent InterestSound;
var const AkEvent TakeoverSound;

function InitializeHelper(int UpgradeLevel)
{
    TycoonUpgradeLevel = UpgradeLevel;

    DoshToDisplay = 0;
    TotalDoshEarned = 0;
    TotalPortfolioMilestones = 0;
    ThrowBuffer = 0;
    bWasTraderOpen = IsTraderOpen();

    LastKnownDosh = GetCurrentPlayerDosh();
    LastDoshCheckTime = Owner.WorldInfo.TimeSeconds;
    DoshCheckInterval = 1.0f;
    bIgnoreNextDoshIncrease = false;
    ExpectedTycoonDosh = 0;

    SetTickIsDisabled(false);
}

function PostBeginPlay()
{
    super.PostBeginPlay();

    if (Owner == None)
        Destroy();
}

function Tick(float DeltaTime)
{
    local float CurrentTime;

    if (Owner == None)
    {
        Destroy();
        return;
    }

    CurrentTime = Owner.WorldInfo.TimeSeconds;

    if (CurrentTime - LastDoshCheckTime >= DoshCheckInterval)
    {
        CheckForRealDoshChanges();
        LastDoshCheckTime = CurrentTime;
    }
}

function Timer()
{
    if (Owner == None)
    {
        Destroy();
        return;
    }

    if (DoshToDisplay > 0)
    {
        DoshToDisplay = 0;
        UpdateDoshDisplay(DoshToDisplay, False);
    }
}

function bool IsTraderOpen()
{
    local KFGameReplicationInfo KFGRI;

    KFGRI = KFGameReplicationInfo(Owner.WorldInfo.GRI);
    return (KFGRI != None && KFGRI.bTraderIsOpen);
}

function CheckForRealDoshChanges()
{
    local int CurrentDosh, DoshChange, AbsorbAmount, CountableChange, ClawbackAmount;
    local bool bCurrentTraderOpen;
    local float DiscountRate;
    local KFPawn_Human OwnerPawn;
    local KFPlayerReplicationInfo KFPRI;

    bCurrentTraderOpen = IsTraderOpen();

    // Detect the trader-close transition (= wave start).
    // Clear ThrowBuffer so any purchases made during trader time do not
    // accidentally absorb kill dosh earned in the upcoming wave.
    if (bWasTraderOpen && !bCurrentTraderOpen)
    {
        `log("Tycoon: Trader closed (wave start) — clearing ThrowBuffer of" @ ThrowBuffer);
        ThrowBuffer = 0;
    }
    bWasTraderOpen = bCurrentTraderOpen;

    CurrentDosh = GetCurrentPlayerDosh();
    DoshChange = CurrentDosh - LastKnownDosh;

    if (DoshChange > 0)
    {
        // Self-generated dosh (stipend / interest / takeover / refund) — ignore.
        if (bIgnoreNextDoshIncrease && DoshChange <= ExpectedTycoonDosh)
        {
            bIgnoreNextDoshIncrease = false;
            ExpectedTycoonDosh = 0;
            `log("Tycoon: Ignored self-generated dosh:" @ DoshChange);
        }
        else
        {
            // Real incoming dosh (kill, pickup, sale, etc.).
            // Absorb from ThrowBuffer first.  This neutralises throw-then-pickup
            // cycles so picking dosh up off the floor never contributes to milestones.
            CountableChange = DoshChange;

            if (ThrowBuffer > 0)
            {
                AbsorbAmount = Min(CountableChange, ThrowBuffer);
                ThrowBuffer -= AbsorbAmount;
                CountableChange -= AbsorbAmount;
                `log("Tycoon: ThrowBuffer absorbed" @ AbsorbAmount @ "— buffer remaining:" @ ThrowBuffer);

                // EXPLOIT FIX: Claw back refund that was given on thrown dosh.
                // When a player threw money during trader time, ApplyPurchaseRefund
                // fired on the decrease. Now that the dosh is picked back up, we
                // deduct the refund that was given on the absorbed (thrown) amount.
                if (bCurrentTraderOpen && AbsorbAmount > 0 && TycoonUpgradeLevel > 0)
                {
                    DiscountRate = class'ZTUpgrade_Perk_Tycoon'.default.BulkDiscount * TycoonUpgradeLevel;
                    ClawbackAmount = int(float(AbsorbAmount) * DiscountRate);

                    if (ClawbackAmount > 0)
                    {
                        OwnerPawn = KFPawn_Human(Owner);
                        if (OwnerPawn != None)
                        {
                            KFPRI = KFPlayerReplicationInfo(OwnerPawn.PlayerReplicationInfo);
                            if (KFPRI != None)
                            {
                                // Don't claw back more than the player has
                                ClawbackAmount = Min(ClawbackAmount, KFPRI.Score);
                                if (ClawbackAmount > 0)
                                {
                                    KFPRI.AddDosh(-ClawbackAmount);
                                    DoshFromRefunds -= ClawbackAmount;
                                    // Adjust our local copy so LastKnownDosh stays correct
                                    CurrentDosh -= ClawbackAmount;
                                    `log("Tycoon: Clawback refund" @ ClawbackAmount @ "on absorbed throw of" @ AbsorbAmount);
                                }
                            }
                        }
                    }
                }
            }

            if (CountableChange > 0)
            {
                TrackRealDoshEarned(CountableChange);
                `log("Tycoon: Tracked real dosh gain:" @ CountableChange @ "Total:" @ TotalDoshEarned);
            }
        }
    }
    else if (DoshChange < 0)
    {
        // Any dosh decrease is buffered unconditionally — throw, purchase, or otherwise.
        // If the dosh comes back (pickup), the buffer absorbs it and claws back the refund.
        // If it doesn't come back (legitimate purchase), the buffer clears at wave start.
        ThrowBuffer += (-DoshChange);
        `log("Tycoon: Dosh decreased by" @ (-DoshChange) @ "— ThrowBuffer now:" @ ThrowBuffer);

        // Purchase refund applies during trader time.
        // If this was actually a throw, the clawback above will recoup the refund
        // when the dosh is picked back up.
        if (bCurrentTraderOpen)
        {
            ApplyPurchaseRefund(-DoshChange);
        }
    }

    LastKnownDosh = CurrentDosh;
}

function TrackRealDoshEarned(int DoshAmount)
{
    local bool bReachedMilestone;
    local int PreviousMilestones;

    if (DoshAmount <= 0) return;

    PreviousMilestones = TotalPortfolioMilestones;

    ClearTimer('HideDoshDisplay');

    TotalDoshEarned += DoshAmount;

    DoshToDisplay = TotalDoshEarned % MaxDoshToDisplay;
    if (DoshToDisplay == 0)
        DoshToDisplay = MaxDoshToDisplay;

    TotalPortfolioMilestones = TotalDoshEarned / MaxDoshToDisplay;
    bReachedMilestone = (TotalPortfolioMilestones > PreviousMilestones);

    if (bReachedMilestone)
    {
        ApplyPortfolioMilestone();
        DoshToDisplay = 0;
        UpdateDoshDisplay(DoshToDisplay, True);
    }
    else
    {
        UpdateDoshDisplay(DoshToDisplay, False);
        SetTimer(DoshDisplayDuration, False, 'HideDoshDisplay');
    }
}

function int GetCurrentPlayerDosh()
{
    local KFPawn_Human OwnerPawn;
    local KFPlayerController KFPC;
    local KFPlayerReplicationInfo KFPRI;

    OwnerPawn = KFPawn_Human(Owner);
    if (OwnerPawn == None) return 0;

    KFPC = KFPlayerController(OwnerPawn.Controller);
    if (KFPC == None) return 0;

    KFPRI = KFPlayerReplicationInfo(KFPC.PlayerReplicationInfo);
    if (KFPRI == None) return 0;

    return KFPRI.Score;
}

function GiveTycoonDosh(int Amount, string Source)
{
    local KFPawn_Human OwnerPawn;
    local KFPlayerController KFPC;
    local KFPlayerReplicationInfo KFPRI;

    if (Amount <= 0) return;

    OwnerPawn = KFPawn_Human(Owner);
    if (OwnerPawn == None) return;

    KFPC = KFPlayerController(OwnerPawn.Controller);
    if (KFPC == None) return;

    KFPRI = KFPlayerReplicationInfo(KFPC.PlayerReplicationInfo);
    if (KFPRI == None) return;

    ExpectedTycoonDosh += Amount;
    bIgnoreNextDoshIncrease = true;

    KFPRI.AddDosh(Amount);

    if (Source ~= "Round Stipend")
        DoshFromStipends += Amount;
    else if (Source ~= "Compound Interest")
        DoshFromInterest += Amount;
    else if (Source ~= "Hostile Takeover")
        DoshFromTakeovers += Amount;
    else if (Source ~= "Purchase Refund")
        DoshFromRefunds += Amount;

    `log("Tycoon: Gave" @ Amount @ "dosh as" @ Source);
}

// Only called when trader is confirmed open (see CheckForRealDoshChanges).
function ApplyPurchaseRefund(int PurchaseAmount)
{
    local KFPlayerController KFPC;
    local float RefundAmount, DiscountRate;
    local KFPawn_Human OwnerPawn;

    if (PurchaseAmount <= 0) return;

    OwnerPawn = KFPawn_Human(Owner);
    if (OwnerPawn == None) return;

    KFPC = KFPlayerController(OwnerPawn.Controller);
    if (KFPC == None) return;

    if (TycoonUpgradeLevel <= 0) return;

    DiscountRate = class'ZTUpgrade_Perk_Tycoon'.default.BulkDiscount * TycoonUpgradeLevel;
    RefundAmount = float(PurchaseAmount) * DiscountRate;

    if (RefundAmount >= 1.0f)
    {
        GiveTycoonDosh(int(RefundAmount), "Purchase Refund");
        KFPC.ClientMessage("TYCOON DISCOUNT: +" $ int(RefundAmount) $ " Dosh refund (" $ int(DiscountRate * 100) $ "% on " $ PurchaseAmount $ " purchase)", 'Event');
    }
}

function ApplyPortfolioMilestone()
{
    local KFPlayerController KFPC;
    local ZTHudWrapper TycoonHUD;
    local string MilestoneMessage;

    KFPC = KFPlayerController(GetALocalPlayerController());
    if (KFPC != None)
    {
        MilestoneMessage = "PORTFOLIO MILESTONE #" $ TotalPortfolioMilestones $ ": +" $
                          BonusDoshPerMilestone $ " Dosh per wave!";
        KFPC.ClientMessage(MilestoneMessage, 'CriticalEvent');

        TycoonHUD = class'ZTHudWrapper'.static.GetReaperHUD(KFPC);
        if (TycoonHUD != None)
            TycoonHUD.ShowEvolutionPanel(false, 8.0f);

        if (MilestoneSound != None)
            KFPC.PlayRMEffect(MilestoneSound, TycoonSoundRTPCName, TotalPortfolioMilestones);
    }

    UpdatePortfolioDisplay();
}

function HideDoshDisplay()
{
    if (DoshToDisplay > 0)
    {
        DoshToDisplay = 0;
        UpdateDoshDisplay(DoshToDisplay, False);
    }
}

reliable client function UpdateDoshDisplay(int CurrentDosh, bool bMilestoneComplete)
{
    local KFPlayerController KFPC;
    local ZTHudWrapper TycoonHUD;
    local AkEvent TempAkEvent;

    KFPC = KFPlayerController(GetALocalPlayerController());
    if (KFPC == None) return;

    TycoonHUD = class'ZTHudWrapper'.static.GetReaperHUD(KFPC);
    if (TycoonHUD != None)
        TycoonHUD.UpdateTycoonPortfolio(CurrentDosh, MaxDoshToDisplay, bMilestoneComplete);
    else if (KFPC.MyGFxHUD != None)
        KFPC.UpdateRhythmCounterWidget(CurrentDosh, MaxDoshToDisplay);

    if (bMilestoneComplete)
        TempAkEvent = MilestoneSound;
    else if (CurrentDosh > 0)
        TempAkEvent = DoshTrackSound;

    if (TempAkEvent != None)
        KFPC.PlayRMEffect(TempAkEvent, TycoonSoundRTPCName, CurrentDosh);
}

reliable client function UpdatePortfolioDisplay()
{
    local KFPlayerController KFPC;
    local ZTHudWrapper TycoonHUD;
    local string PortfolioSummary;

    KFPC = KFPlayerController(GetALocalPlayerController());
    if (KFPC == None) return;

    TycoonHUD = class'ZTHudWrapper'.static.GetReaperHUD(KFPC);
    if (TycoonHUD != None && TotalPortfolioMilestones > 0)
    {
        PortfolioSummary = GetPortfolioSummary();
        TycoonHUD.UpdateTycoonPortfolioBonuses(TotalPortfolioMilestones, PortfolioSummary);
    }
}

function int GetDoshProgress()
{
    return DoshToDisplay;
}

function int GetBonusDoshPerWave()
{
    return TotalPortfolioMilestones * BonusDoshPerMilestone;
}

function string GetPortfolioSummary()
{
    local string Summary;
    local int BonusPerWave;

    BonusPerWave = GetBonusDoshPerWave();
    Summary = "Milestones: " $ TotalPortfolioMilestones $ " | +" $ BonusPerWave $ " per wave";
    Summary $= " | Total Earned: " $ TotalDoshEarned;
    return Summary;
}

function string GetDoshBreakdown()
{
    local string Breakdown;

    Breakdown = "TYCOON WEALTH REPORT:";
    Breakdown $= "|Stipends: " $ DoshFromStipends;
    Breakdown $= "|Interest: " $ DoshFromInterest;
    Breakdown $= "|Takeovers: " $ DoshFromTakeovers;
    Breakdown $= "|Refunds: " $ DoshFromRefunds;
    Breakdown $= "|External: " $ TotalDoshEarned;
    return Breakdown;
}

function TrackKill(optional KFPawn_Monster KilledMonster, optional int UpgradeLevel = 0)
{
    // Kill tracking no longer needed — real dosh polling handles everything
}

function PlayInterestSound(int InterestAmount)
{
    local KFPlayerController KFPC;

    KFPC = KFPlayerController(GetALocalPlayerController());
    if (KFPC != None && InterestSound != None)
        KFPC.PlayRMEffect(InterestSound, TycoonSoundRTPCName, InterestAmount);
}

function PlayTakeoverSound(int TakeoverAmount)
{
    local KFPlayerController KFPC;

    KFPC = KFPlayerController(GetALocalPlayerController());
    if (KFPC != None && TakeoverSound != None)
        KFPC.PlayRMEffect(TakeoverSound, TycoonSoundRTPCName, TakeoverAmount);
}

defaultproperties
{
    MaxDoshToDisplay=2500
    BonusDoshPerMilestone=50
    DoshDisplayDuration=5.0f
    ThrowBuffer=0
    bWasTraderOpen=false

    TycoonSoundRTPCName="Tycoon_Wealth"
    DoshTrackSound=AkEvent'WW_UI_PlayerCharacter.Play_R_Method_Hit'
    MilestoneSound=AkEvent'WW_UI_PlayerCharacter.Play_R_Method_Top'
    InterestSound=AkEvent'WW_UI_PlayerCharacter.Play_R_Method_Hit'
    TakeoverSound=AkEvent'WW_UI_PlayerCharacter.Play_R_Method_Top'

    Name="Default__ZTUpgrade_Perk_Tycoon_Helper"
}
