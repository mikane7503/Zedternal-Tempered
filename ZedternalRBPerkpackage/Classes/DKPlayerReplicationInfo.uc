// ===================================================================
// DKPlayerReplicationInfo - Extends WMPlayerReplicationInfo
// Adds perk availability tracking for unlock system
// Adds roguelike upgrade tracking for wave-based progression
// UPDATED: Added Luck stat for better rarity rolls
// UPDATED: Added immediate ammo bonus on upgrade selection
// UPDATED: Added Glass Cannon, Sumo, Opportunist, Duelist, Wealthy, Last Round
// UPDATED: Fixed armor application - now triggers perk recalculation
// UPDATED: Extended weapon upgrade slots from 4096 → 16384
//   Added bWeaponUpgrade_17 through _64 (48 more × 256 = +12288 slots)
// ===================================================================
class DKPlayerReplicationInfo extends WMPlayerReplicationInfo;

// ===================================================================
// TRADER UPGRADE MENU FORK (DK) - our own menu manager reference.
// Parent's UPGMenuManager is private, so the CreateUPGMenu/CloseUPGMenu
// overrides (bottom of file) use this DK-owned reference instead.
// ===================================================================
var DKUI_Menu UPGMenuManagerDK;

// ===================================================================
// EXTENDED PERK SLOTS (256 → 1024)
// Parent has bPerkUpgrade[256] (struct PerkPurchaseStruct{level, bUnlocked}).
// We add 3 more pages (_2/_3/_4) for indices 256..1023.
// Routed via GetPerkLevel/SetPerkLevel/etc helpers; consumer sites in
// DKPlayerController and DKPerk use the helpers for indices >= 256.
// ===================================================================

const DK_MAX_PERKS = 1024;

var repnotify PerkPurchaseStruct bPerkUpgrade_2[256]; // global indices 256..511
var repnotify PerkPurchaseStruct bPerkUpgrade_3[256]; // global indices 512..767
var repnotify PerkPurchaseStruct bPerkUpgrade_4[256]; // global indices 768..1023

// ===================================================================
// EXTENDED WEAPON UPGRADE SLOTS (4096 → 16384)
// Parent has bWeaponUpgrade_1 through _16 (16 × 256 = 4096 slots).
// We add _17 through _64 for 12288 more, total 16384.
// ===================================================================

const DK_MAX_WEAPON_UPGRADES = 51200;

var repnotify byte bWeaponUpgrade_17[256];
var repnotify byte bWeaponUpgrade_18[256];
var repnotify byte bWeaponUpgrade_19[256];
var repnotify byte bWeaponUpgrade_20[256];
var repnotify byte bWeaponUpgrade_21[256];
var repnotify byte bWeaponUpgrade_22[256];
var repnotify byte bWeaponUpgrade_23[256];
var repnotify byte bWeaponUpgrade_24[256];
var repnotify byte bWeaponUpgrade_25[256];
var repnotify byte bWeaponUpgrade_26[256];
var repnotify byte bWeaponUpgrade_27[256];
var repnotify byte bWeaponUpgrade_28[256];
var repnotify byte bWeaponUpgrade_29[256];
var repnotify byte bWeaponUpgrade_30[256];
var repnotify byte bWeaponUpgrade_31[256];
var repnotify byte bWeaponUpgrade_32[256];
var repnotify byte bWeaponUpgrade_33[256];
var repnotify byte bWeaponUpgrade_34[256];
var repnotify byte bWeaponUpgrade_35[256];
var repnotify byte bWeaponUpgrade_36[256];
var repnotify byte bWeaponUpgrade_37[256];
var repnotify byte bWeaponUpgrade_38[256];
var repnotify byte bWeaponUpgrade_39[256];
var repnotify byte bWeaponUpgrade_40[256];
var repnotify byte bWeaponUpgrade_41[256];
var repnotify byte bWeaponUpgrade_42[256];
var repnotify byte bWeaponUpgrade_43[256];
var repnotify byte bWeaponUpgrade_44[256];
var repnotify byte bWeaponUpgrade_45[256];
var repnotify byte bWeaponUpgrade_46[256];
var repnotify byte bWeaponUpgrade_47[256];
var repnotify byte bWeaponUpgrade_48[256];
var repnotify byte bWeaponUpgrade_49[256];
var repnotify byte bWeaponUpgrade_50[256];
var repnotify byte bWeaponUpgrade_51[256];
var repnotify byte bWeaponUpgrade_52[256];
var repnotify byte bWeaponUpgrade_53[256];
var repnotify byte bWeaponUpgrade_54[256];
var repnotify byte bWeaponUpgrade_55[256];
var repnotify byte bWeaponUpgrade_56[256];
var repnotify byte bWeaponUpgrade_57[256];
var repnotify byte bWeaponUpgrade_58[256];
var repnotify byte bWeaponUpgrade_59[256];
var repnotify byte bWeaponUpgrade_60[256];
var repnotify byte bWeaponUpgrade_61[256];
var repnotify byte bWeaponUpgrade_62[256];
var repnotify byte bWeaponUpgrade_63[256];
var repnotify byte bWeaponUpgrade_64[256];
var repnotify byte bWeaponUpgrade_65[256];
var repnotify byte bWeaponUpgrade_66[256];
var repnotify byte bWeaponUpgrade_67[256];
var repnotify byte bWeaponUpgrade_68[256];
var repnotify byte bWeaponUpgrade_69[256];
var repnotify byte bWeaponUpgrade_70[256];
var repnotify byte bWeaponUpgrade_71[256];
var repnotify byte bWeaponUpgrade_72[256];
var repnotify byte bWeaponUpgrade_73[256];
var repnotify byte bWeaponUpgrade_74[256];
var repnotify byte bWeaponUpgrade_75[256];
var repnotify byte bWeaponUpgrade_76[256];
var repnotify byte bWeaponUpgrade_77[256];
var repnotify byte bWeaponUpgrade_78[256];
var repnotify byte bWeaponUpgrade_79[256];
var repnotify byte bWeaponUpgrade_80[256];
var repnotify byte bWeaponUpgrade_81[256];
var repnotify byte bWeaponUpgrade_82[256];
var repnotify byte bWeaponUpgrade_83[256];
var repnotify byte bWeaponUpgrade_84[256];
var repnotify byte bWeaponUpgrade_85[256];
var repnotify byte bWeaponUpgrade_86[256];
var repnotify byte bWeaponUpgrade_87[256];
var repnotify byte bWeaponUpgrade_88[256];
var repnotify byte bWeaponUpgrade_89[256];
var repnotify byte bWeaponUpgrade_90[256];
var repnotify byte bWeaponUpgrade_91[256];
var repnotify byte bWeaponUpgrade_92[256];
var repnotify byte bWeaponUpgrade_93[256];
var repnotify byte bWeaponUpgrade_94[256];
var repnotify byte bWeaponUpgrade_95[256];
var repnotify byte bWeaponUpgrade_96[256];
var repnotify byte bWeaponUpgrade_97[256];
var repnotify byte bWeaponUpgrade_98[256];
var repnotify byte bWeaponUpgrade_99[256];
var repnotify byte bWeaponUpgrade_100[256];
var repnotify byte bWeaponUpgrade_101[256];
var repnotify byte bWeaponUpgrade_102[256];
var repnotify byte bWeaponUpgrade_103[256];
var repnotify byte bWeaponUpgrade_104[256];
var repnotify byte bWeaponUpgrade_105[256];
var repnotify byte bWeaponUpgrade_106[256];
var repnotify byte bWeaponUpgrade_107[256];
var repnotify byte bWeaponUpgrade_108[256];
var repnotify byte bWeaponUpgrade_109[256];
var repnotify byte bWeaponUpgrade_110[256];
var repnotify byte bWeaponUpgrade_111[256];
var repnotify byte bWeaponUpgrade_112[256];
var repnotify byte bWeaponUpgrade_113[256];
var repnotify byte bWeaponUpgrade_114[256];
var repnotify byte bWeaponUpgrade_115[256];
var repnotify byte bWeaponUpgrade_116[256];
var repnotify byte bWeaponUpgrade_117[256];
var repnotify byte bWeaponUpgrade_118[256];
var repnotify byte bWeaponUpgrade_119[256];
var repnotify byte bWeaponUpgrade_120[256];
var repnotify byte bWeaponUpgrade_121[256];
var repnotify byte bWeaponUpgrade_122[256];
var repnotify byte bWeaponUpgrade_123[256];
var repnotify byte bWeaponUpgrade_124[256];
var repnotify byte bWeaponUpgrade_125[256];
var repnotify byte bWeaponUpgrade_126[256];
var repnotify byte bWeaponUpgrade_127[256];
var repnotify byte bWeaponUpgrade_128[256];
var repnotify byte bWeaponUpgrade_129[256];
var repnotify byte bWeaponUpgrade_130[256];
var repnotify byte bWeaponUpgrade_131[256];
var repnotify byte bWeaponUpgrade_132[256];
var repnotify byte bWeaponUpgrade_133[256];
var repnotify byte bWeaponUpgrade_134[256];
var repnotify byte bWeaponUpgrade_135[256];
var repnotify byte bWeaponUpgrade_136[256];
var repnotify byte bWeaponUpgrade_137[256];
var repnotify byte bWeaponUpgrade_138[256];
var repnotify byte bWeaponUpgrade_139[256];
var repnotify byte bWeaponUpgrade_140[256];
var repnotify byte bWeaponUpgrade_141[256];
var repnotify byte bWeaponUpgrade_142[256];
var repnotify byte bWeaponUpgrade_143[256];
var repnotify byte bWeaponUpgrade_144[256];
var repnotify byte bWeaponUpgrade_145[256];
var repnotify byte bWeaponUpgrade_146[256];
var repnotify byte bWeaponUpgrade_147[256];
var repnotify byte bWeaponUpgrade_148[256];
var repnotify byte bWeaponUpgrade_149[256];
var repnotify byte bWeaponUpgrade_150[256];
var repnotify byte bWeaponUpgrade_151[256];
var repnotify byte bWeaponUpgrade_152[256];
var repnotify byte bWeaponUpgrade_153[256];
var repnotify byte bWeaponUpgrade_154[256];
var repnotify byte bWeaponUpgrade_155[256];
var repnotify byte bWeaponUpgrade_156[256];
var repnotify byte bWeaponUpgrade_157[256];
var repnotify byte bWeaponUpgrade_158[256];
var repnotify byte bWeaponUpgrade_159[256];
var repnotify byte bWeaponUpgrade_160[256];
var repnotify byte bWeaponUpgrade_161[256];
var repnotify byte bWeaponUpgrade_162[256];
var repnotify byte bWeaponUpgrade_163[256];
var repnotify byte bWeaponUpgrade_164[256];
var repnotify byte bWeaponUpgrade_165[256];
var repnotify byte bWeaponUpgrade_166[256];
var repnotify byte bWeaponUpgrade_167[256];
var repnotify byte bWeaponUpgrade_168[256];
var repnotify byte bWeaponUpgrade_169[256];
var repnotify byte bWeaponUpgrade_170[256];
var repnotify byte bWeaponUpgrade_171[256];
var repnotify byte bWeaponUpgrade_172[256];
var repnotify byte bWeaponUpgrade_173[256];
var repnotify byte bWeaponUpgrade_174[256];
var repnotify byte bWeaponUpgrade_175[256];
var repnotify byte bWeaponUpgrade_176[256];
var repnotify byte bWeaponUpgrade_177[256];
var repnotify byte bWeaponUpgrade_178[256];
var repnotify byte bWeaponUpgrade_179[256];
var repnotify byte bWeaponUpgrade_180[256];
var repnotify byte bWeaponUpgrade_181[256];
var repnotify byte bWeaponUpgrade_182[256];
var repnotify byte bWeaponUpgrade_183[256];
var repnotify byte bWeaponUpgrade_184[256];
var repnotify byte bWeaponUpgrade_185[256];
var repnotify byte bWeaponUpgrade_186[256];
var repnotify byte bWeaponUpgrade_187[256];
var repnotify byte bWeaponUpgrade_188[256];
var repnotify byte bWeaponUpgrade_189[256];
var repnotify byte bWeaponUpgrade_190[256];
var repnotify byte bWeaponUpgrade_191[256];
var repnotify byte bWeaponUpgrade_192[256];
var repnotify byte bWeaponUpgrade_193[256];
var repnotify byte bWeaponUpgrade_194[256];
var repnotify byte bWeaponUpgrade_195[256];
var repnotify byte bWeaponUpgrade_196[256];
var repnotify byte bWeaponUpgrade_197[256];
var repnotify byte bWeaponUpgrade_198[256];
var repnotify byte bWeaponUpgrade_199[256];
var repnotify byte bWeaponUpgrade_200[256];

// ===================================================================
// ROGUELIKE UPGRADE SYSTEM
// ===================================================================

// Maximum number of roguelike upgrades a player can have
const MAX_ROGUELIKE_UPGRADES = 64;

// Maximum Luck value (caps at 35% so Common never goes below 10%)
const MAX_LUCK = 0.35;

// Replicated core state
var repnotify byte RoguelikeTreeIndex;              // ERoguelikeTree as byte
var repnotify byte RoguelikeCharacterIndex;         // Character index within tree (0-9)
var repnotify bool bHasRoguelikeCharacterUnique;    // Has character's Unique upgrade
var repnotify int RoguelikeTotalUpgrades;           // Total upgrades selected

// Replicated upgrade data (fixed arrays for replication)
// Each upgrade is stored as: ID hash (for lookup) + stack count
var repnotify byte RoguelikeUpgradeIDs[64];         // Index into upgrade pool (0 = empty)
var repnotify byte RoguelikeUpgradeStacks[64];      // Stack count for each upgrade

// ===================================================================
// CACHED ROGUELIKE STATS (Replicated)
// ===================================================================

// Basic stats
var repnotify int CachedRoguelikeHealthBonus;
var repnotify int CachedRoguelikeArmorBonus;
var repnotify float CachedRoguelikeSpeedMult;
var repnotify float CachedRoguelikeReloadMult;
var repnotify float CachedRoguelikeAmmoMult;
var repnotify float CachedRoguelikeDamageMult;
var repnotify float CachedRoguelikeDamageResist;
var repnotify float CachedRoguelikeLargeZedDamage;
var repnotify float CachedRoguelikeLuck;

// Tradeoff stats
var repnotify float CachedRoguelikeHealthPenaltyPct;  // Glass Cannon (reduces max health %)
var repnotify float CachedRoguelikeSpeedPenaltyPct;   // Sumo (reduces speed %)

// Conditional damage bonuses
var repnotify float CachedRoguelikeOpportunistDamage; // Bonus damage from behind
var repnotify float CachedRoguelikeDuelistDamage;     // Bonus damage vs isolated targets
var repnotify float CachedRoguelikeLastRoundDamage;   // Bonus damage on final bullet

// Economy
var repnotify int CachedRoguelikeWaveStartDosh;       // Wealthy bonus dosh per wave

// ===================================================================
// RANK SYSTEM (persists across sessions via client-side INI)
// ===================================================================
var repnotify int PlayerRank;  // 0-500, replicated to all clients for scoreboard display

// ===================================================================
// REFORGED WEAPON UNLOCK BITMASK (per-player)
// Moved off DKGameReplicationInfo, where it was a single game-wide mask
// that leaked Artificer reforge unlocks across all players. Now per-player:
// each player's Artificer kills unlock reforges only for themselves.
// 5 ints x 31 usable bits = 155 slots (131 reforges currently registered).
// Layout matches DKGameReplicationInfo.ReforgedStartIndex bit ordering.
// ===================================================================
var repnotify int ReforgeFlags_0;
var repnotify int ReforgeFlags_1;
var repnotify int ReforgeFlags_2;
var repnotify int ReforgeFlags_3;
var repnotify int ReforgeFlags_4;

// ===================================================================
// DK-SIDE UPGRADE MENU REFERENCE
// We track our own menu manager (UPGMenuManagerDK, declared at top of
// class) because parent's UPGMenuManager is `var private`. See the
// CreateUPGMenu / CloseUPGMenu overrides near defaultproperties.
// ===================================================================

// ===================================================================
// APPLIED BONUS TRACKING (Server-side, not replicated)
// ===================================================================

// Track what bonuses have already been applied to the pawn
var int AppliedHealthBonus;
var int AppliedArmorBonus;
var float AppliedAmmoMult;
var int AppliedHealthPenalty;  // Track applied health penalty (negative value)

// Server-only: Full upgrade ID strings for complex lookups
var array<string> ServerRoguelikeUpgradeIDs;

// Mapping from upgrade pool index to string ID (populated at game start)
var array<string> UpgradePoolMapping;

// ===================================================================
// REPLICATION
// ===================================================================

replication
{
    if (bNetDirty)
        bPerkUpgrade_2, bPerkUpgrade_3, bPerkUpgrade_4,
        bWeaponUpgrade_17, bWeaponUpgrade_18, bWeaponUpgrade_19, bWeaponUpgrade_20,
        bWeaponUpgrade_21, bWeaponUpgrade_22, bWeaponUpgrade_23, bWeaponUpgrade_24,
        bWeaponUpgrade_25, bWeaponUpgrade_26, bWeaponUpgrade_27, bWeaponUpgrade_28,
        bWeaponUpgrade_29, bWeaponUpgrade_30, bWeaponUpgrade_31, bWeaponUpgrade_32,
        bWeaponUpgrade_33, bWeaponUpgrade_34, bWeaponUpgrade_35, bWeaponUpgrade_36,
        bWeaponUpgrade_37, bWeaponUpgrade_38, bWeaponUpgrade_39, bWeaponUpgrade_40,
        bWeaponUpgrade_41, bWeaponUpgrade_42, bWeaponUpgrade_43, bWeaponUpgrade_44,
        bWeaponUpgrade_45, bWeaponUpgrade_46, bWeaponUpgrade_47, bWeaponUpgrade_48,
        bWeaponUpgrade_49, bWeaponUpgrade_50, bWeaponUpgrade_51, bWeaponUpgrade_52,
        bWeaponUpgrade_53, bWeaponUpgrade_54, bWeaponUpgrade_55, bWeaponUpgrade_56,
        bWeaponUpgrade_57, bWeaponUpgrade_58, bWeaponUpgrade_59, bWeaponUpgrade_60,
        bWeaponUpgrade_61, bWeaponUpgrade_62, bWeaponUpgrade_63, bWeaponUpgrade_64,
        bWeaponUpgrade_65, bWeaponUpgrade_66, bWeaponUpgrade_67, bWeaponUpgrade_68,
        bWeaponUpgrade_69, bWeaponUpgrade_70, bWeaponUpgrade_71, bWeaponUpgrade_72,
        bWeaponUpgrade_73, bWeaponUpgrade_74, bWeaponUpgrade_75, bWeaponUpgrade_76,
        bWeaponUpgrade_77, bWeaponUpgrade_78, bWeaponUpgrade_79, bWeaponUpgrade_80,
        bWeaponUpgrade_81, bWeaponUpgrade_82, bWeaponUpgrade_83, bWeaponUpgrade_84,
        bWeaponUpgrade_85, bWeaponUpgrade_86, bWeaponUpgrade_87, bWeaponUpgrade_88,
        bWeaponUpgrade_89, bWeaponUpgrade_90, bWeaponUpgrade_91, bWeaponUpgrade_92,
        bWeaponUpgrade_93, bWeaponUpgrade_94, bWeaponUpgrade_95, bWeaponUpgrade_96,
        bWeaponUpgrade_97, bWeaponUpgrade_98, bWeaponUpgrade_99, bWeaponUpgrade_100,
        bWeaponUpgrade_101, bWeaponUpgrade_102, bWeaponUpgrade_103, bWeaponUpgrade_104,
        bWeaponUpgrade_105, bWeaponUpgrade_106, bWeaponUpgrade_107, bWeaponUpgrade_108,
        bWeaponUpgrade_109, bWeaponUpgrade_110, bWeaponUpgrade_111, bWeaponUpgrade_112,
        bWeaponUpgrade_113, bWeaponUpgrade_114, bWeaponUpgrade_115, bWeaponUpgrade_116,
        bWeaponUpgrade_117, bWeaponUpgrade_118, bWeaponUpgrade_119, bWeaponUpgrade_120,
        bWeaponUpgrade_121, bWeaponUpgrade_122, bWeaponUpgrade_123, bWeaponUpgrade_124,
        bWeaponUpgrade_125, bWeaponUpgrade_126, bWeaponUpgrade_127, bWeaponUpgrade_128,
        bWeaponUpgrade_129, bWeaponUpgrade_130, bWeaponUpgrade_131, bWeaponUpgrade_132,
        bWeaponUpgrade_133, bWeaponUpgrade_134, bWeaponUpgrade_135, bWeaponUpgrade_136,
        bWeaponUpgrade_137, bWeaponUpgrade_138, bWeaponUpgrade_139, bWeaponUpgrade_140,
        bWeaponUpgrade_141, bWeaponUpgrade_142, bWeaponUpgrade_143, bWeaponUpgrade_144,
        bWeaponUpgrade_145, bWeaponUpgrade_146, bWeaponUpgrade_147, bWeaponUpgrade_148,
        bWeaponUpgrade_149, bWeaponUpgrade_150, bWeaponUpgrade_151, bWeaponUpgrade_152,
        bWeaponUpgrade_153, bWeaponUpgrade_154, bWeaponUpgrade_155, bWeaponUpgrade_156,
        bWeaponUpgrade_157, bWeaponUpgrade_158, bWeaponUpgrade_159, bWeaponUpgrade_160,
        bWeaponUpgrade_161, bWeaponUpgrade_162, bWeaponUpgrade_163, bWeaponUpgrade_164,
        bWeaponUpgrade_165, bWeaponUpgrade_166, bWeaponUpgrade_167, bWeaponUpgrade_168,
        bWeaponUpgrade_169, bWeaponUpgrade_170, bWeaponUpgrade_171, bWeaponUpgrade_172,
        bWeaponUpgrade_173, bWeaponUpgrade_174, bWeaponUpgrade_175, bWeaponUpgrade_176,
        bWeaponUpgrade_177, bWeaponUpgrade_178, bWeaponUpgrade_179, bWeaponUpgrade_180,
        bWeaponUpgrade_181, bWeaponUpgrade_182, bWeaponUpgrade_183, bWeaponUpgrade_184,
        bWeaponUpgrade_185, bWeaponUpgrade_186, bWeaponUpgrade_187, bWeaponUpgrade_188,
        bWeaponUpgrade_189, bWeaponUpgrade_190, bWeaponUpgrade_191, bWeaponUpgrade_192,
        bWeaponUpgrade_193, bWeaponUpgrade_194, bWeaponUpgrade_195, bWeaponUpgrade_196,
        bWeaponUpgrade_197, bWeaponUpgrade_198, bWeaponUpgrade_199, bWeaponUpgrade_200,
        RoguelikeTreeIndex, RoguelikeCharacterIndex, 
        bHasRoguelikeCharacterUnique, RoguelikeTotalUpgrades,
        RoguelikeUpgradeIDs, RoguelikeUpgradeStacks,
        CachedRoguelikeHealthBonus, CachedRoguelikeArmorBonus,
        CachedRoguelikeSpeedMult, CachedRoguelikeReloadMult,
        CachedRoguelikeAmmoMult, CachedRoguelikeDamageMult,
        CachedRoguelikeDamageResist, CachedRoguelikeLargeZedDamage,
        CachedRoguelikeLuck,
        CachedRoguelikeHealthPenaltyPct, CachedRoguelikeSpeedPenaltyPct,
        CachedRoguelikeOpportunistDamage, CachedRoguelikeDuelistDamage,
        CachedRoguelikeLastRoundDamage, CachedRoguelikeWaveStartDosh,
        PlayerRank,
        ReforgeFlags_0, ReforgeFlags_1, ReforgeFlags_2, ReforgeFlags_3, ReforgeFlags_4;
}

// ===================================================================
// REPLICATED EVENT HANDLERS
// ===================================================================

simulated event ReplicatedEvent(name VarName)
{
    Super.ReplicatedEvent(VarName);
    
    switch (VarName)
    {
        case 'bPerkUpgrade_2':
        case 'bPerkUpgrade_3':
        case 'bPerkUpgrade_4':
            // Mirror parent behavior for paged perk arrays: flip SyncCompleted
            // and refresh the trader icon (which now reads via GetPerkLevel).
            SyncCompleted = True;
            ClientUpdateCurrentIconToDisplay();
            break;

        case 'bWeaponUpgrade_17':
        case 'bWeaponUpgrade_18':
        case 'bWeaponUpgrade_19':
        case 'bWeaponUpgrade_20':
        case 'bWeaponUpgrade_21':
        case 'bWeaponUpgrade_22':
        case 'bWeaponUpgrade_23':
        case 'bWeaponUpgrade_24':
        case 'bWeaponUpgrade_25':
        case 'bWeaponUpgrade_26':
        case 'bWeaponUpgrade_27':
        case 'bWeaponUpgrade_28':
        case 'bWeaponUpgrade_29':
        case 'bWeaponUpgrade_30':
        case 'bWeaponUpgrade_31':
        case 'bWeaponUpgrade_32':
        case 'bWeaponUpgrade_33':
        case 'bWeaponUpgrade_34':
        case 'bWeaponUpgrade_35':
        case 'bWeaponUpgrade_36':
        case 'bWeaponUpgrade_37':
        case 'bWeaponUpgrade_38':
        case 'bWeaponUpgrade_39':
        case 'bWeaponUpgrade_40':
        case 'bWeaponUpgrade_41':
        case 'bWeaponUpgrade_42':
        case 'bWeaponUpgrade_43':
        case 'bWeaponUpgrade_44':
        case 'bWeaponUpgrade_45':
        case 'bWeaponUpgrade_46':
        case 'bWeaponUpgrade_47':
        case 'bWeaponUpgrade_48':
        case 'bWeaponUpgrade_49':
        case 'bWeaponUpgrade_50':
        case 'bWeaponUpgrade_51':
        case 'bWeaponUpgrade_52':
        case 'bWeaponUpgrade_53':
        case 'bWeaponUpgrade_54':
        case 'bWeaponUpgrade_55':
        case 'bWeaponUpgrade_56':
        case 'bWeaponUpgrade_57':
        case 'bWeaponUpgrade_58':
        case 'bWeaponUpgrade_59':
        case 'bWeaponUpgrade_60':
        case 'bWeaponUpgrade_61':
        case 'bWeaponUpgrade_62':
        case 'bWeaponUpgrade_63':
        case 'bWeaponUpgrade_64':
        case 'bWeaponUpgrade_65':
        case 'bWeaponUpgrade_66':
        case 'bWeaponUpgrade_67':
        case 'bWeaponUpgrade_68':
        case 'bWeaponUpgrade_69':
        case 'bWeaponUpgrade_70':
        case 'bWeaponUpgrade_71':
        case 'bWeaponUpgrade_72':
        case 'bWeaponUpgrade_73':
        case 'bWeaponUpgrade_74':
        case 'bWeaponUpgrade_75':
        case 'bWeaponUpgrade_76':
        case 'bWeaponUpgrade_77':
        case 'bWeaponUpgrade_78':
        case 'bWeaponUpgrade_79':
        case 'bWeaponUpgrade_80':
        case 'bWeaponUpgrade_81':
        case 'bWeaponUpgrade_82':
        case 'bWeaponUpgrade_83':
        case 'bWeaponUpgrade_84':
        case 'bWeaponUpgrade_85':
        case 'bWeaponUpgrade_86':
        case 'bWeaponUpgrade_87':
        case 'bWeaponUpgrade_88':
        case 'bWeaponUpgrade_89':
        case 'bWeaponUpgrade_90':
        case 'bWeaponUpgrade_91':
        case 'bWeaponUpgrade_92':
        case 'bWeaponUpgrade_93':
        case 'bWeaponUpgrade_94':
        case 'bWeaponUpgrade_95':
        case 'bWeaponUpgrade_96':
        case 'bWeaponUpgrade_97':
        case 'bWeaponUpgrade_98':
        case 'bWeaponUpgrade_99':
        case 'bWeaponUpgrade_100':
        case 'bWeaponUpgrade_101':
        case 'bWeaponUpgrade_102':
        case 'bWeaponUpgrade_103':
        case 'bWeaponUpgrade_104':
        case 'bWeaponUpgrade_105':
        case 'bWeaponUpgrade_106':
        case 'bWeaponUpgrade_107':
        case 'bWeaponUpgrade_108':
        case 'bWeaponUpgrade_109':
        case 'bWeaponUpgrade_110':
        case 'bWeaponUpgrade_111':
        case 'bWeaponUpgrade_112':
        case 'bWeaponUpgrade_113':
        case 'bWeaponUpgrade_114':
        case 'bWeaponUpgrade_115':
        case 'bWeaponUpgrade_116':
        case 'bWeaponUpgrade_117':
        case 'bWeaponUpgrade_118':
        case 'bWeaponUpgrade_119':
        case 'bWeaponUpgrade_120':
        case 'bWeaponUpgrade_121':
        case 'bWeaponUpgrade_122':
        case 'bWeaponUpgrade_123':
        case 'bWeaponUpgrade_124':
        case 'bWeaponUpgrade_125':
        case 'bWeaponUpgrade_126':
        case 'bWeaponUpgrade_127':
        case 'bWeaponUpgrade_129':
        case 'bWeaponUpgrade_130':
        case 'bWeaponUpgrade_131':
        case 'bWeaponUpgrade_132':
        case 'bWeaponUpgrade_133':
        case 'bWeaponUpgrade_134':
        case 'bWeaponUpgrade_135':
        case 'bWeaponUpgrade_136':
        case 'bWeaponUpgrade_137':
        case 'bWeaponUpgrade_138':
        case 'bWeaponUpgrade_139':
        case 'bWeaponUpgrade_140':
        case 'bWeaponUpgrade_141':
        case 'bWeaponUpgrade_142':
        case 'bWeaponUpgrade_143':
        case 'bWeaponUpgrade_144':
        case 'bWeaponUpgrade_145':
        case 'bWeaponUpgrade_146':
        case 'bWeaponUpgrade_147':
        case 'bWeaponUpgrade_148':
        case 'bWeaponUpgrade_149':
        case 'bWeaponUpgrade_150':
        case 'bWeaponUpgrade_151':
        case 'bWeaponUpgrade_152':
        case 'bWeaponUpgrade_153':
        case 'bWeaponUpgrade_154':
        case 'bWeaponUpgrade_155':
        case 'bWeaponUpgrade_156':
        case 'bWeaponUpgrade_157':
        case 'bWeaponUpgrade_158':
        case 'bWeaponUpgrade_159':
        case 'bWeaponUpgrade_160':
        case 'bWeaponUpgrade_161':
        case 'bWeaponUpgrade_162':
        case 'bWeaponUpgrade_163':
        case 'bWeaponUpgrade_164':
        case 'bWeaponUpgrade_165':
        case 'bWeaponUpgrade_166':
        case 'bWeaponUpgrade_167':
        case 'bWeaponUpgrade_168':
        case 'bWeaponUpgrade_169':
        case 'bWeaponUpgrade_170':
        case 'bWeaponUpgrade_171':
        case 'bWeaponUpgrade_172':
        case 'bWeaponUpgrade_173':
        case 'bWeaponUpgrade_174':
        case 'bWeaponUpgrade_175':
        case 'bWeaponUpgrade_176':
        case 'bWeaponUpgrade_177':
        case 'bWeaponUpgrade_178':
        case 'bWeaponUpgrade_179':
        case 'bWeaponUpgrade_180':
        case 'bWeaponUpgrade_181':
        case 'bWeaponUpgrade_182':
        case 'bWeaponUpgrade_183':
        case 'bWeaponUpgrade_184':
        case 'bWeaponUpgrade_185':
        case 'bWeaponUpgrade_186':
        case 'bWeaponUpgrade_187':
        case 'bWeaponUpgrade_188':
        case 'bWeaponUpgrade_189':
        case 'bWeaponUpgrade_190':
        case 'bWeaponUpgrade_191':
        case 'bWeaponUpgrade_192':
        case 'bWeaponUpgrade_193':
        case 'bWeaponUpgrade_194':
        case 'bWeaponUpgrade_195':
        case 'bWeaponUpgrade_196':
        case 'bWeaponUpgrade_197':
        case 'bWeaponUpgrade_198':
        case 'bWeaponUpgrade_199':
        case 'bWeaponUpgrade_200':
        case 'bWeaponUpgrade_128':
            // Mirror parent behavior for bWeaponUpgrade_1..16: without these
            // cases, purchases landing in slots >= 4096 never flip
            // SyncCompleted or refresh the UPG menu icon on the client.
            SyncCompleted = True;
            ClientUpdateCurrentIconToDisplay();
            break;
            
        case 'RoguelikeTreeIndex':
        case 'RoguelikeCharacterIndex':
        case 'bHasRoguelikeCharacterUnique':
        case 'RoguelikeTotalUpgrades':
            `log("[DK_ROGUELIKE_NET] Roguelike state replicated - Tree:" @ RoguelikeTreeIndex 
                @ "Char:" @ RoguelikeCharacterIndex 
                @ "HasUnique:" @ bHasRoguelikeCharacterUnique
                @ "TotalUpgrades:" @ RoguelikeTotalUpgrades);
            break;
            
        case 'RoguelikeUpgradeIDs':
        case 'RoguelikeUpgradeStacks':
            `log("[DK_ROGUELIKE_NET] Roguelike upgrades replicated");
            OnRoguelikeStateReplicated();
            break;
            
        case 'CachedRoguelikeHealthBonus':
        case 'CachedRoguelikeArmorBonus':
        case 'CachedRoguelikeSpeedMult':
        case 'CachedRoguelikeReloadMult':
        case 'CachedRoguelikeAmmoMult':
        case 'CachedRoguelikeDamageMult':
        case 'CachedRoguelikeDamageResist':
        case 'CachedRoguelikeLargeZedDamage':
        case 'CachedRoguelikeLuck':
        case 'CachedRoguelikeHealthPenaltyPct':
        case 'CachedRoguelikeSpeedPenaltyPct':
        case 'CachedRoguelikeOpportunistDamage':
        case 'CachedRoguelikeDuelistDamage':
        case 'CachedRoguelikeLastRoundDamage':
        case 'CachedRoguelikeWaveStartDosh':
            `log("[DK_ROGUELIKE_NET] Roguelike cached stats replicated");
            OnRoguelikeStatsReplicated();
            break;
    }
}

// ===================================================================
// ROGUELIKE SYSTEM - INITIALIZATION
// ===================================================================

// Initialize roguelike state for a new game (server-side)
function InitializeRoguelikeState(byte TreeIndex, byte CharacterIndex)
{
    local int i;
    
    if (Role != ROLE_Authority)
        return;
    
    `log("[DK_ROGUELIKE] InitializeRoguelikeState: Tree=" $ TreeIndex $ " Char=" $ CharacterIndex $ " for " $ PlayerName);
    
    RoguelikeTreeIndex = TreeIndex;
    RoguelikeCharacterIndex = CharacterIndex;
    bHasRoguelikeCharacterUnique = false;
    RoguelikeTotalUpgrades = 0;
    
    // Clear upgrade arrays
    for (i = 0; i < MAX_ROGUELIKE_UPGRADES; i++)
    {
        RoguelikeUpgradeIDs[i] = 0;
        RoguelikeUpgradeStacks[i] = 0;
    }
    
    ServerRoguelikeUpgradeIDs.Length = 0;
    
    // Initialize all cached stats to zero/defaults
    CachedRoguelikeHealthBonus = 0;
    CachedRoguelikeArmorBonus = 0;
    CachedRoguelikeSpeedMult = 0.0;
    CachedRoguelikeReloadMult = 0.0;
    CachedRoguelikeAmmoMult = 0.0;
    CachedRoguelikeDamageMult = 0.0;
    CachedRoguelikeDamageResist = 0.0;
    CachedRoguelikeLargeZedDamage = 0.0;
    CachedRoguelikeLuck = 0.0;
    
    // New stats
    CachedRoguelikeHealthPenaltyPct = 0.0;
    CachedRoguelikeSpeedPenaltyPct = 0.0;
    CachedRoguelikeOpportunistDamage = 0.0;
    CachedRoguelikeDuelistDamage = 0.0;
    CachedRoguelikeLastRoundDamage = 0.0;
    CachedRoguelikeWaveStartDosh = 0;
    
    // Reset applied bonus tracking
    AppliedHealthBonus = 0;
    AppliedArmorBonus = 0;
    AppliedAmmoMult = 0.0;
    AppliedHealthPenalty = 0;
    
    `log("[DK_ROGUELIKE] Roguelike state initialized");
}

// ===================================================================
// ROGUELIKE SYSTEM - UPGRADE MANAGEMENT
// ===================================================================

// Add a roguelike upgrade (server-side)
function bool AddRoguelikeUpgrade(string UpgradeID, bool bIsCharacterUnique)
{
    local int i;
    local int EmptySlot;
    local byte PoolIndex;
    
    if (Role != ROLE_Authority)
        return false;
    
    `log("[DK_ROGUELIKE_APPLY] AddRoguelikeUpgrade: " $ UpgradeID $ " for " $ PlayerName);
    
    // Check if already have this upgrade (stack it)
    for (i = 0; i < ServerRoguelikeUpgradeIDs.Length; i++)
    {
        if (ServerRoguelikeUpgradeIDs[i] == UpgradeID)
        {
            // Stack it
            if (RoguelikeUpgradeStacks[i] < 255)
            {
                RoguelikeUpgradeStacks[i]++;
                `log("[DK_ROGUELIKE_APPLY] Stacked upgrade, new count: " $ RoguelikeUpgradeStacks[i]);
            }
            
            RoguelikeTotalUpgrades++;
            RecalculateRoguelikeStats();
            return true;
        }
    }
    
    // New upgrade - find empty slot
    EmptySlot = INDEX_NONE;
    for (i = 0; i < MAX_ROGUELIKE_UPGRADES; i++)
    {
        if (RoguelikeUpgradeIDs[i] == 0)
        {
            EmptySlot = i;
            break;
        }
    }
    
    if (EmptySlot == INDEX_NONE)
    {
        `log("[DK_ROGUELIKE_APPLY] ERROR: No empty slots for new upgrade!");
        return false;
    }
    
    // Convert upgrade ID to pool index (simple hash for replication)
    PoolIndex = GetUpgradePoolIndex(UpgradeID);
    
    // Store upgrade
    RoguelikeUpgradeIDs[EmptySlot] = PoolIndex;
    RoguelikeUpgradeStacks[EmptySlot] = 1;
    ServerRoguelikeUpgradeIDs.AddItem(UpgradeID);
    
    // Track character unique
    if (bIsCharacterUnique)
    {
        bHasRoguelikeCharacterUnique = true;
        `log("[DK_ROGUELIKE_APPLY] Player now has character Unique!");
    }
    
    RoguelikeTotalUpgrades++;
    
    `log("[DK_ROGUELIKE_APPLY] Added new upgrade at slot " $ EmptySlot $ ", total: " $ RoguelikeTotalUpgrades);
    
    // Spawn helper for Perk Unique passives (PERK_X_ prefix)
    SpawnRoguelikeHelper(UpgradeID);
    
    RecalculateRoguelikeStats();
    return true;
}

// Get pool index for an upgrade ID (for replication)
function byte GetUpgradePoolIndex(string UpgradeID)
{
    local int i;
    
    // Check if already in mapping
    for (i = 0; i < UpgradePoolMapping.Length; i++)
    {
        if (UpgradePoolMapping[i] == UpgradeID)
            return byte(i + 1); // +1 because 0 means empty
    }
    
    // Add to mapping
    UpgradePoolMapping.AddItem(UpgradeID);
    return byte(UpgradePoolMapping.Length); // Returns the new index + 1
}

// Get upgrade ID from pool index
simulated function string GetUpgradeIDFromIndex(byte PoolIndex)
{
    if (PoolIndex == 0 || PoolIndex > UpgradePoolMapping.Length)
        return "";
    
    return UpgradePoolMapping[PoolIndex - 1];
}

// Check if player has a specific upgrade
simulated function bool HasRoguelikeUpgrade(string UpgradeID)
{
    local int i;
    
    for (i = 0; i < ServerRoguelikeUpgradeIDs.Length; i++)
    {
        if (ServerRoguelikeUpgradeIDs[i] == UpgradeID)
            return true;
    }
    
    return false;
}

// Get stack count for a specific upgrade
simulated function int GetRoguelikeUpgradeStacks(string UpgradeID)
{
    local int i;
    
    for (i = 0; i < ServerRoguelikeUpgradeIDs.Length; i++)
    {
        if (ServerRoguelikeUpgradeIDs[i] == UpgradeID)
            return RoguelikeUpgradeStacks[i];
    }
    
    return 0;
}

// ===================================================================
// ROGUELIKE SYSTEM - STAT CALCULATION
// ===================================================================

// Recalculate all roguelike stat bonuses (server-side)
function RecalculateRoguelikeStats()
{
    local int i;
    local string UpgradeID;
    local int Stacks;
    
    if (Role != ROLE_Authority)
        return;
    
    `log("[DK_ROGUELIKE] RecalculateRoguelikeStats for " $ PlayerName);
    
    // Reset all cached stats
    CachedRoguelikeHealthBonus = 0;
    CachedRoguelikeArmorBonus = 0;
    CachedRoguelikeSpeedMult = 0.0;
    CachedRoguelikeReloadMult = 0.0;
    CachedRoguelikeAmmoMult = 0.0;
    CachedRoguelikeDamageMult = 0.0;
    CachedRoguelikeDamageResist = 0.0;
    CachedRoguelikeLargeZedDamage = 0.0;
    CachedRoguelikeLuck = 0.0;
    
    // New stats
    CachedRoguelikeHealthPenaltyPct = 0.0;
    CachedRoguelikeSpeedPenaltyPct = 0.0;
    CachedRoguelikeOpportunistDamage = 0.0;
    CachedRoguelikeDuelistDamage = 0.0;
    CachedRoguelikeLastRoundDamage = 0.0;
    CachedRoguelikeWaveStartDosh = 0;
    
    // Sum up all upgrade bonuses
    for (i = 0; i < ServerRoguelikeUpgradeIDs.Length; i++)
    {
        UpgradeID = ServerRoguelikeUpgradeIDs[i];
        Stacks = RoguelikeUpgradeStacks[i];
        
        if (UpgradeID != "" && Stacks > 0)
        {
            AccumulateUpgradeStats(UpgradeID, Stacks);
        }
    }
    
    // Cap Luck at maximum
    if (CachedRoguelikeLuck > MAX_LUCK)
    {
        CachedRoguelikeLuck = MAX_LUCK;
    }
    
    `log("[DK_ROGUELIKE] Stats recalculated - Health:" @ CachedRoguelikeHealthBonus 
        @ "Armor:" @ CachedRoguelikeArmorBonus
        @ "Speed:" @ CachedRoguelikeSpeedMult
        @ "Ammo:" @ CachedRoguelikeAmmoMult
        @ "Damage:" @ CachedRoguelikeDamageMult
        @ "Luck:" @ CachedRoguelikeLuck
        @ "HealthPenalty:" @ CachedRoguelikeHealthPenaltyPct
        @ "SpeedPenalty:" @ CachedRoguelikeSpeedPenaltyPct
        @ "Opportunist:" @ CachedRoguelikeOpportunistDamage
        @ "Duelist:" @ CachedRoguelikeDuelistDamage
        @ "LastRound:" @ CachedRoguelikeLastRoundDamage
        @ "WaveDosh:" @ CachedRoguelikeWaveStartDosh);
    
    // Notify perk to recalculate
    OnRoguelikeUpgradeChanged();
}

// Accumulate stats from a single upgrade (helper)
function AccumulateUpgradeStats(string UpgradeID, int Stacks)
{
    // ========== HEALTH ==========
    if (UpgradeID == "UNIV_C_HEALTH") { CachedRoguelikeHealthBonus += 5 * Stacks; return; }
    if (UpgradeID == "UNIV_U_HEALTH") { CachedRoguelikeHealthBonus += 10 * Stacks; return; }
    if (UpgradeID == "UNIV_R_HEALTH") { CachedRoguelikeHealthBonus += 15 * Stacks; return; }
    if (UpgradeID == "UNIV_E_HEALTH") { CachedRoguelikeHealthBonus += 25 * Stacks; return; }
    if (UpgradeID == "UNIV_L_HEALTH") { CachedRoguelikeHealthBonus += 40 * Stacks; return; }
    
    // ========== ARMOR ==========
    if (UpgradeID == "UNIV_C_ARMOR") { CachedRoguelikeArmorBonus += 5 * Stacks; return; }
    if (UpgradeID == "UNIV_U_ARMOR") { CachedRoguelikeArmorBonus += 10 * Stacks; return; }
    if (UpgradeID == "UNIV_R_ARMOR") { CachedRoguelikeArmorBonus += 15 * Stacks; return; }
    if (UpgradeID == "UNIV_E_ARMOR") { CachedRoguelikeArmorBonus += 25 * Stacks; return; }
    if (UpgradeID == "UNIV_L_ARMOR") { CachedRoguelikeArmorBonus += 40 * Stacks; return; }
    
    // ========== SPEED ==========
    if (UpgradeID == "UNIV_R_SPEED") { CachedRoguelikeSpeedMult += 0.08 * float(Stacks); return; }
    if (UpgradeID == "UNIV_E_SPEED") { CachedRoguelikeSpeedMult += 0.10 * float(Stacks); return; }
    if (UpgradeID == "UNIV_L_SPEED") { CachedRoguelikeSpeedMult += 0.15 * float(Stacks); return; }
    
    // ========== RELOAD ==========
    if (UpgradeID == "UNIV_C_RELOAD") { CachedRoguelikeReloadMult += 0.05 * float(Stacks); return; }
    if (UpgradeID == "UNIV_U_RELOAD") { CachedRoguelikeReloadMult += 0.10 * float(Stacks); return; }
    if (UpgradeID == "UNIV_R_RELOAD") { CachedRoguelikeReloadMult += 0.15 * float(Stacks); return; }
    if (UpgradeID == "UNIV_E_RELOAD") { CachedRoguelikeReloadMult += 0.20 * float(Stacks); return; }
    if (UpgradeID == "UNIV_L_RELOAD") { CachedRoguelikeReloadMult += 0.30 * float(Stacks); return; }
    
    // ========== AMMO ==========
    if (UpgradeID == "UNIV_C_AMMO") { CachedRoguelikeAmmoMult += 0.05 * float(Stacks); return; }
    if (UpgradeID == "UNIV_U_AMMO") { CachedRoguelikeAmmoMult += 0.10 * float(Stacks); return; }
    if (UpgradeID == "UNIV_R_AMMO") { CachedRoguelikeAmmoMult += 0.15 * float(Stacks); return; }
    if (UpgradeID == "UNIV_E_AMMO") { CachedRoguelikeAmmoMult += 0.20 * float(Stacks); return; }
    if (UpgradeID == "UNIV_L_AMMO") { CachedRoguelikeAmmoMult += 0.30 * float(Stacks); return; }
    
    // ========== DAMAGE ==========
    if (UpgradeID == "UNIV_R_DAMAGE") { CachedRoguelikeDamageMult += 0.05 * float(Stacks); return; }
    if (UpgradeID == "UNIV_E_DAMAGE") { CachedRoguelikeDamageMult += 0.08 * float(Stacks); return; }
    if (UpgradeID == "UNIV_L_DAMAGE") { CachedRoguelikeDamageMult += 0.12 * float(Stacks); return; }
    
    // ========== DAMAGE RESIST ==========
    if (UpgradeID == "UNIV_R_RESIST") { CachedRoguelikeDamageResist += 0.05 * float(Stacks); return; }
    if (UpgradeID == "UNIV_E_RESIST") { CachedRoguelikeDamageResist += 0.08 * float(Stacks); return; }
    if (UpgradeID == "UNIV_L_RESIST") { CachedRoguelikeDamageResist += 0.12 * float(Stacks); return; }
    
    // ========== LUCK ==========
    if (UpgradeID == "UNIV_C_LUCK") { CachedRoguelikeLuck += 0.03 * float(Stacks); return; }
    if (UpgradeID == "UNIV_U_LUCK") { CachedRoguelikeLuck += 0.05 * float(Stacks); return; }
    if (UpgradeID == "UNIV_R_LUCK") { CachedRoguelikeLuck += 0.08 * float(Stacks); return; }
    if (UpgradeID == "UNIV_E_LUCK") { CachedRoguelikeLuck += 0.12 * float(Stacks); return; }
    if (UpgradeID == "UNIV_L_LUCK") { CachedRoguelikeLuck += 0.18 * float(Stacks); return; }
    
    // ========== GLASS CANNON (Damage + Health Penalty) ==========
    if (UpgradeID == "UNIV_C_GLASSCANNON") { CachedRoguelikeDamageMult += 0.10 * float(Stacks); CachedRoguelikeHealthPenaltyPct += 0.10 * float(Stacks); return; }
    if (UpgradeID == "UNIV_U_GLASSCANNON") { CachedRoguelikeDamageMult += 0.15 * float(Stacks); CachedRoguelikeHealthPenaltyPct += 0.15 * float(Stacks); return; }
    if (UpgradeID == "UNIV_R_GLASSCANNON") { CachedRoguelikeDamageMult += 0.20 * float(Stacks); CachedRoguelikeHealthPenaltyPct += 0.20 * float(Stacks); return; }
    if (UpgradeID == "UNIV_E_GLASSCANNON") { CachedRoguelikeDamageMult += 0.28 * float(Stacks); CachedRoguelikeHealthPenaltyPct += 0.25 * float(Stacks); return; }
    if (UpgradeID == "UNIV_L_GLASSCANNON") { CachedRoguelikeDamageMult += 0.40 * float(Stacks); CachedRoguelikeHealthPenaltyPct += 0.30 * float(Stacks); return; }
    
    // ========== SUMO (Damage Resist + Speed Penalty) ==========
    if (UpgradeID == "UNIV_C_SUMO") { CachedRoguelikeDamageResist += 0.08 * float(Stacks); CachedRoguelikeSpeedPenaltyPct += 0.05 * float(Stacks); return; }
    if (UpgradeID == "UNIV_U_SUMO") { CachedRoguelikeDamageResist += 0.12 * float(Stacks); CachedRoguelikeSpeedPenaltyPct += 0.08 * float(Stacks); return; }
    if (UpgradeID == "UNIV_R_SUMO") { CachedRoguelikeDamageResist += 0.18 * float(Stacks); CachedRoguelikeSpeedPenaltyPct += 0.10 * float(Stacks); return; }
    if (UpgradeID == "UNIV_E_SUMO") { CachedRoguelikeDamageResist += 0.25 * float(Stacks); CachedRoguelikeSpeedPenaltyPct += 0.12 * float(Stacks); return; }
    if (UpgradeID == "UNIV_L_SUMO") { CachedRoguelikeDamageResist += 0.35 * float(Stacks); CachedRoguelikeSpeedPenaltyPct += 0.15 * float(Stacks); return; }
    
    // ========== OPPORTUNIST (Back Attack Damage) ==========
    if (UpgradeID == "UNIV_C_OPPORTUNIST") { CachedRoguelikeOpportunistDamage += 0.10 * float(Stacks); return; }
    if (UpgradeID == "UNIV_U_OPPORTUNIST") { CachedRoguelikeOpportunistDamage += 0.15 * float(Stacks); return; }
    if (UpgradeID == "UNIV_R_OPPORTUNIST") { CachedRoguelikeOpportunistDamage += 0.22 * float(Stacks); return; }
    if (UpgradeID == "UNIV_E_OPPORTUNIST") { CachedRoguelikeOpportunistDamage += 0.32 * float(Stacks); return; }
    if (UpgradeID == "UNIV_L_OPPORTUNIST") { CachedRoguelikeOpportunistDamage += 0.45 * float(Stacks); return; }
    
    // ========== DUELIST (Isolated Target Damage) ==========
    if (UpgradeID == "UNIV_C_DUELIST") { CachedRoguelikeDuelistDamage += 0.12 * float(Stacks); return; }
    if (UpgradeID == "UNIV_U_DUELIST") { CachedRoguelikeDuelistDamage += 0.18 * float(Stacks); return; }
    if (UpgradeID == "UNIV_R_DUELIST") { CachedRoguelikeDuelistDamage += 0.26 * float(Stacks); return; }
    if (UpgradeID == "UNIV_E_DUELIST") { CachedRoguelikeDuelistDamage += 0.38 * float(Stacks); return; }
    if (UpgradeID == "UNIV_L_DUELIST") { CachedRoguelikeDuelistDamage += 0.55 * float(Stacks); return; }
    
    // ========== WEALTHY (Wave Start Dosh) ==========
    if (UpgradeID == "UNIV_C_WEALTHY") { CachedRoguelikeWaveStartDosh += 50 * Stacks; return; }
    if (UpgradeID == "UNIV_U_WEALTHY") { CachedRoguelikeWaveStartDosh += 100 * Stacks; return; }
    if (UpgradeID == "UNIV_R_WEALTHY") { CachedRoguelikeWaveStartDosh += 175 * Stacks; return; }
    if (UpgradeID == "UNIV_E_WEALTHY") { CachedRoguelikeWaveStartDosh += 275 * Stacks; return; }
    if (UpgradeID == "UNIV_L_WEALTHY") { CachedRoguelikeWaveStartDosh += 400 * Stacks; return; }
    
    // ========== LAST ROUND (Final Bullet Damage) ==========
    if (UpgradeID == "UNIV_C_LASTROUND") { CachedRoguelikeLastRoundDamage += 0.35 * float(Stacks); return; }
    if (UpgradeID == "UNIV_U_LASTROUND") { CachedRoguelikeLastRoundDamage += 0.55 * float(Stacks); return; }
    if (UpgradeID == "UNIV_R_LASTROUND") { CachedRoguelikeLastRoundDamage += 0.80 * float(Stacks); return; }
    if (UpgradeID == "UNIV_E_LASTROUND") { CachedRoguelikeLastRoundDamage += 1.10 * float(Stacks); return; }
    if (UpgradeID == "UNIV_L_LASTROUND") { CachedRoguelikeLastRoundDamage += 1.50 * float(Stacks); return; }
    
    // ========== ELDRITCH - LARGE ZED DAMAGE ==========
    if (UpgradeID == "ELD_C_LARGEZED") { CachedRoguelikeLargeZedDamage += 0.03 * float(Stacks); return; }
    if (UpgradeID == "ELD_U_LARGEZED") { CachedRoguelikeLargeZedDamage += 0.05 * float(Stacks); return; }
    if (UpgradeID == "ELD_R_LARGEZED") { CachedRoguelikeLargeZedDamage += 0.08 * float(Stacks); return; }
    if (UpgradeID == "ELD_E_LARGEZED") { CachedRoguelikeLargeZedDamage += 0.12 * float(Stacks); return; }
    if (UpgradeID == "ELD_L_LARGEZED") { CachedRoguelikeLargeZedDamage += 0.18 * float(Stacks); return; }
    
    // Special/Unique upgrades don't add flat stats - they're handled by helpers
}
// ===================================================================
// ROGUELIKE SYSTEM - PERK UNIQUE HELPER SPAWNING
// ===================================================================

/** Spawn a roguelike helper when a PERK_X_ upgrade is selected */
function SpawnRoguelikeHelper(string UpgradeID)
{
    local string PerkSuffix;
    local string HelperPath;
    local class<DKRoguelikeHelper> HelperClass;
    local DKRoguelikeHelper Helper;
    local KFPawn_Human KFPH;
    local DKPlayerController DKPC;

    // Only for PERK_X_ upgrades
    if (Left(UpgradeID, 7) != "PERK_X_")
        return;

    // Extract perk name suffix: "PERK_X_BERSERKER" -> "BERSERKER"
    PerkSuffix = Mid(UpgradeID, 7);

    // Build class path: DKRoguelikeHelper_BERSERKER
    HelperPath = "ZedternalRBPerkpackage.DKRoguelikeHelper_" $ PerkSuffix;
    HelperClass = class<DKRoguelikeHelper>(DynamicLoadObject(HelperPath, class'Class', true));

    if (HelperClass == None)
    {
        `log("[DK_ROGUELIKE] No helper class for" @ HelperPath @ "- passive not yet implemented");
        return;
    }

    DKPC = DKPlayerController(Owner);
    if (DKPC == None || DKPC.Pawn == None)
        return;

    KFPH = KFPawn_Human(DKPC.Pawn);
    if (KFPH == None)
        return;

    Helper = KFPH.Spawn(HelperClass, KFPH);
    if (Helper != None)
    {
        Helper.Initialize(KFPH);
        `log("[DK_ROGUELIKE] Spawned" @ HelperClass @ "for" @ PlayerName);
    }
}

// ===================================================================
// ROGUELIKE SYSTEM - CALLBACKS
// ===================================================================

// Called when roguelike upgrades change - apply stats immediately
function OnRoguelikeUpgradeChanged()
{
    local DKPlayerController DKPC;
    local WMPawn_Human WMPH;
    local WMPerk WMP;
    
    `log("[DK_ROGUELIKE] Roguelike upgrades changed - applying stats");
    
    // Get the owning player controller
    if (Owner != None)
    {
        DKPC = DKPlayerController(Owner);
    }
    
    if (DKPC == None || DKPC.Pawn == None)
    {
        `log("[DK_ROGUELIKE] Cannot apply stats - no valid pawn");
        return;
    }
    
    WMPH = WMPawn_Human(DKPC.Pawn);
    if (WMPH == None)
    {
        `log("[DK_ROGUELIKE] Cannot apply stats - pawn is not WMPawn_Human");
        return;
    }
    
    // Get the perk
    WMP = WMPerk(DKPC.GetPerk());
    if (WMP == None)
    {
        `log("[DK_ROGUELIKE] Cannot apply stats - no valid WMPerk");
        return;
    }
    
    // ===================================================================
    // TRIGGER PERK RECALCULATION FOR HEALTH AND ARMOR
    // This is the proper way to apply health/armor bonuses in Zedternal
    // The perk's ModifyHealth/ModifyArmorInt functions will read our cached values
    // ===================================================================
    `log("[DK_ROGUELIKE] Triggering perk health/armor recalculation");
    WMP.PerkSetOwnerHealthAndArmorZedternal(true);  // true = also recalculate health
    
    // Log the results
    `log("[DK_ROGUELIKE] After perk recalc - ZedternalHealth:" @ WMPH.Health $ "/" $ WMPH.HealthMax 
        @ "ZedternalArmor:" @ WMPH.ZedternalArmor $ "/" $ WMPH.ZedternalMaxArmor);
    
    // ===================================================================
    // APPLY AMMO BONUS (re-derive spare-ammo CAPACITY for owned weapons)
    // ===================================================================
    // The perk's ModifySpareAmmoAmount / ModifyMaxSpareAmmoAmount hooks add the
    // roguelike bonus, but they only run when a weapon is purchased or
    // resupplied. Weapons already owned when an ammo upgrade is taken mid-wave
    // never re-run those hooks, so their capacity stays stale (and bumping the
    // held count against a stale cap just gets clamped away). Re-derive the cap
    // here instead.
    RefreshRoguelikeAmmoCapacity(WMPH);
    
    `log("[DK_ROGUELIKE] Stats applied successfully");
}

// Re-derive spare-ammo CAPACITY for every weapon the player already owns so
// roguelike ammo bonuses apply retroactively (the perk hooks only run on
// purchase/resupply). InitializeAmmoCapacity recomputes SpareAmmoCapacity from
// class defaults through the full perk modifier chain (incl. the roguelike
// ModifyMaxSpareAmmoAmount hook), so calling it repeatedly does not compound.
// Any newly-unlocked reserve is granted immediately, clamped to the new cap.
function RefreshRoguelikeAmmoCapacity(KFPawn_Human KFPH)
{
    local KFWeapon KFW;
    local Inventory Inv;
    local int OldCap0, OldCap1, Gained;
    
    if (KFPH == None || KFPH.InvManager == None)
        return;
    
    for (Inv = KFPH.InvManager.InventoryChain; Inv != None; Inv = Inv.Inventory)
    {
        KFW = KFWeapon(Inv);
        if (KFW == None)
            continue;
        
        OldCap0 = KFW.SpareAmmoCapacity[0];
        OldCap1 = KFW.SpareAmmoCapacity[1];
        
        // Recompute caps via the perk modifier chain (mag + spare).
        KFW.InitializeAmmoCapacity();
        
        // Grant the newly-unlocked reserve so the bonus is felt immediately.
        Gained = KFW.SpareAmmoCapacity[0] - OldCap0;
        if (Gained > 0)
            KFW.SpareAmmoCount[0] = Min(KFW.SpareAmmoCount[0] + Gained, KFW.SpareAmmoCapacity[0]);
        
        Gained = KFW.SpareAmmoCapacity[1] - OldCap1;
        if (Gained > 0)
            KFW.SpareAmmoCount[1] = Min(KFW.SpareAmmoCount[1] + Gained, KFW.SpareAmmoCapacity[1]);
        
        KFW.bForceNetUpdate = True;
    }
}

// Called on client when roguelike state is replicated
simulated function OnRoguelikeStateReplicated()
{
    `log("[DK_ROGUELIKE_NET] Client received roguelike state update");
}

// Called on client when roguelike stats are replicated
simulated function OnRoguelikeStatsReplicated()
{
    local PlayerController LocalPC;
    local KFPawn_Human KFPH;
    local KFWeapon KFW;
    local Inventory Inv;
    
    `log("[DK_ROGUELIKE_NET] Client received roguelike stats update");
    // Note: Don't call OnRoguelikeUpgradeChanged() on client -- the server
    // applies all stats authoritatively (held SpareAmmoCount replicates down).
    if (Role == ROLE_Authority)
        return;
    
    // Re-derive each owned weapon's spare-ammo CAPACITY on the client so reload
    // prediction and the dev stat overlay match the server. The roguelike hook
    // reads the now-replicated CachedRoguelikeAmmoMult, so the client computes
    // the same cap the server did. We do NOT touch SpareAmmoCount here -- the
    // server owns the authoritative reserve count.
    LocalPC = class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController();
    if (LocalPC == None || LocalPC.PlayerReplicationInfo != self)
        return;
    
    KFPH = KFPawn_Human(LocalPC.Pawn);
    if (KFPH == None || KFPH.InvManager == None)
        return;
    
    for (Inv = KFPH.InvManager.InventoryChain; Inv != None; Inv = Inv.Inventory)
    {
        KFW = KFWeapon(Inv);
        if (KFW != None)
            KFW.InitializeAmmoCapacity();
    }
}

// ===================================================================
// ROGUELIKE SYSTEM - ACCESSORS
// ===================================================================

simulated function byte GetRoguelikeTree() { return RoguelikeTreeIndex; }
simulated function byte GetRoguelikeCharacter() { return RoguelikeCharacterIndex; }
simulated function bool HasCharacterUnique() { return bHasRoguelikeCharacterUnique; }
simulated function int GetTotalRoguelikeUpgrades() { return RoguelikeTotalUpgrades; }

// Basic stats
simulated function int GetRoguelikeHealthBonus() { return CachedRoguelikeHealthBonus; }
simulated function int GetRoguelikeArmorBonus() { return CachedRoguelikeArmorBonus; }
simulated function float GetRoguelikeSpeedMult() { return CachedRoguelikeSpeedMult; }
simulated function float GetRoguelikeReloadMult() { return CachedRoguelikeReloadMult; }
simulated function float GetRoguelikeAmmoMult() { return CachedRoguelikeAmmoMult; }
simulated function float GetRoguelikeDamageMult() { return CachedRoguelikeDamageMult; }
simulated function float GetRoguelikeDamageResist() { return CachedRoguelikeDamageResist; }
simulated function float GetRoguelikeLargeZedDamage() { return CachedRoguelikeLargeZedDamage; }
simulated function float GetRoguelikeLuck() { return CachedRoguelikeLuck; }

// Tradeoff stats
simulated function float GetRoguelikeHealthPenaltyPct() { return CachedRoguelikeHealthPenaltyPct; }
simulated function float GetRoguelikeSpeedPenaltyPct() { return CachedRoguelikeSpeedPenaltyPct; }

// Conditional damage bonuses
simulated function float GetRoguelikeOpportunistDamage() { return CachedRoguelikeOpportunistDamage; }
simulated function float GetRoguelikeDuelistDamage() { return CachedRoguelikeDuelistDamage; }
simulated function float GetRoguelikeLastRoundDamage() { return CachedRoguelikeLastRoundDamage; }

// Economy
simulated function int GetRoguelikeWaveStartDosh() { return CachedRoguelikeWaveStartDosh; }

// ===================================================================
// EXTENDED WEAPON UPGRADE — GetWeaponUpgrade Override
// Parent handles cases 0-15 (indices 0-4095).
// We extend with cases 16-31 (indices 4096-8191).
// ===================================================================

simulated function byte GetWeaponUpgrade(int index)
{
    local int div, shifted;

    div = index / 256;

    // Cases 0-15 handled by parent (bWeaponUpgrade_1 through _16)
    if (div < 16)
        return super.GetWeaponUpgrade(index);

    shifted = index - div * 256;

    switch (div)
    {
        case 16: return bWeaponUpgrade_17[shifted];
        case 17: return bWeaponUpgrade_18[shifted];
        case 18: return bWeaponUpgrade_19[shifted];
        case 19: return bWeaponUpgrade_20[shifted];
        case 20: return bWeaponUpgrade_21[shifted];
        case 21: return bWeaponUpgrade_22[shifted];
        case 22: return bWeaponUpgrade_23[shifted];
        case 23: return bWeaponUpgrade_24[shifted];
        case 24: return bWeaponUpgrade_25[shifted];
        case 25: return bWeaponUpgrade_26[shifted];
        case 26: return bWeaponUpgrade_27[shifted];
        case 27: return bWeaponUpgrade_28[shifted];
        case 28: return bWeaponUpgrade_29[shifted];
        case 29: return bWeaponUpgrade_30[shifted];
        case 30: return bWeaponUpgrade_31[shifted];
        case 31: return bWeaponUpgrade_32[shifted];
        case 32: return bWeaponUpgrade_33[shifted];
        case 33: return bWeaponUpgrade_34[shifted];
        case 34: return bWeaponUpgrade_35[shifted];
        case 35: return bWeaponUpgrade_36[shifted];
        case 36: return bWeaponUpgrade_37[shifted];
        case 37: return bWeaponUpgrade_38[shifted];
        case 38: return bWeaponUpgrade_39[shifted];
        case 39: return bWeaponUpgrade_40[shifted];
        case 40: return bWeaponUpgrade_41[shifted];
        case 41: return bWeaponUpgrade_42[shifted];
        case 42: return bWeaponUpgrade_43[shifted];
        case 43: return bWeaponUpgrade_44[shifted];
        case 44: return bWeaponUpgrade_45[shifted];
        case 45: return bWeaponUpgrade_46[shifted];
        case 46: return bWeaponUpgrade_47[shifted];
        case 47: return bWeaponUpgrade_48[shifted];
        case 48: return bWeaponUpgrade_49[shifted];
        case 49: return bWeaponUpgrade_50[shifted];
        case 50: return bWeaponUpgrade_51[shifted];
        case 51: return bWeaponUpgrade_52[shifted];
        case 52: return bWeaponUpgrade_53[shifted];
        case 53: return bWeaponUpgrade_54[shifted];
        case 54: return bWeaponUpgrade_55[shifted];
        case 55: return bWeaponUpgrade_56[shifted];
        case 56: return bWeaponUpgrade_57[shifted];
        case 57: return bWeaponUpgrade_58[shifted];
        case 58: return bWeaponUpgrade_59[shifted];
        case 59: return bWeaponUpgrade_60[shifted];
        case 60: return bWeaponUpgrade_61[shifted];
        case 61: return bWeaponUpgrade_62[shifted];
        case 62: return bWeaponUpgrade_63[shifted];
        case 63: return bWeaponUpgrade_64[shifted];
        case 64: return bWeaponUpgrade_65[shifted];
        case 65: return bWeaponUpgrade_66[shifted];
        case 66: return bWeaponUpgrade_67[shifted];
        case 67: return bWeaponUpgrade_68[shifted];
        case 68: return bWeaponUpgrade_69[shifted];
        case 69: return bWeaponUpgrade_70[shifted];
        case 70: return bWeaponUpgrade_71[shifted];
        case 71: return bWeaponUpgrade_72[shifted];
        case 72: return bWeaponUpgrade_73[shifted];
        case 73: return bWeaponUpgrade_74[shifted];
        case 74: return bWeaponUpgrade_75[shifted];
        case 75: return bWeaponUpgrade_76[shifted];
        case 76: return bWeaponUpgrade_77[shifted];
        case 77: return bWeaponUpgrade_78[shifted];
        case 78: return bWeaponUpgrade_79[shifted];
        case 79: return bWeaponUpgrade_80[shifted];
        case 80: return bWeaponUpgrade_81[shifted];
        case 81: return bWeaponUpgrade_82[shifted];
        case 82: return bWeaponUpgrade_83[shifted];
        case 83: return bWeaponUpgrade_84[shifted];
        case 84: return bWeaponUpgrade_85[shifted];
        case 85: return bWeaponUpgrade_86[shifted];
        case 86: return bWeaponUpgrade_87[shifted];
        case 87: return bWeaponUpgrade_88[shifted];
        case 88: return bWeaponUpgrade_89[shifted];
        case 89: return bWeaponUpgrade_90[shifted];
        case 90: return bWeaponUpgrade_91[shifted];
        case 91: return bWeaponUpgrade_92[shifted];
        case 92: return bWeaponUpgrade_93[shifted];
        case 93: return bWeaponUpgrade_94[shifted];
        case 94: return bWeaponUpgrade_95[shifted];
        case 95: return bWeaponUpgrade_96[shifted];
        case 96: return bWeaponUpgrade_97[shifted];
        case 97: return bWeaponUpgrade_98[shifted];
        case 98: return bWeaponUpgrade_99[shifted];
        case 99: return bWeaponUpgrade_100[shifted];
        case 100: return bWeaponUpgrade_101[shifted];
        case 101: return bWeaponUpgrade_102[shifted];
        case 102: return bWeaponUpgrade_103[shifted];
        case 103: return bWeaponUpgrade_104[shifted];
        case 104: return bWeaponUpgrade_105[shifted];
        case 105: return bWeaponUpgrade_106[shifted];
        case 106: return bWeaponUpgrade_107[shifted];
        case 107: return bWeaponUpgrade_108[shifted];
        case 108: return bWeaponUpgrade_109[shifted];
        case 109: return bWeaponUpgrade_110[shifted];
        case 110: return bWeaponUpgrade_111[shifted];
        case 111: return bWeaponUpgrade_112[shifted];
        case 112: return bWeaponUpgrade_113[shifted];
        case 113: return bWeaponUpgrade_114[shifted];
        case 114: return bWeaponUpgrade_115[shifted];
        case 115: return bWeaponUpgrade_116[shifted];
        case 116: return bWeaponUpgrade_117[shifted];
        case 117: return bWeaponUpgrade_118[shifted];
        case 118: return bWeaponUpgrade_119[shifted];
        case 119: return bWeaponUpgrade_120[shifted];
        case 120: return bWeaponUpgrade_121[shifted];
        case 121: return bWeaponUpgrade_122[shifted];
        case 122: return bWeaponUpgrade_123[shifted];
        case 123: return bWeaponUpgrade_124[shifted];
        case 124: return bWeaponUpgrade_125[shifted];
        case 125: return bWeaponUpgrade_126[shifted];
        case 126: return bWeaponUpgrade_127[shifted];
        case 127: return bWeaponUpgrade_128[shifted];
        case 128: return bWeaponUpgrade_129[shifted];
        case 129: return bWeaponUpgrade_130[shifted];
        case 130: return bWeaponUpgrade_131[shifted];
        case 131: return bWeaponUpgrade_132[shifted];
        case 132: return bWeaponUpgrade_133[shifted];
        case 133: return bWeaponUpgrade_134[shifted];
        case 134: return bWeaponUpgrade_135[shifted];
        case 135: return bWeaponUpgrade_136[shifted];
        case 136: return bWeaponUpgrade_137[shifted];
        case 137: return bWeaponUpgrade_138[shifted];
        case 138: return bWeaponUpgrade_139[shifted];
        case 139: return bWeaponUpgrade_140[shifted];
        case 140: return bWeaponUpgrade_141[shifted];
        case 141: return bWeaponUpgrade_142[shifted];
        case 142: return bWeaponUpgrade_143[shifted];
        case 143: return bWeaponUpgrade_144[shifted];
        case 144: return bWeaponUpgrade_145[shifted];
        case 145: return bWeaponUpgrade_146[shifted];
        case 146: return bWeaponUpgrade_147[shifted];
        case 147: return bWeaponUpgrade_148[shifted];
        case 148: return bWeaponUpgrade_149[shifted];
        case 149: return bWeaponUpgrade_150[shifted];
        case 150: return bWeaponUpgrade_151[shifted];
        case 151: return bWeaponUpgrade_152[shifted];
        case 152: return bWeaponUpgrade_153[shifted];
        case 153: return bWeaponUpgrade_154[shifted];
        case 154: return bWeaponUpgrade_155[shifted];
        case 155: return bWeaponUpgrade_156[shifted];
        case 156: return bWeaponUpgrade_157[shifted];
        case 157: return bWeaponUpgrade_158[shifted];
        case 158: return bWeaponUpgrade_159[shifted];
        case 159: return bWeaponUpgrade_160[shifted];
        case 160: return bWeaponUpgrade_161[shifted];
        case 161: return bWeaponUpgrade_162[shifted];
        case 162: return bWeaponUpgrade_163[shifted];
        case 163: return bWeaponUpgrade_164[shifted];
        case 164: return bWeaponUpgrade_165[shifted];
        case 165: return bWeaponUpgrade_166[shifted];
        case 166: return bWeaponUpgrade_167[shifted];
        case 167: return bWeaponUpgrade_168[shifted];
        case 168: return bWeaponUpgrade_169[shifted];
        case 169: return bWeaponUpgrade_170[shifted];
        case 170: return bWeaponUpgrade_171[shifted];
        case 171: return bWeaponUpgrade_172[shifted];
        case 172: return bWeaponUpgrade_173[shifted];
        case 173: return bWeaponUpgrade_174[shifted];
        case 174: return bWeaponUpgrade_175[shifted];
        case 175: return bWeaponUpgrade_176[shifted];
        case 176: return bWeaponUpgrade_177[shifted];
        case 177: return bWeaponUpgrade_178[shifted];
        case 178: return bWeaponUpgrade_179[shifted];
        case 179: return bWeaponUpgrade_180[shifted];
        case 180: return bWeaponUpgrade_181[shifted];
        case 181: return bWeaponUpgrade_182[shifted];
        case 182: return bWeaponUpgrade_183[shifted];
        case 183: return bWeaponUpgrade_184[shifted];
        case 184: return bWeaponUpgrade_185[shifted];
        case 185: return bWeaponUpgrade_186[shifted];
        case 186: return bWeaponUpgrade_187[shifted];
        case 187: return bWeaponUpgrade_188[shifted];
        case 188: return bWeaponUpgrade_189[shifted];
        case 189: return bWeaponUpgrade_190[shifted];
        case 190: return bWeaponUpgrade_191[shifted];
        case 191: return bWeaponUpgrade_192[shifted];
        case 192: return bWeaponUpgrade_193[shifted];
        case 193: return bWeaponUpgrade_194[shifted];
        case 194: return bWeaponUpgrade_195[shifted];
        case 195: return bWeaponUpgrade_196[shifted];
        case 196: return bWeaponUpgrade_197[shifted];
        case 197: return bWeaponUpgrade_198[shifted];
        case 198: return bWeaponUpgrade_199[shifted];
        case 199: return bWeaponUpgrade_200[shifted];
        default: return 0;
    }
}

// ===================================================================
// EXTENDED WEAPON UPGRADE — SetWeaponUpgrade Override
// Parent handles cases 0-15 (indices 0-4095).
// We extend with cases 16-31 (indices 4096-8191).
// ===================================================================

simulated function SetWeaponUpgrade(int index, int value)
{
    local int div, shifted;

    div = index / 256;

    // Cases 0-15 handled by parent
    if (div < 16)
    {
        super.SetWeaponUpgrade(index, value);
        return;
    }

    shifted = index - div * 256;

    switch (div)
    {
        case 16: bWeaponUpgrade_17[shifted] = value; break;
        case 17: bWeaponUpgrade_18[shifted] = value; break;
        case 18: bWeaponUpgrade_19[shifted] = value; break;
        case 19: bWeaponUpgrade_20[shifted] = value; break;
        case 20: bWeaponUpgrade_21[shifted] = value; break;
        case 21: bWeaponUpgrade_22[shifted] = value; break;
        case 22: bWeaponUpgrade_23[shifted] = value; break;
        case 23: bWeaponUpgrade_24[shifted] = value; break;
        case 24: bWeaponUpgrade_25[shifted] = value; break;
        case 25: bWeaponUpgrade_26[shifted] = value; break;
        case 26: bWeaponUpgrade_27[shifted] = value; break;
        case 27: bWeaponUpgrade_28[shifted] = value; break;
        case 28: bWeaponUpgrade_29[shifted] = value; break;
        case 29: bWeaponUpgrade_30[shifted] = value; break;
        case 30: bWeaponUpgrade_31[shifted] = value; break;
        case 31: bWeaponUpgrade_32[shifted] = value; break;
        case 32: bWeaponUpgrade_33[shifted] = value; break;
        case 33: bWeaponUpgrade_34[shifted] = value; break;
        case 34: bWeaponUpgrade_35[shifted] = value; break;
        case 35: bWeaponUpgrade_36[shifted] = value; break;
        case 36: bWeaponUpgrade_37[shifted] = value; break;
        case 37: bWeaponUpgrade_38[shifted] = value; break;
        case 38: bWeaponUpgrade_39[shifted] = value; break;
        case 39: bWeaponUpgrade_40[shifted] = value; break;
        case 40: bWeaponUpgrade_41[shifted] = value; break;
        case 41: bWeaponUpgrade_42[shifted] = value; break;
        case 42: bWeaponUpgrade_43[shifted] = value; break;
        case 43: bWeaponUpgrade_44[shifted] = value; break;
        case 44: bWeaponUpgrade_45[shifted] = value; break;
        case 45: bWeaponUpgrade_46[shifted] = value; break;
        case 46: bWeaponUpgrade_47[shifted] = value; break;
        case 47: bWeaponUpgrade_48[shifted] = value; break;
        case 48: bWeaponUpgrade_49[shifted] = value; break;
        case 49: bWeaponUpgrade_50[shifted] = value; break;
        case 50: bWeaponUpgrade_51[shifted] = value; break;
        case 51: bWeaponUpgrade_52[shifted] = value; break;
        case 52: bWeaponUpgrade_53[shifted] = value; break;
        case 53: bWeaponUpgrade_54[shifted] = value; break;
        case 54: bWeaponUpgrade_55[shifted] = value; break;
        case 55: bWeaponUpgrade_56[shifted] = value; break;
        case 56: bWeaponUpgrade_57[shifted] = value; break;
        case 57: bWeaponUpgrade_58[shifted] = value; break;
        case 58: bWeaponUpgrade_59[shifted] = value; break;
        case 59: bWeaponUpgrade_60[shifted] = value; break;
        case 60: bWeaponUpgrade_61[shifted] = value; break;
        case 61: bWeaponUpgrade_62[shifted] = value; break;
        case 62: bWeaponUpgrade_63[shifted] = value; break;
        case 63: bWeaponUpgrade_64[shifted] = value; break;
        case 64: bWeaponUpgrade_65[shifted] = value; break;
        case 65: bWeaponUpgrade_66[shifted] = value; break;
        case 66: bWeaponUpgrade_67[shifted] = value; break;
        case 67: bWeaponUpgrade_68[shifted] = value; break;
        case 68: bWeaponUpgrade_69[shifted] = value; break;
        case 69: bWeaponUpgrade_70[shifted] = value; break;
        case 70: bWeaponUpgrade_71[shifted] = value; break;
        case 71: bWeaponUpgrade_72[shifted] = value; break;
        case 72: bWeaponUpgrade_73[shifted] = value; break;
        case 73: bWeaponUpgrade_74[shifted] = value; break;
        case 74: bWeaponUpgrade_75[shifted] = value; break;
        case 75: bWeaponUpgrade_76[shifted] = value; break;
        case 76: bWeaponUpgrade_77[shifted] = value; break;
        case 77: bWeaponUpgrade_78[shifted] = value; break;
        case 78: bWeaponUpgrade_79[shifted] = value; break;
        case 79: bWeaponUpgrade_80[shifted] = value; break;
        case 80: bWeaponUpgrade_81[shifted] = value; break;
        case 81: bWeaponUpgrade_82[shifted] = value; break;
        case 82: bWeaponUpgrade_83[shifted] = value; break;
        case 83: bWeaponUpgrade_84[shifted] = value; break;
        case 84: bWeaponUpgrade_85[shifted] = value; break;
        case 85: bWeaponUpgrade_86[shifted] = value; break;
        case 86: bWeaponUpgrade_87[shifted] = value; break;
        case 87: bWeaponUpgrade_88[shifted] = value; break;
        case 88: bWeaponUpgrade_89[shifted] = value; break;
        case 89: bWeaponUpgrade_90[shifted] = value; break;
        case 90: bWeaponUpgrade_91[shifted] = value; break;
        case 91: bWeaponUpgrade_92[shifted] = value; break;
        case 92: bWeaponUpgrade_93[shifted] = value; break;
        case 93: bWeaponUpgrade_94[shifted] = value; break;
        case 94: bWeaponUpgrade_95[shifted] = value; break;
        case 95: bWeaponUpgrade_96[shifted] = value; break;
        case 96: bWeaponUpgrade_97[shifted] = value; break;
        case 97: bWeaponUpgrade_98[shifted] = value; break;
        case 98: bWeaponUpgrade_99[shifted] = value; break;
        case 99: bWeaponUpgrade_100[shifted] = value; break;
        case 100: bWeaponUpgrade_101[shifted] = value; break;
        case 101: bWeaponUpgrade_102[shifted] = value; break;
        case 102: bWeaponUpgrade_103[shifted] = value; break;
        case 103: bWeaponUpgrade_104[shifted] = value; break;
        case 104: bWeaponUpgrade_105[shifted] = value; break;
        case 105: bWeaponUpgrade_106[shifted] = value; break;
        case 106: bWeaponUpgrade_107[shifted] = value; break;
        case 107: bWeaponUpgrade_108[shifted] = value; break;
        case 108: bWeaponUpgrade_109[shifted] = value; break;
        case 109: bWeaponUpgrade_110[shifted] = value; break;
        case 110: bWeaponUpgrade_111[shifted] = value; break;
        case 111: bWeaponUpgrade_112[shifted] = value; break;
        case 112: bWeaponUpgrade_113[shifted] = value; break;
        case 113: bWeaponUpgrade_114[shifted] = value; break;
        case 114: bWeaponUpgrade_115[shifted] = value; break;
        case 115: bWeaponUpgrade_116[shifted] = value; break;
        case 116: bWeaponUpgrade_117[shifted] = value; break;
        case 117: bWeaponUpgrade_118[shifted] = value; break;
        case 118: bWeaponUpgrade_119[shifted] = value; break;
        case 119: bWeaponUpgrade_120[shifted] = value; break;
        case 120: bWeaponUpgrade_121[shifted] = value; break;
        case 121: bWeaponUpgrade_122[shifted] = value; break;
        case 122: bWeaponUpgrade_123[shifted] = value; break;
        case 123: bWeaponUpgrade_124[shifted] = value; break;
        case 124: bWeaponUpgrade_125[shifted] = value; break;
        case 125: bWeaponUpgrade_126[shifted] = value; break;
        case 126: bWeaponUpgrade_127[shifted] = value; break;
        case 127: bWeaponUpgrade_128[shifted] = value; break;
        case 128: bWeaponUpgrade_129[shifted] = value; break;
        case 129: bWeaponUpgrade_130[shifted] = value; break;
        case 130: bWeaponUpgrade_131[shifted] = value; break;
        case 131: bWeaponUpgrade_132[shifted] = value; break;
        case 132: bWeaponUpgrade_133[shifted] = value; break;
        case 133: bWeaponUpgrade_134[shifted] = value; break;
        case 134: bWeaponUpgrade_135[shifted] = value; break;
        case 135: bWeaponUpgrade_136[shifted] = value; break;
        case 136: bWeaponUpgrade_137[shifted] = value; break;
        case 137: bWeaponUpgrade_138[shifted] = value; break;
        case 138: bWeaponUpgrade_139[shifted] = value; break;
        case 139: bWeaponUpgrade_140[shifted] = value; break;
        case 140: bWeaponUpgrade_141[shifted] = value; break;
        case 141: bWeaponUpgrade_142[shifted] = value; break;
        case 142: bWeaponUpgrade_143[shifted] = value; break;
        case 143: bWeaponUpgrade_144[shifted] = value; break;
        case 144: bWeaponUpgrade_145[shifted] = value; break;
        case 145: bWeaponUpgrade_146[shifted] = value; break;
        case 146: bWeaponUpgrade_147[shifted] = value; break;
        case 147: bWeaponUpgrade_148[shifted] = value; break;
        case 148: bWeaponUpgrade_149[shifted] = value; break;
        case 149: bWeaponUpgrade_150[shifted] = value; break;
        case 150: bWeaponUpgrade_151[shifted] = value; break;
        case 151: bWeaponUpgrade_152[shifted] = value; break;
        case 152: bWeaponUpgrade_153[shifted] = value; break;
        case 153: bWeaponUpgrade_154[shifted] = value; break;
        case 154: bWeaponUpgrade_155[shifted] = value; break;
        case 155: bWeaponUpgrade_156[shifted] = value; break;
        case 156: bWeaponUpgrade_157[shifted] = value; break;
        case 157: bWeaponUpgrade_158[shifted] = value; break;
        case 158: bWeaponUpgrade_159[shifted] = value; break;
        case 159: bWeaponUpgrade_160[shifted] = value; break;
        case 160: bWeaponUpgrade_161[shifted] = value; break;
        case 161: bWeaponUpgrade_162[shifted] = value; break;
        case 162: bWeaponUpgrade_163[shifted] = value; break;
        case 163: bWeaponUpgrade_164[shifted] = value; break;
        case 164: bWeaponUpgrade_165[shifted] = value; break;
        case 165: bWeaponUpgrade_166[shifted] = value; break;
        case 166: bWeaponUpgrade_167[shifted] = value; break;
        case 167: bWeaponUpgrade_168[shifted] = value; break;
        case 168: bWeaponUpgrade_169[shifted] = value; break;
        case 169: bWeaponUpgrade_170[shifted] = value; break;
        case 170: bWeaponUpgrade_171[shifted] = value; break;
        case 171: bWeaponUpgrade_172[shifted] = value; break;
        case 172: bWeaponUpgrade_173[shifted] = value; break;
        case 173: bWeaponUpgrade_174[shifted] = value; break;
        case 174: bWeaponUpgrade_175[shifted] = value; break;
        case 175: bWeaponUpgrade_176[shifted] = value; break;
        case 176: bWeaponUpgrade_177[shifted] = value; break;
        case 177: bWeaponUpgrade_178[shifted] = value; break;
        case 178: bWeaponUpgrade_179[shifted] = value; break;
        case 179: bWeaponUpgrade_180[shifted] = value; break;
        case 180: bWeaponUpgrade_181[shifted] = value; break;
        case 181: bWeaponUpgrade_182[shifted] = value; break;
        case 182: bWeaponUpgrade_183[shifted] = value; break;
        case 183: bWeaponUpgrade_184[shifted] = value; break;
        case 184: bWeaponUpgrade_185[shifted] = value; break;
        case 185: bWeaponUpgrade_186[shifted] = value; break;
        case 186: bWeaponUpgrade_187[shifted] = value; break;
        case 187: bWeaponUpgrade_188[shifted] = value; break;
        case 188: bWeaponUpgrade_189[shifted] = value; break;
        case 189: bWeaponUpgrade_190[shifted] = value; break;
        case 190: bWeaponUpgrade_191[shifted] = value; break;
        case 191: bWeaponUpgrade_192[shifted] = value; break;
        case 192: bWeaponUpgrade_193[shifted] = value; break;
        case 193: bWeaponUpgrade_194[shifted] = value; break;
        case 194: bWeaponUpgrade_195[shifted] = value; break;
        case 195: bWeaponUpgrade_196[shifted] = value; break;
        case 196: bWeaponUpgrade_197[shifted] = value; break;
        case 197: bWeaponUpgrade_198[shifted] = value; break;
        case 198: bWeaponUpgrade_199[shifted] = value; break;
        case 199: bWeaponUpgrade_200[shifted] = value; break;
        default: return;
    }
}

// ===================================================================
// EXTENDED WEAPON UPGRADE — IncermentWeaponUpgrade Override
// Parent (WMPlayerReplicationInfo) only handles cases 0-15 (indices
// 0-4095). For slot indices >= 4096 the parent's switch hits
// `default: return;` and silently does nothing — the byte counter
// never increments, so upgrades at those slot indices appear to
// purchase (because Purchase_WeaponUpgrade.AddItem still runs in
// BuyWeaponUpgrade) but their level stays 0, so dispatch reads level
// 0 and the effect never applies.
//
// We extend with cases 16-31 (indices 4096-8191).
// ===================================================================

simulated function IncermentWeaponUpgrade(int index)
{
    local int div, shifted;

    div = index / 256;

    // Cases 0-15 handled by parent (bWeaponUpgrade_1 through _16)
    if (div < 16)
    {
        super.IncermentWeaponUpgrade(index);
        return;
    }

    shifted = index - div * 256;

    switch (div)
    {
        case 16: ++bWeaponUpgrade_17[shifted]; break;
        case 17: ++bWeaponUpgrade_18[shifted]; break;
        case 18: ++bWeaponUpgrade_19[shifted]; break;
        case 19: ++bWeaponUpgrade_20[shifted]; break;
        case 20: ++bWeaponUpgrade_21[shifted]; break;
        case 21: ++bWeaponUpgrade_22[shifted]; break;
        case 22: ++bWeaponUpgrade_23[shifted]; break;
        case 23: ++bWeaponUpgrade_24[shifted]; break;
        case 24: ++bWeaponUpgrade_25[shifted]; break;
        case 25: ++bWeaponUpgrade_26[shifted]; break;
        case 26: ++bWeaponUpgrade_27[shifted]; break;
        case 27: ++bWeaponUpgrade_28[shifted]; break;
        case 28: ++bWeaponUpgrade_29[shifted]; break;
        case 29: ++bWeaponUpgrade_30[shifted]; break;
        case 30: ++bWeaponUpgrade_31[shifted]; break;
        case 31: ++bWeaponUpgrade_32[shifted]; break;
        case 32: ++bWeaponUpgrade_33[shifted]; break;
        case 33: ++bWeaponUpgrade_34[shifted]; break;
        case 34: ++bWeaponUpgrade_35[shifted]; break;
        case 35: ++bWeaponUpgrade_36[shifted]; break;
        case 36: ++bWeaponUpgrade_37[shifted]; break;
        case 37: ++bWeaponUpgrade_38[shifted]; break;
        case 38: ++bWeaponUpgrade_39[shifted]; break;
        case 39: ++bWeaponUpgrade_40[shifted]; break;
        case 40: ++bWeaponUpgrade_41[shifted]; break;
        case 41: ++bWeaponUpgrade_42[shifted]; break;
        case 42: ++bWeaponUpgrade_43[shifted]; break;
        case 43: ++bWeaponUpgrade_44[shifted]; break;
        case 44: ++bWeaponUpgrade_45[shifted]; break;
        case 45: ++bWeaponUpgrade_46[shifted]; break;
        case 46: ++bWeaponUpgrade_47[shifted]; break;
        case 47: ++bWeaponUpgrade_48[shifted]; break;
        case 48: ++bWeaponUpgrade_49[shifted]; break;
        case 49: ++bWeaponUpgrade_50[shifted]; break;
        case 50: ++bWeaponUpgrade_51[shifted]; break;
        case 51: ++bWeaponUpgrade_52[shifted]; break;
        case 52: ++bWeaponUpgrade_53[shifted]; break;
        case 53: ++bWeaponUpgrade_54[shifted]; break;
        case 54: ++bWeaponUpgrade_55[shifted]; break;
        case 55: ++bWeaponUpgrade_56[shifted]; break;
        case 56: ++bWeaponUpgrade_57[shifted]; break;
        case 57: ++bWeaponUpgrade_58[shifted]; break;
        case 58: ++bWeaponUpgrade_59[shifted]; break;
        case 59: ++bWeaponUpgrade_60[shifted]; break;
        case 60: ++bWeaponUpgrade_61[shifted]; break;
        case 61: ++bWeaponUpgrade_62[shifted]; break;
        case 62: ++bWeaponUpgrade_63[shifted]; break;
        case 63: ++bWeaponUpgrade_64[shifted]; break;
        case 64: ++bWeaponUpgrade_65[shifted]; break;
        case 65: ++bWeaponUpgrade_66[shifted]; break;
        case 66: ++bWeaponUpgrade_67[shifted]; break;
        case 67: ++bWeaponUpgrade_68[shifted]; break;
        case 68: ++bWeaponUpgrade_69[shifted]; break;
        case 69: ++bWeaponUpgrade_70[shifted]; break;
        case 70: ++bWeaponUpgrade_71[shifted]; break;
        case 71: ++bWeaponUpgrade_72[shifted]; break;
        case 72: ++bWeaponUpgrade_73[shifted]; break;
        case 73: ++bWeaponUpgrade_74[shifted]; break;
        case 74: ++bWeaponUpgrade_75[shifted]; break;
        case 75: ++bWeaponUpgrade_76[shifted]; break;
        case 76: ++bWeaponUpgrade_77[shifted]; break;
        case 77: ++bWeaponUpgrade_78[shifted]; break;
        case 78: ++bWeaponUpgrade_79[shifted]; break;
        case 79: ++bWeaponUpgrade_80[shifted]; break;
        case 80: ++bWeaponUpgrade_81[shifted]; break;
        case 81: ++bWeaponUpgrade_82[shifted]; break;
        case 82: ++bWeaponUpgrade_83[shifted]; break;
        case 83: ++bWeaponUpgrade_84[shifted]; break;
        case 84: ++bWeaponUpgrade_85[shifted]; break;
        case 85: ++bWeaponUpgrade_86[shifted]; break;
        case 86: ++bWeaponUpgrade_87[shifted]; break;
        case 87: ++bWeaponUpgrade_88[shifted]; break;
        case 88: ++bWeaponUpgrade_89[shifted]; break;
        case 89: ++bWeaponUpgrade_90[shifted]; break;
        case 90: ++bWeaponUpgrade_91[shifted]; break;
        case 91: ++bWeaponUpgrade_92[shifted]; break;
        case 92: ++bWeaponUpgrade_93[shifted]; break;
        case 93: ++bWeaponUpgrade_94[shifted]; break;
        case 94: ++bWeaponUpgrade_95[shifted]; break;
        case 95: ++bWeaponUpgrade_96[shifted]; break;
        case 96: ++bWeaponUpgrade_97[shifted]; break;
        case 97: ++bWeaponUpgrade_98[shifted]; break;
        case 98: ++bWeaponUpgrade_99[shifted]; break;
        case 99: ++bWeaponUpgrade_100[shifted]; break;
        case 100: ++bWeaponUpgrade_101[shifted]; break;
        case 101: ++bWeaponUpgrade_102[shifted]; break;
        case 102: ++bWeaponUpgrade_103[shifted]; break;
        case 103: ++bWeaponUpgrade_104[shifted]; break;
        case 104: ++bWeaponUpgrade_105[shifted]; break;
        case 105: ++bWeaponUpgrade_106[shifted]; break;
        case 106: ++bWeaponUpgrade_107[shifted]; break;
        case 107: ++bWeaponUpgrade_108[shifted]; break;
        case 108: ++bWeaponUpgrade_109[shifted]; break;
        case 109: ++bWeaponUpgrade_110[shifted]; break;
        case 110: ++bWeaponUpgrade_111[shifted]; break;
        case 111: ++bWeaponUpgrade_112[shifted]; break;
        case 112: ++bWeaponUpgrade_113[shifted]; break;
        case 113: ++bWeaponUpgrade_114[shifted]; break;
        case 114: ++bWeaponUpgrade_115[shifted]; break;
        case 115: ++bWeaponUpgrade_116[shifted]; break;
        case 116: ++bWeaponUpgrade_117[shifted]; break;
        case 117: ++bWeaponUpgrade_118[shifted]; break;
        case 118: ++bWeaponUpgrade_119[shifted]; break;
        case 119: ++bWeaponUpgrade_120[shifted]; break;
        case 120: ++bWeaponUpgrade_121[shifted]; break;
        case 121: ++bWeaponUpgrade_122[shifted]; break;
        case 122: ++bWeaponUpgrade_123[shifted]; break;
        case 123: ++bWeaponUpgrade_124[shifted]; break;
        case 124: ++bWeaponUpgrade_125[shifted]; break;
        case 125: ++bWeaponUpgrade_126[shifted]; break;
        case 126: ++bWeaponUpgrade_127[shifted]; break;
        case 127: ++bWeaponUpgrade_128[shifted]; break;
        case 128: ++bWeaponUpgrade_129[shifted]; break;
        case 129: ++bWeaponUpgrade_130[shifted]; break;
        case 130: ++bWeaponUpgrade_131[shifted]; break;
        case 131: ++bWeaponUpgrade_132[shifted]; break;
        case 132: ++bWeaponUpgrade_133[shifted]; break;
        case 133: ++bWeaponUpgrade_134[shifted]; break;
        case 134: ++bWeaponUpgrade_135[shifted]; break;
        case 135: ++bWeaponUpgrade_136[shifted]; break;
        case 136: ++bWeaponUpgrade_137[shifted]; break;
        case 137: ++bWeaponUpgrade_138[shifted]; break;
        case 138: ++bWeaponUpgrade_139[shifted]; break;
        case 139: ++bWeaponUpgrade_140[shifted]; break;
        case 140: ++bWeaponUpgrade_141[shifted]; break;
        case 141: ++bWeaponUpgrade_142[shifted]; break;
        case 142: ++bWeaponUpgrade_143[shifted]; break;
        case 143: ++bWeaponUpgrade_144[shifted]; break;
        case 144: ++bWeaponUpgrade_145[shifted]; break;
        case 145: ++bWeaponUpgrade_146[shifted]; break;
        case 146: ++bWeaponUpgrade_147[shifted]; break;
        case 147: ++bWeaponUpgrade_148[shifted]; break;
        case 148: ++bWeaponUpgrade_149[shifted]; break;
        case 149: ++bWeaponUpgrade_150[shifted]; break;
        case 150: ++bWeaponUpgrade_151[shifted]; break;
        case 151: ++bWeaponUpgrade_152[shifted]; break;
        case 152: ++bWeaponUpgrade_153[shifted]; break;
        case 153: ++bWeaponUpgrade_154[shifted]; break;
        case 154: ++bWeaponUpgrade_155[shifted]; break;
        case 155: ++bWeaponUpgrade_156[shifted]; break;
        case 156: ++bWeaponUpgrade_157[shifted]; break;
        case 157: ++bWeaponUpgrade_158[shifted]; break;
        case 158: ++bWeaponUpgrade_159[shifted]; break;
        case 159: ++bWeaponUpgrade_160[shifted]; break;
        case 160: ++bWeaponUpgrade_161[shifted]; break;
        case 161: ++bWeaponUpgrade_162[shifted]; break;
        case 162: ++bWeaponUpgrade_163[shifted]; break;
        case 163: ++bWeaponUpgrade_164[shifted]; break;
        case 164: ++bWeaponUpgrade_165[shifted]; break;
        case 165: ++bWeaponUpgrade_166[shifted]; break;
        case 166: ++bWeaponUpgrade_167[shifted]; break;
        case 167: ++bWeaponUpgrade_168[shifted]; break;
        case 168: ++bWeaponUpgrade_169[shifted]; break;
        case 169: ++bWeaponUpgrade_170[shifted]; break;
        case 170: ++bWeaponUpgrade_171[shifted]; break;
        case 171: ++bWeaponUpgrade_172[shifted]; break;
        case 172: ++bWeaponUpgrade_173[shifted]; break;
        case 173: ++bWeaponUpgrade_174[shifted]; break;
        case 174: ++bWeaponUpgrade_175[shifted]; break;
        case 175: ++bWeaponUpgrade_176[shifted]; break;
        case 176: ++bWeaponUpgrade_177[shifted]; break;
        case 177: ++bWeaponUpgrade_178[shifted]; break;
        case 178: ++bWeaponUpgrade_179[shifted]; break;
        case 179: ++bWeaponUpgrade_180[shifted]; break;
        case 180: ++bWeaponUpgrade_181[shifted]; break;
        case 181: ++bWeaponUpgrade_182[shifted]; break;
        case 182: ++bWeaponUpgrade_183[shifted]; break;
        case 183: ++bWeaponUpgrade_184[shifted]; break;
        case 184: ++bWeaponUpgrade_185[shifted]; break;
        case 185: ++bWeaponUpgrade_186[shifted]; break;
        case 186: ++bWeaponUpgrade_187[shifted]; break;
        case 187: ++bWeaponUpgrade_188[shifted]; break;
        case 188: ++bWeaponUpgrade_189[shifted]; break;
        case 189: ++bWeaponUpgrade_190[shifted]; break;
        case 190: ++bWeaponUpgrade_191[shifted]; break;
        case 191: ++bWeaponUpgrade_192[shifted]; break;
        case 192: ++bWeaponUpgrade_193[shifted]; break;
        case 193: ++bWeaponUpgrade_194[shifted]; break;
        case 194: ++bWeaponUpgrade_195[shifted]; break;
        case 195: ++bWeaponUpgrade_196[shifted]; break;
        case 196: ++bWeaponUpgrade_197[shifted]; break;
        case 197: ++bWeaponUpgrade_198[shifted]; break;
        case 198: ++bWeaponUpgrade_199[shifted]; break;
        case 199: ++bWeaponUpgrade_200[shifted]; break;
        default: return;
    }
}

// ===================================================================
// EXTENDED PERK / WEAPON UPGRADE — UpdatePurchase Override
// Parent rebuilds Purchase_PerkUpgrade for 0..255 and
// Purchase_WeaponUpgrade for 0..MAXWEAPONUPGRADES-1.
// We extend BOTH loops to cover our additional ranges:
//   - Perks: 256..1023 via paged GetPerkLevel
//   - Weapon upgrades: 4096..8191 via paged GetWeaponUpgrade
// ===================================================================

simulated function UpdatePurchase()
{
    local int i;

    // Parent handles perks (0..255), skills (0..1023), equipment (0..255),
    // and weapon upgrades (0..MAXWEAPONUPGRADES-1 = 0..4095)
    super.UpdatePurchase();

    // Extend perk loop for paged slots (256..1023)
    for (i = 256; i < DK_MAX_PERKS; ++i)
    {
        if (GetPerkLevel(i) > 0)
            Purchase_PerkUpgrade.AddItem(i);
    }

    // Extend weapon upgrade loop for our additional slots (4096..8191)
    for (i = `MAXWEAPONUPGRADES; i < DK_MAX_WEAPON_UPGRADES; ++i)
    {
        if (GetWeaponUpgrade(i) > 0)
            Purchase_WeaponUpgrade.AddItem(i);
    }
}

// ===================================================================
// EXTENDED PERK — Paged Helpers
// Page 0 (indices 0..255) lives in parent's bPerkUpgrade[256] struct array.
// Pages 1..3 (indices 256..1023) live in our bPerkUpgrade_2/3/4 arrays.
//
// Use these EVERYWHERE we'd otherwise read/write WMPRI.bPerkUpgrade[i].
// Direct access to bPerkUpgrade[i] for i>=256 returns the zeroed default
// (UE3 OOB read on a static array) and silently corrupts state.
// ===================================================================

simulated function byte GetPerkLevel(int index)
{
    local int div, shifted;

    if (index < 0 || index >= DK_MAX_PERKS)
        return 0;

    div = index / 256;
    shifted = index - div * 256;

    switch (div)
    {
        case 0: return bPerkUpgrade[shifted].level;
        case 1: return bPerkUpgrade_2[shifted].level;
        case 2: return bPerkUpgrade_3[shifted].level;
        case 3: return bPerkUpgrade_4[shifted].level;
        default: return 0;
    }
}

simulated function SetPerkLevel(int index, byte newLevel)
{
    local int div, shifted;

    if (index < 0 || index >= DK_MAX_PERKS)
        return;

    div = index / 256;
    shifted = index - div * 256;

    switch (div)
    {
        case 0: bPerkUpgrade[shifted].level = newLevel;     break;
        case 1: bPerkUpgrade_2[shifted].level = newLevel;   break;
        case 2: bPerkUpgrade_3[shifted].level = newLevel;   break;
        case 3: bPerkUpgrade_4[shifted].level = newLevel;   break;
    }
}

simulated function IncrementPerkLevel(int index)
{
    local int div, shifted;

    if (index < 0 || index >= DK_MAX_PERKS)
        return;

    div = index / 256;
    shifted = index - div * 256;

    switch (div)
    {
        case 0: ++bPerkUpgrade[shifted].level;      break;
        case 1: ++bPerkUpgrade_2[shifted].level;    break;
        case 2: ++bPerkUpgrade_3[shifted].level;    break;
        case 3: ++bPerkUpgrade_4[shifted].level;    break;
    }
}

simulated function bool IsPerkUnlocked(int index)
{
    local int div, shifted;

    if (index < 0 || index >= DK_MAX_PERKS)
        return false;

    div = index / 256;
    shifted = index - div * 256;

    switch (div)
    {
        case 0: return bPerkUpgrade[shifted].bUnlocked;
        case 1: return bPerkUpgrade_2[shifted].bUnlocked;
        case 2: return bPerkUpgrade_3[shifted].bUnlocked;
        case 3: return bPerkUpgrade_4[shifted].bUnlocked;
        default: return false;
    }
}

simulated function SetPerkUnlocked(int index, bool bUnlock)
{
    local int div, shifted;

    if (index < 0 || index >= DK_MAX_PERKS)
        return;

    div = index / 256;
    shifted = index - div * 256;

    switch (div)
    {
        case 0: bPerkUpgrade[shifted].bUnlocked = bUnlock;      break;
        case 1: bPerkUpgrade_2[shifted].bUnlocked = bUnlock;    break;
        case 2: bPerkUpgrade_3[shifted].bUnlocked = bUnlock;    break;
        case 3: bPerkUpgrade_4[shifted].bUnlocked = bUnlock;    break;
    }
}

// ===================================================================
// EXTENDED PERK — RecalculatePlayerLevel Override
// Parent reads bPerkUpgrade[index].level directly for every entry in
// Purchase_PerkUpgrade. For index >= 256 that's an OOB read returning 0.
// We re-implement using GetPerkLevel for paged correctness.
// ===================================================================

function RecalculatePlayerLevel()
{
    local int index, level;
    local WMGameReplicationInfo WMGRI;

    WMGRI = WMGameReplicationInfo(WorldInfo.GRI);

    if (WMGRI != None)
    {
        PlayerLevel = 0;
        PerkIconIndex = INDEX_NONE;

        foreach Purchase_PerkUpgrade(index)
        {
            for (level = 0; level < GetPerkLevel(index); ++level)
            {
                // PerkUpgPrice is fixed [256] on parent. For perks beyond
                // index 255, the paged price doesn't exist on parent;
                // pass 0 (icon-priority is dosh-based; level still increases).
                if (level < 256)
                    UpdateCurrentIconToDisplay(index, WMGRI.PerkUpgPrice[level], 1);
                else
                    UpdateCurrentIconToDisplay(index, 0, 1);
            }
        }

        foreach Purchase_SkillUpgrade(index)
        {
            for (level = 0; level < WMGRI.PerkUpgradesList.length; ++level)
            {
                if (PathName(WMGRI.PerkUpgradesList[level].PerkUpgrade) ~= WMGRI.SkillUpgradesList[index].PerkPathName)
                    break;
            }

            if (IsSkillDeluxe(index))
                UpdateCurrentIconToDisplay(level, WMGRI.SkillUpgDeluxePrice, 3);
            else
                UpdateCurrentIconToDisplay(level, WMGRI.SkillUpgPrice, 1);
        }

        foreach Purchase_EquipmentUpgrade(index)
        {
            PlayerLevel += bEquipmentUpgrade[index];
        }
    }
}

// ===================================================================
// EXTENDED PERK — ClientUpdateCurrentIconToDisplay Override
// Parent reads bPerkUpgrade[PerkIconIndex].level directly. OOB for >=256.
// ===================================================================

simulated function ClientUpdateCurrentIconToDisplay()
{
    local WMGameReplicationInfo WMGRI;
    local byte L;

    WMGRI = WMGameReplicationInfo(WorldInfo.GRI);

    if (WMGRI != None && PerkIconIndex != INDEX_NONE
        && PerkIconIndex < WMGRI.PerkUpgradesList.Length
        && WMGRI.PerkUpgradesList[PerkIconIndex].PerkUpgrade != None)
    {
        L = GetPerkLevel(PerkIconIndex);
        if (L > 0)
            CurrentIconToDisplay = WMGRI.PerkUpgradesList[PerkIconIndex].PerkUpgrade.static.GetUpgradeIcon(L - 1);
    }
}

// ===================================================================
// EXTENDED PERK — UpdateCurrentIconToDisplay Override
// Parent reads bPerkUpgrade[lastBoughtIndex].level. OOB for >=256.
// ===================================================================

function UpdateCurrentIconToDisplay(int lastBoughtIndex, int doshSpent, int lvl)
{
    local WMGameReplicationInfo WMGRI;
    local int i;
    local byte L;

    WMGRI = WMGameReplicationInfo(WorldInfo.GRI);

    if (WMGRI != None)
    {
        // Initialize doshRecord if needed
        if (PerkIconIndex == INDEX_NONE)
        {
            MaxDoshSpent = 0;
            for (i = 0; i < WMGRI.PerkUpgradesList.length; ++i)
            {
                DoshSpentOnPerk[i] = 0;
            }
        }

        // Bounds-check lastBoughtIndex against PerkUpgradesList for safety
        if (lastBoughtIndex >= 0 && lastBoughtIndex < WMGRI.PerkUpgradesList.length)
        {
            DoshSpentOnPerk[lastBoughtIndex] += doshSpent;

            if (PerkIconIndex == INDEX_NONE || DoshSpentOnPerk[lastBoughtIndex] >= MaxDoshSpent)
            {
                if (WMGRI.PerkUpgradesList[lastBoughtIndex].PerkUpgrade != None)
                {
                    L = GetPerkLevel(lastBoughtIndex);
                    if (L > 0)
                        CurrentIconToDisplay = WMGRI.PerkUpgradesList[lastBoughtIndex].PerkUpgrade.static.GetUpgradeIcon(L - 1);
                }
                MaxDoshSpent = DoshSpentOnPerk[lastBoughtIndex];
                PerkIconIndex = lastBoughtIndex;
            }
        }

        // Increase player level
        PlayerLevel += lvl;
    }
}

// ===================================================================
// EXTENDED PERK / WEAPON UPGRADE — CopyProperties Override
// Parent's CopyProperties only knows about its own arrays. We extend
// it to also copy our paged perk arrays (_2/_3/_4) and paged weapon
// upgrade arrays (_17 through _32) plus rank/roguelike state.
// Called when PlayerReplicationInfo is replaced (e.g. team switch).
// ===================================================================

function CopyProperties(PlayerReplicationInfo PRI)
{
    local DKPlayerReplicationInfo DKPRI;
    local int i;

    super.CopyProperties(PRI);

    DKPRI = DKPlayerReplicationInfo(PRI);
    if (DKPRI != None)
    {
        for (i = 0; i < 256; ++i)
        {
            DKPRI.bPerkUpgrade_2[i] = bPerkUpgrade_2[i];
            DKPRI.bPerkUpgrade_3[i] = bPerkUpgrade_3[i];
            DKPRI.bPerkUpgrade_4[i] = bPerkUpgrade_4[i];
            DKPRI.bWeaponUpgrade_17[i] = bWeaponUpgrade_17[i];
            DKPRI.bWeaponUpgrade_18[i] = bWeaponUpgrade_18[i];
            DKPRI.bWeaponUpgrade_19[i] = bWeaponUpgrade_19[i];
            DKPRI.bWeaponUpgrade_20[i] = bWeaponUpgrade_20[i];
            DKPRI.bWeaponUpgrade_21[i] = bWeaponUpgrade_21[i];
            DKPRI.bWeaponUpgrade_22[i] = bWeaponUpgrade_22[i];
            DKPRI.bWeaponUpgrade_23[i] = bWeaponUpgrade_23[i];
            DKPRI.bWeaponUpgrade_24[i] = bWeaponUpgrade_24[i];
            DKPRI.bWeaponUpgrade_25[i] = bWeaponUpgrade_25[i];
            DKPRI.bWeaponUpgrade_26[i] = bWeaponUpgrade_26[i];
            DKPRI.bWeaponUpgrade_27[i] = bWeaponUpgrade_27[i];
            DKPRI.bWeaponUpgrade_28[i] = bWeaponUpgrade_28[i];
            DKPRI.bWeaponUpgrade_29[i] = bWeaponUpgrade_29[i];
            DKPRI.bWeaponUpgrade_30[i] = bWeaponUpgrade_30[i];
            DKPRI.bWeaponUpgrade_31[i] = bWeaponUpgrade_31[i];
            DKPRI.bWeaponUpgrade_32[i] = bWeaponUpgrade_32[i];
            DKPRI.bWeaponUpgrade_33[i] = bWeaponUpgrade_33[i];
            DKPRI.bWeaponUpgrade_34[i] = bWeaponUpgrade_34[i];
            DKPRI.bWeaponUpgrade_35[i] = bWeaponUpgrade_35[i];
            DKPRI.bWeaponUpgrade_36[i] = bWeaponUpgrade_36[i];
            DKPRI.bWeaponUpgrade_37[i] = bWeaponUpgrade_37[i];
            DKPRI.bWeaponUpgrade_38[i] = bWeaponUpgrade_38[i];
            DKPRI.bWeaponUpgrade_39[i] = bWeaponUpgrade_39[i];
            DKPRI.bWeaponUpgrade_40[i] = bWeaponUpgrade_40[i];
            DKPRI.bWeaponUpgrade_41[i] = bWeaponUpgrade_41[i];
            DKPRI.bWeaponUpgrade_42[i] = bWeaponUpgrade_42[i];
            DKPRI.bWeaponUpgrade_43[i] = bWeaponUpgrade_43[i];
            DKPRI.bWeaponUpgrade_44[i] = bWeaponUpgrade_44[i];
            DKPRI.bWeaponUpgrade_45[i] = bWeaponUpgrade_45[i];
            DKPRI.bWeaponUpgrade_46[i] = bWeaponUpgrade_46[i];
            DKPRI.bWeaponUpgrade_47[i] = bWeaponUpgrade_47[i];
            DKPRI.bWeaponUpgrade_48[i] = bWeaponUpgrade_48[i];
            DKPRI.bWeaponUpgrade_49[i] = bWeaponUpgrade_49[i];
            DKPRI.bWeaponUpgrade_50[i] = bWeaponUpgrade_50[i];
            DKPRI.bWeaponUpgrade_51[i] = bWeaponUpgrade_51[i];
            DKPRI.bWeaponUpgrade_52[i] = bWeaponUpgrade_52[i];
            DKPRI.bWeaponUpgrade_53[i] = bWeaponUpgrade_53[i];
            DKPRI.bWeaponUpgrade_54[i] = bWeaponUpgrade_54[i];
            DKPRI.bWeaponUpgrade_55[i] = bWeaponUpgrade_55[i];
            DKPRI.bWeaponUpgrade_56[i] = bWeaponUpgrade_56[i];
            DKPRI.bWeaponUpgrade_57[i] = bWeaponUpgrade_57[i];
            DKPRI.bWeaponUpgrade_58[i] = bWeaponUpgrade_58[i];
            DKPRI.bWeaponUpgrade_59[i] = bWeaponUpgrade_59[i];
            DKPRI.bWeaponUpgrade_60[i] = bWeaponUpgrade_60[i];
            DKPRI.bWeaponUpgrade_61[i] = bWeaponUpgrade_61[i];
            DKPRI.bWeaponUpgrade_62[i] = bWeaponUpgrade_62[i];
            DKPRI.bWeaponUpgrade_63[i] = bWeaponUpgrade_63[i];
            DKPRI.bWeaponUpgrade_64[i] = bWeaponUpgrade_64[i];
            DKPRI.bWeaponUpgrade_65[i] = bWeaponUpgrade_65[i];
            DKPRI.bWeaponUpgrade_66[i] = bWeaponUpgrade_66[i];
            DKPRI.bWeaponUpgrade_67[i] = bWeaponUpgrade_67[i];
            DKPRI.bWeaponUpgrade_68[i] = bWeaponUpgrade_68[i];
            DKPRI.bWeaponUpgrade_69[i] = bWeaponUpgrade_69[i];
            DKPRI.bWeaponUpgrade_70[i] = bWeaponUpgrade_70[i];
            DKPRI.bWeaponUpgrade_71[i] = bWeaponUpgrade_71[i];
            DKPRI.bWeaponUpgrade_72[i] = bWeaponUpgrade_72[i];
            DKPRI.bWeaponUpgrade_73[i] = bWeaponUpgrade_73[i];
            DKPRI.bWeaponUpgrade_74[i] = bWeaponUpgrade_74[i];
            DKPRI.bWeaponUpgrade_75[i] = bWeaponUpgrade_75[i];
            DKPRI.bWeaponUpgrade_76[i] = bWeaponUpgrade_76[i];
            DKPRI.bWeaponUpgrade_77[i] = bWeaponUpgrade_77[i];
            DKPRI.bWeaponUpgrade_78[i] = bWeaponUpgrade_78[i];
            DKPRI.bWeaponUpgrade_79[i] = bWeaponUpgrade_79[i];
            DKPRI.bWeaponUpgrade_80[i] = bWeaponUpgrade_80[i];
            DKPRI.bWeaponUpgrade_81[i] = bWeaponUpgrade_81[i];
            DKPRI.bWeaponUpgrade_82[i] = bWeaponUpgrade_82[i];
            DKPRI.bWeaponUpgrade_83[i] = bWeaponUpgrade_83[i];
            DKPRI.bWeaponUpgrade_84[i] = bWeaponUpgrade_84[i];
            DKPRI.bWeaponUpgrade_85[i] = bWeaponUpgrade_85[i];
            DKPRI.bWeaponUpgrade_86[i] = bWeaponUpgrade_86[i];
            DKPRI.bWeaponUpgrade_87[i] = bWeaponUpgrade_87[i];
            DKPRI.bWeaponUpgrade_88[i] = bWeaponUpgrade_88[i];
            DKPRI.bWeaponUpgrade_89[i] = bWeaponUpgrade_89[i];
            DKPRI.bWeaponUpgrade_90[i] = bWeaponUpgrade_90[i];
            DKPRI.bWeaponUpgrade_91[i] = bWeaponUpgrade_91[i];
            DKPRI.bWeaponUpgrade_92[i] = bWeaponUpgrade_92[i];
            DKPRI.bWeaponUpgrade_93[i] = bWeaponUpgrade_93[i];
            DKPRI.bWeaponUpgrade_94[i] = bWeaponUpgrade_94[i];
            DKPRI.bWeaponUpgrade_95[i] = bWeaponUpgrade_95[i];
            DKPRI.bWeaponUpgrade_96[i] = bWeaponUpgrade_96[i];
            DKPRI.bWeaponUpgrade_97[i] = bWeaponUpgrade_97[i];
            DKPRI.bWeaponUpgrade_98[i] = bWeaponUpgrade_98[i];
            DKPRI.bWeaponUpgrade_99[i] = bWeaponUpgrade_99[i];
            DKPRI.bWeaponUpgrade_100[i] = bWeaponUpgrade_100[i];
            DKPRI.bWeaponUpgrade_101[i] = bWeaponUpgrade_101[i];
            DKPRI.bWeaponUpgrade_102[i] = bWeaponUpgrade_102[i];
            DKPRI.bWeaponUpgrade_103[i] = bWeaponUpgrade_103[i];
            DKPRI.bWeaponUpgrade_104[i] = bWeaponUpgrade_104[i];
            DKPRI.bWeaponUpgrade_105[i] = bWeaponUpgrade_105[i];
            DKPRI.bWeaponUpgrade_106[i] = bWeaponUpgrade_106[i];
            DKPRI.bWeaponUpgrade_107[i] = bWeaponUpgrade_107[i];
            DKPRI.bWeaponUpgrade_108[i] = bWeaponUpgrade_108[i];
            DKPRI.bWeaponUpgrade_109[i] = bWeaponUpgrade_109[i];
            DKPRI.bWeaponUpgrade_110[i] = bWeaponUpgrade_110[i];
            DKPRI.bWeaponUpgrade_111[i] = bWeaponUpgrade_111[i];
            DKPRI.bWeaponUpgrade_112[i] = bWeaponUpgrade_112[i];
            DKPRI.bWeaponUpgrade_113[i] = bWeaponUpgrade_113[i];
            DKPRI.bWeaponUpgrade_114[i] = bWeaponUpgrade_114[i];
            DKPRI.bWeaponUpgrade_115[i] = bWeaponUpgrade_115[i];
            DKPRI.bWeaponUpgrade_116[i] = bWeaponUpgrade_116[i];
            DKPRI.bWeaponUpgrade_117[i] = bWeaponUpgrade_117[i];
            DKPRI.bWeaponUpgrade_118[i] = bWeaponUpgrade_118[i];
            DKPRI.bWeaponUpgrade_119[i] = bWeaponUpgrade_119[i];
            DKPRI.bWeaponUpgrade_120[i] = bWeaponUpgrade_120[i];
            DKPRI.bWeaponUpgrade_121[i] = bWeaponUpgrade_121[i];
            DKPRI.bWeaponUpgrade_122[i] = bWeaponUpgrade_122[i];
            DKPRI.bWeaponUpgrade_123[i] = bWeaponUpgrade_123[i];
            DKPRI.bWeaponUpgrade_124[i] = bWeaponUpgrade_124[i];
            DKPRI.bWeaponUpgrade_125[i] = bWeaponUpgrade_125[i];
            DKPRI.bWeaponUpgrade_126[i] = bWeaponUpgrade_126[i];
            DKPRI.bWeaponUpgrade_127[i] = bWeaponUpgrade_127[i];
            DKPRI.bWeaponUpgrade_128[i] = bWeaponUpgrade_128[i];
            DKPRI.bWeaponUpgrade_129[i] = bWeaponUpgrade_129[i];
            DKPRI.bWeaponUpgrade_130[i] = bWeaponUpgrade_130[i];
            DKPRI.bWeaponUpgrade_131[i] = bWeaponUpgrade_131[i];
            DKPRI.bWeaponUpgrade_132[i] = bWeaponUpgrade_132[i];
            DKPRI.bWeaponUpgrade_133[i] = bWeaponUpgrade_133[i];
            DKPRI.bWeaponUpgrade_134[i] = bWeaponUpgrade_134[i];
            DKPRI.bWeaponUpgrade_135[i] = bWeaponUpgrade_135[i];
            DKPRI.bWeaponUpgrade_136[i] = bWeaponUpgrade_136[i];
            DKPRI.bWeaponUpgrade_137[i] = bWeaponUpgrade_137[i];
            DKPRI.bWeaponUpgrade_138[i] = bWeaponUpgrade_138[i];
            DKPRI.bWeaponUpgrade_139[i] = bWeaponUpgrade_139[i];
            DKPRI.bWeaponUpgrade_140[i] = bWeaponUpgrade_140[i];
            DKPRI.bWeaponUpgrade_141[i] = bWeaponUpgrade_141[i];
            DKPRI.bWeaponUpgrade_142[i] = bWeaponUpgrade_142[i];
            DKPRI.bWeaponUpgrade_143[i] = bWeaponUpgrade_143[i];
            DKPRI.bWeaponUpgrade_144[i] = bWeaponUpgrade_144[i];
            DKPRI.bWeaponUpgrade_145[i] = bWeaponUpgrade_145[i];
            DKPRI.bWeaponUpgrade_146[i] = bWeaponUpgrade_146[i];
            DKPRI.bWeaponUpgrade_147[i] = bWeaponUpgrade_147[i];
            DKPRI.bWeaponUpgrade_148[i] = bWeaponUpgrade_148[i];
            DKPRI.bWeaponUpgrade_149[i] = bWeaponUpgrade_149[i];
            DKPRI.bWeaponUpgrade_150[i] = bWeaponUpgrade_150[i];
            DKPRI.bWeaponUpgrade_151[i] = bWeaponUpgrade_151[i];
            DKPRI.bWeaponUpgrade_152[i] = bWeaponUpgrade_152[i];
            DKPRI.bWeaponUpgrade_153[i] = bWeaponUpgrade_153[i];
            DKPRI.bWeaponUpgrade_154[i] = bWeaponUpgrade_154[i];
            DKPRI.bWeaponUpgrade_155[i] = bWeaponUpgrade_155[i];
            DKPRI.bWeaponUpgrade_156[i] = bWeaponUpgrade_156[i];
            DKPRI.bWeaponUpgrade_157[i] = bWeaponUpgrade_157[i];
            DKPRI.bWeaponUpgrade_158[i] = bWeaponUpgrade_158[i];
            DKPRI.bWeaponUpgrade_159[i] = bWeaponUpgrade_159[i];
            DKPRI.bWeaponUpgrade_160[i] = bWeaponUpgrade_160[i];
            DKPRI.bWeaponUpgrade_161[i] = bWeaponUpgrade_161[i];
            DKPRI.bWeaponUpgrade_162[i] = bWeaponUpgrade_162[i];
            DKPRI.bWeaponUpgrade_163[i] = bWeaponUpgrade_163[i];
            DKPRI.bWeaponUpgrade_164[i] = bWeaponUpgrade_164[i];
            DKPRI.bWeaponUpgrade_165[i] = bWeaponUpgrade_165[i];
            DKPRI.bWeaponUpgrade_166[i] = bWeaponUpgrade_166[i];
            DKPRI.bWeaponUpgrade_167[i] = bWeaponUpgrade_167[i];
            DKPRI.bWeaponUpgrade_168[i] = bWeaponUpgrade_168[i];
            DKPRI.bWeaponUpgrade_169[i] = bWeaponUpgrade_169[i];
            DKPRI.bWeaponUpgrade_170[i] = bWeaponUpgrade_170[i];
            DKPRI.bWeaponUpgrade_171[i] = bWeaponUpgrade_171[i];
            DKPRI.bWeaponUpgrade_172[i] = bWeaponUpgrade_172[i];
            DKPRI.bWeaponUpgrade_173[i] = bWeaponUpgrade_173[i];
            DKPRI.bWeaponUpgrade_174[i] = bWeaponUpgrade_174[i];
            DKPRI.bWeaponUpgrade_175[i] = bWeaponUpgrade_175[i];
            DKPRI.bWeaponUpgrade_176[i] = bWeaponUpgrade_176[i];
            DKPRI.bWeaponUpgrade_177[i] = bWeaponUpgrade_177[i];
            DKPRI.bWeaponUpgrade_178[i] = bWeaponUpgrade_178[i];
            DKPRI.bWeaponUpgrade_179[i] = bWeaponUpgrade_179[i];
            DKPRI.bWeaponUpgrade_180[i] = bWeaponUpgrade_180[i];
            DKPRI.bWeaponUpgrade_181[i] = bWeaponUpgrade_181[i];
            DKPRI.bWeaponUpgrade_182[i] = bWeaponUpgrade_182[i];
            DKPRI.bWeaponUpgrade_183[i] = bWeaponUpgrade_183[i];
            DKPRI.bWeaponUpgrade_184[i] = bWeaponUpgrade_184[i];
            DKPRI.bWeaponUpgrade_185[i] = bWeaponUpgrade_185[i];
            DKPRI.bWeaponUpgrade_186[i] = bWeaponUpgrade_186[i];
            DKPRI.bWeaponUpgrade_187[i] = bWeaponUpgrade_187[i];
            DKPRI.bWeaponUpgrade_188[i] = bWeaponUpgrade_188[i];
            DKPRI.bWeaponUpgrade_189[i] = bWeaponUpgrade_189[i];
            DKPRI.bWeaponUpgrade_190[i] = bWeaponUpgrade_190[i];
            DKPRI.bWeaponUpgrade_191[i] = bWeaponUpgrade_191[i];
            DKPRI.bWeaponUpgrade_192[i] = bWeaponUpgrade_192[i];
            DKPRI.bWeaponUpgrade_193[i] = bWeaponUpgrade_193[i];
            DKPRI.bWeaponUpgrade_194[i] = bWeaponUpgrade_194[i];
            DKPRI.bWeaponUpgrade_195[i] = bWeaponUpgrade_195[i];
            DKPRI.bWeaponUpgrade_196[i] = bWeaponUpgrade_196[i];
            DKPRI.bWeaponUpgrade_197[i] = bWeaponUpgrade_197[i];
            DKPRI.bWeaponUpgrade_198[i] = bWeaponUpgrade_198[i];
            DKPRI.bWeaponUpgrade_199[i] = bWeaponUpgrade_199[i];
            DKPRI.bWeaponUpgrade_200[i] = bWeaponUpgrade_200[i];
        }

        // Rank state
        DKPRI.PlayerRank = PlayerRank;
    }
}

// ===================================================================
// EXTENDED PERK — CreateUPGMenu / CloseUPGMenu Overrides
//
// Parent instantiates `class'ZedternalReborn.WMUI_Menu'` which binds
// the InventoryMenu Flash widget to WMUI_UPGMenu. WMUI_UPGMenu has 6
// direct bPerkUpgrade[i] accesses that OOB for i >= 256 -- making
// perks at 256+ invisible / unbuyable through the upgrade menu.
//
// We swap the spawn site to `class'ZedternalRBPerkpackage.DKUI_Menu'`,
// which inherits everything from WMUI_Menu but rebinds InventoryMenu
// to DKUI_UPGMenu (a fork that uses GetPerkLevel/IsPerkUnlocked/
// SetPerkLevel for paged correctness).
//
// Parent's UPGMenuManager is `var private` so we cannot write it from
// here; we store our manager in DKUPGMenuManager (declared above).
// Parent's CloseUPGMenu still runs (via super) to clean up its own
// timers / sync state -- safe because parent's UPGMenuManager stays
// None and its `if (UPGMenuManager != None)` block is a no-op.
// ===================================================================

// (DK CreateUPGMenu / CloseUPGMenu live near defaultproperties below -
//  consolidated there onto the single DKUI_Menu-typed UPGMenuManagerDK.)

// ===================================================================
// REFORGED UNLOCK BITMASK ACCESSORS (per-player)
// Read on the owning client (trader filter / HUD); written server-side by
// the Artificer helper on kill-threshold. 155 bits across 5 ints.
// ===================================================================

simulated function bool IsReforgedBitSet(int BitIndex)
{
    local int FlagBit, Flags;

    if (BitIndex < 0 || BitIndex >= 155)
        return False;

    FlagBit = BitIndex % 31;

    switch (BitIndex / 31)
    {
        case 0: Flags = ReforgeFlags_0; break;
        case 1: Flags = ReforgeFlags_1; break;
        case 2: Flags = ReforgeFlags_2; break;
        case 3: Flags = ReforgeFlags_3; break;
        case 4: Flags = ReforgeFlags_4; break;
        default: return False;
    }

    return (Flags & (1 << FlagBit)) != 0;
}

// Server-only write. Returns True if newly set (was previously clear).
function bool UnlockReforgedWeapon(int BitIndex)
{
    local int FlagBit;

    if (BitIndex < 0 || BitIndex >= 155)
        return False;

    if (IsReforgedBitSet(BitIndex))
        return False;

    FlagBit = BitIndex % 31;

    switch (BitIndex / 31)
    {
        case 0: ReforgeFlags_0 = ReforgeFlags_0 | (1 << FlagBit); break;
        case 1: ReforgeFlags_1 = ReforgeFlags_1 | (1 << FlagBit); break;
        case 2: ReforgeFlags_2 = ReforgeFlags_2 | (1 << FlagBit); break;
        case 3: ReforgeFlags_3 = ReforgeFlags_3 | (1 << FlagBit); break;
        case 4: ReforgeFlags_4 = ReforgeFlags_4 | (1 << FlagBit); break;
        default: return False;
    }

    bNetDirty = True;
    bForceNetUpdate = True;
    `log("ZR Artificer: Unlocked Reforged weapon bit" @ BitIndex @ "for" @ PlayerName);
    return True;
}

// ===================================================================
// DEFAULT PROPERTIES
// ===================================================================

// ===================================================================
// TRADER UPGRADE MENU FORK (DK)
// Redirect ZR's menu creation to the DK fork (DKUI_Menu -> DKUI_UPGMenu)
// so paged perks (index >= 256) are visible/buyable in the upgrade menu.
// Mirrors WMPlayerReplicationInfo.CreateUPGMenu / CloseUPGMenu, but
// instantiates DKUI_Menu and tracks it in our own UPGMenuManagerDK (the
// parent's UPGMenuManager / SyncMenuObject are private). Sync cleanup is
// delegated to Super.CloseUPGMenu().
// ===================================================================
simulated function CreateUPGMenu()
{
    local WMPlayerController WMPC;

    WMPC = WMPlayerController(Owner);
    if (WMPC == None || WMPC.bUpgradeMenuOpen)
        return;

    WMPC.bUpgradeMenuOpen = True;

    UPGMenuManagerDK = new class'ZedternalRBPerkpackage.DKUI_Menu';
    UPGMenuManagerDK.Owner = WMPawn_Human(WMPC.Pawn);
    UPGMenuManagerDK.WMPC = WMPC;
    UPGMenuManagerDK.WMPRI = WMPlayerReplicationInfo(WMPC.PlayerReplicationInfo);
    UPGMenuManagerDK.SetTimingMode(TM_Real);
    UPGMenuManagerDK.Init(LocalPlayer(WMPC.Player));
}

simulated function CloseUPGMenu()
{
    // Super clears the private sync state and closes the parent's (unused,
    // None) UPGMenuManager; then we close our own DK menu instance.
    Super.CloseUPGMenu();

    if (UPGMenuManagerDK != None)
    {
        UPGMenuManagerDK.CloseMenu();
        UPGMenuManagerDK = None;
    }
}

defaultproperties
{
    RoguelikeTreeIndex=0
    RoguelikeCharacterIndex=0
    bHasRoguelikeCharacterUnique=false
    RoguelikeTotalUpgrades=0
    
    CachedRoguelikeHealthBonus=0
    CachedRoguelikeArmorBonus=0
    CachedRoguelikeSpeedMult=0.0
    CachedRoguelikeReloadMult=0.0
    CachedRoguelikeAmmoMult=0.0
    CachedRoguelikeDamageMult=0.0
    CachedRoguelikeDamageResist=0.0
    CachedRoguelikeLargeZedDamage=0.0
    CachedRoguelikeLuck=0.0
    
    CachedRoguelikeHealthPenaltyPct=0.0
    CachedRoguelikeSpeedPenaltyPct=0.0
    CachedRoguelikeOpportunistDamage=0.0
    CachedRoguelikeDuelistDamage=0.0
    CachedRoguelikeLastRoundDamage=0.0
    CachedRoguelikeWaveStartDosh=0
    
    AppliedHealthBonus=0
    AppliedArmorBonus=0
    AppliedAmmoMult=0.0
    AppliedHealthPenalty=0
    
    PlayerRank=0
    
    ReforgeFlags_0=0
    ReforgeFlags_1=0
    ReforgeFlags_2=0
    ReforgeFlags_3=0
    ReforgeFlags_4=0
    
    Name="Default__DKPlayerReplicationInfo"
}
