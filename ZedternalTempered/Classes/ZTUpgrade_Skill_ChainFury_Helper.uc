class ZTUpgrade_Skill_ChainFury_Helper extends Info transient;

var KFPawn_Human Player;
var int ChainCount;
var repnotify byte RepChainCount;
var const float ChainWindow;

replication
{
	if (Role == Role_Authority && bNetDirty)
		RepChainCount;
}

function PostBeginPlay()
{
	super.PostBeginPlay();

	Player = KFPawn_Human(Owner);
	if (Player == None || Player.Health <= 0)
		Destroy();
}

function RegisterHit()
{
	if (Player == None || Player.Health <= 0)
	{
		Destroy();
		return;
	}

	++ChainCount;
	RepChainCount = byte(Min(ChainCount, 255));
	bForceNetUpdate = True;

	// Reset the chain break timer on every hit
	SetTimer(ChainWindow, False, nameof(ResetChain));
}

function ResetChain()
{
	ChainCount = 0;
	RepChainCount = 0;
	bForceNetUpdate = True;
}

defaultproperties
{
	RemoteRole=ROLE_SimulatedProxy
	bSkipActorPropertyReplication=False
	bOnlyRelevantToOwner=True
	ChainCount=0
	RepChainCount=0
	ChainWindow=2.0f

	Name="Default__ZTUpgrade_Skill_ChainFury_Helper"
}
