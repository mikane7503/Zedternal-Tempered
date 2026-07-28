class DKUpgrade_Perk_ForgeWarden extends DKUpgrade_Perk
	config(ZedternalUnlimited);

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

		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}


static function ModifyDamageGiven(out int InDamage, int DefaultDamage, int upgLevel, optional Actor DamageCauser, optional KFPawn_Monster MyKFPM, optional KFPlayerController DamageInstigator, optional class<KFDamageType> DamageType, optional int HitZoneIdx, optional KFWeapon MyKFW)
{
    local float TotalDamageBonus;
    local DKUpgrade_Perk_ForgeWarden_Helper ForgeHelper;
    local bool bIsFireOrExplosive;
    
    if (MyKFPM == None || DamageInstigator == None || DamageType == None) return;
    
    // Check if this is fire or explosive damage
    bIsFireOrExplosive = IsFireOrExplosiveDamage(DamageType);
    
    if (bIsFireOrExplosive)
    {
        // Apply fire/explosive damage bonus
        TotalDamageBonus = default.FireExplosiveDamage * upgLevel;
        
        // Level 10: Additional damage bonus
        if (upgLevel >= class'DKConfig_Capstone'.default.Capstone_Rank1Level)
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
                if (upgLevel >= class'DKConfig_Capstone'.default.Capstone_Rank2Level && FRand() <= default.MoltenCoreChance)
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
    if (ClassIsChildOf(DamageType, class'DKDT_ForgeWarden_BurningGround'))
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
    local DKUpgrade_Perk_ForgeWarden_Helper ForgeHelper;
    local bool bFound;

    if (KFPawn_Human(OwnerPawn) != None && OwnerPawn.Role == Role_Authority)
    {
        bFound = False;
        foreach OwnerPawn.ChildActors(class'DKUpgrade_Perk_ForgeWarden_Helper', ForgeHelper)
        {
            bFound = True;
            break;
        }

        if (!bFound)
            ForgeHelper = OwnerPawn.Spawn(class'DKUpgrade_Perk_ForgeWarden_Helper', OwnerPawn);
    }
}

static function DKUpgrade_Perk_ForgeWarden_Helper GetHelper(Pawn OwnerPawn)
{
    local DKUpgrade_Perk_ForgeWarden_Helper ForgeHelper;

    if (KFPawn_Human(OwnerPawn) != None)
    {
        foreach OwnerPawn.ChildActors(class'DKUpgrade_Perk_ForgeWarden_Helper', ForgeHelper)
        {
            return ForgeHelper;
        }

        // Should have one
        ForgeHelper = OwnerPawn.Spawn(class'DKUpgrade_Perk_ForgeWarden_Helper', OwnerPawn);
    }

    return ForgeHelper;
}

static simulated function DeleteHelperClass(Pawn OwnerPawn)
{
    local DKUpgrade_Perk_ForgeWarden_Helper ForgeHelper;

    if (OwnerPawn != None)
    {
        foreach OwnerPawn.ChildActors(class'DKUpgrade_Perk_ForgeWarden_Helper', ForgeHelper)
        {
            ForgeHelper.Destroy();
        }
    }
}

defaultproperties
{
    
    // --- Localization (auto-generated by mass_localize_dk_upgrades.py) ---
    // Strings live in KFGame/Localization/<lang>/ZedternalRBPerkpackage.<langext>
    // Section: [DKUpgrade_Perk_ForgeWarden]  -- see DKUpgrade_* base class for details.
    bShouldLocalize=True
    LocPackage="ZedternalRBPerkpackage"
    LocSection="DKUpgrade_Perk_ForgeWarden"
    LocalizeDescriptionLineCount=5

    UpgradeName="ForgeWarden"

    // PerkBonus for UI display
    PerkBonus(0)=(baseValue=0, incValue=4, maxValue=-1)    // Fire/Explosive damage %
    PerkBonus(1)=(baseValue=0, incValue=5, maxValue=-1)    // Burn duration %
    PerkBonus(2)=(baseValue=25, incValue=0, maxValue=25)   // Level 10 damage bonus % (fixed)
    PerkBonus(3)=(baseValue=8, incValue=0, maxValue=8)     // Level 20 molten core chance % (fixed)
    
    // Upgrade descriptions
    UpgradeDescription(0)="<font color=\"#FF4500\">Molten Mastery:</font> <font color=\"#FFFFFF\">+%x%%</font> <font color=\"#FF8C00\">Fire & Explosive Damage</font>"
    UpgradeDescription(1)="<font color=\"#FF4500\">Lingering Flames:</font> <font color=\"#FFFFFF\">+%x%%</font> <font color=\"#FF8C00\">Fire DoT Duration</font>"
    UpgradeDescription(2)="<font color=\"#8B0000\">LEVEL 10:</font> <font color=\"#FFD700\">Forge Mastery</font> - <font color=\"#FFFFFF\">+25%</font> additional <font color=\"#FF8C00\">Fire & Explosive Damage</font>"
    UpgradeDescription(3)="<font color=\"#8B0000\">LEVEL 20:</font> <font color=\"#FFD700\">Molten Core</font> - <font color=\"#FFFFFF\">8%</font> chance on Fire/Explosive kill to create <font color=\"#FF8C00\">burning ground</font>"
    UpgradeDescription(4)="Earn <font color=\"#FFFFFF\">+1 Grenade</font> every <font color=\"#FFFFFF\">25</font> Fire or Explosive kills"
    
    // Icons
    UpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_ForgeWarden_Legacy_Rank_0'
    UpgradeIcon(1)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_ForgeWarden_Legacy_Rank_1'
    UpgradeIcon(2)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_ForgeWarden_Legacy_Rank_2'
    UpgradeIcon(3)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_ForgeWarden_Legacy_Rank_3'
    UpgradeIcon(4)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_ForgeWarden_Legacy_Rank_4'
    UpgradeIcon(5)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_ForgeWarden_Legacy_Rank_5'
    UpgradeIcon(6)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_ForgeWarden_Legacy_Rank_5'
    UpgradeIcon(7)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_ForgeWarden_Legacy_Rank_5'
    UpgradeIcon(8)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_ForgeWarden_Legacy_Rank_5'
    UpgradeIcon(9)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_ForgeWarden_Legacy_Rank_5'
    UpgradeIcon(10)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_ForgeWarden_Legacy_Rank_5'
    UpgradeIcon(11)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_ForgeWarden_Legacy_Rank_5'
    UpgradeIcon(12)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_ForgeWarden_Legacy_Rank_5'
    UpgradeIcon(13)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_ForgeWarden_Legacy_Rank_5'
    UpgradeIcon(14)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_ForgeWarden_Legacy_Rank_5'
    UpgradeIcon(15)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_ForgeWarden_Legacy_Rank_5'
    UpgradeIcon(16)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_ForgeWarden_Legacy_Rank_5'
    UpgradeIcon(17)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_ForgeWarden_Legacy_Rank_5'
    UpgradeIcon(18)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_ForgeWarden_Legacy_Rank_5'
    UpgradeIcon(19)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_ForgeWarden_Legacy_Rank_5'
    UpgradeIcon(20)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_ForgeWarden_Legacy_Rank_5'
    
	// Legacy (hand-made) artwork icons
	LegacyUpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_ForgeWarden_Legacy_Rank_0'
	LegacyUpgradeIcon(1)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_ForgeWarden_Legacy_Rank_1'
	LegacyUpgradeIcon(2)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_ForgeWarden_Legacy_Rank_2'
	LegacyUpgradeIcon(3)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_ForgeWarden_Legacy_Rank_3'
	LegacyUpgradeIcon(4)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_ForgeWarden_Legacy_Rank_4'
	LegacyUpgradeIcon(5)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_ForgeWarden_Legacy_Rank_5'
	LegacyUpgradeIcon(6)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_ForgeWarden_Legacy_Rank_5'
	LegacyUpgradeIcon(7)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_ForgeWarden_Legacy_Rank_5'
	LegacyUpgradeIcon(8)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_ForgeWarden_Legacy_Rank_5'
	LegacyUpgradeIcon(9)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_ForgeWarden_Legacy_Rank_5'
	LegacyUpgradeIcon(10)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_ForgeWarden_Legacy_Rank_5'
	LegacyUpgradeIcon(11)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_ForgeWarden_Legacy_Rank_5'
	LegacyUpgradeIcon(12)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_ForgeWarden_Legacy_Rank_5'
	LegacyUpgradeIcon(13)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_ForgeWarden_Legacy_Rank_5'
	LegacyUpgradeIcon(14)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_ForgeWarden_Legacy_Rank_5'
	LegacyUpgradeIcon(15)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_ForgeWarden_Legacy_Rank_5'
	LegacyUpgradeIcon(16)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_ForgeWarden_Legacy_Rank_5'
	LegacyUpgradeIcon(17)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_ForgeWarden_Legacy_Rank_5'
	LegacyUpgradeIcon(18)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_ForgeWarden_Legacy_Rank_5'
	LegacyUpgradeIcon(19)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_ForgeWarden_Legacy_Rank_5'
	LegacyUpgradeIcon(20)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_ForgeWarden_Legacy_Rank_5'

    Name="Default__DKUpgrade_Perk_ForgeWarden"
}
