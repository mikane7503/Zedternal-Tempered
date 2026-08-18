// ===================================================================
// DKUpgrade_Perk_Parasite_Helper - Life Drain Tracking
// Handles: Siphoned enemy tracking, Blood Harvest, Hemorrhage Pulse
// ===================================================================
class DKUpgrade_Perk_Parasite_Helper extends Info
	transient;

var KFPawn_Human Player;
var int UpgradeLevel;

// Siphon tracking
struct SiphonedEnemy
{
	var KFPawn_Monster Monster;
	var float ExpirationTime;
};
var array<SiphonedEnemy> SiphonedEnemies;
var float LastSiphonCheckTime;
var float SiphonCheckInterval;

// Blood Harvest tracking (Level 20)
var int BloodHarvestProgress;
var bool bHemorrhagePulseReady;
var bool bHemorrhagePulseUsedThisWave;

// Double Life Steal buff
var bool bDoubleLifeStealActive;
var float DoubleLifeStealEndTime;

// Recursion guard: prevents siphon/pulse damage from re-triggering life steal
var bool bIsSiphonDamage;

// Wave tracking for auto-reset
var int LastWaveNum;

// Sound effects
var SoundCue HemorrhagePulseSound;
var SoundCue BloodHarvestReadySound;

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
		`log("Parasite Helper: Invalid owner, destroying");
		Destroy();
		return;
	}
	
	`log("Parasite Helper: Initialized for" @ Player.PlayerReplicationInfo.PlayerName);
}

function Initialize(KFPawn_Human NewPlayer, int NewUpgradeLevel)
{
	local DKMutator Mutator;
	
	Player = NewPlayer;
	UpgradeLevel = NewUpgradeLevel;
	
	// Initialize siphon tracking
	SiphonedEnemies.Length = 0;
	LastSiphonCheckTime = 0.0f;
	SiphonCheckInterval = 0.2f; // Check 5 times per second
	
	// Initialize Blood Harvest
	BloodHarvestProgress = 0;
	bHemorrhagePulseReady = false;
	bHemorrhagePulseUsedThisWave = false;
	
	// Initialize double life steal buff
	bDoubleLifeStealActive = false;
	DoubleLifeStealEndTime = 0.0f;
	
	// Recursion guard off
	bIsSiphonDamage = false;
	
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
		`log("Parasite Helper: Found DKMutator, requesting sounds...");
		
		HemorrhagePulseSound = Mutator.GetCustomSound('Parasite_Hemorrhage_Pulse');
		BloodHarvestReadySound = Mutator.GetCustomSound('Parasite_BloodHarvest_Ready');
		
		if (HemorrhagePulseSound != None)
			`log("Parasite Helper: Loaded Hemorrhage Pulse SoundCue");
		else
			`log("Parasite Helper: Hemorrhage Pulse sound returned None!");
		
		break;
	}
	
	`log("Parasite Helper: Initialized with upgrade level" @ UpgradeLevel);
}

function SetUpgradeLevel(int NewLevel)
{
	UpgradeLevel = NewLevel;
	`log("Parasite Helper: Upgrade level set to" @ UpgradeLevel);
}

// ===================================================================
// Main Tick - Update Siphon Tracking and Buffs
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
	
	// Check for wave change and reset Blood Harvest
	if (Player.WorldInfo.GRI != None)
	{
		CurrentWaveNum = KFGameReplicationInfo(Player.WorldInfo.GRI).WaveNum;
		if (CurrentWaveNum != LastWaveNum)
		{
			ResetBloodHarvest();
			LastWaveNum = CurrentWaveNum;
		}
	}
	
	// Update siphoned enemy tracking periodically
	if (CurrentTime - LastSiphonCheckTime >= SiphonCheckInterval)
	{
		UpdateSiphonedEnemies();
		LastSiphonCheckTime = CurrentTime;
	}
	
	// Check double life steal buff timer
	if (bDoubleLifeStealActive && CurrentTime >= DoubleLifeStealEndTime)
	{
		EndDoubleLifeSteal();
	}
	
	// Update HUD
	UpdateHUD();
}

// ===================================================================
// Siphon Application and Tracking
// ===================================================================
function ApplySiphon(KFPawn_Monster Monster)
{
	local int i;
	local float CurrentTime;
	local SiphonedEnemy NewEntry;
	local bool bFound;
	
	if (Monster == None || !Monster.IsAliveAndWell())
		return;
	
	CurrentTime = Player.WorldInfo.TimeSeconds;
	bFound = false;
	
	// Check if already siphoning this enemy
	for (i = 0; i < SiphonedEnemies.Length; i++)
	{
		if (SiphonedEnemies[i].Monster == Monster)
		{
			// Refresh duration
			SiphonedEnemies[i].ExpirationTime = CurrentTime + class'DKUpgrade_Perk_Parasite'.default.SiphonDuration;
			bFound = true;
			break;
		}
	}
	
	// Add new siphon if not found and under cap
	if (!bFound && SiphonedEnemies.Length < class'DKUpgrade_Perk_Parasite'.default.MaxSiphonedEnemies)
	{
		NewEntry.Monster = Monster;
		NewEntry.ExpirationTime = CurrentTime + class'DKUpgrade_Perk_Parasite'.default.SiphonDuration;
		SiphonedEnemies.AddItem(NewEntry);
		
		// Apply bleeding DoT to the monster
		Monster.ApplyDamageOverTime(
			class'DKUpgrade_Perk_Parasite'.default.SiphonDamagePerTick,
			Player.Controller,
			class'DKDT_Siphon'
		);
	}
}

function UpdateSiphonedEnemies()
{
	local int i;
	local float CurrentTime;
	
	if (Player == None)
		return;
	
	CurrentTime = Player.WorldInfo.TimeSeconds;
	
	// Remove expired or dead siphons
	for (i = SiphonedEnemies.Length - 1; i >= 0; i--)
	{
		if (SiphonedEnemies[i].Monster == None || 
			!SiphonedEnemies[i].Monster.IsAliveAndWell() ||
			CurrentTime >= SiphonedEnemies[i].ExpirationTime)
		{
			SiphonedEnemies.Remove(i, 1);
		}
	}
}

function int GetSiphonedEnemyCount()
{
	return SiphonedEnemies.Length;
}

function int GetMaxSiphons()
{
	return class'DKUpgrade_Perk_Parasite'.default.MaxSiphonedEnemies;
}

function bool IsSiphoned(KFPawn_Monster Monster)
{
	local int i;

	if (Monster == None)
		return false;

	for (i = 0; i < SiphonedEnemies.Length; i++)
	{
		if (SiphonedEnemies[i].Monster == Monster)
			return true;
	}

	return false;
}

function GetSiphonedEnemies(out array<KFPawn_Monster> OutList)
{
	local int i;

	OutList.Length = 0;
	for (i = 0; i < SiphonedEnemies.Length; i++)
	{
		if (SiphonedEnemies[i].Monster != None && SiphonedEnemies[i].Monster.IsAliveAndWell())
			OutList.AddItem(SiphonedEnemies[i].Monster);
	}
}

function RefreshAllSiphons()
{
	local int i;
	local float CurrentTime;

	if (Player == None)
		return;

	CurrentTime = Player.WorldInfo.TimeSeconds;
	for (i = 0; i < SiphonedEnemies.Length; i++)
	{
		SiphonedEnemies[i].ExpirationTime = CurrentTime + class'DKUpgrade_Perk_Parasite'.default.SiphonDuration;
	}
}

function int ConsumeAllSiphons()
{
	local int Count;

	Count = SiphonedEnemies.Length;
	SiphonedEnemies.Length = 0;
	return Count;
}

function ApplySiphonToTarget(KFPawn_Monster Monster)
{
	ApplySiphon(Monster);
}

function bool IsDoubleLifeStealActive()
{
	return bDoubleLifeStealActive;
}

// ===================================================================
// Level 10: Healing Damages Siphoned Enemies
// GUARD: bIsSiphonDamage prevents TakeDamage -> ModifyDamageGiven
//        from re-triggering life steal -> HealingDamage -> here again
// ===================================================================
function DamageSiphonedEnemies(int HealAmount)
{
	local int i;
	local int DamagePerEnemy;
	
	if (UpgradeLevel < class'DKConfig_Capstone'.default.Capstone_Rank1Level)
		return;
	
	if (SiphonedEnemies.Length == 0)
		return;
	
	// Prevent recursion: if we're already in siphon damage, bail out
	if (bIsSiphonDamage)
		return;
	
	// 50% of healing dealt as damage to each siphoned enemy
	DamagePerEnemy = Round(float(HealAmount) * class'DKUpgrade_Perk_Parasite'.default.HealingDamageRatio);
	
	if (DamagePerEnemy <= 0)
		return;
	
	// SET GUARD: any TakeDamage calls below will re-enter ModifyDamageGiven,
	// which checks this flag to skip life steal, breaking the loop
	bIsSiphonDamage = true;
	
	for (i = 0; i < SiphonedEnemies.Length; i++)
	{
		if (SiphonedEnemies[i].Monster != None && SiphonedEnemies[i].Monster.IsAliveAndWell())
		{
			SiphonedEnemies[i].Monster.TakeDamage(
				DamagePerEnemy,
				Player.Controller,
				SiphonedEnemies[i].Monster.Location,
				vect(0,0,0),
				class'DKDT_Siphon'
			);
		}
	}
	
	// CLEAR GUARD
	bIsSiphonDamage = false;
	
	`log("Parasite: Healing damaged" @ SiphonedEnemies.Length @ "siphoned enemies for" @ DamagePerEnemy @ "each");
}

// ===================================================================
// Level 20: Blood Harvest Kill Tracking
// ===================================================================
function OnKillForBloodHarvest(KFPawn_Monster KilledMonster)
{
	local KFPlayerController KFPC;
	
	if (Player == None || Player.Role != ROLE_Authority)
		return;
	
	if (UpgradeLevel < class'DKConfig_Capstone'.default.Capstone_Rank2Level)
		return;
	
	// Don't track if pulse already used this wave
	if (bHemorrhagePulseUsedThisWave)
		return;
	
	// Only count kills when enough enemies are siphoned. Config-driven:
	// [ZedternalRBPerkpackage.DKUpgrade_Perk_Parasite] MinSiphonedForHarvest
	if (SiphonedEnemies.Length < class'DKUpgrade_Perk_Parasite'.default.MinSiphonedForHarvest)
		return;
	
	BloodHarvestProgress++;
	
	// Check if ready to trigger
	if (BloodHarvestProgress >= class'DKUpgrade_Perk_Parasite'.default.BloodHarvestKillsRequired && !bHemorrhagePulseReady)
	{
		bHemorrhagePulseReady = true;
		
		// Play ready sound
		PlayReadySound();
		
		// Send notification
		KFPC = KFPlayerController(Player.Controller);
		if (KFPC != None)
		{
			class'DKMessageManager'.static.SendCritical(
				KFPC,
				"BLOOD HARVEST COMPLETE! Hemorrhage Pulse ready - keep attacking!"
			);
		}
	}
	
	`log("Parasite: Blood Harvest progress -" @ BloodHarvestProgress @ "/" @ class'DKUpgrade_Perk_Parasite'.default.BloodHarvestKillsRequired);
}

// ===================================================================
// Level 20: Hemorrhage Pulse - Triggered on Next Kill When Ready
// GUARD: bIsSiphonDamage prevents TakeDamage and HealDamage here
//        from re-entering the siphon/life-steal feedback loop
// ===================================================================
function TriggerHemorrhagePulse()
{
	local KFPawn_Monster Monster;
	local KFPawn_Human Teammate;
	local KFPlayerController KFPC;
	local DKPlayerController DKPC;
	local float DistSq, RadiusSq;
	local vector PlayerLoc;
	local int TotalDamage, SelfHeal, TeamHeal;
	
	if (Player == None || Player.Role != ROLE_Authority)
		return;
	
	if (!bHemorrhagePulseReady)
		return;
	
	bHemorrhagePulseReady = false;
	bHemorrhagePulseUsedThisWave = true;
	BloodHarvestProgress = 0;
	
	PlayerLoc = Player.Location;
	RadiusSq = class'DKUpgrade_Perk_Parasite'.default.HemorrhagePulseRadius ** 2;
	TotalDamage = 0;
	
	// Play pulse sound to all nearby players
	foreach Player.WorldInfo.AllPawns(class'KFPawn_Human', Teammate)
	{
		if (Teammate.IsAliveAndWell())
		{
			DKPC = DKPlayerController(Teammate.Controller);
			if (DKPC != None && HemorrhagePulseSound != None)
			{
				DKPC.ClientPlaySound(HemorrhagePulseSound);
			}
		}
	}
	
	// SET GUARD: pulse damage should not trigger life steal or siphon feedback
	bIsSiphonDamage = true;
	
	// Damage all enemies in radius
	foreach Player.WorldInfo.AllPawns(class'KFPawn_Monster', Monster)
	{
		if (Monster != None && Monster.IsAliveAndWell())
		{
			DistSq = VSizeSq(Monster.Location - PlayerLoc);
			if (DistSq <= RadiusSq)
			{
				Monster.TakeDamage(
					class'DKUpgrade_Perk_Parasite'.default.HemorrhagePulseDamage,
					Player.Controller,
					Monster.Location,
					vect(0,0,0),
					class'DKDT_Siphon'
				);
				TotalDamage += class'DKUpgrade_Perk_Parasite'.default.HemorrhagePulseDamage;
			}
		}
	}
	
	// CLEAR GUARD before the intentional heals below - these are direct
	// one-shot heals, not life steal, and should NOT feed back into siphon
	// damage. However we still keep the guard active during HealDamage
	// because HealDamage -> HealingDamage -> DamageSiphonedEnemies would
	// loop. So we clear AFTER the heals instead.
	
	// Heal self for a configured fraction of damage dealt
	// ([ZedternalRBPerkpackage.DKUpgrade_Perk_Parasite] HemorrhageHealPercent)
	SelfHeal = Round(float(TotalDamage) * class'DKUpgrade_Perk_Parasite'.default.HemorrhageHealPercent);
	if (SelfHeal > 0)
	{
		Player.HealDamage(SelfHeal, Player.Controller, class'KFDT_Healing');
	}
	
	// Heal nearby teammates for a configured fraction of damage dealt
	// ([ZedternalRBPerkpackage.DKUpgrade_Perk_Parasite] HemorrhageTeamHealPercent)
	TeamHeal = Round(float(TotalDamage) * class'DKUpgrade_Perk_Parasite'.default.HemorrhageTeamHealPercent);
	if (TeamHeal > 0)
	{
		foreach Player.WorldInfo.AllPawns(class'KFPawn_Human', Teammate)
		{
			if (Teammate != Player && Teammate.IsAliveAndWell())
			{
				DistSq = VSizeSq(Teammate.Location - PlayerLoc);
				if (DistSq <= RadiusSq)
				{
					Teammate.HealDamage(TeamHeal, KFPlayerController(Player.Controller), class'KFDT_Healing');
				}
			}
		}
	}
	
	// CLEAR GUARD: pulse is complete, normal life steal can resume
	bIsSiphonDamage = false;
	
	// Activate double life steal buff
	bDoubleLifeStealActive = true;
	DoubleLifeStealEndTime = Player.WorldInfo.TimeSeconds + class'DKUpgrade_Perk_Parasite'.default.DoubleLifeStealDuration;
	
	// Send notification
	KFPC = KFPlayerController(Player.Controller);
	if (KFPC != None)
	{
		class'DKMessageManager'.static.SendCritical(
			KFPC,
			"HEMORRHAGE PULSE! Healed " $ SelfHeal $ " HP! Double life steal for 8 seconds!"
		);
	}
	
	`log("Parasite: Hemorrhage Pulse TRIGGERED! Damage:" @ TotalDamage @ "Self Heal:" @ SelfHeal @ "Team Heal:" @ TeamHeal);
}

function EndDoubleLifeSteal()
{
	bDoubleLifeStealActive = false;
	
	class'DKMessageManager'.static.SendImportant(
		KFPlayerController(Player.Controller),
		"Double life steal ended - keep draining!"
	);
	
	`log("Parasite: Double life steal buff ended");
}

function ResetBloodHarvest()
{
	BloodHarvestProgress = 0;
	bHemorrhagePulseReady = false;
	bHemorrhagePulseUsedThisWave = false;
	
	`log("Parasite: Blood Harvest reset for new wave");
}

function PlayReadySound()
{
	local DKPlayerController DKPC;
	
	DKPC = DKPlayerController(Player.Controller);
	if (DKPC != None && BloodHarvestReadySound != None)
	{
		DKPC.ClientPlaySound(BloodHarvestReadySound);
	}
}

// ===================================================================
// HUD Updates
// ===================================================================
function UpdateHUD()
{
	local float RemainingTime;
	
	// Calculate remaining double life steal time
	if (bDoubleLifeStealActive && Player != None)
	{
		RemainingTime = DoubleLifeStealEndTime - Player.WorldInfo.TimeSeconds;
		RemainingTime = FMax(0.0f, RemainingTime);
	}
	else
	{
		RemainingTime = 0.0f;
	}
	
	ClientUpdateHUD(SiphonedEnemies.Length, BloodHarvestProgress, bDoubleLifeStealActive, RemainingTime, bHemorrhagePulseUsedThisWave, UpgradeLevel);
}

reliable client function ClientUpdateHUD(int SiphonedCount, int HarvestProgress, bool bDoubleDrain, float DrainTimeRemaining, bool bPulseUsed, int CurrentUpgradeLevel)
{
	local DKPlayerController DKPC;
	local DKHudWrapper ParasiteHUD;
	
	// Debug counter - log every 50 calls to avoid spam
	DebugUpdateCount++;
	if (DebugUpdateCount % 50 == 1)
	{
		`log("Parasite Helper CLIENT: ClientUpdateHUD called (call #" $ DebugUpdateCount $ ")");
		`log("Parasite Helper CLIENT: Siphoned=" $ SiphonedCount @ "Harvest=" $ HarvestProgress @ "DoubleDrain=" $ bDoubleDrain @ "TimeLeft=" $ DrainTimeRemaining @ "Level=" $ CurrentUpgradeLevel);
	}
	
	// Get local player controller
	DKPC = DKPlayerController(GetALocalPlayerController());
	if (DKPC == None)
	{
		if (DebugUpdateCount % 50 == 1)
			`log("Parasite Helper CLIENT: GetALocalPlayerController returned None or not DKPlayerController!");
		return;
	}
	
	if (DebugUpdateCount % 50 == 1)
		`log("Parasite Helper CLIENT: Got DKPlayerController:" @ DKPC);
	
	// Get HUD using GetReaperHUD static function
	ParasiteHUD = class'DKHudWrapper'.static.GetReaperHUD(DKPC);
	if (ParasiteHUD == None)
	{
		if (DebugUpdateCount % 50 == 1)
			`log("Parasite Helper CLIENT: GetReaperHUD returned None!");
		return;
	}
	
	if (DebugUpdateCount % 50 == 1)
		`log("Parasite Helper CLIENT: Got ParasiteHUD:" @ ParasiteHUD);
	
	// Call UpdateParasiteTracking
	ParasiteHUD.UpdateParasiteTracking(SiphonedCount, HarvestProgress, bDoubleDrain, DrainTimeRemaining, CurrentUpgradeLevel, bPulseUsed);
	
	if (DebugUpdateCount % 50 == 1)
		`log("Parasite Helper CLIENT: Called UpdateParasiteTracking successfully!");
}

// ===================================================================
// Cleanup
// ===================================================================
function Cleanup()
{
	SiphonedEnemies.Length = 0;
	bIsSiphonDamage = false;
	`log("Parasite Helper: Cleaned up - Final stats: Siphoned=" @ SiphonedEnemies.Length @ "HarvestProgress=" @ BloodHarvestProgress);
}

// ===================================================================
// Default Properties
// ===================================================================
defaultproperties
{
	LastSiphonCheckTime=0.0f
	SiphonCheckInterval=0.2f
	
	BloodHarvestProgress=0
	bHemorrhagePulseReady=false
	bHemorrhagePulseUsedThisWave=false
	
	bDoubleLifeStealActive=false
	DoubleLifeStealEndTime=0.0f
	
	bIsSiphonDamage=false
	
	LastWaveNum=0
	
	DebugUpdateCount=0
	
	Name="Default__DKUpgrade_Perk_Parasite_Helper"
}
