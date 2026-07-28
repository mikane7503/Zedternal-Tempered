class DKUpgrade_Perk_Hydra extends DKUpgrade_Perk
	config(ZedternalUnlimited);

// Theme: "Hydra" - Multi-strike fury, overwhelming offense, cascading damage
// Special mechanics: Twin strikes at level 10, Fury Mode at level 20

var config float RateOfFireBonus;         // Rate of fire increase per level
var config float PenetrationBonus;        // Penetration bonus per level  
var config float MagazineSizeBonus;       // Magazine size increase per level

// Level 10 special bonus - Twin Strikes
var config float TwinStrikeChance;        // Chance for twin strikes at level 10+

// Level 20 special bonus - Fury Mode (UPDATED: No infinite ammo, added damage multiplier)
var config float FuryModeRateOfFireMult;  // Rate of fire multiplier during fury mode
var config float FuryModeDamageMult;      // Damage multiplier during fury mode (3x damage)
var config float FuryModeDuration;        // Duration of fury mode in seconds
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.RateOfFireBonus = 0.02f;
		default.PenetrationBonus = 0.20f;
		default.MagazineSizeBonus = 0.05f;
		default.TwinStrikeChance = 0.45f;
		default.FuryModeRateOfFireMult = 1.0f;
		default.FuryModeDamageMult = 3.0f;
		default.FuryModeDuration = 8.0f;

		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}


static simulated function ModifyRateOfFire(out float InRate, float DefaultRate, int upgLevel, KFWeapon KFW)
{
    local DKUpgrade_Perk_Hydra_Helper HydraHelper;
    local KFPawn OwnerPawn;
    local float TotalRateBonus;
    
    if (KFW == None) return;
    
    // Get the owner pawn more reliably
    OwnerPawn = KFPawn(KFW.Instigator);
    if (OwnerPawn == None)
    {
        OwnerPawn = KFPawn(KFW.Owner);
    }
    if (OwnerPawn == None) return;
    
    // Get the helper to check for fury mode
    HydraHelper = GetHelper(OwnerPawn);
    
    // Calculate total rate of fire bonus
    TotalRateBonus = default.RateOfFireBonus * upgLevel;
    
    // Add fury mode bonus if active
    if (HydraHelper != None && HydraHelper.bInFuryMode)
    {
        TotalRateBonus += default.FuryModeRateOfFireMult;
        
        // Show fury mode is active
        if (KFPlayerController(OwnerPawn.Controller) != None)
        {
            KFPlayerController(OwnerPawn.Controller).ClientMessage("FURY MODE ACTIVE: +" $ int(default.FuryModeRateOfFireMult * 100) $ "% Fire Rate + Triple Damage!", 'Event');
        }
    }
    
    // Apply the rate of fire bonus via INV-ADD so we COMPOSE with other RoF
    // contributors instead of overwriting them. Old code did
    // `InRate = DefaultRate * (1 + bonus)` which wiped every other perk's
    // and skill's RoF modification.
    if (TotalRateBonus > 0.0f)
        InRate = DefaultRate / (DefaultRate / InRate + TotalRateBonus);
}

static simulated function ModifyPenetration(out float InPenetration, float DefaultPenetration, int upgLevel, class<KFDamageType> DamageType, KFPawn OwnerPawn, optional bool bForce)
{
    local float TotalPenetrationBonus;
    
    // Linear penetration scaling. Use += so we compose with other penetration
    // contributors (Hollow, ArmorPiercingProtocol, etc.) instead of stomping
    // them. Old code did `InPenetration = DefaultPenetration * (1 + bonus)`
    // which discarded every other contribution.
    TotalPenetrationBonus = default.PenetrationBonus * upgLevel;
    InPenetration += DefaultPenetration * TotalPenetrationBonus;
}

static simulated function ModifyMagSizeAndNumber(out int InMagazineCapacity, int DefaultMagazineCapacity, int upgLevel, KFWeapon KFW, optional array< Class<KFPerk> > WeaponPerkClass, optional bool bSecondary=False, optional name WeaponClassname)
{
    local float TotalMagBonus;
    
    // Linear magazine size scaling. Switch from compound multiplicative
    // (`InMagazineCapacity *= (1+bonus)`) to additive on the default so the
    // bonus stays additive with other mag-size contributors.
    TotalMagBonus = default.MagazineSizeBonus * upgLevel;
    InMagazineCapacity += Round(float(DefaultMagazineCapacity) * TotalMagBonus);
}

static function ModifyDamageGiven(out int InDamage, int DefaultDamage, int upgLevel, optional Actor DamageCauser, optional KFPawn_Monster MyKFPM, optional KFPlayerController DamageInstigator, optional class<KFDamageType> DamageType, optional int HitZoneIdx, optional KFWeapon MyKFW)
{
    local DKUpgrade_Perk_Hydra_Helper HydraHelper;
    local bool bTwinStrike;
    
    if (MyKFPM == None || DamageInstigator == None) return;
    
    // Get helper for fury mode and twin strike bonuses
    if (DamageInstigator.Pawn != None)
    {
        HydraHelper = GetHelper(DamageInstigator.Pawn);
    }
    
    // NEW: Apply fury mode triple damage bonus first (level 20 feature)
    if (upgLevel >= class'DKConfig_Capstone'.default.Capstone_Rank2Level && HydraHelper != None && HydraHelper.bInFuryMode)
    {
        InDamage = Round(float(InDamage) * default.FuryModeDamageMult);
    }
    
    // Twin Strikes feature at level 10+ (45% chance for double hit)
    if (upgLevel >= class'DKConfig_Capstone'.default.Capstone_Rank1Level)
    {
        bTwinStrike = (FRand() <= default.TwinStrikeChance);
        if (bTwinStrike)
        {
            // Double the damage for twin strikes (applied after fury mode bonus)
            InDamage = InDamage * 2;
            
            // Show twin strike notification
            if (HydraHelper != None)
            {
                HydraHelper.ShowTwinStrikeNotification();
            }
        }
    }
    
    // Track kill for Fury Mode (Level 20 feature)
    if (upgLevel >= class'DKConfig_Capstone'.default.Capstone_Rank2Level && InDamage >= MyKFPM.Health && DamageInstigator.Pawn != None)
    {
        if (HydraHelper != None)
        {
            HydraHelper.TrackKill(MyKFPM);
        }
    }
}

// Helper class management functions
static simulated function InitiateWeapon(int upgLevel, KFWeapon KFW, KFPawn OwnerPawn)
{
    local DKUpgrade_Perk_Hydra_Helper HydraHelper;
    local bool bFound;

    if (KFPawn_Human(OwnerPawn) != None && OwnerPawn.Role == Role_Authority)
    {
        bFound = False;
        foreach OwnerPawn.ChildActors(class'DKUpgrade_Perk_Hydra_Helper', HydraHelper)
        {
            bFound = True;
            break;
        }

        if (!bFound)
            HydraHelper = OwnerPawn.Spawn(class'DKUpgrade_Perk_Hydra_Helper', OwnerPawn);
    }
}

static function DKUpgrade_Perk_Hydra_Helper GetHelper(Pawn OwnerPawn)
{
    local DKUpgrade_Perk_Hydra_Helper HydraHelper;

    if (KFPawn_Human(OwnerPawn) != None)
    {
        foreach OwnerPawn.ChildActors(class'DKUpgrade_Perk_Hydra_Helper', HydraHelper)
        {
            return HydraHelper;
        }

        // Should have one
        HydraHelper = OwnerPawn.Spawn(class'DKUpgrade_Perk_Hydra_Helper', OwnerPawn);
    }

    return HydraHelper;
}

static simulated function DeleteHelperClass(Pawn OwnerPawn)
{
    local DKUpgrade_Perk_Hydra_Helper HydraHelper;

    if (OwnerPawn != None)
    {
        foreach OwnerPawn.ChildActors(class'DKUpgrade_Perk_Hydra_Helper', HydraHelper)
        {
            HydraHelper.Destroy();
        }
    }
}

defaultproperties
{
    
    // --- Localization (auto-generated by mass_localize_dk_upgrades.py) ---
    // Strings live in KFGame/Localization/<lang>/ZedternalRBPerkpackage.<langext>
    // Section: [DKUpgrade_Perk_Hydra]  -- see DKUpgrade_* base class for details.
    bShouldLocalize=True
    LocPackage="ZedternalRBPerkpackage"
    LocSection="DKUpgrade_Perk_Hydra"
    LocalizeDescriptionLineCount=5

    // Level 10 "Twin Strikes" bonus
    
    // Level 20 "Fury Mode" bonuses (UPDATED: Removed infinite ammo, added damage multiplier)
    
    UpgradeName="Hydra"

    // PerkBonus for UI display (updated values)
    PerkBonus(0)=(baseValue=0, incValue=2, maxValue=-1)    // Rate of fire %
    PerkBonus(1)=(baseValue=0, incValue=20, maxValue=-1)   // Penetration %
    PerkBonus(2)=(baseValue=0, incValue=5, maxValue=-1)    // Magazine size %
    PerkBonus(3)=(baseValue=45, incValue=0, maxValue=45)   // Twin strike chance %
    PerkBonus(4)=(baseValue=300, incValue=0, maxValue=300) // Fury mode damage multiplier % (300% = 3x)
    
    // UPDATED: Upgrade descriptions with new fury mode bonuses
    UpgradeDescription(0)="<font color=\"#FF6600\">Hydra's Fury:</font> <font color=\"#FFFFFF\">+%x%%</font> <font color=\"#FF9933\">Rate of Fire</font>"
    UpgradeDescription(1)="<font color=\"#FF6600\">Serpent Strike:</font> <font color=\"#FFFFFF\">+%x%%</font> <font color=\"#FF9933\">Penetration</font>"
    UpgradeDescription(2)="<font color=\"#FF6600\">Endless Ammunition:</font> <font color=\"#FFFFFF\">+%x%%</font> <font color=\"#FF9933\">Magazine Capacity</font>"
    UpgradeDescription(3)="<font color=\"#8B0000\">LEVEL 10:</font> <font color=\"#FFD700\">Twin Strikes</font> - <font color=\"#FFFFFF\">45%</font> chance for attacks to <font color=\"#FF9933\">hit twice</font>"
    UpgradeDescription(4)="<font color=\"#8B0000\">LEVEL 20:</font> <font color=\"#FFD700\">Fury Mode</font> - Every <font color=\"#FFFFFF\">75 kills</font> triggers <font color=\"#FF9933\">Fury Mode</font>: <font color=\"#FFFFFF\">+100%</font> Rate of Fire and <font color=\"#FFFFFF\">Triple Damage</font> for <font color=\"#FFFFFF\">8 seconds</font>"
    
    // Placeholder icons - you'll need to create actual textures
    UpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Hydra_Legacy_Rank_0'
    UpgradeIcon(1)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Hydra_Legacy_Rank_1'
    UpgradeIcon(2)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Hydra_Legacy_Rank_2'
    UpgradeIcon(3)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Hydra_Legacy_Rank_3'
    UpgradeIcon(4)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Hydra_Legacy_Rank_4'
    UpgradeIcon(5)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Hydra_Legacy_Rank_5'
    UpgradeIcon(6)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Hydra_Legacy_Rank_5'
    UpgradeIcon(7)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Hydra_Legacy_Rank_5'
    UpgradeIcon(8)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Hydra_Legacy_Rank_5'
    UpgradeIcon(9)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Hydra_Legacy_Rank_5'
    UpgradeIcon(10)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Hydra_Legacy_Rank_5'
    UpgradeIcon(11)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Hydra_Legacy_Rank_5'
    UpgradeIcon(12)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Hydra_Legacy_Rank_5'
    UpgradeIcon(13)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Hydra_Legacy_Rank_5'
    UpgradeIcon(14)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Hydra_Legacy_Rank_5'
    UpgradeIcon(15)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Hydra_Legacy_Rank_5'
    UpgradeIcon(16)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Hydra_Legacy_Rank_5'
    UpgradeIcon(17)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Hydra_Legacy_Rank_5'
    UpgradeIcon(18)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Hydra_Legacy_Rank_5'
    UpgradeIcon(19)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Hydra_Legacy_Rank_5'
    UpgradeIcon(20)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Hydra_Legacy_Rank_5'
    
	// Legacy (hand-made) artwork icons
	LegacyUpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Hydra_Legacy_Rank_0'
	LegacyUpgradeIcon(1)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Hydra_Legacy_Rank_1'
	LegacyUpgradeIcon(2)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Hydra_Legacy_Rank_2'
	LegacyUpgradeIcon(3)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Hydra_Legacy_Rank_3'
	LegacyUpgradeIcon(4)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Hydra_Legacy_Rank_4'
	LegacyUpgradeIcon(5)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Hydra_Legacy_Rank_5'
	LegacyUpgradeIcon(6)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Hydra_Legacy_Rank_5'
	LegacyUpgradeIcon(7)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Hydra_Legacy_Rank_5'
	LegacyUpgradeIcon(8)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Hydra_Legacy_Rank_5'
	LegacyUpgradeIcon(9)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Hydra_Legacy_Rank_5'
	LegacyUpgradeIcon(10)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Hydra_Legacy_Rank_5'
	LegacyUpgradeIcon(11)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Hydra_Legacy_Rank_5'
	LegacyUpgradeIcon(12)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Hydra_Legacy_Rank_5'
	LegacyUpgradeIcon(13)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Hydra_Legacy_Rank_5'
	LegacyUpgradeIcon(14)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Hydra_Legacy_Rank_5'
	LegacyUpgradeIcon(15)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Hydra_Legacy_Rank_5'
	LegacyUpgradeIcon(16)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Hydra_Legacy_Rank_5'
	LegacyUpgradeIcon(17)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Hydra_Legacy_Rank_5'
	LegacyUpgradeIcon(18)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Hydra_Legacy_Rank_5'
	LegacyUpgradeIcon(19)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Hydra_Legacy_Rank_5'
	LegacyUpgradeIcon(20)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Hydra_Legacy_Rank_5'

    Name="Default__DKUpgrade_Perk_Hydra"
}