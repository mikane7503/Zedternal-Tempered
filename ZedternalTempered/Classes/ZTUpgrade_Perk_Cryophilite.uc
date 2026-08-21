class ZTUpgrade_Perk_Cryophilite extends ZTUpgrade_Perk config(ZedternalUnlimited);

// Theme: "Cryophilite" - Ice-based archery perk focused on precision and freezing effects
// Special mechanics: Icicle Arrow precision shots and Absolute Zero freeze explosions

var config float BaseDamage;              // Base damage increase per level
var config float HeadshotDamage;          // Additional headshot damage per level
var config float ReloadSpeed;             // Reload speed increase per level

// Level milestones - one static boost each
var config float IcicleArrowBonus;        // Level 10: configurable charged-shot damage bonus
var config int HeadshotKillsRequired;     // Headshot kills needed for Icicle Arrow
var config int TotalKillsRequired;        // Total kills needed for Absolute Zero
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.BaseDamage = 0.05f;
		default.HeadshotDamage = 0.05f;
		default.ReloadSpeed = 0.05f;
		default.IcicleArrowBonus = 5.0f;
		default.HeadshotKillsRequired = 10;
		default.TotalKillsRequired = 20;

		// BEGIN TEMPERED INI DEFAULTS (generated; do not edit by hand)
		default.BaseDamage = 0.010000f;
		default.HeadshotDamage = 0.020000f;
		default.ReloadSpeed = 0.015000f;
		default.IcicleArrowBonus = 2.000000f;
		default.HeadshotKillsRequired = 10;
		default.TotalKillsRequired = 20;
		// END TEMPERED INI DEFAULTS
		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}


static function ModifyDamageGiven(out int InDamage, int DefaultDamage, int upgLevel, optional Actor DamageCauser, optional KFPawn_Monster MyKFPM, optional KFPlayerController DamageInstigator, optional class<KFDamageType> DamageType, optional int HitZoneIdx, optional KFWeapon MyKFW)
{
    local float TotalDamageBonus;
    local ZTUpgrade_Perk_Cryophilite_Helper CryoHelper;
    local bool bIsHeadshot, bWillBeKill;
    local rotator Rot;
    local vector Loc;
    local bool bAbilityConsumed;
    
    if (MyKFPM == None || DamageInstigator == None) return;
    
    CryoHelper = GetHelper(DamageInstigator.Pawn);
    if (CryoHelper == None) return;
    
    bIsHeadshot = (HitZoneIdx == HZI_HEAD);
    
    // Base damage bonus (scales with level)
    TotalDamageBonus += default.BaseDamage * upgLevel;
    
    // Headshot damage bonus (scales with level)
    if (bIsHeadshot)
    {
        TotalDamageBonus += default.HeadshotDamage * upgLevel;
    }
    
    // Level 10: Icicle Arrow - CONSUME FIRST, then apply damage
    if (upgLevel >= class'ZTConfig_Capstone'.default.Capstone_Rank1Level && CryoHelper.bIcicleArrowReady)
    {
        TotalDamageBonus += default.IcicleArrowBonus;
        // Consume immediately to prevent retriggering
        CryoHelper.ConsumeIcicleArrow();
        CryoHelper.ShowIcicleArrowNotification();
        bAbilityConsumed = true;
    }
    
    // Apply total damage bonus
    if (TotalDamageBonus > 0.0f)
    {
        InDamage += Round(float(DefaultDamage) * TotalDamageBonus);
    }
    
    // Check if this shot will kill after damage bonuses applied
    bWillBeKill = (InDamage >= MyKFPM.Health);
    
    // Level 20: Absolute Zero - CONSUME FIRST, then create explosion
    if (upgLevel >= class'ZTConfig_Capstone'.default.Capstone_Rank2Level && CryoHelper.bAbsoluteZeroReady && bWillBeKill)
    {
        // Consume immediately to prevent retriggering
        CryoHelper.ConsumeAbsoluteZero();
        
        // Spawn freeze explosion at target location
        Rot = rotator(MyKFPM.Velocity);
        Loc = MyKFPM.Location;
        Loc.Z -= MyKFPM.GetCollisionHeight();
        Rot.Pitch = 0;
        
        DamageInstigator.Spawn(class'ZedternalTempered.ZTProj_FreezeExplosion', 
                              DamageInstigator, , Loc, Rot, , True);
        
        CryoHelper.ShowAbsoluteZeroNotification();
        bAbilityConsumed = true;
    }
    
    // Track kills for milestones - always track, but tell Helper if ability was consumed and current level
    if (bWillBeKill)
    {
        CryoHelper.TrackKill(bIsHeadshot, MyKFPM, bAbilityConsumed, upgLevel);
    }
}

static simulated function GetReloadRateScale(out float InReloadRateScale, int upgLevel, KFWeapon KFW, KFPawn OwnerPawn)
{
    InReloadRateScale = 1.f / (1.f/InReloadRateScale + default.ReloadSpeed * upgLevel);
}

// Helper class management functions (copied from Reaper pattern)
static simulated function InitiateWeapon(int upgLevel, KFWeapon KFW, KFPawn OwnerPawn)
{
    local ZTUpgrade_Perk_Cryophilite_Helper CryoHelper;
    local bool bFound;

    if (KFPawn_Human(OwnerPawn) != None && OwnerPawn.Role == Role_Authority)
    {
        bFound = False;
        foreach OwnerPawn.ChildActors(class'ZTUpgrade_Perk_Cryophilite_Helper', CryoHelper)
        {
            bFound = True;
            break;
        }

        if (!bFound)
            CryoHelper = OwnerPawn.Spawn(class'ZTUpgrade_Perk_Cryophilite_Helper', OwnerPawn);
    }
}

static function ZTUpgrade_Perk_Cryophilite_Helper GetHelper(Pawn OwnerPawn)
{
    local ZTUpgrade_Perk_Cryophilite_Helper CryoHelper;

    if (KFPawn_Human(OwnerPawn) != None)
    {
        foreach OwnerPawn.ChildActors(class'ZTUpgrade_Perk_Cryophilite_Helper', CryoHelper)
        {
            return CryoHelper;
        }

        // Should have one
        CryoHelper = OwnerPawn.Spawn(class'ZTUpgrade_Perk_Cryophilite_Helper', OwnerPawn);
    }

    return CryoHelper;
}

static simulated function DeleteHelperClass(Pawn OwnerPawn)
{
    local ZTUpgrade_Perk_Cryophilite_Helper CryoHelper;

    if (OwnerPawn != None)
    {
        foreach OwnerPawn.ChildActors(class'ZTUpgrade_Perk_Cryophilite_Helper', CryoHelper)
        {
            CryoHelper.Destroy();
        }
    }
}

defaultproperties
{
    
	UpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Cryophilite_Rank_0'
    // --- Localization (auto-generated by mass_localize_dk_upgrades.py) ---
    // Strings live in KFGame/Localization/<lang>/ZedternalTempered.<langext>
    // Section: [ZTUpgrade_Perk_Cryophilite]  -- see DKUpgrade_* base class for details.
    bShouldLocalize=True
    LocPackage="ZedternalTempered"
    LocSection="ZTUpgrade_Perk_Cryophilite"
    LocalizeDescriptionLineCount=5

    // Milestone bonuses
    
    UpgradeName="Cryophilite"

    // PerkBonus for UI display
    PerkBonus(0)=(baseValue=0, incValue=1, maxValue=-1)    // Base damage %
    PerkBonus(1)=(baseValue=0, incValue=2, maxValue=-1)    // Headshot damage %
    PerkBonus(2)=(baseValue=0, incValue=2, maxValue=-1)    // Reload speed %
    PerkBonus(3)=(baseValue=200, incValue=0, maxValue=200) // Icicle Arrow damage %
    PerkBonus(4)=(baseValue=1, incValue=0, maxValue=1)     // Absolute Zero (binary: has effect or not)
    
    // Upgrade descriptions with ice/frost theme
    UpgradeDescription(0)="<font color=\"#87CEEB\">Frost Mastery:</font> <font color=\"#FFFFFF\">+%x%%</font> <font color=\"#B0E0E6\">All Damage</font>"
    UpgradeDescription(1)="<font color=\"#87CEEB\">Precision Ice:</font> <font color=\"#FFFFFF\">+%x%%</font> <font color=\"#B0E0E6\">Headshot Damage</font>"
    UpgradeDescription(2)="<font color=\"#87CEEB\">Swift Reload:</font> <font color=\"#FFFFFF\">+%x%%</font> <font color=\"#B0E0E6\">Reload Speed</font>"
    UpgradeDescription(3)="<font color=\"#8B0000\">LEVEL 10:</font> <font color=\"#FFD700\">Icicle Arrow</font> - Every <font color=\"#FFFFFF\">10 headshot kills</font> charges next shot for <font color=\"#FFFFFF\">+200%</font> damage"
    UpgradeDescription(4)="<font color=\"#8B0000\">LEVEL 20:</font> <font color=\"#FFD700\">Absolute Zero</font> - Every <font color=\"#FFFFFF\">20 kills</font> charges next shot to create a <font color=\"#B0E0E6\">freeze explosion</font>"
    
    // Icons for all 21 ranks (0-20)
    
	// Legacy (hand-made) artwork icons

    Name="Default__ZTUpgrade_Perk_Cryophilite"
}
