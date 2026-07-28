// Helper for Miasma.
// Periodically applies a custom STACKING toxic DoT (DKDT_Miasma) to all nearby ZEDs.
// Pattern based on HotPepper_Helper.
class DKUpgrade_Skill_Miasma_Helper extends Info
	transient;

var KFPawn_Human Player;
var bool bDeluxe;
var const float Radius, Update;

// Per-tick damage as a fraction of each zed's MAX health, applied through the custom
// stacking DKDT_Miasma DoT. With that DoT's 3s duration vs this 1s re-apply, stacks
// self-cap at ~3, so sustained damage ~= 3 * Pct * MaxHealth per second. Flat damage
// can't scale into endless (zed HP runs to the thousands), hence %-of-max-HP. Large
// zeds / bosses take LargeZedMult of the % so long boss fights aren't trivialized by
// %-HP melt. Toxic resistance (KFDT_Toxic) still applies on top.
var const array<float> HealthPct;   // [0]=Standard, [1]=Deluxe -- per tick per stack
var const float LargeZedMult;

function PostBeginPlay()
{
	super.PostBeginPlay();

	Player = KFPawn_Human(Owner);
	if (Player == None || Player.Health <= 0)
		Destroy();
	else
		SetTimer(Update, True);
}

function Timer()
{
	local KFPawn_Monster KFM;
	local KFPlayerController KFPC;
	local float Pct, ZedMult;
	local int Dmg;

	if (Player == None || Player.Health <= 0)
	{
		Destroy();
		return;
	}

	KFPC = KFPlayerController(Player.Controller);
	if (KFPC == None)
		return;

	if (bDeluxe)
		Pct = default.HealthPct[1];
	else
		Pct = default.HealthPct[0];

	foreach DynamicActors(class'KFPawn_Monster', KFM)
	{
		if (KFM.IsAliveAndWell() && VSizeSQ(Player.Location - KFM.Location) <= Radius)
		{
			ZedMult = 1.0f;
			if (KFM.IsLargeZed() || KFM.IsABoss() || KFInterface_MonsterBoss(KFM) != None)
				ZedMult = default.LargeZedMult;

			Dmg = Round(float(KFM.HealthMax) * Pct * ZedMult);
			if (Dmg > 0)
				KFM.ApplyDamageOverTime(Dmg, KFPC, class'DKDT_Miasma');
		}
	}
}

defaultproperties
{
	bDeluxe=False

	// Radius squared: (350uu)^2 = 122500
	Radius=122500
	Update=1.0f

	// Per tick per stack, as a fraction of max health. ~3-stack plateau means sustained:
	//   Standard 0.5%/tick -> ~1.5% max HP/sec ; Deluxe 1.0%/tick -> ~3.0% max HP/sec.
	HealthPct(0)=0.005f
	HealthPct(1)=0.010f

	// Giants / bosses take 25% of the above (tune or set 1.0 to disable the cap).
	LargeZedMult=0.25f

	Name="Default__DKUpgrade_Skill_Miasma_Helper"
}
