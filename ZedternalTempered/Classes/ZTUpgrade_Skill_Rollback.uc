// Rollback - universal glitch: big hits partially "roll back" as healing over time.
class ZTUpgrade_Skill_Rollback extends ZTUpgrade_Skill
	config(ZedternalUnlimited);

var config array<float> RefundFraction;
var config float BigHitThreshold; // fraction of max health in one hit
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.RefundFraction[0] = 0.30f;
		default.RefundFraction[1] = 0.50f;
		default.BigHitThreshold = 0.20f;
		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static function ZTUpgrade_Skill_Rollback_Helper GetHelper(Pawn OwnerPawn)
{
	local ZTUpgrade_Skill_Rollback_Helper H;

	if (KFPawn_Human(OwnerPawn) == None)
		return None;

	foreach OwnerPawn.ChildActors(class'ZTUpgrade_Skill_Rollback_Helper', H)
		return H;

	return OwnerPawn.Spawn(class'ZTUpgrade_Skill_Rollback_Helper', OwnerPawn);
}

static simulated function InitiateWeapon(int upgLevel, KFWeapon KFW, KFPawn OwnerPawn)
{
	if (KFPawn_Human(OwnerPawn) != None && OwnerPawn.Role == ROLE_Authority)
		GetHelper(OwnerPawn);
}

static function ModifyDamageTaken(out int InDamage, int DefaultDamage, int upgLevel, KFPawn OwnerPawn, optional class<DamageType> DamageType, optional Controller InstigatedBy, optional KFWeapon MyKFW)
{
	local ZTUpgrade_Skill_Rollback_Helper H;

	if (OwnerPawn == None || InDamage <= 0)
		return;

	if (float(InDamage) < float(OwnerPawn.HealthMax) * default.BigHitThreshold)
		return;

	H = GetHelper(OwnerPawn);
	if (H != None)
		H.QueueRefund(Round(float(InDamage) * default.RefundFraction[upgLevel - 1]));
}

static simulated function DeleteHelperClass(Pawn OwnerPawn)
{
	local ZTUpgrade_Skill_Rollback_Helper H;

	if (OwnerPawn == None)
		return;

	foreach OwnerPawn.ChildActors(class'ZTUpgrade_Skill_Rollback_Helper', H)
		H.Destroy();
}

defaultproperties
{
	bShouldLocalize=True
	LocPackage="ZedternalTempered"
	LocSection="ZTUpgrade_Skill_Rollback"

	UpgradeName="Rollback"
	upgradeDescription(0)="Hits that cost over <font color=\"#FFFFFF\">20%</font> of your Max Health are <font color=\"#00ff00\">rolled back</font>: heal <font color=\"#77d914\">30%</font> of that damage over 4s."
	upgradeDescription(1)="Hits that cost over <font color=\"#FFFFFF\">20%</font> of your Max Health are <font color=\"#00ff00\">rolled back</font>: heal <font color=\"#77d914\">50%</font> of that damage over 4s."
	UpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_Rollback'
	UpgradeIcon(1)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_Rollback_Deluxe'
	Name="Default__ZTUpgrade_Skill_Rollback"
}
