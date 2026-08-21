// ===================================================================
// ZTUpgrade_Skill_BloodShield_Helper
// Manages the Blood Shield state: activation, DR tracking, duration
// timer, and wave-based cooldown.
// ===================================================================
class ZTUpgrade_Skill_BloodShield_Helper extends Info transient;

var bool bShieldActive;
var bool bOnCooldown;
var float CurrentDR;
var KFPawn_Human Player;

replication
{
	if (Role == ROLE_Authority)
		bShieldActive, CurrentDR;
}

function PostBeginPlay()
{
	super.PostBeginPlay();

	Player = KFPawn_Human(Owner);
	if (Player == None || Player.Health <= 0)
		Destroy();
}

function ActivateShield(float DR, float Duration)
{
	bShieldActive = True;
	bOnCooldown = True;
	CurrentDR = DR;
	bForceNetUpdate = True;

	SetTimer(Duration, False, NameOf(DeactivateShield));

	// Visual/audio feedback
	NotifyShieldActivated();
}

function DeactivateShield()
{
	if (Owner == None)
	{
		Destroy();
		return;
	}

	bShieldActive = False;
	CurrentDR = 0.0f;
	bForceNetUpdate = True;

	NotifyShieldDeactivated();
}

function ResetCooldown()
{
	bOnCooldown = False;
}

reliable client function NotifyShieldActivated()
{
	local PlayerController PC;

	PC = GetALocalPlayerController();
	if (KFPlayerController(PC) != None)
		KFPlayerController(PC).SetPerkEffect(True);
}

reliable client function NotifyShieldDeactivated()
{
	local PlayerController PC;

	PC = GetALocalPlayerController();
	if (KFPlayerController(PC) != None)
		KFPlayerController(PC).SetPerkEffect(False);
}

defaultproperties
{
	bOnlyRelevantToOwner=True
	bShieldActive=False
	bOnCooldown=False
	CurrentDR=0.0f

	Name="Default__ZTUpgrade_Skill_BloodShield_Helper"
}
