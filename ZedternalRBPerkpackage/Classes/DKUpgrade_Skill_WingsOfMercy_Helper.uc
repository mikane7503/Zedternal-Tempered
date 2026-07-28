class DKUpgrade_Skill_WingsOfMercy_Helper extends Info
	transient;

var KFPawn_Human Player;
var byte HurtAllyCount;
var const float RadiusSQ, HealthThreshold, Update;
var const byte MaxHurtAllies;

replication
{
	if (Role == Role_Authority && bNetDirty)
		HurtAllyCount;
}

function PostBeginPlay()
{
	super.PostBeginPlay();

	Player = KFPawn_Human(Owner);
	if (Player == None || Player.Health <= 0)
		Destroy();
	else
		SetTimer(Update, True);
}

function Timer()
{
	local KFPawn_Human KFPH;
	local byte Count;

	if (Player == None || Player.Health <= 0)
	{
		Destroy();
		return;
	}

	Count = 0;
	foreach DynamicActors(class'KFPawn_Human', KFPH)
	{
		if (KFPH != Player && KFPH.IsAliveAndWell()
			&& KFPH.GetHealthPercentage() < HealthThreshold
			&& VSizeSQ(Player.Location - KFPH.Location) <= RadiusSQ)
		{
			++Count;
			if (Count >= MaxHurtAllies)
				break;
		}
	}

	if (Count != HurtAllyCount)
	{
		HurtAllyCount = Count;
		Player.UpdateGroundSpeed();
	}
}

defaultproperties
{
	RemoteRole=ROLE_SimulatedProxy
	bSkipActorPropertyReplication=False
	bOnlyRelevantToOwner=True
	HurtAllyCount=0
	RadiusSQ=640000.0f
	HealthThreshold=0.5f
	MaxHurtAllies=3
	Update=1.0f

	Name="Default__DKUpgrade_Skill_WingsOfMercy_Helper"
}
