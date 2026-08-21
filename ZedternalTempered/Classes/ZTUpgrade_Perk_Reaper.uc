class ZTUpgrade_Perk_Reaper extends ZTUpgrade_Perk config(ZedternalUnlimited);

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

		// BEGIN TEMPERED INI DEFAULTS (generated; do not edit by hand)
		default.CritChance = 0.010000f;
		default.HeadshotDamage = 0.020000f;
		default.MovementSpeed = 0.020000f;
		default.Level10DamageBonus = 0.125000f;
		// END TEMPERED INI DEFAULTS
		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}


static function ModifyDamageGiven(out int InDamage, int DefaultDamage, int upgLevel, optional Actor DamageCauser, optional KFPawn_Monster MyKFPM, optional KFPlayerController DamageInstigator, optional class<KFDamageType> DamageType, optional int HitZoneIdx, optional KFWeapon MyKFW)
{
    local float TotalDamageBonus, TotalCritChance;
    local ZTUpgrade_Perk_Reaper_Helper ReaperHelper;
    
    if (MyKFPM == None || DamageInstigator == None) return;
    
    // Instant kill feature only at level 20 (5% chance, no bosses)
    if (upgLevel >= class'ZTConfig_Capstone'.default.Capstone_Rank2Level)
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
    if (upgLevel >= class'ZTConfig_Capstone'.default.Capstone_Rank1Level)
    {
        TotalDamageBonus = default.Level10DamageBonus;
    }
    
    // Apply damage bonus
    InDamage += Round(float(DefaultDamage) * TotalDamageBonus);

    // Death's Precision: a critical hit adds one full base-damage packet.
    // The old extension identifier had no caller, so the displayed chance
    // never affected combat.
    TotalCritChance = FMin(default.CritChance * upgLevel, 1.0f);
    if (FRand() < TotalCritChance)
    {
        InDamage += DefaultDamage;
    }
    
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

// Helper class management functions (copied from Rank Them Up pattern)
static simulated function InitiateWeapon(int upgLevel, KFWeapon KFW, KFPawn OwnerPawn)
{
    local ZTUpgrade_Perk_Reaper_Helper ReaperHelper;
    local bool bFound;

    if (KFPawn_Human(OwnerPawn) != None && OwnerPawn.Role == Role_Authority)
    {
        bFound = False;
        foreach OwnerPawn.ChildActors(class'ZTUpgrade_Perk_Reaper_Helper', ReaperHelper)
        {
            bFound = True;
            break;
        }

        if (!bFound)
            ReaperHelper = OwnerPawn.Spawn(class'ZTUpgrade_Perk_Reaper_Helper', OwnerPawn);
    }
}

static function ZTUpgrade_Perk_Reaper_Helper GetHelper(Pawn OwnerPawn)
{
    local ZTUpgrade_Perk_Reaper_Helper ReaperHelper;

    if (KFPawn_Human(OwnerPawn) != None)
    {
        foreach OwnerPawn.ChildActors(class'ZTUpgrade_Perk_Reaper_Helper', ReaperHelper)
        {
            return ReaperHelper;
        }

        // Should have one
        ReaperHelper = OwnerPawn.Spawn(class'ZTUpgrade_Perk_Reaper_Helper', OwnerPawn);
    }

    return ReaperHelper;
}

static simulated function DeleteHelperClass(Pawn OwnerPawn)
{
    local ZTUpgrade_Perk_Reaper_Helper ReaperHelper;

    if (OwnerPawn != None)
    {
        foreach OwnerPawn.ChildActors(class'ZTUpgrade_Perk_Reaper_Helper', ReaperHelper)
        {
            ReaperHelper.Destroy();
        }
    }
}

defaultproperties
{
    
	UpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Reaper_Rank_0'
    // --- Localization (auto-generated by mass_localize_dk_upgrades.py) ---
    // Strings live in KFGame/Localization/<lang>/ZedternalTempered.<langext>
    // Section: [ZTUpgrade_Perk_Reaper]  -- see DKUpgrade_* base class for details.
    bShouldLocalize=True
    LocPackage="ZedternalTempered"
    LocSection="ZTUpgrade_Perk_Reaper"
    LocalizeDescriptionLineCount=6

    // Level 10 "Reaper's Ascension" - One static bonus
    
    UpgradeName="Reaper"

    // PerkBonus for UI display
    PerkBonus(0)=(baseValue=0, incValue=1, maxValue=-1)    // Crit chance %
    PerkBonus(1)=(baseValue=0, incValue=2, maxValue=-1)    // Headshot damage %
    PerkBonus(2)=(baseValue=0, incValue=2, maxValue=-1)    // Movement speed %
    PerkBonus(3)=(baseValue=13, incValue=0, maxValue=13)   // Level 10 damage bonus % (fixed at 50%)
    PerkBonus(4)=(baseValue=5, incValue=0, maxValue=5)     // Instant kill chance % (fixed at 5%)
    
    // Upgrade descriptions with improved Reaper theme and readability
    UpgradeDescription(0)="<font color=\"#CC0000\">Death's Precision:</font> <font color=\"#FFFFFF\">+%x%%</font> chance to deal <font color=\"#FF6666\">+100% base damage</font>"
    UpgradeDescription(1)="<font color=\"#CC0000\">Soul Strike:</font> <font color=\"#FFFFFF\">+%x%%</font> <font color=\"#FF6666\">Headshot Damage</font>"
    UpgradeDescription(2)="<font color=\"#CC0000\">Shadow Step:</font> <font color=\"#FFFFFF\">+%x%%</font> <font color=\"#FF6666\">Movement Speed</font>"
    UpgradeDescription(3)="<font color=\"#8B0000\">LEVEL 10:</font> <font color=\"#FFD700\">Reaper's Ascension</font> - <font color=\"#FFFFFF\">+12.5%</font> <font color=\"#FF6666\">Damage Bonus</font>"
    UpgradeDescription(4)="<font color=\"#8B0000\">LEVEL 20:</font> <font color=\"#FFD700\">Death's Touch</font> - <font color=\"#FFFFFF\">5%</font> chance to <font color=\"#FF6666\">instantly kill</font> non-boss enemies"
    UpgradeDescription(5)="<font color=\"#FFD700\">Soul Harvesting</font>: Earn <font color=\"#FFFFFF\">100 Dosh</font> every <font color=\"#FFFFFF\">100 kills</font>"
    
    // Placeholder icons - you'll need to create actual textures
	
	// Legacy (hand-made) artwork icons

    Name="Default__ZTUpgrade_Perk_Reaper"
}
