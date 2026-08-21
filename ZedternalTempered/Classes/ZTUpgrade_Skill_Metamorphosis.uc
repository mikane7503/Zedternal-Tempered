class ZTUpgrade_Skill_Metamorphosis extends ZTUpgrade_Skill config(ZedternalUnlimited);

var config array<int> PoisonKillsRequired;
var config array<float> StatBonus;
var config array<float> TransformDuration;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.PoisonKillsRequired[0] = 50;
		default.PoisonKillsRequired[1] = 50;
		default.StatBonus[0] = 0.1f;
		default.StatBonus[1] = 0.2f;
		default.TransformDuration[0] = 5.0f;
		default.TransformDuration[1] = 10.0f;

		// BEGIN TEMPERED INI DEFAULTS (generated; do not edit by hand)
		default.PoisonKillsRequired.Length = 2;
		default.PoisonKillsRequired[0] = 50;
		default.PoisonKillsRequired[1] = 50;
		default.StatBonus.Length = 2;
		default.StatBonus[0] = 0.100000f;
		default.StatBonus[1] = 0.200000f;
		default.TransformDuration.Length = 2;
		default.TransformDuration[0] = 5.000000f;
		default.TransformDuration[1] = 10.000000f;
		// END TEMPERED INI DEFAULTS
		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}


static function ModifyDamageGiven(out int InDamage, int DefaultDamage, int upgLevel, optional Actor DamageCauser, optional KFPawn_Monster MyKFPM, optional KFPlayerController DamageInstigator, optional class<KFDamageType> DamageType, optional int HitZoneIdx, optional KFWeapon MyKFW)
{
    local ZTUpgrade_Skill_Metamorphosis_Helper MetaHelper;
    
    if (DamageInstigator == None || DamageInstigator.Pawn == None) return;
    
    // Check if transformation is active
    MetaHelper = GetHelper(DamageInstigator.Pawn);
    if (MetaHelper != None && MetaHelper.bTransformationActive)
    {
        // Apply damage bonus during transformation
        InDamage += Round(float(DefaultDamage) * default.StatBonus[upgLevel - 1]);
    }
    
    // Track poison kills for transformation progress
    if (InDamage >= MyKFPM.Health && MyKFPM.bIsPoisoned && MetaHelper != None)
    {
        MetaHelper.TrackPoisonKill(upgLevel);
    }
}

static function ModifyDamageTaken(out int InDamage, int DefaultDamage, int upgLevel, KFPawn OwnerPawn, optional class<DamageType> DamageType, optional Controller InstigatedBy, optional KFWeapon MyKFW)
{
    local ZTUpgrade_Skill_Metamorphosis_Helper MetaHelper;
    
    if (OwnerPawn == None) return;
    
    // Check if transformation is active
    MetaHelper = GetHelper(OwnerPawn);
    if (MetaHelper != None && MetaHelper.bTransformationActive)
    {
        // Immune to damage during transformation
        InDamage = 0;
    }
}

static simulated function ModifySpeed(out float InSpeed, float DefaultSpeed, int upgLevel, KFPawn OwnerPawn)
{
    local ZTUpgrade_Skill_Metamorphosis_Helper MetaHelper;
    
    if (OwnerPawn == None) return;
    
    // Check if transformation is active
    MetaHelper = GetHelper(OwnerPawn);
    if (MetaHelper != None && MetaHelper.bTransformationActive)
    {
        // Apply speed bonus during transformation
        InSpeed += DefaultSpeed * default.StatBonus[upgLevel - 1];
    }
}

static simulated function GetReloadRateScale(out float InReloadRateScale, int upgLevel, KFWeapon KFW, KFPawn OwnerPawn)
{
    local ZTUpgrade_Skill_Metamorphosis_Helper MetaHelper;
    
    if (OwnerPawn == None) return;
    
    // Check if transformation is active
    MetaHelper = GetHelper(OwnerPawn);
    if (MetaHelper != None && MetaHelper.bTransformationActive)
    {
        // Apply reload speed bonus during transformation
        InReloadRateScale = 1.0f / (1.0f / InReloadRateScale + default.StatBonus[upgLevel - 1]);
    }
}

static function WaveEnd(int upgLevel, KFPlayerController KFPC)
{
    local ZTUpgrade_Skill_Metamorphosis_Helper MetaHelper;
    
    if (KFPC == None || KFPC.Pawn == None) return;
    
    // Reset poison kill counter at wave end
    MetaHelper = GetHelper(KFPC.Pawn);
    if (MetaHelper != None)
    {
        MetaHelper.ResetWaveProgress();
    }
}

static simulated function InitiateWeapon(int upgLevel, KFWeapon KFW, KFPawn OwnerPawn)
{
    local ZTUpgrade_Skill_Metamorphosis_Helper MetaHelper;
    local bool bFound;

    if (KFPawn_Human(OwnerPawn) != None && OwnerPawn.Role == Role_Authority)
    {
        bFound = False;
        foreach OwnerPawn.ChildActors(class'ZTUpgrade_Skill_Metamorphosis_Helper', MetaHelper)
        {
            bFound = True;
            break;
        }

        if (!bFound)
        {
            MetaHelper = OwnerPawn.Spawn(class'ZTUpgrade_Skill_Metamorphosis_Helper', OwnerPawn);
            MetaHelper.UpgradeLevel = upgLevel;
        }
    }
}

static function ZTUpgrade_Skill_Metamorphosis_Helper GetHelper(Pawn OwnerPawn)
{
    local ZTUpgrade_Skill_Metamorphosis_Helper MetaHelper;

    if (KFPawn_Human(OwnerPawn) != None)
    {
        foreach OwnerPawn.ChildActors(class'ZTUpgrade_Skill_Metamorphosis_Helper', MetaHelper)
        {
            return MetaHelper;
        }

        // Create one if needed
        MetaHelper = OwnerPawn.Spawn(class'ZTUpgrade_Skill_Metamorphosis_Helper', OwnerPawn);
    }

    return MetaHelper;
}

static simulated function DeleteHelperClass(Pawn OwnerPawn)
{
    local ZTUpgrade_Skill_Metamorphosis_Helper MetaHelper;

    if (OwnerPawn != None)
    {
        foreach OwnerPawn.ChildActors(class'ZTUpgrade_Skill_Metamorphosis_Helper', MetaHelper)
        {
            MetaHelper.Destroy();
        }
    }
}

defaultproperties
{
    
    // --- Localization (auto-generated by mass_localize_dk_upgrades.py) ---
    // Strings live in KFGame/Localization/<lang>/ZedternalTempered.<langext>
    // Section: [ZTUpgrade_Skill_Metamorphosis]  -- see DKUpgrade_* base class for details.
    bShouldLocalize=True
    LocPackage="ZedternalTempered"
    LocSection="ZTUpgrade_Skill_Metamorphosis"

    UpgradeName="Metamorphosis"
    UpgradeDescription(0)="<font color=\"#8B008B\">Metamorphosis:</font> After <font color=\"#FFFFFF\">50 poison kills</font> in one wave, transform for <font color=\"#FFFFFF\">5 seconds</font> (<font color=\"#66FF66\">+10% all stats</font>, <font color=\"#FFD700\">immune to damage</font>)."
    UpgradeDescription(1)="<font color=\"#8B008B\">Metamorphosis (Deluxe):</font> After <font color=\"#FFFFFF\">50 poison kills</font> in one wave, transform for <font color=\"#FFFFFF\">10 seconds</font> (<font color=\"#66FF66\">+20% all stats</font>, <font color=\"#FFD700\">immune to damage</font>)."
    
    UpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_Metamorphosis'
    UpgradeIcon(1)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_Metamorphosis_Deluxe'
    
    Name="Default__ZTUpgrade_Skill_Metamorphosis"
}