// ===================================================================
// ZTUpgrade_Skill_Mitosis_Helper
// Tracks kill count and refills the current weapon's magazine
// when the threshold is reached. Uses the MagicBullet pattern
// for reliable client-server ammo synchronization.
// ===================================================================
class ZTUpgrade_Skill_Mitosis_Helper extends Info transient;

var KFPawn_Human Player;
var byte KillCount;
var byte KillThreshold;
var bool bDeluxe;

replication
{
	if (Role == Role_Authority && bNetDirty)
		KillCount;
}

function PostBeginPlay()
{
	super.PostBeginPlay();

	Player = KFPawn_Human(Owner);
	if (Player == None || Player.Health <= 0)
		Destroy();
}

function OnKill()
{
	if (Player == None || Player.Health <= 0)
	{
		Destroy();
		return;
	}

	++KillCount;

	if (KillCount >= KillThreshold)
	{
		KillCount = 0;
		RefillMagazine();
	}
}

function RefillMagazine()
{
	local KFWeapon MyKFWeapon;

	MyKFWeapon = KFWeapon(Player.Weapon);
	if (MyKFWeapon == None)
		return;

	// Only refill if magazine has capacity > 1 (skip melee etc.)
	if (MyKFWeapon.MagazineCapacity[0] <= 1)
		return;

	if (Player.WorldInfo.NetMode == NM_Standalone)
		StandaloneRefill(MyKFWeapon);
	else
		ServerRefill(MyKFWeapon);
}

function StandaloneRefill(KFWeapon MyKFWeapon)
{
	local int AmmoNeeded;

	AmmoNeeded = MyKFWeapon.MagazineCapacity[0] - MyKFWeapon.AmmoCount[0];
	if (AmmoNeeded <= 0)
		return;

	// Take from spare ammo
	AmmoNeeded = Min(AmmoNeeded, MyKFWeapon.SpareAmmoCount[0]);
	if (AmmoNeeded > 0)
	{
		MyKFWeapon.AmmoCount[0] += AmmoNeeded;
		MyKFWeapon.SpareAmmoCount[0] -= AmmoNeeded;
	}
}

function ServerRefill(KFWeapon MyKFWeapon)
{
	local int AmmoNeeded;

	AmmoNeeded = MyKFWeapon.MagazineCapacity[0] - MyKFWeapon.AmmoCount[0];
	if (AmmoNeeded <= 0)
		return;

	AmmoNeeded = Min(AmmoNeeded, MyKFWeapon.SpareAmmoCount[0]);
	if (AmmoNeeded > 0)
	{
		MyKFWeapon.AmmoCount[0] += AmmoNeeded;
		MyKFWeapon.SpareAmmoCount[0] -= AmmoNeeded;
		ClientRefill(AmmoNeeded);
	}
}

reliable client function ClientRefill(int Ammo)
{
	local KFWeapon MyKFWeapon;
	local PlayerController PC;

	PC = GetALocalPlayerController();

	if (PC != None && PC.Pawn != None && PC.Pawn.Health > 0)
	{
		MyKFWeapon = KFWeapon(PC.Pawn.Weapon);
		if (MyKFWeapon != None && Ammo > 0)
		{
			MyKFWeapon.AmmoCount[0] = Min(MyKFWeapon.MagazineCapacity[0], MyKFWeapon.AmmoCount[0] + Ammo);
			MyKFWeapon.SpareAmmoCount[0] = Max(0, MyKFWeapon.SpareAmmoCount[0] - Ammo);
		}
	}
}

defaultproperties
{
	RemoteRole=ROLE_SimulatedProxy
	bSkipActorPropertyReplication=False
	KillCount=0
	KillThreshold=15
	bDeluxe=False

	Name="Default__ZTUpgrade_Skill_Mitosis_Helper"
}
