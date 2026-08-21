// ===================================================================
// ZTUpgrade_Skill_FieldSurgery_Helper - Manages Field Surgery ability state
// ===================================================================
class ZTUpgrade_Skill_FieldSurgery_Helper extends Info transient;

var KFPawn_Human OwnerPawn;
var ZTPlayerController DKPC;
var int MySlotIndex;

var bool bOnCooldown;
var float CooldownStartTime;

var int Tier;
var int HealAmount;

const COOLDOWN = 60.0f;

function Initialize(int InTier, KFPawn_Human InOwnerPawn, ZTPlayerController InDKPC)
{
	local Texture2D AbilityIcon;
	
	OwnerPawn = InOwnerPawn;
	DKPC = InDKPC;
	
	if (OwnerPawn == None || DKPC == None)
	{
		`log("FieldSurgery_Helper: ERROR - Invalid owner or controller!");
		Destroy();
		return;
	}
	
	SetTier(InTier);
	
	bOnCooldown = false;
	
	if (InTier == 1)
		AbilityIcon = class'ZTUpgrade_Skill_FieldSurgery'.default.UpgradeIcon[0];
	else
		AbilityIcon = class'ZTUpgrade_Skill_FieldSurgery'.default.UpgradeIcon[1];
	
	if (!DKPC.RegisterAbility("Field Surgery", self, class'ZTUpgrade_Skill_FieldSurgery_Helper', AbilityIcon))
	{
		`log("FieldSurgery_Helper: Failed to register with player controller");
		Destroy();
		return;
	}
	
	MySlotIndex = DKPC.FindSlotByHelper(self);
	SetTimer(0.1f, true, nameof(UpdateAbility));
	DKPC.ClientUpdateAbilityHUD(MySlotIndex, false, false, 0.0f, 0.0f);
	
	`log("FieldSurgery_Helper: Initialized at slot" @ MySlotIndex);
}

function SetTier(int InTier)
{
	Tier = Clamp(InTier, 1, 2);
	HealAmount = class'ZTUpgrade_Skill_FieldSurgery'.default.HealAmount[Tier - 1];
	`log("FieldSurgery_Helper: Tier" @ Tier @ "- Heal:" @ HealAmount);
}

function TryActivate()
{
	local float RemainingCooldown;
	
	if (OwnerPawn == None || OwnerPawn.Health <= 0)
	{
		class'ZTMessageManager'.static.SendMinor(DKPC, "Field Surgery: Cannot activate while dead!");
		return;
	}
	
	if (bOnCooldown)
	{
		RemainingCooldown = COOLDOWN - (OwnerPawn.WorldInfo.TimeSeconds - CooldownStartTime);
		class'ZTMessageManager'.static.SendMinor(DKPC, "Field Surgery: On cooldown (" $ int(RemainingCooldown) $ "s remaining)");
		return;
	}
	
	Activate();
}

function Activate()
{
	local int HealedAmount;
	
	// Heal the player
	HealedAmount = Min(HealAmount, OwnerPawn.HealthMax - OwnerPawn.Health);
	OwnerPawn.Health = Min(OwnerPawn.Health + HealAmount, OwnerPawn.HealthMax);
	
	if (Tier == 1)
	{
		class'ZTMessageManager'.static.SendImportant(DKPC, "FIELD SURGERY! Healed " $ HealedAmount $ " HP!");
	}
	else
	{
		class'ZTMessageManager'.static.SendImportant(DKPC, "FIELD SURGERY (DELUXE)! Healed " $ HealedAmount $ " HP!");
	}
	
	// Start cooldown
	bOnCooldown = true;
	CooldownStartTime = OwnerPawn.WorldInfo.TimeSeconds;
	DKPC.ClientUpdateAbilityHUD(MySlotIndex, false, true, COOLDOWN, COOLDOWN);
	
	`log("FieldSurgery_Helper: ACTIVATED - Healed" @ HealedAmount @ "HP");
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
			class'ZTMessageManager'.static.SendImportant(DKPC, "Field Surgery ready!");
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
	bOnCooldown=false
	Tier=1
	HealAmount=25
	MySlotIndex=-1
	
	Name="Default__ZTUpgrade_Skill_FieldSurgery_Helper"
}