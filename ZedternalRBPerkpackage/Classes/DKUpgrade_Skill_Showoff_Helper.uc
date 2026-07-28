class DKUpgrade_Skill_Showoff_Helper extends Info
	transient;

var KFPawn_Human Player;
var byte NearbyZedCount;
var const float CheckInterval;
var const float Radius;

function PostBeginPlay()
{
	super.PostBeginPlay();

	Player = KFPawn_Human(Owner);
	if (Player == None || Player.Health <= 0)
		Destroy();
	else
		SetTimer(CheckInterval, True);
}

function Timer()
{
	local KFPawn_Monster KFM;
	local byte Count;

	if (Player == None || Player.Health <= 0)
	{
		Destroy();
		return;
	}

	Count = 0;
	foreach DynamicActors(class'KFPawn_Monster', KFM)
	{
		if (KFM.IsAliveAndWell() && VSizeSQ(Player.Location - KFM.Location) <= Radius)
			++Count;
	}

	NearbyZedCount = Count;
}

defaultproperties
{
	NearbyZedCount=0
	CheckInterval=0.5f
	Radius=640000

	Name="Default__DKUpgrade_Skill_Showoff_Helper"
}
