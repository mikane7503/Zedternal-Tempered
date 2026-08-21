class ZTUpgrade_Skill_JuryRig_Helper extends Info transient;

var KFPawn_Human Player;
var KFWeapon LastWeapon;
var int RemainingBonusShots;
var float LastBonusShotTime;

function PostBeginPlay()
{
	super.PostBeginPlay();

	Player = KFPawn_Human(Owner);
	if (Player == None || Player.Health <= 0)
		Destroy();
}

defaultproperties
{
	RemainingBonusShots=0
	LastBonusShotTime=0.0f

	Name="Default__ZTUpgrade_Skill_JuryRig_Helper"
}
