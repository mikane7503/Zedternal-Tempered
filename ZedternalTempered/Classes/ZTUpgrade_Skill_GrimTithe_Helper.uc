class ZTUpgrade_Skill_GrimTithe_Helper extends Info transient;

var int WaveKills;

function PostBeginPlay()
{
	super.PostBeginPlay();

	if (Owner == None)
		Destroy();
}

function AddKill()
{
	++WaveKills;
}

function ResetKills()
{
	WaveKills = 0;
}

defaultproperties
{
	WaveKills=0

	Name="Default__ZTUpgrade_Skill_GrimTithe_Helper"
}
