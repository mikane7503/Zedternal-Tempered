class ZTUpgrade_Skill_SoulChain_Helper extends Info transient;

var int CurrentStacks;
var const float ResetDelay;

function PostBeginPlay()
{
	super.PostBeginPlay();

	if (Owner == None)
		Destroy();
}

function AddStack(int InMaxStacks)
{
	ClearTimer(NameOf(ResetStacks));
	CurrentStacks = Min(CurrentStacks + 1, InMaxStacks);
	SetTimer(ResetDelay, False, NameOf(ResetStacks));
}

function ResetStacks()
{
	if (Owner == None)
		Destroy();
	else
		CurrentStacks = 0;
}

defaultproperties
{
	CurrentStacks=0
	ResetDelay=5.0f

	Name="Default__ZTUpgrade_Skill_SoulChain_Helper"
}
