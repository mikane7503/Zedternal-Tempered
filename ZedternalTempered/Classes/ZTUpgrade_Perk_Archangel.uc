class ZTUpgrade_Perk_Archangel extends ZTUpgrade_Perk config(ZedternalUnlimited);

// Theme: "Archangel" - A support perk focused on healing allies and providing tactical benefits
// Special mechanics: Healing aura, miracle recovery, ally proximity bonuses

var config float FieldMedicine;           // Healing amount bonus per level
var config float CombatReadiness;         // Reload speed bonus for allies per level
var config float HealingTouch;            // Healing effectiveness with syringes/medic weapons per level

// Level bonuses - one-time static boosts
var config float Level10AuraHealing;      // Health regeneration per second for allies at level 10
var config float Level20MiracleChance;    // Chance for miracle recovery at level 20
var config float AllyProximityRange;      // Range to detect allies for bonuses
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.FieldMedicine = 0.10f;
		default.CombatReadiness = 0.03f;
		default.HealingTouch = 0.08f;
		default.Level10AuraHealing = 1.0f;
		default.Level20MiracleChance = 0.15f;
		default.AllyProximityRange = 600.0f;

		// BEGIN TEMPERED INI DEFAULTS (generated; do not edit by hand)
		default.FieldMedicine = 0.015000f;
		default.CombatReadiness = 0.007500f;
		default.HealingTouch = 0.010000f;
		default.Level10AuraHealing = 1.000000f;
		default.Level20MiracleChance = 0.050000f;
		default.AllyProximityRange = 600.000000f;
		// END TEMPERED INI DEFAULTS
		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}


static function ModifyHealAmount(out float InHealAmount, float DefaultHealAmount, int upgLevel)
{
    // Field Medicine: +10% healing from all sources per level.
    // Use += so we compose with other heal-modifying skills (Analytics,
    // BattleSurgeon, etc.) instead of overwriting their contributions.
    InHealAmount += DefaultHealAmount * (default.FieldMedicine * upgLevel);
}

static simulated function GetReloadRateScale(out float InReloadRateScale, int upgLevel, KFWeapon KFW, KFPawn OwnerPawn)
{
    local ZTUpgrade_Perk_Archangel_Helper ArchangelHelper;
    local float Bonus;
    
    if (KFW == None || OwnerPawn == None) return;
    
    ArchangelHelper = GetHelper(OwnerPawn);
    if (ArchangelHelper != None)
    {
        // Update the helper with current perk level
        ArchangelHelper.SetPerkLevel(upgLevel);
        
        // Combat Readiness: Faster reload when near allies.
        // Reload Rate Scale uses INV-ADD; lower = faster reload.
        // Old code did `InReloadRateScale += bonus`, which made reload SLOWER
        // (opposite of what the description promises) and stomped composition.
        if (ArchangelHelper.GetNearbyAlliesCount() > 0)
        {
            Bonus = default.CombatReadiness * upgLevel;
            InReloadRateScale = 1.0f / (1.0f / InReloadRateScale + Bonus);
        }
    }
}

static function HealingDamage(int upgLevel, int HealAmount, KFPawn HealedPawn, KFPawn InstigatorPawn, class<DamageType> DamageType)
{
    local ZTUpgrade_Perk_Archangel_Helper ArchangelHelper;
    local KFPawn_Human HealedAlly, HealerPawn;
    local float MiracleRoll;
    local float ActualHealingDone;
    local float HealthBefore;
    
    // Only process positive healing amounts (not damage)
    if (HealAmount <= 0) return;
    
    // Only track healing done by the player who has this perk
    HealerPawn = KFPawn_Human(InstigatorPawn);
    if (HealerPawn == None) return;
    
    ArchangelHelper = GetHelper(HealerPawn);
    if (ArchangelHelper == None) return;
    
    // Update the helper with current perk level
    ArchangelHelper.SetPerkLevel(upgLevel);
    
    HealedAlly = KFPawn_Human(HealedPawn);
    if (HealedAlly == None) return;
    
    // Calculate actual healing done (not theoretical)
    HealthBefore = HealedAlly.Health;
    ActualHealingDone = FMin(float(HealAmount), HealedAlly.HealthMax - HealthBefore);
    
    // Only track if actual healing was done (target wasn't already at full health)
    if (ActualHealingDone > 0)
    {
        // Track the actual healing done
        ArchangelHelper.TrackHealing(int(ActualHealingDone), HealedAlly);
        
        // Check for Miracle Recovery at level 20 (only for healing others)
        if (upgLevel >= class'ZTConfig_Capstone'.default.Capstone_Rank2Level && HealedAlly != HealerPawn)
        {
            MiracleRoll = FRand();
            if (MiracleRoll <= default.Level20MiracleChance)
            {
                ArchangelHelper.TriggerMiracleRecovery(HealedAlly);
            }
        }
    }
}

// Extension function for healing bonuses with syringes/medic weapons
static simulated function ExtensionFuncFloat(out float InValue, float DefaultValue, int upgLevel, string Identifier,
    KFWeapon MyKFW, KFPawn OwnerPawn, optional int InputInt, optional float InputFloat, optional name InputClassName,
    optional Object InputObject1, optional Object InputObject2, optional Object InputObject3)
{
    local KFWeap_MedicBase MedicWeapon;
    local ZTUpgrade_Perk_Archangel_Helper ArchangelHelper;
    local float HealingBonus, MiracleRoll;
    local KFPawn_Human TargetPawn;
    
    if (Identifier ~= "ArchangelHealingTouch")
    {
        // Update helper with perk level
        ArchangelHelper = GetHelper(OwnerPawn);
        if (ArchangelHelper != None)
        {
            ArchangelHelper.SetPerkLevel(upgLevel);
        }
        
        // Healing Touch: Enhanced effectiveness with medic weapons/syringes
        MedicWeapon = KFWeap_MedicBase(MyKFW);
        if (MedicWeapon != None)
        {
            HealingBonus = default.HealingTouch * upgLevel;
            InValue = DefaultValue + HealingBonus;
        }
    }
    else if (Identifier ~= "ArchangelMiracleChance" && upgLevel >= class'ZTConfig_Capstone'.default.Capstone_Rank2Level)
    {
        // Update helper with perk level
        ArchangelHelper = GetHelper(OwnerPawn);
        if (ArchangelHelper != None)
        {
            ArchangelHelper.SetPerkLevel(upgLevel);
        }
        
        // Miracle Recovery: 15% chance for full heal at level 20
        TargetPawn = KFPawn_Human(InputObject1);
        if (TargetPawn != None)
        {
            MiracleRoll = FRand();
            if (MiracleRoll <= default.Level20MiracleChance)
            {
                if (ArchangelHelper != None)
                {
                    ArchangelHelper.TriggerMiracleRecovery(TargetPawn);
                }
                InValue = 1.0f; // Signal miracle recovery occurred
            }
            else
            {
                InValue = DefaultValue;
            }
        }
    }
}

// Extension function for aura healing at level 10+
static simulated function bool ExtensionFuncBoolean(int upgLevel, string Identifier, KFWeapon MyKFW, KFPawn OwnerPawn,
    optional int InputInt, optional float InputFloat, optional name InputClassName,
    optional Object InputObject1, optional Object InputObject2, optional Object InputObject3)
{
    local ZTUpgrade_Perk_Archangel_Helper ArchangelHelper;
    
    if (Identifier ~= "ArchangelHealingAura" && upgLevel >= class'ZTConfig_Capstone'.default.Capstone_Rank1Level)
    {
        ArchangelHelper = GetHelper(OwnerPawn);
        if (ArchangelHelper != None)
        {
            ArchangelHelper.SetPerkLevel(upgLevel);
            ArchangelHelper.UpdateHealingAura(upgLevel);
            return true;
        }
    }
    
    return false;
}

// Helper class management functions (pattern from Reaper)
static simulated function InitiateWeapon(int upgLevel, KFWeapon KFW, KFPawn OwnerPawn)
{
    local ZTUpgrade_Perk_Archangel_Helper ArchangelHelper;
    local bool bFound;

    if (KFPawn_Human(OwnerPawn) != None && OwnerPawn.Role == Role_Authority)
    {
        bFound = False;
        foreach OwnerPawn.ChildActors(class'ZTUpgrade_Perk_Archangel_Helper', ArchangelHelper)
        {
            bFound = True;
            // Update the helper with current perk level when weapon is initiated
            ArchangelHelper.SetPerkLevel(upgLevel);
            break;
        }

        if (!bFound)
        {
            ArchangelHelper = OwnerPawn.Spawn(class'ZTUpgrade_Perk_Archangel_Helper', OwnerPawn);
            if (ArchangelHelper != None)
            {
                ArchangelHelper.SetPerkLevel(upgLevel);
            }
        }
    }
}

static function ZTUpgrade_Perk_Archangel_Helper GetHelper(Pawn OwnerPawn)
{
    local ZTUpgrade_Perk_Archangel_Helper ArchangelHelper;

    if (KFPawn_Human(OwnerPawn) != None)
    {
        foreach OwnerPawn.ChildActors(class'ZTUpgrade_Perk_Archangel_Helper', ArchangelHelper)
        {
            return ArchangelHelper;
        }

        // Should have one
        ArchangelHelper = OwnerPawn.Spawn(class'ZTUpgrade_Perk_Archangel_Helper', OwnerPawn);
    }

    return ArchangelHelper;
}

static simulated function DeleteHelperClass(Pawn OwnerPawn)
{
    local ZTUpgrade_Perk_Archangel_Helper ArchangelHelper;

    if (OwnerPawn != None)
    {
        foreach OwnerPawn.ChildActors(class'ZTUpgrade_Perk_Archangel_Helper', ArchangelHelper)
        {
            ArchangelHelper.Destroy();
        }
    }
}

defaultproperties
{
    
	UpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Archangel_Rank_0'
    // --- Localization (auto-generated by mass_localize_dk_upgrades.py) ---
    // Strings live in KFGame/Localization/<lang>/ZedternalTempered.<langext>
    // Section: [ZTUpgrade_Perk_Archangel]  -- see DKUpgrade_* base class for details.
    bShouldLocalize=True
    LocPackage="ZedternalTempered"
    LocSection="ZTUpgrade_Perk_Archangel"
    LocalizeDescriptionLineCount=5

    // Special level bonuses
    
    UpgradeName="Archangel"

    // PerkBonus for UI display
    PerkBonus(0)=(baseValue=0, incValue=2, maxValue=-1)   // Field Medicine healing %
    PerkBonus(1)=(baseValue=0, incValue=1, maxValue=-1)    // Combat Readiness reload speed %
    PerkBonus(2)=(baseValue=0, incValue=1, maxValue=-1)    // Healing Touch effectiveness %
    PerkBonus(3)=(baseValue=1, incValue=0, maxValue=1)     // Level 10 aura healing HP/sec
    PerkBonus(4)=(baseValue=5, incValue=0, maxValue=5)   // Level 20 miracle chance % (fixed at 15%)
    
    // Upgrade descriptions with Archangel theme
    UpgradeDescription(0)="<font color=\"#FFD700\">Field Medicine:</font> <font color=\"#FFFFFF\">+%x%%</font> <font color=\"#00FF7F\">Healing Amount</font> from all sources"
    UpgradeDescription(1)="<font color=\"#FFD700\">Combat Readiness:</font> <font color=\"#FFFFFF\">+%x%%</font> <font color=\"#00FF7F\">Reload Speed</font> when near allies (6m)"
    UpgradeDescription(2)="<font color=\"#FFD700\">Healing Touch:</font> <font color=\"#FFFFFF\">+%x%%</font> <font color=\"#00FF7F\">Healing Effectiveness</font> with syringes and medic weapons"
    UpgradeDescription(3)="<font color=\"#8B0000\">LEVEL 10:</font> <font color=\"#FFD700\">Healing Aura</font> - Allies within <font color=\"#FFFFFF\">6m</font> regenerate <font color=\"#FFFFFF\">1 HP/sec</font>"
    UpgradeDescription(4)="<font color=\"#8B0000\">LEVEL 20:</font> <font color=\"#FFD700\">Miracle Recovery</font> - <font color=\"#FFFFFF\">5%</font> chance for healing actions to <font color=\"#00FF7F\">restore full health</font> to target"
    
    // Placeholder icons - you'll need to create actual textures
    
	// Legacy (hand-made) artwork icons

    Name="Default__ZTUpgrade_Perk_Archangel"
}
