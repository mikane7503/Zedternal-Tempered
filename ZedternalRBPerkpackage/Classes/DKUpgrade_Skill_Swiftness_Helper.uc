// ===================================================================
// DKUpgrade_Skill_Swiftness_Helper - Manages Swiftness ability state
// Provides temporary speed boost with active ability system
// ===================================================================
class DKUpgrade_Skill_Swiftness_Helper extends Info
	transient;

var KFPawn_Human OwnerPawn;
var DKPlayerController DKPC;
var int MySlotIndex;

// Replicate bActive to clients so ModifySpeed can read it
var repnotify bool bActive;
var bool bOnCooldown;
var float ActivationTime;
var float CooldownStartTime;

var int Tier;
var float SpeedMultiplier;

const DURATION = 10.0f;
const COOLDOWN = 60.0f;

// Replicate bActive to all clients
replication
{
	if (bNetDirty)
		bActive;
}

// Update ground speed when bActive changes (client-side)
simulated event ReplicatedEvent(name VarName)
{
	if (VarName == 'bActive')
	{
		if (OwnerPawn != None)
		{
			OwnerPawn.UpdateGroundSpeed();
		}
	}
}

function Initialize(int InTier, KFPawn_Human InOwnerPawn, DKPlayerController InDKPC)
{
	local Texture2D AbilityIcon;
	
	OwnerPawn = InOwnerPawn;
	DKPC = InDKPC;
	
	if (OwnerPawn == None || DKPC == None)
	{
		`log("Swiftness_Helper: ERROR - Invalid owner or controller!");
		Destroy();
		return;
	}
	
	SetTier(InTier);
	
	bActive = false;
	bOnCooldown = false;
	
	if (InTier == 1)
		AbilityIcon = class'DKUpgrade_Skill_Swiftness'.default.UpgradeIcon[0];
	else
		AbilityIcon = class'DKUpgrade_Skill_Swiftness'.default.UpgradeIcon[1];
	
	if (!DKPC.RegisterAbility("Swiftness", self, class'DKUpgrade_Skill_Swiftness_Helper', AbilityIcon))
	{
		`log("Swiftness_Helper: Failed to register with player controller");
		Destroy();
		return;
	}
	
	MySlotIndex = DKPC.FindSlotByHelper(self);
	
	SetTimer(0.1f, true, nameof(UpdateAbility));
	
	DKPC.ClientUpdateAbilityHUD(MySlotIndex, false, false, 0.0f, 0.0f);
	
	`log("Swiftness_Helper: Initialized at slot" @ MySlotIndex);
}

function SetTier(int InTier)
{
	Tier = Clamp(InTier, 1, 2);
	
	if (Tier == 1)
	{
		SpeedMultiplier = 1.25f; // 25% speed boost
	}
	else
	{
		SpeedMultiplier = 1.5f; // 50% speed boost
	}
	
	`log("Swiftness_Helper: Tier" @ Tier @ "- Speed multiplier:" @ SpeedMultiplier);
}

function TryActivate()
{
	local float RemainingCooldown;
	
	if (OwnerPawn == None || OwnerPawn.Health <= 0)
	{
		class'DKMessageManager'.static.SendMinor(DKPC, "Swiftness: Cannot activate while dead!");
		return;
	}
	
	if (bActive)
	{
		class'DKMessageManager'.static.SendMinor(DKPC, "Swiftness: Already active!");
		return;
	}
	
	if (bOnCooldown)
	{
		RemainingCooldown = COOLDOWN - (OwnerPawn.WorldInfo.TimeSeconds - CooldownStartTime);
		class'DKMessageManager'.static.SendMinor(
			DKPC, 
			"Swiftness: On cooldown (" $ int(RemainingCooldown) $ "s remaining)"
		);
		return;
	}
	
	Activate();
}

function Activate()
{
	bActive = true;
	bNetDirty = true; // Force replication
	ActivationTime = OwnerPawn.WorldInfo.TimeSeconds;
	
	// Update ground speed immediately after activation
	if (OwnerPawn != None)
	{
		OwnerPawn.UpdateGroundSpeed();
	}
	
	if (Tier == 1)
	{
		class'DKMessageManager'.static.SendImportant(
			DKPC,
			"SWIFTNESS ACTIVATED! +25% movement speed for 10 seconds!"
		);
	}
	else
	{
		class'DKMessageManager'.static.SendImportant(
			DKPC,
			"SWIFTNESS (DELUXE) ACTIVATED! +50% movement speed for 10 seconds!"
		);
	}
	
	DKPC.ClientUpdateAbilityHUD(MySlotIndex, true, false, DURATION, DURATION);
	
	`log("Swiftness_Helper: ACTIVATED - bActive=" $ bActive);
}

function Deactivate()
{
	bActive = false;
	bNetDirty = true; // Force replication
	bOnCooldown = true;
	CooldownStartTime = OwnerPawn.WorldInfo.TimeSeconds;
	
	// Update ground speed immediately after deactivation
	if (OwnerPawn != None)
	{
		OwnerPawn.UpdateGroundSpeed();
	}
	
	class'DKMessageManager'.static.SendMinor(DKPC, "Swiftness effect ended. Cooldown: 60 seconds.");
	
	DKPC.ClientUpdateAbilityHUD(MySlotIndex, false, true, COOLDOWN, COOLDOWN);
	
	`log("Swiftness_Helper: DEACTIVATED - bActive=" $ bActive);
}

function UpdateAbility()
{
	local float CurrentTime, Elapsed, RemainingTime;
	
	if (OwnerPawn == None || OwnerPawn.Health <= 0)
		return;
	
	CurrentTime = OwnerPawn.WorldInfo.TimeSeconds;
	
	if (bActive)
	{
		Elapsed = CurrentTime - ActivationTime;
		
		if (Elapsed >= DURATION)
		{
			Deactivate();
		}
		else
		{
			RemainingTime = DURATION - Elapsed;
			DKPC.ClientUpdateAbilityHUD(MySlotIndex, true, false, RemainingTime, DURATION);
		}
	}
	else if (bOnCooldown)
	{
		Elapsed = CurrentTime - CooldownStartTime;
		
		if (Elapsed >= COOLDOWN)
		{
			bOnCooldown = false;
			class'DKMessageManager'.static.SendImportant(DKPC, "Swiftness ready!");
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
	SpeedMultiplier=1.25f
	MySlotIndex=-1
	
	Name="Default__DKUpgrade_Skill_Swiftness_Helper"
}