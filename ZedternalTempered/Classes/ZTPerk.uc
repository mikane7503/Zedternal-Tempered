// ===================================================================
// ZTPerk - Extended perk system with roguelike upgrade stat integration
// + paged perk dispatch for indices >= 256 (Phase 3b)
//
// Hooks into WMPerk functions that need roguelike stat modifications.
// Supports Glass Cannon, Sumo, Opportunist, Duelist, Last Round.
//
// PHASE 3b BATCH 1: Adds dispatch loops and parallel passive cache for
// perks at index 256+. Parent's MyWMPRI.bPerkUpgrade is fixed [256] so
// reads for idx >= 256 OOB to level=0 (static methods bail). DKPRI
// maintains paged level data via GetPerkLevel; we re-iterate
// Purchase_PerkUpgrade after super to invoke 256+ perks' static methods
// with correct level.
//
// At <256 perks, paged loops iterate but skip every entry (idx<256
// short-circuit). DK passive cache stays at 1.0f. Net effect: no
// behavioral change vs Phase 3a.
//
// Batch 1 covers: passive cache infrastructure + 11 existing modifier
// overrides. Batch 2 will cover the remaining ~60 dispatch functions.
// ===================================================================
class ZTPerk extends WMPerk;

// Constants for conditional checks
const DUELIST_RANGE = 1500.0;  // 15 meters in UU (100 UU = 1m)
const OPPORTUNIST_DOT_THRESHOLD = -0.5;  // Dot product threshold for "behind"

// ===================================================================
// DK PAGED PASSIVE CACHE (256+ contributions)
// Parent's PassiveX cache vars are private; we maintain a parallel
// cache for paged perks. Applied as additional multiplier in our
// modifier overrides after super. Initialized to 1.0f in
// defaultproperties so a modifier call that arrives before
// ApplySkillsToPawn won't multiply by 0.
// ===================================================================

// Server-only (8 vars)
var private float DKPassiveDamageGiven_256Plus;
var private float DKPassiveDamageTaken_256Plus;
var private float DKPassiveHealAmount_256Plus;
var private float DKPassiveHardAttackDamage_256Plus;
var private float DKPassiveStunPower_256Plus;
var private float DKPassiveStumblePower_256Plus;
var private float DKPassiveKnockdownPower_256Plus;
var private float DKPassiveSnarePower_256Plus;

// Client+Server (12 vars)
var private float DKPassiveMovementSpeed_256Plus;
var private float DKPassiveSwitchSpeed_256Plus;
var private float DKPassiveMeleeAttackSpeed_256Plus;
var private float DKPassiveReloadRateScale_256Plus;
var private float DKPassiveRecoil_256Plus;
var private float DKPassiveSpread_256Plus;
var private float DKPassiveBobDamp_256Plus;
var private float DKPassiveMagazineCapacity_256Plus;
var private float DKPassiveSpareAmmo_256Plus;
var private float DKPassiveRateOfFire_256Plus;
var private float DKPassiveTightChoke_256Plus;
var private float DKPassivePenetration_256Plus;

// ===================================================================
// ROGUELIKE STAT ACCESS
// ===================================================================

// Get DKPRI for roguelike stat access (server-side)
function ZTPlayerReplicationInfo GetDKPRI()
{
    local ZTPlayerController DKPC;

    DKPC = ZTPlayerController(OwnerPC);
    if (DKPC != None)
    {
        return ZTPlayerReplicationInfo(DKPC.PlayerReplicationInfo);
    }

    return None;
}

// Get DKPRI for roguelike stat access (client-side)
simulated function ZTPlayerReplicationInfo GetDKPRISimulated()
{
    local ZTPlayerController DKPC;

    if (OwnerPC != None)
        DKPC = ZTPlayerController(OwnerPC);
    else if (Owner != None)
        DKPC = ZTPlayerController(Owner);

    if (DKPC != None)
    {
        return ZTPlayerReplicationInfo(DKPC.PlayerReplicationInfo);
    }

    return None;
}

// ===================================================================
// PASSIVE CACHE LIFECYCLE (Phase 3b)
// Parent's ServerComputePassiveBonuses calls ServerPassiveBonusDefaults
// at the top — virtual dispatch resolves our override on a ZTPerk
// instance, so our DK cache resets in sync with parent's. Same for
// ClientAndServer.
// ===================================================================

function ServerPassiveBonusDefaults()
{
    Super.ServerPassiveBonusDefaults();

    DKPassiveDamageGiven_256Plus = 1.0f;
    DKPassiveDamageTaken_256Plus = 1.0f;
    DKPassiveHealAmount_256Plus = 1.0f;
    DKPassiveHardAttackDamage_256Plus = 1.0f;
    DKPassiveStunPower_256Plus = 1.0f;
    DKPassiveStumblePower_256Plus = 1.0f;
    DKPassiveKnockdownPower_256Plus = 1.0f;
    DKPassiveSnarePower_256Plus = 1.0f;
}

simulated function ClientAndServerPassiveBonusDefaults()
{
    Super.ClientAndServerPassiveBonusDefaults();

    DKPassiveMovementSpeed_256Plus = 1.0f;
    DKPassiveSwitchSpeed_256Plus = 1.0f;
    DKPassiveMeleeAttackSpeed_256Plus = 1.0f;
    DKPassiveReloadRateScale_256Plus = 1.0f;
    DKPassiveRecoil_256Plus = 1.0f;
    DKPassiveSpread_256Plus = 1.0f;
    DKPassiveBobDamp_256Plus = 1.0f;
    DKPassiveMagazineCapacity_256Plus = 1.0f;
    DKPassiveSpareAmmo_256Plus = 1.0f;
    DKPassiveRateOfFire_256Plus = 1.0f;
    DKPassiveTightChoke_256Plus = 1.0f;
    DKPassivePenetration_256Plus = 1.0f;
}

function ServerComputePassiveBonuses()
{
    // Super calls ServerPassiveBonusDefaults() (our override resets both
    // parent's privates AND our DK vars), then iterates
    // Purchase_PerkUpgrade. For idx >= 256 entries in Purchase, super
    // reads OOB level=0 so static ModifyXPassive bails -- no
    // contribution to either cache.
    Super.ServerComputePassiveBonuses();

    // Now compute the 256+ contributions to our DK cache.
    DK_ServerComputePassiveBonuses_256Plus();
}

simulated function ClientAndServerComputePassiveBonuses()
{
    Super.ClientAndServerComputePassiveBonuses();
    DK_ClientAndServerComputePassiveBonuses_256Plus();
}

function DK_ServerComputePassiveBonuses_256Plus()
{
    local int i, idx;
    local ZTPlayerReplicationInfo DKPRI;
    local WMGameReplicationInfo WMGRI;

    DKPRI = GetDKPRI();
    if (DKPRI == None)
        return;

    WMGRI = WMGameReplicationInfo(WorldInfo.GRI);
    if (WMGRI == None)
        return;

    // Iterate paged perks (idx >= 256). DKPRI inherits Purchase_PerkUpgrade
    // from WMPRI; same array, full range of perks.
    for (i = 0; i < DKPRI.Purchase_PerkUpgrade.Length; ++i)
    {
        idx = DKPRI.Purchase_PerkUpgrade[i];
        if (idx < 256)
            continue;
        if (idx >= WMGRI.PerkUpgradesList.Length)
            continue;
        if (WMGRI.PerkUpgradesList[idx].PerkUpgrade == None)
            continue;

        WMGRI.PerkUpgradesList[idx].PerkUpgrade.static.ModifyDamageGivenPassive(DKPassiveDamageGiven_256Plus, DKPRI.GetPerkLevel(idx));
        WMGRI.PerkUpgradesList[idx].PerkUpgrade.static.ModifyDamageTakenPassive(DKPassiveDamageTaken_256Plus, DKPRI.GetPerkLevel(idx));
        WMGRI.PerkUpgradesList[idx].PerkUpgrade.static.ModifyHealAmountPassive(DKPassiveHealAmount_256Plus, DKPRI.GetPerkLevel(idx));
        WMGRI.PerkUpgradesList[idx].PerkUpgrade.static.ModifyHardAttackDamagePassive(DKPassiveHardAttackDamage_256Plus, DKPRI.GetPerkLevel(idx));
        WMGRI.PerkUpgradesList[idx].PerkUpgrade.static.ModifyStunPowerPassive(DKPassiveStunPower_256Plus, DKPRI.GetPerkLevel(idx));
        WMGRI.PerkUpgradesList[idx].PerkUpgrade.static.ModifyStumblePowerPassive(DKPassiveStumblePower_256Plus, DKPRI.GetPerkLevel(idx));
        WMGRI.PerkUpgradesList[idx].PerkUpgrade.static.ModifyKnockdownPowerPassive(DKPassiveKnockdownPower_256Plus, DKPRI.GetPerkLevel(idx));
        WMGRI.PerkUpgradesList[idx].PerkUpgrade.static.ModifySnarePowerPassive(DKPassiveSnarePower_256Plus, DKPRI.GetPerkLevel(idx));
    }
}

simulated function DK_ClientAndServerComputePassiveBonuses_256Plus()
{
    local int i, idx;
    local ZTPlayerReplicationInfo DKPRI;
    local WMGameReplicationInfo WMGRI;

    DKPRI = GetDKPRISimulated();
    if (DKPRI == None)
        return;

    WMGRI = WMGameReplicationInfo(WorldInfo.GRI);
    if (WMGRI == None)
        return;

    for (i = 0; i < DKPRI.Purchase_PerkUpgrade.Length; ++i)
    {
        idx = DKPRI.Purchase_PerkUpgrade[i];
        if (idx < 256)
            continue;
        if (idx >= WMGRI.PerkUpgradesList.Length)
            continue;
        if (WMGRI.PerkUpgradesList[idx].PerkUpgrade == None)
            continue;

        WMGRI.PerkUpgradesList[idx].PerkUpgrade.static.ModifySpeedPassive(DKPassiveMovementSpeed_256Plus, DKPRI.GetPerkLevel(idx));
        WMGRI.PerkUpgradesList[idx].PerkUpgrade.static.ModifyWeaponSwitchTimePassive(DKPassiveSwitchSpeed_256Plus, DKPRI.GetPerkLevel(idx));
        WMGRI.PerkUpgradesList[idx].PerkUpgrade.static.ModifyMeleeAttackSpeedPassive(DKPassiveMeleeAttackSpeed_256Plus, DKPRI.GetPerkLevel(idx));
        WMGRI.PerkUpgradesList[idx].PerkUpgrade.static.GetReloadRateScalePassive(DKPassiveReloadRateScale_256Plus, DKPRI.GetPerkLevel(idx));
        WMGRI.PerkUpgradesList[idx].PerkUpgrade.static.ModifyRecoilPassive(DKPassiveRecoil_256Plus, DKPRI.GetPerkLevel(idx));
        WMGRI.PerkUpgradesList[idx].PerkUpgrade.static.ModifySpreadPassive(DKPassiveSpread_256Plus, DKPRI.GetPerkLevel(idx));
        WMGRI.PerkUpgradesList[idx].PerkUpgrade.static.ModifyWeaponBopDampingPassive(DKPassiveBobDamp_256Plus, DKPRI.GetPerkLevel(idx));
        WMGRI.PerkUpgradesList[idx].PerkUpgrade.static.ModifyMagSizeAndNumberPassive(DKPassiveMagazineCapacity_256Plus, DKPRI.GetPerkLevel(idx));
        WMGRI.PerkUpgradesList[idx].PerkUpgrade.static.ModifySpareAmmoAmountPassive(DKPassiveSpareAmmo_256Plus, DKPRI.GetPerkLevel(idx));
        WMGRI.PerkUpgradesList[idx].PerkUpgrade.static.ModifyRateOfFirePassive(DKPassiveRateOfFire_256Plus, DKPRI.GetPerkLevel(idx));
        WMGRI.PerkUpgradesList[idx].PerkUpgrade.static.ModifyTightChokePassive(DKPassiveTightChoke_256Plus, DKPRI.GetPerkLevel(idx));
        WMGRI.PerkUpgradesList[idx].PerkUpgrade.static.ModifyPenetrationPassive(DKPassivePenetration_256Plus, DKPRI.GetPerkLevel(idx));
    }
}

// ===================================================================
// HEALTH & ARMOR
// ===================================================================

// ===================================================================
// PLAYERCAPS ENFORCEMENT HELPERS
// Applied at the END of each stat hook (after Super + paged perks +
// roguelike + helpers) so caps win over every bonus source. Each helper
// is a no-op when caps are globally disabled or the specific cap is 0.
// See ZTConfig_PlayerCaps.
// ===================================================================

// Absolute upper bound on an int stat.
final function DKCapAbsInt(out int Val, int CapVal)
{
    if (CapVal > 0 && Val > CapVal && class'ZTConfig_PlayerCaps'.static.IsEnabled())
        Val = CapVal;
}

// Absolute upper bound on a float stat.
final function DKCapAbsFloat(out float Val, float CapVal)
{
    if (CapVal > 0.0 && Val > CapVal && class'ZTConfig_PlayerCaps'.static.IsEnabled())
        Val = CapVal;
}

// Absolute lower bound on an int stat (floor - guarantees "no less than X").
final function DKCapMinAbsInt(out int Val, int MinVal)
{
    if (MinVal > 0 && Val < MinVal && class'ZTConfig_PlayerCaps'.static.IsEnabled())
        Val = MinVal;
}

// Absolute lower bound on an int stat, never raised above the stat's own base.
// Guarantees "no less than X" for normal cases without inflating values whose
// base is already below X (e.g. single-shot launcher magazines).
final function DKCapMinAbsIntToBase(out int Val, int MinVal, int InBase)
{
    local int FloorVal;

    if (MinVal > 0 && InBase > 0 && class'ZTConfig_PlayerCaps'.static.IsEnabled())
    {
        FloorVal = Min(MinVal, InBase);
        if (Val < FloorVal)
            Val = FloorVal;
    }
}

// Upper bound expressed as a multiple of a base value (higher-is-better stats).
final function DKCapMaxMultInt(out int Val, int InBase, float MaxMult)
{
    local int Lim;

    if (MaxMult > 0.0 && InBase > 0 && class'ZTConfig_PlayerCaps'.static.IsEnabled())
    {
        Lim = Round(float(InBase) * MaxMult);
        if (Val > Lim)
            Val = Lim;
    }
}

// Upper bound expressed as a multiple of a base value (higher-is-better, float).
final function DKCapMaxMultFloat(out float Val, float InBase, float MaxMult)
{
    if (MaxMult > 0.0 && InBase > 0.0 && Val > InBase * MaxMult
        && class'ZTConfig_PlayerCaps'.static.IsEnabled())
        Val = InBase * MaxMult;
}

// Lower bound expressed as a fraction of a base value (lower-is-better stats:
// reload scale, fire interval, switch time, recoil, spread, melee duration).
final function DKCapMinScaleFloat(out float Val, float InBase, float MinScale)
{
    if (MinScale > 0.0 && InBase > 0.0 && Val < InBase * MinScale
        && class'ZTConfig_PlayerCaps'.static.IsEnabled())
        Val = InBase * MinScale;
}

// Lower bound expressed as a fraction of a base value (lower-is-better int:
// incoming-damage floor).
final function DKCapMinScaleInt(out int Val, int InBase, float MinScale)
{
    local int Lim;

    if (MinScale > 0.0 && InBase > 0 && class'ZTConfig_PlayerCaps'.static.IsEnabled())
    {
        Lim = Round(float(InBase) * MinScale);
        if (Val < Lim)
            Val = Lim;
    }
}

function ModifyHealth(out int InHealth)
{
    local ZTPlayerReplicationInfo DKPRI;
    local WMGameReplicationInfo WMGRI;
    local int OrigInHealth;
    local int RoguelikeBonus;
    local float HealthPenaltyPct;
    local int PenaltyAmount;
    local int i, idx;
    local ZTUpgrade_Skill_MementoMori_Helper MMHelper;

    OrigInHealth = InHealth;  // captured pre-super; note super OVERWRITES InHealth = StartingMaxHealth(Difficulty)

    // Let parent apply all <256 perk/skill/equipment modifiers + special waves
    Super.ModifyHealth(InHealth);

    // === PAGED PERK DISPATCH (idx >= 256) ===
    // Note: parent overwrites InHealth at start, so OrigInHealth is the
    // caller's input (typically 0 or stale) -- not super's DefaultHealth.
    // Paged perks doing "+10% of default" will use OrigInHealth which is
    // wrong here. Paged ModifyHealth perks should use level + constants
    // (e.g., "+5 HP per level") instead of relying on DefaultValue.
    DKPRI = GetDKPRI();
    if (DKPRI != None)
    {
        WMGRI = WMGameReplicationInfo(WorldInfo.GRI);
        if (WMGRI != None)
        {
            for (i = 0; i < DKPRI.Purchase_PerkUpgrade.Length; ++i)
            {
                idx = DKPRI.Purchase_PerkUpgrade[i];
                if (idx < 256) continue;
                if (idx >= WMGRI.PerkUpgradesList.Length) continue;
                if (WMGRI.PerkUpgradesList[idx].PerkUpgrade == None) continue;

                WMGRI.PerkUpgradesList[idx].PerkUpgrade.static.ModifyHealth(InHealth, OrigInHealth, DKPRI.GetPerkLevel(idx));
            }
        }
    }

    // === ROGUELIKE STATS ===
    if (DKPRI != None)
    {
        // Flat health bonus
        RoguelikeBonus = DKPRI.GetRoguelikeHealthBonus();
        if (RoguelikeBonus > 0)
        {
            InHealth += RoguelikeBonus;
            `log("[DK_ROGUELIKE_PERK] ModifyHealth: Added " $ RoguelikeBonus $ " roguelike HP");
        }

        // Glass Cannon health penalty (applied to BASE health, not modified)
        HealthPenaltyPct = DKPRI.GetRoguelikeHealthPenaltyPct();
        if (HealthPenaltyPct > 0)
        {
            // Calculate penalty based on base 100 HP
            PenaltyAmount = Round(100.0 * HealthPenaltyPct);
            InHealth = Max(InHealth - PenaltyAmount, 1); // Minimum 1 HP
            `log("[DK_ROGUELIKE_PERK] ModifyHealth: Glass Cannon penalty -" $ PenaltyAmount $ " HP, total=" $ InHealth);
        }
    }

    // === MEMENTO MORI: permanent per-wave max health stack (per-life) ===
    // The stack lives on the pawn-owned helper, so it survives the
    // base-recompute that Super performs (InHealth = StartingMaxHealth +
    // upgrades) and dies naturally with the pawn.
    if (OwnerPawn != None)
    {
        foreach OwnerPawn.ChildActors(class'ZTUpgrade_Skill_MementoMori_Helper', MMHelper)
        {
            if (MMHelper.PermanentHealthBonus > 0)
                InHealth += MMHelper.PermanentHealthBonus;
            break;
        }
    }

    // === PLAYERCAPS: absolute max health (highest priority) ===
    DKCapAbsInt(InHealth, class'ZTConfig_PlayerCaps'.static.GetCapMaxHealth());

    // === PLAYERCAPS: absolute min health floor (applied after the max) ===
    DKCapMinAbsInt(InHealth, class'ZTConfig_PlayerCaps'.static.GetCapMinHealth());
}

function ModifyArmorInt(out int MaxArmor)
{
    local ZTPlayerReplicationInfo DKPRI;
    local WMGameReplicationInfo WMGRI;
    local int OrigMaxArmor;
    local int RoguelikeBonus;
    local int i, idx;

    OrigMaxArmor = MaxArmor;  // pre-super; super OVERWRITES MaxArmor = StartingMaxArmor(Difficulty)

    // Let parent apply all perk/skill/equipment modifiers first
    Super.ModifyArmorInt(MaxArmor);

    // === PAGED PERK DISPATCH (idx >= 256) ===
    // Same DefaultValue-drift caveat as ModifyHealth.
    // Note: parent dispatches to static .ModifyArmor (not .ModifyArmorInt).
    DKPRI = GetDKPRI();
    if (DKPRI != None)
    {
        WMGRI = WMGameReplicationInfo(WorldInfo.GRI);
        if (WMGRI != None)
        {
            for (i = 0; i < DKPRI.Purchase_PerkUpgrade.Length; ++i)
            {
                idx = DKPRI.Purchase_PerkUpgrade[i];
                if (idx < 256) continue;
                if (idx >= WMGRI.PerkUpgradesList.Length) continue;
                if (WMGRI.PerkUpgradesList[idx].PerkUpgrade == None) continue;

                WMGRI.PerkUpgradesList[idx].PerkUpgrade.static.ModifyArmor(MaxArmor, OrigMaxArmor, DKPRI.GetPerkLevel(idx));
            }
        }
    }

    // === ROGUELIKE STATS ===
    if (DKPRI != None)
    {
        RoguelikeBonus = DKPRI.GetRoguelikeArmorBonus();
        if (RoguelikeBonus > 0)
        {
            MaxArmor += RoguelikeBonus;
            `log("[DK_ROGUELIKE_PERK] ModifyArmorInt: Added " $ RoguelikeBonus $ " roguelike armor, total=" $ MaxArmor);
        }
    }

    // === PLAYERCAPS: absolute max armor (highest priority) ===
    DKCapAbsInt(MaxArmor, class'ZTConfig_PlayerCaps'.static.GetCapMaxArmor());

    // === PLAYERCAPS: absolute min armor floor (applied after the max) ===
    DKCapMinAbsInt(MaxArmor, class'ZTConfig_PlayerCaps'.static.GetCapMinArmor());
}

// ===================================================================
// DAMAGE GIVEN - Roguelike damage multipliers + Perk Unique Helpers
// + paged perk dispatch (Phase 3b)
// ===================================================================

function ModifyDamageGiven(out int InDamage, optional Actor DamageCauser, optional KFPawn_Monster MyKFPM, optional KFPlayerController DamageInstigator, optional class<KFDamageType> DamageType, optional int HitZoneIdx)
{
    local ZTPlayerReplicationInfo DKPRI;
    local WMGameReplicationInfo WMGRI;
    local int OrigInDamage;
    local float BonusMult;
    local int BaseDamage;
    local float RoguelikeDamage;
    local float RoguelikeLargeZed;
    local float RoguelikeOpportunist;
    local float RoguelikeDuelist;
    local float RoguelikeLastRound;
    local KFWeapon KFW;
    local KFWeapon MyKFW;
    local bool bIsLastRound;
    local bool bIsFromBehind;
    local bool bIsIsolated;
    local ZTRoguelikeHelper RLHelper;
    local ZTHauntedTerrifyMarker HauntedMarker;
    local int i, idx;
    local float EffDmgCap, LargeCap, HeadCap;

    OrigInDamage = InDamage;  // pre-super; matches caller's input (drifts vs super's recaptured DefaultDamage post-custom-balance)

    // Call parent first - this applies all WM upgrades, skills, etc.
    Super.ModifyDamageGiven(InDamage, DamageCauser, MyKFPM, DamageInstigator, DamageType, HitZoneIdx);

    // === PAGED PERK DISPATCH (idx >= 256) ===
    DKPRI = GetDKPRI();
    if (DKPRI != None)
    {
        WMGRI = WMGameReplicationInfo(WorldInfo.GRI);
        if (WMGRI != None)
        {
            // Compute MyKFW like parent (without GetWeaponFromDamageType
            // which uses parent's private cache vars).
            if (DamageCauser != None)
            {
                if (DamageCauser.IsA('Weapon'))
                    MyKFW = KFWeapon(DamageCauser);
                else if (DamageCauser.IsA('Projectile'))
                    MyKFW = KFWeapon(DamageCauser.Owner);
                else if (DamageCauser.IsA('KFSprayActor'))
                    MyKFW = GetOwnerWeapon();
            }

            // Apply DK paged passive
            if (DKPassiveDamageGiven_256Plus != 1.0f)
                InDamage = Round(float(InDamage) * DKPassiveDamageGiven_256Plus);

            for (i = 0; i < DKPRI.Purchase_PerkUpgrade.Length; ++i)
            {
                idx = DKPRI.Purchase_PerkUpgrade[i];
                if (idx < 256) continue;
                if (idx >= WMGRI.PerkUpgradesList.Length) continue;
                if (WMGRI.PerkUpgradesList[idx].PerkUpgrade == None) continue;

                WMGRI.PerkUpgradesList[idx].PerkUpgrade.static.ModifyDamageGiven(InDamage, OrigInDamage, DKPRI.GetPerkLevel(idx), DamageCauser, MyKFPM, DamageInstigator, DamageType, HitZoneIdx, MyKFW);
            }

            if (InDamage < 0) InDamage = 0;
        }
    }

    // Store base damage after perk modifiers (now includes paged contributions)
    BaseDamage = InDamage;
    BonusMult = 0.0;

    // The Watcher's Gift is a target debuff, so every attacker receives the
    // advertised bonus while the shared marker is active.
    if (MyKFPM != None)
    {
        foreach MyKFPM.ChildActors(class'ZTHauntedTerrifyMarker', HauntedMarker)
        {
            BonusMult += class'ZTRoguelikeHelper_HAUNTED'.const.TERRIFY_BONUS;
            break;
        }
    }

    // =============================================================
    // ROGUELIKE DAMAGE STATS
    // =============================================================
    if (DKPRI != None)
    {
        // General damage multiplier (includes Glass Cannon bonus)
        RoguelikeDamage = DKPRI.GetRoguelikeDamageMult();
        if (RoguelikeDamage > 0)
        {
            BonusMult += RoguelikeDamage;
        }

        // Large zed damage
        if (MyKFPM != None && MyKFPM.IsLargeZed())
        {
            RoguelikeLargeZed = DKPRI.GetRoguelikeLargeZedDamage();
            if (RoguelikeLargeZed > 0)
            {
                BonusMult += RoguelikeLargeZed;
            }
        }

        // Opportunist - bonus damage from behind
        RoguelikeOpportunist = DKPRI.GetRoguelikeOpportunistDamage();
        if (RoguelikeOpportunist > 0 && MyKFPM != None && OwnerPawn != None)
        {
            bIsFromBehind = IsAttackingFromBehind(OwnerPawn, MyKFPM);
            if (bIsFromBehind)
            {
                BonusMult += RoguelikeOpportunist;
            }
        }

        // Duelist - bonus damage vs isolated targets
        RoguelikeDuelist = DKPRI.GetRoguelikeDuelistDamage();
        if (RoguelikeDuelist > 0 && MyKFPM != None)
        {
            bIsIsolated = IsTargetIsolated(MyKFPM);
            if (bIsIsolated)
            {
                BonusMult += RoguelikeDuelist;
            }
        }

        // Last Round - bonus damage on final bullet in magazine
        RoguelikeLastRound = DKPRI.GetRoguelikeLastRoundDamage();
        if (RoguelikeLastRound > 0 && DamageCauser != None)
        {
            KFW = KFWeapon(DamageCauser);
            if (KFW == None && DamageCauser.Instigator != None)
            {
                KFW = KFWeapon(DamageCauser.Instigator.Weapon);
            }

            if (KFW != None)
            {
                bIsLastRound = (KFW.AmmoCount[0] == 0 && KFW.MagazineCapacity[0] > 1);
                if (bIsLastRound)
                {
                    BonusMult += RoguelikeLastRound;
                }
            }
        }
    }

    // =============================================================
    // PERK UNIQUE HELPER DAMAGE BONUSES
    // =============================================================
    if (OwnerPawn != None)
    {
        foreach OwnerPawn.ChildActors(class'ZTRoguelikeHelper', RLHelper)
        {
            BonusMult += RLHelper.GetDamageMultiplier(MyKFPM, DamageType, HitZoneIdx, DamageCauser);
        }
    }

    // =============================================================
    // APPLY TOTAL BONUS
    // =============================================================
    if (BonusMult > 0)
    {
        InDamage = Round(float(BaseDamage) * (1.0 + BonusMult));
    }

    // Ensure damage doesn't go negative
    if (InDamage < 0)
        InDamage = 0;

    // === PLAYERCAPS: clamp final damage to a multiple of base weapon damage ===
    // Highest priority - after every bonus. Large-zed and headshot caps (when
    // set) take the LOWER effective multiplier for those hit contexts. Runs
    // before the kill check so the cap affects lethality.
    if (OrigInDamage > 0 && class'ZTConfig_PlayerCaps'.static.IsEnabled())
    {
        EffDmgCap = class'ZTConfig_PlayerCaps'.static.GetCapDamageGivenMultiplier();

        if (MyKFPM != None && MyKFPM.IsLargeZed())
        {
            LargeCap = class'ZTConfig_PlayerCaps'.static.GetCapDamageToLargeMultiplier();
            if (LargeCap > 0.0 && (EffDmgCap <= 0.0 || LargeCap < EffDmgCap))
                EffDmgCap = LargeCap;
        }

        if (MyKFPM != None && HitZoneIdx >= 0 && HitZoneIdx < MyKFPM.HitZones.Length
            && MyKFPM.HitZones[HitZoneIdx].ZoneName == 'head')
        {
            HeadCap = class'ZTConfig_PlayerCaps'.static.GetCapHeadshotDamageMultiplier();
            if (HeadCap > 0.0 && (EffDmgCap <= 0.0 || HeadCap < EffDmgCap))
                EffDmgCap = HeadCap;
        }

        DKCapMaxMultInt(InDamage, OrigInDamage, EffDmgCap);
    }

    // =============================================================
    // NOTIFY PERK UNIQUE HELPERS OF KILLS
    // =============================================================
    if (OwnerPawn != None && MyKFPM != None && MyKFPM.IsAliveAndWell() && (MyKFPM.Health - InDamage) <= 0)
    {
        foreach OwnerPawn.ChildActors(class'ZTRoguelikeHelper', RLHelper)
        {
            RLHelper.OnZedKilled(MyKFPM, HitZoneIdx, DamageInstigator);
        }
    }
}

// ===================================================================
// CONDITIONAL DAMAGE HELPERS
// ===================================================================

/** Check if player is attacking from behind the target */
function bool IsAttackingFromBehind(Pawn Attacker, KFPawn_Monster Target)
{
    local vector ToAttacker;
    local vector TargetForward;
    local float DotProduct;

    if (Attacker == None || Target == None)
        return false;

    ToAttacker = Normal(Attacker.Location - Target.Location);
    TargetForward = vector(Target.Rotation);
    DotProduct = ToAttacker dot TargetForward;

    return (DotProduct < OPPORTUNIST_DOT_THRESHOLD);
}

/** Check if target is isolated (only 1 enemy within range) */
function bool IsTargetIsolated(KFPawn_Monster Target)
{
    local KFPawn_Monster KFPM;
    local int NearbyCount;

    if (Target == None)
        return false;

    NearbyCount = 0;

    foreach WorldInfo.AllPawns(class'KFPawn_Monster', KFPM)
    {
        if (KFPM != Target && KFPM.IsAliveAndWell())
        {
            if (VSize(KFPM.Location - Target.Location) <= DUELIST_RANGE)
            {
                NearbyCount++;
                if (NearbyCount > 0)
                    return false;
            }
        }
    }

    return true;
}

// ===================================================================
// RELOAD SPEED (ROGUELIKE) + paged perk dispatch
// ===================================================================

simulated function float GetReloadRateScale(KFWeapon KFW)
{
    local float Result;
    local ZTPlayerReplicationInfo DKPRI;
    local WMGameReplicationInfo WMGRI;
    local float RoguelikeReload;
    local int i, idx;

    // Note: parent's static GetReloadRateScale signature is (out float Scale,
    // byte level, KFWeapon KFW, KFPawn_Human OwnerPawn) -- no DefaultValue arg,
    // so we don't capture an OrigInRate.

    Result = Super.GetReloadRateScale(KFW);

    // === PAGED PERK DISPATCH (idx >= 256) ===
    DKPRI = GetDKPRISimulated();
    if (DKPRI != None)
    {
        WMGRI = WMGameReplicationInfo(WorldInfo.GRI);
        if (WMGRI != None)
        {
            // Apply DK paged passive
            if (DKPassiveReloadRateScale_256Plus != 1.0f)
                Result *= DKPassiveReloadRateScale_256Plus;

            for (i = 0; i < DKPRI.Purchase_PerkUpgrade.Length; ++i)
            {
                idx = DKPRI.Purchase_PerkUpgrade[i];
                if (idx < 256) continue;
                if (idx >= WMGRI.PerkUpgradesList.Length) continue;
                if (WMGRI.PerkUpgradesList[idx].PerkUpgrade == None) continue;

                WMGRI.PerkUpgradesList[idx].PerkUpgrade.static.GetReloadRateScale(Result, DKPRI.GetPerkLevel(idx), KFW, OwnerPawn);
            }
        }
    }

    // === ROGUELIKE STATS ===
    if (DKPRI != None)
    {
        RoguelikeReload = DKPRI.GetRoguelikeReloadMult();
        if (RoguelikeReload > 0)
        {
            Result *= (1.0 - RoguelikeReload);
        }
    }

    // === PLAYERCAPS: reload-rate floor (caps how fast reloads can get) ===
    DKCapMinScaleFloat(Result, 1.0, class'ZTConfig_PlayerCaps'.static.GetCapReloadRateMinScale());

    if (Result <= 0.05f)
        return 0.05f;

    return Result;
}

// ===================================================================
// SPARE AMMO (ROGUELIKE) + paged perk dispatch
// ===================================================================

simulated function ModifySpareAmmoAmount(KFWeapon KFW, out int PrimarySpareAmmo, optional const out STraderItem TraderItem, optional bool bSecondary = False)
{
    local ZTPlayerReplicationInfo DKPRI;
    local WMGameReplicationInfo WMGRI;
    local int OrigPrimarySpareAmmo;
    local int BaseSpareAmmo;
    local float RoguelikeAmmo;
    local int i, idx;

    OrigPrimarySpareAmmo = PrimarySpareAmmo;  // pre-super; matches parent's DefaultSpareAmmo
    BaseSpareAmmo = PrimarySpareAmmo;
    Super.ModifySpareAmmoAmount(KFW, PrimarySpareAmmo, TraderItem, bSecondary);

    // === PAGED PERK DISPATCH (idx >= 256) ===
    if (KFW != None && OrigPrimarySpareAmmo > 0)
    {
        DKPRI = GetDKPRISimulated();
        if (DKPRI != None)
        {
            WMGRI = WMGameReplicationInfo(WorldInfo.GRI);
            if (WMGRI != None)
            {
                if (DKPassiveSpareAmmo_256Plus != 1.0f)
                    PrimarySpareAmmo = Round(float(PrimarySpareAmmo) * DKPassiveSpareAmmo_256Plus);

                for (i = 0; i < DKPRI.Purchase_PerkUpgrade.Length; ++i)
                {
                    idx = DKPRI.Purchase_PerkUpgrade[i];
                    if (idx < 256) continue;
                    if (idx >= WMGRI.PerkUpgradesList.Length) continue;
                    if (WMGRI.PerkUpgradesList[idx].PerkUpgrade == None) continue;

                    WMGRI.PerkUpgradesList[idx].PerkUpgrade.static.ModifySpareAmmoAmount(PrimarySpareAmmo, OrigPrimarySpareAmmo, DKPRI.GetPerkLevel(idx), KFW, TraderItem, bSecondary);
                }

                if (!bSecondary) PrimarySpareAmmo = Clamp(PrimarySpareAmmo, 0, MaxInt);
                else PrimarySpareAmmo = Clamp(PrimarySpareAmmo, 0, 255);
            }
        }
    }

    // === ROGUELIKE STATS ===
    DKPRI = GetDKPRISimulated();
    if (DKPRI != None && BaseSpareAmmo > 0)
    {
        RoguelikeAmmo = DKPRI.GetRoguelikeAmmoMult();
        if (RoguelikeAmmo > 0)
        {
            PrimarySpareAmmo += Round(float(BaseSpareAmmo) * RoguelikeAmmo);
        }
    }

    // === PLAYERCAPS: max spare ammo as a multiple of base (also covers the
    // cap path, since ModifyMaxSpareAmmoAmount routes through here) ===
    DKCapMaxMultInt(PrimarySpareAmmo, BaseSpareAmmo, class'ZTConfig_PlayerCaps'.static.GetCapSpareAmmoMultiplier());
}

simulated function ModifyMaxSpareAmmoAmount(KFWeapon KFW, out int MaxSpareAmmo, optional const out STraderItem TraderItem, optional bool bSecondary = False)
{
    // WMPerk.ModifyMaxSpareAmmoAmount calls ModifySpareAmmoAmount via virtual
    // dispatch, and our ModifySpareAmmoAmount override already adds the
    // roguelike ammo bonus (and runs the paged perk dispatch). Adding the
    // roguelike bonus again here would double-count it on the spare-ammo CAP,
    // so we only chain to Super.
    Super.ModifyMaxSpareAmmoAmount(KFW, MaxSpareAmmo, TraderItem, bSecondary);
}

// ===================================================================
// MOVEMENT SPEED (ROGUELIKE) + paged perk dispatch
// ===================================================================

simulated function ModifySpeed(out float Speed)
{
    local ZTPlayerReplicationInfo DKPRI;
    local WMGameReplicationInfo WMGRI;
    local float OrigSpeed;
    local float RoguelikeSpeed;
    local float SpeedPenalty;
    local float NetSpeedMod;
    local int i, idx;

    OrigSpeed = Speed;  // pre-super; matches parent's DefaultSpeed

    Super.ModifySpeed(Speed);

    // === PAGED PERK DISPATCH (idx >= 256) ===
    DKPRI = GetDKPRISimulated();
    if (DKPRI != None)
    {
        WMGRI = WMGameReplicationInfo(WorldInfo.GRI);
        if (WMGRI != None)
        {
            if (DKPassiveMovementSpeed_256Plus != 1.0f)
                Speed *= DKPassiveMovementSpeed_256Plus;

            for (i = 0; i < DKPRI.Purchase_PerkUpgrade.Length; ++i)
            {
                idx = DKPRI.Purchase_PerkUpgrade[i];
                if (idx < 256) continue;
                if (idx >= WMGRI.PerkUpgradesList.Length) continue;
                if (WMGRI.PerkUpgradesList[idx].PerkUpgrade == None) continue;

                WMGRI.PerkUpgradesList[idx].PerkUpgrade.static.ModifySpeed(Speed, OrigSpeed, DKPRI.GetPerkLevel(idx), OwnerPawn);
            }
        }
    }

    // === ROGUELIKE STATS ===
    if (DKPRI != None)
    {
        RoguelikeSpeed = DKPRI.GetRoguelikeSpeedMult();
        SpeedPenalty = DKPRI.GetRoguelikeSpeedPenaltyPct();

        NetSpeedMod = RoguelikeSpeed - SpeedPenalty;

        if (NetSpeedMod != 0)
        {
            Speed *= (1.0 + NetSpeedMod);

            if (Speed <= 0.1)
                Speed = 0.1;
        }
    }

    // === PLAYERCAPS: max movement speed as a multiple of base ===
    DKCapMaxMultFloat(Speed, OrigSpeed, class'ZTConfig_PlayerCaps'.static.GetCapSpeedMultiplier());
}

// ===================================================================
// WEAPON HANDLING TIMERS (FLOOR CLAMPS) + paged perk dispatch
// Hardens engine-level limits at extreme upgrade stacks. Mirrors the
// existing Reload (0.05f) and Speed (0.1) floors elsewhere in this
// class. WMPerk has no floor on switch time and only degenerate floors
// on RoF/melee, so DK adds proper guards. If we ever introduce
// roguelike multipliers for these stats, they go in here above the
// floor check, mirroring the GetReloadRateScale pattern.
// ===================================================================

simulated function ModifyRateOfFire(out float InRate, KFWeapon KFW)
{
    local ZTPlayerReplicationInfo DKPRI;
    local WMGameReplicationInfo WMGRI;
    local float OrigInRate;
    local int i, idx;

    OrigInRate = InRate;  // pre-super; matches parent's DefaultRate

    Super.ModifyRateOfFire(InRate, KFW);

    // === PAGED PERK DISPATCH (idx >= 256) ===
    DKPRI = GetDKPRISimulated();
    if (DKPRI != None)
    {
        WMGRI = WMGameReplicationInfo(WorldInfo.GRI);
        if (WMGRI != None)
        {
            // Mirror parent's flame-base passive skip
            if (DKPassiveRateOfFire_256Plus != 1.0f && KFWeap_FlameBase(KFW) == None)
                InRate *= DKPassiveRateOfFire_256Plus;

            for (i = 0; i < DKPRI.Purchase_PerkUpgrade.Length; ++i)
            {
                idx = DKPRI.Purchase_PerkUpgrade[i];
                if (idx < 256) continue;
                if (idx >= WMGRI.PerkUpgradesList.Length) continue;
                if (WMGRI.PerkUpgradesList[idx].PerkUpgrade == None) continue;

                WMGRI.PerkUpgradesList[idx].PerkUpgrade.static.ModifyRateOfFire(InRate, OrigInRate, DKPRI.GetPerkLevel(idx), KFW);
            }
        }
    }

    // 0.05f = 20x max fire rate. WMPerk's own floor is 0.005f (200x)
    // which is too lenient and lets weapons fire faster than the engine
    // can replicate cleanly.
    // === PLAYERCAPS: rate-of-fire floor (caps how fast firing can get) ===
    DKCapMinScaleFloat(InRate, OrigInRate, class'ZTConfig_PlayerCaps'.static.GetCapRateOfFireMinScale());

    if (InRate < 0.05f)
        InRate = 0.05f;
}

simulated function ModifyMeleeAttackSpeed(out float InDuration, KFWeapon KFW)
{
    local ZTPlayerReplicationInfo DKPRI;
    local WMGameReplicationInfo WMGRI;
    local float OrigInDuration;
    local int i, idx;

    OrigInDuration = InDuration;  // pre-super; matches parent's DefaultDuration

    Super.ModifyMeleeAttackSpeed(InDuration, KFW);

    // === PAGED PERK DISPATCH (idx >= 256) ===
    DKPRI = GetDKPRISimulated();
    if (DKPRI != None)
    {
        WMGRI = WMGameReplicationInfo(WorldInfo.GRI);
        if (WMGRI != None)
        {
            if (DKPassiveMeleeAttackSpeed_256Plus != 1.0f)
                InDuration *= DKPassiveMeleeAttackSpeed_256Plus;

            for (i = 0; i < DKPRI.Purchase_PerkUpgrade.Length; ++i)
            {
                idx = DKPRI.Purchase_PerkUpgrade[i];
                if (idx < 256) continue;
                if (idx >= WMGRI.PerkUpgradesList.Length) continue;
                if (WMGRI.PerkUpgradesList[idx].PerkUpgrade == None) continue;

                WMGRI.PerkUpgradesList[idx].PerkUpgrade.static.ModifyMeleeAttackSpeed(InDuration, OrigInDuration, DKPRI.GetPerkLevel(idx), KFW);
            }
        }
    }

    // 0.1f = 10x max melee speed. Melee animations need more headroom
    // than ranged-fire to avoid sync issues with strike windows.
    // WMPerk only catches duration <= 0, not tiny-positive values.
    // === PLAYERCAPS: melee-duration floor (caps how fast melee can get) ===
    DKCapMinScaleFloat(InDuration, OrigInDuration, class'ZTConfig_PlayerCaps'.static.GetCapMeleeAttackSpeedMinDuration());

    if (InDuration < 0.1f)
        InDuration = 0.1f;
}

simulated function ModifyWeaponSwitchTime(out float ModifiedSwitchTime)
{
    local ZTPlayerReplicationInfo DKPRI;
    local WMGameReplicationInfo WMGRI;
    local float OrigSwitchTime;
    local KFWeapon KFW;
    local KFInventoryManager KFIM;
    local int i, idx;

    OrigSwitchTime = ModifiedSwitchTime;  // pre-super; matches parent's DefaultSwitchTime

    Super.ModifyWeaponSwitchTime(ModifiedSwitchTime);

    // === PAGED PERK DISPATCH (idx >= 256) ===
    DKPRI = GetDKPRISimulated();
    if (DKPRI != None)
    {
        WMGRI = WMGameReplicationInfo(WorldInfo.GRI);
        if (WMGRI != None)
        {
            // Compute KFW like parent
            KFW = GetOwnerWeapon();
            if (KFW == None && CheckOwnerPawn())
            {
                KFIM = KFInventoryManager(OwnerPawn.InvManager);
                if (KFIM != None && KFIM.PendingWeapon != None)
                    KFW = KFWeapon(KFIM.PendingWeapon);
            }

            if (DKPassiveSwitchSpeed_256Plus != 1.0f)
                ModifiedSwitchTime *= DKPassiveSwitchSpeed_256Plus;

            for (i = 0; i < DKPRI.Purchase_PerkUpgrade.Length; ++i)
            {
                idx = DKPRI.Purchase_PerkUpgrade[i];
                if (idx < 256) continue;
                if (idx >= WMGRI.PerkUpgradesList.Length) continue;
                if (WMGRI.PerkUpgradesList[idx].PerkUpgrade == None) continue;

                WMGRI.PerkUpgradesList[idx].PerkUpgrade.static.ModifyWeaponSwitchTime(ModifiedSwitchTime, OrigSwitchTime, DKPRI.GetPerkLevel(idx), KFW);
            }
        }
    }

    // 0.05f = sub-100ms swaps still possible. WMPerk has no floor here
    // at all, so heavily-stacked switch-time bonuses can drive the timer
    // to 0 or negative.
    // === PLAYERCAPS: switch-time floor (caps how fast swaps can get) ===
    DKCapMinScaleFloat(ModifiedSwitchTime, OrigSwitchTime, class'ZTConfig_PlayerCaps'.static.GetCapWeaponSwitchMinScale());

    if (ModifiedSwitchTime < 0.05f)
        ModifiedSwitchTime = 0.05f;
}

// ===================================================================
// DAMAGE TAKEN (ROGUELIKE + Perk Unique Helpers) + paged perk dispatch
// ===================================================================

function ModifyDamageTaken(out int InDamage, optional class<DamageType> DamageType, optional Controller InstigatedBy)
{
    local ZTPlayerReplicationInfo DKPRI;
    local WMGameReplicationInfo WMGRI;
    local KFWeapon MyKFW;
    local KFInventoryManager KFIM;
    local int OrigInDamage;
    local float RoguelikeResist;
    local ZTRoguelikeHelper RLHelper;
    local int DefaultDamage;
    local ZTUpgrade_Perk_JekyllHyde_Helper HydeHelper;
    local float HydeMult;
    local int i, idx;

    OrigInDamage = InDamage;  // pre-super; matches caller's input (drifts vs super's recaptured DefaultDamage post-custom-balance)

    // Call parent first
    Super.ModifyDamageTaken(InDamage, DamageType, InstigatedBy);

    // === PAGED PERK DISPATCH (idx >= 256) ===
    DKPRI = GetDKPRI();
    if (DKPRI != None)
    {
        WMGRI = WMGameReplicationInfo(WorldInfo.GRI);
        if (WMGRI != None)
        {
            // Compute MyKFW like parent
            MyKFW = GetOwnerWeapon();
            if (MyKFW == None && CheckOwnerPawn())
            {
                KFIM = KFInventoryManager(OwnerPawn.InvManager);
                if (KFIM != None && KFIM.PendingWeapon != None)
                    MyKFW = KFWeapon(KFIM.PendingWeapon);
            }

            if (DKPassiveDamageTaken_256Plus != 1.0f)
                InDamage = Round(float(InDamage) * DKPassiveDamageTaken_256Plus);

            for (i = 0; i < DKPRI.Purchase_PerkUpgrade.Length; ++i)
            {
                idx = DKPRI.Purchase_PerkUpgrade[i];
                if (idx < 256) continue;
                if (idx >= WMGRI.PerkUpgradesList.Length) continue;
                if (WMGRI.PerkUpgradesList[idx].PerkUpgrade == None) continue;

                WMGRI.PerkUpgradesList[idx].PerkUpgrade.static.ModifyDamageTaken(InDamage, OrigInDamage, DKPRI.GetPerkLevel(idx), OwnerPawn, DamageType, InstigatedBy, MyKFW);
            }

            if (InDamage < 0) InDamage = 1;
        }
    }

    // === ROGUELIKE STATS ===
    if (InDamage > 0)
    {
        if (DKPRI != None)
        {
            RoguelikeResist = DKPRI.GetRoguelikeDamageResist();
            if (RoguelikeResist > 0)
            {
                InDamage = Round(float(InDamage) * (1.0 - RoguelikeResist));

                if (InDamage < 1)
                    InDamage = 1;
            }
        }

        // === PERK UNIQUE HELPER DAMAGE REDUCTION ===
        if (OwnerPawn != None)
        {
            DefaultDamage = InDamage;
            foreach OwnerPawn.ChildActors(class'ZTRoguelikeHelper', RLHelper)
            {
                RLHelper.ModifyIncomingDamage(InDamage, DefaultDamage, OwnerPawn, DamageType);
            }
        }
    }

    // === PLAYERCAPS: floor on incoming damage (caps max damage resistance) ===
    DKCapMinScaleInt(InDamage, OrigInDamage, class'ZTConfig_PlayerCaps'.static.GetCapDamageTakenMinScale());

    // === DR. JEKYLL & MR. HYDE: flat final reduction while transformed ===
    // Applied as the very last step so it is "10% less FINAL damage" -- after
    // every other resistance multiplier (vanilla/skill resists inside Super,
    // roguelike resist, perk-helper reductions) AND after the PlayerCaps
    // floor. Hyde is no longer damage-immune; this multiplicative cut is its
    // defensive layer. Guarded so an unseeded/invalid mult (e.g. 0.0) can
    // never grant accidental immunity -- it simply does nothing in that case.
    if (InDamage > 0 && OwnerPawn != None)
    {
        HydeMult = class'ZTUpgrade_Perk_JekyllHyde'.default.HydeFinalDamageTakenMult;
        if (HydeMult > 0.0f && HydeMult < 1.0f)
        {
            foreach OwnerPawn.ChildActors(class'ZTUpgrade_Perk_JekyllHyde_Helper', HydeHelper)
            {
                if (HydeHelper.bHyde)
                {
                    InDamage = Round(float(InDamage) * HydeMult);
                    if (InDamage < 1)
                        InDamage = 1;
                }
                break;
            }
        }
    }
}

// ===================================================================
// PHASE 3b BATCH 2 - REMAINING DISPATCH OVERRIDES
//
// All overrides below follow the same pattern: call super (which
// handles 0..255 perks correctly + harmless OOB no-ops for 256+),
// then iterate DKPRI.Purchase_PerkUpgrade for idx >= 256 and dispatch
// the static method with DKPRI.GetPerkLevel(idx).
//
// Notes:
//  - For modifier funcs: capture OrigX before super; pass as
//    DefaultValue to paged perks. Drift exists for funcs where super
//    overwrites or recaptures (documented per-func).
//  - For cached getter funcs (TightChoke / Penetration / Stun /
//    Stumble / Knockdown / Snare): parent caches via WMTimers, but
//    WMTimers is private. We don't cache paged contributions; they
//    re-fire each call. Acceptable CPU cost.
//  - For boolean-OR funcs: short-circuit on super=true, else iterate
//    paged. Side-effect setters (bExtraFireRange, bSplashActive,
//    bCanSeeCloakedZeds, bMovesFastInZedTime) replicated in our path.
//  - For ShouldSacrifice: parent's bUsedSacrifice guard is private;
//    paged sacrifice may fire after parent already used it. Edge case.
//  - For AddVampireHealth: super already issued HealDamage with its
//    contribution; we issue a SECOND HealDamage for paged contribution.
//    Two heal events instead of one combined.
// ===================================================================

// =================== MODIFIER FUNCTIONS (1/2) ===================

function ModifyHardAttackDamage(out int InDamage)
{
    local ZTPlayerReplicationInfo DKPRI;
    local WMGameReplicationInfo WMGRI;
    local int OrigInDamage;
    local int i, idx;

    OrigInDamage = InDamage;
    Super.ModifyHardAttackDamage(InDamage);

    DKPRI = GetDKPRI();
    if (DKPRI == None) return;
    WMGRI = WMGameReplicationInfo(WorldInfo.GRI);
    if (WMGRI == None) return;

    if (DKPassiveHardAttackDamage_256Plus != 1.0f)
        InDamage = Round(float(InDamage) * DKPassiveHardAttackDamage_256Plus);

    for (i = 0; i < DKPRI.Purchase_PerkUpgrade.Length; ++i)
    {
        idx = DKPRI.Purchase_PerkUpgrade[i];
        if (idx < 256) continue;
        if (idx >= WMGRI.PerkUpgradesList.Length) continue;
        if (WMGRI.PerkUpgradesList[idx].PerkUpgrade == None) continue;

        WMGRI.PerkUpgradesList[idx].PerkUpgrade.static.ModifyHardAttackDamage(InDamage, OrigInDamage, DKPRI.GetPerkLevel(idx), OwnerPawn);
    }

    if (InDamage < 0) InDamage = 0;

    // === PLAYERCAPS: max hard-attack damage as a multiple of base ===
    DKCapMaxMultInt(InDamage, OrigInDamage, class'ZTConfig_PlayerCaps'.static.GetCapHardAttackDamageMultiplier());
}

function bool ModifyHealAmount(out float HealAmount)
{
    local ZTPlayerReplicationInfo DKPRI;
    local WMGameReplicationInfo WMGRI;
    local float OrigHealAmount;
    local bool bSurgeActive;
    local int i, idx;

    OrigHealAmount = HealAmount;
    bSurgeActive = Super.ModifyHealAmount(HealAmount);

    DKPRI = GetDKPRI();
    if (DKPRI == None) return bSurgeActive;
    WMGRI = WMGameReplicationInfo(WorldInfo.GRI);
    if (WMGRI == None) return bSurgeActive;

    if (DKPassiveHealAmount_256Plus != 1.0f)
        HealAmount *= DKPassiveHealAmount_256Plus;

    for (i = 0; i < DKPRI.Purchase_PerkUpgrade.Length; ++i)
    {
        idx = DKPRI.Purchase_PerkUpgrade[i];
        if (idx < 256) continue;
        if (idx >= WMGRI.PerkUpgradesList.Length) continue;
        if (WMGRI.PerkUpgradesList[idx].PerkUpgrade == None) continue;

        WMGRI.PerkUpgradesList[idx].PerkUpgrade.static.ModifyHealAmount(HealAmount, OrigHealAmount, DKPRI.GetPerkLevel(idx));
    }

    // === PLAYERCAPS: max heal amount as a multiple of base ===
    DKCapMaxMultFloat(HealAmount, OrigHealAmount, class'ZTConfig_PlayerCaps'.static.GetCapHealAmountMultiplier());

    return bSurgeActive;
}

simulated function ModifyHealerRechargeTime(out float RechargeRate)
{
    local ZTPlayerReplicationInfo DKPRI;
    local WMGameReplicationInfo WMGRI;
    local float OrigRechargeRate;
    local int i, idx;

    OrigRechargeRate = RechargeRate;
    Super.ModifyHealerRechargeTime(RechargeRate);

    DKPRI = GetDKPRISimulated();
    if (DKPRI == None) return;
    WMGRI = WMGameReplicationInfo(WorldInfo.GRI);
    if (WMGRI == None) return;

    for (i = 0; i < DKPRI.Purchase_PerkUpgrade.Length; ++i)
    {
        idx = DKPRI.Purchase_PerkUpgrade[i];
        if (idx < 256) continue;
        if (idx >= WMGRI.PerkUpgradesList.Length) continue;
        if (WMGRI.PerkUpgradesList[idx].PerkUpgrade == None) continue;

        WMGRI.PerkUpgradesList[idx].PerkUpgrade.static.ModifyHealerRechargeTime(RechargeRate, OrigRechargeRate, DKPRI.GetPerkLevel(idx));
    }
}

simulated function ModifyRecoil(out float CurrentRecoilModifier, KFWeapon KFW)
{
    local ZTPlayerReplicationInfo DKPRI;
    local WMGameReplicationInfo WMGRI;
    local float OrigRecoil;
    local int i, idx;

    OrigRecoil = CurrentRecoilModifier;
    Super.ModifyRecoil(CurrentRecoilModifier, KFW);

    DKPRI = GetDKPRISimulated();
    if (DKPRI == None) return;
    WMGRI = WMGameReplicationInfo(WorldInfo.GRI);
    if (WMGRI == None) return;

    if (DKPassiveRecoil_256Plus != 1.0f)
        CurrentRecoilModifier *= DKPassiveRecoil_256Plus;

    for (i = 0; i < DKPRI.Purchase_PerkUpgrade.Length; ++i)
    {
        idx = DKPRI.Purchase_PerkUpgrade[i];
        if (idx < 256) continue;
        if (idx >= WMGRI.PerkUpgradesList.Length) continue;
        if (WMGRI.PerkUpgradesList[idx].PerkUpgrade == None) continue;

        WMGRI.PerkUpgradesList[idx].PerkUpgrade.static.ModifyRecoil(CurrentRecoilModifier, OrigRecoil, DKPRI.GetPerkLevel(idx), KFW);
    }

    // === PLAYERCAPS: recoil floor (caps how much recoil can be reduced) ===
    DKCapMinScaleFloat(CurrentRecoilModifier, OrigRecoil, class'ZTConfig_PlayerCaps'.static.GetCapRecoilMinScale());

    if (CurrentRecoilModifier < OrigRecoil * 0.05f)
        CurrentRecoilModifier = OrigRecoil * 0.05f;
}

simulated function ModifySpread(out float InSpread)
{
    local ZTPlayerReplicationInfo DKPRI;
    local WMGameReplicationInfo WMGRI;
    local KFWeapon KFW;
    local float OrigSpread;
    local int i, idx;

    OrigSpread = InSpread;
    Super.ModifySpread(InSpread);

    DKPRI = GetDKPRISimulated();
    if (DKPRI == None) return;
    WMGRI = WMGameReplicationInfo(WorldInfo.GRI);
    if (WMGRI == None) return;

    KFW = GetOwnerWeapon();

    if (DKPassiveSpread_256Plus != 1.0f)
        InSpread *= DKPassiveSpread_256Plus;

    for (i = 0; i < DKPRI.Purchase_PerkUpgrade.Length; ++i)
    {
        idx = DKPRI.Purchase_PerkUpgrade[i];
        if (idx < 256) continue;
        if (idx >= WMGRI.PerkUpgradesList.Length) continue;
        if (WMGRI.PerkUpgradesList[idx].PerkUpgrade == None) continue;

        WMGRI.PerkUpgradesList[idx].PerkUpgrade.static.ModifySpread(InSpread, OrigSpread, DKPRI.GetPerkLevel(idx), KFW);
    }

    // === PLAYERCAPS: spread floor (caps how much spread can be reduced) ===
    DKCapMinScaleFloat(InSpread, OrigSpread, class'ZTConfig_PlayerCaps'.static.GetCapSpreadMinScale());

    if (InSpread < OrigSpread * 0.05f)
        InSpread = OrigSpread * 0.05f;
}

simulated function ModifyWeaponBopDamping(out float BobDamping, KFWeapon PawnWeapon)
{
    local ZTPlayerReplicationInfo DKPRI;
    local WMGameReplicationInfo WMGRI;
    local float OrigBobDamping;
    local int i, idx;

    OrigBobDamping = BobDamping;
    Super.ModifyWeaponBopDamping(BobDamping, PawnWeapon);

    DKPRI = GetDKPRISimulated();
    if (DKPRI == None) return;
    WMGRI = WMGameReplicationInfo(WorldInfo.GRI);
    if (WMGRI == None) return;

    if (DKPassiveBobDamp_256Plus != 1.0f)
        BobDamping *= DKPassiveBobDamp_256Plus;

    for (i = 0; i < DKPRI.Purchase_PerkUpgrade.Length; ++i)
    {
        idx = DKPRI.Purchase_PerkUpgrade[i];
        if (idx < 256) continue;
        if (idx >= WMGRI.PerkUpgradesList.Length) continue;
        if (WMGRI.PerkUpgradesList[idx].PerkUpgrade == None) continue;

        WMGRI.PerkUpgradesList[idx].PerkUpgrade.static.ModifyWeaponBopDamping(BobDamping, OrigBobDamping, DKPRI.GetPerkLevel(idx), PawnWeapon);
    }
}

simulated function ModifyMagSizeAndNumber(KFWeapon KFW, out int MagazineCapacity, optional array< class<KFPerk> > WeaponPerkClass, optional bool bSecondary = False, optional name WeaponClassname)
{
    local ZTPlayerReplicationInfo DKPRI;
    local WMGameReplicationInfo WMGRI;
    local int OrigMagazineCapacity;
    local int MagCapacity;
    local int i, idx;

    OrigMagazineCapacity = MagazineCapacity;
    Super.ModifyMagSizeAndNumber(KFW, MagazineCapacity, WeaponPerkClass, bSecondary, WeaponClassname);

    if (KFWeap_Healer_Syringe(KFW) != None || KFWeap_Welder(KFW) != None)
        return;

    DKPRI = GetDKPRISimulated();
    if (DKPRI == None) return;
    WMGRI = WMGameReplicationInfo(WorldInfo.GRI);
    if (WMGRI == None) return;

    MagCapacity = MagazineCapacity;

    if (DKPassiveMagazineCapacity_256Plus != 1.0f)
        MagCapacity = Round(float(MagCapacity) * DKPassiveMagazineCapacity_256Plus);

    for (i = 0; i < DKPRI.Purchase_PerkUpgrade.Length; ++i)
    {
        idx = DKPRI.Purchase_PerkUpgrade[i];
        if (idx < 256) continue;
        if (idx >= WMGRI.PerkUpgradesList.Length) continue;
        if (WMGRI.PerkUpgradesList[idx].PerkUpgrade == None) continue;

        WMGRI.PerkUpgradesList[idx].PerkUpgrade.static.ModifyMagSizeAndNumber(MagCapacity, OrigMagazineCapacity, DKPRI.GetPerkLevel(idx), KFW, WeaponPerkClass, bSecondary, WeaponClassname);
    }

    // === PLAYERCAPS: max magazine size as a multiple of base ===
    DKCapMaxMultInt(MagCapacity, OrigMagazineCapacity, class'ZTConfig_PlayerCaps'.static.GetCapMagSizeMultiplier());

    // === PLAYERCAPS: absolute min magazine size floor (base-aware; non-bow) ===
    // Floors to Min(cap, base) so penalties cannot shrink a normal mag below the
    // cap, without inflating weapons whose base mag is already below it.
    DKCapMinAbsIntToBase(MagCapacity, class'ZTConfig_PlayerCaps'.static.GetCapMinMagSize(), OrigMagazineCapacity);

    if (KFWeap_Bow_Crossbow(KFW) == None && KFWeap_Bow_CompoundBow(KFW) == None && KFWeap_HRG_Crossboom(KFW) == None)
    {
        if (!bSecondary) MagazineCapacity = Clamp(MagCapacity, 0, MaxInt);
        else MagazineCapacity = Clamp(MagCapacity, 0, 255);
    }
    else
        MagazineCapacity = 1;
}

simulated function ModifyMaxSpareGrenadeAmount()
{
    local ZTPlayerReplicationInfo DKPRI;
    local WMGameReplicationInfo WMGRI;
    local int DefaultSpareGrenade;
    local int SpareGrenade;
    local int i, idx;

    Super.ModifyMaxSpareGrenadeAmount();

    DKPRI = GetDKPRISimulated();
    if (DKPRI == None) return;
    WMGRI = WMGameReplicationInfo(WorldInfo.GRI);
    if (WMGRI == None) return;

    DefaultSpareGrenade = MaxGrenadeCount;
    SpareGrenade = MaxGrenadeCount;

    for (i = 0; i < DKPRI.Purchase_PerkUpgrade.Length; ++i)
    {
        idx = DKPRI.Purchase_PerkUpgrade[i];
        if (idx < 256) continue;
        if (idx >= WMGRI.PerkUpgradesList.Length) continue;
        if (WMGRI.PerkUpgradesList[idx].PerkUpgrade == None) continue;

        WMGRI.PerkUpgradesList[idx].PerkUpgrade.static.ModifySpareGrenadeAmount(SpareGrenade, DefaultSpareGrenade, DKPRI.GetPerkLevel(idx));
    }

    // === PLAYERCAPS: absolute max spare grenades ===
    DKCapAbsInt(SpareGrenade, class'ZTConfig_PlayerCaps'.static.GetCapMaxSpareGrenades());

    MaxGrenadeCount = SpareGrenade;
}

simulated function ModifyWeldingRate(out float FastenRate, out float UnfastenRate)
{
    local ZTPlayerReplicationInfo DKPRI;
    local WMGameReplicationInfo WMGRI;
    local float OrigFastenRate, OrigUnfastenRate;
    local int i, idx;

    OrigFastenRate = FastenRate;
    OrigUnfastenRate = UnfastenRate;
    Super.ModifyWeldingRate(FastenRate, UnfastenRate);

    DKPRI = GetDKPRISimulated();
    if (DKPRI == None) return;
    WMGRI = WMGameReplicationInfo(WorldInfo.GRI);
    if (WMGRI == None) return;

    for (i = 0; i < DKPRI.Purchase_PerkUpgrade.Length; ++i)
    {
        idx = DKPRI.Purchase_PerkUpgrade[i];
        if (idx < 256) continue;
        if (idx >= WMGRI.PerkUpgradesList.Length) continue;
        if (WMGRI.PerkUpgradesList[idx].PerkUpgrade == None) continue;

        WMGRI.PerkUpgradesList[idx].PerkUpgrade.static.ModifyWeldingRate(FastenRate, OrigFastenRate, UnfastenRate, OrigUnfastenRate, DKPRI.GetPerkLevel(idx));
    }
}

function float GetZedTimeExtensionMax(byte Level)
{
    local ZTPlayerReplicationInfo DKPRI;
    local WMGameReplicationInfo WMGRI;
    local float Extension;
    local int i, idx;

    Extension = Super.GetZedTimeExtensionMax(Level);

    DKPRI = GetDKPRI();
    if (DKPRI == None) return Extension;
    WMGRI = WMGameReplicationInfo(WorldInfo.GRI);
    if (WMGRI == None) return Extension;

    for (i = 0; i < DKPRI.Purchase_PerkUpgrade.Length; ++i)
    {
        idx = DKPRI.Purchase_PerkUpgrade[i];
        if (idx < 256) continue;
        if (idx >= WMGRI.PerkUpgradesList.Length) continue;
        if (WMGRI.PerkUpgradesList[idx].PerkUpgrade == None) continue;

        WMGRI.PerkUpgradesList[idx].PerkUpgrade.static.GetZedTimeExtension(Extension, 1.0f, DKPRI.GetPerkLevel(idx));
    }

    return Extension;
}

function ApplyWeightLimits()
{
    local ZTPlayerReplicationInfo DKPRI;
    local WMGameReplicationInfo WMGRI;
    local KFInventoryManager KFIM;
    local int InWeightLimit, DefaultWeightLimit;
    local int i, idx;

    Super.ApplyWeightLimits();

    if (!CheckOwnerPawn()) return;
    KFIM = KFInventoryManager(OwnerPawn.InvManager);
    if (KFIM == None) return;

    DKPRI = GetDKPRI();
    if (DKPRI == None) return;
    WMGRI = WMGameReplicationInfo(WorldInfo.GRI);
    if (WMGRI == None) return;

    InWeightLimit = KFIM.MaxCarryBlocks;
    DefaultWeightLimit = InWeightLimit;

    for (i = 0; i < DKPRI.Purchase_PerkUpgrade.Length; ++i)
    {
        idx = DKPRI.Purchase_PerkUpgrade[i];
        if (idx < 256) continue;
        if (idx >= WMGRI.PerkUpgradesList.Length) continue;
        if (WMGRI.PerkUpgradesList[idx].PerkUpgrade == None) continue;

        WMGRI.PerkUpgradesList[idx].PerkUpgrade.static.ApplyWeightLimits(InWeightLimit, DefaultWeightLimit, DKPRI.GetPerkLevel(idx));
    }

    // === PLAYERCAPS: absolute max carry weight ===
    DKCapAbsInt(InWeightLimit, class'ZTConfig_PlayerCaps'.static.GetCapCarryWeight());

    KFIM.MaxCarryBlocks = InWeightLimit;
    CheckForOverWeight(KFIM);
}

function ModifyDoTScaler(out float DoTScaler, optional class<KFDamageType> KFDT, optional bool bNapalmInfected)
{
    local ZTPlayerReplicationInfo DKPRI;
    local WMGameReplicationInfo WMGRI;
    local float OrigDoTScaler;
    local int i, idx;

    OrigDoTScaler = DoTScaler;
    Super.ModifyDoTScaler(DoTScaler, KFDT, bNapalmInfected);

    DKPRI = GetDKPRI();
    if (DKPRI == None) return;
    WMGRI = WMGameReplicationInfo(WorldInfo.GRI);
    if (WMGRI == None) return;

    for (i = 0; i < DKPRI.Purchase_PerkUpgrade.Length; ++i)
    {
        idx = DKPRI.Purchase_PerkUpgrade[i];
        if (idx < 256) continue;
        if (idx >= WMGRI.PerkUpgradesList.Length) continue;
        if (WMGRI.PerkUpgradesList[idx].PerkUpgrade == None) continue;

        WMGRI.PerkUpgradesList[idx].PerkUpgrade.static.ModifyDoTScaler(DoTScaler, OrigDoTScaler, DKPRI.GetPerkLevel(idx), KFDT, bNapalmInfected);
    }
}

// =================== MODIFIER FUNCTIONS (2/2) ===================

simulated function float GetTightChokeModifier()
{
    local ZTPlayerReplicationInfo DKPRI;
    local WMGameReplicationInfo WMGRI;
    local KFWeapon KFW;
    local KFInventoryManager KFIM;
    local float InTight;
    local int i, idx;

    InTight = Super.GetTightChokeModifier();

    DKPRI = GetDKPRISimulated();
    if (DKPRI == None) return InTight;
    WMGRI = WMGameReplicationInfo(WorldInfo.GRI);
    if (WMGRI == None) return InTight;

    KFW = GetOwnerWeapon();
    if (KFW == None && CheckOwnerPawn())
    {
        KFIM = KFInventoryManager(OwnerPawn.InvManager);
        if (KFIM != None && KFIM.PendingWeapon != None)
            KFW = KFWeapon(KFIM.PendingWeapon);
    }

    if (DKPassiveTightChoke_256Plus != 1.0f)
        InTight *= DKPassiveTightChoke_256Plus;

    for (i = 0; i < DKPRI.Purchase_PerkUpgrade.Length; ++i)
    {
        idx = DKPRI.Purchase_PerkUpgrade[i];
        if (idx < 256) continue;
        if (idx >= WMGRI.PerkUpgradesList.Length) continue;
        if (WMGRI.PerkUpgradesList[idx].PerkUpgrade == None) continue;

        WMGRI.PerkUpgradesList[idx].PerkUpgrade.static.ModifyTightChoke(InTight, 1.0f, DKPRI.GetPerkLevel(idx), KFW, OwnerPawn);
    }

    if (InTight <= 0.005f) InTight = 0.005f;

    return InTight;
}

// DK FIX: KF2 shares ONE penetration pool per SHOT across all pellets and
// scales every impact's damage by remaining/initial on a linear curve
// (KFWeapon.ProcessInstantHitEx). Because ZR-style penetration bonuses ADD
// to the weapon's initial power, any penetration upgrade activates/extends
// that per-pellet damage degradation (e.g. Full Metal Jacket collapsing
// HZ12 pellet damage to single digits). This is the engine switch TWI added
// for the Gunslinger/Sharpshooter penetration skills: impacts deal full
// damage until the pool exhausts, making penetration purely a bonus.
// Side effect (intended): no through-body damage falloff for rifles either.
simulated function bool IgnoresPenetrationDmgReduction()
{
    return true;
}

simulated function float GetPenetrationModifier(byte Level, class<KFDamageType> DamageType, optional bool bForce)
{
    local ZTPlayerReplicationInfo DKPRI;
    local WMGameReplicationInfo WMGRI;
    local float InPenetration;
    local int i, idx;

    InPenetration = Super.GetPenetrationModifier(Level, DamageType, bForce);

    DKPRI = GetDKPRISimulated();
    if (DKPRI == None) return InPenetration;
    WMGRI = WMGameReplicationInfo(WorldInfo.GRI);
    if (WMGRI == None) return InPenetration;

    if (DKPassivePenetration_256Plus != 1.0f)
        InPenetration *= DKPassivePenetration_256Plus;

    for (i = 0; i < DKPRI.Purchase_PerkUpgrade.Length; ++i)
    {
        idx = DKPRI.Purchase_PerkUpgrade[i];
        if (idx < 256) continue;
        if (idx >= WMGRI.PerkUpgradesList.Length) continue;
        if (WMGRI.PerkUpgradesList[idx].PerkUpgrade == None) continue;

        WMGRI.PerkUpgradesList[idx].PerkUpgrade.static.ModifyPenetration(InPenetration, 1.0f, DKPRI.GetPerkLevel(idx), DamageType, OwnerPawn, bForce);
    }

    // === PLAYERCAPS: absolute max penetration ===
    DKCapAbsFloat(InPenetration, class'ZTConfig_PlayerCaps'.static.GetCapPenetrationMax());

    return InPenetration;
}

function float GetStunPowerModifier(optional class<DamageType> DamageType, optional byte HitZoneIdx)
{
    local ZTPlayerReplicationInfo DKPRI;
    local WMGameReplicationInfo WMGRI;
    local float InStunPower;
    local int i, idx;

    InStunPower = Super.GetStunPowerModifier(DamageType, HitZoneIdx);

    DKPRI = GetDKPRI();
    if (DKPRI == None) return InStunPower;
    WMGRI = WMGameReplicationInfo(WorldInfo.GRI);
    if (WMGRI == None) return InStunPower;

    if (DKPassiveStunPower_256Plus != 1.0f)
        InStunPower *= DKPassiveStunPower_256Plus;

    for (i = 0; i < DKPRI.Purchase_PerkUpgrade.Length; ++i)
    {
        idx = DKPRI.Purchase_PerkUpgrade[i];
        if (idx < 256) continue;
        if (idx >= WMGRI.PerkUpgradesList.Length) continue;
        if (WMGRI.PerkUpgradesList[idx].PerkUpgrade == None) continue;

        WMGRI.PerkUpgradesList[idx].PerkUpgrade.static.ModifyStunPower(InStunPower, 1.0f, DKPRI.GetPerkLevel(idx), DamageType, HitZoneIdx);
    }

    // === PLAYERCAPS: absolute max stun power ===
    DKCapAbsFloat(InStunPower, class'ZTConfig_PlayerCaps'.static.GetCapStunPowerMax());

    return InStunPower;
}

function float GetStumblePowerModifier(optional KFPawn KFP, optional class<KFDamageType> DamageType, optional out float CooldownModifier, optional byte BodyPart)
{
    local ZTPlayerReplicationInfo DKPRI;
    local WMGameReplicationInfo WMGRI;
    local float InStumblePower;
    local int i, idx;

    InStumblePower = Super.GetStumblePowerModifier(KFP, DamageType, CooldownModifier, BodyPart);

    DKPRI = GetDKPRI();
    if (DKPRI == None) return InStumblePower;
    WMGRI = WMGameReplicationInfo(WorldInfo.GRI);
    if (WMGRI == None) return InStumblePower;

    if (DKPassiveStumblePower_256Plus != 1.0f)
        InStumblePower *= DKPassiveStumblePower_256Plus;

    for (i = 0; i < DKPRI.Purchase_PerkUpgrade.Length; ++i)
    {
        idx = DKPRI.Purchase_PerkUpgrade[i];
        if (idx < 256) continue;
        if (idx >= WMGRI.PerkUpgradesList.Length) continue;
        if (WMGRI.PerkUpgradesList[idx].PerkUpgrade == None) continue;

        WMGRI.PerkUpgradesList[idx].PerkUpgrade.static.ModifyStumblePower(InStumblePower, 1.0f, DKPRI.GetPerkLevel(idx), KFP, DamageType, CooldownModifier, BodyPart, OwnerPawn);
    }

    // === PLAYERCAPS: absolute max stumble power ===
    DKCapAbsFloat(InStumblePower, class'ZTConfig_PlayerCaps'.static.GetCapStumblePowerMax());

    return InStumblePower;
}

function float GetKnockdownPowerModifier(optional class<DamageType> DamageType, optional byte BodyPart, optional bool bIsSprinting = False)
{
    local ZTPlayerReplicationInfo DKPRI;
    local WMGameReplicationInfo WMGRI;
    local float InKnockdownPower;
    local int i, idx;

    InKnockdownPower = Super.GetKnockdownPowerModifier(DamageType, BodyPart, bIsSprinting);

    DKPRI = GetDKPRI();
    if (DKPRI == None) return InKnockdownPower;
    WMGRI = WMGameReplicationInfo(WorldInfo.GRI);
    if (WMGRI == None) return InKnockdownPower;

    if (DKPassiveKnockdownPower_256Plus != 1.0f)
        InKnockdownPower *= DKPassiveKnockdownPower_256Plus;

    for (i = 0; i < DKPRI.Purchase_PerkUpgrade.Length; ++i)
    {
        idx = DKPRI.Purchase_PerkUpgrade[i];
        if (idx < 256) continue;
        if (idx >= WMGRI.PerkUpgradesList.Length) continue;
        if (WMGRI.PerkUpgradesList[idx].PerkUpgrade == None) continue;

        WMGRI.PerkUpgradesList[idx].PerkUpgrade.static.ModifyKnockdownPower(InKnockdownPower, 1.0f, DKPRI.GetPerkLevel(idx), OwnerPawn, DamageType, BodyPart, bIsSprinting);
    }

    // === PLAYERCAPS: absolute max knockdown power ===
    DKCapAbsFloat(InKnockdownPower, class'ZTConfig_PlayerCaps'.static.GetCapKnockdownPowerMax());

    return InKnockdownPower;
}

simulated function float GetSnarePowerModifier(optional class<DamageType> DamageType, optional byte HitZoneIdx)
{
    local ZTPlayerReplicationInfo DKPRI;
    local WMGameReplicationInfo WMGRI;
    local float InSnarePower;
    local int i, idx;

    // Parent returns FMax(0, value - 1.0f). Recover approximate internal
    // value by adding 1.0f. Drift if super clamped to 0.
    InSnarePower = Super.GetSnarePowerModifier(DamageType, HitZoneIdx) + 1.0f;

    DKPRI = GetDKPRISimulated();
    if (DKPRI == None) return FMax(0.0f, InSnarePower - 1.0f);
    WMGRI = WMGameReplicationInfo(WorldInfo.GRI);
    if (WMGRI == None) return FMax(0.0f, InSnarePower - 1.0f);

    if (DKPassiveSnarePower_256Plus != 1.0f)
        InSnarePower *= DKPassiveSnarePower_256Plus;

    for (i = 0; i < DKPRI.Purchase_PerkUpgrade.Length; ++i)
    {
        idx = DKPRI.Purchase_PerkUpgrade[i];
        if (idx < 256) continue;
        if (idx >= WMGRI.PerkUpgradesList.Length) continue;
        if (WMGRI.PerkUpgradesList[idx].PerkUpgrade == None) continue;

        WMGRI.PerkUpgradesList[idx].PerkUpgrade.static.ModifySnarePower(InSnarePower, 1.0f, DKPRI.GetPerkLevel(idx), DamageType, HitZoneIdx);
    }

    // === PLAYERCAPS: absolute max snare power (external snare value is x-1.0) ===
    if (class'ZTConfig_PlayerCaps'.static.IsEnabled()
        && class'ZTConfig_PlayerCaps'.static.GetCapSnarePowerMax() > 0.0
        && (InSnarePower - 1.0f) > class'ZTConfig_PlayerCaps'.static.GetCapSnarePowerMax())
    {
        InSnarePower = class'ZTConfig_PlayerCaps'.static.GetCapSnarePowerMax() + 1.0f;
    }

    return FMax(0.0f, InSnarePower - 1.0f);
}

function AddVampireHealth(KFPlayerController KFPC, class<DamageType> DT)
{
    local ZTPlayerReplicationInfo DKPRI;
    local WMGameReplicationInfo WMGRI;
    local int InHealth;
    local int i, idx;

    Super.AddVampireHealth(KFPC, DT);

    if (KFPC == None || KFPC.Pawn == None) return;

    DKPRI = GetDKPRI();
    if (DKPRI == None) return;
    WMGRI = WMGameReplicationInfo(WorldInfo.GRI);
    if (WMGRI == None) return;

    InHealth = 0;

    for (i = 0; i < DKPRI.Purchase_PerkUpgrade.Length; ++i)
    {
        idx = DKPRI.Purchase_PerkUpgrade[i];
        if (idx < 256) continue;
        if (idx >= WMGRI.PerkUpgradesList.Length) continue;
        if (WMGRI.PerkUpgradesList[idx].PerkUpgrade == None) continue;

        WMGRI.PerkUpgradesList[idx].PerkUpgrade.static.AddVampireHealth(InHealth, 0, DKPRI.GetPerkLevel(idx), KFPC, DT);
    }

    if (InHealth > 0)
    {
        KFPC.Pawn.HealDamage(InHealth, KFPC, class'KFDT_Healing', False, False);
    }
}

simulated function float GetSelfHealingSurgePct()
{
    local ZTPlayerReplicationInfo DKPRI;
    local WMGameReplicationInfo WMGRI;
    local float InHealingPct;
    local int i, idx;

    InHealingPct = Super.GetSelfHealingSurgePct();

    DKPRI = GetDKPRISimulated();
    if (DKPRI == None) return InHealingPct;
    WMGRI = WMGameReplicationInfo(WorldInfo.GRI);
    if (WMGRI == None) return InHealingPct;

    for (i = 0; i < DKPRI.Purchase_PerkUpgrade.Length; ++i)
    {
        idx = DKPRI.Purchase_PerkUpgrade[i];
        if (idx < 256) continue;
        if (idx >= WMGRI.PerkUpgradesList.Length) continue;
        if (WMGRI.PerkUpgradesList[idx].PerkUpgrade == None) continue;

        WMGRI.PerkUpgradesList[idx].PerkUpgrade.static.GetSelfHealingSurgePct(InHealingPct, DKPRI.GetPerkLevel(idx));
    }

    return InHealingPct;
}

simulated event float GetIronSightSpeedModifier(KFWeapon KFW)
{
    local ZTPlayerReplicationInfo DKPRI;
    local WMGameReplicationInfo WMGRI;
    local float InSpeed;
    local int i, idx;

    InSpeed = Super.GetIronSightSpeedModifier(KFW);

    DKPRI = GetDKPRISimulated();
    if (DKPRI == None) return InSpeed;
    WMGRI = WMGameReplicationInfo(WorldInfo.GRI);
    if (WMGRI == None) return InSpeed;

    for (i = 0; i < DKPRI.Purchase_PerkUpgrade.Length; ++i)
    {
        idx = DKPRI.Purchase_PerkUpgrade[i];
        if (idx < 256) continue;
        if (idx >= WMGRI.PerkUpgradesList.Length) continue;
        if (WMGRI.PerkUpgradesList[idx].PerkUpgrade == None) continue;

        WMGRI.PerkUpgradesList[idx].PerkUpgrade.static.GetIronSightSpeedModifier(InSpeed, 1.0f, DKPRI.GetPerkLevel(idx));
    }

    return InSpeed;
}

simulated event float GetCrouchSpeedModifier(KFWeapon KFW)
{
    local ZTPlayerReplicationInfo DKPRI;
    local WMGameReplicationInfo WMGRI;
    local float InSpeed;
    local int i, idx;

    InSpeed = Super.GetCrouchSpeedModifier(KFW);

    DKPRI = GetDKPRISimulated();
    if (DKPRI == None) return InSpeed;
    WMGRI = WMGameReplicationInfo(WorldInfo.GRI);
    if (WMGRI == None) return InSpeed;

    for (i = 0; i < DKPRI.Purchase_PerkUpgrade.Length; ++i)
    {
        idx = DKPRI.Purchase_PerkUpgrade[i];
        if (idx < 256) continue;
        if (idx >= WMGRI.PerkUpgradesList.Length) continue;
        if (WMGRI.PerkUpgradesList[idx].PerkUpgrade == None) continue;

        WMGRI.PerkUpgradesList[idx].PerkUpgrade.static.GetCrouchSpeedModifier(InSpeed, 1.0f, DKPRI.GetPerkLevel(idx));
    }

    return InSpeed;
}

simulated function float GetCloakDetectionRange()
{
    local ZTPlayerReplicationInfo DKPRI;
    local WMGameReplicationInfo WMGRI;
    local float InRange;
    local int i, idx;

    InRange = Super.GetCloakDetectionRange();

    DKPRI = GetDKPRISimulated();
    if (DKPRI == None) return InRange;
    WMGRI = WMGameReplicationInfo(WorldInfo.GRI);
    if (WMGRI == None) return InRange;

    for (i = 0; i < DKPRI.Purchase_PerkUpgrade.Length; ++i)
    {
        idx = DKPRI.Purchase_PerkUpgrade[i];
        if (idx < 256) continue;
        if (idx >= WMGRI.PerkUpgradesList.Length) continue;
        if (WMGRI.PerkUpgradesList[idx].PerkUpgrade == None) continue;

        WMGRI.PerkUpgradesList[idx].PerkUpgrade.static.ModifyCloakDetectionRange(InRange, 2000.0f, DKPRI.GetPerkLevel(idx));
    }

    return InRange;
}

simulated event float GetZedTimeModifier(KFWeapon W)
{
    local ZTPlayerReplicationInfo DKPRI;
    local WMGameReplicationInfo WMGRI;
    local float InModifier;
    local int i, idx;

    InModifier = Super.GetZedTimeModifier(W);

    DKPRI = GetDKPRISimulated();
    if (DKPRI == None) return InModifier;
    WMGRI = WMGameReplicationInfo(WorldInfo.GRI);
    if (WMGRI == None) return InModifier;

    for (i = 0; i < DKPRI.Purchase_PerkUpgrade.Length; ++i)
    {
        idx = DKPRI.Purchase_PerkUpgrade[i];
        if (idx < 256) continue;
        if (idx >= WMGRI.PerkUpgradesList.Length) continue;
        if (WMGRI.PerkUpgradesList[idx].PerkUpgrade == None) continue;

        WMGRI.PerkUpgradesList[idx].PerkUpgrade.static.GetZedTimeModifier(InModifier, DKPRI.GetPerkLevel(idx), W);
    }

    return InModifier;
}

simulated function ModifyMaxDeployed(out int CurrentMaxDeployed, KFWeapon KFW)
{
    local ZTPlayerReplicationInfo DKPRI;
    local WMGameReplicationInfo WMGRI;
    local int OrigMaxDeployed;
    local int i, idx;

    OrigMaxDeployed = CurrentMaxDeployed;
    Super.ModifyMaxDeployed(CurrentMaxDeployed, KFW);

    DKPRI = GetDKPRISimulated();
    if (DKPRI == None) return;
    WMGRI = WMGameReplicationInfo(WorldInfo.GRI);
    if (WMGRI == None) return;

    for (i = 0; i < DKPRI.Purchase_PerkUpgrade.Length; ++i)
    {
        idx = DKPRI.Purchase_PerkUpgrade[i];
        if (idx < 256) continue;
        if (idx >= WMGRI.PerkUpgradesList.Length) continue;
        if (WMGRI.PerkUpgradesList[idx].PerkUpgrade == None) continue;

        WMGRI.PerkUpgradesList[idx].PerkUpgrade.static.ModifyMaxDeployed(CurrentMaxDeployed, OrigMaxDeployed, DKPRI.GetPerkLevel(idx), KFW);
    }

    // === PLAYERCAPS: absolute max deployed turrets/pets ===
    DKCapAbsInt(CurrentMaxDeployed, class'ZTConfig_PlayerCaps'.static.GetCapMaxDeployedTurrets());
}

// =================== BOOLEAN-OR FUNCTIONS (1/2) ===================

function bool CanSpreadNapalm()
{
    local ZTPlayerReplicationInfo DKPRI;
    local WMGameReplicationInfo WMGRI;
    local int i, idx;

    if (Super.CanSpreadNapalm()) return True;

    DKPRI = GetDKPRI();
    if (DKPRI == None) return False;
    WMGRI = WMGameReplicationInfo(WorldInfo.GRI);
    if (WMGRI == None) return False;

    for (i = 0; i < DKPRI.Purchase_PerkUpgrade.Length; ++i)
    {
        idx = DKPRI.Purchase_PerkUpgrade[i];
        if (idx < 256) continue;
        if (idx >= WMGRI.PerkUpgradesList.Length) continue;
        if (WMGRI.PerkUpgradesList[idx].PerkUpgrade == None) continue;

        if (WMGRI.PerkUpgradesList[idx].PerkUpgrade.static.CanSpreadNapalm(DKPRI.GetPerkLevel(idx), OwnerPawn))
            return True;
    }

    return False;
}

simulated function bool CanKnockDownOnBump(KFPawn_Monster KFPM)
{
    local ZTPlayerReplicationInfo DKPRI;
    local WMGameReplicationInfo WMGRI;
    local int i, idx;

    if (Super.CanKnockDownOnBump(KFPM)) return True;

    DKPRI = GetDKPRISimulated();
    if (DKPRI == None) return False;
    WMGRI = WMGameReplicationInfo(WorldInfo.GRI);
    if (WMGRI == None) return False;

    for (i = 0; i < DKPRI.Purchase_PerkUpgrade.Length; ++i)
    {
        idx = DKPRI.Purchase_PerkUpgrade[i];
        if (idx < 256) continue;
        if (idx >= WMGRI.PerkUpgradesList.Length) continue;
        if (WMGRI.PerkUpgradesList[idx].PerkUpgrade == None) continue;

        if (WMGRI.PerkUpgradesList[idx].PerkUpgrade.static.ShouldKnockDownOnBump(DKPRI.GetPerkLevel(idx), KFPM, OwnerPawn))
            return True;
    }

    return False;
}

simulated function bool ShouldNeverDud()
{
    local ZTPlayerReplicationInfo DKPRI;
    local WMGameReplicationInfo WMGRI;
    local KFWeapon KFW;
    local KFInventoryManager KFIM;
    local int i, idx;

    if (Super.ShouldNeverDud()) return True;

    DKPRI = GetDKPRISimulated();
    if (DKPRI == None) return False;
    WMGRI = WMGameReplicationInfo(WorldInfo.GRI);
    if (WMGRI == None) return False;

    KFW = GetOwnerWeapon();
    if (KFW == None && CheckOwnerPawn())
    {
        KFIM = KFInventoryManager(OwnerPawn.InvManager);
        if (KFIM != None && KFIM.PendingWeapon != None)
            KFW = KFWeapon(KFIM.PendingWeapon);
    }

    for (i = 0; i < DKPRI.Purchase_PerkUpgrade.Length; ++i)
    {
        idx = DKPRI.Purchase_PerkUpgrade[i];
        if (idx < 256) continue;
        if (idx >= WMGRI.PerkUpgradesList.Length) continue;
        if (WMGRI.PerkUpgradesList[idx].PerkUpgrade == None) continue;

        if (WMGRI.PerkUpgradesList[idx].PerkUpgrade.static.ShouldNeverDud(DKPRI.GetPerkLevel(idx), KFW, OwnerPawn))
            return True;
    }

    return False;
}

function bool CouldBeZedShrapnel(class<KFDamageType> KFDT)
{
    local ZTPlayerReplicationInfo DKPRI;
    local WMGameReplicationInfo WMGRI;
    local int i, idx;

    if (Super.CouldBeZedShrapnel(KFDT)) return True;

    DKPRI = GetDKPRI();
    if (DKPRI == None) return False;
    WMGRI = WMGameReplicationInfo(WorldInfo.GRI);
    if (WMGRI == None) return False;

    for (i = 0; i < DKPRI.Purchase_PerkUpgrade.Length; ++i)
    {
        idx = DKPRI.Purchase_PerkUpgrade[i];
        if (idx < 256) continue;
        if (idx >= WMGRI.PerkUpgradesList.Length) continue;
        if (WMGRI.PerkUpgradesList[idx].PerkUpgrade == None) continue;

        if (WMGRI.PerkUpgradesList[idx].PerkUpgrade.static.CouldBeZedShrapnel(DKPRI.GetPerkLevel(idx), KFDT))
            return True;
    }

    return False;
}

simulated function bool ShouldShrapnel()
{
    local ZTPlayerReplicationInfo DKPRI;
    local WMGameReplicationInfo WMGRI;
    local int i, idx;

    if (Super.ShouldShrapnel()) return True;

    DKPRI = GetDKPRISimulated();
    if (DKPRI == None) return False;
    WMGRI = WMGameReplicationInfo(WorldInfo.GRI);
    if (WMGRI == None) return False;

    for (i = 0; i < DKPRI.Purchase_PerkUpgrade.Length; ++i)
    {
        idx = DKPRI.Purchase_PerkUpgrade[i];
        if (idx < 256) continue;
        if (idx >= WMGRI.PerkUpgradesList.Length) continue;
        if (WMGRI.PerkUpgradesList[idx].PerkUpgrade == None) continue;

        if (WMGRI.PerkUpgradesList[idx].PerkUpgrade.static.ShouldShrapnel(DKPRI.GetPerkLevel(idx)))
            return True;
    }

    return False;
}

simulated function bool IsRangeActive()
{
    local ZTPlayerReplicationInfo DKPRI;
    local WMGameReplicationInfo WMGRI;
    local int i, idx;

    if (Super.IsRangeActive()) return True;  // super already set bExtraFireRange

    DKPRI = GetDKPRISimulated();
    if (DKPRI == None) return False;
    WMGRI = WMGameReplicationInfo(WorldInfo.GRI);
    if (WMGRI == None) return False;

    for (i = 0; i < DKPRI.Purchase_PerkUpgrade.Length; ++i)
    {
        idx = DKPRI.Purchase_PerkUpgrade[i];
        if (idx < 256) continue;
        if (idx >= WMGRI.PerkUpgradesList.Length) continue;
        if (WMGRI.PerkUpgradesList[idx].PerkUpgrade == None) continue;

        if (WMGRI.PerkUpgradesList[idx].PerkUpgrade.static.IsRangeActive(DKPRI.GetPerkLevel(idx), OwnerPawn))
        {
            DKPRI.bExtraFireRange = True;
            return True;
        }
    }

    return False;
}

simulated function bool IsGroundFireActive()
{
    local ZTPlayerReplicationInfo DKPRI;
    local WMGameReplicationInfo WMGRI;
    local int i, idx;

    if (Super.IsGroundFireActive()) return True;  // super already set bSplashActive

    DKPRI = GetDKPRISimulated();
    if (DKPRI == None) return False;
    WMGRI = WMGameReplicationInfo(WorldInfo.GRI);
    if (WMGRI == None) return False;

    for (i = 0; i < DKPRI.Purchase_PerkUpgrade.Length; ++i)
    {
        idx = DKPRI.Purchase_PerkUpgrade[i];
        if (idx < 256) continue;
        if (idx >= WMGRI.PerkUpgradesList.Length) continue;
        if (WMGRI.PerkUpgradesList[idx].PerkUpgrade == None) continue;

        if (WMGRI.PerkUpgradesList[idx].PerkUpgrade.static.IsGroundFireActive(DKPRI.GetPerkLevel(idx), OwnerPawn))
        {
            DKPRI.bSplashActive = True;
            return True;
        }
    }

    return False;
}

simulated function bool GetUsingTactialReload(KFWeapon KFW)
{
    local ZTPlayerReplicationInfo DKPRI;
    local WMGameReplicationInfo WMGRI;
    local int i, idx;

    if (Super.GetUsingTactialReload(KFW)) return True;

    DKPRI = GetDKPRISimulated();
    if (DKPRI == None) return False;
    WMGRI = WMGameReplicationInfo(WorldInfo.GRI);
    if (WMGRI == None) return False;

    for (i = 0; i < DKPRI.Purchase_PerkUpgrade.Length; ++i)
    {
        idx = DKPRI.Purchase_PerkUpgrade[i];
        if (idx < 256) continue;
        if (idx >= WMGRI.PerkUpgradesList.Length) continue;
        if (WMGRI.PerkUpgradesList[idx].PerkUpgrade == None) continue;

        if (WMGRI.PerkUpgradesList[idx].PerkUpgrade.static.GetUsingTactialReload(DKPRI.GetPerkLevel(idx), KFW))
            return True;
    }

    return False;
}

function bool CanNotBeGrabbed()
{
    local ZTPlayerReplicationInfo DKPRI;
    local WMGameReplicationInfo WMGRI;
    local int i, idx;

    if (Super.CanNotBeGrabbed()) return True;

    DKPRI = GetDKPRI();
    if (DKPRI == None) return False;
    WMGRI = WMGameReplicationInfo(WorldInfo.GRI);
    if (WMGRI == None) return False;

    for (i = 0; i < DKPRI.Purchase_PerkUpgrade.Length; ++i)
    {
        idx = DKPRI.Purchase_PerkUpgrade[i];
        if (idx < 256) continue;
        if (idx >= WMGRI.PerkUpgradesList.Length) continue;
        if (WMGRI.PerkUpgradesList[idx].PerkUpgrade == None) continue;

        if (WMGRI.PerkUpgradesList[idx].PerkUpgrade.static.CanNotBeGrabbed(DKPRI.GetPerkLevel(idx), OwnerPawn))
            return True;
    }

    return False;
}

simulated function bool ShouldRandSirenResist()
{
    local ZTPlayerReplicationInfo DKPRI;
    local WMGameReplicationInfo WMGRI;
    local int i, idx;

    if (Super.ShouldRandSirenResist()) return True;

    DKPRI = GetDKPRISimulated();
    if (DKPRI == None) return False;
    WMGRI = WMGameReplicationInfo(WorldInfo.GRI);
    if (WMGRI == None) return False;

    for (i = 0; i < DKPRI.Purchase_PerkUpgrade.Length; ++i)
    {
        idx = DKPRI.Purchase_PerkUpgrade[i];
        if (idx < 256) continue;
        if (idx >= WMGRI.PerkUpgradesList.Length) continue;
        if (WMGRI.PerkUpgradesList[idx].PerkUpgrade == None) continue;

        if (WMGRI.PerkUpgradesList[idx].PerkUpgrade.static.ProjSirenResist(DKPRI.GetPerkLevel(idx), OwnerPawn))
            return True;
    }

    return False;
}

// =================== BOOLEAN-OR FUNCTIONS (2/2) ===================

simulated function bool GetIsUberAmmoActive(KFWeapon KFW)
{
    local ZTPlayerReplicationInfo DKPRI;
    local WMGameReplicationInfo WMGRI;
    local int i, idx;

    if (Super.GetIsUberAmmoActive(KFW)) return True;

    DKPRI = GetDKPRISimulated();
    if (DKPRI == None) return False;
    WMGRI = WMGameReplicationInfo(WorldInfo.GRI);
    if (WMGRI == None) return False;

    for (i = 0; i < DKPRI.Purchase_PerkUpgrade.Length; ++i)
    {
        idx = DKPRI.Purchase_PerkUpgrade[i];
        if (idx < 256) continue;
        if (idx >= WMGRI.PerkUpgradesList.Length) continue;
        if (WMGRI.PerkUpgradesList[idx].PerkUpgrade == None) continue;

        if (WMGRI.PerkUpgradesList[idx].PerkUpgrade.static.GetIsUberAmmoActive(DKPRI.GetPerkLevel(idx), KFW, OwnerPawn))
            return True;
    }

    return False;
}

simulated function bool CanSeeEnemyHealth()
{
    local ZTPlayerReplicationInfo DKPRI;
    local WMGameReplicationInfo WMGRI;
    local int i, idx;

    if (Super.CanSeeEnemyHealth()) return True;

    DKPRI = GetDKPRISimulated();
    if (DKPRI == None) return False;
    WMGRI = WMGameReplicationInfo(WorldInfo.GRI);
    if (WMGRI == None) return False;

    for (i = 0; i < DKPRI.Purchase_PerkUpgrade.Length; ++i)
    {
        idx = DKPRI.Purchase_PerkUpgrade[i];
        if (idx < 256) continue;
        if (idx >= WMGRI.PerkUpgradesList.Length) continue;
        if (WMGRI.PerkUpgradesList[idx].PerkUpgrade == None) continue;

        if (WMGRI.PerkUpgradesList[idx].PerkUpgrade.static.CanSeeEnemyHealth(DKPRI.GetPerkLevel(idx), OwnerPawn))
            return True;
    }

    return False;
}

simulated function bool IsCallOutActive()
{
    local ZTPlayerReplicationInfo DKPRI;
    local WMGameReplicationInfo WMGRI;
    local int i, idx;

    if (Super.IsCallOutActive()) return True;  // super already set bCanSeeCloakedZeds

    // Note: super reset bCanSeeCloakedZeds to False at start. Our paged path
    // sets it to True if any paged perk fires.

    DKPRI = GetDKPRISimulated();
    if (DKPRI == None) return False;
    WMGRI = WMGameReplicationInfo(WorldInfo.GRI);
    if (WMGRI == None) return False;

    for (i = 0; i < DKPRI.Purchase_PerkUpgrade.Length; ++i)
    {
        idx = DKPRI.Purchase_PerkUpgrade[i];
        if (idx < 256) continue;
        if (idx >= WMGRI.PerkUpgradesList.Length) continue;
        if (WMGRI.PerkUpgradesList[idx].PerkUpgrade == None) continue;

        if (WMGRI.PerkUpgradesList[idx].PerkUpgrade.static.IsCallOutActive(DKPRI.GetPerkLevel(idx), OwnerPawn))
        {
            bCanSeeCloakedZeds = True;
            return True;
        }
    }

    return False;
}

simulated function bool ShouldSacrifice()
{
    local ZTPlayerReplicationInfo DKPRI;
    local WMGameReplicationInfo WMGRI;
    local int i, idx;

    if (Super.ShouldSacrifice()) return True;

    // Edge case: parent's bUsedSacrifice guard is private. If super already
    // used the sacrifice and returned False because of that, our paged check
    // still fires. Could double-trigger sacrifice. Accepted.

    DKPRI = GetDKPRI();
    if (DKPRI == None) return False;
    WMGRI = WMGameReplicationInfo(WorldInfo.GRI);
    if (WMGRI == None) return False;

    for (i = 0; i < DKPRI.Purchase_PerkUpgrade.Length; ++i)
    {
        idx = DKPRI.Purchase_PerkUpgrade[i];
        if (idx < 256) continue;
        if (idx >= WMGRI.PerkUpgradesList.Length) continue;
        if (WMGRI.PerkUpgradesList[idx].PerkUpgrade == None) continue;

        if (WMGRI.PerkUpgradesList[idx].PerkUpgrade.static.ShouldSacrifice(DKPRI.GetPerkLevel(idx), OwnerPawn))
            return True;
    }

    return False;
}

simulated function bool DoorShouldNuke()
{
    local ZTPlayerReplicationInfo DKPRI;
    local WMGameReplicationInfo WMGRI;
    local int i, idx;

    if (Super.DoorShouldNuke()) return True;

    DKPRI = GetDKPRISimulated();
    if (DKPRI == None) return False;
    WMGRI = WMGameReplicationInfo(WorldInfo.GRI);
    if (WMGRI == None) return False;

    for (i = 0; i < DKPRI.Purchase_PerkUpgrade.Length; ++i)
    {
        idx = DKPRI.Purchase_PerkUpgrade[i];
        if (idx < 256) continue;
        if (idx >= WMGRI.PerkUpgradesList.Length) continue;
        if (WMGRI.PerkUpgradesList[idx].PerkUpgrade == None) continue;

        if (WMGRI.PerkUpgradesList[idx].PerkUpgrade.static.DoorShouldNuke(DKPRI.GetPerkLevel(idx), OwnerPawn))
            return True;
    }

    return False;
}

simulated function bool CanExplosiveWeld()
{
    local ZTPlayerReplicationInfo DKPRI;
    local WMGameReplicationInfo WMGRI;
    local int i, idx;

    if (Super.CanExplosiveWeld()) return True;

    DKPRI = GetDKPRISimulated();
    if (DKPRI == None) return False;
    WMGRI = WMGameReplicationInfo(WorldInfo.GRI);
    if (WMGRI == None) return False;

    for (i = 0; i < DKPRI.Purchase_PerkUpgrade.Length; ++i)
    {
        idx = DKPRI.Purchase_PerkUpgrade[i];
        if (idx < 256) continue;
        if (idx >= WMGRI.PerkUpgradesList.Length) continue;
        if (WMGRI.PerkUpgradesList[idx].PerkUpgrade == None) continue;

        if (WMGRI.PerkUpgradesList[idx].PerkUpgrade.static.CanExplosiveWeld(DKPRI.GetPerkLevel(idx), OwnerPawn))
            return True;
    }

    return False;
}

simulated function bool HasNightVision()
{
    local ZTPlayerReplicationInfo DKPRI;
    local WMGameReplicationInfo WMGRI;
    local int i, idx;

    if (Super.HasNightVision()) return True;

    DKPRI = GetDKPRISimulated();
    if (DKPRI == None) return False;
    WMGRI = WMGameReplicationInfo(WorldInfo.GRI);
    if (WMGRI == None) return False;

    for (i = 0; i < DKPRI.Purchase_PerkUpgrade.Length; ++i)
    {
        idx = DKPRI.Purchase_PerkUpgrade[i];
        if (idx < 256) continue;
        if (idx >= WMGRI.PerkUpgradesList.Length) continue;
        if (WMGRI.PerkUpgradesList[idx].PerkUpgrade == None) continue;

        if (WMGRI.PerkUpgradesList[idx].PerkUpgrade.static.HasNightVision(DKPRI.GetPerkLevel(idx)))
            return True;
    }

    return False;
}

function bool IsUnAffectedByZedTime()
{
    local ZTPlayerReplicationInfo DKPRI;
    local WMGameReplicationInfo WMGRI;
    local int i, idx;

    if (Super.IsUnAffectedByZedTime()) return True;  // super already set bMovesFastInZedTime

    DKPRI = GetDKPRI();
    if (DKPRI == None) return False;
    WMGRI = WMGameReplicationInfo(WorldInfo.GRI);
    if (WMGRI == None) return False;

    for (i = 0; i < DKPRI.Purchase_PerkUpgrade.Length; ++i)
    {
        idx = DKPRI.Purchase_PerkUpgrade[i];
        if (idx < 256) continue;
        if (idx >= WMGRI.PerkUpgradesList.Length) continue;
        if (WMGRI.PerkUpgradesList[idx].PerkUpgrade == None) continue;

        if (WMGRI.PerkUpgradesList[idx].PerkUpgrade.static.IsUnAffectedByZedTime(DKPRI.GetPerkLevel(idx), OwnerPawn))
        {
            if (OwnerPawn != None)
                OwnerPawn.bMovesFastInZedTime = True;
            return True;
        }
    }

    return False;
}

simulated function bool ImmuneToCameraShake()
{
    local ZTPlayerReplicationInfo DKPRI;
    local WMGameReplicationInfo WMGRI;
    local int i, idx;

    if (Super.ImmuneToCameraShake()) return True;

    DKPRI = GetDKPRISimulated();
    if (DKPRI == None) return False;
    WMGRI = WMGameReplicationInfo(WorldInfo.GRI);
    if (WMGRI == None) return False;

    for (i = 0; i < DKPRI.Purchase_PerkUpgrade.Length; ++i)
    {
        idx = DKPRI.Purchase_PerkUpgrade[i];
        if (idx < 256) continue;
        if (idx >= WMGRI.PerkUpgradesList.Length) continue;
        if (WMGRI.PerkUpgradesList[idx].PerkUpgrade == None) continue;

        if (WMGRI.PerkUpgradesList[idx].PerkUpgrade.static.ImmuneToCameraShake(DKPRI.GetPerkLevel(idx), OwnerPawn))
            return True;
    }

    return False;
}

simulated function bool IsSupplierActive()
{
    local ZTPlayerReplicationInfo DKPRI;
    local WMGameReplicationInfo WMGRI;
    local int i, idx;

    if (Super.IsSupplierActive()) return True;

    DKPRI = GetDKPRISimulated();
    if (DKPRI == None) return False;
    WMGRI = WMGameReplicationInfo(WorldInfo.GRI);
    if (WMGRI == None) return False;

    for (i = 0; i < DKPRI.Purchase_PerkUpgrade.Length; ++i)
    {
        idx = DKPRI.Purchase_PerkUpgrade[i];
        if (idx < 256) continue;
        if (idx >= WMGRI.PerkUpgradesList.Length) continue;
        if (WMGRI.PerkUpgradesList[idx].PerkUpgrade == None) continue;

        if (WMGRI.PerkUpgradesList[idx].PerkUpgrade.static.IsSupplierActive(DKPRI.GetPerkLevel(idx)))
            return True;
    }

    return False;
}

simulated function bool CanSeeCloaked(KFWeapon KFW)
{
    local ZTPlayerReplicationInfo DKPRI;
    local WMGameReplicationInfo WMGRI;
    local int i, idx;

    if (Super.CanSeeCloaked(KFW)) return True;

    DKPRI = GetDKPRISimulated();
    if (DKPRI == None) return False;
    WMGRI = WMGameReplicationInfo(WorldInfo.GRI);
    if (WMGRI == None) return False;

    for (i = 0; i < DKPRI.Purchase_PerkUpgrade.Length; ++i)
    {
        idx = DKPRI.Purchase_PerkUpgrade[i];
        if (idx < 256) continue;
        if (idx >= WMGRI.PerkUpgradesList.Length) continue;
        if (WMGRI.PerkUpgradesList[idx].PerkUpgrade == None) continue;

        if (WMGRI.PerkUpgradesList[idx].PerkUpgrade.static.CanSeeCloaked(DKPRI.GetPerkLevel(idx), KFW, OwnerPawn))
            return True;
    }

    return False;
}

// =================== SIDE-EFFECT FUNCTIONS ===================

function simulated SetSuccessfullParry()
{
    local ZTPlayerReplicationInfo DKPRI;
    local WMGameReplicationInfo WMGRI;
    local int i, idx;
    local ZTHudWrapper TemperedHUD;

    Super.SetSuccessfullParry();

    DKPRI = GetDKPRISimulated();
    if (DKPRI == None) return;
    WMGRI = WMGameReplicationInfo(WorldInfo.GRI);
    if (WMGRI == None) return;

    // Keep the compact stat box synchronized with the event-driven Parry
    // bonus. The helper actor is not reliably discoverable on every client.
    for (i = 0; i < DKPRI.Purchase_SkillUpgrade.Length; ++i)
    {
        idx = DKPRI.Purchase_SkillUpgrade[i];
        if (idx < 0 || idx >= WMGRI.SkillUpgradesList.Length)
            continue;
        if (WMGRI.SkillUpgradesList[idx].SkillUpgrade == class'WMUpgrade_Skill_Parry'
            || WMGRI.SkillUpgradesList[idx].SkillUpgrade == class'ZTWrapper_Skill_Parry')
        {
            TemperedHUD = ZTHudWrapper(OwnerPC.myHUD);
            if (TemperedHUD != None)
                TemperedHUD.NotifyParryStatBuff(True, 10.0f);
            break;
        }
    }

    for (i = 0; i < DKPRI.Purchase_PerkUpgrade.Length; ++i)
    {
        idx = DKPRI.Purchase_PerkUpgrade[i];
        if (idx < 256) continue;
        if (idx >= WMGRI.PerkUpgradesList.Length) continue;
        if (WMGRI.PerkUpgradesList[idx].PerkUpgrade == None) continue;

        WMGRI.PerkUpgradesList[idx].PerkUpgrade.static.SuccessfullParry(DKPRI.GetPerkLevel(idx), OwnerPawn);
    }
}

simulated function InitiateWeapon(KFWeapon KFW)
{
    local ZTPlayerReplicationInfo DKPRI;
    local WMGameReplicationInfo WMGRI;
    local int i, idx;

    // Super calls ModifyMaxSpareGrenadeAmount() at end; that virtual-
    // dispatches to our override which handles paged. Do NOT call it
    // again here, would double-fire grenade adjustments.
    Super.InitiateWeapon(KFW);

    DKPRI = GetDKPRISimulated();
    if (DKPRI == None) return;
    WMGRI = WMGameReplicationInfo(WorldInfo.GRI);
    if (WMGRI == None) return;

    for (i = 0; i < DKPRI.Purchase_PerkUpgrade.Length; ++i)
    {
        idx = DKPRI.Purchase_PerkUpgrade[i];
        if (idx < 256) continue;
        if (idx >= WMGRI.PerkUpgradesList.Length) continue;
        if (WMGRI.PerkUpgradesList[idx].PerkUpgrade == None) continue;

        WMGRI.PerkUpgradesList[idx].PerkUpgrade.static.InitiateWeapon(DKPRI.GetPerkLevel(idx), KFW, OwnerPawn);
    }
}

function WaveEnd(KFPlayerController KFPC)
{
    local ZTPlayerReplicationInfo DKPRI;
    local WMGameReplicationInfo WMGRI;
    local int i, idx;

    Super.WaveEnd(KFPC);

    DKPRI = GetDKPRI();
    if (DKPRI == None) return;
    WMGRI = WMGameReplicationInfo(WorldInfo.GRI);
    if (WMGRI == None) return;

    for (i = 0; i < DKPRI.Purchase_PerkUpgrade.Length; ++i)
    {
        idx = DKPRI.Purchase_PerkUpgrade[i];
        if (idx < 256) continue;
        if (idx >= WMGRI.PerkUpgradesList.Length) continue;
        if (WMGRI.PerkUpgradesList[idx].PerkUpgrade == None) continue;

        WMGRI.PerkUpgradesList[idx].PerkUpgrade.static.WaveEnd(DKPRI.GetPerkLevel(idx), KFPC);
    }
}

simulated function ReceiveLocalizedMessage(class<LocalMessage> Message, optional int Switch)
{
    local ZTPlayerReplicationInfo DKPRI;
    local WMGameReplicationInfo WMGRI;
    local int i, idx;

    Super.ReceiveLocalizedMessage(Message, Switch);

    DKPRI = GetDKPRISimulated();
    if (DKPRI == None) return;
    WMGRI = WMGameReplicationInfo(WorldInfo.GRI);
    if (WMGRI == None) return;

    for (i = 0; i < DKPRI.Purchase_PerkUpgrade.Length; ++i)
    {
        idx = DKPRI.Purchase_PerkUpgrade[i];
        if (idx < 256) continue;
        if (idx >= WMGRI.PerkUpgradesList.Length) continue;
        if (WMGRI.PerkUpgradesList[idx].PerkUpgrade == None) continue;

        WMGRI.PerkUpgradesList[idx].PerkUpgrade.static.ReceiveLocalizedMessage(DKPRI.GetPerkLevel(idx), Message, OwnerPawn, Switch);
    }
}

function HealingDamage(int HealAmount, KFPawn KFP, class<DamageType> DamageType)
{
    local ZTPlayerReplicationInfo DKPRI;
    local WMGameReplicationInfo WMGRI;
    local int i, idx;

    Super.HealingDamage(HealAmount, KFP, DamageType);

    DKPRI = GetDKPRI();
    if (DKPRI == None) return;
    WMGRI = WMGameReplicationInfo(WorldInfo.GRI);
    if (WMGRI == None) return;

    for (i = 0; i < DKPRI.Purchase_PerkUpgrade.Length; ++i)
    {
        idx = DKPRI.Purchase_PerkUpgrade[i];
        if (idx < 256) continue;
        if (idx >= WMGRI.PerkUpgradesList.Length) continue;
        if (WMGRI.PerkUpgradesList[idx].PerkUpgrade == None) continue;

        WMGRI.PerkUpgradesList[idx].PerkUpgrade.static.HealingDamage(DKPRI.GetPerkLevel(idx), HealAmount, KFP, OwnerPawn, DamageType);
    }
}

simulated function SupplierModifiers(out float PrimaryAmmoPercentage, out float SecondaryAmmoPercentage, out float ArmorPercentage, out int GrenadeAmount)
{
    local ZTPlayerReplicationInfo DKPRI;
    local WMGameReplicationInfo WMGRI;
    local int i, idx;

    Super.SupplierModifiers(PrimaryAmmoPercentage, SecondaryAmmoPercentage, ArmorPercentage, GrenadeAmount);

    DKPRI = GetDKPRISimulated();
    if (DKPRI == None) return;
    WMGRI = WMGameReplicationInfo(WorldInfo.GRI);
    if (WMGRI == None) return;

    for (i = 0; i < DKPRI.Purchase_PerkUpgrade.Length; ++i)
    {
        idx = DKPRI.Purchase_PerkUpgrade[i];
        if (idx < 256) continue;
        if (idx >= WMGRI.PerkUpgradesList.Length) continue;
        if (WMGRI.PerkUpgradesList[idx].PerkUpgrade == None) continue;

        WMGRI.PerkUpgradesList[idx].PerkUpgrade.static.SupplierModifiers(DKPRI.GetPerkLevel(idx), PrimaryAmmoPercentage, SecondaryAmmoPercentage, ArmorPercentage, GrenadeAmount);
    }

    // Re-clamp after paged contributions (super already clamped pre-paged).
    PrimaryAmmoPercentage = FClamp(PrimaryAmmoPercentage, 0.0f, 100.0f);
    SecondaryAmmoPercentage = FClamp(SecondaryAmmoPercentage, 0.0f, 100.0f);
    ArmorPercentage = FClamp(ArmorPercentage, 0.0f, 100.0f);
    GrenadeAmount = Clamp(GrenadeAmount, 0, 255);
}

simulated function ApplyBatteryRechargeRate()
{
    local ZTPlayerReplicationInfo DKPRI;
    local WMGameReplicationInfo WMGRI;
    local float InRechargeRateFL, InRechargeRateNVG;
    local int i, idx;

    Super.ApplyBatteryRechargeRate();

    if (!CheckOwnerPawn()) return;

    DKPRI = GetDKPRISimulated();
    if (DKPRI == None) return;
    WMGRI = WMGameReplicationInfo(WorldInfo.GRI);
    if (WMGRI == None) return;

    // Recover post-super internal rates from OwnerPawn.
    // Drift if super clamped to 0.05f minimum; we lose info about the
    // pre-clamp value but the floor stays applied.
    if (OwnerPawn.default.BatteryDrainRate != 0.0f)
        InRechargeRateFL = OwnerPawn.BatteryDrainRate / OwnerPawn.default.BatteryDrainRate;
    else
        InRechargeRateFL = 1.0f;

    if (OwnerPawn.default.NVGBatteryDrainRate != 0.0f)
        InRechargeRateNVG = OwnerPawn.NVGBatteryDrainRate / OwnerPawn.default.NVGBatteryDrainRate;
    else
        InRechargeRateNVG = 1.0f;

    for (i = 0; i < DKPRI.Purchase_PerkUpgrade.Length; ++i)
    {
        idx = DKPRI.Purchase_PerkUpgrade[i];
        if (idx < 256) continue;
        if (idx >= WMGRI.PerkUpgradesList.Length) continue;
        if (WMGRI.PerkUpgradesList[idx].PerkUpgrade == None) continue;

        WMGRI.PerkUpgradesList[idx].PerkUpgrade.static.GetBatteryRateScale(InRechargeRateFL, InRechargeRateNVG, DKPRI.GetPerkLevel(idx), OwnerPawn);
    }

    if (InRechargeRateFL <= 0.05f) InRechargeRateFL = 0.05f;
    if (InRechargeRateNVG <= 0.05f) InRechargeRateNVG = 0.05f;

    OwnerPawn.BatteryDrainRate = OwnerPawn.default.BatteryDrainRate * InRechargeRateFL;
    OwnerPawn.NVGBatteryDrainRate = OwnerPawn.default.NVGBatteryDrainRate * InRechargeRateNVG;
}

simulated function DrawSpecialPerkHUD(Canvas C)
{
    local ZTPlayerReplicationInfo DKPRI;
    local WMGameReplicationInfo WMGRI;
    local int i, idx;

    Super.DrawSpecialPerkHUD(C);

    DKPRI = GetDKPRISimulated();
    if (DKPRI == None) return;
    WMGRI = WMGameReplicationInfo(WorldInfo.GRI);
    if (WMGRI == None) return;

    for (i = 0; i < DKPRI.Purchase_PerkUpgrade.Length; ++i)
    {
        idx = DKPRI.Purchase_PerkUpgrade[i];
        if (idx < 256) continue;
        if (idx >= WMGRI.PerkUpgradesList.Length) continue;
        if (WMGRI.PerkUpgradesList[idx].PerkUpgrade == None) continue;

        WMGRI.PerkUpgradesList[idx].PerkUpgrade.static.DrawOnHUD(DKPRI.GetPerkLevel(idx), C, OwnerPawn);
    }
}

// =================== DISPLAY/RETURN-VALUE FUNCTIONS ===================

simulated function byte GetHealingDamageBoost()
{
    local ZTPlayerReplicationInfo DKPRI;
    local WMGameReplicationInfo WMGRI;
    local byte InHealingDamageBoost;
    local int i, idx;

    InHealingDamageBoost = Super.GetHealingDamageBoost();

    DKPRI = GetDKPRISimulated();
    if (DKPRI == None) return InHealingDamageBoost;
    WMGRI = WMGameReplicationInfo(WorldInfo.GRI);
    if (WMGRI == None) return InHealingDamageBoost;

    for (i = 0; i < DKPRI.Purchase_PerkUpgrade.Length; ++i)
    {
        idx = DKPRI.Purchase_PerkUpgrade[i];
        if (idx < 256) continue;
        if (idx >= WMGRI.PerkUpgradesList.Length) continue;
        if (WMGRI.PerkUpgradesList[idx].PerkUpgrade == None) continue;

        WMGRI.PerkUpgradesList[idx].PerkUpgrade.static.GetHealingDamageBoost(InHealingDamageBoost, DKPRI.GetPerkLevel(idx));
    }

    return InHealingDamageBoost;
}

simulated function byte GetMaxHealingDamageBoost()
{
    local ZTPlayerReplicationInfo DKPRI;
    local WMGameReplicationInfo WMGRI;
    local byte InMaxHealingDamageBoost;
    local int i, idx;

    InMaxHealingDamageBoost = Super.GetMaxHealingDamageBoost();

    DKPRI = GetDKPRISimulated();
    if (DKPRI == None) return InMaxHealingDamageBoost;
    WMGRI = WMGameReplicationInfo(WorldInfo.GRI);
    if (WMGRI == None) return InMaxHealingDamageBoost;

    for (i = 0; i < DKPRI.Purchase_PerkUpgrade.Length; ++i)
    {
        idx = DKPRI.Purchase_PerkUpgrade[i];
        if (idx < 256) continue;
        if (idx >= WMGRI.PerkUpgradesList.Length) continue;
        if (WMGRI.PerkUpgradesList[idx].PerkUpgrade == None) continue;

        WMGRI.PerkUpgradesList[idx].PerkUpgrade.static.GetMaxHealingDamageBoost(InMaxHealingDamageBoost, DKPRI.GetPerkLevel(idx));
    }

    return InMaxHealingDamageBoost;
}

simulated function byte GetHealingShield()
{
    local ZTPlayerReplicationInfo DKPRI;
    local WMGameReplicationInfo WMGRI;
    local byte InHealingShield;
    local int i, idx;

    InHealingShield = Super.GetHealingShield();

    DKPRI = GetDKPRISimulated();
    if (DKPRI == None) return InHealingShield;
    WMGRI = WMGameReplicationInfo(WorldInfo.GRI);
    if (WMGRI == None) return InHealingShield;

    for (i = 0; i < DKPRI.Purchase_PerkUpgrade.Length; ++i)
    {
        idx = DKPRI.Purchase_PerkUpgrade[i];
        if (idx < 256) continue;
        if (idx >= WMGRI.PerkUpgradesList.Length) continue;
        if (WMGRI.PerkUpgradesList[idx].PerkUpgrade == None) continue;

        WMGRI.PerkUpgradesList[idx].PerkUpgrade.static.GetHealingShield(InHealingShield, DKPRI.GetPerkLevel(idx));
    }

    return InHealingShield;
}

simulated function byte GetMaxHealingShield()
{
    local ZTPlayerReplicationInfo DKPRI;
    local WMGameReplicationInfo WMGRI;
    local byte InMaxHealingShield;
    local int i, idx;

    InMaxHealingShield = Super.GetMaxHealingShield();

    DKPRI = GetDKPRISimulated();
    if (DKPRI == None) return InMaxHealingShield;
    WMGRI = WMGameReplicationInfo(WorldInfo.GRI);
    if (WMGRI == None) return InMaxHealingShield;

    for (i = 0; i < DKPRI.Purchase_PerkUpgrade.Length; ++i)
    {
        idx = DKPRI.Purchase_PerkUpgrade[i];
        if (idx < 256) continue;
        if (idx >= WMGRI.PerkUpgradesList.Length) continue;
        if (WMGRI.PerkUpgradesList[idx].PerkUpgrade == None) continue;

        WMGRI.PerkUpgradesList[idx].PerkUpgrade.static.GetMaxHealingShield(InMaxHealingShield, DKPRI.GetPerkLevel(idx));
    }

    return InMaxHealingShield;
}

simulated function class<EmitterCameraLensEffectBase> GetPerkLensEffect(class<KFDamageType> DmgType)
{
    local ZTPlayerReplicationInfo DKPRI;
    local WMGameReplicationInfo WMGRI;
    local class<EmitterCameraLensEffectBase> CamEffect;
    local int i, idx;

    CamEffect = Super.GetPerkLensEffect(DmgType);

    DKPRI = GetDKPRISimulated();
    if (DKPRI == None) return CamEffect;
    WMGRI = WMGameReplicationInfo(WorldInfo.GRI);
    if (WMGRI == None) return CamEffect;

    for (i = 0; i < DKPRI.Purchase_PerkUpgrade.Length; ++i)
    {
        idx = DKPRI.Purchase_PerkUpgrade[i];
        if (idx < 256) continue;
        if (idx >= WMGRI.PerkUpgradesList.Length) continue;
        if (WMGRI.PerkUpgradesList[idx].PerkUpgrade == None) continue;

        WMGRI.PerkUpgradesList[idx].PerkUpgrade.static.GetPerkLensEffect(CamEffect, DmgType, DKPRI.GetPerkLevel(idx));
    }

    return CamEffect;
}

// =================== EXTENSION FUNCTIONS ===================

simulated function bool ExtensionFuncBoolean(string Identifier, optional int InputInt = INDEX_NONE, optional float InputFloat = INDEX_NONE, optional name InputClassName, optional Object InputObject1, optional Object InputObject2, optional Object InputObject3)
{
    local ZTPlayerReplicationInfo DKPRI;
    local WMGameReplicationInfo WMGRI;
    local KFWeapon MyKFW;
    local int i, idx;

    if (Super.ExtensionFuncBoolean(Identifier, InputInt, InputFloat, InputClassName, InputObject1, InputObject2, InputObject3))
        return True;

    DKPRI = GetDKPRISimulated();
    if (DKPRI == None) return False;
    WMGRI = WMGameReplicationInfo(WorldInfo.GRI);
    if (WMGRI == None) return False;

    MyKFW = GetOwnerWeapon();

    for (i = 0; i < DKPRI.Purchase_PerkUpgrade.Length; ++i)
    {
        idx = DKPRI.Purchase_PerkUpgrade[i];
        if (idx < 256) continue;
        if (idx >= WMGRI.PerkUpgradesList.Length) continue;
        if (WMGRI.PerkUpgradesList[idx].PerkUpgrade == None) continue;

        if (WMGRI.PerkUpgradesList[idx].PerkUpgrade.static.ExtensionFuncBoolean(DKPRI.GetPerkLevel(idx), Identifier, MyKFW, OwnerPawn, InputInt, InputFloat, InputClassName, InputObject1, InputObject2, InputObject3))
            return True;
    }

    return False;
}

simulated function int ExtensionFuncInteger(int DefaultValueIn, string Identifier, optional int InputInt = INDEX_NONE, optional float InputFloat = INDEX_NONE, optional name InputClassName, optional Object InputObject1, optional Object InputObject2, optional Object InputObject3)
{
    local ZTPlayerReplicationInfo DKPRI;
    local WMGameReplicationInfo WMGRI;
    local KFWeapon MyKFW;
    local int InValue, DefaultValue;
    local int i, idx;

    InValue = Super.ExtensionFuncInteger(DefaultValueIn, Identifier, InputInt, InputFloat, InputClassName, InputObject1, InputObject2, InputObject3);
    DefaultValue = DefaultValueIn;

    DKPRI = GetDKPRISimulated();
    if (DKPRI == None) return InValue;
    WMGRI = WMGameReplicationInfo(WorldInfo.GRI);
    if (WMGRI == None) return InValue;

    MyKFW = GetOwnerWeapon();

    for (i = 0; i < DKPRI.Purchase_PerkUpgrade.Length; ++i)
    {
        idx = DKPRI.Purchase_PerkUpgrade[i];
        if (idx < 256) continue;
        if (idx >= WMGRI.PerkUpgradesList.Length) continue;
        if (WMGRI.PerkUpgradesList[idx].PerkUpgrade == None) continue;

        WMGRI.PerkUpgradesList[idx].PerkUpgrade.static.ExtensionFuncInteger(InValue, DefaultValue, DKPRI.GetPerkLevel(idx), Identifier, MyKFW, OwnerPawn, InputInt, InputFloat, InputClassName, InputObject1, InputObject2, InputObject3);
    }

    return InValue;
}

simulated function float ExtensionFuncFloat(float DefaultValueIn, string Identifier, optional int InputInt = INDEX_NONE, optional float InputFloat = INDEX_NONE, optional name InputClassName, optional Object InputObject1, optional Object InputObject2, optional Object InputObject3)
{
    local ZTPlayerReplicationInfo DKPRI;
    local WMGameReplicationInfo WMGRI;
    local KFWeapon MyKFW;
    local float InValue, DefaultValue;
    local int i, idx;

    InValue = Super.ExtensionFuncFloat(DefaultValueIn, Identifier, InputInt, InputFloat, InputClassName, InputObject1, InputObject2, InputObject3);
    DefaultValue = DefaultValueIn;

    DKPRI = GetDKPRISimulated();
    if (DKPRI == None) return InValue;
    WMGRI = WMGameReplicationInfo(WorldInfo.GRI);
    if (WMGRI == None) return InValue;

    MyKFW = GetOwnerWeapon();

    for (i = 0; i < DKPRI.Purchase_PerkUpgrade.Length; ++i)
    {
        idx = DKPRI.Purchase_PerkUpgrade[i];
        if (idx < 256) continue;
        if (idx >= WMGRI.PerkUpgradesList.Length) continue;
        if (WMGRI.PerkUpgradesList[idx].PerkUpgrade == None) continue;

        WMGRI.PerkUpgradesList[idx].PerkUpgrade.static.ExtensionFuncFloat(InValue, DefaultValue, DKPRI.GetPerkLevel(idx), Identifier, MyKFW, OwnerPawn, InputInt, InputFloat, InputClassName, InputObject1, InputObject2, InputObject3);
    }

    return InValue;
}

// ===================================================================
// STATIC ZED TYPE IDENTIFICATION HELPERS
// ===================================================================

static function bool IsBossZed(KFPawn_Monster KFPM)
{
    if (KFPM == None)
        return false;
    return KFPM.IsA('KFPawn_MonsterBoss');
}

static function bool IsBloatZed(KFPawn_Monster KFPM)
{
    if (KFPM == None)
        return false;
    return KFPM.IsA('KFPawn_ZedBloat');
}

static function bool IsScrakeZed(KFPawn_Monster KFPM)
{
    if (KFPM == None)
        return false;
    return KFPM.IsA('KFPawn_ZedScrake');
}

static function bool IsFleshpoundZed(KFPawn_Monster KFPM)
{
    if (KFPM == None)
        return false;
    return KFPM.IsA('KFPawn_ZedFleshpound');
}

static function bool IsLargeZed(KFPawn_Monster KFPM)
{
    if (KFPM == None)
        return false;
    return KFPM.IsLargeZed();
}

static function bool IsCrawlerZed(KFPawn_Monster KFPM)
{
    if (KFPM == None)
        return false;
    return KFPM.IsA('KFPawn_ZedCrawler');
}

static function bool IsHuskZed(KFPawn_Monster KFPM)
{
    if (KFPM == None)
        return false;
    return KFPM.IsA('KFPawn_ZedHusk');
}

static function bool IsSirenZed(KFPawn_Monster KFPM)
{
    if (KFPM == None)
        return false;
    return KFPM.IsA('KFPawn_ZedSiren');
}

static function bool IsClotZed(KFPawn_Monster KFPM)
{
    if (KFPM == None)
        return false;
    return KFPM.IsA('KFPawn_ZedClot');
}

static function bool IsStalkerZed(KFPawn_Monster KFPM)
{
    if (KFPM == None)
        return false;
    return KFPM.IsA('KFPawn_ZedStalker');
}

static function bool IsGorefastZed(KFPawn_Monster KFPM)
{
    if (KFPM == None)
        return false;
    return KFPM.IsA('KFPawn_ZedGorefast');
}

static function bool IsEDARZed(KFPawn_Monster KFPM)
{
    if (KFPM == None)
        return false;
    return KFPM.IsA('KFPawn_ZedDAR');
}

// ===================================================================
// VARIANT-AWARE isValidWeapon
// Parent WMPerk.isValidWeapon does EXACT class match (KFW.Class ==
// WeaponClass). When a weapon's class swaps to a Reforged/Hollow variant
// (Artificer reforging, Hollow swap, etc), the held class no longer
// matches the slot's stored WeaponClass and dispatch silently skips the
// slot. The level stays in WMPRI.bWeaponUpgrade so the trader UI keeps
// showing the upgrade as purchased while no bonus applies.
//
// Fix: also accept "held weapon's class is a subclass of slot's
// WeaponClass" (ClassIsChildOf KFW.Class -> WeaponClass). Asymmetric on
// purpose: a slot for a SPECIFIC variant (e.g. Reforged 9mm) still does
// not apply when holding the vanilla parent, so separately-purchased
// variant slots remain distinct.
// ===================================================================
simulated function bool isValidWeapon(class<KFWeapon> WeaponClass, KFWeapon KFW)
{
    local KFPawn KP;
    local class<KFWeapon> SingleCls;

    if (KFW == None || WeaponClass == None)
        return False;

    // Exact match (parent behavior).
    if (KFW.Class == WeaponClass)
        return True;

    // Variant subclass match: held weapon descends from slot's class.
    // Covers Reforged/Hollow variants of any base KFWeap_*.
    if (ClassIsChildOf(KFW.Class, WeaponClass))
        return True;

    // Dual single-class match (parent behavior) + variant subclass.
    if (KFWeap_DualBase(KFW) != None)
    {
        SingleCls = KFWeap_DualBase(KFW).SingleClass;
        if (SingleCls == WeaponClass)
            return True;
        if (SingleCls != None && ClassIsChildOf(SingleCls, WeaponClass))
            return True;
    }

    // Turret match (parent behavior) + variant subclass.
    KP = KFPawn(KFW.Owner);
    if (KP != None && KP.bIsTurret && KFWeapon(KP.Owner) != None)
    {
        if (KFWeapon(KP.Owner).Class == WeaponClass)
            return True;
        if (ClassIsChildOf(KFWeapon(KP.Owner).Class, WeaponClass))
            return True;
    }

    return False;
}

defaultproperties
{
    // Initialize DK paged passive cache to 1.0f so a modifier call that
    // arrives before ApplySkillsToPawn doesn't multiply by 0.
    DKPassiveDamageGiven_256Plus=1.0
    DKPassiveDamageTaken_256Plus=1.0
    DKPassiveHealAmount_256Plus=1.0
    DKPassiveHardAttackDamage_256Plus=1.0
    DKPassiveStunPower_256Plus=1.0
    DKPassiveStumblePower_256Plus=1.0
    DKPassiveKnockdownPower_256Plus=1.0
    DKPassiveSnarePower_256Plus=1.0

    DKPassiveMovementSpeed_256Plus=1.0
    DKPassiveSwitchSpeed_256Plus=1.0
    DKPassiveMeleeAttackSpeed_256Plus=1.0
    DKPassiveReloadRateScale_256Plus=1.0
    DKPassiveRecoil_256Plus=1.0
    DKPassiveSpread_256Plus=1.0
    DKPassiveBobDamp_256Plus=1.0
    DKPassiveMagazineCapacity_256Plus=1.0
    DKPassiveSpareAmmo_256Plus=1.0
    DKPassiveRateOfFire_256Plus=1.0
    DKPassiveTightChoke_256Plus=1.0
    DKPassivePenetration_256Plus=1.0

    Name="Default__ZTPerk"
}
