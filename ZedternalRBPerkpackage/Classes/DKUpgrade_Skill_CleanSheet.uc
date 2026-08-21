// Clean Sheet - universal: damage bonus while untouched for a while.
// Helper tracks last-hit time; damage hook reads it (conditional non-passive pattern).
class DKUpgrade_Skill_CleanSheet extends DKUpgrade_Skill
	config(ZedternalUnlimited);

var config array<float> DamageBonus;
var config float GraceSeconds;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.DamageBonus[0] = 0.10f;
		default.DamageBonus[1] = 0.20f;
		default.GraceSeconds = 8.0f;
		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static function DKUpgrade_Skill_CleanSheet_Helper GetHelper(Pawn OwnerPawn)
{
	local DKUpgrade_Skill_CleanSheet_Helper H;

	if (KFPawn_Human(OwnerPawn) == None)
		return None;

	foreach OwnerPawn.ChildActors(class'DKUpgrade_Skill_CleanSheet_Helper', H)
		return H;

	return OwnerPawn.Spawn(class'DKUpgrade_Skill_CleanSheet_Helper', OwnerPawn);
}

static simulated function InitiateWeapon(int upgLevel, KFWeapon KFW, KFPawn OwnerPawn)
{
	if (KFPawn_Human(OwnerPawn) != None && OwnerPawn.Role == ROLE_Authority)
		GetHelper(OwnerPawn);
}

static function ModifyDamageTaken(out int InDamage, int DefaultDamage, int upgLevel, KFPawn OwnerPawn, optional class<DamageType> DamageType, optional Controller InstigatedBy, optional KFWeapon MyKFW)
{
	local DKUpgrade_Skill_CleanSheet_Helper H;

	if (InDamage <= 0 || OwnerPawn == None)
		return;

	H = GetHelper(OwnerPawn);
	if (H != None)
		H.LastHitTime = H.WorldInfo.TimeSeconds;
}

static function ModifyDamageGiven(out int InDamage, int DefaultDamage, int upgLevel, optional Actor DamageCauser, optional KFPawn_Monster MyKFPM, optional KFPlayerController DamageInstigator, optional class<KFDamageType> DamageType, optional int HitZoneIdx, optional KFWeapon MyKFW)
{
	local DKUpgrade_Skill_CleanSheet_Helper H;

	if (DamageInstigator == None || DamageInstigator.Pawn == None)
		return;

	H = GetHelper(DamageInstigator.Pawn);
	if (H == None)
		return;

	if (H.WorldInfo.TimeSeconds - H.LastHitTime >= default.GraceSeconds)
		InDamage += Round(float(DefaultDamage) * default.DamageBonus[upgLevel - 1]);
}

static simulated function DeleteHelperClass(Pawn OwnerPawn)
{
	local DKUpgrade_Skill_CleanSheet_Helper H;

	if (OwnerPawn == None)
		return;

	foreach OwnerPawn.ChildActors(class'DKUpgrade_Skill_CleanSheet_Helper', H)
		H.Destroy();
}

defaultproperties
{
	bShouldLocalize=True
	LocPackage="ZedternalRBPerkpackage"
	LocSection="DKUpgrade_Skill_CleanSheet"

	UpgradeName="Clean Sheet"
	upgradeDescription(0)="Taking no damage for <font color=\"#FFFFFF\">8 seconds</font> grants <font color=\"#ff3399\">+10% damage</font> until you are hit."
	upgradeDescription(1)="Taking no damage for <font color=\"#FFFFFF\">8 seconds</font> grants <font color=\"#ff3399\">+20% damage</font> until you are hit."
	UpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_CleanSheet'
	UpgradeIcon(1)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_CleanSheet_Deluxe'
	Name="Default__DKUpgrade_Skill_CleanSheet"
}
