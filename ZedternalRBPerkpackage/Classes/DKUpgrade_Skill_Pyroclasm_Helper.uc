class DKUpgrade_Skill_Pyroclasm_Helper extends Info
	transient;

// Pyroclasm Helper: Manages cooldown-based damage buff charge
// When Timer fires, bEnable becomes true (charge ready)
// ConsumeCharge sets bEnable false and restarts cooldown

var KFPawn_Human Player;
var bool bEnable;
var array<float> Cooldown;
var byte UpgLevel;

replication
{
	if (Role == Role_Authority && bNetDirty)
		bEnable;
}

function PostBeginPlay()
{
	super.PostBeginPlay();

	Player = KFPawn_Human(Owner);
	if (Player == None || Player.Health <= 0)
		Destroy();
}

function StartTimer(bool bDeluxe)
{
	if (bDeluxe)
		UpgLevel = 2;
	else
		UpgLevel = 1;

	// Start first cooldown
	SetTimer(Cooldown[UpgLevel - 1], False);
}

function Timer()
{
	if (Player == None || Player.Health <= 0)
	{
		Destroy();
		return;
	}

	// Charge is ready
	if (!bEnable)
	{
		bEnable = True;
		ActiveEffect();
	}
}

function ConsumeCharge()
{
	if (bEnable)
	{
		bEnable = False;
		ResetEffect();
		// Restart cooldown
		SetTimer(Cooldown[UpgLevel - 1], False);
	}
}

function EndWaveReset()
{
	ClearTimer();
	ResetEffect();
	bEnable = False;
	SetTimer(Cooldown[UpgLevel - 1], False);
}

reliable client function ActiveEffect()
{
	local KFPlayerController KFPC;

	KFPC = KFPlayerController(GetALocalPlayerController());
	if (KFPC != None)
		KFPC.SetPerkEffect(True);
}

reliable client function ResetEffect()
{
	local KFPlayerController KFPC;

	KFPC = KFPlayerController(GetALocalPlayerController());
	if (KFPC != None)
		KFPC.SetPerkEffect(False);
}

defaultproperties
{
	RemoteRole=ROLE_SimulatedProxy
	bSkipActorPropertyReplication=False
	bOnlyRelevantToOwner=True
	bEnable=False
	UpgLevel=1
	Cooldown(0)=30.0f
	Cooldown(1)=18.0f

	Name="Default__DKUpgrade_Skill_Pyroclasm_Helper"
}
