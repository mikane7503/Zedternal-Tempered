// Ascension Medical Injection helper: Deluxe doubles healing frequency.
class ZUTUpgrade_Skill_MedicalInjection_Helper extends Info transient;

var KFPawn_Human Player;
var byte DeluxeLevel;
var const byte MinHealth, Regen;
var const array<float> MaxRegenDelay, MinRegenDelay;

function PostBeginPlay()
{
	Super.PostBeginPlay();
	Player = KFPawn_Human(Owner);
	if (Player == None || Player.Health <= 0)
		Destroy();
}

function StartTimer(bool bDeluxe)
{
	DeluxeLevel = bDeluxe ? 1 : 0;
	SetTimer(MinRegenDelay[DeluxeLevel], False);
}

function Timer()
{
	if (Player == None || Player.Health <= 0)
	{
		Destroy();
		return;
	}

	if (Player.Health < MinHealth)
		Player.HealDamage(Regen, KFPlayerController(Player.Controller), class'KFDT_Healing', False, False);

	if (Player.Health < MinHealth)
		SetTimer(MinRegenDelay[DeluxeLevel] + Player.Health *
			(MaxRegenDelay[DeluxeLevel] - MinRegenDelay[DeluxeLevel]) / float(MinHealth), False);
	else
		SetTimer(MinRegenDelay[DeluxeLevel], False);
}

defaultproperties
{
	MinHealth=50
	Regen=1
	MaxRegenDelay(0)=1.50f
	MaxRegenDelay(1)=0.75f
	MinRegenDelay(0)=0.333333f
	MinRegenDelay(1)=0.166667f
	Name="Default__ZUTUpgrade_Skill_MedicalInjection_Helper"
}
