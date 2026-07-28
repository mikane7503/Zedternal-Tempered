// ===================================================================
// DKUpgrade_Perk_Haunted_Helper - The Watcher System Controller
// Handles: Activation checking, kill tracking, escalation, HUD sync
// ===================================================================
class DKUpgrade_Perk_Haunted_Helper extends Info
	transient;

// ===================================================================
// Core State
// ===================================================================
var KFPawn_Human Player;
var int UpgradeLevel;

// Watcher activation state
var bool bWatcherActive;
var bool bActivationChecked;

// Kill tracking for escalation
var int TotalKills;
var int CurrentStage;

// Timing for periodic checks
var float LastActivationCheckTime;
var float ActivationCheckInterval;

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
	local DKMutator Mutator;
	
	Player = NewPlayer;
	UpgradeLevel = NewUpgradeLevel;
	
	// Initialize state
	bWatcherActive = false;
	bActivationChecked = false;
	TotalKills = 0;
	CurrentStage = 0;
	
	LastActivationCheckTime = 0.0f;
	ActivationCheckInterval = 1.0f;
	
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
	
	// Load sounds via DKMutator
	foreach Player.WorldInfo.AllActors(class'DKMutator', Mutator)
	{
		`log("Haunted Helper: Found DKMutator, requesting sounds...");
		
		WatcherAmbientSound = Mutator.GetCustomSound('Watcher_Ambient');
		WatcherEyeAppearSound = Mutator.GetCustomSound('Watcher_Eye_Appear');
		WatcherEyeBlinkSound = Mutator.GetCustomSound('Watcher_Eye_Blink');
		WatcherWhisperSound = Mutator.GetCustomSound('Watcher_Whisper');
		WatcherStaticSound = Mutator.GetCustomSound('Watcher_Static');
		WatcherHeartbeatSound = Mutator.GetCustomSound('Watcher_Heartbeat');
		WatcherEscalateSound = Mutator.GetCustomSound('Watcher_Escalate');
		
		if (WatcherAmbientSound != None)
			`log("Haunted Helper: ✓ Loaded Watcher_Ambient");
		if (WatcherEyeAppearSound != None)
			`log("Haunted Helper: ✓ Loaded Watcher_Eye_Appear");
		if (WatcherEscalateSound != None)
			`log("Haunted Helper: ✓ Loaded Watcher_Escalate");
			
		break;
	}
	
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
	
	// Check activation conditions periodically
	if (!bActivationChecked && CurrentTime - LastActivationCheckTime >= ActivationCheckInterval)
	{
		CheckActivationConditions();
		LastActivationCheckTime = CurrentTime;
	}
	
	// If Watcher is active, run the horror systems
	if (bWatcherActive)
	{
		UpdateEscalation();
		UpdateEyes(DeltaTime);
		UpdateVisualEffects(DeltaTime);
		UpdateSounds(DeltaTime);
		UpdateHUD();
	}
}

// ===================================================================
// Activation Check
// ===================================================================
function CheckActivationConditions()
{
	local WMPlayerReplicationInfo WMPRI;
	local WMGameReplicationInfo WMGRI;
	local int i, PerkIndex;
	local bool bHasActivationPerk;
	local string ActivationPerkName;
	
	if (Player == None)
		return;
	
	WMPRI = WMPlayerReplicationInfo(Player.PlayerReplicationInfo);
	WMGRI = WMGameReplicationInfo(Player.WorldInfo.GRI);
	
	if (WMPRI == None || WMGRI == None)
		return;
	
	// Check if player has the activation perk at required level
	// Activation perk: Support Level 5
	ActivationPerkName = class'DKUpgrade_Perk_Haunted'.default.ActivationPerkName;
	bHasActivationPerk = false;
	
	for (i = 0; i < WMGRI.PerkUpgradesList.Length; i++)
	{
		if (InStr(string(WMGRI.PerkUpgradesList[i].PerkUpgrade), ActivationPerkName) != INDEX_NONE)
		{
			PerkIndex = i;
			if (WMPRI.bPerkUpgrade[PerkIndex].level >= class'DKUpgrade_Perk_Haunted'.default.ActivationPerkLevel)
			{
				bHasActivationPerk = true;
				break;
			}
		}
	}
	
	if (bHasActivationPerk)
	{
		ActivateWatcher();
		bActivationChecked = true;
	}
}

function ActivateWatcher()
{
	local DKPlayerController DKPC;
	
	if (bWatcherActive)
		return;
	
	bWatcherActive = true;
	CurrentStage = 1;
	TotalKills = 0;
	
	// Set initial vignette for stage 1
	TargetVignetteIntensity = 0.05f;
	
	// Start ambient sound
	DKPC = DKPlayerController(Player.Controller);
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
	NewStage = (TotalKills / class'DKUpgrade_Perk_Haunted'.default.KillsPerStage) + 1;
	NewStage = Min(NewStage, class'DKUpgrade_Perk_Haunted'.default.MaxStage);
	
	// Check for stage advancement
	if (NewStage > CurrentStage)
	{
		AdvanceStage(NewStage);
	}
}

function AdvanceStage(int NewStage)
{
	local DKPlayerController DKPC;
	
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
	DKPC = DKPlayerController(Player.Controller);
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
	local DKPlayerController DKPC;
	
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
			DKPC = DKPlayerController(Player.Controller);
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
	local DKPlayerController DKPC;
	
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
	DKPC = DKPlayerController(Player.Controller);
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
	local DKPlayerController DKPC;
	
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
		
		DKPC = DKPlayerController(Player.Controller);
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
		
		DKPC = DKPlayerController(Player.Controller);
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
	local DKPlayerController DKPC;
	
	if (HeartbeatInterval <= 0.0f)
		return;
	
	CurrentTime = Player.WorldInfo.TimeSeconds;
	
	if (CurrentTime - LastHeartbeatTime >= HeartbeatInterval)
	{
		DKPC = DKPlayerController(Player.Controller);
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
	
	DebugUpdateCount++;
	
	// Send all state to client for rendering
	ClientUpdateWatcherHUD(
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
	ClientSetWatcherEyeCount(ActiveEyes.Length);
	
	// Send each eye individually to avoid struct type mismatch
	for (i = 0; i < ActiveEyes.Length; i++)
	{
		ClientUpdateWatcherEye(
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
	local DKPlayerController DKPC;
	local DKHudWrapper WatcherHUD;
	
	DKPC = DKPlayerController(GetALocalPlayerController());
	if (DKPC == None)
		return;
	
	WatcherHUD = class'DKHudWrapper'.static.GetReaperHUD(DKPC);
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
	local DKPlayerController DKPC;
	local DKHudWrapper WatcherHUD;
	
	DKPC = DKPlayerController(GetALocalPlayerController());
	if (DKPC == None)
		return;
	
	WatcherHUD = class'DKHudWrapper'.static.GetReaperHUD(DKPC);
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
	local DKPlayerController DKPC;
	local DKHudWrapper WatcherHUD;
	
	DKPC = DKPlayerController(GetALocalPlayerController());
	if (DKPC == None)
		return;
	
	WatcherHUD = class'DKHudWrapper'.static.GetReaperHUD(DKPC);
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
	bActivationChecked=false
	TotalKills=0
	CurrentStage=0
	
	LastActivationCheckTime=0.0f
	ActivationCheckInterval=1.0f
	
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
	
	Name="Default__DKUpgrade_Perk_Haunted_Helper"
}
