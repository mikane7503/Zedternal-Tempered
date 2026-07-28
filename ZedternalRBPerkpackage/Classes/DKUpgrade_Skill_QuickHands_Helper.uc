class DKUpgrade_Skill_QuickHands_Helper extends Info
	transient;

var KFPawn_Human Player;
var bool bBoosted;
var float BoostTime;
var float BoostRemaining;
var int LastAmmoCount;
var KFWeapon LastTrackedWeapon;

var const float CheckInterval;

replication
{
	if (Role == Role_Authority && bNetDirty)
		bBoosted;
}

function PostBeginPlay()
{
	super.PostBeginPlay();

	Player = KFPawn_Human(Owner);
	if (Player == None || Player.Health <= 0)
		Destroy();
	else
		SetTimer(CheckInterval, True);
}

function Timer()
{
	local KFWeapon KFW;

	if (Player == None || Player.Health <= 0)
	{
		Destroy();
		return;
	}

	KFW = KFWeapon(Player.Weapon);

	// Decrement boost timer
	if (bBoosted)
	{
		BoostRemaining -= CheckInterval;
		if (BoostRemaining <= 0.0f)
		{
			bBoosted = False;
			BoostRemaining = 0.0f;
		}
	}

	if (KFW != None)
	{
		// Weapon changed - reset tracking
		if (KFW != LastTrackedWeapon)
		{
			LastTrackedWeapon = KFW;
			LastAmmoCount = KFW.AmmoCount[0];
			return;
		}

		// Detect reload completion: ammo jumped up from a low value
		if (KFW.AmmoCount[0] > LastAmmoCount && LastAmmoCount < KFW.MagazineCapacity[0])
		{
			// Reload just completed - activate boost
			bBoosted = True;
			BoostRemaining = BoostTime;
		}

		LastAmmoCount = KFW.AmmoCount[0];
	}
}

defaultproperties
{
	RemoteRole=ROLE_SimulatedProxy
	bSkipActorPropertyReplication=False

	bBoosted=False
	BoostTime=3.0f
	BoostRemaining=0.0f
	LastAmmoCount=0
	CheckInterval=0.2f

	Name="Default__DKUpgrade_Skill_QuickHands_Helper"
}
