// ===================================================================
// ZTUpgrade_Skill_RegenerativeMembrane_Helper
// State machine for stationary healing:
//   IDLE     → checking if player is stationary
//   HEALING  → actively healing per tick
//   COOLDOWN → 60s lockout after movement interrupted healing
//
// Healing only triggers after being stationary for StationaryDelay.
// Moving after at least one heal tick triggers the cooldown.
// ===================================================================
class ZTUpgrade_Skill_RegenerativeMembrane_Helper extends Info transient;

var KFPawn_Human Player;
var bool bDeluxe;

// State tracking
var byte CurrentState; // 0=IDLE, 1=HEALING, 2=COOLDOWN
var bool bHasHealedThisCycle; // Track if we've healed at least once

// Configuration
var const float PollInterval;
var const float StationaryDelay;
var const float CooldownDuration;
var const float VelocityThreshold;
var const array<byte> HealPerTick;
var const byte DeluxeArmorPerTick;

// Timers
var float StationaryTime;

function PostBeginPlay()
{
	super.PostBeginPlay();

	Player = KFPawn_Human(Owner);
	if (Player == None || Player.Health <= 0)
		Destroy();
	else
		SetTimer(PollInterval, True);
}

function Timer()
{
	local float Speed;

	if (Player == None || Player.Health <= 0)
	{
		Destroy();
		return;
	}

	Speed = VSize(Player.Velocity);

	switch (CurrentState)
	{
		// IDLE: waiting for player to become stationary
		case 0:
			if (Speed < VelocityThreshold)
			{
				StationaryTime += PollInterval;
				if (StationaryTime >= StationaryDelay)
				{
					CurrentState = 1; // → HEALING
					bHasHealedThisCycle = False;
					StationaryTime = 0.0f;
				}
			}
			else
			{
				StationaryTime = 0.0f;
			}
			break;

		// HEALING: actively healing while stationary
		case 1:
			if (Speed >= VelocityThreshold)
			{
				// Player moved - check if we've actually healed
				if (bHasHealedThisCycle)
				{
					// Trigger cooldown
					CurrentState = 2; // → COOLDOWN
					ClearTimer();
					SetTimer(CooldownDuration, False, nameof(CooldownExpired));
				}
				else
				{
					// Never actually healed, just go back to idle
					CurrentState = 0;
					StationaryTime = 0.0f;
				}
			}
			else
			{
				// Still stationary - heal
				DoHeal();
			}
			break;

		// COOLDOWN: should not reach here (uses named timer)
		case 2:
			break;
	}
}

function DoHeal()
{
	local byte HealAmount;
	local int UpgIdx;

	if (Player == None || Player.Health <= 0)
		return;

	UpgIdx = 0;
	if (bDeluxe)
		UpgIdx = 1;

	// Heal HP if not at max
	if (Player.Health < Player.HealthMax)
	{
		HealAmount = HealPerTick[UpgIdx];
		Player.Health = Min(Player.Health + HealAmount, Player.HealthMax);
		bHasHealedThisCycle = True;
	}

	// Deluxe: also restore armor
	if (bDeluxe && Player.Armor < Player.MaxArmor)
	{
		Player.Armor = Min(Player.Armor + DeluxeArmorPerTick, Player.MaxArmor);
		bHasHealedThisCycle = True;
	}
}

function CooldownExpired()
{
	if (Player == None || Player.Health <= 0)
	{
		Destroy();
		return;
	}

	// Return to idle
	CurrentState = 0;
	StationaryTime = 0.0f;
	bHasHealedThisCycle = False;
	SetTimer(PollInterval, True);
}

defaultproperties
{
	CurrentState=0
	bDeluxe=False
	bHasHealedThisCycle=False
	StationaryTime=0.0f

	PollInterval=1.0f
	StationaryDelay=1.0f
	CooldownDuration=60.0f
	VelocityThreshold=10.0f

	HealPerTick(0)=1
	HealPerTick(1)=2
	DeluxeArmorPerTick=1

	Name="Default__ZTUpgrade_Skill_RegenerativeMembrane_Helper"
}
