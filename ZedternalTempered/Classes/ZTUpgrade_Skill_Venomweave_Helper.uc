// Helper for Venomweave.
// Periodically counts nearby poisoned ZEDs.
// The count is used by the main skill class for damage reduction.
class ZTUpgrade_Skill_Venomweave_Helper extends Info transient;

var KFPawn_Human Player;
var bool bDeluxe;
var int PoisonedCount;
var const float Update;
var const array<int> Radius, MaxStacks;

function PostBeginPlay()
{
	super.PostBeginPlay();

	Player = KFPawn_Human(Owner);
	if (Player == None || Player.Health <= 0)
		Destroy();
	else
		SetTimer(Update, True);
}

function Timer()
{
	local KFPawn_Monster KFM;
	local int Count, Rad, Cap;

	if (Player == None || Player.Health <= 0)
	{
		Destroy();
		return;
	}

	if (bDeluxe)
	{
		Rad = default.Radius[1];
		Cap = default.MaxStacks[1];
	}
	else
	{
		Rad = default.Radius[0];
		Cap = default.MaxStacks[0];
	}

	Count = 0;
	foreach DynamicActors(class'KFPawn_Monster', KFM)
	{
		if (KFM.IsAliveAndWell() && (KFM.bIsPoisoned || ZedHasToxicDoT(KFM)) && VSizeSQ(Player.Location - KFM.Location) <= Rad)
		{
			Count++;
			if (Count >= Cap)
				break;
		}
	}

	PoisonedCount = Count;
}

// bIsPoisoned is the toxic affliction flag, which a light DoT may never
// trigger; scan the zed's active DoTs for a KFDT_Toxic entry so the poisoned
// count reflects real poison damage (matches Necrosis / Putrefaction).
static function bool ZedHasToxicDoT(KFPawn_Monster M)
{
	local int i;

	if (M == None)
		return false;

	for (i = 0; i < M.DamageOverTimeArray.Length; ++i)
	{
		if (M.DamageOverTimeArray[i].DamageType != None
			&& ClassIsChildOf(M.DamageOverTimeArray[i].DamageType, class'KFDT_Toxic'))
			return true;
	}

	return false;
}

defaultproperties
{
	bDeluxe=False
	PoisonedCount=0
	Update=0.5f

	// Radius squared: (500uu)^2 = 250000, (700uu)^2 = 490000
	Radius(0)=250000
	Radius(1)=490000

	MaxStacks(0)=6
	MaxStacks(1)=10

	Name="Default__ZTUpgrade_Skill_Venomweave_Helper"
}
