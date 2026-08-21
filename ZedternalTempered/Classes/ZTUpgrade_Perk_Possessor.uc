// ===================================================================
// ZTUpgrade_Perk_Possessor - "Possession"
//
// Body-snatcher perk built around one active ability on a dedicated key
// (default O, PossessorPress):
//
//   Possession: press O to open the form wheel (reuses the proven
//   CommandWheel SWF). Click a form to leave your human body behind
//   (parked safe, invisible, ignored by AI) and take direct control of a
//   player-driven ZED for a limited time (default 20s). Press O again to
//   revert early; you also auto-revert when the timer runs out or the
//   puppet takes lethal damage. Cooldown starts on revert.
//
//   By default only the Clot is available (wheel slot 0). Each of the 10
//   Possessor skills unlocks another form: the Slasher skill upgrades
//   slot 0 (Clot -> Slasher), the other 9 fill wheel slots 1-9 up to the
//   Patriarch. Deluxe skill level makes that form tougher.
//
// Rank scaling: puppet health and possession cooldown scale per rank.
// Capstone 1 (lvl 10): +5s possession duration.
// Capstone 2 (lvl 20): kills made while possessed extend the possession
//                      timer (+2s per kill).
//
// All state (cooldown, duration timer, form unlocks, HUD, wheel snapshot)
// lives in ZTUpgrade_Perk_Possessor_Helper. The actual possess / park /
// revert machinery is ZTPlayerController's puppet path. This class is the
// upgrade hook surface + helper management + tunables.
// ===================================================================
class ZTUpgrade_Perk_Possessor extends ZTUpgrade_Perk config(ZedternalUnlimited);

// --- Possession active ---
var config float PossessDuration;             // s: base time you stay in the puppet
var config float DurationBonusCapstone10;     // s: added at capstone 1 (lvl 10)
var config float Cooldown;                    // s: base cooldown, starts on revert
var config float CooldownReductionPerRank;    // fraction removed per rank (0.01 = -1%/rank)

// Puppet durability. Health = form's default health x
// (PuppetHealthMultBase + PuppetHealthPerRank * rank), x DeluxeFormHealthMult
// if that form's skill is owned at deluxe level.
var config float PuppetHealthMultBase;
var config float PuppetHealthPerRank;
var config float DeluxeFormHealthMult;

// Capstone 2: seconds added to the possession timer per kill while possessed.
var config float KillDurationBonusCapstone20;

// --- Possessed-zed OUTGOING damage (MODEVERSION 2) ---
// A possessed form deals its Versus-balanced damage, which is far too low
// against Endless zeds. Scale the damage it DEALS by rank + deluxe + a
// per-tier form multiplier so bigger forms hit much harder.
// Final scalar = (Base + PerRank*rank) x (deluxe? DeluxeMult : 1) x TierMult.
var config float PuppetDamageMultBase;
var config float PuppetDamagePerRank;
var config float DeluxeFormDamageMult;
var config float FormDamageMult_Trash;    // Clot/Slasher, Crawler, Stalker, Gorefast
var config float FormDamageMult_Medium;   // Bloat, Siren, Husk
var config float FormDamageMult_Large;    // Scrake, Fleshpound
var config float FormDamageMult_Boss;     // Patriarch

var config int MODEVERSION;

// ===================================================================
// CONFIG SEED
// ===================================================================
static function UpdateConfig()
{
    if (default.MODEVERSION < 1)
    {
        default.PossessDuration          = 20.0f;
        default.DurationBonusCapstone10  = 5.0f;
        default.Cooldown                 = 40.0f;
        default.CooldownReductionPerRank = 0.01f;   // -20% @20

        default.PuppetHealthMultBase   = 1.5f;
        default.PuppetHealthPerRank    = 0.05f;     // +100% @20 -> 2.5x total
        default.DeluxeFormHealthMult   = 1.5f;

        default.KillDurationBonusCapstone20 = 2.0f;

        default.MODEVERSION = 1;
        static.StaticSaveConfig();
    }

    if (default.MODEVERSION < 2)
    {
        // Possessed zeds hit hard, and the big forms hit MUCH harder.
        default.PuppetDamageMultBase = 2.0f;     // all forms start at 2x
        default.PuppetDamagePerRank  = 0.05f;    // +5%/rank -> +100% @20 (3.0x base)
        default.DeluxeFormDamageMult = 1.5f;     // deluxe form: +50% on top

        default.FormDamageMult_Trash  = 1.0f;    // clot/slasher, crawler, stalker, gorefast
        default.FormDamageMult_Medium = 1.5f;    // bloat, siren, husk
        default.FormDamageMult_Large  = 3.0f;    // Scrake / Fleshpound - way more
        default.FormDamageMult_Boss   = 4.0f;    // Patriarch - hardest hitter

        default.MODEVERSION = 2;
        static.StaticSaveConfig();
    }
}

// ===================================================================
// HELPER MANAGEMENT
// ===================================================================

// Spawns if missing (server-side). Safe to call from server hooks.
static function ZTUpgrade_Perk_Possessor_Helper GetHelper(Pawn OwnerPawn)
{
    local ZTUpgrade_Perk_Possessor_Helper H;
    local ZTPlayerController DKPC;

    if (KFPawn_Human(OwnerPawn) != None && OwnerPawn.Role == ROLE_Authority)
    {
        foreach OwnerPawn.ChildActors(class'ZTUpgrade_Perk_Possessor_Helper', H)
            return H;

        DKPC = ZTPlayerController(OwnerPawn.Controller);
        if (DKPC == None)
            return None;

        H = OwnerPawn.Spawn(class'ZTUpgrade_Perk_Possessor_Helper', OwnerPawn);
        if (H != None)
            H.Initialize(KFPawn_Human(OwnerPawn), DKPC);
    }

    return H;
}

// Never spawns - safe for client-side simulated hooks.
static simulated function ZTUpgrade_Perk_Possessor_Helper FindHelper(Pawn OwnerPawn)
{
    local ZTUpgrade_Perk_Possessor_Helper H;

    if (OwnerPawn != None)
    {
        foreach OwnerPawn.ChildActors(class'ZTUpgrade_Perk_Possessor_Helper', H)
            return H;
    }

    return None;
}

static simulated function InitiateWeapon(int upgLevel, KFWeapon KFW, KFPawn OwnerPawn)
{
    local ZTUpgrade_Perk_Possessor_Helper H;

    if (KFPawn_Human(OwnerPawn) != None && OwnerPawn.Role == ROLE_Authority)
    {
        H = GetHelper(OwnerPawn);
        if (H != None)
            H.SetPerkLevel(upgLevel);
    }
}

static simulated function DeleteHelperClass(Pawn OwnerPawn)
{
    local ZTUpgrade_Perk_Possessor_Helper H;

    if (OwnerPawn != None)
    {
        foreach OwnerPawn.ChildActors(class'ZTUpgrade_Perk_Possessor_Helper', H)
        {
            H.Cleanup();
            H.Destroy();
        }
    }
}

static function WaveEnd(int upgLevel, KFPlayerController KFPC)
{
    local ZTUpgrade_Perk_Possessor_Helper H;
    local ZTPlayerController DKPC;
    local Pawn HelperPawn;

    if (KFPC == None)
        return;

    // While possessed, KFPC.Pawn is the puppet zed - the helper lives on the
    // parked human. Resolve through the controller's saved human in that case.
    HelperPawn = KFPC.Pawn;
    DKPC = ZTPlayerController(KFPC);
    if (DKPC != None && DKPC.PuppetSavedHuman != None)
        HelperPawn = DKPC.PuppetSavedHuman;

    if (HelperPawn == None)
        return;

    H = FindHelper(HelperPawn);
    if (H != None)
    {
        H.SetPerkLevel(upgLevel);
        H.OnWaveEnd();   // force revert + clear cooldown for a fresh wave
    }
}

// ===================================================================
// CAPSTONE 2 - kills made while possessed extend the possession timer.
// Wired from ZTGameInfo_Endless / _AllWeapons Killed() next to the
// Artificer / Detonator kill notifies.
// ===================================================================
static function NotifyZedKilled(Controller Killer, Pawn KilledPawn, class<DamageType> DT)
{
    local ZTPlayerController DKPC;
    local ZTUpgrade_Perk_Possessor_Helper H;

    DKPC = ZTPlayerController(Killer);
    if (DKPC == None || DKPC.PuppetZed == None || DKPC.PuppetSavedHuman == None)
        return;

    // Only count kills made BY the puppet (not e.g. lingering DoT from the human form).
    if (DKPC.Pawn != DKPC.PuppetZed)
        return;

    // Don't extend off the puppet itself dying.
    if (KilledPawn == DKPC.PuppetZed)
        return;

    H = FindHelper(DKPC.PuppetSavedHuman);
    if (H != None)
        H.NotifyPuppetKill();
}

defaultproperties
{
	UpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Shapeshifter_Rank_0'
    bShouldLocalize=True
    LocPackage="ZedternalTempered"
    LocSection="ZTUpgrade_Perk_Possessor"
    LocalizeDescriptionLineCount=5

    UpgradeName="Possessor"
    upgradeDescription(0)="Press your <font color=\"#15d7fa\">Possession</font> key (default <font color=\"#ffc832\">O</font>) to open the form wheel and take control of a <font color=\"#ff3399\">ZED</font> for <font color=\"#77d914\">20s</font>. Press again to revert early. Only the <font color=\"#15d7fa\">Clot</font> is available by default; skills unlock stronger forms."
    upgradeDescription(1)="Your puppet has <font color=\"#77d914\">%x%%</font> <font color=\"#15d7fa\">bonus health</font>."
    upgradeDescription(2)="Possession <font color=\"#15d7fa\">cooldown</font> is reduced by <font color=\"#77d914\">%x%%</font>."
    upgradeDescription(3)="<font color=\"#8B0000\">LEVEL 10:</font> Possession lasts <font color=\"#77d914\">5s longer</font>."
    upgradeDescription(4)="<font color=\"#8B0000\">LEVEL 20:</font> Kills made while possessed <font color=\"#77d914\">extend</font> the possession timer by <font color=\"#77d914\">2s</font> each."

    PerkBonus(1)=(baseValue=50, incValue=5, maxValue=-1)
    PerkBonus(2)=(baseValue=0, incValue=1, maxValue=-1)

    Name="Default__ZTUpgrade_Perk_Possessor"
}
