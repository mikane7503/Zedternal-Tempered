// ===================================================================
// ZTUpgrade_Perk_JekyllHyde - "The Duality"
//
// Dr. Jekyll (default): a controlled, gun-using human with small
// per-rank refinements (move / reload).
//
// Mr. Hyde (the serum, dedicated key - default H, ActivateHyde):
//   - Transform into a 2x-size monster (IntendedBodyScale, mesh-only
//     scale -> no sinking; collision stays human-sized).
//   - Immune to ALL damage.
//   - +300% melee damage. Guns deal 95% less while transformed (this
//     self-clears the instant bHyde flips false - it is a per-hit gate,
//     not a stored modifier).
//   - Melee hits on a zed unleash a damage shockwave in a wide radius.
//   - 20s base. Capstone 1 (lvl 10): duration x2. Capstone 2 (lvl 20):
//     3 charges per wave. Charges reset every wave.
//
// All heavy lifting (transform, timers, charges, shockwave, sound, HUD)
// lives in ZTUpgrade_Perk_JekyllHyde_Helper. This class is the upgrade
// hook surface + helper management.
// ===================================================================
class ZTUpgrade_Perk_JekyllHyde extends ZTUpgrade_Perk config(ZedternalUnlimited);

// --- Hyde tunables (seeded by UpdateConfig, read by the helper/hooks) ---
var config float HydeDuration;              // base seconds in Hyde form
var config float HydeDurationCapstoneMult;  // multiplier at capstone 1
var config float HydeBodyScale;             // visual scale while Hyde
var config float HydeScaleRate;             // BodyScaleChangePerSecond (grow-in speed)
var config float HydeMeleeBonus;            // +melee fraction (3.0 = +300%)
var config float HydeGunDamageMult;         // gun damage multiplier while Hyde (0.05 = -95%)
var config float HydeAoERadius;             // shockwave radius (uu)
var config float HydeAoEMinDamageFrac;      // damage fraction at the edge of the shockwave
var config bool  bHydeFullImmune;           // true = take 0 damage while Hyde
var config int   HydeChargesBase;           // serum charges per wave (pre-capstone-2)
var config int   HydeChargesCapstone2;      // serum charges per wave at capstone 2
var config float HydeFinalDamageTakenMult;  // Hyde: final incoming-damage multiplier (0.9 = take 10% less)

// --- Jekyll passive (per-rank, always on; small "refined human" bonuses) ---
var config float Jekyll_MovePerRank;        // +move speed fraction per rank
var config float Jekyll_ReloadPerRank;      // +reload rate fraction per rank

var config int MODEVERSION;

// ===================================================================
// CONFIG SEED
// ===================================================================
static function UpdateConfig()
{
    if (default.MODEVERSION < 1)
    {
        default.HydeDuration = 10.0f;
        default.HydeDurationCapstoneMult = 2.0f;
        default.HydeBodyScale = 2.0f;
        default.HydeScaleRate = 2.5f;        // ~0.4s grow-in across 1.0 scale units
        default.HydeMeleeBonus = 1.5f;       // +150%
        default.HydeGunDamageMult = 0.05f;   // -95%
        default.HydeAoERadius = 800.0f;      // ~10m (tune to taste)
        default.HydeAoEMinDamageFrac = 0.5f; // edge of the blast does 50%
        default.bHydeFullImmune = False;     // deprecated: Hyde is no longer immune
        default.HydeFinalDamageTakenMult = 0.9f; // take 10% less final damage while Hyde
        default.HydeChargesBase = 1;
        default.HydeChargesCapstone2 = 2;

        default.Jekyll_MovePerRank = 0.01f;    // +1%/rank  (+20% at 20)
        default.Jekyll_ReloadPerRank = 0.01f;  // +1%/rank

        default.MODEVERSION = 1;
        static.StaticSaveConfig();
    }

    // v2: Jekyll passive bumped 0.4%/rank -> 1%/rank so the upgrade menu can
    // render a clean integer %x% per level (PerkBonus is integer-only).
    // Migrates configs already seeded at v1.
    if (default.MODEVERSION < 2)
    {
        default.Jekyll_MovePerRank = 0.01f;
        default.Jekyll_ReloadPerRank = 0.01f;

        default.MODEVERSION = 2;
        static.StaticSaveConfig();
    }

    // v3: Hyde nerf pass -- melee 300%->150%, base duration 20s->10s,
    // capstone-2 charges 3->2, and full immunity replaced by a flat 10%
    // final damage reduction. Seeds the new HydeFinalDamageTakenMult for
    // configs created before it existed (critical: an unseeded 0.0 would
    // otherwise read as full immunity in ZTPerk, so we force it here).
    if (default.MODEVERSION < 3)
    {
        default.HydeMeleeBonus = 1.5f;
        default.HydeDuration = 10.0f;
        default.HydeChargesCapstone2 = 2;
        default.bHydeFullImmune = False;
        default.HydeFinalDamageTakenMult = 0.9f;

        default.MODEVERSION = 3;
        static.StaticSaveConfig();
    }
}

// ===================================================================
// HELPER MANAGEMENT
// ===================================================================

// Spawns if missing (server-side). Safe to call from server hooks.
static function ZTUpgrade_Perk_JekyllHyde_Helper GetHelper(Pawn OwnerPawn)
{
    local ZTUpgrade_Perk_JekyllHyde_Helper H;

    if (KFPawn_Human(OwnerPawn) != None)
    {
        foreach OwnerPawn.ChildActors(class'ZTUpgrade_Perk_JekyllHyde_Helper', H)
            return H;

        H = OwnerPawn.Spawn(class'ZTUpgrade_Perk_JekyllHyde_Helper', OwnerPawn);
    }

    return H;
}

// Never spawns - safe for client-side simulated hooks.
static simulated function ZTUpgrade_Perk_JekyllHyde_Helper FindHelper(Pawn OwnerPawn)
{
    local ZTUpgrade_Perk_JekyllHyde_Helper H;

    if (KFPawn_Human(OwnerPawn) != None)
    {
        foreach OwnerPawn.ChildActors(class'ZTUpgrade_Perk_JekyllHyde_Helper', H)
            return H;
    }

    return None;
}

static simulated function InitiateWeapon(int upgLevel, KFWeapon KFW, KFPawn OwnerPawn)
{
    local ZTUpgrade_Perk_JekyllHyde_Helper H;

    if (KFPawn_Human(OwnerPawn) != None && OwnerPawn.Role == ROLE_Authority)
    {
        H = GetHelper(OwnerPawn);
        if (H != None)
            H.SetPerkLevel(upgLevel);
    }
}

static simulated function DeleteHelperClass(Pawn OwnerPawn)
{
    local ZTUpgrade_Perk_JekyllHyde_Helper H;

    if (OwnerPawn != None)
    {
        foreach OwnerPawn.ChildActors(class'ZTUpgrade_Perk_JekyllHyde_Helper', H)
        {
            H.ForceRevert();
            H.Destroy();
        }
    }
}

static function WaveEnd(int upgLevel, KFPlayerController KFPC)
{
    local ZTUpgrade_Perk_JekyllHyde_Helper H;

    if (KFPC != None && KFPC.Pawn != None)
    {
        H = GetHelper(KFPC.Pawn);
        if (H != None)
        {
            H.SetPerkLevel(upgLevel);
            H.OnWaveEnd();
        }
    }
}

// ===================================================================
// DAMAGE TAKEN
// ===================================================================
// Hyde's defensive layer no longer lives here. Full immunity was removed;
// the flat "10% less final damage while Hyde" cut is applied as the very
// last step of ZTPerk.ModifyDamageTaken so it lands after every other
// resistance multiplier (vanilla/skill resists, roguelike, helpers). See
// ZTPerk.uc.

// ===================================================================
// DAMAGE GIVEN - Hyde melee buff + shockwave, gun penalty
// ===================================================================
static function ModifyDamageGiven(out int InDamage, int DefaultDamage, int upgLevel,
    optional Actor DamageCauser, optional KFPawn_Monster MyKFPM,
    optional KFPlayerController DamageInstigator, optional class<KFDamageType> DamageType,
    optional int HitZoneIdx, optional KFWeapon MyKFW)
{
    local ZTUpgrade_Perk_JekyllHyde_Helper H;

    if (DamageInstigator == None || DamageInstigator.Pawn == None)
        return;

    H = FindHelper(DamageInstigator.Pawn);
    if (H == None || !H.bHyde)
        return;

    // Re-entrancy guard: the shockwave's own TakeDamage calls re-enter this
    // hook with the same instigator. While the shockwave is being applied we
    // let the (already-computed) damage pass through untouched.
    if (H.bShockwaveActive)
        return;

    if (IsMeleeDamageType(DamageType))
    {
        // +300% melee
        InDamage += Round(float(DefaultDamage) * default.HydeMeleeBonus);

        // 10m shockwave when a zed is struck
        if (MyKFPM != None)
            H.MeleeShockwave(MyKFPM, InDamage, DamageType, DamageInstigator);
    }
    else
    {
        // Guns deal 95% less while Hyde. Per-hit gate -> self-clears when
        // bHyde flips false at serum expiry (nothing to "turn off").
        InDamage = Round(float(InDamage) * default.HydeGunDamageMult);
    }
}

// ===================================================================
// JEKYLL PASSIVES (per-rank, always on - small refinement bonuses)
// ===================================================================
static simulated function ModifySpeedPassive(out float speedFactor, int upgLevel)
{
    speedFactor += default.Jekyll_MovePerRank * float(upgLevel);
}

static simulated function GetReloadRateScalePassive(out float reloadRateFactor, int upgLevel)
{
    reloadRateFactor += default.Jekyll_ReloadPerRank * float(upgLevel);
}

defaultproperties
{
	UpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Shapeshifter_Rank_0'
    bShouldLocalize=True
    LocPackage="ZedternalTempered"
    LocSection="ZTUpgrade_Perk_JekyllHyde"
    LocalizeDescriptionLineCount=5

    UpgradeName="Dr. Jekyll & Mr. Hyde"
    upgradeDescription(0)="Increase <font color=\"#15d7fa\">Movement Speed</font> by <font color=\"#77d914\">%x%%</font>."
    upgradeDescription(1)="Increase <font color=\"#15d7fa\">Reload Speed</font> by <font color=\"#77d914\">%x%%</font>."
    upgradeDescription(2)="Press your <font color=\"#15d7fa\">Hyde Serum</font> key (default <font color=\"#ffc832\">H</font>) to become <font color=\"#be4d25\">MR. HYDE</font> for <font color=\"#77d914\">10s</font>: <font color=\"#77d914\">2x</font> size, <font color=\"#be4d25\">take 10% less damage</font>, <font color=\"#ff3399\">+150% melee</font> with a shockwave. Guns deal <font color=\"#be4d25\">95% less</font> while transformed."
    upgradeDescription(3)="<font color=\"#8B0000\">LEVEL 10:</font> Hyde duration <font color=\"#77d914\">doubled</font> (<font color=\"#77d914\">20s</font>)."
    upgradeDescription(4)="<font color=\"#8B0000\">LEVEL 20:</font> Serum gains <font color=\"#77d914\">2 charges</font> per wave (up from 1)."

    // Drives the dynamic %x% in lines 0/1 (current total = incValue * level).
    // Lines 2-4 have no %x% and intentionally have no PerkBonus entry.
    PerkBonus(0)=(baseValue=0, incValue=1, maxValue=-1)
    PerkBonus(1)=(baseValue=0, incValue=1, maxValue=-1)

    Name="Default__ZTUpgrade_Perk_JekyllHyde"
}
