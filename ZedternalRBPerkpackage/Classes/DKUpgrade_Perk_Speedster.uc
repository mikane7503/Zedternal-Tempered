// ===================================================================
// DKUpgrade_Perk_Speedster - "Blink Strike"
//
// A melee mobility duelist built around one active ability on a dedicated
// key (default U, ActivateSpeedster -> the helper's TryActivate):
//
//   Blink Strike: store your position, tag the nearest live zeds in range
//   (5, +2 at capstone 1), then flicker through them ~0.08s apart. Each blink
//   lands adjacent, deals a devastating strike (% of the target's max health,
//   so it scales into endless and reliably deletes trash; large zeds/bosses
//   take a reduced chunk) plus a knockdown, then you blink BACK to your start
//   with a short invulnerable tail. You are invulnerable for the whole dash.
//
// Passives (always on, per rank): movement speed, and faster heavy melee
// swings -- the "speedster" feel.
//
// Capstone 1 (lvl 10): +2 blink targets and a shorter cooldown.
// Capstone 2 (lvl 20): each strike cleaves a shockwave into nearby zeds, and
//                      the large/boss chunk doubles.
//
// All the heavy lifting (targeting, the blink-flurry timeline, cooldown, HUD,
// invuln window) lives in DKUpgrade_Perk_Speedster_Helper. This class is the
// upgrade hook surface + helper management + tunables.
// ===================================================================
class DKUpgrade_Perk_Speedster extends DKUpgrade_Perk
    config(ZedternalUnlimited);

// --- Passives (per rank) ---
var config float MoveSpeedPerRank;     // +move fraction per rank
var config float MeleeSpeedPerRank;    // +heavy-melee attack-speed per rank (INV-ADD)

// --- Blink Strike active ---
var config int   MaxTargetsBase;       // tags per cast (pre-capstone-1)
var config int   MaxTargetsCapstone10; // tags per cast at capstone 1
var config float TagRange;             // uu: how far a zed can be tagged
var config float BlinkInterval;        // s between consecutive blinks (the flurry cadence)
var config float BlinkStandoff;        // uu: how far short of the zed you land
var config float InvulnTail;           // s of invuln after the final blink-back
var config float Cooldown;             // s base cooldown
var config float CooldownCapstone10Mult; // cooldown multiplier at capstone 1 (<1 = shorter)

// Strike damage as a fraction of the target's MAX health. Trash takes the full
// fraction (>1 guarantees a kill); large zeds/bosses take LargeMult of it.
var config float BlinkStrikePctHP;
var config float BlinkStrikeLargeMult;
var config float BlinkStrikeLargeMultCapstone20;

// Capstone 2 cleave.
var config float CleaveRadius;
var config float CleaveFrac;           // fraction of the strike dealt to other nearby zeds

var config int MODEVERSION;

// ===================================================================
// CONFIG SEED
// ===================================================================
static function UpdateConfig()
{
    if (default.MODEVERSION < 1)
    {
        default.MoveSpeedPerRank  = 0.01f;   // +1%/rank  -> +20% @20
        default.MeleeSpeedPerRank = 0.02f;   // +2%/rank  -> +40% @20

        default.MaxTargetsBase       = 5;
        default.MaxTargetsCapstone10 = 7;
        default.TagRange             = 2000.0f;
        default.BlinkInterval        = 0.08f;
        default.BlinkStandoff        = 90.0f;
        default.InvulnTail           = 0.5f;
        default.Cooldown             = 28.0f;
        default.CooldownCapstone10Mult = 0.8f; // -20%

        default.BlinkStrikePctHP   = 1.5f;   // 150% max HP -> guaranteed trash kill
        default.BlinkStrikeLargeMult = 0.15f; // large/boss take ~22.5% max HP/strike
        default.BlinkStrikeLargeMultCapstone20 = 0.30f; // doubled at capstone 2

        default.CleaveRadius = 350.0f;
        default.CleaveFrac   = 0.5f;

        default.MODEVERSION = 1;
        static.StaticSaveConfig();
    }
}

// ===================================================================
// HELPER MANAGEMENT
// ===================================================================

// Spawns if missing (server-side). Safe to call from server hooks.
static function DKUpgrade_Perk_Speedster_Helper GetHelper(Pawn OwnerPawn)
{
    local DKUpgrade_Perk_Speedster_Helper H;
    local DKPlayerController DKPC;

    if (KFPawn_Human(OwnerPawn) != None && OwnerPawn.Role == ROLE_Authority)
    {
        foreach OwnerPawn.ChildActors(class'DKUpgrade_Perk_Speedster_Helper', H)
            return H;

        DKPC = DKPlayerController(OwnerPawn.Controller);
        if (DKPC == None)
            return None;

        H = OwnerPawn.Spawn(class'DKUpgrade_Perk_Speedster_Helper', OwnerPawn);
        if (H != None)
            H.Initialize(KFPawn_Human(OwnerPawn), DKPC);
    }

    return H;
}

// Never spawns - safe for client-side simulated hooks.
static simulated function DKUpgrade_Perk_Speedster_Helper FindHelper(Pawn OwnerPawn)
{
    local DKUpgrade_Perk_Speedster_Helper H;

    if (OwnerPawn != None)
    {
        foreach OwnerPawn.ChildActors(class'DKUpgrade_Perk_Speedster_Helper', H)
            return H;
    }

    return None;
}

static simulated function InitiateWeapon(int upgLevel, KFWeapon KFW, KFPawn OwnerPawn)
{
    local DKUpgrade_Perk_Speedster_Helper H;

    if (KFPawn_Human(OwnerPawn) != None && OwnerPawn.Role == ROLE_Authority)
    {
        H = GetHelper(OwnerPawn);
        if (H != None)
            H.SetPerkLevel(upgLevel);
    }
}

static simulated function DeleteHelperClass(Pawn OwnerPawn)
{
    local DKUpgrade_Perk_Speedster_Helper H;

    if (OwnerPawn != None)
    {
        foreach OwnerPawn.ChildActors(class'DKUpgrade_Perk_Speedster_Helper', H)
        {
            H.Cleanup();
            H.Destroy();
        }
    }
}

static function WaveEnd(int upgLevel, KFPlayerController KFPC)
{
    local DKUpgrade_Perk_Speedster_Helper H;

    if (KFPC != None && KFPC.Pawn != None)
    {
        H = GetHelper(KFPC.Pawn);
        if (H != None)
        {
            H.SetPerkLevel(upgLevel);
            H.OnWaveEnd();   // clear cooldown for a fresh wave
        }
    }
}

// ===================================================================
// PASSIVES (per rank, always on)
// ===================================================================

// Movement speed.
static simulated function ModifySpeedPassive(out float speedFactor, int upgLevel)
{
    speedFactor += default.MoveSpeedPerRank * float(upgLevel);
}

// Faster heavy melee swings. INV-ADD in speed space (same shape as
// SerpentineReflexes' switch-time): converts the incoming duration to a speed
// multiple, adds our bonus, converts back -- so it stacks harmonically with
// other attack-speed modifiers instead of exploding.
static simulated function ModifyMeleeAttackSpeed(out float InDuration, float DefaultDuration, int upgLevel, KFWeapon KFW)
{
    if (DefaultDuration <= 0.0f || InDuration <= 0.0f)
        return;

    InDuration = DefaultDuration / (DefaultDuration / InDuration + default.MeleeSpeedPerRank * float(upgLevel));
}

// ===================================================================
// DAMAGE TAKEN - invulnerable for the duration of a blink dash
// ===================================================================
static function ModifyDamageTaken(out int InDamage, int DefaultDamage, int upgLevel,
    KFPawn OwnerPawn, optional class<DamageType> DamageType, optional Controller InstigatedBy, optional KFWeapon MyKFW)
{
    local DKUpgrade_Perk_Speedster_Helper H;

    H = FindHelper(OwnerPawn);
    if (H != None && H.bBlinking)
        InDamage = 0;
}

defaultproperties
{
    bShouldLocalize=True
    LocPackage="ZedternalRBPerkpackage"
    LocSection="DKUpgrade_Perk_Speedster"
    LocalizeDescriptionLineCount=5

    UpgradeName="Speedfreak"
    upgradeDescription(0)="Increase <font color=\"#15d7fa\">Movement Speed</font> by <font color=\"#77d914\">%x%%</font>."
    upgradeDescription(1)="Heavy melee attacks swing <font color=\"#77d914\">%x%%</font> <font color=\"#15d7fa\">faster</font>."
    upgradeDescription(2)="Press your <font color=\"#15d7fa\">Blink Strike</font> key (default <font color=\"#ffc832\">U</font>) to flicker through the <font color=\"#77d914\">5</font> nearest ZEDs, dealing a <font color=\"#ff3399\">devastating strike</font> to each and returning to your start. <font color=\"#be4d25\">Invulnerable</font> during the dash."
    upgradeDescription(3)="<font color=\"#8B0000\">LEVEL 10:</font> Blink Strike hits <font color=\"#77d914\">2 more</font> ZEDs and its <font color=\"#77d914\">cooldown is reduced</font>."
    upgradeDescription(4)="<font color=\"#8B0000\">LEVEL 20:</font> Each strike <font color=\"#ff3399\">cleaves</font> a shockwave into nearby ZEDs, and hits giants/bosses <font color=\"#77d914\">twice as hard</font>."

    // Drives the dynamic %x% in lines 0/1 (current total = incValue * level).
    PerkBonus(0)=(baseValue=0, incValue=1, maxValue=-1)
    PerkBonus(1)=(baseValue=0, incValue=2, maxValue=-1)

    // Speedfreak rank icons. 6 distinct ranks (0-5); Rank_5 repeats for 6-20.
    // Duke supplies UI_Perk_Speedfreak_Rank_0..5 in the Resources UPK.
    UpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Speedfreak_Rank_0'
    UpgradeIcon(1)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Speedfreak_Rank_1'
    UpgradeIcon(2)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Speedfreak_Rank_2'
    UpgradeIcon(3)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Speedfreak_Rank_3'
    UpgradeIcon(4)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Speedfreak_Rank_4'
    UpgradeIcon(5)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Speedfreak_Rank_5'
    UpgradeIcon(6)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Speedfreak_Rank_5'
    UpgradeIcon(7)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Speedfreak_Rank_5'
    UpgradeIcon(8)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Speedfreak_Rank_5'
    UpgradeIcon(9)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Speedfreak_Rank_5'
    UpgradeIcon(10)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Speedfreak_Rank_5'
    UpgradeIcon(11)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Speedfreak_Rank_5'
    UpgradeIcon(12)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Speedfreak_Rank_5'
    UpgradeIcon(13)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Speedfreak_Rank_5'
    UpgradeIcon(14)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Speedfreak_Rank_5'
    UpgradeIcon(15)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Speedfreak_Rank_5'
    UpgradeIcon(16)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Speedfreak_Rank_5'
    UpgradeIcon(17)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Speedfreak_Rank_5'
    UpgradeIcon(18)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Speedfreak_Rank_5'
    UpgradeIcon(19)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Speedfreak_Rank_5'
    UpgradeIcon(20)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Speedfreak_Rank_5'

    Name="Default__DKUpgrade_Perk_Speedster"
}
