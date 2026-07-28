class DKUpgrade_Skill_AdrenalineReload_Helper extends Info
	transient;

var KFPawn_Human Player;
var bool bBoosted;
var float BoostRemaining;

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
}

function ActivateBoost(float Duration)
{
	bBoosted = True;
	BoostRemaining = Duration;

	// Ensure timer is running to decrement boost
	if (!IsTimerActive())
		SetTimer(0.25f, True);

	// Update ground speed to apply the speed boost immediately
	Player.UpdateGroundSpeed();
}

function Timer()
{
	if (Player == None || Player.Health <= 0)
	{
		Destroy();
		return;
	}

	if (bBoosted)
	{
		BoostRemaining -= 0.25f;
		if (BoostRemaining <= 0.0f)
		{
			bBoosted = False;
			BoostRemaining = 0.0f;
			Player.UpdateGroundSpeed();
			ClearTimer();
		}
	}
	else
		ClearTimer();
}

defaultproperties
{
	RemoteRole=ROLE_SimulatedProxy
	bSkipActorPropertyReplication=False

	bBoosted=False
	BoostRemaining=0.0f

	Name="Default__DKUpgrade_Skill_AdrenalineReload_Helper"
}
