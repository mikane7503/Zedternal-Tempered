// Designated Hitter - universal: BEING launched (by anyone's Fastball) grants you a
// damage window on landing. Own helper watches for the payload marker; no perk needed.
class ZTUpgrade_Skill_DesignatedHitter extends ZTUpgrade_Skill
	config(ZedternalUnlimited);

var config array<float> DamageBonus;
var config float BuffDuration;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.DamageBonus[0] = 0.20f;
		default.DamageBonus[1] = 0.40f;
		default.BuffDuration = 8.0f;
		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static function ZTUpgrade_Skill_DesignatedHitter_Helper GetHelper(Pawn OwnerPawn)
{
	local ZTUpgrade_Skill_DesignatedHitter_Helper H;

	if (KFPawn_Human(OwnerPawn) == None)
		return None;

	foreach OwnerPawn.ChildActors(class'ZTUpgrade_Skill_DesignatedHitter_Helper', H)
		return H;

	return OwnerPawn.Spawn(class'ZTUpgrade_Skill_DesignatedHitter_Helper', OwnerPawn);
}

static simulated function InitiateWeapon(int upgLevel, KFWeapon KFW, KFPawn OwnerPawn)
{
	if (KFPawn_Human(OwnerPawn) != None && OwnerPawn.Role == ROLE_Authority)
		GetHelper(OwnerPawn);
}

static function ModifyDamageGiven(out int InDamage, int DefaultDamage, int upgLevel, optional Actor DamageCauser, optional KFPawn_Monster MyKFPM, optional KFPlayerController DamageInstigator, optional class<KFDamageType> DamageType, optional int HitZoneIdx, optional KFWeapon MyKFW)
{
	local ZTUpgrade_Skill_DesignatedHitter_Helper H;

	if (DamageInstigator == None || DamageInstigator.Pawn == None)
		return;

	H = GetHelper(DamageInstigator.Pawn);
	if (H == None || H.WorldInfo.TimeSeconds >= H.BuffEndTime)
		return;

	InDamage += Round(float(DefaultDamage) * default.DamageBonus[upgLevel - 1]);
}

static simulated function DeleteHelperClass(Pawn OwnerPawn)
{
	local ZTUpgrade_Skill_DesignatedHitter_Helper H;

	if (OwnerPawn == None)
		return;

	foreach OwnerPawn.ChildActors(class'ZTUpgrade_Skill_DesignatedHitter_Helper', H)
		H.Destroy();
}

defaultproperties
{
	bShouldLocalize=True
	LocPackage="ZedternalTempered"
	LocSection="ZTUpgrade_Skill_DesignatedHitter"

	UpgradeName="Designated Hitter"
	upgradeDescription(0)="Being <font color=\"#15d7fa\">launched by a Fastball</font> grants you <font color=\"#ff3399\">+20% damage</font> for 8s after landing."
	upgradeDescription(1)="Being <font color=\"#15d7fa\">launched by a Fastball</font> grants you <font color=\"#ff3399\">+40% damage</font> for 8s after landing."
	UpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_DesignatedHitter'
	UpgradeIcon(1)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_DesignatedHitter_Deluxe'
	Name="Default__ZTUpgrade_Skill_DesignatedHitter"
}
