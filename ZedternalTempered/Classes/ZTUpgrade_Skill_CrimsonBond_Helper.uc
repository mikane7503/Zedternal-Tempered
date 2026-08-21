// ===================================================================
// ZTUpgrade_Skill_CrimsonBond_Helper
// Tracks the blood bond state: which ally is bonded and for how long.
// New heals refresh the bond and can switch the bonded target.
// ===================================================================
class ZTUpgrade_Skill_CrimsonBond_Helper extends Info transient;

var KFPawn_Human Player;
var KFPawn_Human BondedAlly;
var bool bBondActive;

replication
{
	if (Role == ROLE_Authority)
		bBondActive;
}

function PostBeginPlay()
{
	super.PostBeginPlay();

	Player = KFPawn_Human(Owner);
	if (Player == None || Player.Health <= 0)
		Destroy();
}

function EstablishBond(KFPawn_Human Ally, float Duration)
{
	if (Ally == None || Ally.Health <= 0)
		return;

	BondedAlly = Ally;
	bBondActive = True;
	bForceNetUpdate = True;

	// Reset/set bond expiration timer
	ClearTimer(NameOf(ExpireBond));
	SetTimer(Duration, False, NameOf(ExpireBond));
}

function ExpireBond()
{
	bBondActive = False;
	BondedAlly = None;
	bForceNetUpdate = True;
}

defaultproperties
{
	bOnlyRelevantToOwner=True
	bBondActive=False

	Name="Default__ZTUpgrade_Skill_CrimsonBond_Helper"
}
