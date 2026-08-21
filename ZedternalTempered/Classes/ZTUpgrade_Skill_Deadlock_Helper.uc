class ZTUpgrade_Skill_Deadlock_Helper extends Info transient;

var KFPawn_Human Player;
var bool bUsedThisWave;
var bool bInvincible;
var const float NearbyRadiusSQ;

function PostBeginPlay()
{
	super.PostBeginPlay();

	Player = KFPawn_Human(Owner);
	if (Player == None || Player.Health <= 0)
		Destroy();
}

function int CountNearbyEnemies()
{
	local int Count;
	local KFPawn_Monster KFM;

	if (Player == None)
		return 0;

	Count = 0;
	foreach DynamicActors(class'KFPawn_Monster', KFM)
	{
		if (KFM.IsAliveAndWell() && VSizeSQ(Player.Location - KFM.Location) <= NearbyRadiusSQ)
			++Count;
	}

	return Count;
}

function ActivateInvincibility(float Duration)
{
	bUsedThisWave = True;
	bInvincible = True;
	SetTimer(Duration, False, nameof(EndInvincibility));
	PlayActivateEffect();
}

function EndInvincibility()
{
	bInvincible = False;
	PlayDeactivateEffect();
}

function ResetForWave()
{
	bUsedThisWave = False;
	bInvincible = False;
	ClearTimer(nameof(EndInvincibility));
}

reliable client function PlayActivateEffect()
{
	local KFPlayerController KFPC;

	KFPC = KFPlayerController(GetALocalPlayerController());
	if (KFPC != None)
		KFPC.SetPerkEffect(True);
}

reliable client function PlayDeactivateEffect()
{
	local KFPlayerController KFPC;

	KFPC = KFPlayerController(GetALocalPlayerController());
	if (KFPC != None)
		KFPC.SetPerkEffect(False);
}

defaultproperties
{
	bOnlyRelevantToOwner=True
	bUsedThisWave=False
	bInvincible=False
	NearbyRadiusSQ=250000   // 500 UU = 5 meters, squared

	Name="Default__ZTUpgrade_Skill_Deadlock_Helper"
}
