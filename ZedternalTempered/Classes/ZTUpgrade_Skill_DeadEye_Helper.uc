// ===================================================================
// ZTUpgrade_Skill_DeadEye_Helper - Manages Dead Eye ability state
// ===================================================================
class ZTUpgrade_Skill_DeadEye_Helper extends Info transient;

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

function Initialize(int InTier, KFPawn_Human InOwnerPawn, ZTPlayerController InDKPC)
{
	local Texture2D AbilityIcon;
	
	OwnerPawn = InOwnerPawn;
	DKPC = InDKPC;
	
	if (OwnerPawn == None || DKPC == None)
	{
		`log("DeadEye_Helper: ERROR - Invalid owner or controller!");
		Destroy();
		return;
	}
	
	SetTier(InTier);
	
	bActive = false;
	bOnCooldown = false;
	
	if (InTier == 1)
		AbilityIcon = class'ZTUpgrade_Skill_DeadEye'.default.UpgradeIcon[0];
	else
		AbilityIcon = class'ZTUpgrade_Skill_DeadEye'.default.UpgradeIcon[1];
	
	if (!DKPC.RegisterAbility("Dead Eye", self, class'ZTUpgrade_Skill_DeadEye_Helper', AbilityIcon))
	{
		`log("DeadEye_Helper: Failed to register with player controller");
		Destroy();
		return;
	}
	
	MySlotIndex = DKPC.FindSlotByHelper(self);
	SetTimer(0.1f, true, nameof(UpdateAbility));
	DKPC.ClientUpdateAbilityHUD(MySlotIndex, false, false, 0.0f, 0.0f);
	
	`log("DeadEye_Helper: Initialized at slot" @ MySlotIndex);
}

function SetTier(int InTier)
{
	Tier = Clamp(InTier, 1, 2);
	`log("DeadEye_Helper: Tier" @ Tier);
}

function TryActivate()
{
	local float RemainingCooldown;
	
	if (OwnerPawn == None || OwnerPawn.Health <= 0)
	{
		class'ZTMessageManager'.static.SendMinor(DKPC, "Dead Eye: Cannot activate while dead!");
		return;
	}
	
	if (bActive)
	{
		class'ZTMessageManager'.static.SendMinor(DKPC, "Dead Eye: Already active!");
		return;
	}
	
	if (bOnCooldown)
	{
		RemainingCooldown = COOLDOWN - (OwnerPawn.WorldInfo.TimeSeconds - CooldownStartTime);
		class'ZTMessageManager'.static.SendMinor(DKPC, "Dead Eye: On cooldown (" $ int(RemainingCooldown) $ "s remaining)");
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
		class'ZTMessageManager'.static.SendImportant(DKPC, "DEAD EYE ACTIVATED! +25% headshot damage for 10 seconds!");
	}
	else
	{
		class'ZTMessageManager'.static.SendImportant(DKPC, "DEAD EYE (DELUXE) ACTIVATED! +40% headshot damage for 10 seconds!");
	}
	
	DKPC.ClientUpdateAbilityHUD(MySlotIndex, true, false, DURATION, DURATION);
	`log("DeadEye_Helper: ACTIVATED - bActive=" $ bActive);
}

function Deactivate()
{
	bActive = false;
	bNetDirty = true;
	bOnCooldown = true;
	CooldownStartTime = OwnerPawn.WorldInfo.TimeSeconds;
	
	class'ZTMessageManager'.static.SendMinor(DKPC, "Dead Eye ended. Cooldown: 60 seconds.");
	DKPC.ClientUpdateAbilityHUD(MySlotIndex, false, true, COOLDOWN, COOLDOWN);
	`log("DeadEye_Helper: DEACTIVATED - bActive=" $ bActive);
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
			class'ZTMessageManager'.static.SendImportant(DKPC, "Dead Eye ready!");
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
	
	Name="Default__ZTUpgrade_Skill_DeadEye_Helper"
}