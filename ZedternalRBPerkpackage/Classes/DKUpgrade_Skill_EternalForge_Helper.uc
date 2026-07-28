class DKUpgrade_Skill_EternalForge_Helper extends Info
	transient;

// Eternal Forge Helper: Tracks stacking damage bonus across waves
// DamageBonus accumulates each wave end, applied as a multiplier in ModifyDamageGiven

var KFPawn_Human Player;
var float DamageBonus;
var array<float> BonusPerWave;

replication
{
	if (Role == Role_Authority && bNetDirty)
		DamageBonus;
}

function PostBeginPlay()
{
	super.PostBeginPlay();

	Player = KFPawn_Human(Owner);
	if (Player == None || Player.Health <= 0)
		Destroy();
}

function AddStack(bool bDeluxe)
{
	if (Player == None || Player.Health <= 0)
	{
		Destroy();
		return;
	}

	if (bDeluxe)
		DamageBonus += BonusPerWave[1];
	else
		DamageBonus += BonusPerWave[0];
}

defaultproperties
{
	RemoteRole=ROLE_SimulatedProxy
	bSkipActorPropertyReplication=False
	bOnlyRelevantToOwner=True
	DamageBonus=0.0f
	BonusPerWave(0)=0.01f
	BonusPerWave(1)=0.02f

	Name="Default__DKUpgrade_Skill_EternalForge_Helper"
}
