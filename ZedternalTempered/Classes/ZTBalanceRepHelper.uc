// ===================================================================
// ZTBalanceRepHelper
//
// Replicated Actor that carries tuned balance values from server INI
// to clients. Spawned once by ZTGameInfo_Endless.InitGame().
//
// Server: Populates Values[] from DKWrapper_* config vars
// Client: Reads Values[] via static GetHelper() accessor
// ===================================================================
class ZTBalanceRepHelper extends ReplicationInfo;

// Balance value storage — replicated to all clients
var float Values[256];

replication
{
	if (bNetDirty)
		Values;
}

simulated event PostBeginPlay()
{
	super.PostBeginPlay();
	`log("[DKBalanceRep] PostBeginPlay on" @ (Role == Role_Authority ? "SERVER" : "CLIENT"));
}

// Find the helper via any Actor's world context
static simulated function ZTBalanceRepHelper GetHelper(Actor Context)
{
	local ZTBalanceRepHelper H;

	if (Context != None)
	{
		foreach Context.DynamicActors(class'ZTBalanceRepHelper', H)
		{
			return H;
		}
	}

	return None;
}

defaultproperties
{
	RemoteRole=ROLE_SimulatedProxy
	bAlwaysRelevant=True
	bSkipActorPropertyReplication=False
	bOnlyRelevantToOwner=False

	Name="Default__ZTBalanceRepHelper"
}
