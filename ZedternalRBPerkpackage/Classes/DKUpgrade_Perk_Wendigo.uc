class DKUpgrade_Perk_Wendigo extends DKUpgrade_Perk
	config(ZedternalUnlimited);

// Theme: "Wendigo Stalker" - Patient ambush predator that grows stronger through stillness

var config float StalkDamageBonus;        // 10% damage per level after not firing for 5+ seconds
var config float MovementSpeed;           // 2% movement speed per level
var config float SpareAmmoBonus;          // 5% spare ammo per level

// Special bonuses
var config float PerfectAmbushBonus;      // 200% damage for first shot after 10+ seconds (Level 10)
var config float ApexStalkerBonus;        // 150% damage bonus when not taking damage for 30+ seconds (Level 20)

// Timing constants
var const float StalkTimeRequired;      // 5 seconds of not firing for stalk bonus
var const float AmbushTimeRequired;     // 10 seconds of not firing for perfect ambush
var const float ApexTimeRequired;       // 30 seconds of not taking damage for apex stalker
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.StalkDamageBonus = 0.10f;
		default.MovementSpeed = 0.02f;
		default.SpareAmmoBonus = 0.05f;
		default.PerfectAmbushBonus = 2.0f;
		default.ApexStalkerBonus = 1.5f;

		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}


static function ModifyDamageGiven(out int InDamage, int DefaultDamage, int upgLevel, optional Actor DamageCauser, optional KFPawn_Monster MyKFPM, optional KFPlayerController DamageInstigator, optional class<KFDamageType> DamageType, optional int HitZoneIdx, optional KFWeapon MyKFW)
{
    local DKUpgrade_Perk_Wendigo_Helper WendigoHelper;
    local float CurrentTime, TimeSinceLastFire, TimeSinceLastDamage;
    local float TotalDamageBonus;
    local bool bPerfectAmbushTriggered, bApexStalkerActive;
    
    if (MyKFPM == None || DamageInstigator == None || DamageInstigator.Pawn == None) return;
    
    WendigoHelper = GetHelper(DamageInstigator.Pawn);
    if (WendigoHelper == None) return;
    
    // Update the helper with current perk level
    WendigoHelper.SetPerkLevel(upgLevel);
    
    CurrentTime = DamageInstigator.Pawn.WorldInfo.TimeSeconds;
    TimeSinceLastFire = CurrentTime - WendigoHelper.LastFireTime;
    TimeSinceLastDamage = CurrentTime - WendigoHelper.LastDamageTime;
    
    // Check for Perfect Ambush (Level 10+)
    if (upgLevel >= class'DKConfig_Capstone'.default.Capstone_Rank1Level && WendigoHelper.bFirstShotReady && TimeSinceLastFire >= default.AmbushTimeRequired)
    {
        bPerfectAmbushTriggered = true;
        WendigoHelper.bFirstShotReady = false; // Consume the perfect ambush shot
        TotalDamageBonus += default.PerfectAmbushBonus;
        
        // Show perfect ambush notification
        WendigoHelper.ShowPerfectAmbushNotification();
    }
    
    // Check for Apex Stalker bonus (Level 20+)
    if (upgLevel >= class'DKConfig_Capstone'.default.Capstone_Rank2Level && TimeSinceLastDamage >= default.ApexTimeRequired)
    {
        bApexStalkerActive = true;
        WendigoHelper.bApexStalkerActive = true;
        TotalDamageBonus += default.ApexStalkerBonus;
    }
    
    // Regular stalk damage bonus (requires 5+ seconds of not firing)
    if (TimeSinceLastFire >= default.StalkTimeRequired)
    {
        TotalDamageBonus += default.StalkDamageBonus * upgLevel;
    }
    
    // Apply total damage bonus
    if (TotalDamageBonus > 0.0f)
    {
        InDamage += Round(float(DefaultDamage) * TotalDamageBonus);
    }
    
    // Update the last fire time since we just fired
    WendigoHelper.LastFireTime = CurrentTime;
    
    // Push an immediate HUD update only for the one-shot Perfect Ambush flash.
    // Steady-state stalk / Apex Stalker tracker display is driven by the helper's
    // 0.5s timer (UpdateStalkerTracking). Pushing on every hit re-announced the
    // Apex Stalker state on each bullet, which at L20 (firing while undamaged)
    // read as message spam that never cleared. The damage bonus above is
    // unaffected -- only the redundant per-bullet HUD push is removed.
    if (bPerfectAmbushTriggered)
        WendigoHelper.UpdateStalkerDisplay(TimeSinceLastFire, TimeSinceLastDamage, true, bApexStalkerActive);
}

static simulated function ModifySpeed(out float InSpeed, float DefaultSpeed, int upgLevel, KFPawn OwnerPawn)
{
    InSpeed += DefaultSpeed * default.MovementSpeed * upgLevel;
}

static simulated function ModifySpareAmmoAmount(out int InSpareAmmo, int DefaultSpareAmmo, int upgLevel, KFWeapon KFW, optional const out STraderItem TraderItem, optional bool bSecondary=False)
{
    InSpareAmmo += Round(float(DefaultSpareAmmo) * default.SpareAmmoBonus * upgLevel);
}

// Helper class management functions
static simulated function InitiateWeapon(int upgLevel, KFWeapon KFW, KFPawn OwnerPawn)
{
    local DKUpgrade_Perk_Wendigo_Helper WendigoHelper;
    local bool bFound;

    if (KFPawn_Human(OwnerPawn) != None && OwnerPawn.Role == Role_Authority)
    {
        bFound = False;
        foreach OwnerPawn.ChildActors(class'DKUpgrade_Perk_Wendigo_Helper', WendigoHelper)
        {
            bFound = True;
            // Update the helper with current perk level when weapon is initiated
            WendigoHelper.SetPerkLevel(upgLevel);
            break;
        }

        if (!bFound)
        {
            WendigoHelper = OwnerPawn.Spawn(class'DKUpgrade_Perk_Wendigo_Helper', OwnerPawn);
            if (WendigoHelper != None)
            {
                WendigoHelper.SetPerkLevel(upgLevel);
            }
        }
    }
}

static function DKUpgrade_Perk_Wendigo_Helper GetHelper(Pawn OwnerPawn)
{
    local DKUpgrade_Perk_Wendigo_Helper WendigoHelper;

    if (KFPawn_Human(OwnerPawn) != None)
    {
        foreach OwnerPawn.ChildActors(class'DKUpgrade_Perk_Wendigo_Helper', WendigoHelper)
        {
            return WendigoHelper;
        }

        // Should have one
        WendigoHelper = OwnerPawn.Spawn(class'DKUpgrade_Perk_Wendigo_Helper', OwnerPawn);
    }

    return WendigoHelper;
}

static simulated function DeleteHelperClass(Pawn OwnerPawn)
{
    local DKUpgrade_Perk_Wendigo_Helper WendigoHelper;

    if (OwnerPawn != None)
    {
        foreach OwnerPawn.ChildActors(class'DKUpgrade_Perk_Wendigo_Helper', WendigoHelper)
        {
            WendigoHelper.Destroy();
        }
    }
}

defaultproperties
{
    
    // --- Localization (auto-generated by mass_localize_dk_upgrades.py) ---
    // Strings live in KFGame/Localization/<lang>/ZedternalRBPerkpackage.<langext>
    // Section: [DKUpgrade_Perk_Wendigo]  -- see DKUpgrade_* base class for details.
    bShouldLocalize=True
    LocPackage="ZedternalRBPerkpackage"
    LocSection="DKUpgrade_Perk_Wendigo"
    LocalizeDescriptionLineCount=5

    // Special abilities
    
    // Timing requirements
    StalkTimeRequired=5.0f         // 5 seconds for stalk bonus
    AmbushTimeRequired=10.0f       // 10 seconds for perfect ambush
    ApexTimeRequired=30.0f         // 30 seconds for apex stalker
    
    UpgradeName="Wendigo"

    // PerkBonus for UI display
    PerkBonus(0)=(baseValue=0, incValue=10, maxValue=-1)   // Stalk damage bonus %
    PerkBonus(1)=(baseValue=0, incValue=2, maxValue=-1)    // Movement speed %
    PerkBonus(2)=(baseValue=0, incValue=5, maxValue=-1)    // Spare ammo %
    PerkBonus(3)=(baseValue=200, incValue=0, maxValue=200) // Perfect ambush damage % (fixed at 200%)
    PerkBonus(4)=(baseValue=150, incValue=0, maxValue=150) // Apex stalker damage % (fixed at 150%)
    
    // Upgrade descriptions with icy Wendigo theme
    UpgradeDescription(0)="<font color=\"#4682B4\">Predator's Patience:</font> <font color=\"#FFFFFF\">+%x%%</font> <font color=\"#87CEEB\">Damage</font> after not firing for <font color=\"#FFFFFF\">5+ seconds</font>"
    UpgradeDescription(1)="<font color=\"#4682B4\">Stalker's Grace:</font> <font color=\"#FFFFFF\">+%x%%</font> <font color=\"#87CEEB\">Movement Speed</font>"
    UpgradeDescription(2)="<font color=\"#4682B4\">Hunter's Preparation:</font> <font color=\"#FFFFFF\">+%x%%</font> <font color=\"#87CEEB\">Spare Ammo</font>"
    UpgradeDescription(3)="<font color=\"#8B0000\">LEVEL 10:</font> <font color=\"#FFD700\">Perfect Ambush</font> - First shot after <font color=\"#FFFFFF\">10 seconds</font> deals <font color=\"#FFFFFF\">+200%</font> <font color=\"#87CEEB\">Damage</font>"
    UpgradeDescription(4)="<font color=\"#8B0000\">LEVEL 20:</font> <font color=\"#FFD700\">Apex Stalker</font> - Not taking damage for <font color=\"#FFFFFF\">30+ seconds</font> grants <font color=\"#FFFFFF\">+150%</font> <font color=\"#87CEEB\">Damage</font> until hit"
    
    // Placeholder icons - using icy blue theme
    UpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Wendigo_Legacy_Rank_0'
    UpgradeIcon(1)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Wendigo_Legacy_Rank_1'
    UpgradeIcon(2)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Wendigo_Legacy_Rank_2'
    UpgradeIcon(3)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Wendigo_Legacy_Rank_3'
    UpgradeIcon(4)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Wendigo_Legacy_Rank_4'
    UpgradeIcon(5)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Wendigo_Legacy_Rank_5'
    UpgradeIcon(6)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Wendigo_Legacy_Rank_5'
    UpgradeIcon(7)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Wendigo_Legacy_Rank_5'
    UpgradeIcon(8)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Wendigo_Legacy_Rank_5'
    UpgradeIcon(9)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Wendigo_Legacy_Rank_5'
    UpgradeIcon(10)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Wendigo_Legacy_Rank_5'
    UpgradeIcon(11)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Wendigo_Legacy_Rank_5'
    UpgradeIcon(12)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Wendigo_Legacy_Rank_5'
    UpgradeIcon(13)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Wendigo_Legacy_Rank_5'
    UpgradeIcon(14)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Wendigo_Legacy_Rank_5'
    UpgradeIcon(15)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Wendigo_Legacy_Rank_5'
    UpgradeIcon(16)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Wendigo_Legacy_Rank_5'
    UpgradeIcon(17)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Wendigo_Legacy_Rank_5'
    UpgradeIcon(18)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Wendigo_Legacy_Rank_5'
    UpgradeIcon(19)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Wendigo_Legacy_Rank_5'
    UpgradeIcon(20)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Wendigo_Legacy_Rank_5'
    
	// Legacy (hand-made) artwork icons
	LegacyUpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Wendigo_Legacy_Rank_0'
	LegacyUpgradeIcon(1)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Wendigo_Legacy_Rank_1'
	LegacyUpgradeIcon(2)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Wendigo_Legacy_Rank_2'
	LegacyUpgradeIcon(3)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Wendigo_Legacy_Rank_3'
	LegacyUpgradeIcon(4)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Wendigo_Legacy_Rank_4'
	LegacyUpgradeIcon(5)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Wendigo_Legacy_Rank_5'
	LegacyUpgradeIcon(6)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Wendigo_Legacy_Rank_5'
	LegacyUpgradeIcon(7)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Wendigo_Legacy_Rank_5'
	LegacyUpgradeIcon(8)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Wendigo_Legacy_Rank_5'
	LegacyUpgradeIcon(9)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Wendigo_Legacy_Rank_5'
	LegacyUpgradeIcon(10)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Wendigo_Legacy_Rank_5'
	LegacyUpgradeIcon(11)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Wendigo_Legacy_Rank_5'
	LegacyUpgradeIcon(12)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Wendigo_Legacy_Rank_5'
	LegacyUpgradeIcon(13)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Wendigo_Legacy_Rank_5'
	LegacyUpgradeIcon(14)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Wendigo_Legacy_Rank_5'
	LegacyUpgradeIcon(15)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Wendigo_Legacy_Rank_5'
	LegacyUpgradeIcon(16)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Wendigo_Legacy_Rank_5'
	LegacyUpgradeIcon(17)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Wendigo_Legacy_Rank_5'
	LegacyUpgradeIcon(18)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Wendigo_Legacy_Rank_5'
	LegacyUpgradeIcon(19)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Wendigo_Legacy_Rank_5'
	LegacyUpgradeIcon(20)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Wendigo_Legacy_Rank_5'

    Name="Default__DKUpgrade_Perk_Wendigo"
}