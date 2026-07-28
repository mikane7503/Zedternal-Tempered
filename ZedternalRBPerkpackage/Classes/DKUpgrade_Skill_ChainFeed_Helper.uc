class DKUpgrade_Skill_ChainFeed_Helper extends Info
	transient;

var KFPawn_Human Player;

function PostBeginPlay()
{
	super.PostBeginPlay();

	Player = KFPawn_Human(Owner);
	if (Player == None || Player.Health <= 0)
		Destroy();
}

function int AddAmmo(float CapMultiplier, KFWeapon MyKFWeapon)
{
	local int MaxAmmo;

	// Calculate extended cap based on multiplier
	MaxAmmo = Round(float(MyKFWeapon.MagazineCapacity[0]) * CapMultiplier);

	// Only add if we haven't hit the extended cap
	if (MyKFWeapon.AmmoCount[0] < MaxAmmo)
	{
		MyKFWeapon.AmmoCount[0] += 1;
		return 1;
	}

	return -1;
}

function StandaloneAddAmmo(float CapMultiplier)
{
	local KFWeapon MyKFWeapon;

	if (Player != None && Player.Health > 0)
	{
		MyKFWeapon = KFWeapon(Player.Weapon);
		if (MyKFWeapon != None && MyKFWeapon.MagazineCapacity[0] > 1)
		{
			AddAmmo(CapMultiplier, MyKFWeapon);
		}
	}
	else
		Destroy();
}

function ServerAddAmmo(float CapMultiplier)
{
	local KFWeapon MyKFWeapon;
	local int Result;

	if (Player != None && Player.Health > 0)
	{
		MyKFWeapon = KFWeapon(Player.Weapon);
		if (MyKFWeapon != None && MyKFWeapon.MagazineCapacity[0] > 1)
		{
			Result = AddAmmo(CapMultiplier, MyKFWeapon);
			if (Result > 0)
				ClientAddAmmo(CapMultiplier);
		}
	}
	else
		Destroy();
}

reliable client function ClientAddAmmo(float CapMultiplier)
{
	local KFWeapon MyKFWeapon;
	local PlayerController PC;
	local int MaxAmmo;

	PC = GetALocalPlayerController();

	if (PC != None && PC.Pawn != None && PC.Pawn.Health > 0)
	{
		MyKFWeapon = KFWeapon(PC.Pawn.Weapon);
		if (MyKFWeapon != None)
		{
			MaxAmmo = Round(float(MyKFWeapon.MagazineCapacity[0]) * CapMultiplier);
			MyKFWeapon.AmmoCount[0] = Min(MaxAmmo, MyKFWeapon.AmmoCount[0] + 1);
		}
	}
}

defaultproperties
{
	Name="Default__DKUpgrade_Skill_ChainFeed_Helper"
}
