// ===================================================================
// DKConfig_PerkUnlockRules - Perk Unlock Requirements Configuration
//
// Defines how perks are unlocked:
// - Prerequisite rules: need specific perks at specific levels
// - Achievement locks: perk hidden until a specific achievement is completed
// - Exclusion rules: buying one perk hides another (bidirectional)
//
// Admins can modify these in KFZedternalReborn_Upgrades.ini to
// change, add, or remove unlock requirements for any perk.
//
// Perk names use class names without package prefix.
// Examples: DKUpgrade_Perk_Riot, WMUpgrade_Perk_Berserker
//
// Available AchievementIDs:
//   KillMilestone1500, KillMilestone5000, HeadshotHero, ScrakeHunter,
//   NoTrader5Waves, BossWaveComplete, Untouchable, FleshpoundSlayer,
//   BossWaveSpeed, NoTrader10Waves, SurvivalStreak20
// ===================================================================
class DKConfig_PerkUnlockRules extends Object
	config(ZedternalUnlimited);

struct S_PerkUnlockRule
{
	var string PerkName;
	var string Req1Perk;
	var int Req1Level;
	var string Req2Perk;
	var int Req2Level;
};

struct S_AchievementPerkUnlock
{
	var string PerkName;
	var string AchievementID;
};

struct S_PerkExclusionRule
{
	var string PerkA;
	var string PerkB;
};

// Rank-gated perk unlock
// UnlockMode: 0=GlobalRank, 1=LocalRank, 2=Either (whichever is higher), 3=Disabled (always available)
struct S_RankPerkUnlock
{
	var string PerkName;
	var int RequiredRank;
	var byte UnlockMode;
};

var config array<S_PerkUnlockRule> PerkUnlockRules;
var config array<S_AchievementPerkUnlock> AchievementPerkUnlocks;
var config array<S_PerkExclusionRule> PerkExclusionRules;
var config array<S_RankPerkUnlock> RankPerkUnlocks;
var config int MODEVERSION;

static function InitializeConfig()
{
	if (default.MODEVERSION < 1)
	{
		// Symbiote hybrid perks: require Symbiote 10 + a base perk at 10
		AddDefaultUnlockRule("DKUpgrade_Perk_Riot", "DKUpgrade_Perk_Symbiote", 10, "WMUpgrade_Perk_Berserker", 10);
		AddDefaultUnlockRule("DKUpgrade_Perk_Agony", "DKUpgrade_Perk_Symbiote", 10, "DKUpgrade_Perk_TimeTraveler", 10);
		AddDefaultUnlockRule("DKUpgrade_Perk_Cinder", "DKUpgrade_Perk_Symbiote", 10, "WMUpgrade_Perk_Firebug", 10);
		AddDefaultUnlockRule("DKUpgrade_Perk_Hivemind", "DKUpgrade_Perk_Symbiote", 10, "WMUpgrade_Perk_Support", 10);

		// Haunted: Berserker 5 + Sharpshooter 5
		AddDefaultUnlockRule("DKUpgrade_Perk_Haunted", "WMUpgrade_Perk_Berserker", 5, "WMUpgrade_Perk_Sharpshooter", 5);

		// Achievement-locked perks: perk + which achievement unlocks it
		default.AchievementPerkUnlocks.Length = 0;
		AddDefaultAchievementUnlock("DKUpgrade_Perk_Headhunter", "HeadshotHero");
		AddDefaultAchievementUnlock("DKUpgrade_Perk_Tycoon", "NoTrader5Waves");

		// No exclusion rules by default
		default.PerkExclusionRules.Length = 0;

		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}

	if (default.MODEVERSION < 2)
	{
		// v2: Add rank-gated perks (UnlockMode: 0=Global, 1=Local, 2=Either, 3=Disabled)
		default.RankPerkUnlocks.Length = 0;
		AddDefaultRankUnlock("DKUpgrade_Perk_Metronome", 5, 0);
		AddDefaultRankUnlock("DKUpgrade_Perk_Hollow", 10, 0);

		default.MODEVERSION = 2;
		static.StaticSaveConfig();
	}
}

static function AddDefaultUnlockRule(string PerkName, string Req1, int Req1Lvl, string Req2, int Req2Lvl)
{
	local S_PerkUnlockRule Rule;

	Rule.PerkName = PerkName;
	Rule.Req1Perk = Req1;
	Rule.Req1Level = Req1Lvl;
	Rule.Req2Perk = Req2;
	Rule.Req2Level = Req2Lvl;

	default.PerkUnlockRules.AddItem(Rule);
}

static function AddDefaultAchievementUnlock(string PerkName, string AchievementID)
{
	local S_AchievementPerkUnlock Entry;

	Entry.PerkName = PerkName;
	Entry.AchievementID = AchievementID;

	default.AchievementPerkUnlocks.AddItem(Entry);
}

static function AddDefaultRankUnlock(string PerkName, int RequiredRank, byte UnlockMode)
{
	local S_RankPerkUnlock Entry;

	Entry.PerkName = PerkName;
	Entry.RequiredRank = RequiredRank;
	Entry.UnlockMode = UnlockMode;

	default.RankPerkUnlocks.AddItem(Entry);
}

// Get rank requirement for a perk. Returns 0 if no rank requirement.
static function int GetRankRequirement(string PerkName)
{
	local int i;

	for (i = 0; i < default.RankPerkUnlocks.Length; ++i)
	{
		if (default.RankPerkUnlocks[i].PerkName ~= PerkName)
			return default.RankPerkUnlocks[i].RequiredRank;
	}

	return 0;
}

// Get unlock mode for a rank-gated perk. Returns 3 (disabled) if not found.
static function byte GetRankUnlockMode(string PerkName)
{
	local int i;

	for (i = 0; i < default.RankPerkUnlocks.Length; ++i)
	{
		if (default.RankPerkUnlocks[i].PerkName ~= PerkName)
			return default.RankPerkUnlocks[i].UnlockMode;
	}

	return 3;
}

// Check if a player's rank meets the requirement for a perk.
// PlayerGlobalRank = from client's local file (DKPRI.PlayerRank)
// PlayerLocalRank = from server's local rank storage (0 if not using local rank)
static function bool MeetsRankRequirement(string PerkName, int PlayerGlobalRank, int PlayerLocalRank)
{
	local int i, ReqRank;
	local byte Mode;

	for (i = 0; i < default.RankPerkUnlocks.Length; ++i)
	{
		if (default.RankPerkUnlocks[i].PerkName ~= PerkName)
		{
			ReqRank = default.RankPerkUnlocks[i].RequiredRank;
			Mode = default.RankPerkUnlocks[i].UnlockMode;

			if (ReqRank <= 0 || Mode == 3)
				return True;

			switch (Mode)
			{
				case 0: // Global rank only
					return PlayerGlobalRank >= ReqRank;
				case 1: // Local rank only
					return PlayerLocalRank >= ReqRank;
				case 2: // Either (whichever is higher)
					return Max(PlayerGlobalRank, PlayerLocalRank) >= ReqRank;
				default:
					return True;
			}
		}
	}

	// No rank requirement found for this perk
	return True;
}

static function CheckBasicConfigValues()
{
	local int i;

	for (i = 0; i < default.PerkUnlockRules.Length; ++i)
	{
		if (default.PerkUnlockRules[i].PerkName == "")
		{
			`log("[DK_UNLOCK] WARNING: Empty PerkName in unlock rule at index" @ i $ ", removing");
			default.PerkUnlockRules.Remove(i, 1);
			--i;
			continue;
		}
		if (default.PerkUnlockRules[i].Req1Perk == "")
		{
			`log("[DK_UNLOCK] WARNING: Empty Req1Perk for" @ default.PerkUnlockRules[i].PerkName $ ", removing rule");
			default.PerkUnlockRules.Remove(i, 1);
			--i;
			continue;
		}
		if (default.PerkUnlockRules[i].Req1Level < 1)
		{
			`log("[DK_UNLOCK] WARNING: Req1Level < 1 for" @ default.PerkUnlockRules[i].PerkName $ ", clamping to 1");
			default.PerkUnlockRules[i].Req1Level = 1;
		}
		if (default.PerkUnlockRules[i].Req2Perk != "" && default.PerkUnlockRules[i].Req2Level < 1)
		{
			`log("[DK_UNLOCK] WARNING: Req2Level < 1 for" @ default.PerkUnlockRules[i].PerkName $ ", clamping to 1");
			default.PerkUnlockRules[i].Req2Level = 1;
		}
	}

	for (i = 0; i < default.AchievementPerkUnlocks.Length; ++i)
	{
		if (default.AchievementPerkUnlocks[i].PerkName == "")
		{
			`log("[DK_UNLOCK] WARNING: Empty PerkName in achievement unlock at index" @ i $ ", removing");
			default.AchievementPerkUnlocks.Remove(i, 1);
			--i;
			continue;
		}
		if (default.AchievementPerkUnlocks[i].AchievementID == "")
		{
			`log("[DK_UNLOCK] WARNING: Empty AchievementID for" @ default.AchievementPerkUnlocks[i].PerkName $ ", removing");
			default.AchievementPerkUnlocks.Remove(i, 1);
			--i;
			continue;
		}
	}

	// Validate rank perk unlocks
	for (i = 0; i < default.RankPerkUnlocks.Length; ++i)
	{
		if (default.RankPerkUnlocks[i].PerkName == "")
		{
			`log("[DK_UNLOCK] WARNING: Empty PerkName in rank unlock at index" @ i $ ", removing");
			default.RankPerkUnlocks.Remove(i, 1);
			--i;
			continue;
		}
		if (default.RankPerkUnlocks[i].RequiredRank < 0)
		{
			`log("[DK_UNLOCK] WARNING: Negative RequiredRank for" @ default.RankPerkUnlocks[i].PerkName $ ", clamping to 0");
			default.RankPerkUnlocks[i].RequiredRank = 0;
		}
		if (default.RankPerkUnlocks[i].UnlockMode > 3)
		{
			`log("[DK_UNLOCK] WARNING: Invalid UnlockMode for" @ default.RankPerkUnlocks[i].PerkName $ ", setting to 3 (disabled)");
			default.RankPerkUnlocks[i].UnlockMode = 3;
		}
	}

	`log("[DK_UNLOCK] Config:" @ default.PerkUnlockRules.Length @ "unlock rules,"
		@ default.AchievementPerkUnlocks.Length @ "achievement unlocks,"
		@ default.PerkExclusionRules.Length @ "exclusion rules,"
		@ default.RankPerkUnlocks.Length @ "rank unlocks");
}

// Apply all rules to a PerkFilterConfig instance
static function ApplyRules(PerkFilterConfig PerkConfig)
{
	local int i;

	if (PerkConfig == None) return;

	// Apply prerequisite unlock rules
	for (i = 0; i < default.PerkUnlockRules.Length; ++i)
	{
		PerkConfig.AddUnlockRule(
			default.PerkUnlockRules[i].PerkName,
			default.PerkUnlockRules[i].Req1Perk,
			default.PerkUnlockRules[i].Req1Level,
			default.PerkUnlockRules[i].Req2Perk,
			default.PerkUnlockRules[i].Req2Level
		);
	}

	// Apply achievement locks (just the perk names for the filter)
	for (i = 0; i < default.AchievementPerkUnlocks.Length; ++i)
	{
		PerkConfig.AddAchievementLockedPerk(default.AchievementPerkUnlocks[i].PerkName);
	}

	// Apply exclusion rules
	for (i = 0; i < default.PerkExclusionRules.Length; ++i)
	{
		PerkConfig.AddExclusionRule(
			default.PerkExclusionRules[i].PerkA,
			default.PerkExclusionRules[i].PerkB
		);
	}
}

// Called by DKAchievementData after initializing achievements
// to apply perk-achievement mappings from config
static function ApplyAchievementPerkLinks(DKAchievementData AchData)
{
	local int i, AchIdx;

	if (AchData == None) return;

	for (i = 0; i < default.AchievementPerkUnlocks.Length; ++i)
	{
		AchIdx = AchData.FindAchievementByName(default.AchievementPerkUnlocks[i].AchievementID);
		if (AchIdx != INDEX_NONE)
		{
			AchData.Achievements[AchIdx].UnlockedPerkClass = default.AchievementPerkUnlocks[i].PerkName;
			`log("[DK_UNLOCK] Linked achievement" @ default.AchievementPerkUnlocks[i].AchievementID
				@ "-> perk" @ default.AchievementPerkUnlocks[i].PerkName);
		}
		else
		{
			`log("[DK_UNLOCK] WARNING: Achievement ID" @ default.AchievementPerkUnlocks[i].AchievementID
				@ "not found! Cannot link to perk" @ default.AchievementPerkUnlocks[i].PerkName);
		}
	}
}

defaultproperties
{
	Name="Default__DKConfig_PerkUnlockRules"
}
