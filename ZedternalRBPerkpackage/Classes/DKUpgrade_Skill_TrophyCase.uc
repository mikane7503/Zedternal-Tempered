// Trophy Case - kills with returned Goalkeeper projectiles bank bonus armor for the wave.
// Lethality detected inside the damage hook; stacks live in the skill's own helper.
class DKUpgrade_Skill_TrophyCase extends DKUpgrade_Skill
	config(ZedternalUnlimited);

var config array<int> ArmorPerKill;
var config int MaxStacks;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.ArmorPerKill[0] = 1;
		default.ArmorPerKill[1] = 2;
		default.MaxStacks = 25;
		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static function DKUpgrade_Skill_TrophyCase_Helper GetHelper(Pawn OwnerPawn)
{
	local DKUpgrade_Skill_TrophyCase_Helper H;

	if (KFPawn_Human(OwnerPawn) == None)
		return None;

	foreach OwnerPawn.ChildActors(class'DKUpgrade_Skill_TrophyCase_Helper', H)
		return H;

	return OwnerPawn.Spawn(class'DKUpgrade_Skill_TrophyCase_Helper', OwnerPawn);
}

static function ModifyDamageGiven(out int InDamage, int DefaultDamage, int upgLevel, optional Actor DamageCauser, optional KFPawn_Monster MyKFPM, optional KFPlayerController DamageInstigator, optional class<KFDamageType> DamageType, optional int HitZoneIdx, optional KFWeapon MyKFW)
{
	local DKUpgrade_Skill_TrophyCase_Helper H;

	if (DamageType == None || !ClassIsChildOf(DamageType, class'DKDT_Goalkeeper_Return'))
		return;

	if (MyKFPM == None || DamageInstigator == None || DamageInstigator.Pawn == None)
		return;

	// Lethal return hit: bank a trophy stack
	if (InDamage >= MyKFPM.Health)
	{
		H = GetHelper(DamageInstigator.Pawn);
		if (H != None)
			H.AddStacks(default.ArmorPerKill[upgLevel - 1], default.MaxStacks);
	}
}

static function ModifyArmor(out int MaxArmor, int DefaultArmor, int upgLevel)
{
	// Applied through the helper granting flat armor on stack gain; MaxArmor
	// itself stays untouched to avoid mid-wave recalc desyncs.
}

static function WaveEnd(int upgLevel, KFPlayerController KFPC)
{
	local DKUpgrade_Skill_TrophyCase_Helper H;

	if (KFPC == None || KFPC.Pawn == None)
		return;

	H = GetHelper(KFPC.Pawn);
	if (H != None)
		H.ResetStacks();
}

static simulated function DeleteHelperClass(Pawn OwnerPawn)
{
	local DKUpgrade_Skill_TrophyCase_Helper H;

	if (OwnerPawn == None)
		return;

	foreach OwnerPawn.ChildActors(class'DKUpgrade_Skill_TrophyCase_Helper', H)
		H.Destroy();
}

defaultproperties
{
	bShouldLocalize=True
	LocPackage="ZedternalRBPerkpackage"
	LocSection="DKUpgrade_Skill_TrophyCase"

	UpgradeName="Trophy Case"
	upgradeDescription(0)="<font color=\"#15d7fa\">Goalkeeper only:</font> kills with returned projectiles grant <font color=\"#77d914\">+1 Armor</font> each (up to 25 per wave)."
	upgradeDescription(1)="<font color=\"#15d7fa\">Goalkeeper only:</font> kills with returned projectiles grant <font color=\"#77d914\">+2 Armor</font> each (up to 25 per wave)."
	UpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_TrophyCase'
	UpgradeIcon(1)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_TrophyCase_Deluxe'
	Name="Default__DKUpgrade_Skill_TrophyCase"
}
