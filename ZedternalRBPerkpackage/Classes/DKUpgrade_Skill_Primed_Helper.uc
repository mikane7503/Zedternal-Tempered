class DKUpgrade_Skill_Primed_Helper extends Info
	transient;

var KFPawn_Human Player;
var bool bArmed;
var KFWeapon LastWeapon;
var const float CheckInterval;

function PostBeginPlay()
{
	super.PostBeginPlay();

	Player = KFPawn_Human(Owner);
	if (Player == None || Player.Health <= 0)
		Destroy();
	else
	{
		LastWeapon = KFWeapon(Player.Weapon);
		SetTimer(CheckInterval, True);
	}
}

function Timer()
{
	local KFWeapon CurrentWeapon;

	if (Player == None || Player.Health <= 0)
	{
		Destroy();
		return;
	}

	CurrentWeapon = KFWeapon(Player.Weapon);
	if (CurrentWeapon != None && CurrentWeapon != LastWeapon)
	{
		LastWeapon = CurrentWeapon;
		ArmShot();
	}
}

function ArmShot()
{
	bArmed = True;
}

function ConsumeShot()
{
	bArmed = False;
}

defaultproperties
{
	bArmed=True
	CheckInterval=0.1f

	Name="Default__DKUpgrade_Skill_Primed_Helper"
}
