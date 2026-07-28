// ===================================================================
// DKUpgrade_Skill_PhantomPain_Helper
// Accumulates damage dealt during ZED Time. When ZED Time ends,
// detonates an AoE explosion centered on the player dealing a
// percentage of accumulated damage. Deluxe adds a second explosion
// at the last damaged enemy's location.
// Pattern: WMUpgrade_Skill_Destruction_Helper
// ===================================================================
class DKUpgrade_Skill_PhantomPain_Helper extends Info
	transient;

var KFPawn_Human Player;
var bool bDeluxe;
var bool bInZedTime;
var int AccumulatedDamage;
var vector LastEnemyLocation;
var bool bHasEnemyLocation;
var const float Update;

// AoE config
var const array<float> DamagePct;
var const array<int> DamageCapPerTarget;
var const array<int> RadiusSq;

function Initialize(KFPawn_Human InPlayer, bool InDeluxe)
{
	Player = InPlayer;
	bDeluxe = InDeluxe;
}

function PostBeginPlay()
{
	super.PostBeginPlay();

	Player = KFPawn_Human(Owner);
	if (Player == None || Player.Health <= 0)
		Destroy();
	else
		SetTimer(Update, True);
}

function AccumulateDamage(int Damage, vector EnemyLocation)
{
	AccumulatedDamage += Damage;
	LastEnemyLocation = EnemyLocation;
	bHasEnemyLocation = True;
}

function Timer()
{
	if (Player == None || Player.Health <= 0)
	{
		Destroy();
		return;
	}

	if (Player.WorldInfo.TimeDilation < 1.0)
	{
		bInZedTime = True;
	}
	else if (bInZedTime)
	{
		// ZED Time just ended - detonate
		bInZedTime = False;
		if (AccumulatedDamage > 0)
		{
			Detonate();
			// Reset
			AccumulatedDamage = 0;
			bHasEnemyLocation = False;
		}
	}
}

function Detonate()
{
	local int Idx;
	local int ExplosionDamage;
	local int Cap;
	local int RadSq;

	if (bDeluxe)
		Idx = 1;
	else
		Idx = 0;

	ExplosionDamage = Round(float(AccumulatedDamage) * default.DamagePct[Idx]);
	Cap = default.DamageCapPerTarget[Idx];
	RadSq = default.RadiusSq[Idx];

	if (ExplosionDamage <= 0)
		return;

	// Primary explosion at player location
	ApplyAoE(Player.Location, ExplosionDamage, Cap, RadSq);

	// Deluxe: second explosion at last enemy hit location
	if (bDeluxe && bHasEnemyLocation)
		ApplyAoE(LastEnemyLocation, ExplosionDamage, Cap, RadSq);
}

function ApplyAoE(vector Center, int TotalDamage, int Cap, int RadSq)
{
	local KFPawn_Monster KFM;

	foreach DynamicActors(class'KFPawn_Monster', KFM)
	{
		if (KFM.IsAliveAndWell() && VSizeSq(Center - KFM.Location) <= RadSq)
			KFM.TakeDamage(Min(TotalDamage, Cap), Player.Controller, KFM.Location, vect(0,0,0), class'KFDT_Explosive');
	}
}

defaultproperties
{
	bDeluxe=False
	bInZedTime=False
	AccumulatedDamage=0
	bHasEnemyLocation=False
	Update=0.25f

	// Standard: 10% damage, 300 cap, 10m radius (1000 UU ^2 = 1000000)
	// Deluxe:   20% damage, 600 cap, 20m radius (2000 UU ^2 = 4000000)
	DamagePct(0)=0.1f
	DamagePct(1)=0.2f
	DamageCapPerTarget(0)=300
	DamageCapPerTarget(1)=600
	RadiusSq(0)=1000000
	RadiusSq(1)=4000000

	Name="Default__DKUpgrade_Skill_PhantomPain_Helper"
}
