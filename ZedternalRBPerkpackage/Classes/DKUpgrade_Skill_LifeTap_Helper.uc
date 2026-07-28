// ===================================================================
// DKUpgrade_Skill_LifeTap_Helper
// Periodically reads siphon count from the Parasite perk helper and
// replicates it to the client via a repnotify var. The static
// simulated ModifyHealerRechargeTime in LifeTap finds this helper
// via GetALocalPlayerController and reads ReplicatedSiphonCount.
// ===================================================================
class DKUpgrade_Skill_LifeTap_Helper extends Info
	transient;

var KFPawn_Human Player;
var const float UpdateInterval;

// Replicated to client so ModifyHealerRechargeTime can read it
var int ReplicatedSiphonCount;

replication
{
	if (Role == Role_Authority && bNetDirty)
		ReplicatedSiphonCount;
}

function PostBeginPlay()
{
	super.PostBeginPlay();

	Player = KFPawn_Human(Owner);
	if (Player == None || Player.Health <= 0)
		Destroy();
	else
		SetTimer(UpdateInterval, True, NameOf(UpdateSiphonCache));
}

function UpdateSiphonCache()
{
	local DKUpgrade_Perk_Parasite_Helper ParasiteHelper;

	if (Player == None || Player.Health <= 0)
	{
		ReplicatedSiphonCount = 0;
		Destroy();
		return;
	}

	foreach Player.ChildActors(class'DKUpgrade_Perk_Parasite_Helper', ParasiteHelper)
	{
		ReplicatedSiphonCount = ParasiteHelper.GetSiphonedEnemyCount();
		return;
	}

	// No parasite helper found
	ReplicatedSiphonCount = 0;
}

defaultproperties
{
	RemoteRole=ROLE_SimulatedProxy
	bSkipActorPropertyReplication=False
	bOnlyRelevantToOwner=True
	UpdateInterval=0.5f
	ReplicatedSiphonCount=0

	Name="Default__DKUpgrade_Skill_LifeTap_Helper"
}
