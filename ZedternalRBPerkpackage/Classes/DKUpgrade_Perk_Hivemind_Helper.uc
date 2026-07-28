// ===================================================================
// DKUpgrade_Perk_Hivemind_Helper - Team Buff Tracking
// Handles: Nearby teammate count, kill tracking, Swarm Collective
// ===================================================================
class DKUpgrade_Perk_Hivemind_Helper extends Info
	transient;

var KFPawn_Human Player;
var int UpgradeLevel;

// Neural Network tracking
var int ConnectedTeammatesCount;
var float LastProximityCheckTime;
var float ProximityCheckInterval;

// Swarm Collective tracking
var int SwarmKillProgress;
var bool bSwarmCollectiveActive;
var float SwarmCollectiveEndTime;
var bool bSwarmReadyNotificationSent;

// Wave tracking for auto-reset
var int LastWaveNum;

// Sound effects
var SoundCue SwarmActivateSound;

// Debug tracking
var int DebugUpdateCount;

// ===================================================================
// Initialization
// ===================================================================
function PostBeginPlay()
{
	Super.PostBeginPlay();
	
	Player = KFPawn_Human(Owner);
	if (Player == None || Player.Health <= 0)
	{
		`log("Hivemind Helper: Invalid owner, destroying");
		Destroy();
		return;
	}
	
	`log("Hivemind Helper: Initialized for" @ Player.PlayerReplicationInfo.PlayerName);
}

function Initialize(KFPawn_Human NewPlayer, int NewUpgradeLevel)
{
	local DKMutator Mutator;
	
	Player = NewPlayer;
	UpgradeLevel = NewUpgradeLevel;
	
	ConnectedTeammatesCount = 0;
	LastProximityCheckTime = 0.0f;
	ProximityCheckInterval = 0.2f; // Check 5 times per second
	
	SwarmKillProgress = 0;
	bSwarmCollectiveActive = false;
	SwarmCollectiveEndTime = 0.0f;
	bSwarmReadyNotificationSent = false;
	
	// Initialize wave tracking
	if (Player.WorldInfo.GRI != None)
	{
		LastWaveNum = KFGameReplicationInfo(Player.WorldInfo.GRI).WaveNum;
	}
	else
	{
		LastWaveNum = 0;
	}
	
	DebugUpdateCount = 0;
	
	// Load sound effects via DKMutator
	foreach Player.WorldInfo.AllActors(class'DKMutator', Mutator)
	{
		`log("Hivemind Helper: Found DKMutator, requesting sounds...");
		
		SwarmActivateSound = Mutator.GetCustomSound('Hivemind_Collective_Activate');
		
		if (SwarmActivateSound != None)
			`log("Hivemind Helper: âœ“ Loaded Swarm Activate SoundCue:" @ SwarmActivateSound);
		else
			`log("Hivemind Helper: âœ— Swarm Activate sound returned None!");
		
		break;
	}
	
	`log("Hivemind Helper: Initialized with upgrade level" @ UpgradeLevel);
}

function SetUpgradeLevel(int NewLevel)
{
	UpgradeLevel = NewLevel;
	`log("Hivemind Helper: Upgrade level set to" @ UpgradeLevel);
}

// ===================================================================
// Main Tick - Track Nearby Teammates and Swarm Collective
// ===================================================================
function Tick(float DeltaTime)
{
	local float CurrentTime;
	local int CurrentWaveNum;
	
	Super.Tick(DeltaTime);
	
	if (Player == None || Player.Health <= 0)
	{
		Cleanup();
		Destroy();
		return;
	}
	
	CurrentTime = Player.WorldInfo.TimeSeconds;
	
	// Check for wave change and reset Swarm Collective
	if (Player.WorldInfo.GRI != None)
	{
		CurrentWaveNum = KFGameReplicationInfo(Player.WorldInfo.GRI).WaveNum;
		if (CurrentWaveNum != LastWaveNum)
		{
			ResetSwarmCollective();
			LastWaveNum = CurrentWaveNum;
		}
	}
	
	// Scan for nearby teammates periodically
	if (CurrentTime - LastProximityCheckTime >= ProximityCheckInterval)
	{
		ScanNearbyTeammates();
		LastProximityCheckTime = CurrentTime;
	}
	
	// Check Swarm Collective timer
	if (bSwarmCollectiveActive && CurrentTime >= SwarmCollectiveEndTime)
	{
		EndSwarmCollective();
	}
	
	// Update HUD
	UpdateHUD();
}

// ===================================================================
// Nearby Teammate Tracking
// ===================================================================
function ScanNearbyTeammates()
{
	local KFPawn_Human Teammate;
	local int Count;
	local float Distance;
	
	if (Player == None)
		return;
	
	Count = 0;
	
	// Count all living teammates within radius
	foreach Player.WorldInfo.AllPawns(class'KFPawn_Human', Teammate)
	{
		if (Teammate != Player && Teammate.IsAliveAndWell())
		{
			Distance = VSize(Teammate.Location - Player.Location);
			if (Distance <= class'DKUpgrade_Perk_Hivemind'.default.NeuralNetworkRadius)
			{
				Count++;
			}
		}
	}
	
	ConnectedTeammatesCount = Count;
}

function int GetConnectedTeammateCount()
{
	return ConnectedTeammatesCount;
}

// ===================================================================
// Kill Tracking for Swarm Collective
// ===================================================================
function OnKill(KFPawn_Monster KilledMonster)
{
	if (Player == None || Player.Role != ROLE_Authority)
		return;
	
	// Don't track kills if Swarm is already active
	if (bSwarmCollectiveActive)
		return;
	
	// Increment kill progress (no Symbiote requirement - Swarm Collective is independent)
	SwarmKillProgress++;
	
	// Check if we've reached the requirement
	if (UpgradeLevel >= class'DKConfig_Capstone'.default.Capstone_Rank2Level && SwarmKillProgress >= class'DKUpgrade_Perk_Hivemind'.default.SwarmCollectiveKillsRequired)
	{
		
		// Trigger Swarm Collective on next kill
		TriggerSwarmCollective();
	}
	
	`log("Hivemind: Kill tracked -" @ SwarmKillProgress @ "/" @ class'DKUpgrade_Perk_Hivemind'.default.SwarmCollectiveKillsRequired);
}

// ===================================================================
// Swarm Collective - Team-Wide Buff System
// ===================================================================
function TriggerSwarmCollective()
{
	local KFPlayerController KFPC;
	local DKPlayerController DKPC;
	local KFPawn_Human Teammate;
	
	if (Player == None || Player.Role != ROLE_Authority)
		return;
	
	if (UpgradeLevel < class'DKConfig_Capstone'.default.Capstone_Rank2Level)
		return;
	
	if (bSwarmCollectiveActive)
		return;
	
	bSwarmCollectiveActive = true;
	SwarmCollectiveEndTime = Player.WorldInfo.TimeSeconds + class'DKUpgrade_Perk_Hivemind'.default.SwarmCollectiveDuration;
	SwarmKillProgress = 0; // Reset kill counter
	bSwarmReadyNotificationSent = false;
	
	// ===================================================================
	// PLAY SWARM COLLECTIVE SOUND TO ALL PLAYERS
	// ===================================================================
	`log("Hivemind: SWARM COLLECTIVE ACTIVATED! Playing team-wide sound...");
	
	foreach Player.WorldInfo.AllPawns(class'KFPawn_Human', Teammate)
	{
		if (Teammate.IsAliveAndWell())
		{
			DKPC = DKPlayerController(Teammate.Controller);
			if (DKPC != None && SwarmActivateSound != None)
			{
				DKPC.ClientPlaySound(SwarmActivateSound);
				`log("Hivemind: âœ“ Played Swarm sound for" @ Teammate.PlayerReplicationInfo.PlayerName);
			}
		}
	}
	
	// Send notification to all players
	foreach Player.WorldInfo.AllActors(class'KFPlayerController', KFPC)
	{
		if (KFPC != None)
		{
			class'DKMessageManager'.static.SendCritical(
				KFPC,
				"SWARM COLLECTIVE ACTIVATED! +30% damage, +50% reload, +15% speed for 8 seconds!"
			);
		}
	}
	
	`log("Hivemind: Swarm Collective TRIGGERED! All teammates buffed for 8 seconds");
}

function EndSwarmCollective()
{
	bSwarmCollectiveActive = false;
	
	class'DKMessageManager'.static.SendImportant(
		KFPlayerController(Player.Controller),
		"Swarm Collective ended - keep killing to recharge!"
	);
	
	`log("Hivemind: Swarm Collective ended");
}

// Called when wave starts - reset Swarm Collective
function ResetSwarmCollective()
{
	SwarmKillProgress = 0;
	bSwarmCollectiveActive = false;
	bSwarmReadyNotificationSent = false;
	
	`log("Hivemind: Swarm Collective reset for new wave");
}

// ===================================================================
// HUD Updates
// ===================================================================
function UpdateHUD()
{
	local DKUpgrade_Perk_Symbiote_Helper SymbioteHelper;
	local int SymbioteEvolutions;
	local float RemainingTime;
	
	// Get Symbiote evolution count for display
	SymbioteHelper = class'DKUpgrade_Perk_Symbiote'.static.GetHelper(Player);
	if (SymbioteHelper != None)
	{
		SymbioteEvolutions = SymbioteHelper.TotalEvolutions;
	}
	else
	{
		SymbioteEvolutions = 0;
	}
	
	// Calculate remaining Swarm Collective time
	if (bSwarmCollectiveActive && Player != None)
	{
		RemainingTime = SwarmCollectiveEndTime - Player.WorldInfo.TimeSeconds;
		RemainingTime = FMax(0.0f, RemainingTime);
	}
	else
	{
		RemainingTime = 0.0f;
	}
	
	ClientUpdateHUD(ConnectedTeammatesCount, SwarmKillProgress, SymbioteEvolutions, bSwarmCollectiveActive, RemainingTime, UpgradeLevel);
}

reliable client function ClientUpdateHUD(int TeammatesConnected, int SwarmProgress, int SymbioteEvolutionCount, bool bSwarmActive, float SwarmTimeRemaining, int CurrentUpgradeLevel)
{
	local DKPlayerController DKPC;
	local DKHudWrapper HivemindHUD;
	
	// Debug counter - log every 50 calls to avoid spam
	DebugUpdateCount++;
	if (DebugUpdateCount % 50 == 1)
	{
		`log("Hivemind Helper CLIENT: ClientUpdateHUD called (call #" $ DebugUpdateCount $ ")");
		`log("Hivemind Helper CLIENT: Connected=" $ TeammatesConnected @ "Progress=" $ SwarmProgress @ "Evolutions=" $ SymbioteEvolutionCount @ "Active=" $ bSwarmActive @ "TimeLeft=" $ SwarmTimeRemaining @ "Level=" $ CurrentUpgradeLevel);
	}
	
	// Get local player controller
	DKPC = DKPlayerController(GetALocalPlayerController());
	if (DKPC == None)
	{
		if (DebugUpdateCount % 50 == 1)
			`log("Hivemind Helper CLIENT: âœ— GetALocalPlayerController returned None or not DKPlayerController!");
		return;
	}
	
	if (DebugUpdateCount % 50 == 1)
		`log("Hivemind Helper CLIENT: âœ“ Got DKPlayerController:" @ DKPC);
	
	// Get HUD using GetReaperHUD static function
	HivemindHUD = class'DKHudWrapper'.static.GetReaperHUD(DKPC);
	if (HivemindHUD == None)
	{
		if (DebugUpdateCount % 50 == 1)
			`log("Hivemind Helper CLIENT: âœ— GetReaperHUD returned None!");
		return;
	}
	
	if (DebugUpdateCount % 50 == 1)
		`log("Hivemind Helper CLIENT: âœ“ Got HivemindHUD:" @ HivemindHUD);
	
	// Call UpdateHivemindTracking
	HivemindHUD.UpdateHivemindTracking(TeammatesConnected, SwarmProgress, SymbioteEvolutionCount, bSwarmActive, SwarmTimeRemaining, CurrentUpgradeLevel);
	
	if (DebugUpdateCount % 50 == 1)
		`log("Hivemind Helper CLIENT: âœ“ Called UpdateHivemindTracking successfully!");
}

// ===================================================================
// Cleanup
// ===================================================================
function Cleanup()
{
	`log("Hivemind Helper: Cleaned up - Final stats: Connected=" @ ConnectedTeammatesCount @ "SwarmProgress=" @ SwarmKillProgress);
}

// ===================================================================
// Default Properties
// ===================================================================
defaultproperties
{
	ConnectedTeammatesCount=0
	LastProximityCheckTime=0.0f
	ProximityCheckInterval=0.2f
	
	SwarmKillProgress=0
	bSwarmCollectiveActive=false
	SwarmCollectiveEndTime=0.0f
	bSwarmReadyNotificationSent=false
	
	LastWaveNum=0
	
	DebugUpdateCount=0
	
	Name="Default__DKUpgrade_Perk_Hivemind_Helper"
}