class DKUpgrade_Skill_CloseCall_Helper extends Info
	transient;

var WMPawn_Human Player;
var bool bActive;
var const float CheckInterval;
var const float HealthThreshold;

function PostBeginPlay()
{
	super.PostBeginPlay();

	Player = WMPawn_Human(Owner);
	if (Player == None || Player.Health <= 0)
		Destroy();
	else
		SetTimer(CheckInterval, True);
}

function Timer()
{
	local bool bShouldBeActive;

	if (Player == None || Player.Health <= 0)
	{
		Destroy();
		return;
	}

	bShouldBeActive = (float(Player.Health) / float(Player.HealthMax)) <= HealthThreshold;

	if (bShouldBeActive && !bActive)
	{
		bActive = True;
		ActivateEffect();
	}
	else if (!bShouldBeActive && bActive)
	{
		bActive = False;
		DeactivateEffect();
	}
}

reliable client function ActivateEffect()
{
	local KFPlayerController KFPC;

	KFPC = KFPlayerController(GetALocalPlayerController());
	if (KFPC != None)
		KFPC.SetPerkEffect(True);
}

reliable client function DeactivateEffect()
{
	local KFPlayerController KFPC;

	KFPC = KFPlayerController(GetALocalPlayerController());
	if (KFPC != None)
		KFPC.SetPerkEffect(False);
}

defaultproperties
{
	RemoteRole=ROLE_SimulatedProxy
	bSkipActorPropertyReplication=False
	bOnlyRelevantToOwner=True
	bActive=False
	CheckInterval=0.25f
	HealthThreshold=0.25f

	Name="Default__DKUpgrade_Skill_CloseCall_Helper"
}
