class ZUTUpgrade_Skill_AirborneAgent_Helper extends Info transient;

var KFPawn_Human Player;
var bool bDeluxe;
var int ActivationsThisWave;
var const int CriticalHealth, RadiusSQ;
var const float Recharge, Update;

function PostBeginPlay()
{
	super.PostBeginPlay();
	Player = KFPawn_Human(Owner);
	if (Player == None || Player.Health <= 0)
		Destroy();
	else
		SetTimer(Update, False);
}

function int GetWaveLimit()
{
	return bDeluxe ? 2 : 1;
}

function ResetForWave()
{
	ActivationsThisWave = 0;
	if (Player != None && Player.Health > 0)
		SetTimer(Update, False);
}

function Timer()
{
	local KFPawn_Human KFPH;
	local bool bActivate;

	if (Player == None || Player.Health <= 0)
	{
		Destroy();
		return;
	}
	if (ActivationsThisWave >= GetWaveLimit())
		return;

	bActivate = Player.Health <= CriticalHealth;
	if (!bActivate)
	{
		foreach DynamicActors(class'KFPawn_Human', KFPH)
		{
			if (KFPH.Health <= CriticalHealth && KFPH.Health > 0
				&& VSizeSQ(Player.Location - KFPH.Location) <= RadiusSQ)
			{
				bActivate = True;
				break;
			}
		}
	}

	if (!bActivate)
	{
		SetTimer(Update, False);
		return;
	}

	++ActivationsThisWave;
	Player.StartAirBorneAgentEvent();
	Spawn(class'ZedternalReborn.WMFX_AirborneAgent', , , Player.Location, Player.Rotation, , True);
	if (bDeluxe)
	{
		Player.HealDamage(35, Player.Controller, class'KFGameContent.KFDT_Healing_MedicGrenade');
		foreach DynamicActors(class'KFPawn_Human', KFPH)
			if (KFPH != Player && VSizeSQ(Player.Location - KFPH.Location) <= RadiusSQ)
				KFPH.HealDamage(20, Player.Controller, class'KFGameContent.KFDT_Healing_MedicGrenade');
	}
	else
		Player.HealDamage(15, Player.Controller, class'KFGameContent.KFDT_Healing_MedicGrenade');

	if (ActivationsThisWave < GetWaveLimit())
		SetTimer(Recharge, False);
}

defaultproperties
{
	bDeluxe=False
	CriticalHealth=60
	RadiusSQ=160000
	Recharge=40.0f
	Update=0.5f
	Name="Default__ZUTUpgrade_Skill_AirborneAgent_Helper"
}
