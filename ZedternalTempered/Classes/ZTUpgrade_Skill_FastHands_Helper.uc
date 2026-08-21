// ===================================================================
// ZTUpgrade_Skill_FastHands_Helper - Manages Fast Hands ability state
// (renamed from ZTUpgrade_Skill_QuickDraw_Helper)
// ===================================================================
class ZTUpgrade_Skill_FastHands_Helper extends Info
	transient;

var KFPawn_Human OwnerPawn;
var ZTPlayerController ZTPC;
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
	ZTPC = InDKPC;
	
	if (OwnerPawn == None || ZTPC == None)
	{
		`log("FastHands_Helper: ERROR - Invalid owner or controller!");
		Destroy();
		return;
	}
	
	SetTier(InTier);
	
	bActive = false;
	bOnCooldown = false;
	
	if (InTier == 1)
		AbilityIcon = class'ZTUpgrade_Skill_FastHands'.default.UpgradeIcon[0];
	else
		AbilityIcon = class'ZTUpgrade_Skill_FastHands'.default.UpgradeIcon[1];
	
	if (!ZTPC.RegisterAbility("Fast Hands", self, class'ZTUpgrade_Skill_FastHands_Helper', AbilityIcon))
	{
		`log("FastHands_Helper: Failed to register with player controller");
		Destroy();
		return;
	}
	
	MySlotIndex = ZTPC.FindSlotByHelper(self);
	SetTimer(0.1f, true, nameof(UpdateAbility));
	ZTPC.ClientUpdateAbilityHUD(MySlotIndex, false, false, 0.0f, 0.0f);
	
	`log("FastHands_Helper: Initialized at slot" @ MySlotIndex);
}

function SetTier(int InTier)
{
	Tier = Clamp(InTier, 1, 2);
	`log("FastHands_Helper: Tier" @ Tier);
}

function TryActivate()
{
	local float RemainingCooldown;
	
	if (OwnerPawn == None || OwnerPawn.Health <= 0)
	{
		class'ZTMessageManager'.static.SendMinor(ZTPC, "Fast Hands: Cannot activate while dead!");
		return;
	}
	
	if (bActive)
	{
		class'ZTMessageManager'.static.SendMinor(ZTPC, "Fast Hands: Already active!");
		return;
	}
	
	if (bOnCooldown)
	{
		RemainingCooldown = COOLDOWN - (OwnerPawn.WorldInfo.TimeSeconds - CooldownStartTime);
		class'ZTMessageManager'.static.SendMinor(ZTPC, "Fast Hands: On cooldown (" $ int(RemainingCooldown) $ "s remaining)");
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
		class'ZTMessageManager'.static.SendImportant(ZTPC, "FAST HANDS ACTIVATED! +40% fire rate for 10 seconds!");
	}
	else
	{
		class'ZTMessageManager'.static.SendImportant(ZTPC, "FAST HANDS (DELUXE) ACTIVATED! +60% fire rate for 10 seconds!");
	}
	
	ZTPC.ClientUpdateAbilityHUD(MySlotIndex, true, false, DURATION, DURATION);
	`log("FastHands_Helper: ACTIVATED - bActive=" $ bActive);
}

function Deactivate()
{
	bActive = false;
	bNetDirty = true;
	bOnCooldown = true;
	CooldownStartTime = OwnerPawn.WorldInfo.TimeSeconds;
	
	class'ZTMessageManager'.static.SendMinor(ZTPC, "Fast Hands ended. Cooldown: 60 seconds.");
	ZTPC.ClientUpdateAbilityHUD(MySlotIndex, false, true, COOLDOWN, COOLDOWN);
	`log("FastHands_Helper: DEACTIVATED - bActive=" $ bActive);
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
			ZTPC.ClientUpdateAbilityHUD(MySlotIndex, true, false, RemainingTime, DURATION);
		}
	}
	else if (bOnCooldown)
	{
		Elapsed = CurrentTime - CooldownStartTime;
		
		if (Elapsed >= COOLDOWN)
		{
			bOnCooldown = false;
			class'ZTMessageManager'.static.SendImportant(ZTPC, "Fast Hands ready!");
			ZTPC.ClientUpdateAbilityHUD(MySlotIndex, false, false, 0.0f, 0.0f);
		}
		else
		{
			RemainingTime = COOLDOWN - Elapsed;
			ZTPC.ClientUpdateAbilityHUD(MySlotIndex, false, true, RemainingTime, COOLDOWN);
		}
	}
}

function Cleanup()
{
	if (ZTPC != None)
	{
		ZTPC.UnregisterAbility(self);
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
	
	Name="Default__ZTUpgrade_Skill_FastHands_Helper"
}
