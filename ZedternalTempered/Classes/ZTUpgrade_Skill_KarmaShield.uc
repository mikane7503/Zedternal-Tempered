// Karma Shield - universal: heavy hits harden you. After a hit costing over 25%
// of your Max Health, take reduced damage for 5 seconds.
class ZTUpgrade_Skill_KarmaShield extends ZTUpgrade_Skill
	config(ZedternalUnlimited);

var config array<float> ResistAmount;
var config float BigHitThreshold;
var config float ShieldDuration;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.ResistAmount[0] = 0.20f;
		default.ResistAmount[1] = 0.35f;
		default.BigHitThreshold = 0.25f;
		default.ShieldDuration = 5.0f;
		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static function ZTUpgrade_Skill_KarmaShield_Helper GetHelper(Pawn OwnerPawn)
{
	local ZTUpgrade_Skill_KarmaShield_Helper H;

	if (KFPawn_Human(OwnerPawn) == None)
		return None;

	foreach OwnerPawn.ChildActors(class'ZTUpgrade_Skill_KarmaShield_Helper', H)
		return H;

	return OwnerPawn.Spawn(class'ZTUpgrade_Skill_KarmaShield_Helper', OwnerPawn);
}

static simulated function InitiateWeapon(int upgLevel, KFWeapon KFW, KFPawn OwnerPawn)
{
	if (KFPawn_Human(OwnerPawn) != None && OwnerPawn.Role == ROLE_Authority)
		GetHelper(OwnerPawn);
}

static function ModifyDamageTaken(out int InDamage, int DefaultDamage, int upgLevel, KFPawn OwnerPawn, optional class<DamageType> DamageType, optional Controller InstigatedBy, optional KFWeapon MyKFW)
{
	local ZTUpgrade_Skill_KarmaShield_Helper H;

	if (OwnerPawn == None || InDamage <= 0)
		return;

	H = GetHelper(OwnerPawn);
	if (H == None)
		return;

	// Shield active: soften this hit
	if (H.WorldInfo.TimeSeconds < H.ShieldEndTime)
	{
		InDamage -= Round(float(InDamage) * default.ResistAmount[upgLevel - 1]);
		return;
	}

	// Big hit: raise the shield (this hit lands at full force)
	if (float(InDamage) >= float(OwnerPawn.HealthMax) * default.BigHitThreshold)
		H.ShieldEndTime = H.WorldInfo.TimeSeconds + default.ShieldDuration;
}

static simulated function DeleteHelperClass(Pawn OwnerPawn)
{
	local ZTUpgrade_Skill_KarmaShield_Helper H;

	if (OwnerPawn == None)
		return;

	foreach OwnerPawn.ChildActors(class'ZTUpgrade_Skill_KarmaShield_Helper', H)
		H.Destroy();
}

defaultproperties
{
	bShouldLocalize=True
	LocPackage="ZedternalTempered"
	LocSection="ZTUpgrade_Skill_KarmaShield"

	UpgradeName="Karma Shield"
	upgradeDescription(0)="Hits costing over <font color=\"#FFFFFF\">25%</font> of your Max Health harden you: take <font color=\"#77d914\">20% less damage</font> for 5s."
	upgradeDescription(1)="Hits costing over <font color=\"#FFFFFF\">25%</font> of your Max Health harden you: take <font color=\"#77d914\">35% less damage</font> for 5s."
	UpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_KarmaShield'
	UpgradeIcon(1)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_KarmaShield_Deluxe'
	Name="Default__ZTUpgrade_Skill_KarmaShield"
}
