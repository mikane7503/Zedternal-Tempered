class DKUpgrade_Skill_DeathChill_Helper extends Info
	transient;

var int KillCount;
var const float DecayTime;

function PostBeginPlay()
{
	super.PostBeginPlay();

	if (Owner == None)
		Destroy();
}

function AddKill()
{
	++KillCount;

	// Reset decay timer on each kill
	SetTimer(DecayTime, False);
}

function ResetKills()
{
	KillCount = 0;
	ClearTimer();
}

function Timer()
{
	if (Owner == None)
	{
		Destroy();
		return;
	}

	// Decay one kill stack
	if (KillCount > 0)
	{
		--KillCount;

		// If still stacks remaining, keep decaying
		if (KillCount > 0)
			SetTimer(DecayTime, False);
	}
}

defaultproperties
{
	KillCount=0
	DecayTime=8.0f

	Name="Default__DKUpgrade_Skill_DeathChill_Helper"
}
