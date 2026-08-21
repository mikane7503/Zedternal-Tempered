// ===================================================================
// ZTUpgrade_Skill_LeechField_Helper
// Monitors player movement. After being stationary for the delay,
// activates a damage aura that hurts nearby enemies and heals the
// player. Moving cancels the field immediately.
// ===================================================================
class ZTUpgrade_Skill_LeechField_Helper extends Info transient;

var KFPawn_Human Player;

// Config (set by skill on spawn)
var float FieldRadius;
var int DamagePerTick;
var float HealPercent;
var float StationaryDelay;

// State
var vector LastPosition;
var float StationaryTime;
var bool bFieldActive;
var const float CheckInterval;
var const float MovementThreshold;

replication
{
	if (Role == ROLE_Authority)
		bFieldActive;
}

function PostBeginPlay()
{
	super.PostBeginPlay();

	Player = KFPawn_Human(Owner);
	if (Player == None || Player.Health <= 0)
	{
		Destroy();
		return;
	}

	LastPosition = Player.Location;
	SetTimer(CheckInterval, True, NameOf(CheckMovement));
}

function CheckMovement()
{
	local float DistMoved;

	if (Player == None || Player.Health <= 0)
	{
		Destroy();
		return;
	}

	DistMoved = VSize(Player.Location - LastPosition);
	LastPosition = Player.Location;

	if (DistMoved <= MovementThreshold)
	{
		// Player is stationary
		StationaryTime += CheckInterval;

		if (!bFieldActive && StationaryTime >= StationaryDelay)
		{
			bFieldActive = True;
			bForceNetUpdate = True;
			NotifyFieldActivated();
		}

		// Apply aura damage if field is active
		if (bFieldActive)
			ApplyFieldDamage();
	}
	else
	{
		// Player moved
		StationaryTime = 0.0f;

		if (bFieldActive)
		{
			bFieldActive = False;
			bForceNetUpdate = True;
			NotifyFieldDeactivated();
		}
	}
}

function ApplyFieldDamage()
{
	local KFPawn_Monster KFPM;
	local float RadiusSq;
	local int TotalDamageDealt;
	local int HealAmount;

	RadiusSq = FieldRadius ** 2;
	TotalDamageDealt = 0;

	foreach Player.WorldInfo.AllPawns(class'KFPawn_Monster', KFPM)
	{
		if (KFPM.Health <= 0 || !KFPM.IsAliveAndWell())
			continue;

		if (VSizeSq(KFPM.Location - Player.Location) <= RadiusSq)
		{
			KFPM.TakeDamage(DamagePerTick, Player.Controller, KFPM.Location, vect(0,0,0), class'KFDT_Bleeding');
			TotalDamageDealt += DamagePerTick;
		}
	}

	// Heal player based on total damage dealt
	if (TotalDamageDealt > 0)
	{
		HealAmount = Max(1, Round(float(TotalDamageDealt) * HealPercent));
		Player.HealDamage(HealAmount, Player.Controller, class'KFDT_Healing');
	}
}

reliable client function NotifyFieldActivated()
{
	local PlayerController PC;

	PC = GetALocalPlayerController();
	if (KFPlayerController(PC) != None)
		KFPlayerController(PC).SetPerkEffect(True);
}

reliable client function NotifyFieldDeactivated()
{
	local PlayerController PC;

	PC = GetALocalPlayerController();
	if (KFPlayerController(PC) != None)
		KFPlayerController(PC).SetPerkEffect(False);
}

defaultproperties
{
	bOnlyRelevantToOwner=True
	bFieldActive=False
	StationaryTime=0.0f
	CheckInterval=1.0f
	MovementThreshold=10.0f

	Name="Default__ZTUpgrade_Skill_LeechField_Helper"
}
