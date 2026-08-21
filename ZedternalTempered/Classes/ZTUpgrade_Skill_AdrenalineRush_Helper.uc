class ZTUpgrade_Skill_AdrenalineRush_Helper extends Info transient;

var KFPawn_Human Player;
var int CurrentStacks;
var repnotify byte RepStacks;
var bool bDeluxe;
var const float StackDecayInterval;
var const float NormalDecayInterval, DeluxeDecayInterval;

replication
{
	if (Role == Role_Authority && bNetDirty)
		RepStacks;
}

function PostBeginPlay()
{
	super.PostBeginPlay();

	Player = KFPawn_Human(Owner);
	if (Player == None || Player.Health <= 0)
		Destroy();
}

function SetDeluxe(bool bIsDeluxe)
{
	bDeluxe = bIsDeluxe;
}

function AddStack(int MaxStacks)
{
	if (Player == None || Player.Health <= 0)
	{
		Destroy();
		return;
	}

	if (CurrentStacks < MaxStacks)
	{
		++CurrentStacks;
		RepStacks = byte(CurrentStacks);
		bForceNetUpdate = True;
	}

	// Reset or start decay timer
	if (bDeluxe)
		SetTimer(DeluxeDecayInterval, False, nameof(DecayStack));
	else
		SetTimer(NormalDecayInterval, False, nameof(DecayStack));
}

function DecayStack()
{
	if (Player == None || Player.Health <= 0)
	{
		Destroy();
		return;
	}

	if (CurrentStacks > 0)
	{
		--CurrentStacks;
		RepStacks = byte(CurrentStacks);
		bForceNetUpdate = True;

		// Continue decaying remaining stacks
		if (CurrentStacks > 0)
		{
			if (bDeluxe)
				SetTimer(DeluxeDecayInterval, False, nameof(DecayStack));
			else
				SetTimer(NormalDecayInterval, False, nameof(DecayStack));
		}
	}
}

defaultproperties
{
	RemoteRole=ROLE_SimulatedProxy
	bSkipActorPropertyReplication=False
	bOnlyRelevantToOwner=True
	CurrentStacks=0
	RepStacks=0
	bDeluxe=False
	NormalDecayInterval=4.0f
	DeluxeDecayInterval=5.0f

	Name="Default__ZTUpgrade_Skill_AdrenalineRush_Helper"
}
