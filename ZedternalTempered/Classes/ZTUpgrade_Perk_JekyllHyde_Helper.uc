// ===================================================================
// ZTUpgrade_Perk_JekyllHyde_Helper - per-player Hyde state machine
//
// Spawned as a ChildActor of the human pawn by the perk's InitiateWeapon.
// Server authoritative. Replicates bHyde + bAfterglowActive to the owning
// client so skill hooks can read the current form / afterglow window.
//
// Drives the body-scale transform, the per-wave charge economy, the melee
// shockwave, the serum sounds, and the HUD meter. Also exposes hooks for
// the Jekyll/Hyde SKILLS to feed it state (banked duration, timer
// extension, vampire->armor banking, AoE radius/scale boosts, afterglow).
// ===================================================================
class ZTUpgrade_Perk_JekyllHyde_Helper extends Info;

var KFPawn_Human OwnerPawn;
var ZTPlayerController DKPC;

// Replicated to the owning client (skill hooks read these).
var bool bHyde;
var bool bAfterglowActive;   // Lingering Beast window after a revert

// Server-only guard: true while the melee shockwave is dealing its damage.
var bool bShockwaveActive;

var int PerkLevel;
var int Charges;
var int MaxCharges;
var float CurDuration;
var bool bNeedsInitialCharge;

// --- Skill-driven modifiers (set by the owning skills' InitiateWeapon) ---
var float BankedBonusDuration;     // Adrenaline Reserve: added to NEXT transform
var int   BankedArmor;             // Monstrous Vitality: vampire banked -> armor on revert
var float BloodlustAddedThisHyde;  // Bloodlust: running per-transform extension total
var float SeismicRadiusBonus;      // Seismic Slam: + fraction to shockwave radius
var float SeismicMomentumMult;     // Seismic Slam: knockback multiplier (0 = default x1)
var float TitanicScaleOverride;    // Titanic Frame: overrides body scale (0 = use perk default)
var float TitanicRadiusBonus;      // Titanic Frame: + fraction to shockwave radius
var bool  bLingering;              // Lingering Beast owned
var float LingeringDuration;       // afterglow length (s)

// HUD card states (mirrored in ZTHudWrapper.DrawHydeDisplay)
const HYDE_HUD_HIDDEN = 0;
const HYDE_HUD_READY  = 1;   // Jekyll: show charges
const HYDE_HUD_ACTIVE = 2;   // Hyde: show draining meter + charges

replication
{
    if (bNetDirty)
        bHyde, bAfterglowActive;
}

simulated function PostBeginPlay()
{
    Super.PostBeginPlay();

    OwnerPawn = KFPawn_Human(Owner);

    if (Role == ROLE_Authority)
    {
        if (OwnerPawn != None)
            DKPC = ZTPlayerController(OwnerPawn.Controller);

        bHyde = False;
        bAfterglowActive = False;
        bShockwaveActive = False;
        Charges = 0;
        MaxCharges = class'ZTUpgrade_Perk_JekyllHyde'.default.HydeChargesBase;
        bNeedsInitialCharge = True;
    }
}

function ZTPlayerController GetPC()
{
    if (DKPC == None && OwnerPawn != None)
        DKPC = ZTPlayerController(OwnerPawn.Controller);
    return DKPC;
}

function int MaxChargesForLevel(int L)
{
    if (L >= class'ZTConfig_Capstone'.static.GetRank2Level())
        return class'ZTUpgrade_Perk_JekyllHyde'.default.HydeChargesCapstone2;
    return class'ZTUpgrade_Perk_JekyllHyde'.default.HydeChargesBase;
}

function float DurationForLevel(int L)
{
    local float D;

    D = class'ZTUpgrade_Perk_JekyllHyde'.default.HydeDuration;
    if (L >= class'ZTConfig_Capstone'.static.GetRank1Level())
        D *= class'ZTUpgrade_Perk_JekyllHyde'.default.HydeDurationCapstoneMult;
    return D;
}

function SetPerkLevel(int L)
{
    local int OldMax;

    PerkLevel = L;
    OldMax = MaxCharges;
    MaxCharges = MaxChargesForLevel(L);

    if (bNeedsInitialCharge)
    {
        Charges = MaxCharges;
        bNeedsInitialCharge = False;
        PushHUD(HYDE_HUD_READY);
        return;
    }

    // Cap raised mid-game (e.g. capstone 2 just bought): grant the newly
    // unlocked charge(s) right now and refresh the HUD so the meter jumps
    // from 1/1 to 2/2 the instant the upgrade is purchased -- BuyPerkUpgrade
    // -> UpdateWeaponMagAndCap -> ReInitializeAmmoCounts -> InitiateWeapon
    // reaches us synchronously, so no wave boundary is needed.
    if (MaxCharges > OldMax)
    {
        Charges += (MaxCharges - OldMax);
        if (Charges > MaxCharges)
            Charges = MaxCharges;
        if (!bHyde)
            PushHUD(HYDE_HUD_READY);
    }
    else if (Charges > MaxCharges)
    {
        Charges = MaxCharges;
        if (!bHyde)
            PushHUD(HYDE_HUD_READY);
    }
}

// ===================================================================
// ACTIVATION
// ===================================================================
function TryActivate()
{
    if (OwnerPawn == None || OwnerPawn.Health <= 0)
    {
        class'ZTMessageManager'.static.SendMinor(GetPC(), "Hyde Serum: cannot transform while down.");
        return;
    }

    if (bHyde)
    {
        class'ZTMessageManager'.static.SendMinor(GetPC(), "Hyde Serum: already transformed.");
        return;
    }

    if (Charges <= 0)
    {
        class'ZTMessageManager'.static.SendMinor(GetPC(), "Hyde Serum: no doses left this wave.");
        return;
    }

    Activate();
}

function Activate()
{
    local float UseScale;

    Charges--;
    bHyde = True;
    bNetDirty = True;
    bShockwaveActive = False;
    BloodlustAddedThisHyde = 0.0f;

    CurDuration = DurationForLevel(PerkLevel);

    // Adrenaline Reserve: spend any banked bonus duration.
    if (BankedBonusDuration > 0.0f)
    {
        CurDuration += BankedBonusDuration;
        BankedBonusDuration = 0.0f;
    }

    // Titanic Frame can override the visual scale.
    UseScale = class'ZTUpgrade_Perk_JekyllHyde'.default.HydeBodyScale;
    if (TitanicScaleOverride > 0.0f)
        UseScale = TitanicScaleOverride;

    // Grow-in transform (mesh-only scale, anchored at feet -> no sinking).
    OwnerPawn.BodyScaleChangePerSecond = class'ZTUpgrade_Perk_JekyllHyde'.default.HydeScaleRate;
    OwnerPawn.IntendedBodyScale = UseScale;

    PlayHydeSound('Hyde_Activate');
    class'ZTMessageManager'.static.SendImportant(GetPC(), "MR. HYDE UNLEASHED!");

    SetTimer(CurDuration, False, nameof(EndHyde));
    PushHUD(HYDE_HUD_ACTIVE);
}

// Natural expiry
function EndHyde()
{
    bHyde = False;
    bNetDirty = True;

    if (OwnerPawn != None)
    {
        OwnerPawn.BodyScaleChangePerSecond = class'ZTUpgrade_Perk_JekyllHyde'.default.HydeScaleRate;
        OwnerPawn.IntendedBodyScale = 1.0f;

        // Monstrous Vitality: grant the banked lifesteal as armor.
        if (BankedArmor > 0)
        {
            OwnerPawn.AddArmor(BankedArmor);
            BankedArmor = 0;
        }
    }

    // Lingering Beast: open the afterglow window.
    if (bLingering && LingeringDuration > 0.0f)
    {
        bAfterglowActive = True;
        bNetDirty = True;
        SetTimer(LingeringDuration, False, nameof(EndAfterglow));
    }

    PlayHydeSound('Hyde_Deactivate');
    class'ZTMessageManager'.static.SendMinor(GetPC(), "Reverting to Dr. Jekyll...");
    PushHUD(HYDE_HUD_READY);
}

function EndAfterglow()
{
    bAfterglowActive = False;
    bNetDirty = True;
}

// Silent revert for cleanup / perk removal (no sound, no afterglow, no armor grant)
function ForceRevert()
{
    ClearTimer(nameof(EndHyde));
    ClearTimer(nameof(EndAfterglow));

    if (bHyde && OwnerPawn != None)
    {
        OwnerPawn.BodyScaleChangePerSecond = class'ZTUpgrade_Perk_JekyllHyde'.default.HydeScaleRate;
        OwnerPawn.IntendedBodyScale = 1.0f;
    }

    bHyde = False;
    bAfterglowActive = False;
    BankedArmor = 0;
    bNetDirty = True;
    PushHUD(HYDE_HUD_HIDDEN);
}

function OnWaveEnd()
{
    // End any active transform/afterglow cleanly, then refill the wave's charges.
    ClearTimer(nameof(EndHyde));
    ClearTimer(nameof(EndAfterglow));

    if (bHyde && OwnerPawn != None)
    {
        OwnerPawn.BodyScaleChangePerSecond = class'ZTUpgrade_Perk_JekyllHyde'.default.HydeScaleRate;
        OwnerPawn.IntendedBodyScale = 1.0f;
    }

    bHyde = False;
    bAfterglowActive = False;
    BankedArmor = 0;
    BankedBonusDuration = 0.0f;
    bNetDirty = True;

    Charges = MaxCharges;
    PushHUD(HYDE_HUD_READY);
}

// ===================================================================
// SKILL HOOKS (called by the Jekyll/Hyde skills)
// ===================================================================

// Adrenaline Reserve - bank duration toward the NEXT transform (capped).
function AddBankedDuration(float Amount, float Cap)
{
    BankedBonusDuration = FMin(BankedBonusDuration + Amount, Cap);
}

// Bloodlust - extend the CURRENT transform (capped per transform).
function ExtendHyde(float Amount, float Cap)
{
    local float Remaining, Add;

    if (!bHyde || Amount <= 0.0f)
        return;

    if (BloodlustAddedThisHyde >= Cap)
        return;

    Add = FMin(Amount, Cap - BloodlustAddedThisHyde);
    if (Add <= 0.0f)
        return;

    BloodlustAddedThisHyde += Add;

    Remaining = GetTimerRate(nameof(EndHyde)) - GetTimerCount(nameof(EndHyde));
    Remaining = FMax(Remaining, 0.0f) + Add;

    ClearTimer(nameof(EndHyde));
    SetTimer(Remaining, False, nameof(EndHyde));

    CurDuration = Remaining;
    PushHUD(HYDE_HUD_ACTIVE);
}

// Monstrous Vitality - bank lifesteal as armor (granted on revert, capped).
function BankVampireArmor(int Amount)
{
    if (Amount <= 0)
        return;

    BankedArmor += Amount;
    if (OwnerPawn != None && BankedArmor > OwnerPawn.GetMaxArmor())
        BankedArmor = OwnerPawn.GetMaxArmor();
}

// Reset helpers (called from the contributing skills' DeleteHelperClass).
function ResetSeismic()  { SeismicRadiusBonus = 0.0f; SeismicMomentumMult = 0.0f; }
function ResetTitanic()  { TitanicScaleOverride = 0.0f; TitanicRadiusBonus = 0.0f; }
function ResetLingering(){ bLingering = False; LingeringDuration = 0.0f; }

// ===================================================================
// MELEE SHOCKWAVE - radial damage when a Hyde melee hit lands on a zed
// ===================================================================
function MeleeShockwave(KFPawn_Monster HitZed, int DamageAmount, class<KFDamageType> DT, KFPlayerController Instig)
{
    local KFPawn_Monster M;
    local vector Origin, Dir;
    local float Radius, MinFrac, Dist, Frac, MomentumMult;
    local int Dmg;

    if (bShockwaveActive || HitZed == None)
        return;

    Radius = class'ZTUpgrade_Perk_JekyllHyde'.default.HydeAoERadius
        * (1.0f + SeismicRadiusBonus + TitanicRadiusBonus);
    MinFrac = class'ZTUpgrade_Perk_JekyllHyde'.default.HydeAoEMinDamageFrac;
    Origin = HitZed.Location;

    MomentumMult = 1.0f;
    if (SeismicMomentumMult > 0.0f)
        MomentumMult = SeismicMomentumMult;

    bShockwaveActive = True;

    foreach WorldInfo.AllPawns(class'KFPawn_Monster', M, Origin, Radius)
    {
        if (M == HitZed || M.Health <= 0 || !M.IsAliveAndWell())
            continue;

        Dist = VSize(M.Location - Origin);
        Frac = 1.0f - (Dist / Radius) * (1.0f - MinFrac);
        Frac = FClamp(Frac, MinFrac, 1.0f);
        Dmg = Round(float(DamageAmount) * Frac);

        Dir = Normal(M.Location - Origin);
        M.TakeDamage(Dmg, Instig, M.Location, Dir * 5000.0f * MomentumMult, DT, , OwnerPawn);
    }

    bShockwaveActive = False;
}

// ===================================================================
// SOUND - routed through the owning client via ClientPlayBuffSound
// ===================================================================
function PlayHydeSound(name SoundID)
{
    local ZTMutator Mut;
    local SoundCue Cue;
    local ZTPlayerController PC;

    PC = GetPC();
    if (PC == None || OwnerPawn == None)
        return;

    Mut = class'ZTSoundManager'.static.GetMutator(OwnerPawn.WorldInfo);
    if (Mut == None)
        return;

    Cue = class'ZTSoundManager'.static.GetSound(Mut, SoundID);
    if (Cue != None)
        PC.ClientPlayBuffSound(Cue);
}

// ===================================================================
// HUD - server pushes state; the client records its own end-time and
// animates the meter smoothly in ZTHudWrapper.DrawHydeDisplay.
// ===================================================================
function PushHUD(byte State)
{
    ClientHydeHUD(State, CurDuration, Charges, MaxCharges);
}

reliable client function ClientHydeHUD(byte State, float Duration, int InCharges, int InMax)
{
    local KFPlayerController LocalPC;
    local ZTHudWrapper HUD;

    LocalPC = KFPlayerController(GetALocalPlayerController());
    if (LocalPC == None)
        return;

    HUD = class'ZTHudWrapper'.static.GetReaperHUD(LocalPC);
    if (HUD == None)
        return;

    if (State == HYDE_HUD_HIDDEN)
        HUD.ClearHydeDisplay();
    else
        HUD.UpdateHydeDisplay(State, Duration, InCharges, InMax);
}

// ===================================================================
// CLEANUP
// ===================================================================
function Cleanup()
{
    ClearTimer(nameof(EndHyde));
    ClearTimer(nameof(EndAfterglow));
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
    bSkipActorPropertyReplication=False
    bHidden=True

    bHyde=False
    bAfterglowActive=False
    bShockwaveActive=False
    Charges=0
    MaxCharges=1
    PerkLevel=1
    bNeedsInitialCharge=True

    BankedBonusDuration=0.0
    BankedArmor=0
    SeismicRadiusBonus=0.0
    SeismicMomentumMult=0.0
    TitanicScaleOverride=0.0
    TitanicRadiusBonus=0.0
    bLingering=False
    LingeringDuration=0.0

    Name="Default__ZTUpgrade_Perk_JekyllHyde_Helper"
}
