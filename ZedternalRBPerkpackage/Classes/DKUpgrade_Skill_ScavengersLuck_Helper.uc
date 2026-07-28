// ===================================================================
// DKUpgrade_Skill_ScavengersLuck_Helper - Manages Scavenger's Luck ability state
// Instant reload + fire rate boost
// FIXED: Improved instant reload to properly handle weapon state
// ===================================================================
class DKUpgrade_Skill_ScavengersLuck_Helper extends Info
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
		`log("ScavengersLuck_Helper: ERROR - Invalid owner or controller!");
		Destroy();
		return;
	}
	
	SetTier(InTier);
	
	bActive = false;
	bOnCooldown = false;
	
	if (InTier == 1)
		AbilityIcon = class'DKUpgrade_Skill_ScavengersLuck'.default.UpgradeIcon[0];
	else
		AbilityIcon = class'DKUpgrade_Skill_ScavengersLuck'.default.UpgradeIcon[1];
	
	if (!DKPC.RegisterAbility("Scavenger's Luck", self, class'DKUpgrade_Skill_ScavengersLuck_Helper', AbilityIcon))
	{
		`log("ScavengersLuck_Helper: Failed to register with player controller");
		Destroy();
		return;
	}
	
	MySlotIndex = DKPC.FindSlotByHelper(self);
	SetTimer(0.1f, true, nameof(UpdateAbility));
	DKPC.ClientUpdateAbilityHUD(MySlotIndex, false, false, 0.0f, 0.0f);
	
	`log("ScavengersLuck_Helper: Initialized at slot" @ MySlotIndex);
}

function SetTier(int InTier)
{
	Tier = Clamp(InTier, 1, 2);
	`log("ScavengersLuck_Helper: Tier" @ Tier);
}

function TryActivate()
{
	local float RemainingCooldown;
	
	if (OwnerPawn == None || OwnerPawn.Health <= 0)
	{
		class'DKMessageManager'.static.SendMinor(DKPC, "Scavenger's Luck: Cannot activate while dead!");
		return;
	}
	
	if (bActive)
	{
		class'DKMessageManager'.static.SendMinor(DKPC, "Scavenger's Luck: Already active!");
		return;
	}
	
	if (bOnCooldown)
	{
		RemainingCooldown = COOLDOWN - (OwnerPawn.WorldInfo.TimeSeconds - CooldownStartTime);
		class'DKMessageManager'.static.SendMinor(DKPC, "Scavenger's Luck: On cooldown (" $ int(RemainingCooldown) $ "s remaining)");
		return;
	}
	
	Activate();
}

function Activate()
{
	bActive = true;
	bNetDirty = true;
	ActivationTime = OwnerPawn.WorldInfo.TimeSeconds;
	
	// Perform instant reload
	PerformInstantReload();
	
	if (Tier == 1)
	{
		class'DKMessageManager'.static.SendImportant(DKPC, "SCAVENGER'S LUCK! Instant reload + +30% fire rate for 10 seconds!");
	}
	else
	{
		class'DKMessageManager'.static.SendImportant(DKPC, "SCAVENGER'S LUCK (DELUXE)! Instant reload + +50% fire rate for 10 seconds!");
	}
	
	DKPC.ClientUpdateAbilityHUD(MySlotIndex, true, false, DURATION, DURATION);
	`log("ScavengersLuck_Helper: ACTIVATED - bActive=" $ bActive);
}

// FIXED: Use proven MagicBullet pattern for instant reload
function PerformInstantReload()
{
	local KFWeapon CurrentWeapon;
	
	if (OwnerPawn == None || OwnerPawn.Health <= 0)
		return;
	
	CurrentWeapon = KFWeapon(OwnerPawn.Weapon);
	if (CurrentWeapon == None)
	{
		`log("ScavengersLuck_Helper: No weapon equipped");
		return;
	}
	
	// Use different methods for standalone vs networked
	if (OwnerPawn.WorldInfo.NetMode == NM_Standalone)
	{
		StandaloneInstantReload(CurrentWeapon);
	}
	else
	{
		ServerInstantReload(CurrentWeapon);
	}
	
	`log("ScavengersLuck_Helper: Instant reload complete");
}

// Standalone (single-player) instant reload
function StandaloneInstantReload(KFWeapon MyKFWeapon)
{
	local int i, AmmoNeeded;
	
	if (MyKFWeapon == None)
		return;
	
	// Reload both fire modes
	for (i = 0; i < 2; i++)
	{
		if (MyKFWeapon.MagazineCapacity[i] > 0)
		{
			AmmoNeeded = MyKFWeapon.MagazineCapacity[i] - MyKFWeapon.AmmoCount[i];
			
			if (AmmoNeeded > 0 && MyKFWeapon.SpareAmmoCount[i] > 0)
			{
				AmmoNeeded = Min(AmmoNeeded, MyKFWeapon.SpareAmmoCount[i]);
				MyKFWeapon.AmmoCount[i] += AmmoNeeded;
				MyKFWeapon.SpareAmmoCount[i] -= AmmoNeeded;
			}
		}
	}
}

// Server instant reload (multiplayer)
function ServerInstantReload(KFWeapon MyKFWeapon)
{
	local int i, AmmoNeeded;
	local int AmmoAdded[2];
	
	if (MyKFWeapon == None)
		return;
	
	// Reload both fire modes and track what we added
	for (i = 0; i < 2; i++)
	{
		if (MyKFWeapon.MagazineCapacity[i] > 0)
		{
			AmmoNeeded = MyKFWeapon.MagazineCapacity[i] - MyKFWeapon.AmmoCount[i];
			
			if (AmmoNeeded > 0 && MyKFWeapon.SpareAmmoCount[i] > 0)
			{
				AmmoNeeded = Min(AmmoNeeded, MyKFWeapon.SpareAmmoCount[i]);
				MyKFWeapon.AmmoCount[i] += AmmoNeeded;
				MyKFWeapon.SpareAmmoCount[i] -= AmmoNeeded;
				AmmoAdded[i] = AmmoNeeded;
			}
			else
			{
				AmmoAdded[i] = 0;
			}
		}
		else
		{
			AmmoAdded[i] = 0;
		}
	}
	
	// Sync to client
	ClientInstantReload(AmmoAdded[0], AmmoAdded[1]);
}

// Client-side sync for instant reload
reliable client function ClientInstantReload(int AmmoAdded0, int AmmoAdded1)
{
	local KFWeapon MyKFWeapon;
	local PlayerController PC;
	
	PC = GetALocalPlayerController();
	
	if (PC != None && PC.Pawn != None && PC.Pawn.Health > 0)
	{
		MyKFWeapon = KFWeapon(PC.Pawn.Weapon);
		if (MyKFWeapon != None)
		{
			// Update primary fire mode
			if (AmmoAdded0 > 0 && MyKFWeapon.MagazineCapacity[0] > 0)
			{
				MyKFWeapon.AmmoCount[0] = Min(MyKFWeapon.MagazineCapacity[0], MyKFWeapon.AmmoCount[0] + AmmoAdded0);
				MyKFWeapon.SpareAmmoCount[0] = Max(0, MyKFWeapon.SpareAmmoCount[0] - AmmoAdded0);
			}
			
			// Update secondary fire mode
			if (AmmoAdded1 > 0 && MyKFWeapon.MagazineCapacity[1] > 0)
			{
				MyKFWeapon.AmmoCount[1] = Min(MyKFWeapon.MagazineCapacity[1], MyKFWeapon.AmmoCount[1] + AmmoAdded1);
				MyKFWeapon.SpareAmmoCount[1] = Max(0, MyKFWeapon.SpareAmmoCount[1] - AmmoAdded1);
			}
		}
	}
}

function Deactivate()
{
	bActive = false;
	bNetDirty = true;
	bOnCooldown = true;
	CooldownStartTime = OwnerPawn.WorldInfo.TimeSeconds;
	
	class'DKMessageManager'.static.SendMinor(DKPC, "Scavenger's Luck ended. Cooldown: 60 seconds.");
	DKPC.ClientUpdateAbilityHUD(MySlotIndex, false, true, COOLDOWN, COOLDOWN);
	`log("ScavengersLuck_Helper: DEACTIVATED - bActive=" $ bActive);
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
			class'DKMessageManager'.static.SendImportant(DKPC, "Scavenger's Luck ready!");
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
	
	Name="Default__DKUpgrade_Skill_ScavengersLuck_Helper"
}