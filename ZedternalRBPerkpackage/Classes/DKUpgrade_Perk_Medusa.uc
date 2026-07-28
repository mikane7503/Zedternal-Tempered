class DKUpgrade_Perk_Medusa extends DKUpgrade_Perk
	config(ZedternalUnlimited);

// Theme: "Medusa" - A venomous perk focused on poison damage and serpentine transformation
// Special mechanics: Poison application, venom spreading, Toxic Metamorphosis progression

var config float HeadshotDamage;      // Headshot damage bonus per level (Toxic Precision)
var config float ReloadSpeed;         // Reload speed increase per level (Serpentine Speed)
var config float SpareAmmo;           // Spare ammo increase per level (Venom Reserves)

// Poison mechanics
var config int PoisonDamagePerSecond; // Poison damage per second
var config float PoisonDuration;      // How long poison lasts
var config float VenomSpreadChance;   // Chance to spread poison on kill at level 20
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.HeadshotDamage = 0.03f;
		default.ReloadSpeed = 0.02f;
		default.SpareAmmo = 0.03f;
		default.PoisonDamagePerSecond = 5;
		default.PoisonDuration = 5.0f;
		default.VenomSpreadChance = 1.0f;

		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}


static function ModifyDamageGiven(out int InDamage, int DefaultDamage, int upgLevel, optional Actor DamageCauser, optional KFPawn_Monster MyKFPM, optional KFPlayerController DamageInstigator, optional class<KFDamageType> DamageType, optional int HitZoneIdx, optional KFWeapon MyKFW)
{
    local DKUpgrade_Perk_Medusa_Helper MedusaHelper;
    local float HeadshotBonus;
    local KFPawn_Monster NearbyMonster;
    local array<KFPawn_Monster> NearbyMonsters;
    local float Distance;
    local int i;
    
    if (MyKFPM == None || DamageInstigator == None) return;
    
    // Get helper for tracking and bonuses
    if (DamageInstigator.Pawn != None)
    {
        MedusaHelper = GetHelper(DamageInstigator.Pawn);
    }
    
    // UPDATED: Track actual poison damage per tick and apply Full Gorgon poison DoT bonus
    if (DamageType != None && ClassIsChildOf(DamageType, class'DKDT_Medusa_Poison'))
    {
        if (MedusaHelper != None)
        {
            // Track the per-tick poison damage (should be 5 damage per tick)
            MedusaHelper.TrackActualPoisonDamage(InDamage, MyKFPM);
            
            // Apply Full Gorgon poison DoT bonus if achieved
            if (MedusaHelper.bFullGorgonAchieved)
            {
                InDamage += Round(float(InDamage) * MedusaHelper.PermanentPoisonBonus);
            }
        }
    }
    
    // Apply headshot damage bonus (base perk only)
    if (HitZoneIdx == HZI_HEAD)
    {
        HeadshotBonus = default.HeadshotDamage * upgLevel;
        InDamage += Round(float(DefaultDamage) * HeadshotBonus);
    }
    
    // Level 10+: Apply poison to all damage (except poison damage itself to avoid recursion)
    if (upgLevel >= class'DKConfig_Capstone'.default.Capstone_Rank1Level && (DamageType == None || !ClassIsChildOf(DamageType, class'DKDT_Medusa_Poison')))
    {
        ApplyPoisonToMonster(MyKFPM, DamageInstigator);
    }
    
    // FIXED: Level 20+: Dramatically increased venom spreading range (15m instead of 5m)
    if (upgLevel >= class'DKConfig_Capstone'.default.Capstone_Rank2Level && InDamage >= MyKFPM.Health)
    {
        // Find all monsters within 15m of the killed monster (was 5m)
        foreach MyKFPM.CollidingActors(class'KFPawn_Monster', NearbyMonster, 1500.0f) // 15m = 1500 units (3x larger)
        {
            if (NearbyMonster != MyKFPM && NearbyMonster.Health > 0)
            {
                Distance = VSize(NearbyMonster.Location - MyKFPM.Location);
                if (Distance <= 1500.0f) // 15m radius
                {
                    NearbyMonsters.AddItem(NearbyMonster);
                }
            }
        }
        
        // Apply poison to nearby monsters (100% chance, no spam message)
        for (i = 0; i < NearbyMonsters.Length; i++)
        {
            ApplyPoisonToMonster(NearbyMonsters[i], DamageInstigator);
        }
    }
}

// FIXED: Apply poison effect using proper per-tick damage
static function ApplyPoisonToMonster(KFPawn_Monster Monster, KFPlayerController PC)
{
    if (Monster == None || PC == None || PC.Pawn == None) return;
    
    // Don't re-poison already poisoned monsters (unless we want to reset duration)
    if (Monster.bIsPoisoned) return;
    
    // FIXED: Apply poison DoT with per-tick damage (2 per tick, not total 10)
    // This should result in 2 damage per second for 5 seconds = 10 total damage
    Monster.ApplyDamageOverTime(default.PoisonDamagePerSecond, PC, class'DKDT_Medusa_Poison');
}

// Apply reload speed bonus from Serpentine Speed + current scales
static simulated function GetReloadRateScale(out float InReloadRateScale, int upgLevel, KFWeapon KFW, KFPawn OwnerPawn)
{
    local DKUpgrade_Perk_Medusa_Helper MedusaHelper;
    local float ReloadSpeedBonus;
    
    // Base reload speed bonus from perk level
    ReloadSpeedBonus = default.ReloadSpeed * upgLevel;
    
    // Get current serpent scales bonus if we have access to the helper
    if (OwnerPawn != None)
    {
        MedusaHelper = GetHelper(OwnerPawn);
        if (MedusaHelper != None && MedusaHelper.CurrentScales > 0)
        {
            // Each scale provides additional 1% reload speed
            ReloadSpeedBonus += MedusaHelper.CurrentScales * 0.01f;
        }
    }
    
    // Apply the reload speed bonus
    InReloadRateScale = 1.0f / (1.0f / InReloadRateScale + ReloadSpeedBonus);
}

// Apply spare ammo bonus from Venom Reserves
static simulated function ModifySpareAmmoAmount(out int InSpareAmmo, int DefaultSpareAmmo, int upgLevel, KFWeapon KFW, optional const out STraderItem TraderItem, optional bool bSecondary=False)
{
    if (!bSecondary && DefaultSpareAmmo > 0)
    {
        InSpareAmmo += Round(float(DefaultSpareAmmo) * default.SpareAmmo * upgLevel);
    }
}

// Note: Movement speed bonus from Serpent Scales is handled through the extension function system
// since it requires dynamic access to current scales rather than static perk level bonuses

// Note: Damage resistance bonus from Serpent Scales is handled through the extension function system
// since it requires dynamic access to current scales rather than static perk level bonuses

// Extension function for scale-based bonuses that need pawn context
static simulated function bool ExtensionFuncBoolean(int upgLevel, string Identifier, KFWeapon MyKFW, KFPawn OwnerPawn,
    optional int InputInt, optional float InputFloat, optional name InputClassName,
    optional Object InputObject1, optional Object InputObject2, optional Object InputObject3)
{
    local DKUpgrade_Perk_Medusa_Helper MedusaHelper;
    
    if (Identifier ~= "MedusaScaleBonus" && OwnerPawn != None)
    {
        MedusaHelper = GetHelper(OwnerPawn);
        if (MedusaHelper != None)
        {
            // Apply current scale bonuses
            // This is a way to get context-dependent bonuses
            return true;
        }
    }
    
    return false;
}

// Extension function for getting scale-based float bonuses
static simulated function ExtensionFuncFloat(out float InValue, float DefaultValue, int upgLevel, string Identifier,
    KFWeapon MyKFW, KFPawn OwnerPawn, optional int InputInt, optional float InputFloat, optional name InputClassName,
    optional Object InputObject1, optional Object InputObject2, optional Object InputObject3)
{
    local DKUpgrade_Perk_Medusa_Helper MedusaHelper;
    local float BonusValue;
    
    if (OwnerPawn == None) return;
    
    MedusaHelper = GetHelper(OwnerPawn);
    if (MedusaHelper == None) return;
    
    if (Identifier ~= "MedusaMovementSpeed")
    {
        // Apply movement speed bonus from current scales (+2% per scale)
        BonusValue = MedusaHelper.CurrentScales * 0.02f;
        InValue += BonusValue;
    }
    else if (Identifier ~= "MedusaDamageResistance")
    {
        // Apply damage resistance bonus from current scales (+3% per scale)
        BonusValue = MedusaHelper.CurrentScales * 0.03f;
        InValue = DefaultValue * (1.0f - BonusValue); // Damage reduction
    }
}

// Helper class management functions (copied from Reaper pattern)
static simulated function InitiateWeapon(int upgLevel, KFWeapon KFW, KFPawn OwnerPawn)
{
    local DKUpgrade_Perk_Medusa_Helper MedusaHelper;
    local bool bFound;

    if (KFPawn_Human(OwnerPawn) != None && OwnerPawn.Role == Role_Authority)
    {
        bFound = False;
        foreach OwnerPawn.ChildActors(class'DKUpgrade_Perk_Medusa_Helper', MedusaHelper)
        {
            bFound = True;
            break;
        }

        if (!bFound)
            MedusaHelper = OwnerPawn.Spawn(class'DKUpgrade_Perk_Medusa_Helper', OwnerPawn);
    }
}

static function DKUpgrade_Perk_Medusa_Helper GetHelper(Pawn OwnerPawn)
{
    local DKUpgrade_Perk_Medusa_Helper MedusaHelper;

    if (KFPawn_Human(OwnerPawn) != None)
    {
        foreach OwnerPawn.ChildActors(class'DKUpgrade_Perk_Medusa_Helper', MedusaHelper)
        {
            return MedusaHelper;
        }

        // Should have one
        MedusaHelper = OwnerPawn.Spawn(class'DKUpgrade_Perk_Medusa_Helper', OwnerPawn);
    }

    return MedusaHelper;
}

static simulated function DeleteHelperClass(Pawn OwnerPawn)
{
    local DKUpgrade_Perk_Medusa_Helper MedusaHelper;

    if (OwnerPawn != None)
    {
        foreach OwnerPawn.ChildActors(class'DKUpgrade_Perk_Medusa_Helper', MedusaHelper)
        {
            MedusaHelper.Destroy();
        }
    }
}

defaultproperties
{
    
    // --- Localization (auto-generated by mass_localize_dk_upgrades.py) ---
    // Strings live in KFGame/Localization/<lang>/ZedternalRBPerkpackage.<langext>
    // Section: [DKUpgrade_Perk_Medusa]  -- see DKUpgrade_* base class for details.
    bShouldLocalize=True
    LocPackage="ZedternalRBPerkpackage"
    LocSection="DKUpgrade_Perk_Medusa"
    LocalizeDescriptionLineCount=6

    // FIXED: Poison mechanics - use per-tick damage (5) for more impact
    
    UpgradeName="Medusa"

    // PerkBonus for UI display
    PerkBonus(0)=(baseValue=0, incValue=3, maxValue=-1)    // Headshot damage %
    PerkBonus(1)=(baseValue=0, incValue=2, maxValue=-1)    // Reload speed %
    PerkBonus(2)=(baseValue=0, incValue=3, maxValue=-1)    // Spare ammo %
    PerkBonus(3)=(baseValue=5, incValue=0, maxValue=5)     // Poison damage per second (fixed at 5)
    PerkBonus(4)=(baseValue=100, incValue=0, maxValue=100) // Venom spread chance % (100%)
    PerkBonus(5)=(baseValue=2500, incValue=0, maxValue=2500) // Poison damage per scale (fixed at 2500)
    
    // UPDATED: Upgrade descriptions with new 15m spread range
    UpgradeDescription(0)="<font color=\"#8B008B\">Toxic Precision:</font> <font color=\"#FFFFFF\">+%x%%</font> <font color=\"#9966FF\">Headshot Damage</font>"
    UpgradeDescription(1)="<font color=\"#8B008B\">Serpentine Speed:</font> <font color=\"#FFFFFF\">+%x%%</font> <font color=\"#9966FF\">Reload Speed</font>"
    UpgradeDescription(2)="<font color=\"#8B008B\">Venom Reserves:</font> <font color=\"#FFFFFF\">+%x%%</font> <font color=\"#9966FF\">Spare Ammo</font>"
    UpgradeDescription(3)="<font color=\"#8B0000\">LEVEL 10:</font> <font color=\"#FFD700\">Poison Touch</font> - All damage applies <font color=\"#8B008B\">poison</font> (<font color=\"#FFFFFF\">5</font> damage/sec for <font color=\"#FFFFFF\">5s</font>)"
    UpgradeDescription(4)="<font color=\"#8B0000\">LEVEL 20:</font> <font color=\"#FFD700\">Gorgon's Venom</font> - Kills spread <font color=\"#8B008B\">poison</font> to enemies within <font color=\"#FFFFFF\">15m</font>"
    UpgradeDescription(5)="Every <font color=\"#FFFFFF\">2500</font> <font color=\"#8B008B\">poison damage</font> grants a <font color=\"#FFD700\">Serpent Scale</font> (<font color=\"#FFFFFF\">+3%</font> Resistance, <font color=\"#FFFFFF\">+2%</font> Speed). At <font color=\"#FFFFFF\">6 scales</font>: <font color=\"#FFD700\">Full Gorgon</font> (<font color=\"#FFFFFF\">+100%</font> poison damage)"
    
    // Placeholder icons - you'll need to create actual textures
    UpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Medusa_Legacy_Rank_0'
    UpgradeIcon(1)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Medusa_Legacy_Rank_1'
    UpgradeIcon(2)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Medusa_Legacy_Rank_2'
    UpgradeIcon(3)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Medusa_Legacy_Rank_3'
    UpgradeIcon(4)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Medusa_Legacy_Rank_4'
    UpgradeIcon(5)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Medusa_Legacy_Rank_5'
    UpgradeIcon(6)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Medusa_Legacy_Rank_5'
    UpgradeIcon(7)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Medusa_Legacy_Rank_5'
    UpgradeIcon(8)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Medusa_Legacy_Rank_5'
    UpgradeIcon(9)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Medusa_Legacy_Rank_5'
    UpgradeIcon(10)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Medusa_Legacy_Rank_5'
	UpgradeIcon(11)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Medusa_Legacy_Rank_5'
    UpgradeIcon(12)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Medusa_Legacy_Rank_5'
    UpgradeIcon(13)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Medusa_Legacy_Rank_5'
    UpgradeIcon(14)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Medusa_Legacy_Rank_5'
    UpgradeIcon(15)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Medusa_Legacy_Rank_5'
    UpgradeIcon(16)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Medusa_Legacy_Rank_5'
    UpgradeIcon(17)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Medusa_Legacy_Rank_5'
    UpgradeIcon(18)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Medusa_Legacy_Rank_5'
    UpgradeIcon(19)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Medusa_Legacy_Rank_5'
    UpgradeIcon(20)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Medusa_Legacy_Rank_5'
	
	// Legacy (hand-made) artwork icons
	LegacyUpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Medusa_Legacy_Rank_0'
	LegacyUpgradeIcon(1)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Medusa_Legacy_Rank_1'
	LegacyUpgradeIcon(2)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Medusa_Legacy_Rank_2'
	LegacyUpgradeIcon(3)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Medusa_Legacy_Rank_3'
	LegacyUpgradeIcon(4)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Medusa_Legacy_Rank_4'
	LegacyUpgradeIcon(5)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Medusa_Legacy_Rank_5'
	LegacyUpgradeIcon(6)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Medusa_Legacy_Rank_5'
	LegacyUpgradeIcon(7)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Medusa_Legacy_Rank_5'
	LegacyUpgradeIcon(8)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Medusa_Legacy_Rank_5'
	LegacyUpgradeIcon(9)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Medusa_Legacy_Rank_5'
	LegacyUpgradeIcon(10)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Medusa_Legacy_Rank_5'
	LegacyUpgradeIcon(11)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Medusa_Legacy_Rank_5'
	LegacyUpgradeIcon(12)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Medusa_Legacy_Rank_5'
	LegacyUpgradeIcon(13)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Medusa_Legacy_Rank_5'
	LegacyUpgradeIcon(14)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Medusa_Legacy_Rank_5'
	LegacyUpgradeIcon(15)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Medusa_Legacy_Rank_5'
	LegacyUpgradeIcon(16)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Medusa_Legacy_Rank_5'
	LegacyUpgradeIcon(17)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Medusa_Legacy_Rank_5'
	LegacyUpgradeIcon(18)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Medusa_Legacy_Rank_5'
	LegacyUpgradeIcon(19)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Medusa_Legacy_Rank_5'
	LegacyUpgradeIcon(20)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Medusa_Legacy_Rank_5'

    Name="Default__DKUpgrade_Perk_Medusa"
}