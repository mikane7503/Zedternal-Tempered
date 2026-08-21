// ===================================================================
// ZTUpgrade_Perk_Agony_Helper - ZED Time Tracking and Dosh Rewards
// Handles: ZED time state tracking, cumulative time counter, headshot extensions
// ===================================================================
class ZTUpgrade_Perk_Agony_Helper extends Info transient;

var KFPawn_Human Player;
var int UpgradeLevel;

// ZED time tracking
var bool bWasZedTimeActive;
var bool bZedTimeActive;

// ZED time duration tracking (Level 20+)
var float TotalZedTimeSeconds;  // Cumulative ZED time spent (persists across waves)
var int DoshRewardsEarned;      // Number of 500-dosh rewards earned

// Headshot extension tracking
var float LastHeadshotExtensionTime;

// ===================================================================
// Initialization
// ===================================================================
function PostBeginPlay()
{
	Super.PostBeginPlay();
	
	Player = KFPawn_Human(Owner);
	if (Player == None || Player.Health <= 0)
	{
		`log("Agony Helper: Invalid owner, destroying");
		Destroy();
		return;
	}
	
	`log("Agony Helper: Initialized for" @ Player.PlayerReplicationInfo.PlayerName);
}

function Initialize(KFPawn_Human NewPlayer, int NewUpgradeLevel)
{
	Player = NewPlayer;
	UpgradeLevel = NewUpgradeLevel;
	
	bWasZedTimeActive = false;
	bZedTimeActive = false;
	TotalZedTimeSeconds = 0.0f;
	DoshRewardsEarned = 0;
	LastHeadshotExtensionTime = 0.0f;
	
	`log("Agony Helper: Initialized with upgrade level" @ UpgradeLevel);
}

function SetUpgradeLevel(int NewLevel)
{
	UpgradeLevel = NewLevel;
	`log("Agony Helper: Upgrade level set to" @ UpgradeLevel);
}

// ===================================================================
// Main Tick - ZED Time State Tracking
// ===================================================================
function Tick(float DeltaTime)
{
	Super.Tick(DeltaTime);
	
	if (Player == None || Player.Health <= 0)
	{
		Cleanup();
		Destroy();
		return;
	}
	
	// Check ZED time state
	bZedTimeActive = (Player.WorldInfo.TimeDilation < 1.0);
	
	// Detect ZED time transitions
	if (bZedTimeActive && !bWasZedTimeActive)
		OnZedTimeStarted();
	else if (!bZedTimeActive && bWasZedTimeActive)
		OnZedTimeEnded();
	
	// Level 20+: Track ZED time duration
	if (UpgradeLevel >= class'ZTConfig_Capstone'.default.Capstone_Rank2Level && bZedTimeActive)
		TrackZedTimeDuration(DeltaTime);
	
	bWasZedTimeActive = bZedTimeActive;
}

// ===================================================================
// ZED Time Event Handlers
// ===================================================================
function OnZedTimeStarted()
{
	`log("Agony: ZED time started");
	
	// DK FIX: GroundSpeed is only recomputed via ApplySkillsToPawn /
	// UpdateGroundSpeed (spawn, purchases, weapon events). Nothing recomputes
	// it on ZED time transitions, so the TimeDilation-gated bonus in
	// ZTUpgrade_Perk_Agony.ModifySpeed never applied (or stuck after ZED time
	// if something recomputed mid-event). Force a recompute on both
	// transitions; this helper runs server-side, so the result is
	// authoritative and replicates.
	if (Player != None)
		Player.UpdateGroundSpeed();
	
	// Update HUD - show tracker for Level 20+
	if (UpgradeLevel >= class'ZTConfig_Capstone'.default.Capstone_Rank2Level)
	{
		UpdateHUD(true, TotalZedTimeSeconds, DoshRewardsEarned);
	}
}

function OnZedTimeEnded()
{
	`log("Agony: ZED time ended");
	
	// DK FIX: see OnZedTimeStarted - drop the ZED-time speed bonus again.
	if (Player != None)
		Player.UpdateGroundSpeed();
	
	// Update HUD - hide tracker but keep stats
	if (UpgradeLevel >= class'ZTConfig_Capstone'.default.Capstone_Rank2Level)
	{
		UpdateHUD(false, TotalZedTimeSeconds, DoshRewardsEarned);
	}
}

// ===================================================================
// Level 20+: ZED Time Duration Tracking & Dosh Rewards
// ===================================================================
function TrackZedTimeDuration(float DeltaTime)
{
	local int PreviousMilestone, CurrentMilestone;
	
	if (Player == None || Player.Role != ROLE_Authority)
		return;
	
	// Calculate milestone before adding time
	PreviousMilestone = int(TotalZedTimeSeconds / 120.0f);
	
	// Add ZED time (account for time dilation)
	TotalZedTimeSeconds += DeltaTime / Player.WorldInfo.TimeDilation;
	
	// Calculate milestone after adding time
	CurrentMilestone = int(TotalZedTimeSeconds / 120.0f);
	
	// Check if we crossed a 120-second threshold
	if (CurrentMilestone > PreviousMilestone)
	{
		AwardDoshReward();
	}
	
	// Update HUD every frame while in ZED time
	UpdateHUD(true, TotalZedTimeSeconds, DoshRewardsEarned);
}

function AwardDoshReward()
{
	local WMPlayerReplicationInfo WMPRI;
	local KFPlayerController KFPC;
	
	if (Player == None || Player.Role != ROLE_Authority)
		return;
	
	KFPC = KFPlayerController(Player.Controller);
	if (KFPC == None)
		return;
	
	WMPRI = WMPlayerReplicationInfo(KFPC.PlayerReplicationInfo);
	if (WMPRI == None)
		return;
	
	// Award 500 dosh
	WMPRI.Score += 500;
	DoshRewardsEarned++;
	
	`log("Agony: Awarded 500 dosh! Total rewards:" @ DoshRewardsEarned @ "Total time:" @ TotalZedTimeSeconds);
	
	// Notify player
	class'ZTMessageManager'.static.SendCritical(
		KFPC,
		"TIME BANKER REWARD: +500 DOSH! (" $ int(TotalZedTimeSeconds) $ "s total ZED time)"
	);
}

// ===================================================================
// Level 10+: Headshot Extension System
// ===================================================================
function TryHeadshotExtension(KFPawn OwnerPawn)
{
	local float CurrentTime;
	local float ExtensionChance;
	local float RandomValue;
	local KFGameInfo KFGI;
	
	if (OwnerPawn == None || OwnerPawn.Role != ROLE_Authority)
		return;
	
	// Only during ZED time
	if (!bZedTimeActive)
		return;
	
	CurrentTime = OwnerPawn.WorldInfo.TimeSeconds;
	
	// Cooldown check (0.1s deduplication)
	if (CurrentTime - LastHeadshotExtensionTime < class'ZTUpgrade_Perk_Agony'.default.HeadshotExtensionCooldown)
		return;
	
	// 30% chance to extend
	ExtensionChance = class'ZTUpgrade_Perk_Agony'.default.HeadshotExtensionChance;
	RandomValue = FRand();
	
	if (RandomValue <= ExtensionChance)
	{
		// Trigger extension through KFGameInfo
		KFGI = KFGameInfo(OwnerPawn.WorldInfo.Game);
		if (KFGI != None)
		{
			KFGI.DramaticEvent(1.0);
			LastHeadshotExtensionTime = CurrentTime;
			`log("Agony: Headshot extension triggered! (" $ RandomValue $ " <= " $ ExtensionChance $ ")");
		}
	}
}

// ===================================================================
// HUD Update - Reliable Client Function
// ===================================================================
reliable client function UpdateHUD(bool bZedTime, float TotalSeconds, int RewardsCount)
{
	local KFPlayerController KFPC;
	local ZTHudWrapper HudWrapper;
	
	KFPC = KFPlayerController(Player.Controller);
	if (KFPC == None)
		return;
	
	HudWrapper = ZTHudWrapper(KFPC.myHUD);
	if (HudWrapper != None)
	{
		HudWrapper.UpdateAgonyZedTimeTracker(bZedTime, TotalSeconds, RewardsCount, UpgradeLevel);
	}
}

// ===================================================================
// Cleanup
// ===================================================================
function Cleanup()
{
	`log("Agony Helper: Cleaned up - Total ZED time:" @ TotalZedTimeSeconds @ "seconds, Rewards earned:" @ DoshRewardsEarned);
}

// ===================================================================
// Default Properties
// ===================================================================
defaultproperties
{
	Name="Default__ZTUpgrade_Perk_Agony_Helper"
}