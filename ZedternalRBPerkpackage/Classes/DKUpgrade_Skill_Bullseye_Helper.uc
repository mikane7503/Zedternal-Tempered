// ===================================================================
// DKUpgrade_Skill_Bullseye_Helper - Manages Bullseye ability state
// Provides temporary recoil and spread reduction
// ===================================================================
class DKUpgrade_Skill_Bullseye_Helper extends Info
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

const COOLDOWN = 60.0f;

replication
{
	if (bNetDirty)
		bActive;
}

simulated event ReplicatedEvent(name VarName)
{
	if (VarName == 'bActive')
	{
		`log("[DK_BULLSEYE] ReplicatedEvent: bActive changed to" @ bActive);
	}
}

function Initialize(int InTier, KFPawn_Human InOwnerPawn, DKPlayerController InDKPC)
{
	local Texture2D AbilityIcon;
	
	OwnerPawn = InOwnerPawn;
	DKPC = InDKPC;
	
	if (OwnerPawn == None || DKPC == None)
	{
		`log("[DK_BULLSEYE] ERROR - Invalid owner or controller!");
		Destroy();
		return;
	}
	
	SetTier(InTier);
	
	bActive = false;
	bOnCooldown = false;
	
	if (InTier == 1)
		AbilityIcon = class'DKUpgrade_Skill_Bullseye'.default.UpgradeIcon[0];
	else
		AbilityIcon = class'DKUpgrade_Skill_Bullseye'.default.UpgradeIcon[1];
	
	if (!DKPC.RegisterAbility("Bullseye", self, class'DKUpgrade_Skill_Bullseye_Helper', AbilityIcon))
	{
		`log("[DK_BULLSEYE] Failed to register with player controller");
		Destroy();
		return;
	}
	
	MySlotIndex = DKPC.FindSlotByHelper(self);
	
	SetTimer(0.1f, true, nameof(UpdateAbility));
	
	DKPC.ClientUpdateAbilityHUD(MySlotIndex, false, false, 0.0f, 0.0f);
	
	`log("[DK_BULLSEYE] Initialized at slot" @ MySlotIndex @ "- Tier" @ Tier);
}

function SetTier(int InTier)
{
	Tier = Clamp(InTier, 1, 2);
	`log("[DK_BULLSEYE] Tier set to" @ Tier @ "- Duration:" @ Duration[Tier - 1] $ "s");
}

function TryActivate()
{
	local float RemainingCooldown;
	
	if (OwnerPawn == None || OwnerPawn.Health <= 0)
	{
		class'DKMessageManager'.static.SendMinor(DKPC, "Bullseye: Cannot activate while dead!");
		return;
	}
	
	if (bActive)
	{
		class'DKMessageManager'.static.SendMinor(DKPC, "Bullseye: Already active!");
		return;
	}
	
	if (bOnCooldown)
	{
		RemainingCooldown = COOLDOWN - (OwnerPawn.WorldInfo.TimeSeconds - CooldownStartTime);
		class'DKMessageManager'.static.SendMinor(
			DKPC, 
			"Bullseye: On cooldown (" $ int(RemainingCooldown) $ "s remaining)"
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
			"BULLSEYE ACTIVATED! 50% reduced recoil/spread for " $ int(Duration[0]) $ " seconds!"
		);
	}
	else
	{
		class'DKMessageManager'.static.SendImportant(
			DKPC,
			"BULLSEYE (DELUXE) ACTIVATED! 75% reduced recoil/spread for " $ int(Duration[1]) $ " seconds!"
		);
	}
	
	DKPC.ClientUpdateAbilityHUD(MySlotIndex, true, false, Duration[Tier - 1], Duration[Tier - 1]);
	
	`log("[DK_BULLSEYE] ACTIVATED - Tier" @ Tier @ "bActive=" @ bActive);
}

function Deactivate()
{
	bActive = false;
	bNetDirty = true;
	bForceNetUpdate = true;
	bOnCooldown = true;
	CooldownStartTime = OwnerPawn.WorldInfo.TimeSeconds;
	
	class'DKMessageManager'.static.SendMinor(DKPC, "Bullseye effect ended. Cooldown: 60 seconds.");
	
	DKPC.ClientUpdateAbilityHUD(MySlotIndex, false, true, COOLDOWN, COOLDOWN);
	
	`log("[DK_BULLSEYE] DEACTIVATED");
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
			class'DKMessageManager'.static.SendImportant(DKPC, "Bullseye ready!");
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
	
	Duration(0)=8.0f
	Duration(1)=12.0f
	
	Name="Default__DKUpgrade_Skill_Bullseye_Helper"
}
