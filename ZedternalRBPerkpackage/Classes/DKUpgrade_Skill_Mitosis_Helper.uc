// ===================================================================
// DKUpgrade_Skill_Mitosis_Helper
// Tracks kill count and refills the current weapon's magazine
// when the threshold is reached. Uses the MagicBullet pattern
// for reliable client-server ammo synchronization.
//
// Structure matches the proven SymbioticToxin / AmmoSiphon helpers:
// plain server-side Info (ROLE_None), no property replication. The
// previous replication block and RemoteRole override served no
// purpose (KillCount is server-only) and were the single deviation
// from the working helper shape.
//
// The kill counter caps at the threshold and only resets when a
// refill actually transfers rounds, so a trigger that lands on a
// full magazine or a melee weapon is retried on the next kill
// instead of being consumed.
// ===================================================================
class DKUpgrade_Skill_Mitosis_Helper extends Info
	transient;

var KFPawn_Human Player;
var byte KillCount;
var byte KillThreshold;
var bool bDeluxe;

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

	// Cap at threshold so a banked trigger cannot overshoot or wrap
	if (KillCount < KillThreshold)
		++KillCount;

	if (KillCount >= KillThreshold)
	{
		// Only consume the quota when rounds actually moved.
		// Otherwise keep it banked and retry on the next kill.
		if (RefillMagazine())
			KillCount = 0;
	}
}

// Returns true if at least one round was transferred into the magazine
function bool RefillMagazine()
{
	local KFWeapon MyKFWeapon;

	MyKFWeapon = KFWeapon(Player.Weapon);
	if (MyKFWeapon == None)
		return false;

	// Only refill if magazine has capacity > 1 (skip melee etc.)
	if (MyKFWeapon.MagazineCapacity[0] <= 1)
		return false;

	if (Player.WorldInfo.NetMode == NM_Standalone)
		return StandaloneRefill(MyKFWeapon);
	else
		return ServerRefill(MyKFWeapon);
}

function bool StandaloneRefill(KFWeapon MyKFWeapon)
{
	local int AmmoNeeded;

	AmmoNeeded = MyKFWeapon.MagazineCapacity[0] - MyKFWeapon.AmmoCount[0];
	if (AmmoNeeded <= 0)
		return false;

	// Take from spare ammo
	AmmoNeeded = Min(AmmoNeeded, MyKFWeapon.SpareAmmoCount[0]);
	if (AmmoNeeded > 0)
	{
		MyKFWeapon.AmmoCount[0] += AmmoNeeded;
		MyKFWeapon.SpareAmmoCount[0] -= AmmoNeeded;
		return true;
	}

	return false;
}

function bool ServerRefill(KFWeapon MyKFWeapon)
{
	local int AmmoNeeded;

	AmmoNeeded = MyKFWeapon.MagazineCapacity[0] - MyKFWeapon.AmmoCount[0];
	if (AmmoNeeded <= 0)
		return false;

	AmmoNeeded = Min(AmmoNeeded, MyKFWeapon.SpareAmmoCount[0]);
	if (AmmoNeeded > 0)
	{
		MyKFWeapon.AmmoCount[0] += AmmoNeeded;
		MyKFWeapon.SpareAmmoCount[0] -= AmmoNeeded;
		ClientRefill(AmmoNeeded);
		return true;
	}

	return false;
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
	KillCount=0
	KillThreshold=15
	bDeluxe=False

	Name="Default__DKUpgrade_Skill_Mitosis_Helper"
}
