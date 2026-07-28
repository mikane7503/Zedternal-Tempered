class DKUpgrade_Skill_DeadeyeMomentum_Helper extends Info
	transient;

var byte Streak;
var const byte MaxStreak;
var const float DecreaseDelayTimer, ResetDelayTimer;
var const name RhytmMethodRTPCName;
var const AkEvent RhythmMethodSoundReset;
var const AkEvent RhythmMethodSoundHit;
var const AkEvent RhythmMethodSoundTop;

function PostBeginPlay()
{
	super.PostBeginPlay();

	if (Owner == None)
		Destroy();
}

function Timer()
{
	if (Owner == None)
	{
		Destroy();
		return;
	}

	if (Streak > 0)
	{
		DecreaseCounter();
		if (Streak > 0)
			SetTimer(DecreaseDelayTimer, False);
	}
}

function IncreaseCounter()
{
	ClearTimer();

	if (Streak < MaxStreak)
		++Streak;

	StreakMessage(Streak, Min(MaxStreak, Streak), False, Streak >= MaxStreak);
	SetTimer(ResetDelayTimer, False);
}

function DecreaseCounter()
{
	--Streak;
	StreakMessage(Streak, Streak, True, False);
}

function ResetCounter()
{
	ClearTimer();
	if (Streak > 0)
	{
		Streak = 0;
		StreakMessage(0, 0, False, False);
	}
}

reliable client function StreakMessage(byte StreakNum, byte DisplayValue, optional bool bDecayed, optional bool bMaxStreak)
{
	local AkEvent TempAkEvent;
	local KFPlayerController KFPC;

	KFPC = KFPlayerController(GetALocalPlayerController());

	if (KFPC == None || KFPC.MyGFxHUD == None)
		return;

	KFPC.UpdateRhythmCounterWidget(DisplayValue, MaxStreak);

	if (bMaxStreak)
		TempAkEvent = RhythmMethodSoundTop;
	else if (!bDecayed && StreakNum > 0)
		TempAkEvent = RhythmMethodSoundHit;
	else if (StreakNum == 0)
		TempAkEvent = RhythmMethodSoundReset;

	if (TempAkEvent != None)
		KFPC.PlayRMEffect(TempAkEvent, RhytmMethodRTPCName, StreakNum);
}

defaultproperties
{
	Streak=0
	MaxStreak=5
	DecreaseDelayTimer=1.5f
	ResetDelayTimer=5.0f

	RhytmMethodRTPCName="R_Method"
	RhythmMethodSoundReset=AkEvent'WW_UI_PlayerCharacter.Play_R_Method_Reset'
	RhythmMethodSoundHit=AkEvent'WW_UI_PlayerCharacter.Play_R_Method_Hit'
	RhythmMethodSoundTop=AkEvent'WW_UI_PlayerCharacter.Play_R_Method_Top'

	Name="Default__DKUpgrade_Skill_DeadeyeMomentum_Helper"
}
