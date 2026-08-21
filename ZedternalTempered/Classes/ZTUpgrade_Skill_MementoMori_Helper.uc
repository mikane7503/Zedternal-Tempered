class ZTUpgrade_Skill_MementoMori_Helper extends Info transient;

var int WavesSurvived;

// DK: permanent max health gained from waves survived this life.
// Read by ZTPerk.ModifyHealth so it survives ZR's base recompute;
// resets naturally on death (helper is owned by the pawn).
var int PermanentHealthBonus;

function PostBeginPlay()
{
	super.PostBeginPlay();

	if (Owner == None)
		Destroy();
}

function IncrementWave()
{
	++WavesSurvived;
}

defaultproperties
{
	WavesSurvived=0
	PermanentHealthBonus=0

	Name="Default__ZTUpgrade_Skill_MementoMori_Helper"
}
