// ===================================================================
// ZTMutator - Consolidated Gameplay Mutator
// Handles: Achievements, Special Wave Integration, Sound Management
// FIXED: Removed duplicate perk filtering (ZTGameInfo_Endless owns it)
// FIXED: Singleplayer player registration (NotifyLogin never fires)
// ===================================================================
class ZTMutator extends Mutator;

// Sound System
struct CustomSoundEntry
{
	var name SoundID;
	var string SoundCuePath;
	var bool bCustomSoundLoaded;
	var SoundCue LoadedSound;
};
var array<CustomSoundEntry> CustomSounds;

// Achievement System
var ZTAchievementData AchievementData;
var array<ZTAchievementReplicator> PlayerReplicators;

// Kill tracking for achievements  
struct PlayerKillStats
{
	var int PlayerID;
	var int TotalKills;
	var int ScrakeKills;
	var int FleshpoundKills;
	var int HeadshotKills;
	var int WaveKillCount;
	var int WaveScrakeKills;
	var int WaveFleshpoundKills;
	var int WaveHeadshotKills;
	var float WaveStartTime;
	var int ConsecutiveWavesWithoutTrader;
	var int ConsecutiveWavesAlive;
	var int ConsecutiveWavesNoDamage;
	var bool bTookDamageThisWave;
	var float TotalDamageTaken;
	var float TotalHealingGiven;
	var int DoshAtWaveStart;
	var bool bSpentDoshThisWave;
	var bool bWaveWasActive;
};
var array<PlayerKillStats> PlayerStats;
var array<KFPlayerController> PlayerControllers;

// Wave state tracking (for achievement wave transitions)
var bool bWasTraderOpen;

// Boss tracking for special waves
struct BossWaveTracker
{
	var int BossesSpawned;
	var int BossesKilled;
	var class<KFPawn_Monster> BossClass;
	var float WaveStartTime;
	var bool bIsActive;
};
var BossWaveTracker CurrentBossWave;

event PostBeginPlay()
{
	super.PostBeginPlay();
	
	// ===================================================================
	// INITIALIZE SOUND MANAGER - MUST BE FIRST!
	// ===================================================================
	`log("===== ZTMutator: Initializing Systems =====");
	class'ZTSoundManager'.static.Initialize(self);
	`log("ZTMutator: Sound manager initialized with" @ CustomSounds.Length @ "sounds");
	
	// Initialize Boss Wave Config
	class'ZTConfig_BossWave'.static.InitializeConfig();
	class'ZTConfig_BossWave'.static.CheckBasicConfigValues();
	`log("ZTMutator: Boss Wave config initialized");
	
	// Initialize Achievement System
	AchievementData = new class'ZTAchievementData';
	if (AchievementData == None)
	{
		`log("ZTMutator Error: Failed to create achievement data!");
		return;
	}
	AchievementData.InitializeAchievements();
	class'ZTConfig_PerkUnlockRules'.static.ApplyAchievementPerkLinks(AchievementData);
	
	`log("===== ZTMutator: System Initialized =====");
	`log("ZTMutator: Loaded" @ AchievementData.Achievements.Length @ "achievements");
	
	// Start monitoring timer
	SetTimer(0.5f, true, 'MonitorGameState');
	
	// Hook into game events
	SetTimer(2.0f, false, 'InitializeEventHooks');
	
	// ===================================================================
	// SINGLEPLAYER FIX: In NM_Standalone the local player already exists
	// before the mutator spawns, so NotifyLogin() never fires for them.
	// Use a delayed timer to catch and register any existing players.
	// ===================================================================
	if (WorldInfo.NetMode == NM_Standalone)
	{
		`log("ZTMutator: Standalone mode detected, scheduling existing player registration");
		SetTimer(1.0f, false, 'RegisterExistingPlayers');
	}
}

function InitializeEventHooks()
{
	local WMGameReplicationInfo WMGRI;
	
	WMGRI = WMGameReplicationInfo(WorldInfo.GRI);
	if (WMGRI == None)
	{
		SetTimer(1.0f, false, 'InitializeEventHooks');
		return;
	}
	
	`log("ZTMutator: Event hooks initialized");
}

// ===================================================================
// PLAYER MANAGEMENT
// ===================================================================

function NotifyLogin(Controller NewPlayer)
{
	local KFPlayerController KFPC;
	
	super.NotifyLogin(NewPlayer);
	
	KFPC = KFPlayerController(NewPlayer);
	if (KFPC != None)
	{
		`log("ZTMutator: Player connected, creating replicator and stats");
		CreateReplicatorForPlayer(KFPC);
		InitializePlayerStats(KFPC);
	}
}

// ===================================================================
// SINGLEPLAYER FIX: Register players that existed before the mutator.
// In NM_Standalone, the local player Controller is created before
// mutators spawn, so NotifyLogin() is never called for them.
// This catches them after a short delay to ensure everything is ready.
// ===================================================================

function RegisterExistingPlayers()
{
	local KFPlayerController KFPC;
	local int RegisteredCount;
	
	RegisteredCount = 0;
	
	foreach WorldInfo.AllControllers(class'KFPlayerController', KFPC)
	{
		if (FindPlayerStatIndex(KFPC) == INDEX_NONE)
		{
			CreateReplicatorForPlayer(KFPC);
			InitializePlayerStats(KFPC);
			RegisteredCount++;
			`log("ZTMutator: Registered existing player" @ KFPC.PlayerReplicationInfo.PlayerName @ "(singleplayer fix)");
		}
	}
	
	if (RegisteredCount > 0)
	{
		`log("ZTMutator: Registered" @ RegisteredCount @ "existing player(s) via singleplayer fix");
	}
	else
	{
		// Player might not have a controller yet; retry once more
		`log("ZTMutator: No unregistered players found, scheduling one more attempt");
		SetTimer(2.0f, false, 'RegisterExistingPlayersRetry');
	}
}

function RegisterExistingPlayersRetry()
{
	local KFPlayerController KFPC;
	
	foreach WorldInfo.AllControllers(class'KFPlayerController', KFPC)
	{
		if (FindPlayerStatIndex(KFPC) == INDEX_NONE)
		{
			CreateReplicatorForPlayer(KFPC);
			InitializePlayerStats(KFPC);
			`log("ZTMutator: Registered existing player on retry:" @ KFPC.PlayerReplicationInfo.PlayerName);
		}
	}
}

function CreateReplicatorForPlayer(KFPlayerController KFPC)
{
	local ZTAchievementReplicator Replicator;
	
	// Don't create duplicates
	if (FindReplicatorIndex(KFPC) != INDEX_NONE)
	{
		`log("ZTMutator: Replicator already exists for player, skipping");
		return;
	}
	
	Replicator = Spawn(class'ZTAchievementReplicator', KFPC);
	if (Replicator != None)
	{
		Replicator.OwningPC = KFPC;
		Replicator.Mutator = self;
		PlayerReplicators.AddItem(Replicator);
		`log("ZTMutator: Created achievement replicator for player");
	}
}

function InitializePlayerStats(KFPlayerController KFPC)
{
	local PlayerKillStats NewStats;
	local int PlayerID;
	local WMPlayerReplicationInfo WMPRI;
	
	// Don't create duplicates
	if (FindPlayerStatIndex(KFPC) != INDEX_NONE)
	{
		`log("ZTMutator: Stats already exist for player, skipping");
		return;
	}
	
	// Add controller to array and get ID
	PlayerControllers.AddItem(KFPC);
	PlayerID = PlayerControllers.Length - 1;
	
	// Initialize all fields explicitly
	NewStats.PlayerID = PlayerID;
	NewStats.TotalKills = 0;
	NewStats.ScrakeKills = 0;
	NewStats.FleshpoundKills = 0;
	NewStats.HeadshotKills = 0;
	NewStats.WaveKillCount = 0;
	NewStats.WaveScrakeKills = 0;
	NewStats.WaveFleshpoundKills = 0;
	NewStats.WaveHeadshotKills = 0;
	NewStats.WaveStartTime = 0.0;
	NewStats.ConsecutiveWavesWithoutTrader = 0;
	NewStats.ConsecutiveWavesAlive = 0;
	NewStats.ConsecutiveWavesNoDamage = 0;
	NewStats.bTookDamageThisWave = False;
	NewStats.TotalDamageTaken = 0.0;
	NewStats.TotalHealingGiven = 0.0;
	NewStats.bSpentDoshThisWave = False;
	NewStats.bWaveWasActive = False;
	
	// Initialize DoshAtWaveStart to current dosh (handles mid-game joins)
	WMPRI = WMPlayerReplicationInfo(KFPC.PlayerReplicationInfo);
	if (WMPRI != None)
	{
		NewStats.DoshAtWaveStart = WMPRI.Score;
		`log("ZTMutator: Initialized DoshAtWaveStart for new player:" @ WMPRI.Score);
	}
	else
	{
		NewStats.DoshAtWaveStart = 0;
	}
	
	PlayerStats.AddItem(NewStats);
}

// ===================================================================
// MAIN GAME STATE MONITORING
// Perk filtering is handled entirely by ZTGameInfo_Endless.
// This monitor only tracks wave state transitions for achievements
// and monitors boss waves / trader spending.
// ===================================================================

function MonitorGameState()
{
	local WMGameReplicationInfo WMGRI;
	
	WMGRI = WMGameReplicationInfo(WorldInfo.GRI);
	if (WMGRI == None) return;
	
	// Check wave state transitions (for achievement tracking)
	if (!WMGRI.bTraderIsOpen && bWasTraderOpen)
	{
		// Wave just started (trader closed)
		OnWaveStarted();
	}
	
	// Check trader state transitions
	if (WMGRI.bTraderIsOpen && !bWasTraderOpen)
	{
		// Trader just opened (wave ended)
		OnTraderOpened();
	}
	
	bWasTraderOpen = WMGRI.bTraderIsOpen;
	
	// Monitor boss wave if active
	if (CurrentBossWave.bIsActive)
	{
		MonitorBossWave();
	}
	
	// Monitor trader spending (for no-trader achievements)
	if (WMGRI.bTraderIsOpen)
	{
		CheckTraderSpending();
	}
}

function OnTraderOpened()
{
	local int i;
	local KFPlayerController KFPC;
	local WMPlayerReplicationInfo WMPRI;
	
	`log("ZTMutator: *** TRADER OPENED ***");
	
	// Record dosh baseline when trader OPENS (before spending)
	for (i = 0; i < PlayerStats.Length; i++)
	{
		KFPC = PlayerControllers[PlayerStats[i].PlayerID];
		if (KFPC == None) continue;
		
		WMPRI = WMPlayerReplicationInfo(KFPC.PlayerReplicationInfo);
		if (WMPRI != None)
		{
			PlayerStats[i].DoshAtWaveStart = WMPRI.Score;
			PlayerStats[i].bSpentDoshThisWave = False;
			`log("ZTMutator: Player" @ i @ "dosh baseline:" @ PlayerStats[i].DoshAtWaveStart);
		}
	}
	
	// Process wave end achievements
	OnWaveEnded();
}

function OnWaveStarted()
{
	local int i;
	local KFPlayerController KFPC;
	
	`log("ZTMutator: *** WAVE STARTED ***");
	
	// Evaluate no-trader streak now that the trader period is over.
	// bSpentDoshThisWave was tracked during the trader phase by CheckTraderSpending().
	for (i = 0; i < PlayerStats.Length; i++)
	{
		KFPC = PlayerControllers[PlayerStats[i].PlayerID];
		if (KFPC == None) continue;
		
		if (!PlayerStats[i].bSpentDoshThisWave)
		{
			PlayerStats[i].ConsecutiveWavesWithoutTrader++;
			`log("ZTMutator: Player" @ i @ "completed trader without spending dosh. Streak:" @ PlayerStats[i].ConsecutiveWavesWithoutTrader);
			if (PlayerStats[i].ConsecutiveWavesWithoutTrader >= 5)
			{
				CheckAchievement(KFPC, 'NoTrader5Waves');
			}
			if (PlayerStats[i].ConsecutiveWavesWithoutTrader >= 10)
			{
				CheckAchievement(KFPC, 'NoTrader10Waves');
			}
		}
		else
		{
			`log("ZTMutator: Player" @ i @ "spent dosh. Resetting no-trader streak (was" @ PlayerStats[i].ConsecutiveWavesWithoutTrader @ ")");
			PlayerStats[i].ConsecutiveWavesWithoutTrader = 0;
		}
		
		// Reset the flag for the upcoming wave/trader cycle
		PlayerStats[i].bSpentDoshThisWave = False;
	}
	
	// Mark waves as active
	for (i = 0; i < PlayerStats.Length; i++)
	{
		PlayerStats[i].bWaveWasActive = True;
	}
}

function OnWaveEnded()
{
	local int i;
	local KFPlayerController KFPC;
	
	`log("ZTMutator: *** WAVE ENDED ***");
	
	// Reset wave-specific stats and check achievements
	for (i = 0; i < PlayerStats.Length; i++)
	{
		KFPC = PlayerControllers[PlayerStats[i].PlayerID];
		if (KFPC == None) continue;
		
		// Only process achievements if wave actually ran
		if (!PlayerStats[i].bWaveWasActive)
		{
			`log("ZTMutator: Skipping achievement checks for player" @ i @ "- wave was not active");
			continue;
		}
		
		// Check wave-based achievements before resetting
		CheckAchievement(KFPC, 'HeadshotHero');
		CheckAchievement(KFPC, 'ScrakeHunter');
		CheckAchievement(KFPC, 'FleshpoundSlayer');
		
		// Handle consecutive no-damage waves
		if (!PlayerStats[i].bTookDamageThisWave)
		{
			PlayerStats[i].ConsecutiveWavesNoDamage++;
			`log("ZTMutator: Player" @ i @ "completed wave without damage. Streak:" @ PlayerStats[i].ConsecutiveWavesNoDamage);
			CheckAchievement(KFPC, 'Untouchable');
		}
		else
		{
			`log("ZTMutator: Player" @ i @ "took damage. Resetting no-damage streak (was" @ PlayerStats[i].ConsecutiveWavesNoDamage @ ")");
			PlayerStats[i].ConsecutiveWavesNoDamage = 0;
		}
		
		// NOTE: No-trader streak is evaluated in OnWaveStarted() so the full
		// trader period has elapsed before we check bSpentDoshThisWave
		
		// Handle survival streaks
		PlayerStats[i].ConsecutiveWavesAlive++;
		CheckAchievement(KFPC, 'SurvivalStreak20');
		
		// Reset wave counters
		PlayerStats[i].WaveKillCount = 0;
		PlayerStats[i].WaveScrakeKills = 0;
		PlayerStats[i].WaveFleshpoundKills = 0;
		PlayerStats[i].WaveHeadshotKills = 0;
		PlayerStats[i].bTookDamageThisWave = False;
		PlayerStats[i].bWaveWasActive = False;
	}
	
	// End boss wave tracking if active
	if (CurrentBossWave.bIsActive)
	{
		EndBossWave();
	}
}

function CheckTraderSpending()
{
	local int i;
	local KFPlayerController KFPC;
	local WMPlayerReplicationInfo WMPRI;
	local int CurrentDosh;
	
	for (i = 0; i < PlayerStats.Length; i++)
	{
		KFPC = PlayerControllers[PlayerStats[i].PlayerID];
		if (KFPC == None) continue;
		
		WMPRI = WMPlayerReplicationInfo(KFPC.PlayerReplicationInfo);
		if (WMPRI != None)
		{
			CurrentDosh = WMPRI.Score;
			
			// If dosh decreased, player spent money
			if (CurrentDosh < PlayerStats[i].DoshAtWaveStart && !PlayerStats[i].bSpentDoshThisWave)
			{
				PlayerStats[i].bSpentDoshThisWave = True;
				`log("ZTMutator: Player" @ i @ "spent dosh (was" @ PlayerStats[i].DoshAtWaveStart @ "now" @ CurrentDosh @ ")");
			}
		}
	}
}

// ===================================================================
// DAMAGE TRACKING HOOK
// ===================================================================

function NetDamage(int OriginalDamage, out int Damage, Pawn Injured, Controller InstigatedBy, vector HitLocation, out vector Momentum, class<DamageType> DamageType, Actor DamageCauser)
{
	local KFPlayerController KFPC;
	local int StatIdx;
	
	super.NetDamage(OriginalDamage, Damage, Injured, InstigatedBy, HitLocation, Momentum, DamageType, DamageCauser);
	
	KFPC = KFPlayerController(Injured.Controller);
	if (KFPC == None) return;
	
	StatIdx = FindPlayerStatIndex(KFPC);
	if (StatIdx == INDEX_NONE) return;
	
	if (Damage > 0)
	{
		PlayerStats[StatIdx].bTookDamageThisWave = True;
		PlayerStats[StatIdx].TotalDamageTaken += Damage;
	}
}

// ===================================================================
// HELPER FUNCTIONS
// ===================================================================

function int FindPlayerStatIndex(KFPlayerController KFPC)
{
	local int i;
	
	for (i = 0; i < PlayerStats.Length; i++)
	{
		if (PlayerControllers[PlayerStats[i].PlayerID] == KFPC)
			return i;
	}
	
	return INDEX_NONE;
}

function int FindReplicatorIndex(KFPlayerController KFPC)
{
	local int i;
	
	for (i = 0; i < PlayerReplicators.Length; i++)
	{
		if (PlayerReplicators[i].OwningPC == KFPC)
			return i;
	}
	
	return INDEX_NONE;
}

// These are still needed by ZTAchievementReplicator.UnlockPerkFromAchievement()
function int FindPerkIndex(WMGameReplicationInfo WMGRI, string ClassName)
{
	local int i;
	local string CurrentName;
	
	for (i = 0; i < WMGRI.PerkUpgradesList.Length; i++)
	{
		CurrentName = string(WMGRI.PerkUpgradesList[i].PerkUpgrade.Name);
		
		if (CurrentName ~= ClassName)
			return i;
		
		if (CurrentName ~= GetItemName(ClassName))
			return i;
		
		if (PathName(WMGRI.PerkUpgradesList[i].PerkUpgrade) ~= ClassName)
			return i;
	}
	
	return INDEX_NONE;
}

function int FindPerkIndexByName(WMGameReplicationInfo WMGRI, string PerkName)
{
	local int i;
	
	for (i = 0; i < WMGRI.PerkUpgradesList.Length; i++)
	{
		if (WMGRI.PerkUpgradesList[i].PerkUpgrade.default.UpgradeName ~= PerkName)
			return i;
	}
	
	return INDEX_NONE;
}

// ===================================================================
// ACHIEVEMENT SYSTEM - KILL TRACKING
// ===================================================================

function ScoreKill(Controller Killer, Controller Killed)
{
	local KFPlayerController KFPC;
	local KFPawn_Monster KilledMonster;
	local int StatIdx;
	local bool bWasHeadshot;
	
	super.ScoreKill(Killer, Killed);
	
	KFPC = KFPlayerController(Killer);
	if (KFPC == None) return;
	
	KilledMonster = KFPawn_Monster(Killed.Pawn);
	if (KilledMonster == None) return;
	
	StatIdx = FindPlayerStatIndex(KFPC);
	if (StatIdx == INDEX_NONE) return;
	
	PlayerStats[StatIdx].TotalKills++;
	PlayerStats[StatIdx].WaveKillCount++;
	
	bWasHeadshot = False;
	if (KilledMonster.HitZones.Length > 0)
	{
		if (KilledMonster.HitZones[0].GoreHealth <= 0)
		{
			bWasHeadshot = True;
		}
	}
	
	if (bWasHeadshot)
	{
		PlayerStats[StatIdx].HeadshotKills++;
		PlayerStats[StatIdx].WaveHeadshotKills++;
	}
	
	if (KilledMonster.IsA('KFPawn_ZedScrake'))
	{
		PlayerStats[StatIdx].ScrakeKills++;
		PlayerStats[StatIdx].WaveScrakeKills++;
	}
	else if (KilledMonster.IsA('KFPawn_ZedFleshpound'))
	{
		PlayerStats[StatIdx].FleshpoundKills++;
		PlayerStats[StatIdx].WaveFleshpoundKills++;
	}
	
	if (CurrentBossWave.bIsActive && KilledMonster.IsA(CurrentBossWave.BossClass.Name))
	{
		CurrentBossWave.BossesKilled++;
		`log("ZTMutator: Boss killed (" $ CurrentBossWave.BossesKilled $ "/" $ CurrentBossWave.BossesSpawned $ ")");
	}
	
	CheckAchievement(KFPC, 'KillMilestone1500');
	CheckAchievement(KFPC, 'KillMilestone5000');
}

function NotifyPlayerKilled(Controller Killer, Controller Killed, Pawn KilledPawn, class<DamageType> DamageType)
{
	local KFPlayerController KFPC;
	local int StatIdx;
	
	KFPC = KFPlayerController(Killed);
	if (KFPC == None) return;
	
	StatIdx = FindPlayerStatIndex(KFPC);
	if (StatIdx == INDEX_NONE) return;
	
	`log("ZTMutator: Player" @ StatIdx @ "died. Resetting survival streak (was" @ PlayerStats[StatIdx].ConsecutiveWavesAlive @ ")");
	PlayerStats[StatIdx].ConsecutiveWavesAlive = 0;
}

// ===================================================================
// ACHIEVEMENT CHECKING
// ===================================================================

function CheckAchievement(KFPlayerController KFPC, name AchievementID)
{
	local int AchievementIdx, StatIdx, ReplicatorIdx;
	local ZTAchievementData.AchievementDefinition Achievement;
	local bool bCompleted;
	local int CurrentProgress, RequiredProgress;
	
	if (AchievementData == None) return;
	
	AchievementIdx = AchievementData.FindAchievementIndex(AchievementID);
	if (AchievementIdx == INDEX_NONE) return;
	
	Achievement = AchievementData.Achievements[AchievementIdx];
	StatIdx = FindPlayerStatIndex(KFPC);
	if (StatIdx == INDEX_NONE) return;
	
	bCompleted = False;
	
	switch (Achievement.Type)
	{
		case ACH_KillCount:
			CurrentProgress = PlayerStats[StatIdx].TotalKills;
			RequiredProgress = Achievement.RequiredCount;
			bCompleted = (CurrentProgress >= RequiredProgress);
			break;
			
		case ACH_ScrakeKills:
			CurrentProgress = PlayerStats[StatIdx].WaveScrakeKills;
			RequiredProgress = Achievement.RequiredCount;
			bCompleted = (CurrentProgress >= RequiredProgress);
			break;
			
		case ACH_FleshpoundKills:
			CurrentProgress = PlayerStats[StatIdx].WaveFleshpoundKills;
			RequiredProgress = Achievement.RequiredCount;
			bCompleted = (CurrentProgress >= RequiredProgress);
			break;
			
		case ACH_HeadshotCount:
			CurrentProgress = PlayerStats[StatIdx].WaveHeadshotKills;
			RequiredProgress = Achievement.RequiredCount;
			bCompleted = (CurrentProgress >= RequiredProgress);
			break;
			
		case ACH_WaveNoDamage:
			CurrentProgress = PlayerStats[StatIdx].ConsecutiveWavesNoDamage;
			RequiredProgress = Achievement.RequiredCount;
			bCompleted = (CurrentProgress >= RequiredProgress);
			break;
			
		case ACH_NoTraderWaves:
			CurrentProgress = PlayerStats[StatIdx].ConsecutiveWavesWithoutTrader;
			RequiredProgress = Achievement.RequiredCount;
			bCompleted = (CurrentProgress >= RequiredProgress);
			break;
			
		case ACH_SurvivalStreak:
			CurrentProgress = PlayerStats[StatIdx].ConsecutiveWavesAlive;
			RequiredProgress = Achievement.RequiredCount;
			bCompleted = (CurrentProgress >= RequiredProgress);
			break;
	}
	
	ReplicatorIdx = FindReplicatorIndex(KFPC);
	if (ReplicatorIdx != INDEX_NONE)
	{
		PlayerReplicators[ReplicatorIdx].UpdateAchievementProgress(
			AchievementID,
			CurrentProgress,
			RequiredProgress,
			Achievement.bVisible
		);
		
		if (bCompleted)
		{
			PlayerReplicators[ReplicatorIdx].CompleteAchievement(
				AchievementID,
				Achievement.AchievementName,
				Achievement.UnlockedPerkClass,
				Achievement.AchievementIcon
			);
		}
	}
}

// ===================================================================
// BOSS WAVE TRACKING
// ===================================================================

function StartBossWave(class<KFPawn_Monster> BossClass, int BossCount)
{
	CurrentBossWave.BossClass = BossClass;
	CurrentBossWave.BossesSpawned = BossCount;
	CurrentBossWave.BossesKilled = 0;
	CurrentBossWave.WaveStartTime = WorldInfo.TimeSeconds;
	CurrentBossWave.bIsActive = True;
	
	`log("ZTMutator: Started boss wave -" @ BossClass @ "Count:" @ BossCount);
}

function MonitorBossWave()
{
	local float ElapsedTime;
	
	if (!CurrentBossWave.bIsActive) return;
	
	if (CurrentBossWave.BossesKilled >= CurrentBossWave.BossesSpawned)
	{
		ElapsedTime = WorldInfo.TimeSeconds - CurrentBossWave.WaveStartTime;
		`log("ZTMutator: Boss wave completed in" @ ElapsedTime @ "seconds");
		
		CheckBossWaveAchievements(ElapsedTime);
		EndBossWave();
	}
}

function CheckBossWaveAchievements(float CompletionTime)
{
	local KFPlayerController KFPC;
	
	foreach WorldInfo.AllControllers(class'KFPlayerController', KFPC)
	{
		CheckAchievement(KFPC, 'BossWaveComplete');
		`log("ZTMutator: Awarding BossWaveComplete achievement to player");
		
		if (CompletionTime < 180.0f)
		{
			CheckAchievement(KFPC, 'BossWaveSpeed');
			`log("ZTMutator: Awarding BossWaveSpeed achievement to player (completed in" @ CompletionTime @ "seconds)");
		}
	}
}

function EndBossWave()
{
	CurrentBossWave.bIsActive = False;
	CurrentBossWave.BossesSpawned = 0;
	CurrentBossWave.BossesKilled = 0;
	CurrentBossWave.BossClass = None;
}

// ===================================================================
// SOUND SYSTEM HELPER
// ===================================================================

// Get sound from manager (for use by other classes)
function SoundCue GetCustomSound(name SoundID)
{
	return class'ZTSoundManager'.static.GetSound(self, SoundID);
}

// ===================================================================
// MUTATE COMMAND HANDLER
// Supports: zupreset <number>, zupresets (list)
// ===================================================================

function Mutate(string MutateString, PlayerController Sender)
{
	local string Cmd, Arg;

	// Parse command and argument
	if (InStr(MutateString, " ") != INDEX_NONE)
	{
		Cmd = Left(MutateString, InStr(MutateString, " "));
		Arg = Mid(MutateString, InStr(MutateString, " ") + 1);
	}
	else
	{
		Cmd = MutateString;
		Arg = "";
	}

	if (Cmd ~= "zupreset")
	{
		HandlePresetCommand(Arg, Sender);
		return;
	}

	if (Cmd ~= "zupresets")
	{
		ListPresets(Sender);
		return;
	}

	// Pass to next mutator in chain
	super.Mutate(MutateString, Sender);
}

function HandlePresetCommand(string Arg, PlayerController Sender)
{
	local int PresetIndex;
	local string PresetName;

	if (Arg == "")
	{
		Sender.ClientMessage("Usage: mutate zupreset <number>");
		ListPresets(Sender);
		return;
	}

	PresetIndex = int(Arg);

	if (PresetIndex < 0 || PresetIndex >= class'ZTPresetData'.static.GetPresetCount())
	{
		Sender.ClientMessage("Invalid preset index:" @ Arg);
		ListPresets(Sender);
		return;
	}

	PresetName = class'ZTPresetData'.static.GetPresetName(PresetIndex);
	WorldInfo.Game.Broadcast(self, "Applying preset:" @ PresetName @ "- Map will restart...");
	`log("ZU Preset: Player" @ Sender.PlayerReplicationInfo.PlayerName @ "applied preset" @ PresetIndex @ "(" $ PresetName $ ")");

	class'ZTPresetData'.static.ApplyPreset(PresetIndex, WorldInfo);
}

function ListPresets(PlayerController Sender)
{
	local int i;

	Sender.ClientMessage("=== ZU Presets ===");
	for (i = 0; i < class'ZTPresetData'.static.GetPresetCount(); ++i)
	{
		Sender.ClientMessage("  " $ i $ " -" @ class'ZTPresetData'.static.GetPresetName(i));
	}
}

defaultproperties
{
	Name="Default__ZTMutator"
}
