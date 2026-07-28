class DKUpgrade_Skill_Shockwave_Helper extends Info
	transient;

var KFPawn_Human Player;
var int KillCount;
var const int NormalRadius, DeluxeRadius;
var const int NormalDamage, DeluxeDamage;

function PostBeginPlay()
{
	super.PostBeginPlay();

	Player = KFPawn_Human(Owner);
	if (Player == None || Player.Health <= 0)
		Destroy();
}

function RegisterKill()
{
	++KillCount;
}

function TriggerShockwave(bool bDeluxe)
{
	local KFPawn_Monster KFM;
	local int RadiusSQ, ShockDamage;
	local vector KnockDir;

	if (Player == None || Player.Health <= 0)
	{
		Destroy();
		return;
	}

	KillCount = 0;

	if (bDeluxe)
	{
		RadiusSQ = DeluxeRadius;
		ShockDamage = DeluxeDamage;
	}
	else
	{
		RadiusSQ = NormalRadius;
		ShockDamage = NormalDamage;
	}

	foreach DynamicActors(class'KFPawn_Monster', KFM)
	{
		if (KFM.IsAliveAndWell() && VSizeSQ(Player.Location - KFM.Location) <= RadiusSQ)
		{
			// Apply damage
			KFM.TakeDamage(ShockDamage, Player.Controller, KFM.Location, vect(0,0,0), class'KFDT_Bludgeon');

			// Knockdown if possible
			KnockDir = Normal(KFM.Location - Player.Location);
			KnockDir.Z = 0.5f;
			if (KFM.CanDoSpecialMove(SM_Knockdown))
				KFM.Knockdown(KnockDir * 500.0f, vect(1,1,1), KFM.Location, 1000, 100);
		}
	}

	PlayShockwaveEffect();
}

reliable client function PlayShockwaveEffect()
{
	local KFPlayerController KFPC;

	KFPC = KFPlayerController(GetALocalPlayerController());
	if (KFPC != None)
	{
		KFPC.SetPerkEffect(True);
		SetTimer(0.3f, False, nameof(ClearEffect));
	}
}

reliable client function ClearEffect()
{
	local KFPlayerController KFPC;

	KFPC = KFPlayerController(GetALocalPlayerController());
	if (KFPC != None)
		KFPC.SetPerkEffect(False);
}

defaultproperties
{
	bOnlyRelevantToOwner=True
	KillCount=0
	NormalRadius=250000     // 500 UU = 5 meters, squared
	DeluxeRadius=490000     // 700 UU = 7 meters, squared
	NormalDamage=50
	DeluxeDamage=100

	Name="Default__DKUpgrade_Skill_Shockwave_Helper"
}
