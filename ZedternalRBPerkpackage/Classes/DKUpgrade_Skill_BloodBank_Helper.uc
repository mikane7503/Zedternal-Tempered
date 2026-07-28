// ===================================================================
// DKUpgrade_Skill_BloodBank_Helper
// Tracks stored blood amount for the Blood Bank skill.
// Stored blood is built by kills and consumed when taking damage.
// ===================================================================
class DKUpgrade_Skill_BloodBank_Helper extends Info
	transient;

var int StoredBlood;
var KFPawn_Human Player;

replication
{
	if (Role == ROLE_Authority)
		StoredBlood;
}

function PostBeginPlay()
{
	super.PostBeginPlay();

	Player = KFPawn_Human(Owner);
	if (Player == None || Player.Health <= 0)
		Destroy();
}

function AddStoredBlood(int Amount, int MaxBlood)
{
	StoredBlood = Min(StoredBlood + Amount, MaxBlood);
	bForceNetUpdate = True;
}

function ConsumeStoredBlood(int Amount)
{
	StoredBlood = Max(0, StoredBlood - Amount);
	bForceNetUpdate = True;
}

defaultproperties
{
	bOnlyRelevantToOwner=True
	StoredBlood=0

	Name="Default__DKUpgrade_Skill_BloodBank_Helper"
}
