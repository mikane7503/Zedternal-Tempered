// ===================================================================
// ZTUpgrade_Perk_Haunted_Helper - The Watcher System Controller
// Handles: wave disaster, kill tracking, escalation, HUD sync
// ===================================================================
class ZTUpgrade_Perk_Haunted_Helper extends Info transient;

// ===================================================================
// Core State
// ===================================================================
var KFPawn_Human Player;
var int UpgradeLevel;

// Watcher activation state
var bool bWatcherActive;

// Kill tracking for escalation
var int TotalKills;
var int CurrentStage;

// ===================================================================
// Eye System State (replicated to client)
// ===================================================================
struct WatcherEyeData
{
	var float PosX;              // Screen position X (0-1)
	var float PosY;              // Screen position Y (0-1)
	var float Size;              // Eye size multiplier
	var float Alpha;             // Current alpha (for fade)
	var float TargetAlpha;       // Target alpha (fading toward)
	var float PupilOffsetX;      // Pupil tracking offset X
	var float PupilOffsetY;      // Pupil tracking offset Y
	var float Lifetime;          // How long this eye has existed
	var float MaxLifetime;       // When to start fading out
	var bool bBlinking;          // Is eye currently blinking
	var float BlinkTimer;        // Blink animation timer
};

var array<WatcherEyeData> ActiveEyes;
var int MaxEyesPerStage[6];      // Max eyes allowed at each stage (0-5)

// Eye spawn timing
var float LastEyeSpawnTime;
var float EyeSpawnIntervalMin[6];  // Min seconds between eye spawns per stage
var float EyeSpawnIntervalMax[6];  // Max seconds between eye spawns per stage
var float NextEyeSpawnTime;

// ===================================================================
// Visual Effect State
// ===================================================================
var float VignetteIntensity;     // Current vignette darkness (0-1)
var float TargetVignetteIntensity;

var bool bStaticFlashActive;
var float StaticFlashTimer;
var float LastStaticTime;

var bool bSubliminalTextActive;
var string SubliminalText;
var float SubliminalTextX;
var float SubliminalTextY;
var float SubliminalTextTimer;
var float LastSubliminalTime;

var bool bScreenDimActive;
var float ScreenDimTimer;

var bool bColorInvertActive;
var float ColorInvertTimer;

var bool bScanLineActive;
var float ScanLineY;

// Subliminal text options
var array<string> SubliminalTexts;

// ===================================================================
// Sound References
// ===================================================================
var SoundCue WatcherAmbientSound;
var SoundCue WatcherEyeAppearSound;
var SoundCue WatcherEyeBlinkSound;
var SoundCue WatcherWhisperSound;
var SoundCue WatcherStaticSound;
var SoundCue WatcherHeartbeatSound;
var SoundCue WatcherEscalateSound;

var bool bAmbientPlaying;
var float LastHeartbeatTime;
var float HeartbeatInterval;

// Debug
var int DebugUpdateCount;
var float LastHUDUpdateTime;
var float HUDUpdateInterval;

// Once-per-wave global disaster
var int DisasterWaveNum;
var float DisasterTriggerProgress;
var float DisasterFireTime;
var byte PendingDisasterType;
var bool bDisasterWarningActive;
var bool bDisasterFired;
var bool bDisasterWindowInitialized;

// ===================================================================
// Initialization
// ===================================================================
function PostBeginPlay()
{
	Super.PostBeginPlay();
	
	Player = KFPawn_Human(Owner);
	if (Player == None || Player.Health <= 0)
	{
		`log("Haunted Helper: Invalid owner, destroying");
		Destroy();
		return;
	}
	
	`log("Haunted Helper: Initialized for" @ Player.PlayerReplicationInfo.PlayerName);
}

function Initialize(KFPawn_Human NewPlayer, int NewUpgradeLevel)
{
	local ZTMutator Mutator;
	
	Player = NewPlayer;
	UpgradeLevel = NewUpgradeLevel;
	
	// Initialize state
	bWatcherActive = false;
	TotalKills = 0;
	CurrentStage = 0;
	
	// Initialize eye spawn timing
	LastEyeSpawnTime = Player.WorldInfo.TimeSeconds;
	NextEyeSpawnTime = Player.WorldInfo.TimeSeconds + RandRange(EyeSpawnIntervalMin[0], EyeSpawnIntervalMax[0]);
	
	// Initialize visual state
	VignetteIntensity = 0.0f;
	TargetVignetteIntensity = 0.0f;
	bStaticFlashActive = false;
	bSubliminalTextActive = false;
	bScreenDimActive = false;
	bColorInvertActive = false;
	bScanLineActive = false;
	
	bAmbientPlaying = false;
	LastHeartbeatTime = 0.0f;
	
	DebugUpdateCount = 0;
	LastHUDUpdateTime = 0.0f;
	DisasterWaveNum = 0;
	bDisasterWarningActive = false;
	bDisasterFired = false;
	bDisasterWindowInitialized = false;

	// Initialize subliminal texts
	SubliminalTexts.Length = 0;
	SubliminalTexts.AddItem("SEEN");
	SubliminalTexts.AddItem("FOUND");
	SubliminalTexts.AddItem("WATCHING");
	SubliminalTexts.AddItem("BEHIND YOU");
	SubliminalTexts.AddItem("CLOSER");
	SubliminalTexts.AddItem("ALWAYS");
	SubliminalTexts.AddItem("NO ESCAPE");
	SubliminalTexts.AddItem("IT SEES");
	
	// Load sounds via ZTMutator
	foreach Player.WorldInfo.AllActors(class'ZTMutator', Mutator)
	{
		`log("Haunted Helper: Found ZTMutator, requesting sounds...");
		
		WatcherAmbientSound = Mutator.GetCustomSound('Watcher_Ambient');
		WatcherEyeAppearSound = Mutator.GetCustomSound('Watcher_Eye_Appear');
		WatcherEyeBlinkSound = Mutator.GetCustomSound('Watcher_Eye_Blink');
		WatcherWhisperSound = Mutator.GetCustomSound('Watcher_Whisper');
		WatcherStaticSound = Mutator.GetCustomSound('Watcher_Static');
		WatcherHeartbeatSound = Mutator.GetCustomSound('Watcher_Heartbeat');
		WatcherEscalateSound = Mutator.GetCustomSound('Watcher_Escalate');
		
		if (WatcherAmbientSound != None)
			`log("Haunted Helper: ? Loaded Watcher_Ambient");
		if (WatcherEyeAppearSound != None)
			`log("Haunted Helper: ? Loaded Watcher_Eye_Appear");
		if (WatcherEscalateSound != None)
			`log("Haunted Helper: ? Loaded Watcher_Escalate");
			
		break;
	}

	// Owning Haunted is now the activation condition. Activate only after the
	// sound references are ready so the awakening cue is not lost.
	ActivateWatcher();
	
	`log("Haunted Helper: Initialized with upgrade level" @ UpgradeLevel);
}

function SetUpgradeLevel(int NewLevel)
{
	UpgradeLevel = NewLevel;
}

// ===================================================================
// Main Tick
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
	UpdateWaveDisaster(CurrentTime);
	
	// If Watcher is active, run the horror systems
	if (bWatcherActive)
	{
		UpdateEscalation();
		UpdateEyes(DeltaTime);
		UpdateVisualEffects(DeltaTime);
		UpdateSounds(DeltaTime);
		if (CurrentTime - LastHUDUpdateTime >= HUDUpdateInterval)
		{
			UpdateHUD();
			LastHUDUpdateTime = CurrentTime;
		}
	}
}

// ===================================================================
// Once-per-wave global disaster
// ===================================================================
function UpdateWaveDisaster(float CurrentTime)
{
	local KFGameReplicationInfo KFGRI;
	local ZTPlayerController DKPC;
	local float WaveProgress;

	KFGRI = KFGameReplicationInfo(Player.WorldInfo.GRI);
	if (KFGRI == None)
		return;

	if (!KFGRI.bWaveIsActive || KFGRI.bTraderIsOpen || KFGRI.WaveNum <= 0)
	{
		bDisasterWarningActive = false;
		return;
	}

	DKPC = ZTPlayerController(Player.Controller);
	if (DisasterWaveNum != KFGRI.WaveNum)
	{
		DisasterWaveNum = KFGRI.WaveNum;
		DisasterTriggerProgress = RandRange(
			class'ZTUpgrade_Perk_Haunted'.default.DisasterMinWaveProgress,
			class'ZTUpgrade_Perk_Haunted'.default.DisasterMaxWaveProgress);
		bDisasterWarningActive = false;
		bDisasterFired = (DKPC != None && DKPC.LastHauntedDisasterWave == DisasterWaveNum);
		bDisasterWindowInitialized = false;

		`log("Haunted: Wave" @ DisasterWaveNum @ "disaster target progress" @ DisasterTriggerProgress);
	}

	if (bDisasterFired)
		return;

	if (bDisasterWarningActive)
	{
		if (CurrentTime >= DisasterFireTime)
			FireWaveDisaster();
		return;
	}

	if (KFGRI.WaveTotalAICount <= 0)
		return;

	WaveProgress = 1.0f - FClamp(
		float(KFGRI.AIRemaining) / float(KFGRI.WaveTotalAICount), 0.0f, 1.0f);

	// A helper first created after a late-wave respawn must not enter after the
	// 70% boundary. Once initialized normally, crossing a threshold in a large
	// kill burst still guarantees the wave's one activation.
	if (!bDisasterWindowInitialized)
	{
		bDisasterWindowInitialized = true;
		if (WaveProgress > class'ZTUpgrade_Perk_Haunted'.default.DisasterMaxWaveProgress)
		{
			bDisasterFired = true;
			return;
		}
	}

	if (WaveProgress >= DisasterTriggerProgress)
		BeginDisasterWarning(CurrentTime);
}

function BeginDisasterWarning(float CurrentTime)
{
	local ZTPlayerController DKPC;
	local float WarningDuration;

	WarningDuration = class'ZTUpgrade_Perk_Haunted'.default.DisasterWarningDuration;
	PendingDisasterType = Rand(4);
	bDisasterWarningActive = true;
	DisasterFireTime = CurrentTime + WarningDuration;

	// Caster-only warning, carried by the existing Watcher HUD channel.
	bStaticFlashActive = true;
	StaticFlashTimer = WarningDuration;
	bSubliminalTextActive = true;
	SubliminalTextTimer = WarningDuration;
	SubliminalText = "IT COMES";
	SubliminalTextX = 0.5f;
	SubliminalTextY = 0.45f;
	bScreenDimActive = true;
	ScreenDimTimer = WarningDuration;
	bColorInvertActive = true;
	ColorInvertTimer = WarningDuration;
	bScanLineActive = true;
	ScanLineY = -0.2f;

	DKPC = ZTPlayerController(Player.Controller);
	if (DKPC != None)
	{
		if (WatcherEscalateSound != None)
			DKPC.ClientPlayWatcherSound(WatcherEscalateSound);
		class'ZTMessageManager'.static.SendImportant(DKPC, "The Watcher is about to descend.");
	}
}

function FireWaveDisaster()
{
	local ZTPlayerController DKPC;
	local KFPawn_Monster KFM;
	local vector Momentum;
	local int BaseDamage, EventDamage, HitCount;
	local string EventName;

	if (bDisasterFired || Player == None)
		return;

	DKPC = ZTPlayerController(Player.Controller);
	BaseDamage = Max(0, UpgradeLevel * class'ZTUpgrade_Perk_Haunted'.default.DisasterDamagePerLevel);
	EventDamage = BaseDamage;
	if (PendingDisasterType == 1)
		EventDamage = Round(float(BaseDamage) * class'ZTUpgrade_Perk_Haunted'.default.ExplosionDamageMultiplier);

	foreach Player.DynamicActors(class'KFPawn_Monster', KFM)
	{
		if (!KFM.IsAliveAndWell())
			continue;

		Momentum = Normal(KFM.Location - Player.Location);
		if (IsZero(Momentum))
			Momentum = vect(1,0,0);

		switch (PendingDisasterType)
		{
			case 0: // Freeze + damage
				KFM.TakeDamage(EventDamage, DKPC, KFM.Location, Momentum * 50.0f, class'ZTDT_HauntedFreeze', , Player);
				EventName = "Frozen Ruin";
				break;

			case 1: // Double explosion damage
				KFM.TakeDamage(EventDamage, DKPC, KFM.Location, Momentum * 1000.0f, class'ZTDT_HauntedExplosion', , Player);
				EventName = "Cataclysm";
				break;

			case 2: // Knockdown + damage
				KFM.TakeDamage(EventDamage, DKPC, KFM.Location, Momentum * 500.0f, class'KFDT_Bludgeon', , Player);
				if (KFM.IsAliveAndWell() && KFM.CanDoSpecialMove(SM_Knockdown))
					KFM.Knockdown(Momentum * 500.0f + vect(0,0,250), vect(1,1,1), KFM.Location, 1000, 100);
				EventName = "Crushing Dread";
				break;

			case 3: // Ignite + damage
				KFM.TakeDamage(EventDamage, DKPC, KFM.Location, Momentum * 50.0f, class'ZTDT_HauntedFire', , Player);
				EventName = "Infernal Gaze";
				break;
		}

		HitCount++;
	}

	bDisasterWarningActive = false;
	bDisasterFired = true;
	if (DKPC != None)
	{
		DKPC.LastHauntedDisasterWave = DisasterWaveNum;
		class'ZTMessageManager'.static.SendImportant(DKPC,
			EventName $ " - " $ EventDamage $ " damage to " $ HitCount $ " zeds.");
		if (WatcherStaticSound != None)
			DKPC.ClientPlayWatcherSound(WatcherStaticSound);
	}

	`log("Haunted: Fired" @ EventName @ "on wave" @ DisasterWaveNum
		@ "damage" @ EventDamage @ "targets" @ HitCount);
}

function ActivateWatcher()
{
	local ZTPlayerController DKPC;
	
	if (bWatcherActive)
		return;
	
	bWatcherActive = true;
	CurrentStage = 1;
	TotalKills = 0;
	
	// Set initial vignette for stage 1
	TargetVignetteIntensity = 0.05f;
	
	// Start ambient sound
	DKPC = ZTPlayerController(Player.Controller);
	if (DKPC != None && WatcherAmbientSound != None)
	{
		DKPC.ClientPlayWatcherSound(WatcherAmbientSound);
		bAmbientPlaying = true;
	}
	
	`log("Haunted: THE WATCHER HAS AWAKENED");
}

// ===================================================================
// Kill Tracking (called externally when player gets a kill)
// ===================================================================
function OnKill()
{
	local int NewStage;
	
	if (!bWatcherActive)
		return;
	
	if (Player == None || Player.Role != ROLE_Authority)
		return;
	
	TotalKills++;
	
	// Calculate new stage based on kills
	NewStage = (TotalKills / class'ZTUpgrade_Perk_Haunted'.default.KillsPerStage) + 1;
	NewStage = Min(NewStage, class'ZTUpgrade_Perk_Haunted'.default.MaxStage);
	
	// Check for stage advancement
	if (NewStage > CurrentStage)
	{
		AdvanceStage(NewStage);
	}
}

function AdvanceStage(int NewStage)
{
	local ZTPlayerController DKPC;
	
	CurrentStage = NewStage;
	
	// Update vignette intensity for new stage
	switch (CurrentStage)
	{
		case 1:
			TargetVignetteIntensity = 0.05f;
			HeartbeatInterval = 0.0f; // No heartbeat
			break;
		case 2:
			TargetVignetteIntensity = 0.15f;
			HeartbeatInterval = 0.0f;
			break;
		case 3:
			TargetVignetteIntensity = 0.20f;
			HeartbeatInterval = 0.0f;
			break;
		case 4:
			TargetVignetteIntensity = 0.25f;
			HeartbeatInterval = 2.0f; // Start heartbeat
			break;
		case 5:
			TargetVignetteIntensity = 0.30f;
			HeartbeatInterval = 1.2f; // Faster heartbeat
			break;
	}
	
	// Play escalation sound
	DKPC = ZTPlayerController(Player.Controller);
	if (DKPC != None && WatcherEscalateSound != None)
	{
		DKPC.ClientPlayWatcherSound(WatcherEscalateSound);
	}
	
	`log("Haunted: Stage advanced to" @ CurrentStage @ "- Total kills:" @ TotalKills);
}

// ===================================================================
// Escalation Updates
// ===================================================================
function UpdateEscalation()
{
	// Vignette lerp
	VignetteIntensity = FInterpTo(VignetteIntensity, TargetVignetteIntensity, 0.016f, 2.0f);
}

// ===================================================================
// Eye Management
// ===================================================================
function UpdateEyes(float DeltaTime)
{
	local int i;
	local float CurrentTime;
	local ZTPlayerController DKPC;
	
	CurrentTime = Player.WorldInfo.TimeSeconds;
	
	// Update existing eyes
	for (i = ActiveEyes.Length - 1; i >= 0; i--)
	{
		// Update lifetime
		ActiveEyes[i].Lifetime += DeltaTime;
		
		// Fade in
		if (ActiveEyes[i].Alpha < ActiveEyes[i].TargetAlpha)
		{
			ActiveEyes[i].Alpha = FMin(ActiveEyes[i].Alpha + DeltaTime * 2.0f, ActiveEyes[i].TargetAlpha);
		}
		
		// Start fading out after max lifetime
		if (ActiveEyes[i].Lifetime >= ActiveEyes[i].MaxLifetime)
		{
			ActiveEyes[i].TargetAlpha = 0.0f;
			ActiveEyes[i].Alpha = FMax(ActiveEyes[i].Alpha - DeltaTime * 1.5f, 0.0f);
		}
		
		// Remove fully faded eyes
		if (ActiveEyes[i].Lifetime >= ActiveEyes[i].MaxLifetime && ActiveEyes[i].Alpha <= 0.0f)
		{
			ActiveEyes.Remove(i, 1);
			continue;
		}
		
		// Update blink
		if (ActiveEyes[i].bBlinking)
		{
			ActiveEyes[i].BlinkTimer -= DeltaTime;
			if (ActiveEyes[i].BlinkTimer <= 0.0f)
			{
				ActiveEyes[i].bBlinking = false;
			}
		}
		else if (CurrentStage >= 5 && FRand() < 0.002f) // Random blink at stage 5
		{
			ActiveEyes[i].bBlinking = true;
			ActiveEyes[i].BlinkTimer = 0.15f;
			
			// Play blink sound
			DKPC = ZTPlayerController(Player.Controller);
			if (DKPC != None && WatcherEyeBlinkSound != None)
			{
				DKPC.ClientPlayWatcherSound(WatcherEyeBlinkSound);
			}
		}
		
		// Stage 4+: Eyes track toward center
		if (CurrentStage >= 4)
		{
			ActiveEyes[i].PosX = FInterpTo(ActiveEyes[i].PosX, 0.5f, DeltaTime, 0.05f);
			ActiveEyes[i].PosY = FInterpTo(ActiveEyes[i].PosY, 0.5f, DeltaTime, 0.05f);
		}
		
		// Stage 5: Eyes drift inward more aggressively
		if (CurrentStage >= 5)
		{
			ActiveEyes[i].PosX = FInterpTo(ActiveEyes[i].PosX, 0.5f, DeltaTime, 0.1f);
			ActiveEyes[i].PosY = FInterpTo(ActiveEyes[i].PosY, 0.5f, DeltaTime, 0.1f);
		}
	}
	
	// Spawn new eyes
	if (CurrentTime >= NextEyeSpawnTime && ActiveEyes.Length < MaxEyesPerStage[CurrentStage])
	{
		SpawnEye();
		NextEyeSpawnTime = CurrentTime + RandRange(EyeSpawnIntervalMin[CurrentStage], EyeSpawnIntervalMax[CurrentStage]);
	}
}

function SpawnEye()
{
	local WatcherEyeData NewEye;
	local int Edge;
	local ZTPlayerController DKPC;
	
	// Determine spawn position (screen edge)
	Edge = Rand(4);
	
	switch (Edge)
	{
		case 0: // Top
			NewEye.PosX = FRand() * 0.6f + 0.2f;
			NewEye.PosY = 0.02f + FRand() * 0.08f;
			break;
		case 1: // Bottom
			NewEye.PosX = FRand() * 0.6f + 0.2f;
			NewEye.PosY = 0.88f + FRand() * 0.08f;
			break;
		case 2: // Left
			NewEye.PosX = 0.02f + FRand() * 0.08f;
			NewEye.PosY = FRand() * 0.6f + 0.2f;
			break;
		case 3: // Right
			NewEye.PosX = 0.88f + FRand() * 0.08f;
			NewEye.PosY = FRand() * 0.6f + 0.2f;
			break;
	}
	
	// Higher stages: eyes can spawn closer to center
	if (CurrentStage >= 4)
	{
		NewEye.PosX = FRand() * 0.4f + 0.3f;
		NewEye.PosY = FRand() * 0.4f + 0.3f;
	}
	
	// Size based on stage (larger = feels closer)
	NewEye.Size = 0.8f + (float(CurrentStage) * 0.15f) + FRand() * 0.3f;
	
	// Start invisible, fade in
	NewEye.Alpha = 0.0f;
	NewEye.TargetAlpha = 0.7f + FRand() * 0.3f;
	
	// Pupil starts centered
	NewEye.PupilOffsetX = 0.0f;
	NewEye.PupilOffsetY = 0.0f;
	
	// Lifetime based on stage
	NewEye.Lifetime = 0.0f;
	NewEye.MaxLifetime = 1.0f + float(CurrentStage) * 0.5f + FRand() * 1.0f;
	
	NewEye.bBlinking = false;
	NewEye.BlinkTimer = 0.0f;
	
	ActiveEyes.AddItem(NewEye);
	
	// Play eye appear sound
	DKPC = ZTPlayerController(Player.Controller);
	if (DKPC != None && WatcherEyeAppearSound != None)
	{
		DKPC.ClientPlayWatcherSound(WatcherEyeAppearSound);
	}
	
	`log("Haunted: Eye spawned at" @ NewEye.PosX @ "," @ NewEye.PosY @ "- Total eyes:" @ ActiveEyes.Length);
}

// ===================================================================
// Visual Effects Updates
// ===================================================================
function UpdateVisualEffects(float DeltaTime)
{
	local float CurrentTime;
	local float StaticChance, SubliminalChance, DimChance, InvertChance, ScanChance;
	local ZTPlayerController DKPC;
	
	CurrentTime = Player.WorldInfo.TimeSeconds;
	
	// Calculate effect chances based on stage
	switch (CurrentStage)
	{
		case 1:
			StaticChance = 0.0f;
			SubliminalChance = 0.0f;
			DimChance = 0.0f;
			InvertChance = 0.0f;
			ScanChance = 0.0f;
			break;
		case 2:
			StaticChance = 0.0f;
			SubliminalChance = 0.0f;
			DimChance = 0.0f;
			InvertChance = 0.0f;
			ScanChance = 0.0f;
			break;
		case 3:
			StaticChance = 0.001f;
			SubliminalChance = 0.0f;
			DimChance = 0.0f;
			InvertChance = 0.0f;
			ScanChance = 0.0f;
			break;
		case 4:
			StaticChance = 0.002f;
			SubliminalChance = 0.001f;
			DimChance = 0.001f;
			InvertChance = 0.0f;
			ScanChance = 0.0f;
			break;
		case 5:
			StaticChance = 0.003f;
			SubliminalChance = 0.002f;
			DimChance = 0.002f;
			InvertChance = 0.0005f;
			ScanChance = 0.002f;
			break;
	}
	
	// Static flash
	if (bStaticFlashActive)
	{
		StaticFlashTimer -= DeltaTime;
		if (StaticFlashTimer <= 0.0f)
		{
			bStaticFlashActive = false;
		}
	}
	else if (FRand() < StaticChance && CurrentTime - LastStaticTime > 3.0f)
	{
		bStaticFlashActive = true;
		StaticFlashTimer = 0.1f + FRand() * 0.1f;
		LastStaticTime = CurrentTime;
		
		DKPC = ZTPlayerController(Player.Controller);
		if (DKPC != None && WatcherStaticSound != None)
		{
			DKPC.ClientPlayWatcherSound(WatcherStaticSound);
		}
	}
	
	// Subliminal text
	if (bSubliminalTextActive)
	{
		SubliminalTextTimer -= DeltaTime;
		if (SubliminalTextTimer <= 0.0f)
		{
			bSubliminalTextActive = false;
		}
	}
	else if (FRand() < SubliminalChance && CurrentTime - LastSubliminalTime > 5.0f)
	{
		bSubliminalTextActive = true;
		SubliminalTextTimer = 0.05f + FRand() * 0.05f; // 1-3 frames
		SubliminalText = SubliminalTexts[Rand(SubliminalTexts.Length)];
		SubliminalTextX = FRand() * 0.6f + 0.2f;
		SubliminalTextY = FRand() * 0.6f + 0.2f;
		LastSubliminalTime = CurrentTime;
		
		DKPC = ZTPlayerController(Player.Controller);
		if (DKPC != None && WatcherWhisperSound != None)
		{
			DKPC.ClientPlayWatcherSound(WatcherWhisperSound);
		}
	}
	
	// Screen dim
	if (bScreenDimActive)
	{
		ScreenDimTimer -= DeltaTime;
		if (ScreenDimTimer <= 0.0f)
		{
			bScreenDimActive = false;
		}
	}
	else if (FRand() < DimChance)
	{
		bScreenDimActive = true;
		ScreenDimTimer = 0.08f + FRand() * 0.04f;
	}
	
	// Color invert (stage 5 only)
	if (bColorInvertActive)
	{
		ColorInvertTimer -= DeltaTime;
		if (ColorInvertTimer <= 0.0f)
		{
			bColorInvertActive = false;
		}
	}
	else if (FRand() < InvertChance)
	{
		bColorInvertActive = true;
		ColorInvertTimer = 0.03f + FRand() * 0.02f;
	}
	
	// Scan lines (stage 5 only)
	if (bScanLineActive)
	{
		ScanLineY += DeltaTime * 500.0f;
		if (ScanLineY > 1.2f)
		{
			bScanLineActive = false;
		}
	}
	else if (FRand() < ScanChance)
	{
		bScanLineActive = true;
		ScanLineY = -0.2f;
	}
}

// ===================================================================
// Sound Updates
// ===================================================================
function UpdateSounds(float DeltaTime)
{
	local float CurrentTime;
	local ZTPlayerController DKPC;
	
	if (HeartbeatInterval <= 0.0f)
		return;
	
	CurrentTime = Player.WorldInfo.TimeSeconds;
	
	if (CurrentTime - LastHeartbeatTime >= HeartbeatInterval)
	{
		DKPC = ZTPlayerController(Player.Controller);
		if (DKPC != None && WatcherHeartbeatSound != None)
		{
			DKPC.ClientPlayWatcherSound(WatcherHeartbeatSound);
		}
		LastHeartbeatTime = CurrentTime;
	}
}

// ===================================================================
// HUD Communication
// ===================================================================
// ===================================================================
// HUD Communication - FIXED VERSION
// ===================================================================
function UpdateHUD()
{
	local int i;
	local ZTPlayerController DKPC;

	DKPC = ZTPlayerController(Player.Controller);
	if (DKPC == None)
		return;
	
	DebugUpdateCount++;
	
	// The helper is server-only; the replicated owning controller carries the RPC.
	DKPC.ClientUpdateWatcherHUD(
		bWatcherActive,
		CurrentStage,
		VignetteIntensity,
		bStaticFlashActive,
		bSubliminalTextActive,
		SubliminalText,
		SubliminalTextX,
		SubliminalTextY,
		bScreenDimActive,
		bColorInvertActive,
		bScanLineActive,
		ScanLineY
	);
	
	// Send eye count first
	DKPC.ClientSetWatcherEyeCount(ActiveEyes.Length);
	
	// Send each eye individually to avoid struct type mismatch
	for (i = 0; i < ActiveEyes.Length; i++)
	{
		DKPC.ClientUpdateWatcherEye(
			i,
			ActiveEyes[i].PosX,
			ActiveEyes[i].PosY,
			ActiveEyes[i].Size,
			ActiveEyes[i].Alpha,
			ActiveEyes[i].PupilOffsetX,
			ActiveEyes[i].PupilOffsetY,
			ActiveEyes[i].bBlinking,
			ActiveEyes[i].BlinkTimer
		);
	}
}

reliable client function ClientUpdateWatcherHUD(
	bool bActive,
	int Stage,
	float Vignette,
	bool bStaticFlash,
	bool bSubliminal,
	string SubText,
	float SubX,
	float SubY,
	bool bDim,
	bool bInvert,
	bool bScan,
	float ScanY)
{
	local ZTPlayerController DKPC;
	local ZTHudWrapper WatcherHUD;
	
	DKPC = ZTPlayerController(GetALocalPlayerController());
	if (DKPC == None)
		return;
	
	WatcherHUD = class'ZTHudWrapper'.static.GetReaperHUD(DKPC);
	if (WatcherHUD == None)
		return;
	
	WatcherHUD.UpdateWatcherEffects(
		bActive,
		Stage,
		Vignette,
		bStaticFlash,
		bSubliminal,
		SubText,
		SubX,
		SubY,
		bDim,
		bInvert,
		bScan,
		ScanY
	);
}

reliable client function ClientSetWatcherEyeCount(int Count)
{
	local ZTPlayerController DKPC;
	local ZTHudWrapper WatcherHUD;
	
	DKPC = ZTPlayerController(GetALocalPlayerController());
	if (DKPC == None)
		return;
	
	WatcherHUD = class'ZTHudWrapper'.static.GetReaperHUD(DKPC);
	if (WatcherHUD == None)
		return;
	
	WatcherHUD.SetWatcherEyeCount(Count);
}

reliable client function ClientUpdateWatcherEye(
	int EyeIndex,
	float PosX,
	float PosY,
	float Size,
	float Alpha,
	float PupilOffX,
	float PupilOffY,
	bool bBlinkingState,
	float BlinkTime)
{
	local ZTPlayerController DKPC;
	local ZTHudWrapper WatcherHUD;
	
	DKPC = ZTPlayerController(GetALocalPlayerController());
	if (DKPC == None)
		return;
	
	WatcherHUD = class'ZTHudWrapper'.static.GetReaperHUD(DKPC);
	if (WatcherHUD == None)
		return;
	
	WatcherHUD.UpdateWatcherEye(
		EyeIndex,
		PosX,
		PosY,
		Size,
		Alpha,
		PupilOffX,
		PupilOffY,
		bBlinkingState,
		BlinkTime
	);
}

// ===================================================================
// Cleanup
// ===================================================================
function Cleanup()
{
	local ZTPlayerController DKPC;

	if (Player != None)
	{
		DKPC = ZTPlayerController(Player.Controller);
		if (DKPC != None)
		{
			DKPC.ClientUpdateWatcherHUD(false, 0, 0.0f, false, false, "", 0.5f, 0.5f, false, false, false, 0.0f);
			DKPC.ClientSetWatcherEyeCount(0);
		}
	}

	ActiveEyes.Length = 0;
	bWatcherActive = false;
	`log("Haunted Helper: Cleaned up - Total kills:" @ TotalKills @ "Final stage:" @ CurrentStage);
}

// ===================================================================
// Default Properties
// ===================================================================
defaultproperties
{
	bOnlyRelevantToOwner=True
	
	bWatcherActive=false
	TotalKills=0
	CurrentStage=0
	
	HUDUpdateInterval=0.1f
	
	// Max eyes per stage (index 0 unused, stages 1-5)
	MaxEyesPerStage(0)=0
	MaxEyesPerStage(1)=1
	MaxEyesPerStage(2)=1
	MaxEyesPerStage(3)=2
	MaxEyesPerStage(4)=3
	MaxEyesPerStage(5)=4
	
	// Eye spawn intervals per stage (min/max seconds)
	EyeSpawnIntervalMin(0)=999.0f
	EyeSpawnIntervalMin(1)=15.0f
	EyeSpawnIntervalMin(2)=10.0f
	EyeSpawnIntervalMin(3)=8.0f
	EyeSpawnIntervalMin(4)=5.0f
	EyeSpawnIntervalMin(5)=3.0f
	
	EyeSpawnIntervalMax(0)=999.0f
	EyeSpawnIntervalMax(1)=30.0f
	EyeSpawnIntervalMax(2)=20.0f
	EyeSpawnIntervalMax(3)=15.0f
	EyeSpawnIntervalMax(4)=10.0f
	EyeSpawnIntervalMax(5)=6.0f
	
	VignetteIntensity=0.0f
	TargetVignetteIntensity=0.0f
	
	bStaticFlashActive=false
	StaticFlashTimer=0.0f
	LastStaticTime=0.0f
	
	bSubliminalTextActive=false
	SubliminalTextTimer=0.0f
	LastSubliminalTime=0.0f
	
	bScreenDimActive=false
	ScreenDimTimer=0.0f
	
	bColorInvertActive=false
	ColorInvertTimer=0.0f
	
	bScanLineActive=false
	ScanLineY=0.0f
	
	bAmbientPlaying=false
	LastHeartbeatTime=0.0f
	HeartbeatInterval=0.0f
	
	DebugUpdateCount=0
	
	Name="Default__ZTUpgrade_Perk_Haunted_Helper"
}
