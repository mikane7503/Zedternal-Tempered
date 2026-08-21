class ZTUpgrade_Skill_Flashpoint_Helper extends Info transient;

var KFPawn_Human Player;
var bool bDeluxe, bReady;

var const class<KFDamageType> FireDT;
var const float BaseDelay, DeluxeDelay;
var const int BaseDamage, DeluxeDamage;
var const float BaseRadiusSQ, DeluxeRadiusSQ;

function PostBeginPlay()
{
	super.PostBeginPlay();

	Player = KFPawn_Human(Owner);
	if (Player == None || Player.Health <= 0)
		Destroy();
}

function FireNova()
{
	local KFPawn_Monster KFPM;
	local float RadSQ;
	local int Dmg;
	local KFPlayerController KFPC;

	bReady = False;

	if (Player == None || Player.Controller == None)
		return;

	KFPC = KFPlayerController(Player.Controller);
	if (KFPC == None)
		return;

	RadSQ = bDeluxe ? DeluxeRadiusSQ : BaseRadiusSQ;
	Dmg = bDeluxe ? DeluxeDamage : BaseDamage;

	foreach DynamicActors(class'KFPawn_Monster', KFPM)
	{
		if (KFPM != None && KFPM.IsAliveAndWell() && VSizeSQ(Player.Location - KFPM.Location) <= RadSQ)
		{
			KFPM.ApplyDamageOverTime(Dmg, KFPC, default.FireDT);
		}
	}

	SetTimer(bDeluxe ? DeluxeDelay : BaseDelay, False, nameof(ResetFlashpoint));
}

function ResetFlashpoint()
{
	if (Player == None || Player.Health <= 0)
		Destroy();
	else
		bReady = True;
}

defaultproperties
{
	bOnlyRelevantToOwner=True
	bDeluxe=False
	bReady=True

	FireDT=class'ZedternalTempered.ZTDT_Thermite'

	BaseDelay=30.0f
	DeluxeDelay=20.0f
	BaseDamage=20
	DeluxeDamage=35
	BaseRadiusSQ=250000
	DeluxeRadiusSQ=640000

	Name="Default__ZTUpgrade_Skill_Flashpoint_Helper"
}
