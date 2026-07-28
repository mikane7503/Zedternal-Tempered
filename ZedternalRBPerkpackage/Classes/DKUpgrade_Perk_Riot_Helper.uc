class DKUpgrade_Perk_Riot_Helper extends Info
	transient;

var KFPawn OwnerPawn;
var KFPlayerController KFPC;
var int UpgradeLevel;

// Enemy tracking
var int NearbyEnemyCount;             // Current count of enemies within range
var float LastEnemyCheckTime;         // Last time we scanned for enemies
var float EnemyCheckInterval;         // How often to scan (0.2 seconds)
var float LastUpdateTime;             // For deduplication

// Level 20 linger system
var float LastHighEnemyTime;          // Last time we had enough enemies for bonuses
var bool bHadHighEnemyCount;          // Whether we recently had high enemy count

// ===================================================================
// INITIALIZATION
// ===================================================================

function Initialize(int Level, KFPawn Pawn)
{
	OwnerPawn = Pawn;
	UpgradeLevel = Level;
	KFPC = KFPlayerController(OwnerPawn.Controller);
	
	NearbyEnemyCount = 0;
	LastEnemyCheckTime = 0.0f;
	EnemyCheckInterval = 0.2f; // Check 5 times per second
	LastUpdateTime = 0.0f;
	
	LastHighEnemyTime = 0.0f;
	bHadHighEnemyCount = false;
	
	// Initialize HUD
	InitializeHUD();
	
	// Enable tick for enemy scanning
	SetTickIsDisabled(false);
}

// ===================================================================
// HUD INITIALIZATION
// ===================================================================

reliable client function InitializeHUD()
{
	local DKHudWrapper HUD;
	
	if (KFPC == None || KFPC.myHUD == None) return;
	
	HUD = DKHudWrapper(KFPC.myHUD);
	if (HUD != None)
	{
		HUD.InitializeRiotTracking();
	}
}

// ===================================================================
// ENEMY TRACKING
// ===================================================================

function Tick(float DeltaTime)
{
	local float CurrentTime;
	
	if (OwnerPawn == None || OwnerPawn.Health <= 0)
	{
		Destroy();
		return;
	}
	
	CurrentTime = OwnerPawn.WorldInfo.TimeSeconds;
	
	// Scan for nearby enemies periodically
	if (CurrentTime - LastEnemyCheckTime >= EnemyCheckInterval)
	{
		ScanForNearbyEnemies();
		LastEnemyCheckTime = CurrentTime;
	}
	
	// Handle Level 20 linger effect
	if (UpgradeLevel >= class'DKConfig_Capstone'.default.Capstone_Rank2Level)
	{
		UpdateLingerEffect(CurrentTime);
	}
}

function ScanForNearbyEnemies()
{
	local KFPawn_Monster Monster;
	local float Distance, RadiusSq;
	local int Count, OldCount;
	local vector OwnerLoc;
	local float CurrentTime;
	
	if (OwnerPawn == None) return;
	
	CurrentTime = OwnerPawn.WorldInfo.TimeSeconds;
	
	// Deduplication window (50ms)
	if (CurrentTime - LastUpdateTime < 0.05f)
		return;
	
	OldCount = NearbyEnemyCount;
	Count = 0;
	OwnerLoc = OwnerPawn.Location;
	RadiusSq = class'DKUpgrade_Perk_Riot'.default.NearbyEnemyRadius * 
	           class'DKUpgrade_Perk_Riot'.default.NearbyEnemyRadius;
	
	// Count living enemies within radius
	foreach OwnerPawn.WorldInfo.AllPawns(class'KFPawn_Monster', Monster)
	{
		if (Monster.IsAliveAndWell())
		{
			Distance = VSizeSq(Monster.Location - OwnerLoc);
			if (Distance <= RadiusSq)
			{
				Count++;
				
				// Cap at max enemies
				if (Count >= class'DKUpgrade_Perk_Riot'.default.MaxNearbyEnemies)
				{
					Count = class'DKUpgrade_Perk_Riot'.default.MaxNearbyEnemies;
					break;
				}
			}
		}
	}
	
	// Update count (this is the raw count used for Level 10)
	NearbyEnemyCount = Count;
	
	// Track high enemy count for Level 20 linger
	if (UpgradeLevel >= class'DKConfig_Capstone'.default.Capstone_Rank2Level)
	{
		if (Count >= class'DKUpgrade_Perk_Riot'.default.MaxBonusThreshold)
		{
			LastHighEnemyTime = OwnerPawn.WorldInfo.TimeSeconds;
			bHadHighEnemyCount = true;
		}
	}
	
	// Update HUD if count changed
	if (Count != OldCount || Count > 0)
	{
		LastUpdateTime = CurrentTime;
		UpdateHUD();
	}
}

function UpdateLingerEffect(float CurrentTime)
{
	local float TimeSinceHigh;
	
	if (!bHadHighEnemyCount) return;
	
	// Check if we should still apply bonuses (linger effect)
	TimeSinceHigh = CurrentTime - LastHighEnemyTime;
	
	// If linger time expired and enemy count is low, end the linger
	if (TimeSinceHigh > class'DKUpgrade_Perk_Riot'.default.RiotLinger &&
	    NearbyEnemyCount < class'DKUpgrade_Perk_Riot'.default.MaxBonusThreshold)
	{
		bHadHighEnemyCount = false;
	}
}

// ===================================================================
// GETTER FUNCTIONS
// ===================================================================

function int GetNearbyEnemyCount()
{
	local float CurrentTime, TimeSinceHigh;
	
	// For Level 20+, apply linger effect
	if (UpgradeLevel >= class'DKConfig_Capstone'.default.Capstone_Rank2Level && bHadHighEnemyCount)
	{
		CurrentTime = OwnerPawn.WorldInfo.TimeSeconds;
		TimeSinceHigh = CurrentTime - LastHighEnemyTime;
		
		// If still within linger time, return at least the threshold
		if (TimeSinceHigh <= class'DKUpgrade_Perk_Riot'.default.RiotLinger)
		{
			return Max(NearbyEnemyCount, class'DKUpgrade_Perk_Riot'.default.MaxBonusThreshold);
		}
	}
	
	// Return actual count
	return NearbyEnemyCount;
}

// ===================================================================
// HUD UPDATES
// ===================================================================

function UpdateHUD()
{
	local int DisplayCount;
	local bool bMaxBonusActive;
	
	DisplayCount = GetNearbyEnemyCount();
	bMaxBonusActive = (DisplayCount >= class'DKUpgrade_Perk_Riot'.default.MaxBonusThreshold);
	
	ClientUpdateHUD(DisplayCount, bMaxBonusActive);
}

reliable client function ClientUpdateHUD(int EnemyCount, bool bMaxBonus)
{
	local DKHudWrapper HUD;
	
	if (KFPC == None || KFPC.myHUD == None) return;
	
	HUD = DKHudWrapper(KFPC.myHUD);
	if (HUD != None)
	{
		HUD.UpdateRiotTracking(EnemyCount, bMaxBonus);
	}
}

// ===================================================================
// CLEANUP
// ===================================================================

function Destroyed()
{
	// Clear timer
	SetTickIsDisabled(true);
	
	Super.Destroyed();
}

defaultproperties
{
	NearbyEnemyCount=0
	LastEnemyCheckTime=0.0f
	EnemyCheckInterval=0.2f
	LastUpdateTime=0.0f
	
	LastHighEnemyTime=0.0f
	bHadHighEnemyCount=false
	
	Name="Default__DKUpgrade_Perk_Riot_Helper"
}