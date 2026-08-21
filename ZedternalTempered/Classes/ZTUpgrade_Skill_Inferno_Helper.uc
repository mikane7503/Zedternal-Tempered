// ===================================================================
// ZTUpgrade_Skill_Inferno_Helper - Manages Inferno ability state
// Ignites all enemies in line of sight with powerful fire DoT
// ===================================================================
class ZTUpgrade_Skill_Inferno_Helper extends Info transient;

var KFPawn_Human OwnerPawn;
var ZTPlayerController DKPC;
var int MySlotIndex;

var repnotify bool bActive;
var bool bOnCooldown;
var float CooldownStartTime;

var int Tier;
var float Cooldown;

// Sound effect - native SoundCue (not AkEvent!)
var SoundCue ActivationSound;

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
		`log("Inferno_Helper: ERROR - Invalid owner or controller!");
		Destroy();
		return;
	}
	
	SetTier(InTier);
	
	bActive = false;
	bOnCooldown = false;
	
	// Load custom activation sound via ZTMutator
	foreach OwnerPawn.WorldInfo.AllActors(class'ZTMutator', Mutator)
	{
		`log("Inferno_Helper: Found ZTMutator, requesting sound...");
		// FIXED: Use 'Inferno_Activate' not 'Inferno_Activate_Cue'
		ActivationSound = Mutator.GetCustomSound('Inferno_Activate');
		if (ActivationSound != None)
		{
			`log("Inferno_Helper: ✓ Loaded custom SoundCue:" @ ActivationSound);
		}
		else
		{
			`log("Inferno_Helper: ✗ Custom sound returned None!");
		}
		break;
	}
	
	if (Mutator == None)
	{
		`log("Inferno_Helper: ERROR - Could not find ZTMutator!");
	}
	
	if (InTier == 1)
		AbilityIcon = class'ZTUpgrade_Skill_Inferno'.default.UpgradeIcon[0];
	else
		AbilityIcon = class'ZTUpgrade_Skill_Inferno'.default.UpgradeIcon[1];
	
	if (!DKPC.RegisterAbility("Inferno", self, class'ZTUpgrade_Skill_Inferno_Helper', AbilityIcon))
	{
		`log("Inferno_Helper: Failed to register with player controller");
		Destroy();
		return;
	}
	
	MySlotIndex = DKPC.FindSlotByHelper(self);
	
	SetTimer(0.1f, true, nameof(UpdateAbility));
	
	DKPC.ClientUpdateAbilityHUD(MySlotIndex, false, false, 0.0f, 0.0f);
	
	`log("Inferno_Helper: Initialized at slot" @ MySlotIndex);
}

function SetTier(int InTier)
{
	Tier = Clamp(InTier, 1, 2);
	
	// Cooldown is config-driven:
	// [ZedternalTempered.ZTUpgrade_Skill_Inferno] Cooldowns
	// (index 0 = standard, 1 = deluxe)
	if (Tier == 1)
		Cooldown = class'ZTUpgrade_Skill_Inferno'.default.Cooldowns[0];
	else
		Cooldown = class'ZTUpgrade_Skill_Inferno'.default.Cooldowns[1];
	
	`log("Inferno_Helper: Tier" @ Tier @ "- Cooldown:" @ Cooldown);
}

function TryActivate()
{
	local float RemainingCooldown;
	
	if (OwnerPawn == None || OwnerPawn.Health <= 0)
	{
		class'ZTMessageManager'.static.SendMinor(DKPC, "Inferno: Cannot activate while dead!");
		return;
	}
	
	if (bOnCooldown)
	{
		RemainingCooldown = Cooldown - (OwnerPawn.WorldInfo.TimeSeconds - CooldownStartTime);
		class'ZTMessageManager'.static.SendMinor(
			DKPC, 
			"Inferno: On cooldown (" $ int(RemainingCooldown) $ "s remaining)"
		);
		return;
	}
	
	Activate();
}

function Activate()
{
	local KFPawn_Monster Monster;
	local vector ViewLocation, ViewDirection;
	local rotator ViewRotation;
	local int IgnitedCount;
	local float DotProduct;
	local vector ToMonster;
	
	bActive = true;
	bNetDirty = true;
	bOnCooldown = true;
	CooldownStartTime = OwnerPawn.WorldInfo.TimeSeconds;
	
	// ===================================================================
	// PLAY CUSTOM SOUND - Native SoundCue, NO WWISE!
	// ===================================================================
	`log("Inferno_Helper: About to play sound...");
	`log("Inferno_Helper: ActivationSound =" @ ActivationSound);
	`log("Inferno_Helper: DKPC =" @ DKPC);
	
	if (ActivationSound != None && DKPC != None)
	{
		`log("Inferno_Helper: Calling DKPC.ClientPlayInfernoSound...");
		DKPC.ClientPlayInfernoSound(ActivationSound);
		`log("Inferno_Helper: Sent sound to client via PlayerController");
	}
	else
	{
		if (ActivationSound == None)
			`log("Inferno_Helper: ✗ Cannot play - ActivationSound is None!");
		if (DKPC == None)
			`log("Inferno_Helper: ✗ Cannot play - DKPC is None!");
	}
	
	// Get player view
	DKPC.GetPlayerViewPoint(ViewLocation, ViewRotation);
	ViewDirection = vector(ViewRotation);
	
	IgnitedCount = 0;
	
	// Find all enemies in line of sight
	foreach OwnerPawn.WorldInfo.AllPawns(class'KFPawn_Monster', Monster)
	{
		if (Monster.IsAliveAndWell())
		{
			// Check if monster is in front of player (180-degree cone for reliable detection)
			ToMonster = Normal(Monster.Location - ViewLocation);
			DotProduct = ViewDirection dot ToMonster;
			
			// Must be in front of player (180-degree cone = anything not behind)
			if (DotProduct > 0.0f)
			{
				// Perform line of sight trace using FastTrace (more reliable)
				if (OwnerPawn.FastTrace(Monster.Location, ViewLocation))
				{
					// Apply powerful fire DoT
					Monster.ApplyDamageOverTime(
						100, // Strong base damage
						DKPC,
						class'ZTDT_InfernoBlast'
					);
					
					IgnitedCount++;
				}
			}
		}
	}
	
	if (Tier == 1)
	{
		class'ZTMessageManager'.static.SendImportant(
			DKPC,
			"INFERNO ACTIVATED! Set " $ IgnitedCount $ " enemies ablaze!"
		);
	}
	else
	{
		class'ZTMessageManager'.static.SendImportant(
			DKPC,
			"INFERNO (DELUXE) ACTIVATED! Set " $ IgnitedCount $ " enemies ablaze! +" $ int(class'ZTUpgrade_Skill_Inferno'.default.FireDamageBonuses[1] * 100.0f) $ "% fire damage while recharging!"
		);
	}
	
	`log("Inferno_Helper: ACTIVATED - Ignited" @ IgnitedCount @ "enemies in line of sight");
	
	DKPC.ClientUpdateAbilityHUD(MySlotIndex, false, true, Cooldown, Cooldown);
	
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
		
		if (Elapsed >= Cooldown)
		{
			bOnCooldown = false;
			class'ZTMessageManager'.static.SendImportant(DKPC, "Inferno ready!");
			DKPC.ClientUpdateAbilityHUD(MySlotIndex, false, false, 0.0f, 0.0f);
		}
		else
		{
			RemainingTime = Cooldown - Elapsed;
			DKPC.ClientUpdateAbilityHUD(MySlotIndex, false, true, RemainingTime, Cooldown);
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
	Cooldown=60.0f
	MySlotIndex=-1
	
	Name="Default__ZTUpgrade_Skill_Inferno_Helper"
}
