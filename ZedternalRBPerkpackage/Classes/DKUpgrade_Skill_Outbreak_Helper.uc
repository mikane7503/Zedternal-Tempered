// Helper for Outbreak.
// Periodically releases a massive poison pulse, poisoning ALL ZEDs in a huge radius.
// Long interval, big impact. Guarantees baseline poison coverage.
class DKUpgrade_Skill_Outbreak_Helper extends Info
	transient;

var KFPawn_Human Player;
var bool bDeluxe;
var const array<int> Damage;
var const array<float> Radius, Interval;

function PostBeginPlay()
{
	super.PostBeginPlay();

	Player = KFPawn_Human(Owner);
	if (Player == None || Player.Health <= 0)
		Destroy();
}

function StartTimer(bool bIsDeluxe)
{
	bDeluxe = bIsDeluxe;

	if (bDeluxe)
		SetTimer(default.Interval[1], True);
	else
		SetTimer(default.Interval[0], True);
}

function Timer()
{
	local KFPawn_Monster KFM;
	local KFPlayerController KFPC;
	local int Dmg;
	local float Rad;

	if (Player == None || Player.Health <= 0)
	{
		Destroy();
		return;
	}

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
}

defaultproperties
{
	bDeluxe=False

	Damage(0)=10
	Damage(1)=20

	// Radius squared: (1200uu)^2 = 1440000, (1800uu)^2 = 3240000
	Radius(0)=1440000.0f
	Radius(1)=3240000.0f

	// Pulse every 15s (L1) or 10s (L2)
	Interval(0)=15.0f
	Interval(1)=10.0f

	Name="Default__DKUpgrade_Skill_Outbreak_Helper"
}
