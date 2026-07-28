// Helper for Venomous Riposte.
// When triggered (player takes damage), poisons all nearby ZEDs.
// Has a cooldown to prevent spam.
// Pattern based on ColdRiposte_Helper.
class DKUpgrade_Skill_VenomousRiposte_Helper extends Info
	transient;

var KFPawn_Human Player;
var bool bDeluxe, bReady;
var const float Delay, Update;
var const array<int> Radius, Damage;

function PostBeginPlay()
{
	super.PostBeginPlay();

	Player = KFPawn_Human(Owner);
	if (Player == None || Player.Health <= 0)
		Destroy();
}

function PoisonBurst()
{
	local KFPawn_Monster KFM;
	local KFPlayerController KFPC;
	local int Dmg, Rad;

	if (Player == None || Player.Health <= 0)
	{
		Destroy();
		return;
	}

	bReady = False;

	KFPC = KFPlayerController(Player.Controller);
	if (KFPC != None)
	{
		if (bDeluxe)
		{
			Dmg = default.Damage[1];
			Rad = default.Radius[1];
		}
		else
		{
			Dmg = default.Damage[0];
			Rad = default.Radius[0];
		}

		foreach DynamicActors(class'KFPawn_Monster', KFM)
		{
			if (KFM.IsAliveAndWell() && VSizeSQ(Player.Location - KFM.Location) <= Rad)
			{
				KFM.ApplyDamageOverTime(Dmg, KFPC, class'KFDT_Toxic');
			}
		}
	}

	SetTimer(Delay, False, nameof(ResetCooldown));
}

function ResetCooldown()
{
	if (Player == None || Player.Health <= 0)
		Destroy();
	else
		bReady = True;
}

defaultproperties
{
	bOnlyRelevantToOwner=True
	bDeluxe=False
	bReady=True
	Delay=20.0f

	// Radius squared: (400uu)^2 = 160000, (600uu)^2 = 360000
	Radius(0)=160000
	Radius(1)=360000

	Damage(0)=15
	Damage(1)=30

	Name="Default__DKUpgrade_Skill_VenomousRiposte_Helper"
}
