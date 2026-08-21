class ZTUpgrade_Perk_Tycoon extends ZTUpgrade_Perk config(ZedternalUnlimited);

// Theme: "Tycoon" - A business mogul who accumulates wealth and leverages financial power
// Special mechanics: Dosh tracking, round stipends, trader discounts, compound interest

// Linear bonuses per level (1-20)
var config float RoundStipend;            // Dosh bonus at start of each wave per level
var config float BulkDiscount;            // Trader price reduction per level
var config float CostCutting;             // Weapon upgrade cost reduction per level

// Level 10 special bonus - Compound Interest
var config float CompoundInterestRate;    // Interest rate on current dosh at wave end

// Level 20 special bonus - Hostile Takeover
var config float HostileTakeoverRate;     // Percentage of teammates' dosh gained from boss kills
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.RoundStipend = 25.0f;
		default.BulkDiscount = 0.02f;
		default.CostCutting = 0.01f;
		default.CompoundInterestRate = 0.10f;
		default.HostileTakeoverRate = 0.25f;

		// BEGIN TEMPERED INI DEFAULTS (generated; do not edit by hand)
		default.RoundStipend = 20.000000f;
		default.BulkDiscount = 0.008000f;
		default.CostCutting = 0.010000f;
		default.CompoundInterestRate = 0.100000f;
		default.HostileTakeoverRate = 0.200000f;
		// END TEMPERED INI DEFAULTS
		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}


// ===================================================================
// WAVE END SYSTEM
// ===================================================================

static function WaveEnd(int upgLevel, KFPlayerController KFPC)
{
    local KFPlayerReplicationInfo KFPRI;
    local int CurrentDosh, InterestAmount, StipendAmount, MilestoneBonus;
    local ZTUpgrade_Perk_Tycoon_Helper TycoonHelper;
    
    if (KFPC == None || upgLevel <= 0) return;
    
    KFPRI = KFPlayerReplicationInfo(KFPC.PlayerReplicationInfo);
    if (KFPRI == None) return;
    
    if (KFPC.Pawn == None || !KFPC.Pawn.IsAliveAndWell()) return;
    
    TycoonHelper = GetHelper(KFPC.Pawn);
    if (TycoonHelper == None) return;
    
    // 1. Apply round stipend for the NEXT wave
    StipendAmount = int(default.RoundStipend * upgLevel);
    if (StipendAmount > 0)
    {
        TycoonHelper.GiveTycoonDosh(StipendAmount, "Round Stipend");
        KFPC.ClientMessage("ROUND STIPEND: +" $ StipendAmount $ " Dosh for next wave!", 'Event');
    }
    
    // 2. Apply portfolio milestone bonus dosh per wave
    MilestoneBonus = TycoonHelper.GetBonusDoshPerWave();
    if (MilestoneBonus > 0)
    {
        TycoonHelper.GiveTycoonDosh(MilestoneBonus, "Portfolio Bonus");
        KFPC.ClientMessage("PORTFOLIO BONUS: +" $ MilestoneBonus $ " Dosh from " $ TycoonHelper.TotalPortfolioMilestones $ " milestones!", 'Event');
    }
    
    // 3. Apply compound interest (Level 10+)
    if (upgLevel >= class'ZTConfig_Capstone'.default.Capstone_Rank1Level)
    {
        CurrentDosh = KFPRI.Score;
        InterestAmount = int(float(CurrentDosh) * default.CompoundInterestRate);
        
        if (InterestAmount > 0)
        {
            TycoonHelper.GiveTycoonDosh(InterestAmount, "Compound Interest");
            KFPC.ClientMessage("COMPOUND INTEREST: +" $ InterestAmount $ " Dosh! (10% of " $ CurrentDosh $ ")", 'CriticalEvent');
            TycoonHelper.PlayInterestSound(InterestAmount);
        }
    }
}

// ===================================================================
// HOSTILE TAKEOVER SYSTEM
// ===================================================================

static function ModifyDamageGiven(out int InDamage, int DefaultDamage, int upgLevel, optional Actor DamageCauser, optional KFPawn_Monster MyKFPM, optional KFPlayerController DamageInstigator, optional class<KFDamageType> DamageType, optional int HitZoneIdx, optional KFWeapon MyKFW)
{
    local ZTUpgrade_Perk_Tycoon_Helper TycoonHelper;
    
    if (MyKFPM == None || DamageInstigator == None) return;
    
    if (InDamage >= MyKFPM.Health && DamageInstigator.Pawn != None)
    {
        TycoonHelper = GetHelper(DamageInstigator.Pawn);
        if (TycoonHelper != None)
        {
            if (upgLevel >= class'ZTConfig_Capstone'.default.Capstone_Rank2Level && MyKFPM.static.IsABoss())
            {
                ApplyHostileTakeover(DamageInstigator, upgLevel, TycoonHelper);
            }
            
            TycoonHelper.TrackKill(MyKFPM, upgLevel);
        }
    }
}

static function ApplyHostileTakeover(KFPlayerController KFPC, int upgLevel, ZTUpgrade_Perk_Tycoon_Helper TycoonHelper)
{
    local KFPlayerController TeammatePCs;
    local KFPlayerReplicationInfo TeammatePRI;
    local int TotalTeammateDosh, TakeoverBonus;
    
    if (KFPC == None || upgLevel < class'ZTConfig_Capstone'.default.Capstone_Rank2Level || TycoonHelper == None) return;
    
    TotalTeammateDosh = 0;
    foreach KFPC.WorldInfo.AllControllers(class'KFPlayerController', TeammatePCs)
    {
        if (TeammatePCs != KFPC && TeammatePCs.PlayerReplicationInfo != None)
        {
            TeammatePRI = KFPlayerReplicationInfo(TeammatePCs.PlayerReplicationInfo);
            if (TeammatePRI != None)
                TotalTeammateDosh += TeammatePRI.Score;
        }
    }
    
    TakeoverBonus = int(float(TotalTeammateDosh) * default.HostileTakeoverRate);
    
    if (TakeoverBonus > 0)
    {
        TycoonHelper.GiveTycoonDosh(TakeoverBonus, "Hostile Takeover");
        KFPC.ClientMessage("HOSTILE TAKEOVER! +" $ TakeoverBonus $ " Dosh acquired from team assets!", 'CriticalEvent');
        TycoonHelper.PlayTakeoverSound(TakeoverBonus);
        
        foreach KFPC.WorldInfo.AllControllers(class'KFPlayerController', TeammatePCs)
        {
            if (TeammatePCs != KFPC)
                TeammatePCs.ClientMessage(KFPC.PlayerReplicationInfo.PlayerName $ " executed a hostile takeover! (Boss kill bonus)", 'Event');
        }
    }
}

// ===================================================================
// HELPER CLASS MANAGEMENT
// ===================================================================

static simulated function InitiateWeapon(int upgLevel, KFWeapon KFW, KFPawn OwnerPawn)
{
    local ZTUpgrade_Perk_Tycoon_Helper TycoonHelper;
    local bool bFound;

    if (KFPawn_Human(OwnerPawn) != None && OwnerPawn.Role == Role_Authority)
    {
        bFound = False;
        foreach OwnerPawn.ChildActors(class'ZTUpgrade_Perk_Tycoon_Helper', TycoonHelper)
        {
            bFound = True;
            TycoonHelper.TycoonUpgradeLevel = upgLevel;
            break;
        }

        if (!bFound)
        {
            TycoonHelper = OwnerPawn.Spawn(class'ZTUpgrade_Perk_Tycoon_Helper', OwnerPawn);
            if (TycoonHelper != None)
                TycoonHelper.InitializeHelper(upgLevel);
        }
    }
}

static function ZTUpgrade_Perk_Tycoon_Helper GetHelper(Pawn OwnerPawn)
{
    local ZTUpgrade_Perk_Tycoon_Helper TycoonHelper;

    if (KFPawn_Human(OwnerPawn) != None)
    {
        foreach OwnerPawn.ChildActors(class'ZTUpgrade_Perk_Tycoon_Helper', TycoonHelper)
            return TycoonHelper;

        if (OwnerPawn.Role == Role_Authority)
        {
            TycoonHelper = OwnerPawn.Spawn(class'ZTUpgrade_Perk_Tycoon_Helper', OwnerPawn);
            if (TycoonHelper != None)
                TycoonHelper.InitializeHelper(1);
        }
    }

    return TycoonHelper;
}

static simulated function DeleteHelperClass(Pawn OwnerPawn)
{
    local ZTUpgrade_Perk_Tycoon_Helper TycoonHelper;

    if (OwnerPawn != None)
    {
        foreach OwnerPawn.ChildActors(class'ZTUpgrade_Perk_Tycoon_Helper', TycoonHelper)
            TycoonHelper.Destroy();
    }
}

// ===================================================================
// INTEGRATION FUNCTIONS
// ===================================================================

static function int GetTycoonDoshProgress(KFPawn OwnerPawn)
{
    local ZTUpgrade_Perk_Tycoon_Helper Helper;
    
    if (OwnerPawn == None) return 0;
    
    Helper = GetHelper(OwnerPawn);
    if (Helper != None)
        return Helper.GetDoshProgress();
    
    return 0;
}

static function int GetBonusDoshPerWave(KFPawn OwnerPawn)
{
    local ZTUpgrade_Perk_Tycoon_Helper Helper;
    
    if (OwnerPawn == None) return 0;
    
    Helper = GetHelper(OwnerPawn);
    if (Helper != None)
        return Helper.GetBonusDoshPerWave();
    
    return 0;
}

defaultproperties
{
    

    
	UpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Tycoon_Rank_0'
    // --- Localization (auto-generated by mass_localize_dk_upgrades.py) ---
    // Strings live in KFGame/Localization/<lang>/ZedternalTempered.<langext>
    // Section: [ZTUpgrade_Perk_Tycoon]  -- see DKUpgrade_* base class for details.
    bShouldLocalize=True
    LocPackage="ZedternalTempered"
    LocSection="ZTUpgrade_Perk_Tycoon"
    LocalizeDescriptionLineCount=6

    UpgradeName="Tycoon"

    PerkBonus(0)=(baseValue=0, incValue=20, maxValue=-1)
    PerkBonus(1)=(baseValue=0, incValue=1, maxValue=-1)
    PerkBonus(2)=(baseValue=0, incValue=1, maxValue=-1)
    PerkBonus(3)=(baseValue=10, incValue=0, maxValue=10)
    PerkBonus(4)=(baseValue=20, incValue=0, maxValue=20)
    
    UpgradeDescription(0)="<font color=\"#FFD700\">Round Stipend:</font> <font color=\"#FFFFFF\">+%x</font> <font color=\"#90EE90\">Dosh</font> at the end of each wave"
    UpgradeDescription(1)="<font color=\"#FFD700\">Bulk Discount:</font> <font color=\"#FFFFFF\">-%x%%</font> <font color=\"#90EE90\">Trader Prices</font>"
    UpgradeDescription(2)="<font color=\"#FFD700\">Cost Cutting:</font> <font color=\"#FFFFFF\">-%x%%</font> <font color=\"#90EE90\">Weapon and Equipment Upgrade Costs</font>"
    UpgradeDescription(3)="<font color=\"#8B0000\">LEVEL 10:</font> <font color=\"#FFD700\">Compound Interest</font> - Earn <font color=\"#FFFFFF\">10%</font> interest on current <font color=\"#90EE90\">Dosh</font> at wave end"
    UpgradeDescription(4)="<font color=\"#8B0000\">LEVEL 20:</font> <font color=\"#FFD700\">Hostile Takeover</font> - Boss kills siphon <font color=\"#FFFFFF\">20%</font> of all teammates' current <font color=\"#90EE90\">Dosh</font>"
    UpgradeDescription(5)="<font color=\"#FFD700\">Portfolio Growth</font>: Every <font color=\"#FFFFFF\">2500</font> <font color=\"#90EE90\">Dosh earned</font> grants a permanent <font color=\"#FFFFFF\">+50</font> bonus dosh per wave"
    
	// Legacy (hand-made) artwork icons

    Name="Default__ZTUpgrade_Perk_Tycoon"
}
