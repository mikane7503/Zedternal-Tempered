class ZTUpgrade_Perk_Scavenger extends ZTUpgrade_Perk config(ZedternalUnlimited);

// Theme: "Scavenger" - A resourceful survivor who maximizes efficiency and finds opportunities
// Special mechanics: Random ammo scrounging, field adaptation bonuses

// Linear bonuses per level (1-20)
var config float ReloadSpeed;         // Reload speed increase per level
var config float WeaponSwitchSpeed;   // Weapon switch speed per level  
var config float MovementSpeed;       // Movement speed increase per level

// Level 10 special bonus - Battlefield Scrounger
var config float AmmoScavengeChance;      // Chance to find ammo on kill
var config int AmmoScavengeAmount;        // Amount of ammo to add

// Level 20 special bonus - Master Survivor
var config float Level20DamageBonus;      // Massive damage bonus at level 20
var config float Level20MagazineBonus;    // Magazine capacity bonus at level 20
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.ReloadSpeed = 0.03f;
		default.WeaponSwitchSpeed = 0.02f;
		default.MovementSpeed = 0.01f;
		default.AmmoScavengeChance = 0.10f;
		default.AmmoScavengeAmount = 20;
		default.Level20DamageBonus = 0.35f;
		default.Level20MagazineBonus = 0.30f;

		// BEGIN TEMPERED INI DEFAULTS (generated; do not edit by hand)
		default.ReloadSpeed = 0.015000f;
		default.WeaponSwitchSpeed = 0.020000f;
		default.MovementSpeed = 0.010000f;
		default.AmmoScavengeChance = 0.100000f;
		default.AmmoScavengeAmount = 30;
		default.Level20DamageBonus = 0.125000f;
		default.Level20MagazineBonus = 0.300000f;
		// END TEMPERED INI DEFAULTS
		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}


// Field adaptation system will be handled by the helper class

// ===================================================================
// RELOAD SPEED MODIFICATION
// ===================================================================

static simulated function GetReloadRateScale(out float InReloadRateScale, int upgLevel, KFWeapon KFW, KFPawn OwnerPawn)
{
    local float ReloadBonus;
    local ZTUpgrade_Perk_Scavenger_Helper ScavengerHelper;
    
    // Base reload bonus from levels
    ReloadBonus = default.ReloadSpeed * upgLevel;
    
    // Add field adaptation bonuses if available
    if (OwnerPawn != None)
    {
        ScavengerHelper = GetHelper(OwnerPawn);
        if (ScavengerHelper != None)
        {
            ReloadBonus += ScavengerHelper.GetAdaptationBonus("ReloadSpeed");
        }
    }
    
    // Use same formula pattern as Symbiote
    InReloadRateScale = 1.f / (1.f/InReloadRateScale + ReloadBonus);
}

// ===================================================================
// WEAPON SWITCH SPEED MODIFICATION
// ===================================================================

static simulated function ModifyWeaponSwitchTime(out float InSwitchTime, float DefaultSwitchTime, int upgLevel, KFWeapon KFW)
{
    local float TotalSwitchBonus;
    local ZTUpgrade_Perk_Scavenger_Helper ScavengerHelper;
    local KFPawn OwnerPawn;
    
    // Base switch speed bonus from levels
    TotalSwitchBonus = default.WeaponSwitchSpeed * upgLevel;
    
    // Get OwnerPawn from weapon
    if (KFW != None && KFW.Instigator != None)
    {
        OwnerPawn = KFPawn(KFW.Instigator);
        ScavengerHelper = GetHelper(OwnerPawn);
        if (ScavengerHelper != None)
        {
            TotalSwitchBonus += ScavengerHelper.GetAdaptationBonus("WeaponSwitchSpeed");
        }
    }
    
    InSwitchTime = DefaultSwitchTime / (DefaultSwitchTime / InSwitchTime + TotalSwitchBonus);
}

// ===================================================================
// MOVEMENT SPEED MODIFICATION
// ===================================================================

static simulated function ModifySpeed(out float InSpeed, float DefaultSpeed, int upgLevel, KFPawn OwnerPawn)
{
    local ZTUpgrade_Perk_Scavenger_Helper ScavengerHelper;
    
    // Base movement speed bonus from levels
    InSpeed += DefaultSpeed * (default.MovementSpeed * upgLevel);
    
    // Add field adaptation bonuses if available
    if (OwnerPawn != None)
    {
        ScavengerHelper = GetHelper(OwnerPawn);
        if (ScavengerHelper != None)
        {
            InSpeed += DefaultSpeed * ScavengerHelper.GetAdaptationBonus("MovementSpeed");
        }
    }
}

// ===================================================================
// DAMAGE MODIFICATION
// ===================================================================

static function ModifyDamageGiven(out int InDamage, int DefaultDamage, int upgLevel, optional Actor DamageCauser, optional KFPawn_Monster MyKFPM, optional KFPlayerController DamageInstigator, optional class<KFDamageType> DamageType, optional int HitZoneIdx, optional KFWeapon MyKFW)
{
    local float TotalDamageBonus;
    local ZTUpgrade_Perk_Scavenger_Helper ScavengerHelper;
    
    if (MyKFPM == None || DamageInstigator == None) return;
    
    TotalDamageBonus = 0.0f;
    
    // Level 20 massive damage bonus
    if (upgLevel >= class'ZTConfig_Capstone'.default.Capstone_Rank2Level)
    {
        TotalDamageBonus += default.Level20DamageBonus;
    }
    
    // Apply damage bonus
    InDamage += Round(float(DefaultDamage) * TotalDamageBonus);
    
    // Track kill for field adaptation and ammo scavenging (if this damage will kill the monster)
    if (InDamage >= MyKFPM.Health && DamageInstigator.Pawn != None)
    {
        ScavengerHelper = GetHelper(DamageInstigator.Pawn);
        if (ScavengerHelper != None)
        {
            ScavengerHelper.TrackKill(MyKFPM, upgLevel); // Pass upgrade level for ammo scavenging
        }
    }
}

// ===================================================================
// AMMO CAPACITY MODIFICATIONS
// ===================================================================

static simulated function ModifySpareAmmoAmount(out int InSpareAmmo, int DefaultSpareAmmo, int upgLevel, KFWeapon KFW, optional const out STraderItem TraderItem, optional bool bSecondary=false)
{
    local ZTUpgrade_Perk_Scavenger_Helper ScavengerHelper;
    local KFPawn OwnerPawn;
    
    // Add field adaptation bonuses if available
    if (KFW != None && KFW.Instigator != None)
    {
        OwnerPawn = KFPawn(KFW.Instigator);
        ScavengerHelper = GetHelper(OwnerPawn);
        if (ScavengerHelper != None)
        {
            InSpareAmmo += int(float(DefaultSpareAmmo) * ScavengerHelper.GetAdaptationBonus("SpareAmmo"));
        }
    }
}

static simulated function ModifyMagSizeAndNumber(out int InMagazineCapacity, int DefaultMagazineCapacity, int upgLevel, KFWeapon KFW, optional array< Class<KFPerk> > WeaponPerkClass, optional bool bSecondary=False, optional name WeaponClassname)
{
    local ZTUpgrade_Perk_Scavenger_Helper ScavengerHelper;
    local KFPawn OwnerPawn;
    local float MagazineBonus;
    
    MagazineBonus = 0.0f;
    
    // Level 20 magazine bonus
    if (upgLevel >= class'ZTConfig_Capstone'.default.Capstone_Rank2Level)
    {
        MagazineBonus += default.Level20MagazineBonus;
    }
    
    // Get OwnerPawn from weapon for field adaptation bonuses
    if (KFW != None && KFW.Instigator != None)
    {
        OwnerPawn = KFPawn(KFW.Instigator);
        ScavengerHelper = GetHelper(OwnerPawn);
        if (ScavengerHelper != None)
        {
            MagazineBonus += ScavengerHelper.GetAdaptationBonus("MagazineSize");
        }
    }
    
    InMagazineCapacity += int(float(DefaultMagazineCapacity) * MagazineBonus);
}

// ===================================================================
// SPECIAL ABILITIES
// ===================================================================

// Level 10 ability - can see cloaked enemies
static simulated function bool IsCallOutActive(int upgLevel, KFPawn OwnerPawn)
{
    return upgLevel >= class'ZTConfig_Capstone'.default.Capstone_Rank1Level;
}

// ===================================================================
// HELPER CLASS MANAGEMENT
// ===================================================================

// Helper class management functions
static simulated function InitiateWeapon(int upgLevel, KFWeapon KFW, KFPawn OwnerPawn)
{
    local ZTUpgrade_Perk_Scavenger_Helper ScavengerHelper;
    local bool bFound;

    if (KFPawn_Human(OwnerPawn) != None && OwnerPawn.Role == Role_Authority)
    {
        bFound = False;
        foreach OwnerPawn.ChildActors(class'ZTUpgrade_Perk_Scavenger_Helper', ScavengerHelper)
        {
            bFound = True;
            break;
        }

        if (!bFound)
            ScavengerHelper = OwnerPawn.Spawn(class'ZTUpgrade_Perk_Scavenger_Helper', OwnerPawn);
    }
}

static function ZTUpgrade_Perk_Scavenger_Helper GetHelper(Pawn OwnerPawn)
{
    local ZTUpgrade_Perk_Scavenger_Helper ScavengerHelper;

    if (KFPawn_Human(OwnerPawn) != None)
    {
        foreach OwnerPawn.ChildActors(class'ZTUpgrade_Perk_Scavenger_Helper', ScavengerHelper)
        {
            return ScavengerHelper;
        }

        // Should have one
        ScavengerHelper = OwnerPawn.Spawn(class'ZTUpgrade_Perk_Scavenger_Helper', OwnerPawn);
    }

    return ScavengerHelper;
}

static simulated function DeleteHelperClass(Pawn OwnerPawn)
{
    local ZTUpgrade_Perk_Scavenger_Helper ScavengerHelper;

    if (OwnerPawn != None)
    {
        foreach OwnerPawn.ChildActors(class'ZTUpgrade_Perk_Scavenger_Helper', ScavengerHelper)
        {
            ScavengerHelper.Destroy();
        }
    }
}

// ===================================================================
// INTEGRATION FUNCTIONS
// ===================================================================

// Get adaptation bonus helper function for other classes to use
static function float GetScavengerAdaptationBonus(KFPawn OwnerPawn, string BonusType)
{
    local ZTUpgrade_Perk_Scavenger_Helper Helper;
    
    if (OwnerPawn == None)
        return 0.0f;
    
    Helper = GetHelper(OwnerPawn);
    if (Helper != None)
    {
        return Helper.GetAdaptationBonus(BonusType);
    }
    
    return 0.0f;
}

// Get total adaptation count for this player
static function int GetAdaptationCount(KFPawn OwnerPawn)
{
    local ZTUpgrade_Perk_Scavenger_Helper Helper;
    
    if (OwnerPawn == None)
        return 0;
    
    Helper = GetHelper(OwnerPawn);
    if (Helper != None)
    {
        return Helper.TotalAdaptations;
    }
    
    return 0;
}

defaultproperties
{
	UpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Scavenger_Rank_0'
    // --- Localization (auto-generated by mass_localize_dk_upgrades.py) ---
    // Strings live in KFGame/Localization/<lang>/ZedternalTempered.<langext>
    // Section: [ZTUpgrade_Perk_Scavenger]  -- see DKUpgrade_* base class for details.
    bShouldLocalize=True
    LocPackage="ZedternalTempered"
    LocSection="ZTUpgrade_Perk_Scavenger"
    LocalizeDescriptionLineCount=6

    // Linear bonuses per level
    
    // Level 10 "Battlefield Scrounger" bonuses
    
    // Level 20 "Master Survivor" bonuses
    
    UpgradeName="Scavenger"

    // PerkBonus for UI display
    PerkBonus(0)=(baseValue=0, incValue=2, maxValue=-1)    // Reload speed %
    PerkBonus(1)=(baseValue=0, incValue=2, maxValue=-1)    // Weapon switch speed %
    PerkBonus(2)=(baseValue=0, incValue=1, maxValue=-1)    // Movement speed %
    PerkBonus(3)=(baseValue=10, incValue=0, maxValue=10)   // Level 10 ammo scavenge chance % (fixed at 10%)
    PerkBonus(4)=(baseValue=13, incValue=0, maxValue=13)   // Level 20 damage % (fixed at 35%)
    
    // Upgrade descriptions with Scavenger resource management theme
    UpgradeDescription(0)="<font color=\"#DAA520\">Practiced Reloading:</font> <font color=\"#FFFFFF\">+%x%%</font> <font color=\"#F0C868\">Reload Speed</font>"
    UpgradeDescription(1)="<font color=\"#DAA520\">Quick Draw:</font> <font color=\"#FFFFFF\">+%x%%</font> <font color=\"#F0C868\">Weapon Switch Speed</font>"
    UpgradeDescription(2)="<font color=\"#DAA520\">Light on Your Feet:</font> <font color=\"#FFFFFF\">+%x%%</font> <font color=\"#F0C868\">Movement Speed</font>"
    UpgradeDescription(3)="<font color=\"#8B0000\">LEVEL 10:</font> <font color=\"#FFD700\">Battlefield Scrounger</font> - <font color=\"#FFFFFF\">10%</font> chance on kill to find <font color=\"#FFFFFF\">30</font> spare ammo. Reveals <font color=\"#F0C868\">cloaked enemies</font>"
    UpgradeDescription(4)="<font color=\"#8B0000\">LEVEL 20:</font> <font color=\"#FFD700\">Master Survivor</font> - <font color=\"#FFFFFF\">+12.5%</font> <font color=\"#F0C868\">Damage</font> and <font color=\"#FFFFFF\">+30%</font> <font color=\"#F0C868\">Magazine Capacity</font>"
    UpgradeDescription(5)="<font color=\"#FFD700\">Resourceful Learning</font>: Every <font color=\"#FFFFFF\">50</font> kills grants a random permanent <font color=\"#F0C868\">+5% Spare Ammo</font> or <font color=\"#F0C868\">+5% Magazine Size</font>"
    
    // Placeholder icons - you'll need to create actual textures
    
	// Legacy (hand-made) artwork icons

    Name="Default__ZTUpgrade_Perk_Scavenger"
}