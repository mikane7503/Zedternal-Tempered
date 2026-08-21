// ===================================================================
// ZTUpgrade_Skill_PyromaniacRush_Helper - Manages Pyromaniac Rush ability state
// ===================================================================
class ZTUpgrade_Skill_PyromaniacRush_Helper extends Info transient;

var KFPawn_Human OwnerPawn;
var ZTPlayerController DKPC;
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

function Initialize(int InTier, KFPawn_Human InOwnerPawn, ZTPlayerController InDKPC)
{
	local Texture2D AbilityIcon;
	
	OwnerPawn = InOwnerPawn;
	DKPC = InDKPC;
	
	if (OwnerPawn == None || DKPC == None)
	{
		`log("PyromaniacRush_Helper: ERROR - Invalid owner or controller!");
		Destroy();
		return;
	}
	
	SetTier(InTier);
	
	bActive = false;
	bOnCooldown = false;
	
	if (InTier == 1)
		AbilityIcon = class'ZTUpgrade_Skill_PyromaniacRush'.default.UpgradeIcon[0];
	else
		AbilityIcon = class'ZTUpgrade_Skill_PyromaniacRush'.default.UpgradeIcon[1];
	
	if (!DKPC.RegisterAbility("Pyromaniac Rush", self, class'ZTUpgrade_Skill_PyromaniacRush_Helper', AbilityIcon))
	{
		`log("PyromaniacRush_Helper: Failed to register with player controller");
		Destroy();
		return;
	}
	
	MySlotIndex = DKPC.FindSlotByHelper(self);
	SetTimer(0.1f, true, nameof(UpdateAbility));
	DKPC.ClientUpdateAbilityHUD(MySlotIndex, false, false, 0.0f, 0.0f);
	
	`log("PyromaniacRush_Helper: Initialized at slot" @ MySlotIndex);
}

function SetTier(int InTier)
{
	Tier = Clamp(InTier, 1, 2);
	`log("PyromaniacRush_Helper: Tier" @ Tier);
}

function TryActivate()
{
	local float RemainingCooldown;
	
	if (OwnerPawn == None || OwnerPawn.Health <= 0)
	{
		class'ZTMessageManager'.static.SendMinor(DKPC, "Pyromaniac Rush: Cannot activate while dead!");
		return;
	}
	
	if (bActive)
	{
		class'ZTMessageManager'.static.SendMinor(DKPC, "Pyromaniac Rush: Already active!");
		return;
	}
	
	if (bOnCooldown)
	{
		RemainingCooldown = COOLDOWN - (OwnerPawn.WorldInfo.TimeSeconds - CooldownStartTime);
		class'ZTMessageManager'.static.SendMinor(DKPC, "Pyromaniac Rush: On cooldown (" $ int(RemainingCooldown) $ "s remaining)");
		return;
	}
	
	Activate();
}

function Activate()
{
	bActive = true;
	bNetDirty = true;
	ActivationTime = OwnerPawn.WorldInfo.TimeSeconds;
	
	if (OwnerPawn != None)
	{
		OwnerPawn.UpdateGroundSpeed();
	}
	
	if (Tier == 1)
	{
		class'ZTMessageManager'.static.SendImportant(DKPC, "PYROMANIAC RUSH! +10% speed + fire immunity for 10 seconds!");
	}
	else
	{
		class'ZTMessageManager'.static.SendImportant(DKPC, "PYROMANIAC RUSH (DELUXE)! +20% speed + fire immunity for 10 seconds!");
	}
	
	DKPC.ClientUpdateAbilityHUD(MySlotIndex, true, false, DURATION, DURATION);
	`log("PyromaniacRush_Helper: ACTIVATED - bActive=" $ bActive);
}

function Deactivate()
{
	bActive = false;
	bNetDirty = true;
	bOnCooldown = true;
	CooldownStartTime = OwnerPawn.WorldInfo.TimeSeconds;
	
	if (OwnerPawn != None)
	{
		OwnerPawn.UpdateGroundSpeed();
	}
	
	class'ZTMessageManager'.static.SendMinor(DKPC, "Pyromaniac Rush ended. Cooldown: 60 seconds.");
	DKPC.ClientUpdateAbilityHUD(MySlotIndex, false, true, COOLDOWN, COOLDOWN);
	`log("PyromaniacRush_Helper: DEACTIVATED - bActive=" $ bActive);
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
			class'ZTMessageManager'.static.SendImportant(DKPC, "Pyromaniac Rush ready!");
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
	
	Name="Default__ZTUpgrade_Skill_PyromaniacRush_Helper"
}