class ZTUpgrade_Skill_Counterforce_Helper extends Info transient;

var KFPawn_Human Player;
var int CurrentStoredDamage;
var bool bOnCooldown;
var const float CooldownDuration;

function PostBeginPlay()
{
	super.PostBeginPlay();

	Player = KFPawn_Human(Owner);
	if (Player == None || Player.Health <= 0)
		Destroy();
}

function StoreDamage(int Amount, int MaxStored)
{
	if (!bOnCooldown)
	{
		CurrentStoredDamage = Min(CurrentStoredDamage + Amount, MaxStored);
	}
}

function ReleaseStoredDamage()
{
	CurrentStoredDamage = 0;
	bOnCooldown = True;
	SetTimer(CooldownDuration, False, nameof(EndCooldown));
	PlayReleaseEffect();
}

function EndCooldown()
{
	if (Player == None || Player.Health <= 0)
	{
		Destroy();
		return;
	}

	bOnCooldown = False;
}

reliable client function PlayReleaseEffect()
{
	local KFPlayerController KFPC;

	KFPC = KFPlayerController(GetALocalPlayerController());
	if (KFPC != None)
		KFPC.SetPerkEffect(True);

	SetTimer(0.5f, False, nameof(ClearReleaseEffect));
}

reliable client function ClearReleaseEffect()
{
	local KFPlayerController KFPC;

	KFPC = KFPlayerController(GetALocalPlayerController());
	if (KFPC != None)
		KFPC.SetPerkEffect(False);
}

defaultproperties
{
	bOnlyRelevantToOwner=True
	CurrentStoredDamage=0
	bOnCooldown=False
	CooldownDuration=10.0f

	Name="Default__ZTUpgrade_Skill_Counterforce_Helper"
}
