class DKUpgrade_Perk_Reaper extends DKUpgrade_Perk
	config(ZedternalUnlimited);

// Theme: "Reaper" - A death-dealing perk focused on harvesting souls and dealing massive damage
// Special mechanics: Instant kill chance, soul harvesting bonuses, level 10 mega boost

var config float CritChance;          // Critical hit chance increase per level
var config float HeadshotDamage;      // Headshot damage bonus per level
var config float MovementSpeed;       // Movement speed increase per level

// Level 10 special bonus - one static boost
var config float Level10DamageBonus;  // One-time damage bonus at level 10
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.CritChance = 0.02f;
		default.HeadshotDamage = 0.06f;
		default.MovementSpeed = 0.03f;
		default.Level10DamageBonus = 0.5f;

		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}


static function ModifyDamageGiven(out int InDamage, int DefaultDamage, int upgLevel, optional Actor DamageCauser, optional KFPawn_Monster MyKFPM, optional KFPlayerController DamageInstigator, optional class<KFDamageType> DamageType, optional int HitZoneIdx, optional KFWeapon MyKFW)
{
    local float TotalDamageBonus;
    local DKUpgrade_Perk_Reaper_Helper ReaperHelper;
    
    if (MyKFPM == None || DamageInstigator == None) return;
    
    // Instant kill feature only at level 20 (5% chance, no bosses)
    if (upgLevel >= class'DKConfig_Capstone'.default.Capstone_Rank2Level)
    {
        // 5% fixed chance for instant kill
        if (FRand() <= 0.05f)
        {
            // Don't instant kill bosses
            if (!MyKFPM.static.IsABoss())
            {
                // INSTANT KILL - Set damage to monster's max health + 1 to guarantee kill
                InDamage = MyKFPM.HealthMax + 1;
                
                // Show instant kill notification
                if (DamageInstigator.Pawn != None)
                {
                    ReaperHelper = GetHelper(DamageInstigator.Pawn);
                    if (ReaperHelper != None)
                    {
                        ReaperHelper.ShowInstantKillNotification();
                        // Track this as a kill with monster reference
                        ReaperHelper.TrackKill(MyKFPM);
                    }
                }
                return; // Exit early, no need for other damage calculations
            }
        }
    }
    
    // Normal damage bonus ONLY comes from Level 10 milestone
    if (upgLevel >= class'DKConfig_Capstone'.default.Capstone_Rank1Level)
    {
        TotalDamageBonus = default.Level10DamageBonus;
    }
    
    // Apply damage bonus
    InDamage += Round(float(DefaultDamage) * TotalDamageBonus);
    
    // Headshot bonus - Reaper rewards precision
    if (HitZoneIdx == HZI_HEAD)
    {
        InDamage += Round(float(DefaultDamage) * default.HeadshotDamage * upgLevel);
    }
    
    // Check for kill and track it (only if this damage will actually kill the monster)
    if (InDamage >= MyKFPM.Health && DamageInstigator.Pawn != None)
    {
        ReaperHelper = GetHelper(DamageInstigator.Pawn);
        if (ReaperHelper != None)
        {
            ReaperHelper.TrackKill(MyKFPM); // Pass the monster reference
        }
    }
}

static simulated function ModifySpeedPassive(out float speedFactor, int upgLevel)
{
	speedFactor += default.MovementSpeed * upgLevel;
}

// Use extension function for crit chance since no standard function exists
static simulated function bool ExtensionFuncBoolean(int upgLevel, string Identifier, KFWeapon MyKFW, KFPawn OwnerPawn,
    optional int InputInt, optional float InputFloat, optional name InputClassName,
    optional Object InputObject1, optional Object InputObject2, optional Object InputObject3)
{
    local float CritBonus, CritRoll;
    local KFPawn_Monster MyKFPM;
    
    if (Identifier ~= "ReaperCritChance")
    {
        MyKFPM = KFPawn_Monster(InputObject1);
        if (MyKFPM == None) return false;
        
        // Crit chance scales with level
        CritBonus = default.CritChance * upgLevel;
        
        CritRoll = FRand();
        return (CritRoll < CritBonus);
    }
    
    return false;
}

// Helper class management functions (copied from Rank Them Up pattern)
static simulated function InitiateWeapon(int upgLevel, KFWeapon KFW, KFPawn OwnerPawn)
{
    local DKUpgrade_Perk_Reaper_Helper ReaperHelper;
    local bool bFound;

    if (KFPawn_Human(OwnerPawn) != None && OwnerPawn.Role == Role_Authority)
    {
        bFound = False;
        foreach OwnerPawn.ChildActors(class'DKUpgrade_Perk_Reaper_Helper', ReaperHelper)
        {
            bFound = True;
            break;
        }

        if (!bFound)
            ReaperHelper = OwnerPawn.Spawn(class'DKUpgrade_Perk_Reaper_Helper', OwnerPawn);
    }
}

static function DKUpgrade_Perk_Reaper_Helper GetHelper(Pawn OwnerPawn)
{
    local DKUpgrade_Perk_Reaper_Helper ReaperHelper;

    if (KFPawn_Human(OwnerPawn) != None)
    {
        foreach OwnerPawn.ChildActors(class'DKUpgrade_Perk_Reaper_Helper', ReaperHelper)
        {
            return ReaperHelper;
        }

        // Should have one
        ReaperHelper = OwnerPawn.Spawn(class'DKUpgrade_Perk_Reaper_Helper', OwnerPawn);
    }

    return ReaperHelper;
}

static simulated function DeleteHelperClass(Pawn OwnerPawn)
{
    local DKUpgrade_Perk_Reaper_Helper ReaperHelper;

    if (OwnerPawn != None)
    {
        foreach OwnerPawn.ChildActors(class'DKUpgrade_Perk_Reaper_Helper', ReaperHelper)
        {
            ReaperHelper.Destroy();
        }
    }
}

defaultproperties
{
    
    // --- Localization (auto-generated by mass_localize_dk_upgrades.py) ---
    // Strings live in KFGame/Localization/<lang>/ZedternalRBPerkpackage.<langext>
    // Section: [DKUpgrade_Perk_Reaper]  -- see DKUpgrade_* base class for details.
    bShouldLocalize=True
    LocPackage="ZedternalRBPerkpackage"
    LocSection="DKUpgrade_Perk_Reaper"
    LocalizeDescriptionLineCount=6

    // Level 10 "Reaper's Ascension" - One static bonus
    
    UpgradeName="Reaper"

    // PerkBonus for UI display
    PerkBonus(0)=(baseValue=0, incValue=2, maxValue=-1)    // Crit chance %
    PerkBonus(1)=(baseValue=0, incValue=6, maxValue=-1)    // Headshot damage %
    PerkBonus(2)=(baseValue=0, incValue=3, maxValue=-1)    // Movement speed %
    PerkBonus(3)=(baseValue=50, incValue=0, maxValue=50)   // Level 10 damage bonus % (fixed at 50%)
    PerkBonus(4)=(baseValue=5, incValue=0, maxValue=5)     // Instant kill chance % (fixed at 5%)
    
    // Upgrade descriptions with improved Reaper theme and readability
    UpgradeDescription(0)="<font color=\"#CC0000\">Death's Precision:</font> <font color=\"#FFFFFF\">+%x%%</font> <font color=\"#FF6666\">Critical Hit Chance</font>"
    UpgradeDescription(1)="<font color=\"#CC0000\">Soul Strike:</font> <font color=\"#FFFFFF\">+%x%%</font> <font color=\"#FF6666\">Headshot Damage</font>"
    UpgradeDescription(2)="<font color=\"#CC0000\">Shadow Step:</font> <font color=\"#FFFFFF\">+%x%%</font> <font color=\"#FF6666\">Movement Speed</font>"
    UpgradeDescription(3)="<font color=\"#8B0000\">LEVEL 10:</font> <font color=\"#FFD700\">Reaper's Ascension</font> - <font color=\"#FFFFFF\">+50%</font> <font color=\"#FF6666\">Damage Bonus</font>"
    UpgradeDescription(4)="<font color=\"#8B0000\">LEVEL 20:</font> <font color=\"#FFD700\">Death's Touch</font> - <font color=\"#FFFFFF\">5%</font> chance to <font color=\"#FF6666\">instantly kill</font> non-boss enemies"
    UpgradeDescription(5)="<font color=\"#FFD700\">Soul Harvesting</font>: Earn <font color=\"#FFFFFF\">100 Dosh</font> every <font color=\"#FFFFFF\">100 kills</font>"
    
    // Placeholder icons - you'll need to create actual textures
    UpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Reaper_Legacy_Rank_0'
    UpgradeIcon(1)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Reaper_Legacy_Rank_1'
    UpgradeIcon(2)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Reaper_Legacy_Rank_2'
    UpgradeIcon(3)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Reaper_Legacy_Rank_3'
    UpgradeIcon(4)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Reaper_Legacy_Rank_4'
    UpgradeIcon(5)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Reaper_Legacy_Rank_5'
    UpgradeIcon(6)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Reaper_Legacy_Rank_5'
    UpgradeIcon(7)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Reaper_Legacy_Rank_5'
    UpgradeIcon(8)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Reaper_Legacy_Rank_5'
    UpgradeIcon(9)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Reaper_Legacy_Rank_5'
    UpgradeIcon(10)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Reaper_Legacy_Rank_5'
	UpgradeIcon(11)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Reaper_Legacy_Rank_5'
    UpgradeIcon(12)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Reaper_Legacy_Rank_5'
    UpgradeIcon(13)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Reaper_Legacy_Rank_5'
    UpgradeIcon(14)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Reaper_Legacy_Rank_5'
    UpgradeIcon(15)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Reaper_Legacy_Rank_5'
    UpgradeIcon(16)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Reaper_Legacy_Rank_5'
    UpgradeIcon(17)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Reaper_Legacy_Rank_5'
    UpgradeIcon(18)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Reaper_Legacy_Rank_5'
    UpgradeIcon(19)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Reaper_Legacy_Rank_5'
    UpgradeIcon(20)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Reaper_Legacy_Rank_5'
	
	// Legacy (hand-made) artwork icons
	LegacyUpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Reaper_Legacy_Rank_0'
	LegacyUpgradeIcon(1)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Reaper_Legacy_Rank_1'
	LegacyUpgradeIcon(2)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Reaper_Legacy_Rank_2'
	LegacyUpgradeIcon(3)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Reaper_Legacy_Rank_3'
	LegacyUpgradeIcon(4)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Reaper_Legacy_Rank_4'
	LegacyUpgradeIcon(5)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Reaper_Legacy_Rank_5'
	LegacyUpgradeIcon(6)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Reaper_Legacy_Rank_5'
	LegacyUpgradeIcon(7)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Reaper_Legacy_Rank_5'
	LegacyUpgradeIcon(8)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Reaper_Legacy_Rank_5'
	LegacyUpgradeIcon(9)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Reaper_Legacy_Rank_5'
	LegacyUpgradeIcon(10)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Reaper_Legacy_Rank_5'
	LegacyUpgradeIcon(11)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Reaper_Legacy_Rank_5'
	LegacyUpgradeIcon(12)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Reaper_Legacy_Rank_5'
	LegacyUpgradeIcon(13)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Reaper_Legacy_Rank_5'
	LegacyUpgradeIcon(14)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Reaper_Legacy_Rank_5'
	LegacyUpgradeIcon(15)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Reaper_Legacy_Rank_5'
	LegacyUpgradeIcon(16)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Reaper_Legacy_Rank_5'
	LegacyUpgradeIcon(17)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Reaper_Legacy_Rank_5'
	LegacyUpgradeIcon(18)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Reaper_Legacy_Rank_5'
	LegacyUpgradeIcon(19)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Reaper_Legacy_Rank_5'
	LegacyUpgradeIcon(20)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Reaper_Legacy_Rank_5'

    Name="Default__DKUpgrade_Perk_Reaper"
}