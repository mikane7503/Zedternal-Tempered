// ===================================================================
// DKUpgrade_Skill_Wallhack_Helper - Manages Wallhack/Threat Scanner ability
// Tracks ability state for DrawOnHUD to check
// ===================================================================
class DKUpgrade_Skill_Wallhack_Helper extends Info
	transient;

var KFPawn_Human OwnerPawn;
var DKPlayerController DKPC;
var int MySlotIndex;

var repnotify bool bActive;
var bool bOnCooldown;
var float ActivationTime;
var float CooldownStartTime;

var int Tier;
var array<float> Duration;

const COOLDOWN = 45.0f;

replication
{
	if (bNetDirty)
		bActive;
}

simulated event ReplicatedEvent(name VarName)
{
	if (VarName == 'bActive')
	{
		`log("[DK_WALLHACK] ReplicatedEvent: bActive changed to" @ bActive);
	}
}

function Initialize(int InTier, KFPawn_Human InOwnerPawn, DKPlayerController InDKPC)
{
	local Texture2D AbilityIcon;
	
	OwnerPawn = InOwnerPawn;
	DKPC = InDKPC;
	
	if (OwnerPawn == None || DKPC == None)
	{
		`log("[DK_WALLHACK] ERROR - Invalid owner or controller!");
		Destroy();
		return;
	}
	
	SetTier(InTier);
	
	bActive = false;
	bOnCooldown = false;
	
	if (InTier == 1)
		AbilityIcon = class'DKUpgrade_Skill_Wallhack'.default.UpgradeIcon[0];
	else
		AbilityIcon = class'DKUpgrade_Skill_Wallhack'.default.UpgradeIcon[1];
	
	if (!DKPC.RegisterAbility("Threat Scanner", self, class'DKUpgrade_Skill_Wallhack_Helper', AbilityIcon))
	{
		`log("[DK_WALLHACK] Failed to register with player controller");
		Destroy();
		return;
	}
	
	MySlotIndex = DKPC.FindSlotByHelper(self);
	
	SetTimer(0.1f, true, nameof(UpdateAbility));
	
	DKPC.ClientUpdateAbilityHUD(MySlotIndex, false, false, 0.0f, 0.0f);
	
	`log("[DK_WALLHACK] Initialized at slot" @ MySlotIndex @ "- Tier" @ Tier);
}

function SetTier(int InTier)
{
	Tier = Clamp(InTier, 1, 2);
	`log("[DK_WALLHACK] Tier set to" @ Tier @ "- Duration:" @ Duration[Tier - 1] $ "s");
}

function TryActivate()
{
	local float RemainingCooldown;
	
	if (OwnerPawn == None || OwnerPawn.Health <= 0)
	{
		class'DKMessageManager'.static.SendMinor(DKPC, "Threat Scanner: Cannot activate while dead!");
		return;
	}
	
	if (bActive)
	{
		class'DKMessageManager'.static.SendMinor(DKPC, "Threat Scanner: Already active!");
		return;
	}
	
	if (bOnCooldown)
	{
		RemainingCooldown = COOLDOWN - (OwnerPawn.WorldInfo.TimeSeconds - CooldownStartTime);
		class'DKMessageManager'.static.SendMinor(
			DKPC, 
			"Threat Scanner: On cooldown (" $ int(RemainingCooldown) $ "s remaining)"
		);
		return;
	}
	
	Activate();
}

function Activate()
{
	bActive = true;
	bNetDirty = true;
	bForceNetUpdate = true;
	ActivationTime = OwnerPawn.WorldInfo.TimeSeconds;
	
	if (Tier == 1)
	{
		class'DKMessageManager'.static.SendImportant(
			DKPC,
			"THREAT SCANNER ACTIVATED! See enemies through walls for " $ int(Duration[0]) $ " seconds!"
		);
	}
	else
	{
		class'DKMessageManager'.static.SendImportant(
			DKPC,
			"THREAT SCANNER (DELUXE) ACTIVATED! See enemies + health for " $ int(Duration[1]) $ " seconds!"
		);
	}
	
	DKPC.ClientUpdateAbilityHUD(MySlotIndex, true, false, Duration[Tier - 1], Duration[Tier - 1]);
	
	`log("[DK_WALLHACK] ACTIVATED - Tier" @ Tier @ "bActive=" @ bActive);
}

function Deactivate()
{
	bActive = false;
	bNetDirty = true;
	bForceNetUpdate = true;
	bOnCooldown = true;
	CooldownStartTime = OwnerPawn.WorldInfo.TimeSeconds;
	
	class'DKMessageManager'.static.SendMinor(DKPC, "Threat Scanner effect ended. Cooldown: 45 seconds.");
	
	DKPC.ClientUpdateAbilityHUD(MySlotIndex, false, true, COOLDOWN, COOLDOWN);
	
	`log("[DK_WALLHACK] DEACTIVATED");
}

function UpdateAbility()
{
	local float CurrentTime, Elapsed, RemainingTime;
	local float CurrentDuration;
	
	if (OwnerPawn == None || OwnerPawn.Health <= 0)
		return;
	
	CurrentTime = OwnerPawn.WorldInfo.TimeSeconds;
	CurrentDuration = Duration[Tier - 1];
	
	if (bActive)
	{
		Elapsed = CurrentTime - ActivationTime;
		
		if (Elapsed >= CurrentDuration)
		{
			Deactivate();
		}
		else
		{
			RemainingTime = CurrentDuration - Elapsed;
			DKPC.ClientUpdateAbilityHUD(MySlotIndex, true, false, RemainingTime, CurrentDuration);
		}
	}
	else if (bOnCooldown)
	{
		Elapsed = CurrentTime - CooldownStartTime;
		
		if (Elapsed >= COOLDOWN)
		{
			bOnCooldown = false;
			class'DKMessageManager'.static.SendImportant(DKPC, "Threat Scanner ready!");
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
	MySlotIndex=-1
	
	Duration(0)=10.0f
	Duration(1)=15.0f
	
	Name="Default__DKUpgrade_Skill_Wallhack_Helper"
}
