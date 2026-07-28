// ===================================================================
// DKUpgrade_Skill_BioelectricDischarge_Helper
// Monitors the player's current weapon magazine. When the magazine
// transitions from having ammo to empty (last round fired), triggers
// a bioelectric AoE pulse that damages nearby zeds.
// ===================================================================
class DKUpgrade_Skill_BioelectricDischarge_Helper extends Info
	transient;

var KFPawn_Human Player;
var bool bDeluxe;
var bool bReady;

// Tracking
var int PrevAmmoCount;
var KFWeapon PrevWeapon;

// Configuration
var const float PollInterval;
var const array<float> Cooldown;
var const array<int> Damage;
var const float Radius;

function PostBeginPlay()
{
	super.PostBeginPlay();

	Player = KFPawn_Human(Owner);
	if (Player == None || Player.Health <= 0)
		Destroy();
	else
	{
		bReady = True;
		PrevAmmoCount = -1;
		SetTimer(PollInterval, True);
	}
}

function Timer()
{
	local KFWeapon CurrentWeapon;
	local int CurrentAmmo;

	if (Player == None || Player.Health <= 0)
	{
		Destroy();
		return;
	}

	if (!bReady)
		return;

	CurrentWeapon = KFWeapon(Player.Weapon);
	if (CurrentWeapon == None)
	{
		PrevAmmoCount = -1;
		PrevWeapon = None;
		return;
	}

	// Weapon switched - reset tracking
	if (CurrentWeapon != PrevWeapon)
	{
		PrevWeapon = CurrentWeapon;
		PrevAmmoCount = CurrentWeapon.AmmoCount[0];
		return;
	}

	CurrentAmmo = CurrentWeapon.AmmoCount[0];

	// Detect magazine emptied: was > 0, now == 0
	// Also ensure magazine capacity > 1 (skip melee/single-shot oddities)
	if (PrevAmmoCount > 0 && CurrentAmmo == 0 && CurrentWeapon.MagazineCapacity[0] > 1)
	{
		TriggerDischarge();
	}

	PrevAmmoCount = CurrentAmmo;
}

function TriggerDischarge()
{
	local KFPawn_Monster NearbyZed;
	local int DmgAmount;
	local int UpgIdx;

	if (Player == None || Player.Health <= 0 || Player.Controller == None)
		return;

	UpgIdx = 0;
	if (bDeluxe)
		UpgIdx = 1;

	DmgAmount = Damage[UpgIdx];

	// Damage all nearby zeds
	foreach Player.CollidingActors(class'KFPawn_Monster', NearbyZed, Radius)
	{
		if (NearbyZed.IsAliveAndWell())
		{
			NearbyZed.TakeDamage(DmgAmount, Player.Controller, NearbyZed.Location, vect(0,0,0), class'KFDT_EMP');
		}
	}

	// Start cooldown
	bReady = False;
	SetTimer(Cooldown[UpgIdx], False, nameof(CooldownExpired));
}

function CooldownExpired()
{
	if (Player == None || Player.Health <= 0)
	{
		Destroy();
		return;
	}

	bReady = True;

	// Re-sync ammo tracking to prevent immediate re-trigger
	if (KFWeapon(Player.Weapon) != None)
		PrevAmmoCount = KFWeapon(Player.Weapon).AmmoCount[0];
}

defaultproperties
{
	bDeluxe=False
	bReady=True
	PrevAmmoCount=-1

	PollInterval=0.2f
	Cooldown(0)=10.0f
	Cooldown(1)=8.0f
	Damage(0)=50
	Damage(1)=100
	Radius=500.0f

	Name="Default__DKUpgrade_Skill_BioelectricDischarge_Helper"
}
