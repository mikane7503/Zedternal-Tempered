class DKUpgrade_Skill_LastBreath_Helper extends Info
	transient;

var bool bBuffActive;
var bool bUsedThisWave;

function PostBeginPlay()
{
	super.PostBeginPlay();

	if (Owner == None)
		Destroy();
}

function ActivateBuff(float Duration)
{
	bBuffActive = True;
	bUsedThisWave = True;
	ClearTimer(NameOf(DeactivateBuff));
	SetTimer(Duration, False, NameOf(DeactivateBuff));
}

function DeactivateBuff()
{
	if (Owner == None)
		Destroy();
	else
		bBuffActive = False;
}

function ResetForNewWave()
{
	bUsedThisWave = False;
	bBuffActive = False;
	ClearTimer(NameOf(DeactivateBuff));
}

defaultproperties
{
	bBuffActive=False
	bUsedThisWave=False

	Name="Default__DKUpgrade_Skill_LastBreath_Helper"
}
