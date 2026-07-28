class DKUpgrade_Skill_RavenousStrikes_Helper extends Info
	transient;

var bool bBuffActive;
var const float BuffDuration;

function PostBeginPlay()
{
	super.PostBeginPlay();

	if (Owner == None)
		Destroy();
}

function ActivateBuff()
{
	bBuffActive = True;
	SetTimer(BuffDuration, False);
}

function ConsumeBuff()
{
	bBuffActive = False;
	ClearTimer();
}

function Timer()
{
	if (Owner == None)
	{
		Destroy();
		return;
	}

	// Buff expired
	bBuffActive = False;
}

defaultproperties
{
	bBuffActive=False
	BuffDuration=5.0f

	Name="Default__DKUpgrade_Skill_RavenousStrikes_Helper"
}
