/**
 * ZTRoguelikeUpgradeManager
 * Server-authoritative manager for the roguelike upgrade system.
 * Handles upgrade selection, rarity rolls, and player state tracking.
 *
 * UPDATED: Removed 5 universal uniques and 10 Eldritch character uniques (scrapped)
 * UPDATED: Added 46 Perk Unique upgrades — one per perk, requires perk ownership
 * UPDATED: Perk ownership check via ClassIsChildOf for wrapper compatibility
 */
class ZTRoguelikeUpgradeManager extends Actor;

//=============================================================================
// CONFIGURATION
//=============================================================================

var int UpgradeWaveInterval;
var int UpgradeOptionsCount;

//=============================================================================
// UPGRADE DATA STRUCTS (local copies for manager use)
//=============================================================================

enum ERoguelikeRarity
{
    RLR_Common,
    RLR_Uncommon,
    RLR_Rare,
    RLR_Epic,
    RLR_Legendary,
    RLR_Unique
};

enum ERoguelikePoolType
{
    RLPT_Universal,
    RLPT_Tree,
    RLPT_Character,
    RLPT_Perk
};

enum ERoguelikeStatType
{
    RLST_None,
    RLST_MaxHealth,
    RLST_MaxArmor,
    RLST_MovementSpeed,
    RLST_ReloadSpeed,
    RLST_AmmoCapacity,
    RLST_DamageDealt,
    RLST_DamageResist,
    RLST_LargeZedDamage,
    RLST_Luck,
    RLST_GlassCannon,
    RLST_Sumo,
    RLST_Opportunist,
    RLST_Duelist,
    RLST_Wealthy,
    RLST_LastRound,
    RLST_Special
};

struct RoguelikeUpgradeData
{
    var string UpgradeID;
    var string DisplayName;
    var string Description;
    var string IconPath;
    var ERoguelikeRarity Rarity;
    var ERoguelikePoolType PoolType;
    var byte TreeRequirement;
    var int CharacterRequirement;
    var string RequiredPerkName;
    var ERoguelikeStatType StatType;
    var float StatValue;
    var bool bIsPercentage;
    var bool bIsPassiveEffect;
};

//=============================================================================
// STATE TRACKING
//=============================================================================

var array<ZTPlayerController> PlayersInSelection;
var array<ZTPlayerController> PlayersCompletedSelection;

struct PendingUpgradeOptions
{
    var ZTPlayerController PC;
    var array<RoguelikeUpgradeData> Options;
};
var array<PendingUpgradeOptions> PendingOptions;

var bool bUpgradeSelectionActive;
var GameInfo OwningGameInfo;

//=============================================================================
// LATE-JOINER CATCH-UP
//=============================================================================

// Number of group selection events that have run this game. A late joiner is
// owed this many catch-up picks (snapshotted at the moment they join).
var int SelectionsHeldThisGame;

// Optional cap on catch-up picks (0 = unlimited). Set from ZTConfig_Roguelike.
var int CatchUpMaxSelections;

struct CatchUpEntry
{
    var ZTPlayerController PC;
    var int Remaining;   // catch-up picks still owed
    var bool bActive;    // a catch-up option set is currently shown to this player
};
var array<CatchUpEntry> CatchUpQueue;

//=============================================================================
// UPGRADE POOL DATA
//=============================================================================

var array<RoguelikeUpgradeData> UniversalUpgrades;
var array<RoguelikeUpgradeData> EldritchTreeUpgrades;
var array<RoguelikeUpgradeData> PerkUniques;

//=============================================================================
// INITIALIZATION
//=============================================================================

event PostBeginPlay()
{
    super.PostBeginPlay();
    LoadUpgradePools();
    `log("[DK_ROGUELIKE] ZTRoguelikeUpgradeManager spawned and ready");
    `log("[DK_ROGUELIKE] Loaded" @ UniversalUpgrades.Length @ "universal," @ EldritchTreeUpgrades.Length @ "eldritch tree," @ PerkUniques.Length @ "perk unique upgrades");
}

function LoadUpgradePools()
{
    local RoguelikeUpgradeData U;
    local array<string> AppliedOverrideIDs;

    // === Initialize struct defaults ===
    U.PoolType = RLPT_Universal;
    U.TreeRequirement = 0;
    U.CharacterRequirement = -1;
    U.RequiredPerkName = "";
    U.bIsPercentage = false;
    U.bIsPassiveEffect = false;

    // ========== HEALTH (All Rarities) ==========
    U.StatType = RLST_MaxHealth;
    U.bIsPercentage = false;

    U.UpgradeID = "UNIV_C_HEALTH"; U.DisplayName = "Toughness"; U.Description = "+5 Max Health";
    U.Rarity = RLR_Common; U.StatValue = 5.0; UniversalUpgrades.AddItem(U);

    U.UpgradeID = "UNIV_U_HEALTH"; U.DisplayName = "Vitality"; U.Description = "+10 Max Health";
    U.Rarity = RLR_Uncommon; U.StatValue = 10.0; UniversalUpgrades.AddItem(U);

    U.UpgradeID = "UNIV_R_HEALTH"; U.DisplayName = "Fortitude"; U.Description = "+15 Max Health";
    U.Rarity = RLR_Rare; U.StatValue = 15.0; UniversalUpgrades.AddItem(U);

    U.UpgradeID = "UNIV_E_HEALTH"; U.DisplayName = "Vigor"; U.Description = "+25 Max Health";
    U.Rarity = RLR_Epic; U.StatValue = 25.0; UniversalUpgrades.AddItem(U);

    U.UpgradeID = "UNIV_L_HEALTH"; U.DisplayName = "Titan's Constitution"; U.Description = "+40 Max Health";
    U.Rarity = RLR_Legendary; U.StatValue = 40.0; UniversalUpgrades.AddItem(U);

    // ========== ARMOR (All Rarities) ==========
    U.StatType = RLST_MaxArmor;

    U.UpgradeID = "UNIV_C_ARMOR"; U.DisplayName = "Thick Skin"; U.Description = "+5 Max Armor";
    U.Rarity = RLR_Common; U.StatValue = 5.0; UniversalUpgrades.AddItem(U);

    U.UpgradeID = "UNIV_U_ARMOR"; U.DisplayName = "Reinforced"; U.Description = "+10 Max Armor";
    U.Rarity = RLR_Uncommon; U.StatValue = 10.0; UniversalUpgrades.AddItem(U);

    U.UpgradeID = "UNIV_R_ARMOR"; U.DisplayName = "Hardened"; U.Description = "+15 Max Armor";
    U.Rarity = RLR_Rare; U.StatValue = 15.0; UniversalUpgrades.AddItem(U);

    U.UpgradeID = "UNIV_E_ARMOR"; U.DisplayName = "Armored"; U.Description = "+25 Max Armor";
    U.Rarity = RLR_Epic; U.StatValue = 25.0; UniversalUpgrades.AddItem(U);

    U.UpgradeID = "UNIV_L_ARMOR"; U.DisplayName = "Living Fortress"; U.Description = "+40 Max Armor";
    U.Rarity = RLR_Legendary; U.StatValue = 40.0; UniversalUpgrades.AddItem(U);

    // ========== SPEED (Rare+ Only) ==========
    U.StatType = RLST_MovementSpeed; U.bIsPercentage = true;

    U.UpgradeID = "UNIV_R_SPEED"; U.DisplayName = "Sprinter"; U.Description = "+8% Movement Speed";
    U.Rarity = RLR_Rare; U.StatValue = 0.08; UniversalUpgrades.AddItem(U);

    U.UpgradeID = "UNIV_E_SPEED"; U.DisplayName = "Wind Runner"; U.Description = "+10% Movement Speed";
    U.Rarity = RLR_Epic; U.StatValue = 0.10; UniversalUpgrades.AddItem(U);

    U.UpgradeID = "UNIV_L_SPEED"; U.DisplayName = "Blur"; U.Description = "+15% Movement Speed";
    U.Rarity = RLR_Legendary; U.StatValue = 0.15; UniversalUpgrades.AddItem(U);

    // ========== RELOAD (All Rarities) ==========
    U.StatType = RLST_ReloadSpeed;

    U.UpgradeID = "UNIV_C_RELOAD"; U.DisplayName = "Steady Hands"; U.Description = "+5% Reload Speed";
    U.Rarity = RLR_Common; U.StatValue = 0.05; UniversalUpgrades.AddItem(U);

    U.UpgradeID = "UNIV_U_RELOAD"; U.DisplayName = "Fast Hands"; U.Description = "+10% Reload Speed";
    U.Rarity = RLR_Uncommon; U.StatValue = 0.10; UniversalUpgrades.AddItem(U);

    U.UpgradeID = "UNIV_R_RELOAD"; U.DisplayName = "Rapid Reload"; U.Description = "+15% Reload Speed";
    U.Rarity = RLR_Rare; U.StatValue = 0.15; UniversalUpgrades.AddItem(U);

    U.UpgradeID = "UNIV_E_RELOAD"; U.DisplayName = "Lightning Hands"; U.Description = "+20% Reload Speed";
    U.Rarity = RLR_Epic; U.StatValue = 0.20; UniversalUpgrades.AddItem(U);

    U.UpgradeID = "UNIV_L_RELOAD"; U.DisplayName = "Instant Load"; U.Description = "+30% Reload Speed";
    U.Rarity = RLR_Legendary; U.StatValue = 0.30; UniversalUpgrades.AddItem(U);

    // ========== AMMO (All Rarities) ==========
    U.StatType = RLST_AmmoCapacity;

    U.UpgradeID = "UNIV_C_AMMO"; U.DisplayName = "Ammo Reserves"; U.Description = "+5% Ammo Capacity";
    U.Rarity = RLR_Common; U.StatValue = 0.05; UniversalUpgrades.AddItem(U);

    U.UpgradeID = "UNIV_U_AMMO"; U.DisplayName = "Deep Pockets"; U.Description = "+10% Ammo Capacity";
    U.Rarity = RLR_Uncommon; U.StatValue = 0.10; UniversalUpgrades.AddItem(U);

    U.UpgradeID = "UNIV_R_AMMO"; U.DisplayName = "Stockpile"; U.Description = "+15% Ammo Capacity";
    U.Rarity = RLR_Rare; U.StatValue = 0.15; UniversalUpgrades.AddItem(U);

    U.UpgradeID = "UNIV_E_AMMO"; U.DisplayName = "Arsenal"; U.Description = "+20% Ammo Capacity";
    U.Rarity = RLR_Epic; U.StatValue = 0.20; UniversalUpgrades.AddItem(U);

    U.UpgradeID = "UNIV_L_AMMO"; U.DisplayName = "Armory"; U.Description = "+30% Ammo Capacity";
    U.Rarity = RLR_Legendary; U.StatValue = 0.30; UniversalUpgrades.AddItem(U);

    // ========== DAMAGE (Rare+ Only) ==========
    U.StatType = RLST_DamageDealt;

    U.UpgradeID = "UNIV_R_DAMAGE"; U.DisplayName = "Sharpened"; U.Description = "+5% Damage Dealt";
    U.Rarity = RLR_Rare; U.StatValue = 0.05; UniversalUpgrades.AddItem(U);

    U.UpgradeID = "UNIV_E_DAMAGE"; U.DisplayName = "Lethal"; U.Description = "+8% Damage Dealt";
    U.Rarity = RLR_Epic; U.StatValue = 0.08; UniversalUpgrades.AddItem(U);

    U.UpgradeID = "UNIV_L_DAMAGE"; U.DisplayName = "Devastating"; U.Description = "+12% Damage Dealt";
    U.Rarity = RLR_Legendary; U.StatValue = 0.12; UniversalUpgrades.AddItem(U);

    // ========== DAMAGE RESIST (Rare+ Only) ==========
    U.StatType = RLST_DamageResist;

    U.UpgradeID = "UNIV_R_RESIST"; U.DisplayName = "Resilient"; U.Description = "-3% Damage Taken";
    U.Rarity = RLR_Rare; U.StatValue = 0.03; UniversalUpgrades.AddItem(U);

    U.UpgradeID = "UNIV_E_RESIST"; U.DisplayName = "Stalwart"; U.Description = "-4% Damage Taken";
    U.Rarity = RLR_Epic; U.StatValue = 0.04; UniversalUpgrades.AddItem(U);

    U.UpgradeID = "UNIV_L_RESIST"; U.DisplayName = "Unbreakable"; U.Description = "-6% Damage Taken";
    U.Rarity = RLR_Legendary; U.StatValue = 0.06; UniversalUpgrades.AddItem(U);

    // ========== LUCK (All Rarities) ==========
    U.StatType = RLST_Luck;

    U.UpgradeID = "UNIV_C_LUCK"; U.DisplayName = "Lucky Charm"; U.Description = "+3% Luck";
    U.Rarity = RLR_Common; U.StatValue = 0.03; UniversalUpgrades.AddItem(U);

    U.UpgradeID = "UNIV_U_LUCK"; U.DisplayName = "Fortune's Favor"; U.Description = "+5% Luck";
    U.Rarity = RLR_Uncommon; U.StatValue = 0.05; UniversalUpgrades.AddItem(U);

    U.UpgradeID = "UNIV_R_LUCK"; U.DisplayName = "Blessed"; U.Description = "+8% Luck";
    U.Rarity = RLR_Rare; U.StatValue = 0.08; UniversalUpgrades.AddItem(U);

    U.UpgradeID = "UNIV_E_LUCK"; U.DisplayName = "Fate's Chosen"; U.Description = "+12% Luck";
    U.Rarity = RLR_Epic; U.StatValue = 0.12; UniversalUpgrades.AddItem(U);

    U.UpgradeID = "UNIV_L_LUCK"; U.DisplayName = "Destiny's Hand"; U.Description = "+18% Luck";
    U.Rarity = RLR_Legendary; U.StatValue = 0.18; UniversalUpgrades.AddItem(U);

    // ========== GLASS CANNON (All Rarities) ==========
    U.StatType = RLST_GlassCannon;

    U.UpgradeID = "UNIV_C_GLASSCANNON"; U.DisplayName = "Fragile Power"; U.Description = "+10% Damage, -10% Max HP";
    U.Rarity = RLR_Common; U.StatValue = 0.10; UniversalUpgrades.AddItem(U);

    U.UpgradeID = "UNIV_U_GLASSCANNON"; U.DisplayName = "Reckless Might"; U.Description = "+15% Damage, -15% Max HP";
    U.Rarity = RLR_Uncommon; U.StatValue = 0.15; UniversalUpgrades.AddItem(U);

    U.UpgradeID = "UNIV_R_GLASSCANNON"; U.DisplayName = "Glass Cannon"; U.Description = "+20% Damage, -20% Max HP";
    U.Rarity = RLR_Rare; U.StatValue = 0.20; UniversalUpgrades.AddItem(U);

    U.UpgradeID = "UNIV_E_GLASSCANNON"; U.DisplayName = "Death Wish"; U.Description = "+28% Damage, -25% Max HP";
    U.Rarity = RLR_Epic; U.StatValue = 0.28; UniversalUpgrades.AddItem(U);

    U.UpgradeID = "UNIV_L_GLASSCANNON"; U.DisplayName = "Volatile Core"; U.Description = "+40% Damage, -30% Max HP";
    U.Rarity = RLR_Legendary; U.StatValue = 0.40; UniversalUpgrades.AddItem(U);

    // ========== SUMO (All Rarities) ==========
    U.StatType = RLST_Sumo;

    U.UpgradeID = "UNIV_C_SUMO"; U.DisplayName = "Heavy Step"; U.Description = "+4% Damage Resist, -5% Speed";
    U.Rarity = RLR_Common; U.StatValue = 0.04; UniversalUpgrades.AddItem(U);

    U.UpgradeID = "UNIV_U_SUMO"; U.DisplayName = "Immovable"; U.Description = "+6% Damage Resist, -8% Speed";
    U.Rarity = RLR_Uncommon; U.StatValue = 0.06; UniversalUpgrades.AddItem(U);

    U.UpgradeID = "UNIV_R_SUMO"; U.DisplayName = "Sumo Stance"; U.Description = "+9% Damage Resist, -10% Speed";
    U.Rarity = RLR_Rare; U.StatValue = 0.09; UniversalUpgrades.AddItem(U);

    U.UpgradeID = "UNIV_E_SUMO"; U.DisplayName = "Living Wall"; U.Description = "+13% Damage Resist, -12% Speed";
    U.Rarity = RLR_Epic; U.StatValue = 0.13; UniversalUpgrades.AddItem(U);

    U.UpgradeID = "UNIV_L_SUMO"; U.DisplayName = "Unstoppable Force"; U.Description = "+18% Damage Resist, -15% Speed";
    U.Rarity = RLR_Legendary; U.StatValue = 0.18; UniversalUpgrades.AddItem(U);

    // ========== OPPORTUNIST (All Rarities) ==========
    U.StatType = RLST_Opportunist;

    U.UpgradeID = "UNIV_C_OPPORTUNIST"; U.DisplayName = "Backstabber"; U.Description = "+10% Damage from behind";
    U.Rarity = RLR_Common; U.StatValue = 0.10; UniversalUpgrades.AddItem(U);

    U.UpgradeID = "UNIV_U_OPPORTUNIST"; U.DisplayName = "Opportunist"; U.Description = "+15% Damage from behind";
    U.Rarity = RLR_Uncommon; U.StatValue = 0.15; UniversalUpgrades.AddItem(U);

    U.UpgradeID = "UNIV_R_OPPORTUNIST"; U.DisplayName = "Ambush Predator"; U.Description = "+22% Damage from behind";
    U.Rarity = RLR_Rare; U.StatValue = 0.22; UniversalUpgrades.AddItem(U);

    U.UpgradeID = "UNIV_E_OPPORTUNIST"; U.DisplayName = "Shadow Strike"; U.Description = "+32% Damage from behind";
    U.Rarity = RLR_Epic; U.StatValue = 0.32; UniversalUpgrades.AddItem(U);

    U.UpgradeID = "UNIV_L_OPPORTUNIST"; U.DisplayName = "Perfect Ambush"; U.Description = "+45% Damage from behind";
    U.Rarity = RLR_Legendary; U.StatValue = 0.45; UniversalUpgrades.AddItem(U);

    // ========== DUELIST (All Rarities) ==========
    U.StatType = RLST_Duelist;

    U.UpgradeID = "UNIV_C_DUELIST"; U.DisplayName = "One-on-One"; U.Description = "+12% Damage vs isolated targets";
    U.Rarity = RLR_Common; U.StatValue = 0.12; UniversalUpgrades.AddItem(U);

    U.UpgradeID = "UNIV_U_DUELIST"; U.DisplayName = "Duelist"; U.Description = "+18% Damage vs isolated targets";
    U.Rarity = RLR_Uncommon; U.StatValue = 0.18; UniversalUpgrades.AddItem(U);

    U.UpgradeID = "UNIV_R_DUELIST"; U.DisplayName = "Focused Hunter"; U.Description = "+26% Damage vs isolated targets";
    U.Rarity = RLR_Rare; U.StatValue = 0.26; UniversalUpgrades.AddItem(U);

    U.UpgradeID = "UNIV_E_DUELIST"; U.DisplayName = "Apex Predator"; U.Description = "+38% Damage vs isolated targets";
    U.Rarity = RLR_Epic; U.StatValue = 0.38; UniversalUpgrades.AddItem(U);

    U.UpgradeID = "UNIV_L_DUELIST"; U.DisplayName = "Death's Gaze"; U.Description = "+55% Damage vs isolated targets";
    U.Rarity = RLR_Legendary; U.StatValue = 0.55; UniversalUpgrades.AddItem(U);

    // ========== WEALTHY (All Rarities) ==========
    U.StatType = RLST_Wealthy; U.bIsPercentage = false;

    U.UpgradeID = "UNIV_C_WEALTHY"; U.DisplayName = "Pocket Change"; U.Description = "+50 Dosh at wave start";
    U.Rarity = RLR_Common; U.StatValue = 50.0; UniversalUpgrades.AddItem(U);

    U.UpgradeID = "UNIV_U_WEALTHY"; U.DisplayName = "Stipend"; U.Description = "+100 Dosh at wave start";
    U.Rarity = RLR_Uncommon; U.StatValue = 100.0; UniversalUpgrades.AddItem(U);

    U.UpgradeID = "UNIV_R_WEALTHY"; U.DisplayName = "Wealthy"; U.Description = "+175 Dosh at wave start";
    U.Rarity = RLR_Rare; U.StatValue = 175.0; UniversalUpgrades.AddItem(U);

    U.UpgradeID = "UNIV_E_WEALTHY"; U.DisplayName = "Trust Fund"; U.Description = "+275 Dosh at wave start";
    U.Rarity = RLR_Epic; U.StatValue = 275.0; UniversalUpgrades.AddItem(U);

    U.UpgradeID = "UNIV_L_WEALTHY"; U.DisplayName = "Golden Goose"; U.Description = "+400 Dosh at wave start";
    U.Rarity = RLR_Legendary; U.StatValue = 400.0; UniversalUpgrades.AddItem(U);

    // ========== LAST ROUND (All Rarities) ==========
    U.StatType = RLST_LastRound; U.bIsPercentage = true;

    U.UpgradeID = "UNIV_C_LASTROUND"; U.DisplayName = "Final Shot"; U.Description = "+35% Damage on last bullet";
    U.Rarity = RLR_Common; U.StatValue = 0.35; UniversalUpgrades.AddItem(U);

    U.UpgradeID = "UNIV_U_LASTROUND"; U.DisplayName = "Parting Gift"; U.Description = "+55% Damage on last bullet";
    U.Rarity = RLR_Uncommon; U.StatValue = 0.55; UniversalUpgrades.AddItem(U);

    U.UpgradeID = "UNIV_R_LASTROUND"; U.DisplayName = "Last Round"; U.Description = "+80% Damage on last bullet";
    U.Rarity = RLR_Rare; U.StatValue = 0.80; UniversalUpgrades.AddItem(U);

    U.UpgradeID = "UNIV_E_LASTROUND"; U.DisplayName = "Coup de Grace"; U.Description = "+110% Damage on last bullet";
    U.Rarity = RLR_Epic; U.StatValue = 1.10; UniversalUpgrades.AddItem(U);

    U.UpgradeID = "UNIV_L_LASTROUND"; U.DisplayName = "Omega Round"; U.Description = "+150% Damage on last bullet";
    U.Rarity = RLR_Legendary; U.StatValue = 1.50; UniversalUpgrades.AddItem(U);

    // Reset for tree upgrades
    U.bIsPassiveEffect = false;
    U.bIsPercentage = true;

    // === ELDRITCH TREE UPGRADES ===
    U.PoolType = RLPT_Tree;
    U.TreeRequirement = 1;
    U.StatType = RLST_LargeZedDamage;

    U.UpgradeID = "ELD_C_LARGEZED"; U.DisplayName = "Void Touched"; U.Description = "+3% damage vs Large Zeds";
    U.Rarity = RLR_Common; U.StatValue = 0.03; EldritchTreeUpgrades.AddItem(U);

    U.UpgradeID = "ELD_U_LARGEZED"; U.DisplayName = "Abyssal Affinity"; U.Description = "+5% damage vs Large Zeds";
    U.Rarity = RLR_Uncommon; U.StatValue = 0.05; EldritchTreeUpgrades.AddItem(U);

    U.UpgradeID = "ELD_R_LARGEZED"; U.DisplayName = "Eldritch Insight"; U.Description = "+8% damage vs Large Zeds";
    U.Rarity = RLR_Rare; U.StatValue = 0.08; EldritchTreeUpgrades.AddItem(U);

    U.UpgradeID = "ELD_E_LARGEZED"; U.DisplayName = "Cosmic Horror"; U.Description = "+12% damage vs Large Zeds";
    U.Rarity = RLR_Epic; U.StatValue = 0.12; EldritchTreeUpgrades.AddItem(U);

    U.UpgradeID = "ELD_L_LARGEZED"; U.DisplayName = "Beyond Comprehension"; U.Description = "+18% damage vs Large Zeds";
    U.Rarity = RLR_Legendary; U.StatValue = 0.18; EldritchTreeUpgrades.AddItem(U);

    // =================================================================
    // === PERK UNIQUE UPGRADES (46 total — one per perk) ===
    // =================================================================
    U.PoolType = RLPT_Perk;
    U.Rarity = RLR_Unique;
    U.bIsPassiveEffect = true;
    U.StatType = RLST_Special;
    U.StatValue = 0.0;
    U.bIsPercentage = false;
    U.TreeRequirement = 0;
    U.CharacterRequirement = -1;

    // --- WM PERKS (10) ---

    U.UpgradeID = "PERK_X_BERSERKER"; U.DisplayName = "Undying Rage";
    U.Description = "Cheat death once per 60s: 5s invulnerability + 100% melee damage";
    U.RequiredPerkName = "ZedternalReborn.WMUpgrade_Perk_Berserker"; PerkUniques.AddItem(U);

    U.UpgradeID = "PERK_X_COMMANDO"; U.DisplayName = "Endless Zed Time";
    U.Description = "Zed Time extensions last 50% longer. Full speed + 25% damage during Zed Time";
    U.RequiredPerkName = "ZedternalReborn.WMUpgrade_Perk_Commando"; PerkUniques.AddItem(U);

    U.UpgradeID = "PERK_X_SUPPORT"; U.DisplayName = "Walking Armory";
    U.Description = "Wave start: allies within 10m get +25% max ammo. +1 grenade every 5 waves";
    U.RequiredPerkName = "ZedternalReborn.WMUpgrade_Perk_Support"; PerkUniques.AddItem(U);

    U.UpgradeID = "PERK_X_FIELDMEDIC"; U.DisplayName = "Miracle Worker";
    U.Description = "10% chance healing darts fully heal target. Self-heals 2x. Healed allies get 10% DR for 5s";
    U.RequiredPerkName = "ZedternalReborn.WMUpgrade_Perk_FieldMedic"; PerkUniques.AddItem(U);

    U.UpgradeID = "PERK_X_DEMOLITIONIST"; U.DisplayName = "Nuclear Option";
    U.Description = "Every 10th explosion deals 3x damage in 2x radius with lingering radiation zone";
    U.RequiredPerkName = "ZedternalReborn.WMUpgrade_Perk_Demolitionist"; PerkUniques.AddItem(U);

    U.UpgradeID = "PERK_X_FIREBUG"; U.DisplayName = "Infernal Aura";
    U.Description = "Zeds within 5m are permanently on fire. Ground fire 50% larger and lasts 50% longer";
    U.RequiredPerkName = "ZedternalReborn.WMUpgrade_Perk_Firebug"; PerkUniques.AddItem(U);

    U.UpgradeID = "PERK_X_GUNSLINGER"; U.DisplayName = "Fan the Hammer";
    U.Description = "After headshot kill: next 3 shots in 2s have +50% fire rate and zero recoil (5s CD)";
    U.RequiredPerkName = "ZedternalReborn.WMUpgrade_Perk_Gunslinger"; PerkUniques.AddItem(U);

    U.UpgradeID = "PERK_X_SHARPSHOOTER"; U.DisplayName = "One Shot, One Kill";
    U.Description = "Large zed headshot kills refund 50% ammo. +25% damage on next hit after HS kill (2s)";
    U.RequiredPerkName = "ZedternalReborn.WMUpgrade_Perk_Sharpshooter"; PerkUniques.AddItem(U);

    U.UpgradeID = "PERK_X_SWAT"; U.DisplayName = "Bullet Storm";
    U.Description = "50 consecutive hits grants 5s frenzy: +100% fire rate, unlimited ammo, no recoil";
    U.RequiredPerkName = "ZedternalReborn.WMUpgrade_Perk_SWAT"; PerkUniques.AddItem(U);

    U.UpgradeID = "PERK_X_SURVIVALIST"; U.DisplayName = "Jack of All Trades";
    U.Description = "+5% damage per distinct perk weapon type in inventory (max 6 types = +30%)";
    U.RequiredPerkName = "ZedternalReborn.WMUpgrade_Perk_Survivalist"; PerkUniques.AddItem(U);

    // --- DK PERKS (36) ---

    U.UpgradeID = "PERK_X_AGONY"; U.DisplayName = "Temporal Prison";
    U.Description = "Zed Time kills have 20% chance to freeze ALL nearby zeds (8m) for 3s. 15s CD";
    U.RequiredPerkName = "ZedternalTempered.ZTUpgrade_Perk_Agony"; PerkUniques.AddItem(U);

    U.UpgradeID = "PERK_X_ARCHANGEL"; U.DisplayName = "Divine Intervention";
    U.Description = "Any ally below 25% HP instantly heals 50 HP. 20s CD per ally. Works on self";
    U.RequiredPerkName = "ZedternalTempered.ZTUpgrade_Perk_Archangel"; PerkUniques.AddItem(U);

    U.UpgradeID = "PERK_X_ARTIFICER"; U.DisplayName = "Masterwork Synthesis";
    U.Description = "Each weapon mastery milestone grants +3% permanent damage bonus to all other weapons";
    U.RequiredPerkName = "ZedternalTempered.ZTUpgrade_Perk_Artificer"; PerkUniques.AddItem(U);

    U.UpgradeID = "PERK_X_BULWARK"; U.DisplayName = "Immovable Object";
    U.Description = "Cannot be knocked down or stumbled. Hits over 50 damage are capped at 50 (10s CD)";
    U.RequiredPerkName = "ZedternalTempered.ZTUpgrade_Perk_Bulwark"; PerkUniques.AddItem(U);

    U.UpgradeID = "PERK_X_CINDER"; U.DisplayName = "Living Pyre";
    U.Description = "With 5+ burning enemies: +50% speed and leave fire trail. Refreshes while active";
    U.RequiredPerkName = "ZedternalTempered.ZTUpgrade_Perk_Cinder"; PerkUniques.AddItem(U);

    U.UpgradeID = "PERK_X_CRYOPHILITE"; U.DisplayName = "Shatter Storm";
    U.Description = "Frozen enemy kills explode into ice shards dealing 200 freeze damage in 5m. Chain-freezes";
    U.RequiredPerkName = "ZedternalTempered.ZTUpgrade_Perk_Cryophilite"; PerkUniques.AddItem(U);

    U.UpgradeID = "PERK_X_DAREDEVIL"; U.DisplayName = "Dead Man's Hand";
    U.Description = "Consecutive headshot kills build multiplier: 2nd +20%, 3rd +40%, 4th +60%, 5th+ +100%";
    U.RequiredPerkName = "ZedternalTempered.ZTUpgrade_Perk_Daredevil"; PerkUniques.AddItem(U);

    U.UpgradeID = "PERK_X_FORGEWARDEN"; U.DisplayName = "Slag Cascade";
    U.Description = "Fire/explosive kills have 25% chance to explode for 50% target max HP as fire (4m)";
    U.RequiredPerkName = "ZedternalTempered.ZTUpgrade_Perk_ForgeWarden"; PerkUniques.AddItem(U);

    U.UpgradeID = "PERK_X_FROST"; U.DisplayName = "Absolute Zero Aura";
    U.Description = "Every 30 kills: frost pulse (8m) freezes all nearby zeds 3s. Frozen take +50% damage";
    U.RequiredPerkName = "ZedternalTempered.ZTUpgrade_Perk_Frost"; PerkUniques.AddItem(U);

    U.UpgradeID = "PERK_X_GAMBIT"; U.DisplayName = "All In";
    U.Description = "Mythic gambits give double rewards. Mythic chance increased from 1% to 5%";
    U.RequiredPerkName = "ZedternalTempered.ZTUpgrade_Perk_Gambit"; PerkUniques.AddItem(U);

    U.UpgradeID = "PERK_X_GAMBLER"; U.DisplayName = "Loaded Dice";
    U.Description = "All headshot dosh procs doubled. 15% chance wave dosh reward is tripled";
    U.RequiredPerkName = "ZedternalTempered.ZTUpgrade_Perk_Gambler"; PerkUniques.AddItem(U);

    U.UpgradeID = "PERK_X_HAUNTED"; U.DisplayName = "The Watcher's Gift";
    U.Description = "3% chance hits terrify target (flee 4s). Terrified zeds take +30% damage from all";
    U.RequiredPerkName = "ZedternalTempered.ZTUpgrade_Perk_Haunted"; PerkUniques.AddItem(U);

    U.UpgradeID = "PERK_X_HEADHUNTER"; U.DisplayName = "Trophy Collection";
    U.Description = "Every 25 headshot kills: permanent +2% headshot damage. No cap. Persists all run";
    U.RequiredPerkName = "ZedternalTempered.ZTUpgrade_Perk_Headhunter"; PerkUniques.AddItem(U);

    U.UpgradeID = "PERK_X_HIVEMIND"; U.DisplayName = "Neural Network";
    U.Description = "Allies within 15m get +10% reload and +10% damage. You get +5% per ally (max +25%)";
    U.RequiredPerkName = "ZedternalTempered.ZTUpgrade_Perk_Hivemind"; PerkUniques.AddItem(U);

    U.UpgradeID = "PERK_X_HOLLOW"; U.DisplayName = "Void Resonance";
    U.Description = "Hollow weapons deal +25% damage. 10% kill chance to spawn Void Rift pulling zeds 3s";
    U.RequiredPerkName = "ZedternalTempered.ZTUpgrade_Perk_Hollow"; PerkUniques.AddItem(U);

    U.UpgradeID = "PERK_X_HYDRA"; U.DisplayName = "Regenerating Fury";
    U.Description = "Taking lethal limb damage triggers +5 HP/s for 10s. Kills during regen extend by 1s";
    U.RequiredPerkName = "ZedternalTempered.ZTUpgrade_Perk_Hydra"; PerkUniques.AddItem(U);

    U.UpgradeID = "PERK_X_MANIAC"; U.DisplayName = "Chain Detonation";
    U.Description = "Grenade kills have 30% chance to drop another grenade at kill location. +15% nade dmg";
    U.RequiredPerkName = "ZedternalTempered.ZTUpgrade_Perk_Maniac"; PerkUniques.AddItem(U);

    U.UpgradeID = "PERK_X_MEDUSA"; U.DisplayName = "Stone Gaze";
    U.Description = "Looking at a zed within 10m for 2s petrifies it 5s. Petrified take 3x next hit. 20s CD";
    U.RequiredPerkName = "ZedternalTempered.ZTUpgrade_Perk_Medusa"; PerkUniques.AddItem(U);

    U.UpgradeID = "PERK_X_METRONOME"; U.DisplayName = "Perfect Tempo";
    U.Description = "Sync kills grant stacking +3% all-damage for 15s. Max 10 stacks = +30%";
    U.RequiredPerkName = "ZedternalTempered.ZTUpgrade_Perk_Metronome"; PerkUniques.AddItem(U);

    U.UpgradeID = "PERK_X_OMEN"; U.DisplayName = "Doom Prophecy";
    U.Description = "Wave start: one random zed type is Doomed. Doomed kills give +100% dosh and heal 5 HP";
    U.RequiredPerkName = "ZedternalTempered.ZTUpgrade_Perk_Omen"; PerkUniques.AddItem(U);

    U.UpgradeID = "PERK_X_PARASITE"; U.DisplayName = "Infestation Cascade";
    U.Description = "Infested zed kills spread parasites to 2 nearby zeds (5m): +20% dmg taken, -20% speed";
    U.RequiredPerkName = "ZedternalTempered.ZTUpgrade_Perk_Parasite"; PerkUniques.AddItem(U);

    U.UpgradeID = "PERK_X_PREDATOR"; U.DisplayName = "Apex Predator";
    U.Description = "Marked target killed in 5s grants +15% damage 10s. Large zed marks grant +30% instead";
    U.RequiredPerkName = "ZedternalTempered.ZTUpgrade_Perk_Predator"; PerkUniques.AddItem(U);

    U.UpgradeID = "PERK_X_PYROKINETIC"; U.DisplayName = "Spontaneous Combustion";
    U.Description = "Every 15 kills: next hit ignites at 5x fire rate. Large zeds take 500 extra fire damage";
    U.RequiredPerkName = "ZedternalTempered.ZTUpgrade_Perk_Pyrokinetic"; PerkUniques.AddItem(U);

    U.UpgradeID = "PERK_X_REAPER"; U.DisplayName = "Soul Harvest";
    U.Description = "Kills grant 1 Soul (max 50). At 50: next attack +200% damage, consumes all. Decay 2/s";
    U.RequiredPerkName = "ZedternalTempered.ZTUpgrade_Perk_Reaper"; PerkUniques.AddItem(U);

    U.UpgradeID = "PERK_X_RIOT"; U.DisplayName = "Phalanx Protocol";
    U.Description = "Full damage immunity while blocking. Parries stagger ALL zeds within 3m";
    U.RequiredPerkName = "ZedternalTempered.ZTUpgrade_Perk_Riot"; PerkUniques.AddItem(U);

    U.UpgradeID = "PERK_X_SCAVENGER"; U.DisplayName = "Treasure Hunter";
    U.Description = "5% kill chance to drop ammo pickup. Every 50 kills: weapon upgrade token drops";
    U.RequiredPerkName = "ZedternalTempered.ZTUpgrade_Perk_Scavenger"; PerkUniques.AddItem(U);

    U.UpgradeID = "PERK_X_SHAPESHIFTER"; U.DisplayName = "Chimera Form";
    U.Description = "Current form bonuses are doubled. Switching forms grants 3s invulnerability";
    U.RequiredPerkName = "ZedternalTempered.ZTUpgrade_Perk_Shapeshifter"; PerkUniques.AddItem(U);

    U.UpgradeID = "PERK_X_SPECIALAGENT"; U.DisplayName = "Black Ops Protocol";
    U.Description = "+50% damage from behind. 30% reduced aggro radius. First hit on unaware zed = crit";
    U.RequiredPerkName = "ZedternalTempered.ZTUpgrade_Perk_SpecialAgent"; PerkUniques.AddItem(U);

    U.UpgradeID = "PERK_X_SYMBIOTE"; U.DisplayName = "Perfect Symbiosis";
    U.Description = "Evolution bonuses doubled. +2 HP/s above 50% HP. Below 50% HP: +30% damage instead";
    U.RequiredPerkName = "ZedternalTempered.ZTUpgrade_Perk_Symbiote"; PerkUniques.AddItem(U);

    U.UpgradeID = "PERK_X_TASKMASTER"; U.DisplayName = "Drill Sergeant";
    U.Description = "All allies gain permanent +5% damage and +5% reload. Kills heal random ally 5 HP (10s CD)";
    U.RequiredPerkName = "ZedternalTempered.ZTUpgrade_Perk_Taskmaster"; PerkUniques.AddItem(U);

    U.UpgradeID = "PERK_X_TIMETRAVELER"; U.DisplayName = "Paradox Anchor";
    U.Description = "On death: rewind 10s restoring HP, armor, ammo, position. Once per wave";
    U.RequiredPerkName = "ZedternalTempered.ZTUpgrade_Perk_TimeTraveler"; PerkUniques.AddItem(U);

    U.UpgradeID = "PERK_X_TYCOON"; U.DisplayName = "Hostile Takeover";
    U.Description = "Per 1000 dosh earned: +2% permanent damage (max +20%). Trader refunds 5% purchase price";
    U.RequiredPerkName = "ZedternalTempered.ZTUpgrade_Perk_Tycoon"; PerkUniques.AddItem(U);

    U.UpgradeID = "PERK_X_VENOMANCER"; U.DisplayName = "Pandemic Protocol";
    U.Description = "Toxic kills explode into poison cloud (4m, 5s). Poisoned zeds: -30% dmg dealt, +15% taken";
    U.RequiredPerkName = "ZedternalTempered.ZTUpgrade_Perk_Venomancer"; PerkUniques.AddItem(U);

    U.UpgradeID = "PERK_X_VOODOO"; U.DisplayName = "Blood Pact";
    U.Description = "At 1 HP: additional +50% damage on top of Voodoo scaling. Kills at 1 HP heal 3 HP";
    U.RequiredPerkName = "ZedternalTempered.ZTUpgrade_Perk_Voodoo"; PerkUniques.AddItem(U);

    U.UpgradeID = "PERK_X_WARLORD"; U.DisplayName = "Iron Curtain";
U.Description = "Every 20 kills: +5 permanent armor (no cap). At 200+ armor: +10% damage resistance";
    U.RequiredPerkName = "ZedternalTempered.ZTUpgrade_Perk_Warlord"; PerkUniques.AddItem(U);

    U.UpgradeID = "PERK_X_WENDIGO"; U.DisplayName = "Ravenous Consumption";
    U.Description = "Large zed kills restore 25 HP and give +20% damage 10s. 3 large kills/wave: +50 max HP";
    U.RequiredPerkName = "ZedternalTempered.ZTUpgrade_Perk_Wendigo"; PerkUniques.AddItem(U);

    // === Apply admin overrides from KFZedternalUnlimited.ini ===
    // [ZedternalTempered.ZTConfig_RoguelikePool] UpgradeOverride=(...)
    ApplyPoolOverrides(UniversalUpgrades, "Universal", AppliedOverrideIDs);
    ApplyPoolOverrides(EldritchTreeUpgrades, "EldritchTree", AppliedOverrideIDs);
    ApplyPoolOverrides(PerkUniques, "PerkUniques", AppliedOverrideIDs);
    WarnUnmatchedOverrides(AppliedOverrideIDs);
}

//=============================================================================
// ADMIN OVERRIDES — applied after pool generation
//=============================================================================

/** Apply ZTConfig_RoguelikePool overrides to a pool array.
 *  Matching entries can have StatValue/Description patched, or be removed
 *  entirely if bDisabled=True. AppliedIDs is appended with each matched
 *  UpgradeID so WarnUnmatchedOverrides can report typos. */
function ApplyPoolOverrides(out array<RoguelikeUpgradeData> Pool, string PoolName, out array<string> AppliedIDs)
{
    local int i;
    local ZTConfig_RoguelikePool.S_RoguelikeUpgradeOverride Override;

    // Walk backwards so we can safely remove disabled entries
    for (i = Pool.Length - 1; i >= 0; i--)
    {
        if (class'ZTConfig_RoguelikePool'.static.FindOverride(Pool[i].UpgradeID, Override))
        {
            AppliedIDs.AddItem(Pool[i].UpgradeID);

            if (Override.bDisabled)
            {
                `log("[DK_ROGUELIKE_OVERRIDE]" @ PoolName @ "DISABLED:" @ Pool[i].UpgradeID @ "(" $ Pool[i].DisplayName $ ")");
                Pool.Remove(i, 1);
                continue;
            }

            if (Override.StatValue != 0.0)
            {
                `log("[DK_ROGUELIKE_OVERRIDE]" @ PoolName @ "patched StatValue for" @ Pool[i].UpgradeID @ ":" @ Pool[i].StatValue @ "->" @ Override.StatValue);
                Pool[i].StatValue = Override.StatValue;
            }

            if (Override.Description != "")
            {
                `log("[DK_ROGUELIKE_OVERRIDE]" @ PoolName @ "patched Description for" @ Pool[i].UpgradeID);
                Pool[i].Description = Override.Description;
            }
        }
    }
}

/** Log a warning for any UpgradeOverride entry whose UpgradeID didn't match
 *  any upgrade in any pool. Helps admins catch typos. */
function WarnUnmatchedOverrides(array<string> AppliedIDs)
{
    local int i, j;
    local string OverrideID;
    local bool bMatched;

    for (i = 0; i < class'ZTConfig_RoguelikePool'.static.GetOverrideCount(); i++)
    {
        OverrideID = class'ZTConfig_RoguelikePool'.static.GetOverrideID(i);
        if (OverrideID == "")
            continue;

        bMatched = False;
        for (j = 0; j < AppliedIDs.Length; j++)
        {
            if (AppliedIDs[j] ~= OverrideID)
            {
                bMatched = True;
                break;
            }
        }

        if (!bMatched)
        {
            `log("[DK_ROGUELIKE_OVERRIDE] WARNING: UpgradeOverride for unknown UpgradeID:" @ OverrideID @ "(possibly typo'd or duplicate - won't apply)");
        }
    }
}

//=============================================================================
// WAVE TRIGGER LOGIC
//=============================================================================

function bool ShouldTriggerUpgradeSelection(int WaveNum)
{
    return (WaveNum > 0) && (WaveNum % UpgradeWaveInterval == 0);
}

function StartUpgradeSelection()
{
    local PlayerController PC;
    local ZTPlayerController DKPC;

    if (bUpgradeSelectionActive)
    {
        `log("[DK_ROGUELIKE] WARNING: Selection already active!");
        return;
    }

    bUpgradeSelectionActive = true;
    SelectionsHeldThisGame++;
    PlayersInSelection.Length = 0;
    PlayersCompletedSelection.Length = 0;
    PendingOptions.Length = 0;

    foreach WorldInfo.AllControllers(class'PlayerController', PC)
    {
        DKPC = ZTPlayerController(PC);
        if (DKPC != None && DKPC.Pawn != None && DKPC.Pawn.IsAliveAndWell())
        {
            GenerateOptionsForPlayer(DKPC);
            PlayersInSelection.AddItem(DKPC);
        }
    }

    if (PlayersInSelection.Length == 0)
    {
        EndUpgradeSelection();
        return;
    }

    `log("[DK_ROGUELIKE]" @ PlayersInSelection.Length @ "players entering selection");
}

//=============================================================================
// OPTION GENERATION
//=============================================================================

function GenerateOptionsForPlayer(ZTPlayerController DKPC)
{
    local ZTPlayerReplicationInfo DKPRI;
    local PendingUpgradeOptions PlayerOptions;
    local RoguelikeUpgradeData SelectedUpgrade;
    local array<RoguelikeUpgradeData> EligiblePool;
    local ERoguelikeRarity RolledRarity;
    local int i, RandomIndex;
    local array<string> UsedUpgradeIDs;
    local array<ERoguelikeStatType> UsedStatTypes;
    local float PlayerLuck;
    local bool bExcludeUnique;

    DKPRI = ZTPlayerReplicationInfo(DKPC.PlayerReplicationInfo);
    if (DKPRI == None)
        return;

    UsedUpgradeIDs.Length = 0;
    UsedStatTypes.Length = 0;
    PlayerOptions.PC = DKPC;
    PlayerOptions.Options.Length = 0;

    PlayerLuck = DKPRI.GetRoguelikeLuck();

    // Determine if we should exclude Unique rarity
    // Only exclude if there are NO eligible uniques for this player
    bExcludeUnique = !HasAnyEligibleUnique(DKPRI);

    `log("[DK_ROGUELIKE_ROLL] Generating for" @ DKPRI.PlayerName
        @ "Luck=" $ int(PlayerLuck * 100) $ "%"
        @ "ExcludeUnique=" $ bExcludeUnique);

    for (i = 0; i < UpgradeOptionsCount; i++)
    {
        RolledRarity = RollRarityWithLuck(PlayerLuck, bExcludeUnique);

        EligiblePool = BuildEligiblePool(
            DKPRI.GetRoguelikeTree(),
            DKPRI.GetRoguelikeCharacter(),
            RolledRarity,
            DKPRI
        );

        RemoveUsedUpgrades(EligiblePool, UsedUpgradeIDs);
        RemoveUsedStatTypes(EligiblePool, UsedStatTypes);

        if (EligiblePool.Length > 0)
        {
            RandomIndex = Rand(EligiblePool.Length);
            SelectedUpgrade = EligiblePool[RandomIndex];
            PlayerOptions.Options.AddItem(SelectedUpgrade);
            UsedUpgradeIDs.AddItem(SelectedUpgrade.UpgradeID);

            if (SelectedUpgrade.StatType != RLST_Special)
                UsedStatTypes.AddItem(SelectedUpgrade.StatType);
        }
        else
        {
            // Fallback to Common
            EligiblePool = BuildEligiblePool(DKPRI.GetRoguelikeTree(), DKPRI.GetRoguelikeCharacter(), RLR_Common, DKPRI);
            RemoveUsedUpgrades(EligiblePool, UsedUpgradeIDs);
            RemoveUsedStatTypes(EligiblePool, UsedStatTypes);

            if (EligiblePool.Length > 0)
            {
                RandomIndex = Rand(EligiblePool.Length);
                SelectedUpgrade = EligiblePool[RandomIndex];
                PlayerOptions.Options.AddItem(SelectedUpgrade);
                UsedUpgradeIDs.AddItem(SelectedUpgrade.UpgradeID);

                if (SelectedUpgrade.StatType != RLST_Special)
                    UsedStatTypes.AddItem(SelectedUpgrade.StatType);
            }
        }
    }

    PendingOptions.AddItem(PlayerOptions);
    SendOptionsToClient(DKPC, PlayerOptions.Options);
}

//=============================================================================
// POOL BUILDING
//=============================================================================

function array<RoguelikeUpgradeData> BuildEligiblePool(byte PlayerTree, byte PlayerCharacter, ERoguelikeRarity TargetRarity, ZTPlayerReplicationInfo DKPRI)
{
    local array<RoguelikeUpgradeData> Result;
    local int i;

    // Universal upgrades of target rarity
    for (i = 0; i < UniversalUpgrades.Length; i++)
    {
        if (UniversalUpgrades[i].Rarity == TargetRarity)
            Result.AddItem(UniversalUpgrades[i]);
    }

    // Eldritch tree upgrades
    if (PlayerTree == 1)
    {
        for (i = 0; i < EldritchTreeUpgrades.Length; i++)
        {
            if (EldritchTreeUpgrades[i].Rarity == TargetRarity)
                Result.AddItem(EldritchTreeUpgrades[i]);
        }
    }

    // Perk Unique upgrades (only when Unique rarity rolls)
    if (TargetRarity == RLR_Unique && DKPRI != None)
    {
        for (i = 0; i < PerkUniques.Length; i++)
        {
            // Skip if player already has this unique
            if (HasPlayerUpgrade(DKPRI, PerkUniques[i].UpgradeID))
                continue;

            // Check if player owns the required perk
            if (HasPlayerPerk(DKPRI, PerkUniques[i].RequiredPerkName))
            {
                Result.AddItem(PerkUniques[i]);
            }
        }

        `log("[DK_ROGUELIKE] BuildEligiblePool: Added perk uniques, total Unique pool=" $ Result.Length);
    }

    return Result;
}

//=============================================================================
// PERK OWNERSHIP HELPERS
//=============================================================================

/** Check if player owns a perk by class path (handles wrapper subclasses via ClassIsChildOf) */
function bool HasPlayerPerk(WMPlayerReplicationInfo WMPRI, string PerkClassPath)
{
    local WMGameReplicationInfo WMGRI;
    local class<WMUpgrade_Perk> TargetClass;
    local int i;

    if (WMPRI == None || PerkClassPath == "")
        return false;

    WMGRI = WMGameReplicationInfo(WorldInfo.GRI);
    if (WMGRI == None)
        return false;

    // Load the target perk class by path
    TargetClass = class<WMUpgrade_Perk>(DynamicLoadObject(PerkClassPath, class'Class', true));
    if (TargetClass == None)
    {
        `log("[DK_ROGUELIKE] WARNING: Could not load perk class:" @ PerkClassPath);
        return false;
    }

    // Check each perk slot — use ClassIsChildOf so wrappers (ZTWrapper_Perk_Berserker) match
    // their parent (WMUpgrade_Perk_Berserker)
    for (i = 0; i < WMGRI.PerkUpgradesList.Length; i++)
    {
        if (WMGRI.PerkUpgradesList[i].PerkUpgrade != None
            && ClassIsChildOf(WMGRI.PerkUpgradesList[i].PerkUpgrade, TargetClass))
        {
            return WMPRI.bPerkUpgrade[i].level > 0;
        }
    }

    return false;
}

/** Check if player already has a specific upgrade by ID */
function bool HasPlayerUpgrade(ZTPlayerReplicationInfo DKPRI, string UpgradeID)
{
    local int i;

    for (i = 0; i < DKPRI.ServerRoguelikeUpgradeIDs.Length; i++)
    {
        if (DKPRI.ServerRoguelikeUpgradeIDs[i] ~= UpgradeID)
            return true;
    }

    return false;
}

/** Check if player has ANY eligible Unique upgrades remaining (perk-based) */
function bool HasAnyEligibleUnique(ZTPlayerReplicationInfo DKPRI)
{
    local int i;

    if (DKPRI == None)
        return false;

    for (i = 0; i < PerkUniques.Length; i++)
    {
        // If player doesn't already have this unique AND owns the required perk
        if (!HasPlayerUpgrade(DKPRI, PerkUniques[i].UpgradeID)
            && HasPlayerPerk(DKPRI, PerkUniques[i].RequiredPerkName))
        {
            return true;
        }
    }

    return false;
}

//=============================================================================
// POOL FILTERING
//=============================================================================

function RemoveUsedUpgrades(out array<RoguelikeUpgradeData> Pool, array<string> UsedIDs)
{
    local int i, j;

    for (i = Pool.Length - 1; i >= 0; i--)
    {
        for (j = 0; j < UsedIDs.Length; j++)
        {
            if (Pool[i].UpgradeID == UsedIDs[j])
            {
                Pool.Remove(i, 1);
                break;
            }
        }
    }
}

function RemoveUsedStatTypes(out array<RoguelikeUpgradeData> Pool, array<ERoguelikeStatType> UsedTypes)
{
    local int i, j;

    for (i = Pool.Length - 1; i >= 0; i--)
    {
        if (Pool[i].StatType == RLST_Special)
            continue;

        for (j = 0; j < UsedTypes.Length; j++)
        {
            if (Pool[i].StatType == UsedTypes[j])
            {
                Pool.Remove(i, 1);
                break;
            }
        }
    }
}

function SendOptionsToClient(ZTPlayerController DKPC, array<RoguelikeUpgradeData> Options)
{
    local int i;
    local ZTPlayerReplicationInfo DKPRI;
    local string AccDisplay;

    DKPRI = ZTPlayerReplicationInfo(DKPC.PlayerReplicationInfo);

    DKPC.ClientReceiveUpgradeSelectionStart();

    for (i = 0; i < Options.Length; i++)
    {
        // Compute accumulated bonus display for this option's stat type
        AccDisplay = GetAccumulatedDisplay(Options[i].StatType, Options[i].bIsPercentage, DKPRI);

        DKPC.ClientReceiveUpgradeOption(
            i,
            Options[i].UpgradeID,
            Options[i].DisplayName,
            Options[i].Description,
            Options[i].IconPath,
            int(Options[i].Rarity),
            AccDisplay
        );
    }

    DKPC.ClientShowUpgradeSelection();
}

/** Build a pre-formatted display string showing the player's accumulated
 *  roguelike bonus for a given stat type. Returns empty string if value is 0
 *  or the stat type has no simple numeric representation. */
function string GetAccumulatedDisplay(ERoguelikeStatType StatType, bool bIsPercentage, ZTPlayerReplicationInfo DKPRI)
{
    local int IntVal;
    local float FloatVal;

    if (DKPRI == None)
    {
        return "";
    }

    switch (StatType)
    {
        case RLST_MaxHealth:
            IntVal = DKPRI.CachedRoguelikeHealthBonus;
            if (IntVal != 0)
            {
                return "Current: +" $ IntVal $ " HP";
            }
            break;

        case RLST_MaxArmor:
            IntVal = DKPRI.CachedRoguelikeArmorBonus;
            if (IntVal != 0)
            {
                return "Current: +" $ IntVal $ " Armor";
            }
            break;

        case RLST_MovementSpeed:
            FloatVal = DKPRI.CachedRoguelikeSpeedMult;
            if (FloatVal != 0)
            {
                return "Current: +" $ FormatPct(FloatVal);
            }
            break;

        case RLST_ReloadSpeed:
            FloatVal = DKPRI.CachedRoguelikeReloadMult;
            if (FloatVal != 0)
            {
                return "Current: +" $ FormatPct(FloatVal);
            }
            break;

        case RLST_AmmoCapacity:
            FloatVal = DKPRI.CachedRoguelikeAmmoMult;
            if (FloatVal != 0)
            {
                return "Current: +" $ FormatPct(FloatVal);
            }
            break;

        case RLST_DamageDealt:
            FloatVal = DKPRI.CachedRoguelikeDamageMult;
            if (FloatVal != 0)
            {
                return "Current: +" $ FormatPct(FloatVal);
            }
            break;

        case RLST_DamageResist:
            FloatVal = DKPRI.CachedRoguelikeDamageResist;
            if (FloatVal != 0)
            {
                return "Current: +" $ FormatPct(FloatVal);
            }
            break;

        case RLST_LargeZedDamage:
            FloatVal = DKPRI.CachedRoguelikeLargeZedDamage;
            if (FloatVal != 0)
            {
                return "Current: +" $ FormatPct(FloatVal);
            }
            break;

        case RLST_Luck:
            FloatVal = DKPRI.CachedRoguelikeLuck;
            if (FloatVal != 0)
            {
                return "Current: +" $ FormatPct(FloatVal);
            }
            break;

        case RLST_Wealthy:
            IntVal = DKPRI.CachedRoguelikeWaveStartDosh;
            if (IntVal != 0)
            {
                return "Current: +" $ IntVal $ " Dosh/Wave";
            }
            break;

        case RLST_GlassCannon:
            FloatVal = DKPRI.CachedRoguelikeDamageMult;
            if (FloatVal != 0)
            {
                return "Dmg: +" $ FormatPct(FloatVal) $ " | HP: -" $ FormatPct(DKPRI.CachedRoguelikeHealthPenaltyPct);
            }
            break;

        case RLST_Sumo:
            FloatVal = DKPRI.CachedRoguelikeDamageResist;
            if (FloatVal != 0)
            {
                return "Resist: +" $ FormatPct(FloatVal) $ " | Spd: -" $ FormatPct(DKPRI.CachedRoguelikeSpeedPenaltyPct);
            }
            break;

        case RLST_Opportunist:
            FloatVal = DKPRI.CachedRoguelikeOpportunistDamage;
            if (FloatVal != 0)
            {
                return "Current: +" $ FormatPct(FloatVal);
            }
            break;

        case RLST_Duelist:
            FloatVal = DKPRI.CachedRoguelikeDuelistDamage;
            if (FloatVal != 0)
            {
                return "Current: +" $ FormatPct(FloatVal);
            }
            break;

        case RLST_LastRound:
            FloatVal = DKPRI.CachedRoguelikeLastRoundDamage;
            if (FloatVal != 0)
            {
                return "Current: +" $ FormatPct(FloatVal);
            }
            break;
    }

    return "";
}

/** Format a float multiplier as percentage string (e.g. 0.15 -> "15%") */
function string FormatPct(float Value)
{
    local int Rounded;

    Rounded = Round(Value * 100.0);
    return string(Rounded) $ "%";
}

//=============================================================================
// PLAYER SELECTION HANDLING
//=============================================================================

function OnPlayerSelectedUpgrade(ZTPlayerController DKPC, int OptionIndex)
{
    local ZTPlayerReplicationInfo DKPRI;
    local int i;
    local RoguelikeUpgradeData SelectedUpgrade;
    local bool bFound;
    local bool bIsCharacterUnique;
    local int PendingIdx, CatchIdx;

    // NOTE: bUpgradeSelectionActive guard removed - causes race condition on listen server
    // The PendingOptions/bFound check below is sufficient validation

    DKPRI = ZTPlayerReplicationInfo(DKPC.PlayerReplicationInfo);
    if (DKPRI == None)
    {
        `log("[DK_ROGUELIKE_APPLY] REJECTED: DKPRI is None");
        return;
    }

    bFound = false;
    PendingIdx = INDEX_NONE;
    for (i = 0; i < PendingOptions.Length; i++)
    {
        if (PendingOptions[i].PC == DKPC)
        {
            if (OptionIndex >= 0 && OptionIndex < PendingOptions[i].Options.Length)
            {
                SelectedUpgrade = PendingOptions[i].Options[OptionIndex];
                bFound = true;
                PendingIdx = i;
            }
            break;
        }
    }

    if (!bFound)
    {
        `log("[DK_ROGUELIKE_APPLY] REJECTED: bFound=false PendingOptions.Length=" $ PendingOptions.Length $ " OptionIndex=" $ OptionIndex);
        return;
    }

    `log("[DK_ROGUELIKE_APPLY]" @ DKPRI.PlayerName @ "selected:" @ SelectedUpgrade.DisplayName);

    // Character uniques set bHasCharacterUnique flag; perk uniques do not
    bIsCharacterUnique = (SelectedUpgrade.PoolType == RLPT_Character && SelectedUpgrade.Rarity == RLR_Unique);

    DKPRI.AddRoguelikeUpgrade(SelectedUpgrade.UpgradeID, bIsCharacterUnique);

    // Consume the option set we just resolved so a re-show generates a fresh one
    if (PendingIdx != INDEX_NONE)
        PendingOptions.Remove(PendingIdx, 1);

    // ----- Late-joiner catch-up branch -----
    // A catch-up pick advances that player's private queue and never touches
    // the group-selection accounting (the two systems are fully decoupled).
    CatchIdx = FindCatchUpIndex(DKPC);
    if (CatchIdx != INDEX_NONE && CatchUpQueue[CatchIdx].bActive)
    {
        CatchUpQueue[CatchIdx].Remaining -= 1;

        if (CatchUpQueue[CatchIdx].Remaining > 0
            && DKPC.Pawn != None && DKPC.Pawn.IsAliveAndWell())
        {
            // Present the next catch-up pick back-to-back (no hide in between).
            `log("[DK_ROGUELIKE_CATCHUP]" @ DKPRI.PlayerName @ "catch-up advanced," @ CatchUpQueue[CatchIdx].Remaining @ "remaining");
            GenerateOptionsForPlayer(DKPC);
        }
        else
        {
            `log("[DK_ROGUELIKE_CATCHUP]" @ DKPRI.PlayerName @ "catch-up complete");
            DKPC.ClientHideUpgradeSelection();
            CatchUpQueue.Remove(CatchIdx, 1);
        }
        return;
    }

    // ----- Normal group-selection branch -----
    PlayersCompletedSelection.AddItem(DKPC);
    DKPC.ClientHideUpgradeSelection();
    CheckAllPlayersSelected();
}

function CheckAllPlayersSelected()
{
    if (PlayersCompletedSelection.Length >= PlayersInSelection.Length)
        EndUpgradeSelection();
}

function EndUpgradeSelection()
{
    bUpgradeSelectionActive = false;
    PlayersInSelection.Length = 0;
    PlayersCompletedSelection.Length = 0;
    PendingOptions.Length = 0;

    // The group selection has fully ended; flush any queued late-joiner
    // catch-up picks now so they run in the same trader.
    ProcessCatchUpQueue();
}

//=============================================================================
// LATE-JOINER CATCH-UP — IMPLEMENTATION
//=============================================================================

/** Index of a player's catch-up queue entry, or INDEX_NONE. */
function int FindCatchUpIndex(ZTPlayerController DKPC)
{
    local int i;

    for (i = 0; i < CatchUpQueue.Length; i++)
    {
        if (CatchUpQueue[i].PC == DKPC)
            return i;
    }

    return INDEX_NONE;
}

/** Queue a late joiner to receive the selections they missed. Owed = number of
 *  group events already held this game, optionally capped by CatchUpMaxSelections.
 *  No-op if nothing is owed. Call from the game mode's PostLogin. */
function EnqueueCatchUp(ZTPlayerController DKPC)
{
    local CatchUpEntry Entry;
    local int Owed, idx;

    if (DKPC == None)
        return;

    Owed = SelectionsHeldThisGame;
    if (CatchUpMaxSelections > 0 && Owed > CatchUpMaxSelections)
        Owed = CatchUpMaxSelections;

    if (Owed <= 0)
        return;

    // Re-join / double PostLogin: refresh the owed count rather than duplicate.
    idx = FindCatchUpIndex(DKPC);
    if (idx != INDEX_NONE)
    {
        CatchUpQueue[idx].Remaining = Owed;
        return;
    }

    Entry.PC = DKPC;
    Entry.Remaining = Owed;
    Entry.bActive = false;
    CatchUpQueue.AddItem(Entry);

    `log("[DK_ROGUELIKE_CATCHUP] Queued" @ DKPC.PlayerReplicationInfo.PlayerName @ "for" @ Owed @ "catch-up selection(s)");
}

/** Present the next pending catch-up pick to each queued, alive player. Gated so
 *  it never overlaps a group selection (that runs first at trader open). Safe to
 *  call repeatedly. Call from OpenTrader (after the normal trigger) and from
 *  EndUpgradeSelection. */
function ProcessCatchUpQueue()
{
    local int i;

    // Never overlap a group selection; it will flush us via EndUpgradeSelection.
    if (bUpgradeSelectionActive)
        return;

    // Drop stale entries (disconnected or already finished).
    for (i = CatchUpQueue.Length - 1; i >= 0; i--)
    {
        if (CatchUpQueue[i].PC == None || CatchUpQueue[i].Remaining <= 0)
            CatchUpQueue.Remove(i, 1);
    }

    for (i = 0; i < CatchUpQueue.Length; i++)
    {
        if (!CatchUpQueue[i].bActive
            && CatchUpQueue[i].PC != None
            && CatchUpQueue[i].PC.Pawn != None
            && CatchUpQueue[i].PC.Pawn.IsAliveAndWell())
        {
            CatchUpQueue[i].bActive = true;
            `log("[DK_ROGUELIKE_CATCHUP] Presenting catch-up to" @ CatchUpQueue[i].PC.PlayerReplicationInfo.PlayerName @ "(" $ CatchUpQueue[i].Remaining @ "owed)");
            GenerateOptionsForPlayer(CatchUpQueue[i].PC);
        }
    }
}

/** Register test options so OnPlayerSelectedUpgrade can find them */
function RegisterTestOptions(ZTPlayerController TestPC, array<string> UpgradeIDs)
{
    local PendingUpgradeOptions TestOptions;
    local RoguelikeUpgradeData FoundUpgrade;
    local int i, j;
    local bool bFoundUpgrade;

    TestOptions.PC = TestPC;
    TestOptions.Options.Length = 0;

    for (i = 0; i < UpgradeIDs.Length; i++)
    {
        bFoundUpgrade = false;

        // Search perk uniques
        for (j = 0; j < PerkUniques.Length; j++)
        {
            if (PerkUniques[j].UpgradeID == UpgradeIDs[i])
            {
                FoundUpgrade = PerkUniques[j];
                bFoundUpgrade = true;
                break;
            }
        }

        // Search universal upgrades
        if (!bFoundUpgrade)
        {
            for (j = 0; j < UniversalUpgrades.Length; j++)
            {
                if (UniversalUpgrades[j].UpgradeID == UpgradeIDs[i])
                {
                    FoundUpgrade = UniversalUpgrades[j];
                    bFoundUpgrade = true;
                    break;
                }
            }
        }

        // Search eldritch tree upgrades
        if (!bFoundUpgrade)
        {
            for (j = 0; j < EldritchTreeUpgrades.Length; j++)
            {
                if (EldritchTreeUpgrades[j].UpgradeID == UpgradeIDs[i])
                {
                    FoundUpgrade = EldritchTreeUpgrades[j];
                    bFoundUpgrade = true;
                    break;
                }
            }
        }

        if (bFoundUpgrade)
        {
            TestOptions.Options.AddItem(FoundUpgrade);
        }
        else
        {
            `log("[DK_TEST] WARNING: Could not find upgrade data for ID:" @ UpgradeIDs[i]);
        }
    }

    // Add to PendingOptions and mark selection active
    PendingOptions.AddItem(TestOptions);
    if (PlayersInSelection.Find(TestPC) == INDEX_NONE)
    {
        PlayersInSelection.AddItem(TestPC);
    }
    bUpgradeSelectionActive = true;

    `log("[DK_TEST] Registered" @ TestOptions.Options.Length @ "test options in PendingOptions");
}

//=============================================================================
// RARITY HELPERS — LUCK SYSTEM
//=============================================================================

function ERoguelikeRarity RollRarityWithLuck(float PlayerLuck, bool bExcludeUnique)
{
    local float Roll;
    local float CommonChance, UncommonChance, RareChance, EpicChance, LegendaryChance;
    local float TotalNonCommon, RedistributionPool;
    local float Cumulative;

    CommonChance = 0.45;
    UncommonChance = 0.25;
    RareChance = 0.15;
    EpicChance = 0.10;
    LegendaryChance = 0.04;

    PlayerLuck = FClamp(PlayerLuck, 0.0, 0.35);
    RedistributionPool = FMin(PlayerLuck, CommonChance - 0.10);
    CommonChance -= RedistributionPool;

    if (bExcludeUnique)
        TotalNonCommon = 0.25 + 0.15 + 0.10 + 0.04;
    else
        TotalNonCommon = 0.25 + 0.15 + 0.10 + 0.04 + 0.01;

    UncommonChance += RedistributionPool * (0.25 / TotalNonCommon);
    RareChance += RedistributionPool * (0.15 / TotalNonCommon);
    EpicChance += RedistributionPool * (0.10 / TotalNonCommon);
    LegendaryChance += RedistributionPool * (0.04 / TotalNonCommon);

    Roll = FRand();
    Cumulative = 0.0;

    Cumulative += CommonChance;
    if (Roll < Cumulative) return RLR_Common;

    Cumulative += UncommonChance;
    if (Roll < Cumulative) return RLR_Uncommon;

    Cumulative += RareChance;
    if (Roll < Cumulative) return RLR_Rare;

    Cumulative += EpicChance;
    if (Roll < Cumulative) return RLR_Epic;

    Cumulative += LegendaryChance;
    if (Roll < Cumulative) return RLR_Legendary;

    return RLR_Unique;
}

function ERoguelikeRarity RollRarity()
{
    return RollRarityWithLuck(0.0, false);
}

function ERoguelikeRarity RollRarityNoUnique()
{
    return RollRarityWithLuck(0.0, true);
}

function string GetRarityName(ERoguelikeRarity Rarity)
{
    switch (Rarity)
    {
        case RLR_Common:    return "Common";
        case RLR_Uncommon:  return "Uncommon";
        case RLR_Rare:      return "Rare";
        case RLR_Epic:      return "Epic";
        case RLR_Legendary: return "Legendary";
        case RLR_Unique:    return "Unique";
        default:            return "Unknown";
    }
}

defaultproperties
{
    UpgradeWaveInterval=3
    UpgradeOptionsCount=3
    bUpgradeSelectionActive=false

    Name="Default__ZTRoguelikeUpgradeManager"
}
