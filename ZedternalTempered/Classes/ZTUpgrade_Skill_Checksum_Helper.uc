// Checksum helper - stores the wave's rolled buff (0 dmg / 1 speed / 2 reload / 3 resist).
class ZTUpgrade_Skill_Checksum_Helper extends Actor;

var int CurrentBuff;

simulated event PostBeginPlay()
{
	super.PostBeginPlay();
	RollBuff();
}

function RollBuff()
{
	local KFPawn_Human KFPH;
	local string BuffName;

	CurrentBuff = Rand(4);

	KFPH = KFPawn_Human(Owner);
	if (KFPH == None || KFPlayerController(KFPH.Controller) == None)
		return;

	switch (CurrentBuff)
	{
		case 0: BuffName = "DAMAGE"; break;
		case 1: BuffName = "SPEED"; break;
		case 2: BuffName = "RELOAD"; break;
		default: BuffName = "RESISTANCE"; break;
	}

	class'ZTMessageManager'.static.SendMinor(KFPlayerController(KFPH.Controller),
		"Checksum verified:" @ BuffName @ "buff this wave.");
}

defaultproperties
{
	bHidden=True
	RemoteRole=ROLE_None

	Name="Default__ZTUpgrade_Skill_Checksum_Helper"
}
