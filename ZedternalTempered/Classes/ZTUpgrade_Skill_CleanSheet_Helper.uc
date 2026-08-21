// Clean Sheet helper - last-hit timestamp store.
class ZTUpgrade_Skill_CleanSheet_Helper extends Actor;

var float LastHitTime;

simulated event PostBeginPlay()
{
	super.PostBeginPlay();
	LastHitTime = WorldInfo.TimeSeconds;
}

defaultproperties
{
	bHidden=True
	RemoteRole=ROLE_None

	Name="Default__ZTUpgrade_Skill_CleanSheet_Helper"
}
