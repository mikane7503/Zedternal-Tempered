// ===================================================================
// DKUpgrade_Perk_Possessor_Helper - per-player Possession state machine
//
// Spawned as a ChildActor of the human pawn by the perk's GetHelper (server).
// Server authoritative. While possessed, the OWNING PAWN stays the parked
// human (DKPC.PuppetSavedHuman) - the controller drives the puppet zed.
//
// This is a PERK-SHIPPED ability (like Hyde's serum / Domain's Room / the
// Blink Strike), NOT a slotted skill ability - so it deliberately does NOT
// use the RegisterAbility / F-slot system. It is triggered only by the
// dedicated O key (DKPlayerController.PossessorPress).
//
// Flow: PossessorPress -> ServerPossessorPress -> (ready) ClientOpenPossessorWheel
// with BuildWheelSnapshot(). The wheel (DKPossessorWheelMovie, reusing the
// CommandWheel SWF) fires ServerFirePossessorForm(index) -> FirePossess:
// resolve the form class + puppet health, hand off to the controller's
// proven puppet grab, then run the 20s duration timer. Revert (manual O,
// timer expiry, lethal damage, wave end, perk removal) all funnel through
// DKPC.ServerPuppetDrop, which calls back NotifyPossessionEnded to start
// the cooldown.
//
// Possessor SKILLS feed in through SetFormUnlock() (pushed by each skill's
// InitiateWeapon/WaveEnd/DeleteHelperClass, mirroring the Domain skills):
//   slot 0 Clot    -> Possess_Slasher upgrades it to the Slasher
//   slot 1..9      -> Crawler, Stalker, Bloat, Gorefast, Siren, Husk,
//                     Scrake, Fleshpound, Patriarch
// Deluxe level (2) = tougher puppet for that form.
//
// HUD: three-state card (Ready / Possessing / Cooldown) drawn in
// DKHudWrapper.DrawPossessorCard; the possession bar + seconds tick in
// real time client-side off EndTime.
// ===================================================================
class DKUpgrade_Perk_Possessor_Helper extends Info
    transient;

var KFPawn_Human OwnerPawn;
var DKPlayerController DKPC;
var int PerkLevel;

// Possession state (server).
var bool bPossessing;
var int CurrentFormIndex;
var float PossessEndTime;      // WorldInfo.TimeSeconds when the timer expires

// Cooldown bookkeeping (server).
var bool bOnCooldown;
var float CooldownStart;

// --- Form unlock levels (0 = locked, 1 = standard, 2 = deluxe) ---
// Slot 0 is special: always usable; its level is the Slasher skill's level
// (0 = base Clot, 1/2 = Slasher / Slasher deluxe).
var byte FormUnlockLevel[10];

// HUD card states (mirror Domain/Speedster's 0/1/2).
const HUD_READY      = 0;
const HUD_POSSESSING = 1;
const HUD_COOLDOWN   = 2;

// ===================================================================
// LIFECYCLE
// ===================================================================
function Initialize(KFPawn_Human InOwnerPawn, DKPlayerController InDKPC)
{
    OwnerPawn = InOwnerPawn;
    DKPC = InDKPC;

    if (OwnerPawn == None || DKPC == None)
    {
        Destroy();
        return;
    }

    bPossessing = false;
    bOnCooldown = false;
    CurrentFormIndex = -1;

    PushHUD(HUD_READY);
    SetTimer(0.25f, true, nameof(UpdateAbility));
}

function SetPerkLevel(int InLevel)
{
    PerkLevel = Clamp(InLevel, 1, 20);
}

// Skill push-in (Domain SetAbilityUnlock pattern).
function SetFormUnlock(int FormIndex, int lvl)
{
    if (FormIndex >= 0 && FormIndex <= 9)
        FormUnlockLevel[FormIndex] = byte(Clamp(lvl, 0, 2));
}

// ===================================================================
// TUNABLE ACCESSORS
// ===================================================================
function float GetCooldown()
{
    local float CD;

    CD = class'DKUpgrade_Perk_Possessor'.default.Cooldown;
    CD *= 1.0f - class'DKUpgrade_Perk_Possessor'.default.CooldownReductionPerRank * float(PerkLevel);

    return FMax(CD, 5.0f);
}

function float GetDuration()
{
    local float Dur;

    Dur = class'DKUpgrade_Perk_Possessor'.default.PossessDuration;
    if (PerkLevel >= 10)
        Dur += class'DKUpgrade_Perk_Possessor'.default.DurationBonusCapstone10;

    return Dur;
}

function bool IsFormUnlocked(int FormIndex)
{
    if (FormIndex == 0)
        return true;   // Clot (or Slasher) is always available

    return FormIndex >= 1 && FormIndex <= 9 && FormUnlockLevel[FormIndex] > 0;
}

// Form class table. Slots 0-8 use the game's proven player-driven Versus
// pawns (full special-move kits); slot 9 is the de-bossed Patriarch puppet.
function class<KFPawn_Monster> GetFormClass(int FormIndex)
{
    switch (FormIndex)
    {
        case 0:
            if (FormUnlockLevel[0] > 0)
                return class'KFGameContent.KFPawn_ZedClot_Slasher_Versus';
            return class'KFGameContent.KFPawn_ZedClot_Alpha_Versus';
        case 1: return class'KFGameContent.KFPawn_ZedCrawler_Versus';
        case 2: return class'KFGameContent.KFPawn_ZedStalker_Versus';
        case 3: return class'KFGameContent.KFPawn_ZedBloat_Versus';
        case 4: return class'KFGameContent.KFPawn_ZedGorefast_Versus';
        case 5: return class'KFGameContent.KFPawn_ZedSiren_Versus';
        case 6: return class'KFGameContent.KFPawn_ZedHusk_Versus';
        case 7: return class'KFGameContent.KFPawn_ZedScrake_Versus';
        case 8: return class'KFGameContent.KFPawn_ZedFleshPound_Versus';
        case 9: return class'DKPawn_ZedPatriarch_Puppet';
    }

    return None;
}

// Puppet health for a form: default health x rank-scaled multiplier,
// x deluxe multiplier if that form's skill is owned at deluxe level.
function int GetPuppetHealth(int FormIndex, class<KFPawn_Monster> ZedClass)
{
    local float Mult;

    Mult = class'DKUpgrade_Perk_Possessor'.default.PuppetHealthMultBase
         + class'DKUpgrade_Perk_Possessor'.default.PuppetHealthPerRank * float(PerkLevel);

    if (FormIndex >= 0 && FormIndex <= 9 && FormUnlockLevel[FormIndex] >= 2)
        Mult *= class'DKUpgrade_Perk_Possessor'.default.DeluxeFormHealthMult;

    return Max(int(float(ZedClass.default.Health) * Mult), 100);
}

// Outgoing-damage scalar for a form, mirroring GetPuppetHealth: rank-scaled
// base x deluxe (if that form is owned deluxe) x per-tier form multiplier.
// Read in DKGameInfo_Endless[_AllWeapons].ReduceDamage and applied to every
// hit the possessed zed lands. Always >= 1.0 (never weakens a form).
function float GetPuppetDamageScalar(int FormIndex)
{
    local float Mult;

    Mult = class'DKUpgrade_Perk_Possessor'.default.PuppetDamageMultBase
         + class'DKUpgrade_Perk_Possessor'.default.PuppetDamagePerRank * float(PerkLevel);

    if (FormIndex >= 0 && FormIndex <= 9 && FormUnlockLevel[FormIndex] >= 2)
        Mult *= class'DKUpgrade_Perk_Possessor'.default.DeluxeFormDamageMult;

    Mult *= GetFormDamageTierMult(FormIndex);

    return FMax(Mult, 1.0f);
}

// Per-tier form damage multiplier - this is where the big forms (Scrake,
// Fleshpound, Patriarch) hit far harder than trash. Form index map:
// 0 Clot/Slasher, 1 Crawler, 2 Stalker, 3 Bloat, 4 Gorefast, 5 Siren,
// 6 Husk, 7 Scrake, 8 Fleshpound, 9 Patriarch.
function float GetFormDamageTierMult(int FormIndex)
{
    switch (FormIndex)
    {
        case 7:   // Scrake
        case 8:   // Fleshpound
            return class'DKUpgrade_Perk_Possessor'.default.FormDamageMult_Large;
        case 9:   // Patriarch
            return class'DKUpgrade_Perk_Possessor'.default.FormDamageMult_Boss;
        case 3:   // Bloat
        case 5:   // Siren
        case 6:   // Husk
            return class'DKUpgrade_Perk_Possessor'.default.FormDamageMult_Medium;
        default:  // Clot/Slasher, Crawler, Stalker, Gorefast
            return class'DKUpgrade_Perk_Possessor'.default.FormDamageMult_Trash;
    }
}

// ===================================================================
// WHEEL SNAPSHOT - same packed shape as Domain:
// "rem0,..,rem9|tot0,..,tot9|unl0,..,unl9". The wheel only opens when the
// ability is ready, so cooldowns are all zero; unl carries the form unlock
// levels (slot 0 is always active in the movie, its level only swaps the
// Clot/Slasher label).
// ===================================================================
function string BuildWheelSnapshot()
{
    local string RemS, TotS, UnlS;
    local int i;

    for (i = 0; i < 10; i++)
    {
        if (i > 0)
        {
            RemS $= ",";
            TotS $= ",";
            UnlS $= ",";
        }
        RemS $= "0";
        TotS $= "0";
        UnlS $= string(int(FormUnlockLevel[i]));
    }

    return RemS $ "|" $ TotS $ "|" $ UnlS;
}

// ===================================================================
// ACTIVATION
// ===================================================================
function bool CanPossess()
{
    return !bPossessing
        && !bOnCooldown
        && OwnerPawn != None
        && OwnerPawn.Health > 0
        && DKPC != None
        && DKPC.PuppetZed == None;   // not already puppeting (incl. debug commands)
}

// Fired by the wheel click (DKPlayerController.ServerFirePossessorForm).
function FirePossess(int FormIndex)
{
    local class<KFPawn_Monster> ZedClass;
    local int PuppetHealth;

    if (!CanPossess())
        return;

    if (!IsFormUnlocked(FormIndex))
    {
        class'DKMessageManager'.static.SendMinor(DKPC, "Possession: that form is not unlocked.");
        return;
    }

    ZedClass = GetFormClass(FormIndex);
    if (ZedClass == None)
        return;

    PuppetHealth = GetPuppetHealth(FormIndex, ZedClass);

    // Hand off to the controller's proven puppet machinery (spawn, park the
    // human, possess, camera + input routing, lethal-damage auto-revert).
    DKPC.ServerPuppetGrabClass(ZedClass, PuppetHealth);

    // Grab can fail (blocked spawn location) - only start the clock if the
    // controller actually holds a puppet now.
    if (DKPC.PuppetZed == None)
        return;

    bPossessing = true;
    CurrentFormIndex = FormIndex;
    PossessEndTime = WorldInfo.TimeSeconds + GetDuration();
    SetTimer(GetDuration(), false, nameof(PossessionExpired));

    PushHUD(HUD_POSSESSING);
}

// Duration ran out -> revert. ServerPuppetDrop calls back
// NotifyPossessionEnded, which starts the cooldown.
function PossessionExpired()
{
    if (bPossessing && DKPC != None)
        DKPC.ServerPuppetDrop();
}

// Called by DKPlayerController.ServerPuppetDrop on EVERY revert path
// (manual O, timer, lethal damage, wave end, cleanup).
function NotifyPossessionEnded()
{
    if (!bPossessing)
        return;

    bPossessing = false;
    CurrentFormIndex = -1;
    ClearTimer(nameof(PossessionExpired));

    bOnCooldown = true;
    CooldownStart = WorldInfo.TimeSeconds;

    PushHUD(HUD_COOLDOWN);
}

// Capstone 2: a kill made while possessed extends the possession timer.
function NotifyPuppetKill()
{
    local float Bonus, Remaining;

    if (!bPossessing || PerkLevel < 20)
        return;

    Bonus = class'DKUpgrade_Perk_Possessor'.default.KillDurationBonusCapstone20;
    PossessEndTime += Bonus;
    Remaining = PossessEndTime - WorldInfo.TimeSeconds;

    SetTimer(FMax(Remaining, 0.1f), false, nameof(PossessionExpired));

    // Re-push so the client bar re-anchors to the new remaining time.
    ClientPossessorHUD(HUD_POSSESSING, Remaining);
}

// ===================================================================
// COOLDOWN TICK
// ===================================================================
function UpdateAbility()
{
    local float Elapsed;

    if (OwnerPawn == None || OwnerPawn.Health <= 0)
        return;

    if (bOnCooldown)
    {
        Elapsed = WorldInfo.TimeSeconds - CooldownStart;
        if (Elapsed >= GetCooldown())
        {
            bOnCooldown = false;
            PushHUD(HUD_READY);
            class'DKMessageManager'.static.SendImportant(DKPC, "Possession ready!");
        }
    }
}

// ===================================================================
// HUD - server pushes a state; the owning client records its own EndTime
// and animates the bar + seconds in DKHudWrapper.DrawPossessorCard.
// ===================================================================
function PushHUD(byte State)
{
    local float Dur;

    if (State == HUD_COOLDOWN)
        Dur = GetCooldown();
    else if (State == HUD_POSSESSING)
        Dur = FMax(PossessEndTime - WorldInfo.TimeSeconds, 0.0f);
    else
        Dur = 0.0f;   // Ready: full slim bar, no drain

    ClientPossessorHUD(State, Dur);
}

function ClearHUD()
{
    ClientPossessorHUD(255, 0.0f);   // 255 = hide
}

reliable client function ClientPossessorHUD(byte State, float Duration)
{
    local KFPlayerController LocalPC;
    local DKHudWrapper HUD;

    LocalPC = KFPlayerController(GetALocalPlayerController());
    if (LocalPC == None)
        return;

    HUD = class'DKHudWrapper'.static.GetReaperHUD(LocalPC);
    if (HUD == None)
        return;

    if (State == 255)
        HUD.ClearPossessorDisplay();
    else
        HUD.UpdatePossessorDisplay(State, Duration);
}

// ===================================================================
// WAVE / CLEANUP
// ===================================================================
function OnWaveEnd()
{
    // Force revert (drop calls back NotifyPossessionEnded) then clear the
    // cooldown for a fresh wave.
    if (bPossessing && DKPC != None)
        DKPC.ServerPuppetDrop();

    ClearTimer(nameof(PossessionExpired));
    bPossessing = false;
    bOnCooldown = false;
    CurrentFormIndex = -1;

    PushHUD(HUD_READY);
}

function Cleanup()
{
    // Perk removed / pawn dying while possessed: get the player back into
    // the human before the helper goes away.
    if (bPossessing && DKPC != None && DKPC.PuppetZed != None)
        DKPC.ServerPuppetDrop();

    ClearTimer(nameof(PossessionExpired));
    ClearTimer(nameof(UpdateAbility));
    ClearHUD();
}

simulated function Destroyed()
{
    Cleanup();
    Super.Destroyed();
}

defaultproperties
{
    RemoteRole=ROLE_SimulatedProxy
    bOnlyRelevantToOwner=True
    bAlwaysRelevant=False
    bHidden=True

    bPossessing=False
    bOnCooldown=False
    CurrentFormIndex=-1
    PerkLevel=1

    Name="Default__DKUpgrade_Perk_Possessor_Helper"
}
