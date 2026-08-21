// ===================================================================
// ZTAchievementReplicator - Per-Player Achievement Replication
// Handles server->client sync for achievement progress and unlocks
// FIXED: Sequential achievement popups to prevent overlap
// UPDATED: Added achievement unlock sound playback
// FIXED: HUD retry logic - if HUD not ready, retries instead of failing
// ===================================================================
class ZTAchievementReplicator extends ReplicationInfo;

var KFPlayerController OwningPC;
var ZTMutator Mutator;

// Track completed achievements for this player
var array<name> CompletedAchievements;

// Track progress for visible achievements
struct AchievementProgress
{
	var name AchievementID;
	var int CurrentProgress;
	var int RequiredProgress;
	var bool bVisible;
	var bool bNotifiedHalfway;
	var bool bNotifiedCompletion;
};
var array<AchievementProgress> ProgressTracking;

// FIXED: Queue for multiple achievement unlocks
struct QueuedAchievement
{
	var string AchievementName;
	var string Description;
	var string UnlockedPerkClass;
	var Texture2D AchievementIcon;
};
var array<QueuedAchievement> AchievementQueue;
var bool bProcessingQueue;

// Delayed perk unlock support (for sequential popups)
var string DelayedPerkClassName;

// Sound effects - loaded on client via DynamicLoadObject
var SoundCue AchievementSound;
var SoundCue PerkUnlockSound;

// HUD retry counter to prevent infinite loops
var int HUDRetryCount;
var const int MAX_HUD_RETRIES;

replication
{
	if (bNetDirty)
		OwningPC;
}

// ===================================================================
// INITIALIZATION
// ===================================================================

simulated event PostBeginPlay()
{
	Super.PostBeginPlay();
	
	// Load sounds on client (use direct loading, not through mutator)
	if (WorldInfo.NetMode != NM_DedicatedServer)
	{
		SetTimer(0.5f, false, 'LoadCustomSounds');
	}
}

simulated function LoadCustomSounds()
{
	`log("ZTAchievementReplicator (CLIENT): Loading custom sounds...");
	
	// Load achievement sound directly
	AchievementSound = SoundCue(DynamicLoadObject(
		"ZedternalRBPerkpackage_Resources.Sounds.Achievement_Complete_Cue",
		class'SoundCue',
		true
	));
	
	if (AchievementSound != None)
	{
		`log("ZTAchievementReplicator (CLIENT): Loaded achievement sound");
	}
	else
	{
		`log("ZTAchievementReplicator (CLIENT): Failed to load achievement sound!");
	}
	
	// Load perk unlock sound directly
	PerkUnlockSound = SoundCue(DynamicLoadObject(
		"ZedternalRBPerkpackage_Resources.Sounds.PerkUnlock_Epic_Cue",
		class'SoundCue',
		true
	));
	
	if (PerkUnlockSound != None)
	{
		`log("ZTAchievementReplicator (CLIENT): Loaded perk unlock sound");
	}
	else
	{
		`log("ZTAchievementReplicator (CLIENT): Failed to load perk unlock sound!");
	}
}

// ===================================================================
// SERVER-SIDE: Update achievement progress
// ===================================================================

function UpdateAchievementProgress(name AchievementID, int Current, int Required, bool bVisible)
{
	local int Idx;
	local AchievementProgress NewProgress;
	local int HalfwayPoint;
	local string AchName;
	
	// Don't update if already completed
	if (CompletedAchievements.Find(AchievementID) != INDEX_NONE)
	{
		return;
	}
	
	Idx = FindProgressIndex(AchievementID);
	
	if (Idx == INDEX_NONE)
	{
		NewProgress.AchievementID = AchievementID;
		NewProgress.CurrentProgress = Current;
		NewProgress.RequiredProgress = Required;
		NewProgress.bVisible = bVisible;
		NewProgress.bNotifiedHalfway = false;
		NewProgress.bNotifiedCompletion = false;
		
		ProgressTracking.AddItem(NewProgress);
		Idx = ProgressTracking.Length - 1;
	}
	else
	{
		ProgressTracking[Idx].CurrentProgress = Current;
		ProgressTracking[Idx].RequiredProgress = Required;
	}
	
	if (bVisible && !ProgressTracking[Idx].bNotifiedHalfway && !ProgressTracking[Idx].bNotifiedCompletion)
	{
		HalfwayPoint = (Required + 1) / 2;
		
		if (Current >= HalfwayPoint && ShouldShowProgressNotification(AchievementID))
		{
			AchName = GetAchievementName(AchievementID);
			ClientShowProgressNotification(AchName, Current, Required);
			ProgressTracking[Idx].bNotifiedHalfway = true;
		}
	}
}

function bool ShouldShowProgressNotification(name AchievementID)
{
	local int ThisIdx, OtherIdx;
	local ZTAchievementData.AchievementDefinition ThisAchievement, OtherAchievement;
	
	if (Mutator == None || Mutator.AchievementData == None)
		return true;
	
	ThisIdx = Mutator.AchievementData.FindAchievementIndex(AchievementID);
	if (ThisIdx == INDEX_NONE)
		return false;
	
	ThisAchievement = Mutator.AchievementData.Achievements[ThisIdx];
	
	for (OtherIdx = 0; OtherIdx < Mutator.AchievementData.Achievements.Length; OtherIdx++)
	{
		OtherAchievement = Mutator.AchievementData.Achievements[OtherIdx];
		
		if (OtherIdx == ThisIdx)
			continue;
		
		if (OtherAchievement.Type == ThisAchievement.Type && OtherAchievement.bVisible)
		{
			if (OtherAchievement.RequiredCount < ThisAchievement.RequiredCount)
			{
				return false;
			}
		}
	}
	
	return true;
}

// ===================================================================
// SERVER-SIDE: Complete an achievement
// ===================================================================

function CompleteAchievement(name AchievementID, string AchievementName, string UnlockedPerkClass, Texture2D AchievementIcon)
{
	local int Idx;
	local string Description;
	
	if (CompletedAchievements.Find(AchievementID) != INDEX_NONE)
		return;
	
	CompletedAchievements.AddItem(AchievementID);
	
	Idx = FindProgressIndex(AchievementID);
	if (Idx != INDEX_NONE)
	{
		ProgressTracking[Idx].bNotifiedCompletion = true;
	}
	
	// Get description server-side
	Description = GetAchievementDescription(AchievementID);
	
	// Send to client to queue
	ClientQueueAchievement(AchievementName, Description, UnlockedPerkClass, AchievementIcon);
	
	if (UnlockedPerkClass != "")
	{
		UnlockPerkFromAchievement(UnlockedPerkClass);
	}
	
	if (Idx != INDEX_NONE)
	{
		ProgressTracking.Remove(Idx, 1);
	}
	
	`log("ZTAchievementReplicator: Achievement completed -" @ AchievementName);
}

function UnlockPerkFromAchievement(string PerkClassName)
{
	local WMPlayerReplicationInfo WMPRI;
	local WMGameReplicationInfo WMGRI;
	local int PerkIdx;
	
	WMPRI = WMPlayerReplicationInfo(OwningPC.PlayerReplicationInfo);
	WMGRI = WMGameReplicationInfo(WorldInfo.GRI);
	
	if (WMPRI == None || WMGRI == None) return;
	
	PerkIdx = Mutator.FindPerkIndex(WMGRI, PerkClassName);
	if (PerkIdx != INDEX_NONE)
	{
		WMPRI.bPerkUpgrade[PerkIdx].bUnlocked = true;
		`log("ZTAchievementReplicator: Unlocked perk" @ PerkClassName @ "from achievement");
	}
}

function int FindProgressIndex(name AchievementID)
{
	local int i;
	
	for (i = 0; i < ProgressTracking.Length; i++)
	{
		if (ProgressTracking[i].AchievementID == AchievementID)
			return i;
	}
	
	return INDEX_NONE;
}

function string GetAchievementDescription(name AchievementID)
{
	local int Idx;
	
	if (Mutator == None || Mutator.AchievementData == None)
		return "";
	
	Idx = Mutator.AchievementData.FindAchievementIndex(AchievementID);
	if (Idx == INDEX_NONE)
		return "";
	
	return Mutator.AchievementData.Achievements[Idx].Description;
}

// ===================================================================
// CLIENT-SIDE: Queue and display achievements
// ===================================================================

reliable client function ClientQueueAchievement(string AchievementName, string Description, string UnlockedPerkClass, Texture2D AchievementIcon)
{
	local QueuedAchievement NewQueued;
	
	`log("ZTAchievementReplicator (CLIENT): Received achievement -" @ AchievementName);
	
	NewQueued.AchievementName = AchievementName;
	NewQueued.Description = Description;
	NewQueued.UnlockedPerkClass = UnlockedPerkClass;
	NewQueued.AchievementIcon = AchievementIcon;
	
	AchievementQueue.AddItem(NewQueued);
	
	if (!bProcessingQueue)
	{
		// Reset retry counter when starting a new queue processing cycle
		HUDRetryCount = 0;
		ClientProcessAchievementQueue();
	}
}

reliable client function ClientProcessAchievementQueue()
{
	if (bProcessingQueue || AchievementQueue.Length == 0)
		return;
	
	bProcessingQueue = true;
	HUDRetryCount = 0;
	ShowNextAchievementInQueue();
}

reliable client function ShowNextAchievementInQueue()
{
	local QueuedAchievement NextAchievement;
	local ZTHudWrapper CustomHUD;
	local Color MessageColor;
	local string UnlockMessage;
	local ZTPlayerController DKPC;
	
	if (OwningPC == None) return;
	
	if (AchievementQueue.Length == 0)
	{
		bProcessingQueue = false;
		HUDRetryCount = 0;
		`log("ZTAchievementReplicator (CLIENT): Queue empty, processing complete");
		return;
	}
	
	// ===================================================================
	// HUD RETRY FIX: Check HUD availability BEFORE dequeuing.
	// In singleplayer the HUD may not be fully initialized when the
	// first achievement fires. Instead of silently failing, retry
	// with a short delay. Give up after MAX_HUD_RETRIES attempts.
	// ===================================================================
	CustomHUD = class'ZTHudWrapper'.static.GetReaperHUD(OwningPC);
	if (CustomHUD == None)
	{
		HUDRetryCount++;
		if (HUDRetryCount <= MAX_HUD_RETRIES)
		{
			`log("ZTAchievementReplicator (CLIENT): HUD not ready, retry" @ HUDRetryCount $ "/" $ MAX_HUD_RETRIES @ "in 1 second");
			SetTimer(1.0f, false, 'ShowNextAchievementInQueue');
			return;
		}
		else
		{
			`log("ZTAchievementReplicator (CLIENT): HUD not available after" @ MAX_HUD_RETRIES @ "retries, skipping achievement popup");
			// Still dequeue so we don't get stuck, but skip display
			AchievementQueue.Remove(0, 1);
			HUDRetryCount = 0;
			SetTimer(1.0f, false, 'ShowNextAchievementInQueue');
			return;
		}
	}
	
	// HUD is available, reset retry counter
	HUDRetryCount = 0;
	
	NextAchievement = AchievementQueue[0];
	AchievementQueue.Remove(0, 1);
	
	`log("ZTAchievementReplicator (CLIENT): Showing achievement" @ NextAchievement.AchievementName);
	
	// ===================================================================
	// PLAY ACHIEVEMENT UNLOCK SOUND
	// ===================================================================
	DKPC = ZTPlayerController(OwningPC);
	if (DKPC != None && AchievementSound != None)
	{
		DKPC.ClientPlayAchievementSound(AchievementSound);
		`log("ZTAchievementReplicator (CLIENT): Called ClientPlayAchievementSound");
	}
	
	// Show HUD notification
	CustomHUD.ShowAchievementUnlockNotification(
		NextAchievement.AchievementName, 
		NextAchievement.Description, 
		NextAchievement.AchievementIcon
	);
	
	if (NextAchievement.UnlockedPerkClass != "")
	{
		DelayedPerkClassName = NextAchievement.UnlockedPerkClass;
		SetTimer(9.0f, false, 'ShowDelayedPerkUnlock');
	}
	
	UnlockMessage = "ACHIEVEMENT UNLOCKED:" @ NextAchievement.AchievementName;
	
	if (NextAchievement.UnlockedPerkClass != "")
	{
		UnlockMessage = UnlockMessage @ "| PERK UNLOCKED!";
	}
	
	MessageColor.R = 255;
	MessageColor.G = 80;
	MessageColor.B = 40;
	MessageColor.A = 255;
	
	CustomHUD.AddNotificationMessage(UnlockMessage, MessageColor, 3);
	
	if (NextAchievement.UnlockedPerkClass != "")
	{
		SetTimer(19.0f, false, 'ShowNextAchievementInQueue');
	}
	else
	{
		SetTimer(9.0f, false, 'ShowNextAchievementInQueue');
	}
}

reliable client function ClientShowProgressNotification(string AchievementName, int Current, int Required)
{
	local ZTHudWrapper CustomHUD;
	local string ProgressMessage;
	local Color MessageColor;
	
	if (OwningPC == None) return;
	
	CustomHUD = class'ZTHudWrapper'.static.GetReaperHUD(OwningPC);
	if (CustomHUD == None) return;
	
	if (AchievementName == "")
	{
		return;
	}
	
	ProgressMessage = AchievementName @ "-" @ Current $ "/" $ Required;
	
	MessageColor.R = 255;
	MessageColor.G = 215;
	MessageColor.B = 0;
	MessageColor.A = 255;
	
	CustomHUD.AddNotificationMessage(ProgressMessage, MessageColor, 2);
}

simulated function ShowDelayedPerkUnlock()
{
	local WMGameReplicationInfo WMGRI;
	local int PerkIdx;
	local Texture2D PerkIcon;
	local string PerkName;
	local ZTHudWrapper CustomHUD;
	local ZTPlayerController DKPC;
	
	if (DelayedPerkClassName == "")
		return;
	
	WMGRI = WMGameReplicationInfo(WorldInfo.GRI);
	if (WMGRI == None)
	{
		`log("ZTAchievementReplicator (CLIENT): WMGRI not available for delayed perk unlock");
		DelayedPerkClassName = "";
		return;
	}
	
	// Find perk directly in WMGRI
	for (PerkIdx = 0; PerkIdx < WMGRI.PerkUpgradesList.Length; PerkIdx++)
	{
		if (string(WMGRI.PerkUpgradesList[PerkIdx].PerkUpgrade.Name) ~= DelayedPerkClassName)
		{
			PerkName = WMGRI.PerkUpgradesList[PerkIdx].PerkUpgrade.default.UpgradeName;
			PerkIcon = WMGRI.PerkUpgradesList[PerkIdx].PerkUpgrade.static.GetUpgradeIcon(0);
			
			// ===================================================================
			// PLAY PERK UNLOCK SOUND (using pre-loaded sound)
			// ===================================================================
			DKPC = ZTPlayerController(OwningPC);
			if (DKPC != None && PerkUnlockSound != None)
			{
				DKPC.ClientPlayPerkUnlockSound(PerkUnlockSound);
			}
			
			// Call HUD directly instead of going through message replicator
			CustomHUD = class'ZTHudWrapper'.static.GetReaperHUD(OwningPC);
			if (CustomHUD != None)
			{
				CustomHUD.ShowPerkUnlockNotification(PerkName, PerkIcon);
				`log("ZTAchievementReplicator (CLIENT): Showed delayed perk unlock popup for" @ PerkName);
			}
			else
			{
				`log("ZTAchievementReplicator (CLIENT): Could not get CustomHUD for perk unlock popup");
			}
			
			DelayedPerkClassName = "";
			return;
		}
	}
	
	`log("ZTAchievementReplicator (CLIENT): Could not find perk" @ DelayedPerkClassName);
	DelayedPerkClassName = "";
}

function string GetAchievementName(name AchievementID)
{
	local int Idx;
	
	if (Mutator == None || Mutator.AchievementData == None)
		return string(AchievementID);
	
	Idx = Mutator.AchievementData.FindAchievementIndex(AchievementID);
	if (Idx == INDEX_NONE)
		return string(AchievementID);
	
	return Mutator.AchievementData.Achievements[Idx].AchievementName;
}

defaultproperties
{
	bOnlyRelevantToOwner=true
	bAlwaysRelevant=false
	RemoteRole=ROLE_SimulatedProxy
	
	MAX_HUD_RETRIES=10
	HUDRetryCount=0
	
	Name="Default__ZTAchievementReplicator"
}
