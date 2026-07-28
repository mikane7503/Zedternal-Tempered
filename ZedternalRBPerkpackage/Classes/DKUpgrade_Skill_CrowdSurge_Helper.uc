class DKUpgrade_Skill_CrowdSurge_Helper extends Info
	transient;

var KFPawn_Human Player;
var int CurrentStacks;
var repnotify byte RepStacks;
var array<float> StackExpireTimes;
var const float PollInterval;

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

function AddStack(int MaxStacks, float Duration)
{
	if (Player == None || Player.Health <= 0)
	{
		Destroy();
		return;
	}

	if (CurrentStacks < MaxStacks)
	{
		++CurrentStacks;
		StackExpireTimes.AddItem(WorldInfo.TimeSeconds + Duration);
		UpdateRep();
	}
	else
	{
		// At max, refresh oldest stack
		if (StackExpireTimes.Length > 0)
			StackExpireTimes[0] = WorldInfo.TimeSeconds + Duration;
	}

	// Ensure decay poll is running
	if (!IsTimerActive(nameof(CheckDecay)))
		SetTimer(PollInterval, True, nameof(CheckDecay));
}

function CheckDecay()
{
	local bool bChanged;
	local float CurrentTime;

	if (Player == None || Player.Health <= 0)
	{
		Destroy();
		return;
	}

	bChanged = False;
	CurrentTime = WorldInfo.TimeSeconds;

	// Remove expired stacks (oldest are at the front)
	while (StackExpireTimes.Length > 0 && StackExpireTimes[0] <= CurrentTime)
	{
		StackExpireTimes.Remove(0, 1);
		--CurrentStacks;
		bChanged = True;
	}

	if (CurrentStacks < 0)
		CurrentStacks = 0;

	if (bChanged)
		UpdateRep();

	// Stop polling if no stacks
	if (CurrentStacks <= 0)
		ClearTimer(nameof(CheckDecay));
}

function UpdateRep()
{
	RepStacks = byte(CurrentStacks);
	bForceNetUpdate = True;
}

defaultproperties
{
	RemoteRole=ROLE_SimulatedProxy
	bSkipActorPropertyReplication=False
	bOnlyRelevantToOwner=True
	CurrentStacks=0
	RepStacks=0
	PollInterval=0.5f

	Name="Default__DKUpgrade_Skill_CrowdSurge_Helper"
}
