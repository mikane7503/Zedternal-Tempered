// ===================================================================
// ZTAchievementData - Achievement Definitions and Configuration
// Defines all achievements, requirements, and perk unlocks
// ===================================================================
class ZTAchievementData extends Object;

// Achievement types
enum EAchievementType
{
	ACH_KillCount,
	ACH_ScrakeKills,
	ACH_FleshpoundKills,
	ACH_HeadshotCount,
	ACH_WaveNoDamage,
	ACH_NoTraderWaves,
	ACH_SurvivalStreak,
	ACH_BossWaveComplete,
	ACH_BossWaveSpeed,
	ACH_DamageTaken,
	ACH_HealingGiven
};

// Achievement difficulty tiers
enum EAchievementTier
{
	TIER_Easy,
	TIER_Moderate,
	TIER_Hard,
	TIER_Extreme
};

// Achievement definition - Using Texture2D for compile-time validation
struct AchievementDefinition
{
	var name AchievementID;
	var string AchievementName;
	var string Description;
	var EAchievementType Type;
	var EAchievementTier Tier;
	var int RequiredCount;
	var bool bVisible;
	var string UnlockedPerkClass;
	var Texture2D AchievementIcon;
};

var array<AchievementDefinition> Achievements;

// Store icon references in defaultproperties for compile-time validation
var Texture2D Icon_ZedSlayer;
var Texture2D Icon_ZedMassacre;
var Texture2D Icon_HeadshotHero;
var Texture2D Icon_ScrakeHunter;
var Texture2D Icon_PennyPincher;
var Texture2D Icon_OnslaughtSurvivor;
var Texture2D Icon_Untouchable;
var Texture2D Icon_FleshpoundSlayer;
var Texture2D Icon_SpeedDemon;
var Texture2D Icon_AsceticMaster;
var Texture2D Icon_SurvivorLegend;

function InitializeAchievements()
{
	`log("ZTAchievementData: Initializing achievements...");
	
	// Clear existing
	Achievements.Length = 0;
	
	// TIER 1: Easy/Introductory
	AddAchievement('KillMilestone1500', "Zed Slayer", "Kill 1500 total zeds in a session", 
		ACH_KillCount, TIER_Easy, 1500, true, "", Icon_ZedSlayer);
	
	AddAchievement('KillMilestone5000', "Zed Massacre", "Kill 5000 total zeds in a session", 
		ACH_KillCount, TIER_Easy, 5000, true, "", Icon_ZedMassacre);
	
	// TIER 2: Moderate
	AddAchievement('HeadshotHero', "Headshot Hero", "Get 100 headshots in one wave", 
		ACH_HeadshotCount, TIER_Moderate, 100, true, "", Icon_HeadshotHero);
	
	AddAchievement('ScrakeHunter', "Scrake Hunter", "Kill 20 Scrakes in one wave", 
		ACH_ScrakeKills, TIER_Moderate, 20, true, "", Icon_ScrakeHunter);
	
	AddAchievement('NoTrader5Waves', "Penny Pincher", "Five waves in a row without spending Dosh", 
		ACH_NoTraderWaves, TIER_Moderate, 5, true, "", Icon_PennyPincher);
	
	AddAchievement('BossWaveComplete', "Onslaught Survivor", "Complete any boss onslaught special wave", 
		ACH_BossWaveComplete, TIER_Moderate, 1, false, "", Icon_OnslaughtSurvivor);
	
	// TIER 3: Hard
	AddAchievement('Untouchable', "Untouchable", "3 waves in a row without taking damage", 
		ACH_WaveNoDamage, TIER_Hard, 3, false, "", Icon_Untouchable);
	
	AddAchievement('FleshpoundSlayer', "Fleshpound Slayer", "Kill 15 Fleshpounds in one wave", 
		ACH_FleshpoundKills, TIER_Hard, 15, false, "", Icon_FleshpoundSlayer);
	
	AddAchievement('BossWaveSpeed', "Speed Demon", "Complete a boss wave in under 3 minutes", 
		ACH_BossWaveSpeed, TIER_Hard, 1, false, "", Icon_SpeedDemon);
	
	// TIER 4: Extreme/Mastery  
	AddAchievement('NoTrader10Waves', "Ascetic Master", "Complete 10 waves without buying from trader", 
		ACH_NoTraderWaves, TIER_Extreme, 10, true, "", Icon_AsceticMaster);
	
	AddAchievement('SurvivalStreak20', "Survivor Legend", "Survive 20 consecutive waves without dying", 
		ACH_SurvivalStreak, TIER_Extreme, 20, true, "", Icon_SurvivorLegend);
	
	`log("ZTAchievementData: Initialized" @ Achievements.Length @ "achievements");
	LogAllAchievements();
}

function AddAchievement(
	name ID, 
	string AchievementName, 
	string Desc, 
	EAchievementType Type, 
	EAchievementTier Tier, 
	int Required, 
	bool bVis, 
	string UnlockPerk,
	Texture2D Icon
)
{
	local AchievementDefinition NewAch;
	
	NewAch.AchievementID = ID;
	NewAch.AchievementName = AchievementName;
	NewAch.Description = Desc;
	NewAch.Type = Type;
	NewAch.Tier = Tier;
	NewAch.RequiredCount = Required;
	NewAch.bVisible = bVis;
	NewAch.UnlockedPerkClass = UnlockPerk;
	NewAch.AchievementIcon = Icon;
	
	Achievements.AddItem(NewAch);
}

function int FindAchievementIndex(name AchievementID)
{
	local int i;
	
	for (i = 0; i < Achievements.Length; i++)
	{
		if (Achievements[i].AchievementID == AchievementID)
			return i;
	}
	
	return INDEX_NONE;
}

// String-based lookup for config system
function int FindAchievementByName(string AchievementIDString)
{
	local int i;
	
	for (i = 0; i < Achievements.Length; i++)
	{
		if (string(Achievements[i].AchievementID) ~= AchievementIDString)
			return i;
	}
	
	return INDEX_NONE;
}

function LogAllAchievements()
{
	local int i;
	local AchievementDefinition Ach;
	
	`log("===== ZTAchievementData: Achievement List =====");
	for (i = 0; i < Achievements.Length; i++)
	{
		Ach = Achievements[i];
		`log("  [" $ GetTierName(Ach.Tier) $ "]" @ Ach.AchievementName);
		`log("    ID:" @ Ach.AchievementID);
		`log("    Type:" @ GetTypeName(Ach.Type));
		`log("    Required:" @ Ach.RequiredCount);
		`log("    Visible:" @ Ach.bVisible);
		if (Ach.UnlockedPerkClass != "")
			`log("    Unlocks:" @ Ach.UnlockedPerkClass);
		`log("    Icon:" @ (Ach.AchievementIcon != None ? "LOADED" : "MISSING"));
	}
	`log("=============================================");
}

function string GetTypeName(EAchievementType Type)
{
	switch(Type)
	{
		case ACH_KillCount: return "Kill Count";
		case ACH_ScrakeKills: return "Scrake Kills";
		case ACH_FleshpoundKills: return "Fleshpound Kills";
		case ACH_HeadshotCount: return "Headshot Count";
		case ACH_WaveNoDamage: return "Wave No Damage";
		case ACH_NoTraderWaves: return "No Trader Waves";
		case ACH_SurvivalStreak: return "Survival Streak";
		case ACH_BossWaveComplete: return "Boss Wave Complete";
		case ACH_BossWaveSpeed: return "Boss Wave Speed";
		case ACH_DamageTaken: return "Damage Taken";
		case ACH_HealingGiven: return "Healing Given";
	}
	return "Unknown";
}

function string GetTierName(EAchievementTier Tier)
{
	switch(Tier)
	{
		case TIER_Easy: return "EASY";
		case TIER_Moderate: return "MODERATE";
		case TIER_Hard: return "HARD";
		case TIER_Extreme: return "EXTREME";
	}
	return "UNKNOWN";
}

defaultproperties
{
	// Achievement icons - Compiler validates these exist!
	Icon_ZedSlayer=Texture2D'ZedternalRBPerkpackage_Resources.Achievements.UI_Achievement_ZedSlayer'
	Icon_ZedMassacre=Texture2D'ZedternalRBPerkpackage_Resources.Achievements.UI_Achievement_ZedMassacre'
	Icon_HeadshotHero=Texture2D'ZedternalRBPerkpackage_Resources.Achievements.UI_Achievement_HeadshotHero'
	Icon_ScrakeHunter=Texture2D'ZedternalRBPerkpackage_Resources.Achievements.UI_Achievement_ScrakeHunter'
	Icon_PennyPincher=Texture2D'ZedternalRBPerkpackage_Resources.Achievements.UI_Achievement_PennyPincher'
	Icon_OnslaughtSurvivor=Texture2D'ZedternalRBPerkpackage_Resources.Achievements.UI_Achievement_OnslaughtSurvivor'
	Icon_Untouchable=Texture2D'ZedternalRBPerkpackage_Resources.Achievements.UI_Achievement_Untouchable'
	Icon_FleshpoundSlayer=Texture2D'ZedternalRBPerkpackage_Resources.Achievements.UI_Achievement_FleshpoundSlayer'
	Icon_SpeedDemon=Texture2D'ZedternalRBPerkpackage_Resources.Achievements.UI_Achievement_SpeedDemon'
	Icon_AsceticMaster=Texture2D'ZedternalRBPerkpackage_Resources.Achievements.UI_Achievement_AsceticMaster'
	Icon_SurvivorLegend=Texture2D'ZedternalRBPerkpackage_Resources.Achievements.UI_Achievement_SurvivorLegend'
	
	Name="Default__ZTAchievementData"
}