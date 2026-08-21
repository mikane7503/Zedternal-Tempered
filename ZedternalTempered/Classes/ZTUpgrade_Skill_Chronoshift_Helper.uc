// ===================================================================
// ZTUpgrade_Skill_Chronoshift_Helper - Manages Chronoshift ability state
// Triggers ZED time on demand with active ability system
// FIXED: Routes sound through ZTPlayerController for client replication
// ===================================================================
class ZTUpgrade_Skill_Chronoshift_Helper extends Info transient;

var KFPawn_Human OwnerPawn;
var ZTPlayerController DKPC;
var int MySlotIndex;

var repnotify bool bActive;
var bool bOnCooldown;
var float CooldownStartTime;

var int Tier;
var float ZedTimeDuration;

// Sound effect - native SoundCue (not AkEvent!)
var SoundCue ActivationSound;

const COOLDOWN = 90.0f;

replication
{
	if (bNetDirty)
		bActive;
}

simulated event ReplicatedEvent(name VarName)
{
	if (VarName == 'bActive')
	{
		if (bActive && OwnerPawn != None)
		{
			// Placeholder for activation effects
		}
	}
}

function Initialize(int InTier, KFPawn_Human InOwnerPawn, ZTPlayerController InDKPC)
{
	local Texture2D AbilityIcon;
	local ZTMutator Mutator;
	
	OwnerPawn = InOwnerPawn;
	DKPC = InDKPC;
	
	if (OwnerPawn == None || DKPC == None)
	{
		`log("Chronoshift_Helper: ERROR - Invalid owner or controller!");
		Destroy();
		return;
	}
	
	SetTier(InTier);
	
	bActive = false;
	bOnCooldown = false;
	
	// Load custom activation sound via ZTMutator
	foreach OwnerPawn.WorldInfo.AllActors(class'ZTMutator', Mutator)
	{
		`log("Chronoshift_Helper: Found ZTMutator, requesting sound...");
		ActivationSound = Mutator.GetCustomSound('Chronoshift_Activate');
		if (ActivationSound != None)
		{
			`log("Chronoshift_Helper: ✓ Loaded custom SoundCue:" @ ActivationSound);
		}
		else
		{
			`log("Chronoshift_Helper: ✗ Custom sound returned None!");
		}
		break;
	}
	
	if (Mutator == None)
	{
		`log("Chronoshift_Helper: ERROR - Could not find ZTMutator!");
	}
	
	if (InTier == 1)
		AbilityIcon = class'ZTUpgrade_Skill_Chronoshift'.default.UpgradeIcon[0];
	else
		AbilityIcon = class'ZTUpgrade_Skill_Chronoshift'.default.UpgradeIcon[1];
	
	if (!DKPC.RegisterAbility("Chronoshift", self, class'ZTUpgrade_Skill_Chronoshift_Helper', AbilityIcon))
	{
		`log("Chronoshift_Helper: Failed to register with player controller");
		Destroy();
		return;
	}
	
	MySlotIndex = DKPC.FindSlotByHelper(self);
	
	SetTimer(0.1f, true, nameof(UpdateAbility));
	
	DKPC.ClientUpdateAbilityHUD(MySlotIndex, false, false, 0.0f, 0.0f);
	
	`log("Chronoshift_Helper: Initialized at slot" @ MySlotIndex);
}

function SetTier(int InTier)
{
	Tier = Clamp(InTier, 1, 2);
	
	// Duration is config-driven:
	// [ZedternalTempered.ZTUpgrade_Skill_Chronoshift] ZedTimeDurations
	// (index 0 = standard, 1 = deluxe)
	if (Tier == 1)
		ZedTimeDuration = class'ZTUpgrade_Skill_Chronoshift'.default.ZedTimeDurations[0];
	else
		ZedTimeDuration = class'ZTUpgrade_Skill_Chronoshift'.default.ZedTimeDurations[1];
	
	`log("Chronoshift_Helper: Tier" @ Tier @ "- ZED time duration:" @ ZedTimeDuration);
}

function TryActivate()
{
	local float RemainingCooldown;
	local WMGameInfo_Endless WMGI;
	
	if (OwnerPawn == None || OwnerPawn.Health <= 0)
	{
		class'ZTMessageManager'.static.SendMinor(DKPC, "Chronoshift: Cannot activate while dead!");
		return;
	}
	
	WMGI = WMGameInfo_Endless(OwnerPawn.WorldInfo.Game);
	if (WMGI != None && WMGI.IsZedTimeActive())
	{
		class'ZTMessageManager'.static.SendMinor(DKPC, "Chronoshift: ZED time already active!");
		return;
	}
	
	if (bOnCooldown)
	{
		RemainingCooldown = COOLDOWN - (OwnerPawn.WorldInfo.TimeSeconds - CooldownStartTime);
		class'ZTMessageManager'.static.SendMinor(
			DKPC, 
			"Chronoshift: On cooldown (" $ int(RemainingCooldown) $ "s remaining)"
		);
		return;
	}
	
	Activate();
}

function Activate()
{
	local WMGameInfo_Endless WMGI;
	
	bActive = true;
	bNetDirty = true;
	bOnCooldown = true;
	CooldownStartTime = OwnerPawn.WorldInfo.TimeSeconds;
	
	// ===================================================================
	// PLAY CUSTOM SOUND - Native SoundCue, NO WWISE!
	// Must be replicated to client via PlayerController!
	// ===================================================================
	`log("Chronoshift_Helper: About to play sound...");
	`log("Chronoshift_Helper: ActivationSound =" @ ActivationSound);
	`log("Chronoshift_Helper: DKPC =" @ DKPC);
	`log("Chronoshift_Helper: DKPC != None =" @ (DKPC != None));
	
	if (ActivationSound != None && DKPC != None)
	{
		// Play on client via PlayerController
		`log("Chronoshift_Helper: Calling DKPC.ClientPlayChronoshiftSound...");
		DKPC.ClientPlayChronoshiftSound(ActivationSound);
		`log("Chronoshift_Helper: Sent sound to client via PlayerController");
	}
	else
	{
		if (ActivationSound == None)
			`log("Chronoshift_Helper: ✗ Cannot play - ActivationSound is None!");
		if (DKPC == None)
			`log("Chronoshift_Helper: ✗ Cannot play - DKPC is None!");
	}
	
	// Trigger ZED time
	WMGI = WMGameInfo_Endless(OwnerPawn.WorldInfo.Game);
	if (WMGI != None)
	{
		WMGI.DramaticEvent(1.0f, ZedTimeDuration);
		
		if (Tier == 1)
		{
			class'ZTMessageManager'.static.SendImportant(
				DKPC,
				"CHRONOSHIFT ACTIVATED! Triggered " $ int(ZedTimeDuration) $ " seconds of ZED time!"
			);
		}
		else
		{
			class'ZTMessageManager'.static.SendImportant(
				DKPC,
				"CHRONOSHIFT (DELUXE) ACTIVATED! Triggered " $ int(ZedTimeDuration) $ " seconds of ZED time!"
			);
		}
		
		`log("Chronoshift_Helper: ACTIVATED - Triggered" @ ZedTimeDuration @ "seconds of ZED time");
	}
	else
	{
		`log("Chronoshift_Helper: ERROR - Could not access game info!");
		class'ZTMessageManager'.static.SendMinor(DKPC, "Chronoshift: Activation failed!");
	}
	
	DKPC.ClientUpdateAbilityHUD(MySlotIndex, false, true, COOLDOWN, COOLDOWN);
	
	SetTimer(0.5f, false, nameof(Deactivate));
}

function Deactivate()
{
	bActive = false;
	bNetDirty = true;
}

function UpdateAbility()
{
	local float CurrentTime, Elapsed, RemainingTime;
	
	if (OwnerPawn == None || OwnerPawn.Health <= 0)
		return;
	
	CurrentTime = OwnerPawn.WorldInfo.TimeSeconds;
	
	if (bOnCooldown)
	{
		Elapsed = CurrentTime - CooldownStartTime;
		
		if (Elapsed >= COOLDOWN)
		{
			bOnCooldown = false;
			class'ZTMessageManager'.static.SendImportant(DKPC, "Chronoshift ready!");
			DKPC.ClientUpdateAbilityHUD(MySlotIndex, false, false, 0.0f, 0.0f);
		}
		else
		{
			RemainingTime = COOLDOWN - Elapsed;
			DKPC.ClientUpdateAbilityHUD(MySlotIndex, false, true, RemainingTime, COOLDOWN);
		}
	}
}

function Cleanup()
{
	if (DKPC != None)
	{
		DKPC.UnregisterAbility(self);
	}
	
	ClearTimer(nameof(UpdateAbility));
	ClearTimer(nameof(Deactivate));
}

function Destroyed()
{
	Cleanup();
	Super.Destroyed();
}

defaultproperties
{
	bActive=false
	bOnCooldown=false
	Tier=1
	ZedTimeDuration=5.0f
	MySlotIndex=-1
	
	Name="Default__ZTUpgrade_Skill_Chronoshift_Helper"
}