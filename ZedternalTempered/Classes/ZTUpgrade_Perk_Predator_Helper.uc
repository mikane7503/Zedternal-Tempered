// ===================================================================
// ZTUpgrade_Perk_Predator_Helper - Trophy collection state machine
//
// Server-authoritative with replicated bonus fields for client hooks.
// Client HUD data flows through reliable RPC (SendDisplayUpdate).
// Gameplay-relevant Acc* fields are replicated so that simulated
// static hooks (ModifySpeed, GetReloadRateScale, ModifyMagSizeAndNumber
// etc.) can read correct values on the client.
//
// PHASES:
//   1. Set Phase (0-N sets): Collect unique trophies, complete sets
//   2. Stacking Phase (N sets done): Collect unlimited stacking trophies
//      filling 5 category slots with infinite scaling bonuses
//
// SKILL INTEGRATION:
//   Skills set flags on this Helper via InitiateWeapon.
//   Helper checks flags during key operations.
//
// HEALTH/ARMOR BONUS SYSTEM:
//   Static ModifyHealth/ModifyArmor hooks lack a pawn reference,
//   so we apply HP/Armor bonuses directly and use a watchdog timer
//   to re-apply after external UpdateWeaponMagAndCap resets.
//   ForceWeaponRecalc() handles mid-wave weapon stat updates.
// ===================================================================
class ZTUpgrade_Perk_Predator_Helper extends Actor;

// ===================================================================
// REPLICATION
// Acc* fields + boolean flags need to reach the client so that
// simulated static hooks on the perk class can read them.
// ===================================================================
replication
{
    if (bNetDirty && Role == ROLE_Authority)
        AccAllDamage, AccLargeZedDamage, AccDamageResist, AccSpeed,
        AccReload, AccMeleeDamage, AccMagSize, AccWeaponSwitch,
        AccSpareAmmo, AccHeadshotDamage, bCanNotBeGrabbed,
        bCanSeeEnemyHealth;
}

// ===================================================================
// CONSTANTS
// ===================================================================

// Trophy categories
const CAT_CLOT = 0;
const CAT_CRAWLER = 1;
const CAT_GOREFAST = 2;
const CAT_STALKER = 3;
const CAT_BLOAT = 4;
const CAT_HUSK = 5;
const CAT_SIREN = 6;
const CAT_EDAR = 7;
const CAT_SCRAKE = 8;
const CAT_FLESHPOUND = 9;
const CAT_BOSS = 10;
const NUM_CATEGORIES = 11;

// Set indices
const SET_SWARM_BREAKER = 0;
const SET_BLADE_COLLECTOR = 1;
const SET_FREAK_SHOW = 2;
const SET_SALVAGE_RUN = 3;
const SET_BIG_GAME = 4;
const SET_FULL_SWEEP = 5;
const SET_NIGHT_STALKER = 6;
const SET_BRUTE_FORCE = 7;
const SET_KING_SLAYER = 8;
const SET_APEX_PREDATOR = 9;
const SET_TROPHY_WALL = 10;
const SET_LEGENDARY_HUNTER = 11;
const NUM_SETS = 12;

const MAX_INVENTORY = 5;
const MAX_SETS_BASE = 3;

// Drop chance
const BASE_DROP_CHANCE = 0.01f;
const MAX_DROP_CHANCE = 0.05f;
const DROP_CHANCE_PER_LEVEL = 0.002105f;

// Trophy pickup velocity
const TROPHY_VELOCITY_XY = 100.0f;
const TROPHY_VELOCITY_Z = 200.0f;

// Stacking phase bonus rates per stack
const STACK_CLOT_DOSH = 1;
const STACK_CRAWLER_SPEED = 0.01f;
const STACK_STALKER_MAGSIZE = 0.01f;
const STACK_GOREFAST_MELEE = 0.01f;
const STACK_BLOAT_HP = 1;
const STACK_SCRAKE_ARMOR = 5;
const STACK_FP_DAMAGE = 0.10f;
const STACK_EDAR_HEADSHOT = 0.10f;
const STACK_HUSK_RESIST = 0.005f;
const STACK_SIREN_AMMO = 0.05f;

// ===================================================================
// VARIABLES
// ===================================================================

// --- Perk State ---
var int PerkLevel;
var KFPawn_Human Player;

// --- Trophy Inventory (server-authoritative) ---
var byte TrophyCount[11];
var int TotalTrophies;

// --- Set Completion ---
var int CompletedSets;
var int CompletedSetsCount;

// --- Stacking Phase ---
var bool bStackingPhase;
var byte NumStackSlotsFilled;

// --- Bonus Multiplier (1.0 normally, 2.0 at level 20 Trophy Master) ---
var float SetBonusMultiplier;

// --- Accumulated Bonuses (server-computed, replicated to client) ---
var float AccAllDamage;
var float AccLargeZedDamage;
var float AccDamageResist;
var float AccSpeed;
var float AccReload;
var float AccMeleeDamage;
var float AccMagSize;
var float AccWeaponSwitch;
var float AccSpareAmmo;
var float AccHeadshotDamage;
var bool bCanNotBeGrabbed;
var bool bCanSeeEnemyHealth;

// Flat bonuses (stacking phase only, used for HUD display)
var int StackBonusHP;
var int StackBonusArmor;
var int StackBonusDosh;

// --- Unified HP/Armor Bonuses (all sources combined) ---
// These are computed in RecalculateAllBonuses and applied directly
// because static ModifyHealth/ModifyArmor hooks lack pawn references.
var int AccBonusHP;
var int AccBonusArmor;

// --- Health/Armor Watchdog Tracking ---
// After applying our bonus, we record what HealthMax/MaxArmor should be.
// The watchdog timer detects external resets and re-applies.
var int HealthMaxWithBonus;
var int MaxArmorWithBonus;

// --- Drop Tracking (server only) ---
var byte bCategoryDropped[11];
var array<ZTTrophyPickup> LivePickups;

// --- Client-side display copies (set by RPC) ---
var byte RepTrophyCount[11];
var byte RepTotalTrophies;
var int RepCompletedSets;
var byte RepCompletedSetsCount;
var bool bRepTrophyMaster;
var byte RepMaxSlots;

// ===================================================================
// SKILL INTEGRATION VARIABLES
// ===================================================================

// Trophy Hoarder: extra inventory slots beyond base 5
var int SkillExtraSlots;

// Feeding Frenzy: fire rate buff after collection
var float SkillFeedingFrenzyBonus;
var float SkillFeedingFrenzyDuration;
var bool bFeedingFrenzyActive;

// Taxidermist: chance to preserve trophies on set consumption
var float SkillPreserveChance;

// Trophy Magnetism: auto-pull nearby pickups
var float SkillMagnetRange;
var bool bSkillExtendPickupLife;

// Apex Mark: boss kill = guaranteed drops for N seconds
var float SkillApexMarkDuration;
var bool bApexMarkActive;

// Diversified Collection: per-unique-category damage bonus (read by skill)
// (No variable needed here - skill reads CountUniqueTrophyCategories())

// Mounted Trophies: HP/Armor per set completion
var int SkillMountedHP;
var int SkillMountedArmor;

// Carrion Harvest: heal on trophy collection
var int SkillCarrionHealHP;
var int SkillCarrionHealArmor;

// Trophy Shield: damage reduction based on trophy count (read by skill)
// (No variable needed here - skill reads TotalTrophies)

// Wild Hunt: every Nth trophy transforms
var int SkillWildHuntInterval;
var int SkillWildHuntCounter;

// ===================================================================
// INITIALIZATION
// ===================================================================

simulated event PostBeginPlay()
{
    Super.PostBeginPlay();
    Player = KFPawn_Human(Owner);
    ClearAll();
    `log("[DK_PREDATOR] Helper spawned for" @ Player @ "Owner:" @ Owner);
}

function SetPerkLevel(int NewLevel)
{
    PerkLevel = NewLevel;

    if (PerkLevel >= class'ZTConfig_Capstone'.default.Capstone_Rank2Level)
        SetBonusMultiplier = 2.0f;
    else
        SetBonusMultiplier = 1.0f;

    RecalculateAllBonuses();
    ForceWeaponRecalc();
    SendDisplayUpdate();
}

function int GetMaxSets()
{
    return MAX_SETS_BASE;
}

function int GetMaxInventory()
{
    return MAX_INVENTORY + SkillExtraSlots;
}

function ClearAll()
{
    local int i;

    for (i = 0; i < NUM_CATEGORIES; ++i)
    {
        TrophyCount[i] = 0;
        bCategoryDropped[i] = 0;
    }

    LivePickups.Length = 0;
    TotalTrophies = 0;
    CompletedSets = 0;
    CompletedSetsCount = 0;
    bStackingPhase = False;
    NumStackSlotsFilled = 0;
    SetBonusMultiplier = 1.0f;

    AccAllDamage = 0.0f;
    AccLargeZedDamage = 0.0f;
    AccDamageResist = 0.0f;
    AccSpeed = 0.0f;
    AccReload = 0.0f;
    AccMeleeDamage = 0.0f;
    AccMagSize = 0.0f;
    AccWeaponSwitch = 0.0f;
    AccSpareAmmo = 0.0f;
    AccHeadshotDamage = 0.0f;
    bCanNotBeGrabbed = False;
    bCanSeeEnemyHealth = False;

    StackBonusHP = 0;
    StackBonusArmor = 0;
    StackBonusDosh = 0;
    AccBonusHP = 0;
    AccBonusArmor = 0;
    HealthMaxWithBonus = 0;
    MaxArmorWithBonus = 0;

    // Reset skill states (flags persist, counters reset)
    bFeedingFrenzyActive = False;
    bApexMarkActive = False;
    SkillWildHuntCounter = 0;

    SendDisplayUpdate();
}

// ===================================================================
// ZED KILLED - Roll for trophy drop (server only)
// ===================================================================

function OnZedKilled(KFPawn_Monster Victim)
{
    local byte Category;
    local float DropChance;
    local ZTTrophyPickup Pickup;
    local KFInventory_Money TempInv;
    local Vector Vel;
    local bool bIsBoss;

    if (Victim == None || Player == None)
        return;

    if (Player.Controller == None)
        return;

    Category = ClassifyZed(Victim);
    if (Category == 255)
        return;

    bIsBoss = (Category == CAT_BOSS);

    // --- APEX MARK: Boss kill triggers guaranteed drops for all zeds ---
    if (bIsBoss && SkillApexMarkDuration > 0.0f)
    {
        bApexMarkActive = True;
        ClearTimer('OnApexMarkExpired');
        SetTimer(SkillApexMarkDuration, False, 'OnApexMarkExpired');
        PlayPredatorSound('Predator_Legendary');
        `log("[DK_PREDATOR] APEX MARK activated for" @ SkillApexMarkDuration @ "seconds!");
    }

    // --- SET PHASE ---
    if (!bStackingPhase)
    {
        if (TotalTrophies >= GetMaxInventory())
            return;

        if (CompletedSetsCount >= GetMaxSets())
            return;

        if (TrophyCount[Category] > 0)
            return;

        if (bCategoryDropped[Category] != 0)
            return;
    }
    // --- STACKING PHASE ---
    else
    {
        if (NumStackSlotsFilled >= GetMaxInventory() && TrophyCount[Category] == 0)
            return;

        if (bCategoryDropped[Category] != 0)
            return;
    }

    // --- DROP CHANCE ---
    if (bApexMarkActive)
    {
        DropChance = 1.0f;
    }
    else
    {
        DropChance = GetDropChance();
    }

    if (FRand() > DropChance)
        return;

    // --- Spawn pickup ---
    Pickup = Spawn(class'ZTTrophyPickup', Player.Controller, , Victim.Location, , , True);
    TempInv = Spawn(class'KFInventory_Money');

    if (Pickup != None && TempInv != None)
    {
        Vel.X = TROPHY_VELOCITY_XY * (FRand() - 0.5f);
        Vel.Y = TROPHY_VELOCITY_XY * (FRand() - 0.5f);
        Vel.Z = TROPHY_VELOCITY_Z * (0.5f * FRand() + 0.5f);

        Pickup.SetPhysics(PHYS_Falling);
        Pickup.Velocity = Vel;
        Pickup.Inventory = TempInv;
        Pickup.InventoryClass = TempInv.class;
        Pickup.SetPickupMesh(TempInv.default.DroppedPickupMesh);
        Pickup.SetPickupParticles(TempInv.default.DroppedPickupParticles);

        Pickup.CashAmount = 0;
        Pickup.TrophyCategory = Category;
        Pickup.OwnerPawn = Player;
        Pickup.OwnerHelper = self;

        // Trophy Magnetism: extend pickup lifetime
        if (bSkillExtendPickupLife)
            Pickup.LifeSpan = Pickup.LifeSpan * 2.0f;

        bCategoryDropped[Category] = 1;
        LivePickups.AddItem(Pickup);

        PlayPredatorSound('Predator_Trophy_Drop');
        `log("[DK_PREDATOR] Trophy drop! Category:" @ Category @ "Phase:" @ (bStackingPhase ? "STACK" : "SET") @ "Chance:" @ DropChance);
    }
    else
    {
        if (Pickup != None)
            Pickup.Destroy();
        if (TempInv != None)
            TempInv.Destroy();

        `log("[DK_PREDATOR] Trophy spawn FAILED at" @ Victim.Location);
    }
}

// ===================================================================
// DROP CHANCE
// ===================================================================

function float GetDropChance()
{
    local float Chance;

    Chance = BASE_DROP_CHANCE + DROP_CHANCE_PER_LEVEL * float(Clamp(PerkLevel - 1, 0, 19));

    if (PerkLevel >= class'ZTConfig_Capstone'.default.Capstone_Rank1Level && PerkLevel < class'ZTConfig_Capstone'.default.Capstone_Rank2Level)
        Chance *= 2.0f;

    if (PerkLevel >= class'ZTConfig_Capstone'.default.Capstone_Rank2Level)
        Chance = MAX_DROP_CHANCE;

    return FMin(Chance, MAX_DROP_CHANCE);
}

// ===================================================================
// TROPHY COLLECTION (called by ZTTrophyPickup)
// ===================================================================

function CollectTrophy(byte Category)
{
    local byte TransformedCategory;

    if (Category >= NUM_CATEGORIES)
    {
        `log("[DK_PREDATOR] CollectTrophy ABORT: bad category" @ Category);
        return;
    }

    // --- SET PHASE ---
    if (!bStackingPhase)
    {
        if (TotalTrophies >= GetMaxInventory())
        {
            `log("[DK_PREDATOR] CollectTrophy ABORT: inventory full" @ TotalTrophies);
            return;
        }

        if (CompletedSetsCount >= GetMaxSets())
        {
            `log("[DK_PREDATOR] CollectTrophy ABORT: max sets reached" @ CompletedSetsCount);
            return;
        }

        if (TrophyCount[Category] > 0)
        {
            `log("[DK_PREDATOR] CollectTrophy ABORT: already holding category" @ Category);
            return;
        }

        TrophyCount[Category] += 1;
        TotalTrophies += 1;

        // --- WILD HUNT: Transform every Nth trophy ---
        if (SkillWildHuntInterval > 0)
        {
            SkillWildHuntCounter += 1;
            if (SkillWildHuntCounter >= SkillWildHuntInterval)
            {
                SkillWildHuntCounter = 0;
                TransformedCategory = GetBestWildHuntCategory(Category);
                if (TransformedCategory != Category && TransformedCategory < NUM_CATEGORIES)
                {
                    TrophyCount[Category] -= 1;
                    TrophyCount[TransformedCategory] += 1;
                    PlayPredatorSound('Predator_Tier3_Complete');
                    `log("[DK_PREDATOR] WILD HUNT transformed" @ Category @ "->" @ TransformedCategory);
                    Category = TransformedCategory;
                }
            }
        }

        `log("[DK_PREDATOR] [SET PHASE] Collected category:" @ Category @ "Total:" @ TotalTrophies);

        PlayPredatorSound('Predator_Trophy_Collect');

        // --- CARRION HARVEST ---
        ApplyCarrionHarvest();

        // --- FEEDING FRENZY ---
        ActivateFeedingFrenzy();

        // Check set completions
        CheckAllSets();

        // Check stacking transition
        if (CompletedSetsCount >= GetMaxSets() && !bStackingPhase)
        {
            EnterStackingPhase();
        }
    }
    // --- STACKING PHASE ---
    else
    {
        if (TrophyCount[Category] == 0 && NumStackSlotsFilled >= GetMaxInventory())
        {
            `log("[DK_PREDATOR] CollectTrophy ABORT: all" @ GetMaxInventory() @ "stack slots filled, can't add new category");
            return;
        }

        if (TrophyCount[Category] == 0)
            NumStackSlotsFilled += 1;

        TrophyCount[Category] += 1;
        TotalTrophies += 1;

        // --- WILD HUNT: Bonus duplicate every Nth trophy (stacking phase) ---
        // The hunt's bounty grows — periodically collect 2-for-1
        if (SkillWildHuntInterval > 0)
        {
            SkillWildHuntCounter += 1;
            if (SkillWildHuntCounter >= SkillWildHuntInterval)
            {
                SkillWildHuntCounter = 0;
                TrophyCount[Category] += 1;
                TotalTrophies += 1;
                PlayPredatorSound('Predator_Tier3_Complete');
                `log("[DK_PREDATOR] WILD HUNT (stack) bonus duplicate! Category:" @ Category @ "Count:" @ TrophyCount[Category]);
            }
        }

        // --- TAXIDERMIST: Chance to spread a bonus trophy (stacking phase) ---
        // Preserved specimens breed more specimens
        ApplyTaxidermistStackBonus(Category);

        `log("[DK_PREDATOR] [STACK PHASE] Collected category:" @ Category @ "Count:" @ TrophyCount[Category] @ "Slots:" @ NumStackSlotsFilled);

        PlayPredatorSound('Predator_Trophy_Collect');

        // --- CARRION HARVEST ---
        ApplyCarrionHarvest();

        // --- FEEDING FRENZY ---
        ActivateFeedingFrenzy();
    }

    // Recalculate all bonuses (computes AccBonusHP/AccBonusArmor)
    RecalculateAllBonuses();

    // Force weapon stat recalculation (mag/ammo) and re-apply HP/Armor
    ForceWeaponRecalc();

    `log("[DK_PREDATOR] About to call SendDisplayUpdate. TotalTrophies:" @ TotalTrophies @ "CompletedSets:" @ CompletedSets);
    SendDisplayUpdate();
}

// ===================================================================
// TROPHY DISCARD (player exec command)
// ===================================================================

static function string GetCategoryName(byte Cat)
{
    switch (Cat)
    {
        case 0:  return "Clot";
        case 1:  return "Crawler";
        case 2:  return "Gorefast";
        case 3:  return "Stalker";
        case 4:  return "Bloat";
        case 5:  return "Husk";
        case 6:  return "Siren";
        case 7:  return "EDAR";
        case 8:  return "Scrake";
        case 9:  return "Fleshpound";
        case 10: return "Boss";
        default: return "Unknown";
    }
}

static function byte CategoryFromName(string InName)
{
    if (InName ~= "clot")        return 0;
    if (InName ~= "crawler")     return 1;
    if (InName ~= "gorefast")    return 2;
    if (InName ~= "stalker")     return 3;
    if (InName ~= "bloat")       return 4;
    if (InName ~= "husk")        return 5;
    if (InName ~= "siren")       return 6;
    if (InName ~= "edar")        return 7;
    if (InName ~= "scrake")      return 8;
    if (InName ~= "fleshpound" || InName ~= "fp") return 9;
    if (InName ~= "boss")        return 10;
    return 255;
}

function bool DiscardTrophy(byte Category)
{
    if (Category >= NUM_CATEGORIES)
        return False;

    if (TrophyCount[Category] == 0)
        return False;

    TrophyCount[Category] -= 1;
    TotalTrophies -= 1;

    if (bStackingPhase && TrophyCount[Category] == 0)
        NumStackSlotsFilled -= 1;

    `log("[DK_PREDATOR] Trophy discarded: category" @ Category @ "(" $ GetCategoryName(Category) $ ") Remaining:" @ TrophyCount[Category]);

    RecalculateAllBonuses();
    ForceWeaponRecalc();
    SendDisplayUpdate();

    return True;
}

function int DiscardAllTrophies()
{
    local int i, Discarded;

    Discarded = TotalTrophies;

    for (i = 0; i < NUM_CATEGORIES; ++i)
    {
        TrophyCount[i] = 0;
    }
    TotalTrophies = 0;
    NumStackSlotsFilled = 0;

    `log("[DK_PREDATOR] All trophies discarded (" $ Discarded $ ")");

    RecalculateAllBonuses();
    ForceWeaponRecalc();
    SendDisplayUpdate();

    return Discarded;
}

function string GetInventoryString()
{
    local string S;
    local int i;

    S = "";
    for (i = 0; i < NUM_CATEGORIES; ++i)
    {
        if (TrophyCount[i] > 0)
        {
            if (S != "")
                S $= ", ";
            S $= GetCategoryName(byte(i)) @ "x" $ TrophyCount[i];
        }
    }

    if (S == "")
        S = "(empty)";

    return S;
}

// ===================================================================
// SET DISCARD
// ===================================================================

static function string GetSetName(int SetIndex)
{
    switch (SetIndex)
    {
        case 0:  return "Swarm Breaker";
        case 1:  return "Blade Collector";
        case 2:  return "Freak Show";
        case 3:  return "Salvage Run";
        case 4:  return "Big Game";
        case 5:  return "Full Sweep";
        case 6:  return "Night Stalker";
        case 7:  return "Brute Force";
        case 8:  return "King Slayer";
        case 9:  return "Apex Predator";
        case 10: return "Trophy Wall";
        case 11: return "Legendary Hunter";
        default: return "Unknown";
    }
}

static function int SetFromName(string InName)
{
    if (InName ~= "swarm" || InName ~= "swarmbreaker")       return 0;
    if (InName ~= "blade" || InName ~= "bladecollector")     return 1;
    if (InName ~= "freak" || InName ~= "freakshow")           return 2;
    if (InName ~= "salvage" || InName ~= "salvagerun")       return 3;
    if (InName ~= "biggame" || InName ~= "big")              return 4;
    if (InName ~= "sweep" || InName ~= "fullsweep")           return 5;
    if (InName ~= "night" || InName ~= "nightstalker")       return 6;
    if (InName ~= "brute" || InName ~= "bruteforce")         return 7;
    if (InName ~= "king" || InName ~= "kingslayer")           return 8;
    if (InName ~= "apex" || InName ~= "apexpredator")        return 9;
    if (InName ~= "wall" || InName ~= "trophywall")           return 10;
    if (InName ~= "legendary" || InName ~= "legendaryhunter") return 11;
    return INDEX_NONE;
}

function bool DiscardSet(int SetIndex)
{
    if (SetIndex < 0 || SetIndex > 11)
        return False;

    if (!IsSetCompleted(SetIndex))
        return False;

    // Clear the set bit
    CompletedSets = CompletedSets & ~(1 << SetIndex);
    CompletedSetsCount -= 1;

    // If we were in stacking phase and now below max sets, revert to set phase
    if (bStackingPhase && CompletedSetsCount < GetMaxSets())
    {
        bStackingPhase = False;
        NumStackSlotsFilled = 0;
        `log("[DK_PREDATOR] Reverted to SET PHASE after discarding set" @ SetIndex);
    }

    `log("[DK_PREDATOR] Set discarded:" @ GetSetName(SetIndex) @ "| Remaining sets:" @ CompletedSetsCount);

    RecalculateAllBonuses();
    ForceWeaponRecalc();
    SendDisplayUpdate();

    return True;
}

function string GetCompletedSetsString()
{
    local string S;
    local int i;

    S = "";
    for (i = 0; i <= 11; ++i)
    {
        if (IsSetCompleted(i))
        {
            if (S != "")
                S $= ", ";
            S $= GetSetName(i);
        }
    }

    if (S == "")
        S = "(none)";

    return S;
}

// ===================================================================
// SKILL: CARRION HARVEST
// ===================================================================

function ApplyCarrionHarvest()
{
    local int HealAmount;
    local int ArmorAmount;
    local WMPawn_Human WMPH;

    if (SkillCarrionHealHP <= 0 || Player == None)
        return;

    WMPH = WMPawn_Human(Player);
    if (WMPH == None)
        return;

    // Compute how much HP can actually be healed
    HealAmount = Clamp(WMPH.HealthMax - WMPH.Health, 0, SkillCarrionHealHP);

    if (HealAmount > 0)
    {
        WMPH.Health += HealAmount;
        `log("[DK_PREDATOR] Carrion Harvest healed" @ HealAmount @ "HP (now" @ WMPH.Health $ "/" $ WMPH.HealthMax $ ")");

        // If we topped off HP but didn't use the full heal value,
        // grant leftover as armor (partial overflow)
        if (HealAmount < SkillCarrionHealHP && SkillCarrionHealArmor > 0 && WMPH.ZedternalArmor < WMPH.ZedternalMaxArmor)
        {
            ArmorAmount = Min(SkillCarrionHealArmor, WMPH.ZedternalMaxArmor - WMPH.ZedternalArmor);
            WMPH.AddArmor(ArmorAmount);
            `log("[DK_PREDATOR] Carrion Harvest overflow +" @ ArmorAmount @ "Armor (now" @ WMPH.ZedternalArmor $ "/" $ WMPH.ZedternalMaxArmor $ ")");
        }
    }
    else
    {
        // Already at full HP — grant armor instead
        if (SkillCarrionHealArmor > 0 && WMPH.ZedternalArmor < WMPH.ZedternalMaxArmor)
        {
            ArmorAmount = Min(SkillCarrionHealArmor, WMPH.ZedternalMaxArmor - WMPH.ZedternalArmor);
            WMPH.AddArmor(ArmorAmount);
            `log("[DK_PREDATOR] Carrion Harvest +" @ ArmorAmount @ "Armor (full HP," @ WMPH.ZedternalArmor $ "/" $ WMPH.ZedternalMaxArmor $ ")");
        }
        else
        {
            `log("[DK_PREDATOR] Carrion Harvest: no effect (HP" @ WMPH.Health $ "/" $ WMPH.HealthMax @ "Armor" @ WMPH.ZedternalArmor $ "/" $ WMPH.ZedternalMaxArmor $ ")");
        }
    }
}

// ===================================================================
// SKILL: FEEDING FRENZY
// ===================================================================

function ActivateFeedingFrenzy()
{
    if (SkillFeedingFrenzyBonus <= 0.0f)
        return;

    bFeedingFrenzyActive = True;
    ClearTimer('OnFeedingFrenzyExpired');
    SetTimer(SkillFeedingFrenzyDuration, False, 'OnFeedingFrenzyExpired');
    `log("[DK_PREDATOR] Feeding Frenzy activated! +" $ int(SkillFeedingFrenzyBonus * 100.0f) $ "% fire rate");
}

function OnFeedingFrenzyExpired()
{
    bFeedingFrenzyActive = False;
    `log("[DK_PREDATOR] Feeding Frenzy expired");
    SendDisplayUpdate();
}

// ===================================================================
// SKILL: APEX MARK
// ===================================================================

function OnApexMarkExpired()
{
    bApexMarkActive = False;
    `log("[DK_PREDATOR] Apex Mark expired");
}

// ===================================================================
// SKILL: TROPHY MAGNETISM
// ===================================================================

function StartMagnetismTimer()
{
    if (SkillMagnetRange > 0.0f && !IsTimerActive('TickMagnetism'))
    {
        SetTimer(0.5f, True, 'TickMagnetism');
        `log("[DK_PREDATOR] Magnetism timer started, range:" @ SkillMagnetRange);
    }
}

function TickMagnetism()
{
    local int i;
    local ZTTrophyPickup Pickup;
    local float Dist;
    local Vector Dir;

    if (Player == None || SkillMagnetRange <= 0.0f)
        return;

    for (i = 0; i < LivePickups.Length; ++i)
    {
        Pickup = LivePickups[i];
        if (Pickup == None)
            continue;

        Dist = VSize(Pickup.Location - Player.Location);
        if (Dist <= SkillMagnetRange && Dist > 50.0f)
        {
            Dir = Normal(Player.Location - Pickup.Location);
            Pickup.SetPhysics(PHYS_Projectile);
            Pickup.Velocity = Dir * 600.0f;
        }
    }
}

// ===================================================================
// SKILL: WILD HUNT - Transformation helpers
// ===================================================================

function byte GetBestWildHuntCategory(byte OriginalCategory)
{
    local int i;
    local int BestScore, Score;
    local byte BestCat;

    BestScore = -1;
    BestCat = OriginalCategory;

    for (i = 0; i < NUM_CATEGORIES; ++i)
    {
        if (byte(i) == OriginalCategory)
            continue;
        if (TrophyCount[i] > 0)
            continue;

        Score = CountSetParticipation(byte(i));
        if (Score > BestScore)
        {
            BestScore = Score;
            BestCat = byte(i);
        }
    }

    return BestCat;
}

function int CountSetParticipation(byte Cat)
{
    local int Count;

    Count = 0;

    // Tier 1 pairs
    if ((Cat == CAT_CLOT || Cat == CAT_CRAWLER) && !IsSetCompleted(SET_SWARM_BREAKER))
        Count += 1;
    if ((Cat == CAT_GOREFAST || Cat == CAT_STALKER) && !IsSetCompleted(SET_BLADE_COLLECTOR))
        Count += 1;
    if ((Cat == CAT_SIREN || Cat == CAT_HUSK) && !IsSetCompleted(SET_FREAK_SHOW))
        Count += 1;
    if ((Cat == CAT_EDAR || Cat == CAT_BLOAT) && !IsSetCompleted(SET_SALVAGE_RUN))
        Count += 1;
    if ((Cat == CAT_SCRAKE || Cat == CAT_FLESHPOUND) && !IsSetCompleted(SET_BIG_GAME))
        Count += 1;

    // Tier 2 triples (weighted more)
    if ((Cat == CAT_CLOT || Cat == CAT_GOREFAST || Cat == CAT_CRAWLER) && !IsSetCompleted(SET_FULL_SWEEP))
        Count += 2;
    if ((Cat == CAT_STALKER || Cat == CAT_SIREN || Cat == CAT_EDAR) && !IsSetCompleted(SET_NIGHT_STALKER))
        Count += 2;
    if ((Cat == CAT_HUSK || Cat == CAT_SCRAKE || Cat == CAT_FLESHPOUND) && !IsSetCompleted(SET_BRUTE_FORCE))
        Count += 2;

    // Tier 3 boss pairs (weighted heavily)
    if (Cat == CAT_BOSS)
    {
        if (!IsSetCompleted(SET_KING_SLAYER))
            Count += 3;
        if (!IsSetCompleted(SET_APEX_PREDATOR))
            Count += 3;
        if (!IsSetCompleted(SET_TROPHY_WALL))
            Count += 3;
        if (!IsSetCompleted(SET_LEGENDARY_HUNTER))
            Count += 4;
    }
    if (Cat == CAT_FLESHPOUND && !IsSetCompleted(SET_KING_SLAYER))
        Count += 3;
    if (Cat == CAT_SCRAKE && !IsSetCompleted(SET_APEX_PREDATOR))
        Count += 3;

    return Count;
}

function byte GetLowestStackCategory(byte OriginalCategory)
{
    local int i;
    local byte BestCat;
    local byte LowestCount;

    BestCat = OriginalCategory;
    LowestCount = 255;

    for (i = 0; i < NUM_CATEGORIES; ++i)
    {
        if (byte(i) == OriginalCategory)
            continue;
        if (TrophyCount[i] == 0)
            continue;

        if (TrophyCount[i] < LowestCount)
        {
            LowestCount = TrophyCount[i];
            BestCat = byte(i);
        }
    }

    return BestCat;
}

// ===================================================================
// SKILL: DIVERSIFIED COLLECTION - Count unique categories
// ===================================================================

simulated function int CountUniqueTrophyCategories()
{
    local int i, Count;

    Count = 0;
    for (i = 0; i < NUM_CATEGORIES; ++i)
    {
        if (TrophyCount[i] > 0)
            Count += 1;
    }

    return Count;
}

// ===================================================================
// STACKING PHASE TRANSITION
// ===================================================================

function EnterStackingPhase()
{
    bStackingPhase = True;
    NumStackSlotsFilled = CountFilledSlots();
    RecountTotalTrophies();
    `log("[DK_PREDATOR] === ENTERED STACKING PHASE === Leftover slots:" @ NumStackSlotsFilled @ "Leftover trophies:" @ TotalTrophies);
}

function byte CountFilledSlots()
{
    local int i;
    local byte Count;

    Count = 0;
    for (i = 0; i < NUM_CATEGORIES; ++i)
    {
        if (TrophyCount[i] > 0)
            Count += 1;
    }
    return Count;
}

function RecountTotalTrophies()
{
    local int i;

    TotalTrophies = 0;
    for (i = 0; i < NUM_CATEGORIES; ++i)
        TotalTrophies += int(TrophyCount[i]);
}

// ===================================================================
// PICKUP LIFECYCLE
// ===================================================================

function OnPickupDestroyed(ZTTrophyPickup Pickup)
{
    if (Pickup != None)
    {
        if (Pickup.TrophyCategory < NUM_CATEGORIES)
            bCategoryDropped[Pickup.TrophyCategory] = 0;

        LivePickups.RemoveItem(Pickup);
    }
}

function CleanupPickups()
{
    local int i;

    for (i = LivePickups.Length - 1; i >= 0; --i)
    {
        if (LivePickups[i] != None)
            LivePickups[i].Destroy();
    }
    LivePickups.Length = 0;
}

// ===================================================================
// SET COMPLETION with Taxidermist preservation
// ===================================================================

function int ConsumeWithPreservation(byte Category)
{
    if (SkillPreserveChance > 0.0f && FRand() < SkillPreserveChance)
    {
        `log("[DK_PREDATOR] TAXIDERMIST preserved trophy category:" @ Category);
        return 0;
    }

    TrophyCount[Category] -= 1;
    return 1;
}

function int ConsumeOneTrashWithPreservation()
{
    local int i;

    for (i = 0; i <= 7; ++i)
    {
        if (TrophyCount[i] > 0)
            return ConsumeWithPreservation(byte(i));
    }
    return 0;
}

/** Taxidermist stacking phase: X% chance to add +1 to a random OTHER
 *  held category. Only targets categories with count > 0 so it won't
 *  open new stack slots. */
function ApplyTaxidermistStackBonus(byte CollectedCategory)
{
    local array<byte> HeldCategories;
    local int i;
    local byte BonusCat;

    if (SkillPreserveChance <= 0.0f || !bStackingPhase)
        return;

    if (FRand() >= SkillPreserveChance)
        return;

    // Build list of OTHER categories we currently hold
    for (i = 0; i < NUM_CATEGORIES; ++i)
    {
        if (byte(i) != CollectedCategory && TrophyCount[i] > 0)
            HeldCategories.AddItem(byte(i));
    }

    if (HeldCategories.Length == 0)
        return;

    BonusCat = HeldCategories[Rand(HeldCategories.Length)];
    TrophyCount[BonusCat] += 1;
    TotalTrophies += 1;
    PlayPredatorSound('Predator_Set_Complete');
    `log("[DK_PREDATOR] TAXIDERMIST (stack) bonus +1 to category:" @ BonusCat @ "Count:" @ TrophyCount[BonusCat]);
}

function CheckAllSets()
{
    local bool bAnyCompleted;
    local int Consumed;
    local int MaxSets;

    MaxSets = GetMaxSets();
    bAnyCompleted = True;

    while (bAnyCompleted)
    {
        bAnyCompleted = False;

        if (CompletedSetsCount >= MaxSets)
            return;

        // --- TIER 4: Legendary Hunter (Boss + Boss) ---
        if (!IsSetCompleted(SET_LEGENDARY_HUNTER) && TrophyCount[CAT_BOSS] >= 2)
        {
            Consumed = 0;
            Consumed += ConsumeWithPreservation(CAT_BOSS);
            Consumed += ConsumeWithPreservation(CAT_BOSS);
            TotalTrophies -= Consumed;
            CompleteSet(SET_LEGENDARY_HUNTER);
            PlayPredatorSound('Predator_Legendary');
            bAnyCompleted = True;
            continue;
        }

        // --- TIER 3: King Slayer (Boss + FP) ---
        if (!IsSetCompleted(SET_KING_SLAYER) && TrophyCount[CAT_BOSS] >= 1 && TrophyCount[CAT_FLESHPOUND] >= 1)
        {
            Consumed = 0;
            Consumed += ConsumeWithPreservation(CAT_BOSS);
            Consumed += ConsumeWithPreservation(CAT_FLESHPOUND);
            TotalTrophies -= Consumed;
            CompleteSet(SET_KING_SLAYER);
            PlayPredatorSound('Predator_Tier3_Complete');
            bAnyCompleted = True;
            continue;
        }

        // --- TIER 3: Apex Predator (Boss + Scrake) ---
        if (!IsSetCompleted(SET_APEX_PREDATOR) && TrophyCount[CAT_BOSS] >= 1 && TrophyCount[CAT_SCRAKE] >= 1)
        {
            Consumed = 0;
            Consumed += ConsumeWithPreservation(CAT_BOSS);
            Consumed += ConsumeWithPreservation(CAT_SCRAKE);
            TotalTrophies -= Consumed;
            CompleteSet(SET_APEX_PREDATOR);
            PlayPredatorSound('Predator_Tier3_Complete');
            bAnyCompleted = True;
            continue;
        }

        // --- TIER 3: Trophy Wall (Boss + trash) ---
        if (!IsSetCompleted(SET_TROPHY_WALL) && TrophyCount[CAT_BOSS] >= 1 && HasAnyTrashTrophy())
        {
            Consumed = 0;
            Consumed += ConsumeWithPreservation(CAT_BOSS);
            Consumed += ConsumeOneTrashWithPreservation();
            TotalTrophies -= Consumed;
            CompleteSet(SET_TROPHY_WALL);
            PlayPredatorSound('Predator_Tier3_Complete');
            bAnyCompleted = True;
            continue;
        }

        // --- TIER 2: Full Sweep (Clot + Gorefast + Crawler) ---
        if (!IsSetCompleted(SET_FULL_SWEEP) && TrophyCount[CAT_CLOT] >= 1 && TrophyCount[CAT_GOREFAST] >= 1 && TrophyCount[CAT_CRAWLER] >= 1)
        {
            Consumed = 0;
            Consumed += ConsumeWithPreservation(CAT_CLOT);
            Consumed += ConsumeWithPreservation(CAT_GOREFAST);
            Consumed += ConsumeWithPreservation(CAT_CRAWLER);
            TotalTrophies -= Consumed;
            CompleteSet(SET_FULL_SWEEP);
            PlayPredatorSound('Predator_Set_Complete');
            bAnyCompleted = True;
            continue;
        }

        // --- TIER 2: Night Stalker (Stalker + Siren + EDAR) ---
        if (!IsSetCompleted(SET_NIGHT_STALKER) && TrophyCount[CAT_STALKER] >= 1 && TrophyCount[CAT_SIREN] >= 1 && TrophyCount[CAT_EDAR] >= 1)
        {
            Consumed = 0;
            Consumed += ConsumeWithPreservation(CAT_STALKER);
            Consumed += ConsumeWithPreservation(CAT_SIREN);
            Consumed += ConsumeWithPreservation(CAT_EDAR);
            TotalTrophies -= Consumed;
            CompleteSet(SET_NIGHT_STALKER);
            PlayPredatorSound('Predator_Set_Complete');
            bAnyCompleted = True;
            continue;
        }

        // --- TIER 2: Brute Force (Husk + Scrake + FP) ---
        if (!IsSetCompleted(SET_BRUTE_FORCE) && TrophyCount[CAT_HUSK] >= 1 && TrophyCount[CAT_SCRAKE] >= 1 && TrophyCount[CAT_FLESHPOUND] >= 1)
        {
            Consumed = 0;
            Consumed += ConsumeWithPreservation(CAT_HUSK);
            Consumed += ConsumeWithPreservation(CAT_SCRAKE);
            Consumed += ConsumeWithPreservation(CAT_FLESHPOUND);
            TotalTrophies -= Consumed;
            CompleteSet(SET_BRUTE_FORCE);
            PlayPredatorSound('Predator_Set_Complete');
            bAnyCompleted = True;
            continue;
        }

        // --- TIER 1: Swarm Breaker (Clot + Crawler) ---
        if (!IsSetCompleted(SET_SWARM_BREAKER) && TrophyCount[CAT_CLOT] >= 1 && TrophyCount[CAT_CRAWLER] >= 1)
        {
            Consumed = 0;
            Consumed += ConsumeWithPreservation(CAT_CLOT);
            Consumed += ConsumeWithPreservation(CAT_CRAWLER);
            TotalTrophies -= Consumed;
            CompleteSet(SET_SWARM_BREAKER);
            PlayPredatorSound('Predator_Set_Complete');
            bAnyCompleted = True;
            continue;
        }

        // --- TIER 1: Blade Collector (Gorefast + Stalker) ---
        if (!IsSetCompleted(SET_BLADE_COLLECTOR) && TrophyCount[CAT_GOREFAST] >= 1 && TrophyCount[CAT_STALKER] >= 1)
        {
            Consumed = 0;
            Consumed += ConsumeWithPreservation(CAT_GOREFAST);
            Consumed += ConsumeWithPreservation(CAT_STALKER);
            TotalTrophies -= Consumed;
            CompleteSet(SET_BLADE_COLLECTOR);
            PlayPredatorSound('Predator_Set_Complete');
            bAnyCompleted = True;
            continue;
        }

        // --- TIER 1: Freak Show (Siren + Husk) ---
        if (!IsSetCompleted(SET_FREAK_SHOW) && TrophyCount[CAT_SIREN] >= 1 && TrophyCount[CAT_HUSK] >= 1)
        {
            Consumed = 0;
            Consumed += ConsumeWithPreservation(CAT_SIREN);
            Consumed += ConsumeWithPreservation(CAT_HUSK);
            TotalTrophies -= Consumed;
            CompleteSet(SET_FREAK_SHOW);
            PlayPredatorSound('Predator_Set_Complete');
            bAnyCompleted = True;
            continue;
        }

        // --- TIER 1: Salvage Run (EDAR + Bloat) ---
        if (!IsSetCompleted(SET_SALVAGE_RUN) && TrophyCount[CAT_EDAR] >= 1 && TrophyCount[CAT_BLOAT] >= 1)
        {
            Consumed = 0;
            Consumed += ConsumeWithPreservation(CAT_EDAR);
            Consumed += ConsumeWithPreservation(CAT_BLOAT);
            TotalTrophies -= Consumed;
            CompleteSet(SET_SALVAGE_RUN);
            PlayPredatorSound('Predator_Set_Complete');
            bAnyCompleted = True;
            continue;
        }

        // --- TIER 1: Big Game (Scrake + FP) ---
        if (!IsSetCompleted(SET_BIG_GAME) && TrophyCount[CAT_SCRAKE] >= 1 && TrophyCount[CAT_FLESHPOUND] >= 1)
        {
            Consumed = 0;
            Consumed += ConsumeWithPreservation(CAT_SCRAKE);
            Consumed += ConsumeWithPreservation(CAT_FLESHPOUND);
            TotalTrophies -= Consumed;
            CompleteSet(SET_BIG_GAME);
            PlayPredatorSound('Predator_Set_Complete');
            bAnyCompleted = True;
            continue;
        }
    }
}

// ===================================================================
// SET HELPERS
// ===================================================================

function bool IsSetCompleted(int SetIndex)
{
    return (CompletedSets & (1 << SetIndex)) != 0;
}

function CompleteSet(int SetIndex)
{
    CompletedSets = CompletedSets | (1 << SetIndex);
    CompletedSetsCount += 1;

    // HP/Armor from Mounted Trophies and Legendary Hunter are now
    // handled through AccBonusHP/AccBonusArmor in RecalculateAllBonuses.
    // No direct Player.HealthMax/MaxArmor manipulation needed here.

    RecalculateAllBonuses();
    `log("[DK_PREDATOR] SET COMPLETE:" @ SetIndex @ "| Total sets:" @ CompletedSetsCount @ "| AccBonusHP:" @ AccBonusHP @ "AccBonusArmor:" @ AccBonusArmor);
}

function bool HasAnyTrashTrophy()
{
    return TrophyCount[CAT_CLOT] > 0 || TrophyCount[CAT_CRAWLER] > 0
        || TrophyCount[CAT_GOREFAST] > 0 || TrophyCount[CAT_STALKER] > 0
        || TrophyCount[CAT_BLOAT] > 0 || TrophyCount[CAT_HUSK] > 0
        || TrophyCount[CAT_SIREN] > 0 || TrophyCount[CAT_EDAR] > 0;
}

// ===================================================================
// BONUS RECALCULATION
// ===================================================================

function RecalculateAllBonuses()
{
    local float M;
    local int BossStacks;
    local int EffStacks;

    M = SetBonusMultiplier;

    AccAllDamage = 0.0f;
    AccLargeZedDamage = 0.0f;
    AccDamageResist = 0.0f;
    AccSpeed = 0.0f;
    AccReload = 0.0f;
    AccMeleeDamage = 0.0f;
    AccMagSize = 0.0f;
    AccWeaponSwitch = 0.0f;
    AccSpareAmmo = 0.0f;
    AccHeadshotDamage = 0.0f;
    bCanNotBeGrabbed = False;
    bCanSeeEnemyHealth = False;
    StackBonusHP = 0;
    StackBonusArmor = 0;
    StackBonusDosh = 0;

    // --- TIER 1 ---
    if ((CompletedSets & (1 << SET_SWARM_BREAKER)) != 0)
        AccSpeed += 0.15f * M;
    if ((CompletedSets & (1 << SET_BLADE_COLLECTOR)) != 0)
        AccMeleeDamage += 0.30f * M;
    if ((CompletedSets & (1 << SET_FREAK_SHOW)) != 0)
        AccDamageResist += 0.10f * M;
    if ((CompletedSets & (1 << SET_SALVAGE_RUN)) != 0)
        AccReload += 0.25f * M;
    if ((CompletedSets & (1 << SET_BIG_GAME)) != 0)
        AccLargeZedDamage += 0.25f * M;

    // --- TIER 2 ---
    if ((CompletedSets & (1 << SET_FULL_SWEEP)) != 0)
        AccMagSize += 0.30f * M;
    if ((CompletedSets & (1 << SET_NIGHT_STALKER)) != 0)
        AccWeaponSwitch += 0.40f * M;
    if ((CompletedSets & (1 << SET_BRUTE_FORCE)) != 0)
        AccAllDamage += 0.20f * M;

    // --- TIER 3: King Slayer ---
    if ((CompletedSets & (1 << SET_KING_SLAYER)) != 0)
    {
        AccAllDamage += 0.50f * M;
        AccDamageResist += 0.15f * M;
        bCanNotBeGrabbed = True;
    }

    // --- TIER 3: Apex Predator ---
    if ((CompletedSets & (1 << SET_APEX_PREDATOR)) != 0)
    {
        AccAllDamage += 0.40f * M;
        AccSpeed += 0.30f * M;
        bCanSeeEnemyHealth = True;
    }

    // --- TIER 3: Trophy Wall ---
    if ((CompletedSets & (1 << SET_TROPHY_WALL)) != 0)
    {
        AccAllDamage += 0.30f * M;
        AccSpareAmmo += 0.50f * M;
        AccReload += 0.30f * M;
    }

    // --- TIER 4: Legendary Hunter ---
    if ((CompletedSets & (1 << SET_LEGENDARY_HUNTER)) != 0)
    {
        AccAllDamage += 0.75f * M;
        AccDamageResist += 0.25f * M;
        AccSpeed += 0.50f * M;
        bCanNotBeGrabbed = True;
        bCanSeeEnemyHealth = True;
    }

    // ===============================
    // STACKING BONUSES
    // ===============================

    if (bStackingPhase || CompletedSetsCount >= GetMaxSets())
    {
        BossStacks = int(TrophyCount[CAT_BOSS]);

        EffStacks = int(TrophyCount[CAT_CLOT]) + BossStacks;
        if (EffStacks > 0) StackBonusDosh = EffStacks * STACK_CLOT_DOSH;

        EffStacks = int(TrophyCount[CAT_CRAWLER]) + BossStacks;
        if (EffStacks > 0) AccSpeed += float(EffStacks) * STACK_CRAWLER_SPEED;

        EffStacks = int(TrophyCount[CAT_GOREFAST]) + BossStacks;
        if (EffStacks > 0) AccMeleeDamage += float(EffStacks) * STACK_GOREFAST_MELEE;

        EffStacks = int(TrophyCount[CAT_STALKER]) + BossStacks;
        if (EffStacks > 0) AccMagSize += float(EffStacks) * STACK_STALKER_MAGSIZE;

        EffStacks = int(TrophyCount[CAT_BLOAT]) + BossStacks;
        if (EffStacks > 0) StackBonusHP = EffStacks * STACK_BLOAT_HP;

        EffStacks = int(TrophyCount[CAT_HUSK]) + BossStacks;
        if (EffStacks > 0) AccDamageResist += float(EffStacks) * STACK_HUSK_RESIST;

        EffStacks = int(TrophyCount[CAT_SIREN]) + BossStacks;
        if (EffStacks > 0) AccSpareAmmo += float(EffStacks) * STACK_SIREN_AMMO;

        EffStacks = int(TrophyCount[CAT_EDAR]) + BossStacks;
        if (EffStacks > 0) AccHeadshotDamage = float(EffStacks) * STACK_EDAR_HEADSHOT;

        EffStacks = int(TrophyCount[CAT_SCRAKE]) + BossStacks;
        if (EffStacks > 0) StackBonusArmor = EffStacks * STACK_SCRAKE_ARMOR;

        EffStacks = int(TrophyCount[CAT_FLESHPOUND]) + BossStacks;
        if (EffStacks > 0) AccAllDamage += float(EffStacks) * STACK_FP_DAMAGE;
    }

    // ===============================
    // UNIFIED HP/ARMOR BONUSES
    // Combines all sources: stacking + mounted trophies + legendary
    // ===============================

    AccBonusHP = StackBonusHP;
    AccBonusArmor = StackBonusArmor;

    // Mounted Trophies: per-set HP/Armor bonus
    if (SkillMountedHP > 0)
        AccBonusHP += CompletedSetsCount * SkillMountedHP;
    if (SkillMountedArmor > 0)
        AccBonusArmor += CompletedSetsCount * SkillMountedArmor;

    // Legendary Hunter: +50 HP (scaled by Trophy Master multiplier)
    if ((CompletedSets & (1 << SET_LEGENDARY_HUNTER)) != 0)
        AccBonusHP += Round(50.0f * M);

    // Push replicated Acc* fields to owning client
    if (Role == ROLE_Authority)
        bForceNetUpdate = True;
}

// ===================================================================
// FORCE WEAPON RECALCULATION (Shapeshifter pattern)
//
// Calls WMPlayerController.UpdateWeaponMagAndCap() which:
//   1. Recalculates passive bonuses (ApplySkillsToPawn)
//   2. Reinitializes weapon ammo (reads AccMagSize, AccSpareAmmo)
//   3. Recalculates Health/HealthMax and MaxArmor from base
//
// After the WM recalc, we re-apply our HP/Armor bonuses directly
// since static ModifyHealth/ModifyArmor hooks lack pawn references.
// ===================================================================

function ForceWeaponRecalc()
{
    local WMPlayerController WMPC;

    if (Player == None || Player.Controller == None)
        return;

    WMPC = WMPlayerController(Player.Controller);
    if (WMPC != None)
    {
        WMPC.UpdateWeaponMagAndCap();

        // HP/Armor was just reset to base+hooks by UpdateWeaponMagAndCap.
        // Our AccBonusHP/AccBonusArmor are NOT included (no static hook).
        // Apply them directly now.
        ApplyHealthArmorBonuses();

        `log("[DK_PREDATOR] ForceWeaponRecalc complete. AccBonusHP:" @ AccBonusHP @ "AccBonusArmor:" @ AccBonusArmor @ "HealthMax:" @ Player.HealthMax);
    }

    // Start the watchdog timer to catch external resets
    StartHealthArmorWatchdog();
}

// ===================================================================
// HEALTH/ARMOR BONUS APPLICATION
//
// Directly modifies Player.HealthMax and WMPawn_Human.ZedternalMaxArmor.
// Records expected values for watchdog detection.
// Also heals current HP by the bonus amount.
// ===================================================================

function ApplyHealthArmorBonuses()
{
    local WMPawn_Human WMPH;

    if (Player == None)
        return;

    WMPH = WMPawn_Human(Player);

    if (AccBonusHP > 0)
    {
        Player.HealthMax += AccBonusHP;
        Player.Health = Min(Player.Health + AccBonusHP, Player.HealthMax);
    }

    if (AccBonusArmor > 0 && WMPH != None)
    {
        // Modify ZedternalMaxArmor (ZR's int armor system), NOT MaxArmor
        // MaxArmor is a display scalar (0-255) used by AdjustArmorPct()
        // Modifying it directly causes the armor bar to overflow for other players
        WMPH.ZedternalMaxArmor += AccBonusArmor;
        WMPH.AdjustArmorPct();
    }

    // Record expected values for watchdog
    HealthMaxWithBonus = Player.HealthMax;
    if (WMPH != None)
        MaxArmorWithBonus = WMPH.ZedternalMaxArmor;
    else
        MaxArmorWithBonus = Player.MaxArmor;

    `log("[DK_PREDATOR] ApplyHealthArmorBonuses: HP+" $ AccBonusHP @ "Armor+" $ AccBonusArmor @ "-> HealthMax:" @ Player.HealthMax @ "ZedternalMaxArmor:" @ WMPH.ZedternalMaxArmor);
}

// ===================================================================
// HEALTH/ARMOR WATCHDOG TIMER
//
// Detects when external code (UpdateWeaponMagAndCap from perk
// purchases, wave boundaries, etc.) resets HealthMax/MaxArmor
// and re-applies our bonus. Runs every 2 seconds on server.
// ===================================================================

function StartHealthArmorWatchdog()
{
    if (AccBonusHP > 0 || AccBonusArmor > 0)
    {
        if (!IsTimerActive('TickHealthArmorWatchdog'))
        {
            SetTimer(2.0f, True, 'TickHealthArmorWatchdog');
            `log("[DK_PREDATOR] Health/Armor watchdog started");
        }
    }
}

function StopHealthArmorWatchdog()
{
    ClearTimer('TickHealthArmorWatchdog');
}

function TickHealthArmorWatchdog()
{
    local WMPawn_Human WMPH;
    local int CurrentMaxArmor;

    if (Player == None)
    {
        StopHealthArmorWatchdog();
        return;
    }

    // No bonuses to apply
    if (AccBonusHP <= 0 && AccBonusArmor <= 0)
    {
        StopHealthArmorWatchdog();
        return;
    }

    // Read current armor from ZR system
    WMPH = WMPawn_Human(Player);
    if (WMPH != None)
        CurrentMaxArmor = WMPH.ZedternalMaxArmor;
    else
        CurrentMaxArmor = Player.MaxArmor;

    // If HealthMax or ZedternalMaxArmor changed from what we expect,
    // an external recalculation happened — re-apply our bonus
    if (Player.HealthMax != HealthMaxWithBonus || CurrentMaxArmor != MaxArmorWithBonus)
    {
        `log("[DK_PREDATOR] Watchdog detected HP/Armor reset. Expected HealthMax:" @ HealthMaxWithBonus @ "Actual:" @ Player.HealthMax @ "Expected MaxArmor:" @ MaxArmorWithBonus @ "Actual:" @ CurrentMaxArmor);
        ApplyHealthArmorBonuses();
    }
}

// ===================================================================
// ZED CLASSIFICATION
// ===================================================================

function byte ClassifyZed(KFPawn_Monster P)
{
    local string ClassName;

    if (P == None) return 255;
    if (P.static.IsABoss()) return CAT_BOSS;

    ClassName = string(P.Class.Name);

    if (InStr(ClassName, "Clot") != -1) return CAT_CLOT;
    if (InStr(ClassName, "Crawler") != -1) return CAT_CRAWLER;
    if (InStr(ClassName, "Gorefast") != -1 || InStr(ClassName, "GorefastDualBlade") != -1) return CAT_GOREFAST;
    if (InStr(ClassName, "Stalker") != -1) return CAT_STALKER;
    if (InStr(ClassName, "BloatKingSubspawn") != -1) return CAT_BLOAT;
    if (InStr(ClassName, "Bloat") != -1 && InStr(ClassName, "BloatKing") == -1) return CAT_BLOAT;
    if (InStr(ClassName, "Husk") != -1) return CAT_HUSK;
    if (InStr(ClassName, "Siren") != -1) return CAT_SIREN;
    if (InStr(ClassName, "DAR") != -1) return CAT_EDAR;
    if (InStr(ClassName, "Scrake") != -1) return CAT_SCRAKE;
    if (InStr(ClassName, "Fleshpound") != -1) return CAT_FLESHPOUND;

    // Custom ZedInject classes commonly inherit a vanilla archetype without
    // retaining its name. Fall back to ancestry so their kills still count.
    if (P.IsA('KFPawn_ZedCrawler')) return CAT_CRAWLER;
    if (P.IsA('KFPawn_ZedStalker')) return CAT_STALKER;
    if (P.IsA('KFPawn_ZedClot')) return CAT_CLOT;
    if (P.IsA('KFPawn_ZedGorefast')) return CAT_GOREFAST;
    if (P.IsA('KFPawn_ZedBloat')) return CAT_BLOAT;
    if (P.IsA('KFPawn_ZedHusk')) return CAT_HUSK;
    if (P.IsA('KFPawn_ZedSiren')) return CAT_SIREN;
    if (P.IsA('KFPawn_ZedDAR')) return CAT_EDAR;
    if (P.IsA('KFPawn_ZedScrake')) return CAT_SCRAKE;
    if (P.IsA('KFPawn_ZedFleshpound')) return CAT_FLESHPOUND;

    if (P.bLargeZed)
        return CAT_SCRAKE;

    return CAT_CLOT;
}

// ===================================================================
// CLIENT RPC
// ===================================================================

function SendDisplayUpdate()
{
    local int Pack1, Pack2, Pack3;

    `log("[DK_PREDATOR] SendDisplayUpdate called. TotalTrophies:" @ TotalTrophies @ "CompletedSetsCount:" @ CompletedSetsCount @ "Stacking:" @ bStackingPhase);

    RepTrophyCount[0] = TrophyCount[0];
    RepTrophyCount[1] = TrophyCount[1];
    RepTrophyCount[2] = TrophyCount[2];
    RepTrophyCount[3] = TrophyCount[3];
    RepTrophyCount[4] = TrophyCount[4];
    RepTrophyCount[5] = TrophyCount[5];
    RepTrophyCount[6] = TrophyCount[6];
    RepTrophyCount[7] = TrophyCount[7];
    RepTrophyCount[8] = TrophyCount[8];
    RepTrophyCount[9] = TrophyCount[9];
    RepTrophyCount[10] = TrophyCount[10];
    RepTotalTrophies = byte(Clamp(TotalTrophies, 0, 255));
    RepCompletedSets = CompletedSets;
    RepCompletedSetsCount = byte(Clamp(CompletedSetsCount, 0, 255));
    bRepTrophyMaster = PerkLevel >= class'ZTConfig_Capstone'.default.Capstone_Rank2Level;
    RepMaxSlots = byte(GetMaxInventory());
    RecalculateAllBonuses();

    `log("[DK_PREDATOR] Local update done. Calling PushToHUD...");
    PushToHUD();

    Pack1 = int(TrophyCount[0]) | (int(TrophyCount[1]) << 8) | (int(TrophyCount[2]) << 16) | (int(TrophyCount[3]) << 24);
    Pack2 = int(TrophyCount[4]) | (int(TrophyCount[5]) << 8) | (int(TrophyCount[6]) << 16) | (int(TrophyCount[7]) << 24);
    Pack3 = int(TrophyCount[8]) | (int(TrophyCount[9]) << 8) | (int(TrophyCount[10]) << 16);

    if (WorldInfo.NetMode != NM_Standalone)
    {
        ClientUpdatePredatorDisplay(Pack1, Pack2, Pack3,
            byte(Clamp(TotalTrophies, 0, 255)),
            CompletedSets,
            byte(Clamp(CompletedSetsCount, 0, 255)),
            PerkLevel >= class'ZTConfig_Capstone'.default.Capstone_Rank2Level,
            bStackingPhase,
            bFeedingFrenzyActive,
            AccHeadshotDamage,
            StackBonusHP, StackBonusArmor, StackBonusDosh,
            byte(GetMaxInventory()));
    }
}

reliable client function ClientUpdatePredatorDisplay(
    int TrophyPack1, int TrophyPack2, int TrophyPack3,
    byte InTotalTrophies, int InCompletedSets,
    byte InCompletedSetsCount, bool bInTrophyMaster,
    bool bInStackingPhase,
    bool bInFeedingFrenzy,
    float InAccHeadshotDamage,
    int InStackBonusHP, int InStackBonusArmor, int InStackBonusDosh,
    byte InMaxSlots)
{
    `log("[DK_PREDATOR] ClientUpdatePredatorDisplay RPC received. TotalTrophies:" @ InTotalTrophies @ "Stacking:" @ bInStackingPhase);

    RepTrophyCount[0] = byte(TrophyPack1 & 255);
    RepTrophyCount[1] = byte((TrophyPack1 >> 8) & 255);
    RepTrophyCount[2] = byte((TrophyPack1 >> 16) & 255);
    RepTrophyCount[3] = byte((TrophyPack1 >> 24) & 255);
    RepTrophyCount[4] = byte(TrophyPack2 & 255);
    RepTrophyCount[5] = byte((TrophyPack2 >> 8) & 255);
    RepTrophyCount[6] = byte((TrophyPack2 >> 16) & 255);
    RepTrophyCount[7] = byte((TrophyPack2 >> 24) & 255);
    RepTrophyCount[8] = byte(TrophyPack3 & 255);
    RepTrophyCount[9] = byte((TrophyPack3 >> 8) & 255);
    RepTrophyCount[10] = byte((TrophyPack3 >> 16) & 255);

    RepTotalTrophies = InTotalTrophies;
    RepCompletedSets = InCompletedSets;
    RepCompletedSetsCount = InCompletedSetsCount;
    bRepTrophyMaster = bInTrophyMaster;

    CompletedSets = InCompletedSets;
    CompletedSetsCount = int(InCompletedSetsCount);
    bStackingPhase = bInStackingPhase;
    bFeedingFrenzyActive = bInFeedingFrenzy;

    if (bInTrophyMaster)
        SetBonusMultiplier = 2.0f;
    else
        SetBonusMultiplier = 1.0f;

    TrophyCount[0] = RepTrophyCount[0];
    TrophyCount[1] = RepTrophyCount[1];
    TrophyCount[2] = RepTrophyCount[2];
    TrophyCount[3] = RepTrophyCount[3];
    TrophyCount[4] = RepTrophyCount[4];
    TrophyCount[5] = RepTrophyCount[5];
    TrophyCount[6] = RepTrophyCount[6];
    TrophyCount[7] = RepTrophyCount[7];
    TrophyCount[8] = RepTrophyCount[8];
    TrophyCount[9] = RepTrophyCount[9];
    TrophyCount[10] = RepTrophyCount[10];

    RepMaxSlots = InMaxSlots;

    RecalculateAllBonuses();
    PushToHUD();
}

// ===================================================================
// HUD PUSH
// ===================================================================

simulated function PushToHUD()
{
    local KFPlayerController KFPC;
    local ZTHudWrapper HUD;

    `log("[DK_PREDATOR] PushToHUD called. RepTotalTrophies:" @ RepTotalTrophies @ "Stacking:" @ bStackingPhase);

    KFPC = KFPlayerController(GetALocalPlayerController());
    if (KFPC == None)
    {
        `log("[DK_PREDATOR] PushToHUD ABORT: KFPC is None (expected on dedicated server)");
        return;
    }

    HUD = class'ZTHudWrapper'.static.GetReaperHUD(KFPC);
    if (HUD == None)
    {
        `log("[DK_PREDATOR] PushToHUD ABORT: HUD is None");
        return;
    }

    `log("[DK_PREDATOR] PushToHUD: Calling UpdatePredatorDisplay with TotalTrophies:" @ RepTotalTrophies @ "Sets:" @ RepCompletedSetsCount);

    HUD.UpdatePredatorDisplay(
        RepTrophyCount,
        RepTotalTrophies,
        RepCompletedSets,
        RepCompletedSetsCount,
        bRepTrophyMaster,
        bStackingPhase,
        AccAllDamage, AccLargeZedDamage, AccDamageResist,
        AccSpeed, AccReload, AccMeleeDamage, AccMagSize,
        AccWeaponSwitch, AccSpareAmmo, AccHeadshotDamage,
        StackBonusHP, StackBonusArmor, StackBonusDosh,
        bCanNotBeGrabbed, bCanSeeEnemyHealth,
        RepMaxSlots);
}

// ===================================================================
// SOUND HELPER
// ===================================================================

function PlayPredatorSound(name SoundID)
{
    local ZTPlayerController DKPC;
    local ZTMutator Mut;
    local SoundCue Sound;

    if (Player == None || Player.Controller == None)
        return;

    DKPC = ZTPlayerController(Player.Controller);
    if (DKPC == None)
        return;

    Mut = class'ZTSoundManager'.static.GetMutator(WorldInfo);
    if (Mut == None)
        return;

    Sound = class'ZTSoundManager'.static.GetSound(Mut, SoundID);
    if (Sound != None)
        DKPC.ClientPlayBuffSound(Sound);
}

// ===================================================================
// DEFAULT PROPERTIES
// ===================================================================

defaultproperties
{
    RemoteRole=ROLE_SimulatedProxy
    bAlwaysRelevant=False
    bOnlyRelevantToOwner=True
    bHidden=True
    bCollideActors=False
    bBlockActors=False

    PerkLevel=1
    TotalTrophies=0
    CompletedSets=0
    CompletedSetsCount=0
    bStackingPhase=False
    NumStackSlotsFilled=0
    SetBonusMultiplier=1.0f

    AccAllDamage=0.0f
    AccLargeZedDamage=0.0f
    AccDamageResist=0.0f
    AccSpeed=0.0f
    AccReload=0.0f
    AccMeleeDamage=0.0f
    AccMagSize=0.0f
    AccWeaponSwitch=0.0f
    AccSpareAmmo=0.0f
    AccHeadshotDamage=0.0f
    bCanNotBeGrabbed=False
    bCanSeeEnemyHealth=False
    StackBonusHP=0
    StackBonusArmor=0
    StackBonusDosh=0
    AccBonusHP=0
    AccBonusArmor=0
    HealthMaxWithBonus=0
    MaxArmorWithBonus=0

    RepMaxSlots=5

    SkillExtraSlots=0
    SkillFeedingFrenzyBonus=0.0f
    SkillFeedingFrenzyDuration=6.0f
    bFeedingFrenzyActive=False
    SkillPreserveChance=0.0f
    SkillMagnetRange=0.0f
    bSkillExtendPickupLife=False
    SkillApexMarkDuration=0.0f
    bApexMarkActive=False
    SkillMountedHP=0
    SkillMountedArmor=0
    SkillCarrionHealHP=0
    SkillCarrionHealArmor=0
    SkillWildHuntInterval=0
    SkillWildHuntCounter=0

    Name="Default__ZTUpgrade_Perk_Predator_Helper"
}
