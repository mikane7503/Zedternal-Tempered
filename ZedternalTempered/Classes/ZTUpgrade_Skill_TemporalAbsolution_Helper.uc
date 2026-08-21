// ===================================================================
// ZTUpgrade_Skill_TemporalAbsolution_Helper
// Records player health when ZED Time starts. When ZED Time ends,
// calculates damage taken during that interval and heals back a
// configured percentage.
// Pattern: WMUpgrade_Skill_Destruction_Helper
// ===================================================================
class ZTUpgrade_Skill_TemporalAbsolution_Helper extends Info transient;

var KFPawn_Human Player;
var bool bDeluxe;
var bool bInZedTime;
var int RecordedHealth;
var const float Update;
var const array<float> HealPercent;

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

function Timer()
{
	if (Player == None || Player.Health <= 0)
	{
		Destroy();
		return;
	}

	if (Player.WorldInfo.TimeDilation < 1.0)
	{
		if (!bInZedTime)
		{
			// ZED Time just started - snapshot current health
			bInZedTime = True;
			RecordedHealth = Player.Health;
		}
	}
	else if (bInZedTime)
	{
		// ZED Time just ended - heal back damage taken
		bInZedTime = False;
		HealBack();
	}
}

function HealBack()
{
	local int DamageTaken;
	local int HealAmount;
	local float Pct;

	DamageTaken = Max(0, RecordedHealth - Player.Health);
	if (DamageTaken <= 0 || Player.Health <= 0)
		return;

	if (bDeluxe)
		Pct = default.HealPercent[1];
	else
		Pct = default.HealPercent[0];

	HealAmount = Round(float(DamageTaken) * Pct);
	if (HealAmount > 0)
		Player.HealDamage(HealAmount, Player.Controller, class'KFDT_Healing');
}

defaultproperties
{
	bDeluxe=False
	bInZedTime=False
	RecordedHealth=0
	Update=0.25f
	HealPercent(0)=0.35f
	HealPercent(1)=0.65f

	Name="Default__ZTUpgrade_Skill_TemporalAbsolution_Helper"
}
