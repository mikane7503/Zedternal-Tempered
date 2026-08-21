class ZTUpgrade_Perk_Symbiote extends ZTUpgrade_Perk config(ZedternalUnlimited);

// Theme: "Symbiote" - An evolving organism that becomes stronger with each kill
// Special mechanics: Random evolution bonuses every 100 kills, adapts and grows

// Linear bonuses per level (1-20)
var config float ReloadSpeed;         // Reload speed increase per level
var config float WeaponSwitchSpeed;   // Weapon switch speed per level  
var config float PenetrationBonus;   // Penetration increase per level

// Level 10 special bonus - Parasitic Integration
var config float Level10SpareAmmoBonus;    // Spare ammo bonus at level 10
var config float Level10StunBonus;         // Stun power bonus at level 10

// Level 20 special bonus - Perfect Organism
var config float Level20DamageBonus;       // Massive damage bonus at level 20
var config float Level20KnockdownBonus;    // Knockdown power bonus at level 20
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.ReloadSpeed = 0.03f;
		default.WeaponSwitchSpeed = 0.02f;
		default.PenetrationBonus = 0.05f;
		default.Level10SpareAmmoBonus = 0.5f;
		default.Level10StunBonus = 0.3f;
		default.Level20DamageBonus = 0.25f;
		default.Level20KnockdownBonus = 100.0f;

		// BEGIN TEMPERED INI DEFAULTS (generated; do not edit by hand)
		default.ReloadSpeed = 0.015000f;
		default.WeaponSwitchSpeed = 0.020000f;
		default.PenetrationBonus = 0.050000f;
		default.Level10SpareAmmoBonus = 0.250000f;
		default.Level10StunBonus = 0.150000f;
		default.Level20DamageBonus = 0.125000f;
		default.Level20KnockdownBonus = 50.000000f;
		// END TEMPERED INI DEFAULTS
		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}


// Evolution system will be handled by the helper class

// ===================================================================
// RELOAD SPEED MODIFICATION
// ===================================================================

static simulated function GetReloadRateScale(out float InReloadRateScale, int upgLevel, KFWeapon KFW, KFPawn OwnerPawn)
{
    local float ReloadBonus;
    local ZTUpgrade_Perk_Symbiote_Helper SymbioteHelper;
    
    // Base reload bonus from levels (copy original pattern)
    ReloadBonus = default.ReloadSpeed * upgLevel;
    
    // Add evolution bonuses if available
    if (OwnerPawn != None)
    {
        SymbioteHelper = GetHelper(OwnerPawn);
        if (SymbioteHelper != None)
        {
            ReloadBonus += SymbioteHelper.GetEvolutionBonus("ReloadSpeed");
        }
    }
    
    // Use exact same formula as original Symbiote
    InReloadRateScale = 1.f / (1.f/InReloadRateScale + ReloadBonus);
}

// ===================================================================
// WEAPON SWITCH SPEED MODIFICATION
// ===================================================================

static simulated function ModifyWeaponSwitchTime(out float InSwitchTime, float DefaultSwitchTime, int upgLevel, KFWeapon KFW)
{
    local float TotalSwitchBonus;
    local ZTUpgrade_Perk_Symbiote_Helper SymbioteHelper;
    local KFPawn OwnerPawn;
    
    // Base switch speed bonus from levels
    TotalSwitchBonus = default.WeaponSwitchSpeed * upgLevel;
    
    // Get OwnerPawn from weapon
    if (KFW != None && KFW.Instigator != None)
    {
        OwnerPawn = KFPawn(KFW.Instigator);
        SymbioteHelper = GetHelper(OwnerPawn);
        if (SymbioteHelper != None)
        {
            TotalSwitchBonus += SymbioteHelper.GetEvolutionBonus("WeaponSwitchSpeed");
        }
    }
    
    InSwitchTime = DefaultSwitchTime / (DefaultSwitchTime / InSwitchTime + TotalSwitchBonus);
}

// ===================================================================
// PENETRATION MODIFICATION
// ===================================================================

static simulated function ModifyPenetration(out float InPenetration, float DefaultPenetration, int upgLevel, class<KFDamageType> DamageType, KFPawn OwnerPawn, optional bool bForce)
{
    local float TotalPenetrationBonus;
    local ZTUpgrade_Perk_Symbiote_Helper SymbioteHelper;
    
    // Base penetration bonus from levels
    TotalPenetrationBonus = default.PenetrationBonus * upgLevel;
    
    // Add evolution bonuses if available
    if (OwnerPawn != None)
    {
        SymbioteHelper = GetHelper(OwnerPawn);
        if (SymbioteHelper != None)
        {
            TotalPenetrationBonus += SymbioteHelper.GetEvolutionBonus("Penetration");
        }
    }
    
    InPenetration += DefaultPenetration * TotalPenetrationBonus;
}

// ===================================================================
// DAMAGE MODIFICATION
// ===================================================================

static function ModifyDamageGiven(out int InDamage, int DefaultDamage, int upgLevel, optional Actor DamageCauser, optional KFPawn_Monster MyKFPM, optional KFPlayerController DamageInstigator, optional class<KFDamageType> DamageType, optional int HitZoneIdx, optional KFWeapon MyKFW)
{
    local float TotalDamageBonus;
    local ZTUpgrade_Perk_Symbiote_Helper SymbioteHelper;
    
    if (MyKFPM == None || DamageInstigator == None) return;
    
    TotalDamageBonus = 0.0f;
    
    // Level 20 massive damage bonus
    if (upgLevel >= class'ZTConfig_Capstone'.default.Capstone_Rank2Level)
    {
        TotalDamageBonus += default.Level20DamageBonus;
    }
    
    // Add evolution bonuses if available
    if (DamageInstigator.Pawn != None)
    {
        SymbioteHelper = GetHelper(DamageInstigator.Pawn);
        if (SymbioteHelper != None)
        {
            TotalDamageBonus += SymbioteHelper.GetEvolutionBonus("Damage");
            
            // Headshot evolution bonus
            if (HitZoneIdx == HZI_HEAD)
            {
                TotalDamageBonus += SymbioteHelper.GetEvolutionBonus("HeadshotDamage");
            }
        }
    }
    
    // Apply damage bonus
    InDamage += Round(float(DefaultDamage) * TotalDamageBonus);
    
    // Track kill for evolution (if this damage will kill the monster)
    if (InDamage >= MyKFPM.Health && DamageInstigator.Pawn != None)
    {
        SymbioteHelper = GetHelper(DamageInstigator.Pawn);
        if (SymbioteHelper != None)
        {
            SymbioteHelper.TrackKill(MyKFPM); // Pass the monster reference
        }
    }
}

// ===================================================================
// AMMO CAPACITY MODIFICATIONS
// ===================================================================

static simulated function ModifySpareAmmoAmount(out int InSpareAmmo, int DefaultSpareAmmo, int upgLevel, KFWeapon KFW, optional const out STraderItem TraderItem, optional bool bSecondary=false)
{
    local ZTUpgrade_Perk_Symbiote_Helper SymbioteHelper;
    local KFPawn OwnerPawn;
    
    // Level 10 spare ammo bonus - use same pattern as original
    if (upgLevel >= class'ZTConfig_Capstone'.default.Capstone_Rank1Level)
    {
        InSpareAmmo += int(float(DefaultSpareAmmo) * default.Level10SpareAmmoBonus);
    }
    
    // Add evolution bonuses if available
    if (KFW != None && KFW.Instigator != None)
    {
        OwnerPawn = KFPawn(KFW.Instigator);
        SymbioteHelper = GetHelper(OwnerPawn);
        if (SymbioteHelper != None)
        {
            InSpareAmmo += int(float(DefaultSpareAmmo) * SymbioteHelper.GetEvolutionBonus("SpareAmmo"));
        }
    }
}

static simulated function ModifyMagSizeAndNumber(out int InMagazineCapacity, int DefaultMagazineCapacity, int upgLevel, KFWeapon KFW, optional array< Class<KFPerk> > WeaponPerkClass, optional bool bSecondary=False, optional name WeaponClassname)
{
    local ZTUpgrade_Perk_Symbiote_Helper SymbioteHelper;
    local KFPawn OwnerPawn;
    
    // Get OwnerPawn from weapon
    if (KFW != None && KFW.Instigator != None)
    {
        OwnerPawn = KFPawn(KFW.Instigator);
        SymbioteHelper = GetHelper(OwnerPawn);
        if (SymbioteHelper != None)
        {
            InMagazineCapacity += int(float(DefaultMagazineCapacity) * SymbioteHelper.GetEvolutionBonus("MagazineSize"));
        }
    }
}

// ===================================================================
// MOVEMENT SPEED MODIFICATION
// ===================================================================

static simulated function ModifySpeed(out float InSpeed, float DefaultSpeed, int upgLevel, KFPawn OwnerPawn)
{
    local ZTUpgrade_Perk_Symbiote_Helper SymbioteHelper;
    
    // Add evolution bonuses if available
    if (OwnerPawn != None)
    {
        SymbioteHelper = GetHelper(OwnerPawn);
        if (SymbioteHelper != None)
        {
            InSpeed += DefaultSpeed * SymbioteHelper.GetEvolutionBonus("MovementSpeed");
        }
    }
}

// ===================================================================
// STUN AND KNOCKDOWN MODIFICATIONS
// ===================================================================

static function ModifyStunPower(out float InStunPower, float DefaultStunPower, int upgLevel, optional class<DamageType> DamageType, optional byte HitZoneIdx)
{
    local float TotalStunBonus;
    
    TotalStunBonus = 0.0f;
    
    // Level 10 stun bonus
    if (upgLevel >= class'ZTConfig_Capstone'.default.Capstone_Rank1Level)
    {
        TotalStunBonus += default.Level10StunBonus;
    }
    
    InStunPower += DefaultStunPower * TotalStunBonus;
}

static function ModifyKnockdownPower(out float InKnockdownPower, float DefaultKnockdownPower, int upgLevel, KFPawn OwnerPawn, optional class<DamageType> DamageType, optional byte BodyPart, optional bool bIsSprinting=False)
{
    // Level 20 massive knockdown bonus
    if (upgLevel >= class'ZTConfig_Capstone'.default.Capstone_Rank2Level)
    {
        InKnockdownPower += default.Level20KnockdownBonus;
    }
}

// ===================================================================
// SPECIAL ABILITIES
// ===================================================================

// Other level-based abilities
static simulated function bool CanSeeEnemyHealth(int upgLevel, KFPawn OwnerPawn)
{
    return upgLevel >= 3;
}

static simulated function bool ProjSirenResist(int upgLevel, KFPawn OwnerPawn)
{
    return upgLevel >= 6;
}

static simulated function bool IsCallOutActive(int upgLevel, KFPawn OwnerPawn)
{
    return upgLevel >= 9;
}

// ===================================================================
// HELPER CLASS MANAGEMENT
// ===================================================================

// Helper class management functions
static simulated function InitiateWeapon(int upgLevel, KFWeapon KFW, KFPawn OwnerPawn)
{
    local ZTUpgrade_Perk_Symbiote_Helper SymbioteHelper;
    local bool bFound;

    if (KFPawn_Human(OwnerPawn) != None && OwnerPawn.Role == Role_Authority)
    {
        bFound = False;
        foreach OwnerPawn.ChildActors(class'ZTUpgrade_Perk_Symbiote_Helper', SymbioteHelper)
        {
            bFound = True;
            break;
        }

        if (!bFound)
            SymbioteHelper = OwnerPawn.Spawn(class'ZTUpgrade_Perk_Symbiote_Helper', OwnerPawn);
    }
}

static function ZTUpgrade_Perk_Symbiote_Helper GetHelper(Pawn OwnerPawn)
{
    local ZTUpgrade_Perk_Symbiote_Helper SymbioteHelper;

    if (KFPawn_Human(OwnerPawn) != None)
    {
        foreach OwnerPawn.ChildActors(class'ZTUpgrade_Perk_Symbiote_Helper', SymbioteHelper)
        {
            return SymbioteHelper;
        }

        // Should have one
        SymbioteHelper = OwnerPawn.Spawn(class'ZTUpgrade_Perk_Symbiote_Helper', OwnerPawn);
    }

    return SymbioteHelper;
}

static simulated function DeleteHelperClass(Pawn OwnerPawn)
{
    local ZTUpgrade_Perk_Symbiote_Helper SymbioteHelper;

    if (OwnerPawn != None)
    {
        foreach OwnerPawn.ChildActors(class'ZTUpgrade_Perk_Symbiote_Helper', SymbioteHelper)
        {
            SymbioteHelper.Destroy();
        }
    }
}

// ===================================================================
// UTILITY FUNCTIONS FOR OTHER SYSTEMS
// ===================================================================

// Enhanced version of GetEvolutionBonus helper function for other classes to use
static function float GetSymbioteEvolutionBonus(KFPawn OwnerPawn, string BonusType)
{
    local ZTUpgrade_Perk_Symbiote_Helper Helper;
    
    if (OwnerPawn == None)
        return 0.0f;
    
    Helper = GetHelper(OwnerPawn);
    if (Helper != None)
    {
        return Helper.GetEvolutionBonus(BonusType);
    }
    
    return 0.0f;
}

// Get total evolution count for this player
static function int GetEvolutionCount(KFPawn OwnerPawn)
{
    local ZTUpgrade_Perk_Symbiote_Helper Helper;
    
    if (OwnerPawn == None)
        return 0;
    
    Helper = GetHelper(OwnerPawn);
    if (Helper != None)
    {
        return Helper.TotalEvolutions;
    }
    
    return 0;
}

// Force an evolution (for testing/admin purposes)
static function ForceRandomEvolution(KFPawn OwnerPawn)
{
    local ZTUpgrade_Perk_Symbiote_Helper Helper;
    local KFPlayerController KFPC;
    
    if (OwnerPawn == None)
        return;
    
    Helper = GetHelper(OwnerPawn);
    KFPC = KFPlayerController(OwnerPawn.Controller);
    
    if (Helper != None && KFPC != None)
    {
        Helper.ApplyRandomEvolution(KFPC);
    }
}

defaultproperties
{
	UpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Symbiote_Rank_0'
    // --- Localization (auto-generated by mass_localize_dk_upgrades.py) ---
    // Strings live in KFGame/Localization/<lang>/ZedternalTempered.<langext>
    // Section: [ZTUpgrade_Perk_Symbiote]  -- see DKUpgrade_* base class for details.
    bShouldLocalize=True
    LocPackage="ZedternalTempered"
    LocSection="ZTUpgrade_Perk_Symbiote"
    LocalizeDescriptionLineCount=9

    // Linear bonuses per level
    
    // Level 10 "Parasitic Integration" bonuses
    
    // Level 20 "Perfect Organism" bonuses
    
    UpgradeName="Symbiote"

    // PerkBonus for UI display
    PerkBonus(0)=(baseValue=0, incValue=2, maxValue=-1)    // Reload speed %
    PerkBonus(1)=(baseValue=0, incValue=2, maxValue=-1)    // Weapon switch speed %
    PerkBonus(2)=(baseValue=0, incValue=5, maxValue=-1)    // Penetration %
    PerkBonus(3)=(baseValue=25, incValue=0, maxValue=25)   // Level 10 spare ammo % (fixed at 50%)
    PerkBonus(4)=(baseValue=13, incValue=0, maxValue=13)   // Level 20 damage % (fixed at 25%)
    
    // Upgrade descriptions with Symbiote evolution theme
    UpgradeDescription(0)="<font color=\"#00FF7F\">Symbiotic Efficiency:</font> <font color=\"#FFFFFF\">+%x%%</font> <font color=\"#7FFF7F\">Reload Speed</font>"
    UpgradeDescription(1)="<font color=\"#00FF7F\">Neural Interface:</font> <font color=\"#FFFFFF\">+%x%%</font> <font color=\"#7FFF7F\">Weapon Switch Speed</font>"
    UpgradeDescription(2)="<font color=\"#00FF7F\">Hardened Carapace:</font> <font color=\"#FFFFFF\">+%x%%</font> <font color=\"#7FFF7F\">Penetration</font>"
    UpgradeDescription(3)="<font color=\"#4B0082\">LEVEL 3:</font> <font color=\"#FFD700\">Parasitic Sight</font> - See <font color=\"#7FFF7F\">Enemy Health Bars</font>"
    UpgradeDescription(4)="<font color=\"#4B0082\">LEVEL 6:</font> <font color=\"#FFD700\">Adaptive Resistance</font> - <font color=\"#7FFF7F\">Siren Immunity</font>"
    UpgradeDescription(5)="<font color=\"#4B0082\">LEVEL 9:</font> <font color=\"#FFD700\">Enhanced Senses</font> - Always see <font color=\"#7FFF7F\">Cloaked Enemies</font>"
    UpgradeDescription(6)="<font color=\"#8B0000\">LEVEL 10:</font> <font color=\"#FFD700\">Parasitic Integration</font> - <font color=\"#FFFFFF\">+25%</font> <font color=\"#7FFF7F\">Spare Ammo</font> and <font color=\"#FFFFFF\">+15%</font> <font color=\"#7FFF7F\">Stun Power</font>"
    UpgradeDescription(7)="<font color=\"#8B0000\">LEVEL 20:</font> <font color=\"#FFD700\">Perfect Organism</font> - <font color=\"#FFFFFF\">+12.5%</font> <font color=\"#7FFF7F\">Damage</font> and massive <font color=\"#7FFF7F\">Knockdown Power</font>"
    UpgradeDescription(8)="<font color=\"#FFD700\">Adaptive Mutation</font>: Every <font color=\"#FFFFFF\">100</font> kills grants a random permanent <font color=\"#7FFF7F\">stat boost</font>. Stacks infinitely"
    
    // Placeholder icons - you'll need to create actual textures
    
	// Legacy (hand-made) artwork icons

    Name="Default__ZTUpgrade_Perk_Symbiote"
}