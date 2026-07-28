class DKUpgrade_Skill_HoldTheLine_Helper extends Info
	transient;

var KFPawn_Human Player;
var bool bHolding;
var bool bDeluxe;
var const float NormalVelocityThreshold;    // Must be nearly still
var const float DeluxeVelocityThreshold;    // Can move slowly
var const float UpdateInterval;

function PostBeginPlay()
{
	super.PostBeginPlay();

	Player = KFPawn_Human(Owner);
	if (Player == None || Player.Health <= 0)
		Destroy();
	else
		SetTimer(UpdateInterval, True);
}

function SetDeluxe(bool bIsDeluxe)
{
	bDeluxe = bIsDeluxe;
}

function Timer()
{
	local float Threshold;

	if (Player == None || Player.Health <= 0)
	{
		Destroy();
		return;
	}

	if (bDeluxe)
		Threshold = DeluxeVelocityThreshold;
	else
		Threshold = NormalVelocityThreshold;

	bHolding = (VSize(Player.Velocity) <= Threshold);
}

defaultproperties
{
	bOnlyRelevantToOwner=True
	bHolding=False
	bDeluxe=False
	NormalVelocityThreshold=30.0f       // Nearly stationary
	DeluxeVelocityThreshold=100.0f      // Slow walking allowed
	UpdateInterval=0.25f

	Name="Default__DKUpgrade_Skill_HoldTheLine_Helper"
}
