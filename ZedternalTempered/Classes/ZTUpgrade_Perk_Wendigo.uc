class ZTUpgrade_Perk_Wendigo extends ZTUpgrade_Perk config(ZedternalUnlimited);

// Theme: "Wendigo Stalker" - Patient ambush predator that grows stronger through stillness

var config float StalkDamageBonus;        // 10% damage per level after not firing for 5+ seconds
var config float MovementSpeed;           // 2% movement speed per level
var config float SpareAmmoBonus;          // 5% spare ammo per level

// Special bonuses
var config float PerfectAmbushBonus;      // First-shot damage bonus after 10+ seconds (Level 10)
var config float ApexStalkerBonus;        // Damage bonus when not taking damage for 30+ seconds (Level 20)

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

		// BEGIN TEMPERED INI DEFAULTS (generated; do not edit by hand)
		default.StalkDamageBonus = 0.025000f;
		default.MovementSpeed = 0.007500f;
		default.SpareAmmoBonus = 0.015000f;
		default.PerfectAmbushBonus = 0.500000f;
		default.ApexStalkerBonus = 0.350000f;
		// END TEMPERED INI DEFAULTS
		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}


static function ModifyDamageGiven(out int InDamage, int DefaultDamage, int upgLevel, optional Actor DamageCauser, optional KFPawn_Monster MyKFPM, optional KFPlayerController DamageInstigator, optional class<KFDamageType> DamageType, optional int HitZoneIdx, optional KFWeapon MyKFW)
{
    local ZTUpgrade_Perk_Wendigo_Helper WendigoHelper;
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
    if (upgLevel >= class'ZTConfig_Capstone'.default.Capstone_Rank1Level && WendigoHelper.bFirstShotReady && TimeSinceLastFire >= default.AmbushTimeRequired)
    {
        bPerfectAmbushTriggered = true;
        WendigoHelper.bFirstShotReady = false; // Consume the perfect ambush shot
        TotalDamageBonus += default.PerfectAmbushBonus;
        
        // Show perfect ambush notification
        WendigoHelper.ShowPerfectAmbushNotification();
    }
    
    // Check for Apex Stalker bonus (Level 20+)
    if (upgLevel >= class'ZTConfig_Capstone'.default.Capstone_Rank2Level && TimeSinceLastDamage >= default.ApexTimeRequired)
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
    local ZTUpgrade_Perk_Wendigo_Helper WendigoHelper;
    local bool bFound;

    if (KFPawn_Human(OwnerPawn) != None && OwnerPawn.Role == Role_Authority)
    {
        bFound = False;
        foreach OwnerPawn.ChildActors(class'ZTUpgrade_Perk_Wendigo_Helper', WendigoHelper)
        {
            bFound = True;
            // Update the helper with current perk level when weapon is initiated
            WendigoHelper.SetPerkLevel(upgLevel);
            break;
        }

        if (!bFound)
        {
            WendigoHelper = OwnerPawn.Spawn(class'ZTUpgrade_Perk_Wendigo_Helper', OwnerPawn);
            if (WendigoHelper != None)
            {
                WendigoHelper.SetPerkLevel(upgLevel);
            }
        }
    }
}

static function ZTUpgrade_Perk_Wendigo_Helper GetHelper(Pawn OwnerPawn)
{
    local ZTUpgrade_Perk_Wendigo_Helper WendigoHelper;

    if (KFPawn_Human(OwnerPawn) != None)
    {
        foreach OwnerPawn.ChildActors(class'ZTUpgrade_Perk_Wendigo_Helper', WendigoHelper)
        {
            return WendigoHelper;
        }

        // Should have one
        WendigoHelper = OwnerPawn.Spawn(class'ZTUpgrade_Perk_Wendigo_Helper', OwnerPawn);
    }

    return WendigoHelper;
}

static simulated function DeleteHelperClass(Pawn OwnerPawn)
{
    local ZTUpgrade_Perk_Wendigo_Helper WendigoHelper;

    if (OwnerPawn != None)
    {
        foreach OwnerPawn.ChildActors(class'ZTUpgrade_Perk_Wendigo_Helper', WendigoHelper)
        {
            WendigoHelper.Destroy();
        }
    }
}

defaultproperties
{
    
	UpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Wendigo_Rank_0'
    // --- Localization (auto-generated by mass_localize_dk_upgrades.py) ---
    // Strings live in KFGame/Localization/<lang>/ZedternalTempered.<langext>
    // Section: [ZTUpgrade_Perk_Wendigo]  -- see DKUpgrade_* base class for details.
    bShouldLocalize=True
    LocPackage="ZedternalTempered"
    LocSection="ZTUpgrade_Perk_Wendigo"
    LocalizeDescriptionLineCount=5

    // Special abilities
    
    // Timing requirements
    StalkTimeRequired=5.0f         // 5 seconds for stalk bonus
    AmbushTimeRequired=10.0f       // 10 seconds for perfect ambush
    ApexTimeRequired=30.0f         // 30 seconds for apex stalker
    
    UpgradeName="Wendigo"

    // PerkBonus for UI display
    PerkBonus(0)=(baseValue=0, incValue=3, maxValue=-1)   // Stalk damage bonus %
    PerkBonus(1)=(baseValue=0, incValue=1, maxValue=-1)    // Movement speed %
    PerkBonus(2)=(baseValue=0, incValue=2, maxValue=-1)    // Spare ammo %
    PerkBonus(3)=(baseValue=50, incValue=0, maxValue=50) // Perfect ambush damage %
    PerkBonus(4)=(baseValue=35, incValue=0, maxValue=35) // Apex stalker damage %
    
    // Upgrade descriptions with icy Wendigo theme
    UpgradeDescription(0)="<font color=\"#4682B4\">Predator's Patience:</font> <font color=\"#FFFFFF\">+%x%%</font> <font color=\"#87CEEB\">Damage</font> after not firing for <font color=\"#FFFFFF\">5+ seconds</font>"
    UpgradeDescription(1)="<font color=\"#4682B4\">Stalker's Grace:</font> <font color=\"#FFFFFF\">+%x%%</font> <font color=\"#87CEEB\">Movement Speed</font>"
    UpgradeDescription(2)="<font color=\"#4682B4\">Hunter's Preparation:</font> <font color=\"#FFFFFF\">+%x%%</font> <font color=\"#87CEEB\">Spare Ammo</font>"
    UpgradeDescription(3)="<font color=\"#8B0000\">LEVEL 10:</font> <font color=\"#FFD700\">Perfect Ambush</font> - First shot after <font color=\"#FFFFFF\">10 seconds</font> deals <font color=\"#FFFFFF\">+50%</font> <font color=\"#87CEEB\">Damage</font>"
    UpgradeDescription(4)="<font color=\"#8B0000\">LEVEL 20:</font> <font color=\"#FFD700\">Apex Stalker</font> - Not taking damage for <font color=\"#FFFFFF\">30+ seconds</font> grants <font color=\"#FFFFFF\">+35%</font> <font color=\"#87CEEB\">Damage</font> until hit"
    
    // Placeholder icons - using icy blue theme
    
	// Legacy (hand-made) artwork icons

    Name="Default__ZTUpgrade_Perk_Wendigo"
}
