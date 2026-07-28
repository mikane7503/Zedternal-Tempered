class DKUpgrade_Skill_BatteringRam_Helper extends Info
	transient;

var KFPawn_Human Player;
var bool bChargeReady;
var bool bWasSprinting;
var bool bDeluxe;
var const float NormalWindow, DeluxeWindow;
var const float PollInterval;

function PostBeginPlay()
{
	super.PostBeginPlay();

	Player = KFPawn_Human(Owner);
	if (Player == None || Player.Health <= 0)
		Destroy();
}

function StartTimer(bool bIsDeluxe)
{
	bDeluxe = bIsDeluxe;
	SetTimer(PollInterval, True);
}

function Timer()
{
	if (Player == None || Player.Health <= 0)
	{
		Destroy();
		return;
	}

	if (Player.bIsSprinting)
	{
		bWasSprinting = True;
	}
	else if (bWasSprinting)
	{
		// Just stopped sprinting - activate charge window
		bWasSprinting = False;
		bChargeReady = True;

		if (bDeluxe)
			SetTimer(DeluxeWindow, False, nameof(ExpireCharge));
		else
			SetTimer(NormalWindow, False, nameof(ExpireCharge));
	}
}

function ConsumeCharge()
{
	bChargeReady = False;
	ClearTimer(nameof(ExpireCharge));
	PlayChargeEffect();
}

function ExpireCharge()
{
	bChargeReady = False;
}

reliable client function PlayChargeEffect()
{
	local KFPlayerController KFPC;

	KFPC = KFPlayerController(GetALocalPlayerController());
	if (KFPC != None)
	{
		KFPC.SetPerkEffect(True);
		SetTimer(0.4f, False, nameof(ClearChargeEffect));
	}
}

reliable client function ClearChargeEffect()
{
	local KFPlayerController KFPC;

	KFPC = KFPlayerController(GetALocalPlayerController());
	if (KFPC != None)
		KFPC.SetPerkEffect(False);
}

defaultproperties
{
	bOnlyRelevantToOwner=True
	bChargeReady=False
	bWasSprinting=False
	bDeluxe=False
	NormalWindow=1.0f
	DeluxeWindow=1.5f
	PollInterval=0.1f

	Name="Default__DKUpgrade_Skill_BatteringRam_Helper"
}
