class ZTUpgrade_Skill_WingsOfMercy_Helper extends Info transient;

var KFPawn_Human Player;
var byte HurtAllyCount;
var const float Update;

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
		// Thresholds are config-driven:
		// [ZedternalTempered.ZTUpgrade_Skill_WingsOfMercy]
		// AllyRadiusSQ / HealthThreshold / MaxHurtAllies
		if (KFPH != Player && KFPH.IsAliveAndWell()
			&& KFPH.GetHealthPercentage() < class'ZTUpgrade_Skill_WingsOfMercy'.default.HealthThreshold
			&& VSizeSQ(Player.Location - KFPH.Location) <= class'ZTUpgrade_Skill_WingsOfMercy'.default.AllyRadiusSQ)
		{
			++Count;
			if (Count >= class'ZTUpgrade_Skill_WingsOfMercy'.default.MaxHurtAllies)
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
	Update=1.0f

	Name="Default__ZTUpgrade_Skill_WingsOfMercy_Helper"
}
