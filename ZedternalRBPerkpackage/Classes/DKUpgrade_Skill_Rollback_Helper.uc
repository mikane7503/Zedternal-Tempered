// Rollback helper - drains a queued heal pool onto the owner over ~4s.
class DKUpgrade_Skill_Rollback_Helper extends Actor;

var int PendingHeal;

const TICK_INTERVAL = 0.5f;
const TICKS_TO_DRAIN = 8; // 8 x 0.5s = 4s

function QueueRefund(int Amount)
{
	if (Amount <= 0)
		return;

	PendingHeal += Amount;
	if (!IsTimerActive(NameOf(HealTick)))
		SetTimer(TICK_INTERVAL, True, NameOf(HealTick));
}

function HealTick()
{
	local KFPawn_Human KFPH;
	local int Amount;

	KFPH = KFPawn_Human(Owner);
	if (KFPH == None || KFPH.Health <= 0 || PendingHeal <= 0)
	{
		PendingHeal = 0;
		ClearTimer(NameOf(HealTick));
		return;
	}

	Amount = Max(1, PendingHeal / TICKS_TO_DRAIN);
	Amount = Min(Amount, PendingHeal);
	PendingHeal -= Amount;

	KFPH.HealDamage(Amount, KFPlayerController(KFPH.Controller), class'KFDT_Healing');

	if (PendingHeal <= 0)
		ClearTimer(NameOf(HealTick));
}

defaultproperties
{
	bHidden=True
	RemoteRole=ROLE_None

	Name="Default__DKUpgrade_Skill_Rollback_Helper"
}
