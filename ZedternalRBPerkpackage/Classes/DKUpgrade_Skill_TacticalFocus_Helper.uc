// ===================================================================
// DKUpgrade_Skill_TacticalFocus_Helper - Manages Tactical Focus ability state
// ===================================================================
class DKUpgrade_Skill_TacticalFocus_Helper extends Info
	transient;

var KFPawn_Human OwnerPawn;
var DKPlayerController DKPC;
var int MySlotIndex;

var repnotify bool bActive;
var bool bOnCooldown;
var float ActivationTime;
var float CooldownStartTime;

var int Tier;

const DURATION = 10.0f;
const COOLDOWN = 60.0f;

replication
{
	if (bNetDirty)
		bActive;
}

function Initialize(int InTier, KFPawn_Human InOwnerPawn, DKPlayerController InDKPC)
{
	local Texture2D AbilityIcon;
	
	OwnerPawn = InOwnerPawn;
	DKPC = InDKPC;
	
	if (OwnerPawn == None || DKPC == None)
	{
		`log("TacticalFocus_Helper: ERROR - Invalid owner or controller!");
		Destroy();
		return;
	}
	
	SetTier(InTier);
	
	bActive = false;
	bOnCooldown = false;
	
	if (InTier == 1)
		AbilityIcon = class'DKUpgrade_Skill_TacticalFocus'.default.UpgradeIcon[0];
	else
		AbilityIcon = class'DKUpgrade_Skill_TacticalFocus'.default.UpgradeIcon[1];
	
	if (!DKPC.RegisterAbility("Tactical Focus", self, class'DKUpgrade_Skill_TacticalFocus_Helper', AbilityIcon))
	{
		`log("TacticalFocus_Helper: Failed to register with player controller");
		Destroy();
		return;
	}
	
	MySlotIndex = DKPC.FindSlotByHelper(self);
	SetTimer(0.1f, true, nameof(UpdateAbility));
	DKPC.ClientUpdateAbilityHUD(MySlotIndex, false, false, 0.0f, 0.0f);
	
	`log("TacticalFocus_Helper: Initialized at slot" @ MySlotIndex);
}

function SetTier(int InTier)
{
	Tier = Clamp(InTier, 1, 2);
	`log("TacticalFocus_Helper: Tier" @ Tier);
}

function TryActivate()
{
	local float RemainingCooldown;
	
	if (OwnerPawn == None || OwnerPawn.Health <= 0)
	{
		class'DKMessageManager'.static.SendMinor(DKPC, "Tactical Focus: Cannot activate while dead!");
		return;
	}
	
	if (bActive)
	{
		class'DKMessageManager'.static.SendMinor(DKPC, "Tactical Focus: Already active!");
		return;
	}
	
	if (bOnCooldown)
	{
		RemainingCooldown = COOLDOWN - (OwnerPawn.WorldInfo.TimeSeconds - CooldownStartTime);
		class'DKMessageManager'.static.SendMinor(DKPC, "Tactical Focus: On cooldown (" $ int(RemainingCooldown) $ "s remaining)");
		return;
	}
	
	Activate();
}

function Activate()
{
	bActive = true;
	bNetDirty = true;
	ActivationTime = OwnerPawn.WorldInfo.TimeSeconds;
	
	if (Tier == 1)
	{
		class'DKMessageManager'.static.SendImportant(DKPC, "TACTICAL FOCUS ACTIVATED! +40% reload speed for 10 seconds!");
	}
	else
	{
		class'DKMessageManager'.static.SendImportant(DKPC, "TACTICAL FOCUS (DELUXE) ACTIVATED! +60% reload speed for 10 seconds!");
	}
	
	DKPC.ClientUpdateAbilityHUD(MySlotIndex, true, false, DURATION, DURATION);
	`log("TacticalFocus_Helper: ACTIVATED - bActive=" $ bActive);
}

function Deactivate()
{
	bActive = false;
	bNetDirty = true;
	bOnCooldown = true;
	CooldownStartTime = OwnerPawn.WorldInfo.TimeSeconds;
	
	class'DKMessageManager'.static.SendMinor(DKPC, "Tactical Focus ended. Cooldown: 60 seconds.");
	DKPC.ClientUpdateAbilityHUD(MySlotIndex, false, true, COOLDOWN, COOLDOWN);
	`log("TacticalFocus_Helper: DEACTIVATED - bActive=" $ bActive);
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
			class'DKMessageManager'.static.SendImportant(DKPC, "Tactical Focus ready!");
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
	
	Name="Default__DKUpgrade_Skill_TacticalFocus_Helper"
}