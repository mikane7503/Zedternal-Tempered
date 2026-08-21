class ZTUpgrade_Perk_Metronome extends ZTUpgrade_Perk config(ZedternalUnlimited);

// ===================================================================
// METRONOME PERK ? Rhythmic Phase Combat System
//
// Four 12-second phases rotate automatically:
//   ASSAULT  (0) ? Damage + Penetration     (sync: headshot kills)
//   TEMPO    (1) ? Reload + Rate of Fire     (sync: rapid kills <3s apart)
//   MOMENTUM (2) ? Move Speed + Weapon Switch (sync: kills while moving)
//   BASTION  (3) ? Close-range Dmg + Vampire (sync: close-range kills <5m)
//
// Sync kills during matching phase build permanent stacking bonuses.
// Level 10 ? Harmony: phase transition overlap (both phases active).
// Level 20 ? Crescendo: full cycle with good sync ? all bonuses burst.
// ===================================================================

// Per-level bonus scaling (applied only during active phase)
var config float AssaultDamage;            // +3% damage per level during Assault
var config float AssaultPenetration;       // +5% penetration per level during Assault
var config float TempoReload;              // +2% reload speed per level during Tempo
var config float TempoRateOfFire;          // +2% rate of fire per level during Tempo
var config float MomentumSpeed;            // +1.5% move speed per level during Momentum
var config float MomentumWeaponSwitch;     // +3% weapon switch per level during Momentum
var config float BastionDamage;            // +4% close-range damage per level during Bastion
var config float BastionResistance;        // universal resistance during Bastion/Crescendo
var config int BastionVampireHP;           // +1 HP per kill during Bastion

// Phase constants
const PHASE_ASSAULT   = 0;
const PHASE_TEMPO     = 1;
const PHASE_MOMENTUM  = 2;
const PHASE_BASTION   = 3;
const NUM_PHASES      = 4;

// Close-range distance threshold (squared, in UU)
var config float CloseRangeDistSq;        // ~500 UU = ~5 meters

// Sync thresholds
var config int SyncKillsForBonus;          // Sync kills needed per phase for permanent bonus
var config float PermanentBonusPerStack;   // +1% per permanent stack
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.AssaultDamage = 0.03f;
		default.AssaultPenetration = 0.05f;
		default.TempoReload = 0.02f;
		default.TempoRateOfFire = 0.02f;
		default.MomentumSpeed = 0.015f;
		default.MomentumWeaponSwitch = 0.03f;
		default.BastionDamage = 0.04f;
		default.BastionResistance = 0.10f;
		default.BastionVampireHP = 1;
		default.CloseRangeDistSq = 250000.0f;
		default.SyncKillsForBonus = 5;
		default.PermanentBonusPerStack = 0.01f;

		// BEGIN TEMPERED INI DEFAULTS (generated; do not edit by hand)
		default.AssaultDamage = 0.015000f;
		default.AssaultPenetration = 0.012500f;
		default.TempoReload = 0.010000f;
		default.TempoRateOfFire = 0.010000f;
		default.MomentumSpeed = 0.007500f;
		default.MomentumWeaponSwitch = 0.015000f;
		default.BastionDamage = 0.010000f;
		default.BastionResistance = 0.100000f;
		default.BastionVampireHP = 1;
		default.CloseRangeDistSq = 250000.000000f;
		default.SyncKillsForBonus = 5;
		default.PermanentBonusPerStack = 0.002500f;
		// END TEMPERED INI DEFAULTS
		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}


// ===================================================================
// DAMAGE GIVEN ? Assault + Bastion bonuses, kill detection for sync
// ===================================================================

static function ModifyDamageGiven(out int InDamage, int DefaultDamage, int upgLevel, optional Actor DamageCauser, optional KFPawn_Monster MyKFPM, optional KFPlayerController DamageInstigator, optional class<KFDamageType> DamageType, optional int HitZoneIdx, optional KFWeapon MyKFW)
{
    local ZTUpgrade_Perk_Metronome_Helper H;
    local float Bonus;
    local bool bIsHeadshot;
    local float DistSq;
    local bool bCloseRange;
    local bool bWillKill;

    if (MyKFPM == None || DamageInstigator == None || DamageInstigator.Pawn == None)
        return;

    H = GetHelper(DamageInstigator.Pawn);
    if (H == None)
        return;

    H.PerkLevel = upgLevel;
    Bonus = 0.0f;
    bIsHeadshot = (HitZoneIdx == HZI_HEAD);
    bCloseRange = false;

    // Distance check for Bastion
    DistSq = VSizeSQ(MyKFPM.Location - DamageInstigator.Pawn.Location);
    if (DistSq <= default.CloseRangeDistSq)
        bCloseRange = true;

    // ASSAULT phase bonus: flat damage
    if (H.IsPhaseActive(PHASE_ASSAULT))
    {
        Bonus += default.AssaultDamage * upgLevel;
        Bonus += H.GetPermanentBonus(PHASE_ASSAULT);
    }

    // BASTION phase bonus: close-range damage only
    if (H.IsPhaseActive(PHASE_BASTION))
    {
        if (bCloseRange)
        {
            Bonus += default.BastionDamage * upgLevel;
        }
        Bonus += H.GetPermanentBonus(PHASE_BASTION);
    }

    // Crescendo: add all phase damage bonuses
    if (H.bCrescendoActive)
    {
        if (!H.IsPhaseActive(PHASE_ASSAULT))
            Bonus += default.AssaultDamage * upgLevel * 0.5f;
        if (!H.IsPhaseActive(PHASE_BASTION))
        {
            if (bCloseRange)
                Bonus += default.BastionDamage * upgLevel * 0.5f;
        }
    }

    if (Bonus > 0.0f)
        InDamage += Round(float(DefaultDamage) * Bonus);

    // Kill detection for sync tracking
    bWillKill = (InDamage >= MyKFPM.Health);
    if (bWillKill)
    {
        H.OnKill(bIsHeadshot, bCloseRange, MyKFPM);
    }
}

// ===================================================================
// PENETRATION ? Assault phase
// ===================================================================

static simulated function ModifyPenetration(out float InPenetration, float DefaultPenetration, int upgLevel, class<KFDamageType> DamageType, KFPawn OwnerPawn, optional bool bForce)
{
    local ZTUpgrade_Perk_Metronome_Helper H;

    if (OwnerPawn == None)
        return;

    H = GetHelper(OwnerPawn);
    if (H == None)
        return;

    if (H.IsPhaseActive(PHASE_ASSAULT) || H.bCrescendoActive)
        InPenetration += DefaultPenetration * default.AssaultPenetration * upgLevel;
}

// ===================================================================
// RELOAD SPEED ? Tempo phase
// ===================================================================

static simulated function GetReloadRateScale(out float InReloadRateScale, int upgLevel, KFWeapon KFW, KFPawn OwnerPawn)
{
    local ZTUpgrade_Perk_Metronome_Helper H;
    local float Bonus;

    if (OwnerPawn == None)
        return;

    H = GetHelper(OwnerPawn);
    if (H == None)
        return;

    Bonus = 0.0f;

    if (H.IsPhaseActive(PHASE_TEMPO) || H.bCrescendoActive)
    {
        Bonus += default.TempoReload * upgLevel;
        Bonus += H.GetPermanentBonus(PHASE_TEMPO);
    }

    if (Bonus > 0.0f)
        InReloadRateScale = 1.0f / (1.0f / InReloadRateScale + Bonus);
}

// ===================================================================
// RATE OF FIRE ? Tempo phase
// ===================================================================

static simulated function ModifyRateOfFire(out float InRate, float DefaultRate, int upgLevel, KFWeapon KFW)
{
    local ZTUpgrade_Perk_Metronome_Helper H;
    local KFPawn OwnerPawn;
    local float Bonus;

    if (KFW == None)
        return;

    OwnerPawn = KFPawn(KFW.Instigator);
    if (OwnerPawn == None)
        OwnerPawn = KFPawn(KFW.Owner);
    if (OwnerPawn == None)
        return;

    H = GetHelper(OwnerPawn);
    if (H == None)
        return;

    Bonus = 0.0f;

    if (H.IsPhaseActive(PHASE_TEMPO) || H.bCrescendoActive)
        Bonus += default.TempoRateOfFire * upgLevel;

    if (Bonus > 0.0f)
        InRate = DefaultRate / (DefaultRate / InRate + Bonus);
}

// ===================================================================
// MOVEMENT SPEED ? Momentum phase
// ===================================================================

static simulated function ModifySpeed(out float InSpeed, float DefaultSpeed, int upgLevel, KFPawn OwnerPawn)
{
    local ZTUpgrade_Perk_Metronome_Helper H;
    local float Bonus;

    if (OwnerPawn == None)
        return;

    H = GetHelper(OwnerPawn);
    if (H == None)
        return;

    Bonus = 0.0f;

    if (H.IsPhaseActive(PHASE_MOMENTUM) || H.bCrescendoActive)
    {
        Bonus += default.MomentumSpeed * upgLevel;
        Bonus += H.GetPermanentBonus(PHASE_MOMENTUM);
    }

    if (Bonus > 0.0f)
        InSpeed += DefaultSpeed * Bonus;
}

// ===================================================================
// WEAPON SWITCH ? Momentum phase
// ===================================================================

static simulated function ModifyWeaponSwitchTime(out float InSwitchTime, float DefaultSwitchTime, int upgLevel, KFWeapon KFW)
{
    local ZTUpgrade_Perk_Metronome_Helper H;
    local KFPawn OwnerPawn;
    local float Bonus;

    if (KFW == None)
        return;

    OwnerPawn = KFPawn(KFW.Instigator);
    if (OwnerPawn == None)
        OwnerPawn = KFPawn(KFW.Owner);
    if (OwnerPawn == None)
        return;

    H = GetHelper(OwnerPawn);
    if (H == None)
        return;

    Bonus = 0.0f;

    if (H.IsPhaseActive(PHASE_MOMENTUM) || H.bCrescendoActive)
        Bonus += default.MomentumWeaponSwitch * upgLevel;

    if (Bonus > 0.0f)
        InSwitchTime = DefaultSwitchTime / (DefaultSwitchTime / InSwitchTime + Bonus);
}

// ===================================================================
// VAMPIRE HEALTH ? Bastion phase
// ===================================================================

static function AddVampireHealth(out int InHealth, int DefaultHealth, int upgLevel, KFPlayerController KFPC, class<DamageType> DT)
{
    local ZTUpgrade_Perk_Metronome_Helper H;

    if (KFPC == None || KFPC.Pawn == None)
        return;

    H = GetHelper(KFPC.Pawn);
    if (H == None)
        return;

    if (H.IsPhaseActive(PHASE_BASTION) || H.bCrescendoActive)
        InHealth += default.BastionVampireHP;
}

// ===================================================================
// DAMAGE TAKEN ? Bastion phase damage resistance
// ===================================================================

static function ModifyDamageTaken(out int InDamage, int DefaultDamage, int upgLevel, KFPawn OwnerPawn, optional class<DamageType> DamageType, optional Controller InstigatedBy, optional KFWeapon MyKFW)
{
    local ZTUpgrade_Perk_Metronome_Helper H;

    if (OwnerPawn == None)
        return;

    H = GetHelper(OwnerPawn);
    if (H == None)
        return;

    // 15% damage reduction during Bastion (flat, not per-level ? it's strong enough)
    if (H.IsPhaseActive(PHASE_BASTION) || H.bCrescendoActive)
        InDamage -= Round(float(DefaultDamage) * default.BastionResistance);

    if (InDamage < 0)
        InDamage = 0;
}

// ===================================================================
// HELPER CLASS MANAGEMENT
// ===================================================================

static simulated function InitiateWeapon(int upgLevel, KFWeapon KFW, KFPawn OwnerPawn)
{
    local ZTUpgrade_Perk_Metronome_Helper H;
    local bool bFound;

    if (KFPawn_Human(OwnerPawn) != None && OwnerPawn.Role == ROLE_Authority)
    {
        bFound = false;
        foreach OwnerPawn.ChildActors(class'ZTUpgrade_Perk_Metronome_Helper', H)
        {
            bFound = true;
            H.PerkLevel = upgLevel;
            break;
        }

        if (!bFound)
        {
            H = OwnerPawn.Spawn(class'ZTUpgrade_Perk_Metronome_Helper', OwnerPawn);
            if (H != None)
            {
                H.PerkLevel = upgLevel;
            }
        }
    }
}

static function ZTUpgrade_Perk_Metronome_Helper GetHelper(Pawn OwnerPawn)
{
    local ZTUpgrade_Perk_Metronome_Helper H;

    if (KFPawn_Human(OwnerPawn) != None)
    {
        foreach OwnerPawn.ChildActors(class'ZTUpgrade_Perk_Metronome_Helper', H)
        {
            return H;
        }

        // Only spawn on server ? client gets None (all state pushed via RPCs)
        if (OwnerPawn.Role == ROLE_Authority)
        {
            H = OwnerPawn.Spawn(class'ZTUpgrade_Perk_Metronome_Helper', OwnerPawn);
        }
    }

    return H;
}

static simulated function DeleteHelperClass(Pawn OwnerPawn)
{
    local ZTUpgrade_Perk_Metronome_Helper H;

    if (OwnerPawn != None)
    {
        foreach OwnerPawn.ChildActors(class'ZTUpgrade_Perk_Metronome_Helper', H)
        {
            H.Destroy();
        }
    }
}

defaultproperties
{
	UpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Metronome_Rank_0'
    // --- Localization (auto-generated by mass_localize_dk_upgrades.py) ---
    // Strings live in KFGame/Localization/<lang>/ZedternalTempered.<langext>
    // Section: [ZTUpgrade_Perk_Metronome]  -- see DKUpgrade_* base class for details.
    bShouldLocalize=True
    LocPackage="ZedternalTempered"
    LocSection="ZTUpgrade_Perk_Metronome"
    LocalizeDescriptionLineCount=8

    // Per-level scaling during active phase

    // Close range: 500 UU squared (~5 meters)

    // Sync system

    UpgradeName="Metronome"
    upgradeDescription(0)="Phases rotate automatically: <font color=\"#ff4444\">ASSAULT</font>, <font color=\"#44ddff\">TEMPO</font>, <font color=\"#44ff44\">MOMENTUM</font>, <font color=\"#ffaa22\">BASTION</font>. Each phase grants its own bonuses while active."
    upgradeDescription(1)="<font color=\"#ff4444\">ASSAULT</font>: <font color=\"#FFFFFF\">+1.5%</font> Damage and <font color=\"#FFFFFF\">+1.25%</font> Penetration per level. Sync: <font color=\"#FFFFFF\">Headshot kills</font>."
    upgradeDescription(2)="<font color=\"#44ddff\">TEMPO</font>: <font color=\"#FFFFFF\">+1%</font> Reload Speed and <font color=\"#FFFFFF\">+1%</font> Rate of Fire per level. Sync: <font color=\"#FFFFFF\">Rapid kills</font> (under 3s apart)."
    upgradeDescription(3)="<font color=\"#44ff44\">MOMENTUM</font>: <font color=\"#FFFFFF\">+0.75%</font> Move Speed and <font color=\"#FFFFFF\">+1.5%</font> Weapon Switch per level. Sync: <font color=\"#FFFFFF\">Kills while moving</font>."
    upgradeDescription(4)="<font color=\"#ffaa22\">BASTION</font>: <font color=\"#FFFFFF\">+1%</font> Close-range Damage per level, <font color=\"#FFFFFF\">+1 HP</font> on kill, <font color=\"#FFFFFF\">10%</font> Damage Resistance. Sync: <font color=\"#FFFFFF\">Close-range kills</font> (under 5m)."
    upgradeDescription(5)="<font color=\"#FFFFFF\">5 sync kills</font> during a matching phase grant a <font color=\"#77d914\">permanent +0.25%</font> stacking bonus to that phase."
    upgradeDescription(6)="<font color=\"#8B0000\">LEVEL 10:</font> <font color=\"#FFD700\">Harmony</font> - Phase transitions overlap, briefly granting <font color=\"#FFFFFF\">both phases' bonuses</font> simultaneously."
    upgradeDescription(7)="<font color=\"#8B0000\">LEVEL 20:</font> <font color=\"#FFD700\">Crescendo</font> - Completing a full cycle with high sync activates <font color=\"#FFFFFF\">all bonuses at once</font>."
    PerkBonus(0)=(baseValue=0, incValue=2, maxValue=-1)
    PerkBonus(1)=(baseValue=0, incValue=1, maxValue=-1)

	// Legacy (hand-made) artwork icons

    Name="Default__ZTUpgrade_Perk_Metronome"
}
