class ZTUpgrade_Skill_Mimicry_Helper extends Info transient;

var bool bShieldActive;

function PostBeginPlay()
{
	super.PostBeginPlay();

	if (Owner == None)
		Destroy();
}

function StartRecharge(float RechargeTime)
{
	bShieldActive = False;
	SetTimer(RechargeTime, False);
}

function ConsumeShield(float RechargeTime)
{
	bShieldActive = False;

	// Begin recharging
	SetTimer(RechargeTime, False);
}

function ResetRecharge(float RechargeTime)
{
	// Taking damage resets the recharge timer
	if (!bShieldActive)
		SetTimer(RechargeTime, False);
}

function Timer()
{
	if (Owner == None)
	{
		Destroy();
		return;
	}

	// Shield recharged
	bShieldActive = True;
}

defaultproperties
{
	bShieldActive=False

	Name="Default__ZTUpgrade_Skill_Mimicry_Helper"
}
