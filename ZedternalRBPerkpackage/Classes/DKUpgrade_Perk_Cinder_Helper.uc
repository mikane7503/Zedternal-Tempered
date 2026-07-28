// ===================================================================
// DKUpgrade_Perk_Cinder_Helper - Burning Enemy Tracking
// Handles: Burning enemy count, fire kill tracking, Phoenix Protocol
// ===================================================================
class DKUpgrade_Perk_Cinder_Helper extends Info
	transient;

var KFPawn_Human Player;
var int UpgradeLevel;

// Burning enemy tracking
var int BurningEnemyCount;
var float LastBurningCheckTime;
var float BurningCheckInterval;

// Fire kill tracking (for permanent bonus)
var int TotalFireKills;
var float PermanentFireDamageBonus;

// Phoenix Protocol tracking
var bool bPhoenixProtocolUsedThisWave;
var bool bInPhoenixProtocol;
var float PhoenixProtocolEndTime;

// Sound effect for Phoenix Protocol
var SoundCue PhoenixSound;

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
		`log("Cinder Helper: Invalid owner, destroying");
		Destroy();
		return;
	}
	
	`log("Cinder Helper: Initialized for" @ Player.PlayerReplicationInfo.PlayerName);
}

function Initialize(KFPawn_Human NewPlayer, int NewUpgradeLevel)
{
	local DKMutator Mutator;
	
	Player = NewPlayer;
	UpgradeLevel = NewUpgradeLevel;
	
	BurningEnemyCount = 0;
	LastBurningCheckTime = 0.0f;
	BurningCheckInterval = 0.2f; // Check 5 times per second
	
	TotalFireKills = 0;
	PermanentFireDamageBonus = 0.0f;
	
	bPhoenixProtocolUsedThisWave = false;
	bInPhoenixProtocol = false;
	PhoenixProtocolEndTime = 0.0f;
	
	DebugUpdateCount = 0;
	
	// Load Phoenix Protocol sound via DKMutator
	foreach Player.WorldInfo.AllActors(class'DKMutator', Mutator)
	{
		`log("Cinder Helper: Found DKMutator, requesting Phoenix sound...");
		// FIXED: Use 'Phoenix_Protocol' not 'Phoenix_Protocol_Cue'
		PhoenixSound = Mutator.GetCustomSound('Phoenix_Protocol');
		if (PhoenixSound != None)
		{
			`log("Cinder Helper: ✓ Loaded Phoenix Protocol SoundCue:" @ PhoenixSound);
		}
		else
		{
			`log("Cinder Helper: ✗ Phoenix Protocol sound returned None!");
		}
		break;
	}
	
	`log("Cinder Helper: Initialized with upgrade level" @ UpgradeLevel);
}

function SetUpgradeLevel(int NewLevel)
{
	UpgradeLevel = NewLevel;
	`log("Cinder Helper: Upgrade level set to" @ UpgradeLevel);
}

// ===================================================================
// Main Tick - Track Burning Enemies and Phoenix Protocol
// ===================================================================
function Tick(float DeltaTime)
{
	local float CurrentTime;
	
	Super.Tick(DeltaTime);
	
	if (Player == None || Player.Health <= 0)
	{
		Cleanup();
		Destroy();
		return;
	}
	
	CurrentTime = Player.WorldInfo.TimeSeconds;
	
	// Scan for burning enemies periodically
	if (CurrentTime - LastBurningCheckTime >= BurningCheckInterval)
	{
		ScanForBurningEnemies();
		LastBurningCheckTime = CurrentTime;
	}
	
	// Check Phoenix Protocol timer
	if (bInPhoenixProtocol && CurrentTime >= PhoenixProtocolEndTime)
	{
		EndPhoenixProtocol();
	}
	
	// Update HUD
	UpdateHUD();
}

// ===================================================================
// Burning Enemy Tracking
// ===================================================================
function ScanForBurningEnemies()
{
	local KFPawn_Monster Monster;
	local int Count;
	local int i;
	
	if (Player == None)
		return;
	
	Count = 0;
	
	// Count all living, burning enemies
	foreach Player.WorldInfo.AllPawns(class'KFPawn_Monster', Monster)
	{
		if (Monster.IsAliveAndWell())
		{
			// Check if monster has fire DoT active
			for (i = 0; i < Monster.DamageOverTimeArray.Length; i++)
			{
				if (Monster.DamageOverTimeArray[i].DoT_Type == DOT_Fire)
				{
					Count++;
					
					// Cap at max burning enemies
					if (Count >= class'DKUpgrade_Perk_Cinder'.default.MaxBurningEnemyBonus)
					{
						Count = class'DKUpgrade_Perk_Cinder'.default.MaxBurningEnemyBonus;
						return; // Early out when we hit the cap
					}
					
					break; // This monster is counted, move to next
				}
			}
		}
	}
	
	BurningEnemyCount = Count;
}

function int GetBurningEnemyCount()
{
	return BurningEnemyCount;
}

// ===================================================================
// Fire Kill Tracking (for permanent bonus)
// ===================================================================
function OnFireKill()
{
	local int PreviousMilestone, CurrentMilestone;
	
	if (Player == None || Player.Role != ROLE_Authority)
		return;
	
	// Calculate milestone before kill
	PreviousMilestone = TotalFireKills / 100;
	
	TotalFireKills++;
	
	// Calculate milestone after kill
	CurrentMilestone = TotalFireKills / 100;
	
	// Check if we crossed a 100-kill threshold
	if (CurrentMilestone > PreviousMilestone)
	{
		PermanentFireDamageBonus = float(CurrentMilestone) * class'DKUpgrade_Perk_Cinder'.default.PermanentBonusPerKills;
		
		class'DKMessageManager'.static.SendImportant(
			KFPlayerController(Player.Controller),
			"FIRE SYMBIOTE MILESTONE: " $ TotalFireKills @ "fire kills! +" $ int(PermanentFireDamageBonus * 100) $ "% permanent fire damage!"
		);
		
		`log("Cinder: Fire kill milestone reached!" @ TotalFireKills @ "kills, +" $ (PermanentFireDamageBonus * 100) $ "% permanent bonus");
	}
}

function float GetPermanentBonus()
{
	return PermanentFireDamageBonus;
}

// ===================================================================
// Phoenix Protocol - Last Stand System (Level 20)
// ===================================================================
function TriggerPhoenixProtocol()
{
	local KFPawn_Monster Monster;
	local float DistSq, RadiusSq;
	local vector PlayerLoc;
	local KFPlayerController KFPC;
	local DKPlayerController DKPC;
	
	if (Player == None || Player.Role != ROLE_Authority)
		return;
	
	if (UpgradeLevel < class'DKConfig_Capstone'.default.Capstone_Rank2Level)
		return;
	
	if (bPhoenixProtocolUsedThisWave)
	{
		`log("Cinder: Phoenix Protocol already used this wave!");
		return;
	}
	
	bPhoenixProtocolUsedThisWave = true;
	bInPhoenixProtocol = true;
	PhoenixProtocolEndTime = Player.WorldInfo.TimeSeconds + class'DKUpgrade_Perk_Cinder'.default.PhoenixDuration;
	
	// ===================================================================
	// PLAY PHOENIX PROTOCOL SOUND
	// ===================================================================
	`log("Cinder: Playing Phoenix Protocol sound...");
	DKPC = DKPlayerController(Player.Controller);
	if (DKPC != None && PhoenixSound != None)
	{
		DKPC.ClientPlayPhoenixProtocolSound(PhoenixSound);
		`log("Cinder: ✓ Called ClientPlayPhoenixProtocolSound");
	}
	else
	{
		if (DKPC == None)
			`log("Cinder: ✗ Cannot play sound - Not a DKPlayerController!");
		if (PhoenixSound == None)
			`log("Cinder: ✗ Cannot play sound - PhoenixSound is None!");
	}
	
	PlayerLoc = Player.Location;
	RadiusSq = class'DKUpgrade_Perk_Cinder'.default.PhoenixRadius * class'DKUpgrade_Perk_Cinder'.default.PhoenixRadius;
	
	// Ignite all enemies within radius
	foreach Player.WorldInfo.AllPawns(class'KFPawn_Monster', Monster)
	{
		if (Monster.IsAliveAndWell())
		{
			DistSq = VSizeSq(Monster.Location - PlayerLoc);
			if (DistSq <= RadiusSq)
			{
				// Apply strong fire DoT
				Monster.ApplyDamageOverTime(
					50, // Base damage
					KFPlayerController(Player.Controller),
					class'DKDT_InfernoBlast'
				);
			}
		}
	}
	
	// Heal player to 50% health
	Player.Health = Max(Player.Health, Player.HealthMax / 2);
	
	KFPC = KFPlayerController(Player.Controller);
	if (KFPC != None)
	{
		class'DKMessageManager'.static.SendCritical(
			KFPC,
			"PHOENIX PROTOCOL ACTIVATED! You have 10 seconds of FULL IMMUNITY!"
		);
	}
	
	`log("Cinder: Phoenix Protocol TRIGGERED! Ignited nearby enemies and entered Last Stand");
}

function EndPhoenixProtocol()
{
	bInPhoenixProtocol = false;
	
	class'DKMessageManager'.static.SendImportant(
		KFPlayerController(Player.Controller),
		"Phoenix Protocol ended - fight on!"
	);
	
	`log("Cinder: Phoenix Protocol ended");
}

// Called when wave starts - reset Phoenix Protocol
function ResetPhoenixProtocol()
{
	bPhoenixProtocolUsedThisWave = false;
	bInPhoenixProtocol = false;
	
	`log("Cinder: Phoenix Protocol reset for new wave");
}

// ===================================================================
// HUD Updates
// ===================================================================
function UpdateHUD()
{
	local float RemainingTime;
	
	// Calculate remaining Phoenix Protocol time
	if (bInPhoenixProtocol && Player != None)
	{
		RemainingTime = PhoenixProtocolEndTime - Player.WorldInfo.TimeSeconds;
		RemainingTime = FMax(0.0f, RemainingTime); // Clamp to 0
	}
	else
	{
		RemainingTime = 0.0f;
	}
	
	ClientUpdateHUD(BurningEnemyCount, TotalFireKills, PermanentFireDamageBonus, bInPhoenixProtocol, RemainingTime);
}

reliable client function ClientUpdateHUD(int BurningCount, int FireKills, float PermanentBonus, bool bPhoenix, float PhoenixTimeRemaining)
{
	local DKPlayerController DKPC;
	local DKHudWrapper CinderHUD;
	
	// Debug counter - log every 50 calls to avoid spam
	DebugUpdateCount++;
	if (DebugUpdateCount % 50 == 1)
	{
		`log("Cinder Helper CLIENT: ClientUpdateHUD called (call #" $ DebugUpdateCount $ ")");
		`log("Cinder Helper CLIENT: BurningCount=" $ BurningCount @ "FireKills=" $ FireKills @ "Bonus=" $ PermanentBonus @ "Phoenix=" $ bPhoenix @ "TimeLeft=" $ PhoenixTimeRemaining @ "Level=" $ UpgradeLevel);
	}
	
	// Get local player controller
	DKPC = DKPlayerController(GetALocalPlayerController());
	if (DKPC == None)
	{
		if (DebugUpdateCount % 50 == 1)
			`log("Cinder Helper CLIENT: ✗ GetALocalPlayerController returned None or not DKPlayerController!");
		return;
	}
	
	if (DebugUpdateCount % 50 == 1)
		`log("Cinder Helper CLIENT: ✓ Got DKPlayerController:" @ DKPC);
	
	// Get HUD using GetReaperHUD static function
	CinderHUD = class'DKHudWrapper'.static.GetReaperHUD(DKPC);
	if (CinderHUD == None)
	{
		if (DebugUpdateCount % 50 == 1)
			`log("Cinder Helper CLIENT: ✗ GetReaperHUD returned None!");
		return;
	}
	
	if (DebugUpdateCount % 50 == 1)
		`log("Cinder Helper CLIENT: ✓ Got CinderHUD:" @ CinderHUD);
	
	// Call UpdateCinderTracking
	CinderHUD.UpdateCinderTracking(BurningCount, FireKills, PermanentBonus, bPhoenix, UpgradeLevel, PhoenixTimeRemaining);
	
	if (DebugUpdateCount % 50 == 1)
		`log("Cinder Helper CLIENT: ✓ Called UpdateCinderTracking successfully!");
}

// ===================================================================
// Cleanup
// ===================================================================
function Cleanup()
{
	`log("Cinder Helper: Cleaned up - Total fire kills:" @ TotalFireKills @ "Permanent bonus:" @ (PermanentFireDamageBonus * 100) $ "%");
}

// ===================================================================
// Default Properties
// ===================================================================
defaultproperties
{
	BurningEnemyCount=0
	LastBurningCheckTime=0.0f
	BurningCheckInterval=0.2f
	
	TotalFireKills=0
	PermanentFireDamageBonus=0.0f
	
	bPhoenixProtocolUsedThisWave=false
	bInPhoenixProtocol=false
	PhoenixProtocolEndTime=0.0f
	
	DebugUpdateCount=0
	
	Name="Default__DKUpgrade_Perk_Cinder_Helper"
}
