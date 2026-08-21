class ZTUpgrade_Perk_ForgeWarden extends ZTUpgrade_Perk config(ZedternalUnlimited);

// Theme: "ForgeWarden" - Fire/Explosive damage specialist
var config float FireExplosiveDamage;     // Fire/Explosive damage bonus per level
var config float BurnDurationBonus;       // Fire DOT duration extension per level
var config float Level10DamageBonus;      // Level 10 additional damage bonus
var config float MoltenCoreChance;        // Level 20 burning ground chance
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.FireExplosiveDamage = 0.04f;
		default.BurnDurationBonus = 0.05f;
		default.Level10DamageBonus = 0.25f;
		default.MoltenCoreChance = 0.08f;

		// BEGIN TEMPERED INI DEFAULTS (generated; do not edit by hand)
		default.FireExplosiveDamage = 0.020000f;
		default.BurnDurationBonus = 0.025000f;
		default.Level10DamageBonus = 0.125000f;
		default.MoltenCoreChance = 0.080000f;
		// END TEMPERED INI DEFAULTS
		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}


static function ModifyDamageGiven(out int InDamage, int DefaultDamage, int upgLevel, optional Actor DamageCauser, optional KFPawn_Monster MyKFPM, optional KFPlayerController DamageInstigator, optional class<KFDamageType> DamageType, optional int HitZoneIdx, optional KFWeapon MyKFW)
{
    local float TotalDamageBonus;
    local ZTUpgrade_Perk_ForgeWarden_Helper ForgeHelper;
    local bool bIsFireOrExplosive;
    
    if (MyKFPM == None || DamageInstigator == None || DamageType == None) return;
    
    // Check if this is fire or explosive damage
    bIsFireOrExplosive = IsFireOrExplosiveDamage(DamageType);
    
    if (bIsFireOrExplosive)
    {
        // Apply fire/explosive damage bonus
        TotalDamageBonus = default.FireExplosiveDamage * upgLevel;
        
        // Level 10: Additional damage bonus
        if (upgLevel >= class'ZTConfig_Capstone'.default.Capstone_Rank1Level)
        {
            TotalDamageBonus += default.Level10DamageBonus;
        }
        
        InDamage += Round(float(DefaultDamage) * TotalDamageBonus);
        
        // Check for kill and track it for milestone system
        if (InDamage >= MyKFPM.Health && DamageInstigator.Pawn != None)
        {
            ForgeHelper = GetHelper(DamageInstigator.Pawn);
            if (ForgeHelper != None)
            {
                ForgeHelper.TrackFireExplosiveKill(MyKFPM);
                
                // Level 20: Molten Core - chance for burning ground
                if (upgLevel >= class'ZTConfig_Capstone'.default.Capstone_Rank2Level && FRand() <= default.MoltenCoreChance)
                {
                    ForgeHelper.CreateBurningGround(MyKFPM.Location);
                }
            }
        }
    }
}

// Prevent self-damage from ForgeWarden burning ground
static function ModifyDamageTaken(out int InDamage, int DefaultDamage, int upgLevel, KFPawn OwnerPawn, optional class<DamageType> DamageType, optional Controller InstigatedBy, optional KFWeapon MyKFW)
{
    if (ClassIsChildOf(DamageType, class'ZTDT_ForgeWarden_BurningGround'))
        InDamage = 0;
}

// Extension function for burn duration enhancement
static simulated function ExtensionFuncFloat(out float InValue, float DefaultValue, int upgLevel, string Identifier,
    KFWeapon MyKFW, KFPawn OwnerPawn, optional int InputInt, optional float InputFloat, optional name InputClassName,
    optional Object InputObject1, optional Object InputObject2, optional Object InputObject3)
{
    if (Identifier ~= "ForgeWardenBurnDuration")
    {
        // Extend burn duration by percentage
        InValue = InputFloat * (1.0f + (default.BurnDurationBonus * upgLevel));
    }
}

// Check if damage type is fire or explosive
static function bool IsFireOrExplosiveDamage(class<KFDamageType> DamageType)
{
    local string DamageTypeName;
    
    if (DamageType == None) return false;
    
    DamageTypeName = string(DamageType.Name);
    
    // Check for fire or explosive damage types
    return (InStr(Caps(DamageTypeName), "FIRE") != -1 || 
            InStr(Caps(DamageTypeName), "BURN") != -1 ||
            InStr(Caps(DamageTypeName), "FLAME") != -1 ||
            InStr(Caps(DamageTypeName), "INCEN") != -1 ||
            InStr(Caps(DamageTypeName), "EXPLOS") != -1 ||
            InStr(Caps(DamageTypeName), "GRENADE") != -1 ||
            InStr(Caps(DamageTypeName), "FRAG") != -1);
}

// Helper class management functions
static simulated function InitiateWeapon(int upgLevel, KFWeapon KFW, KFPawn OwnerPawn)
{
    local ZTUpgrade_Perk_ForgeWarden_Helper ForgeHelper;
    local bool bFound;

    if (KFPawn_Human(OwnerPawn) != None && OwnerPawn.Role == Role_Authority)
    {
        bFound = False;
        foreach OwnerPawn.ChildActors(class'ZTUpgrade_Perk_ForgeWarden_Helper', ForgeHelper)
        {
            bFound = True;
            break;
        }

        if (!bFound)
            ForgeHelper = OwnerPawn.Spawn(class'ZTUpgrade_Perk_ForgeWarden_Helper', OwnerPawn);
    }
}

static function ZTUpgrade_Perk_ForgeWarden_Helper GetHelper(Pawn OwnerPawn)
{
    local ZTUpgrade_Perk_ForgeWarden_Helper ForgeHelper;

    if (KFPawn_Human(OwnerPawn) != None)
    {
        foreach OwnerPawn.ChildActors(class'ZTUpgrade_Perk_ForgeWarden_Helper', ForgeHelper)
        {
            return ForgeHelper;
        }

        // Should have one
        ForgeHelper = OwnerPawn.Spawn(class'ZTUpgrade_Perk_ForgeWarden_Helper', OwnerPawn);
    }

    return ForgeHelper;
}

static simulated function DeleteHelperClass(Pawn OwnerPawn)
{
    local ZTUpgrade_Perk_ForgeWarden_Helper ForgeHelper;

    if (OwnerPawn != None)
    {
        foreach OwnerPawn.ChildActors(class'ZTUpgrade_Perk_ForgeWarden_Helper', ForgeHelper)
        {
            ForgeHelper.Destroy();
        }
    }
}

defaultproperties
{
    
	UpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_ForgeWarden_Rank_0'
    // --- Localization (auto-generated by mass_localize_dk_upgrades.py) ---
    // Strings live in KFGame/Localization/<lang>/ZedternalTempered.<langext>
    // Section: [ZTUpgrade_Perk_ForgeWarden]  -- see DKUpgrade_* base class for details.
    bShouldLocalize=True
    LocPackage="ZedternalTempered"
    LocSection="ZTUpgrade_Perk_ForgeWarden"
    LocalizeDescriptionLineCount=5

    UpgradeName="ForgeWarden"

    // PerkBonus for UI display
    PerkBonus(0)=(baseValue=0, incValue=2, maxValue=-1)    // Fire/Explosive damage %
    PerkBonus(1)=(baseValue=0, incValue=3, maxValue=-1)    // Burn duration %
    PerkBonus(2)=(baseValue=13, incValue=0, maxValue=13)   // Level 10 damage bonus % (fixed)
    PerkBonus(3)=(baseValue=8, incValue=0, maxValue=8)     // Level 20 molten core chance % (fixed)
    
    // Upgrade descriptions
    UpgradeDescription(0)="<font color=\"#FF4500\">Molten Mastery:</font> <font color=\"#FFFFFF\">+%x%%</font> <font color=\"#FF8C00\">Fire & Explosive Damage</font>"
    UpgradeDescription(1)="<font color=\"#FF4500\">Lingering Flames:</font> <font color=\"#FFFFFF\">+%x%%</font> <font color=\"#FF8C00\">Fire DoT Duration</font>"
    UpgradeDescription(2)="<font color=\"#8B0000\">LEVEL 10:</font> <font color=\"#FFD700\">Forge Mastery</font> - <font color=\"#FFFFFF\">+12.5%</font> additional <font color=\"#FF8C00\">Fire & Explosive Damage</font>"
    UpgradeDescription(3)="<font color=\"#8B0000\">LEVEL 20:</font> <font color=\"#FFD700\">Molten Core</font> - <font color=\"#FFFFFF\">8%</font> chance on Fire/Explosive kill to create <font color=\"#FF8C00\">burning ground</font>"
    UpgradeDescription(4)="Earn <font color=\"#FFFFFF\">+1 Grenade</font> every <font color=\"#FFFFFF\">25</font> Fire or Explosive kills"
    
    // Icons
    
	// Legacy (hand-made) artwork icons

    Name="Default__ZTUpgrade_Perk_ForgeWarden"
}
