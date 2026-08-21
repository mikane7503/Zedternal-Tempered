// Trophy Case helper - per-wave armor stack bookkeeping for the owner.
class ZTUpgrade_Skill_TrophyCase_Helper extends Actor;

var int StacksGranted;

function AddStacks(int Amount, int MaxStacks)
{
	local KFPawn_Human KFPH;
	local int Grant;

	KFPH = KFPawn_Human(Owner);
	if (KFPH == None || KFPH.Health <= 0)
		return;

	Grant = Min(Amount, MaxStacks - StacksGranted);
	if (Grant <= 0)
		return;

	StacksGranted += Grant;
	KFPH.Armor = Min(KFPH.MaxArmor, KFPH.Armor + Grant);
}

function ResetStacks()
{
	StacksGranted = 0;
}

defaultproperties
{
	bHidden=True
	RemoteRole=ROLE_None

	Name="Default__ZTUpgrade_Skill_TrophyCase_Helper"
}
