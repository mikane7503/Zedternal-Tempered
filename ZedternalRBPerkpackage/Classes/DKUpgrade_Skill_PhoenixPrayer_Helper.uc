class DKUpgrade_Skill_PhoenixPrayer_Helper extends Info;

var int HealthCounter;

function PostBeginPlay()
{
	super.PostBeginPlay();

	if (Owner == None)
		Destroy();
}

function AddHealedHealth(int InHealth)
{
	HealthCounter += InHealth;
}

defaultproperties
{
	HealthCounter=0

	Name="Default__DKUpgrade_Skill_PhoenixPrayer_Helper"
}
