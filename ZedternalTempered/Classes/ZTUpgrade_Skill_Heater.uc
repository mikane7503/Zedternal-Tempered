// Heater - Fastball synergy: harder throws, harder landings. Inert without the perk.
class ZTUpgrade_Skill_Heater extends ZTUpgrade_Skill
	config(ZedternalUnlimited);

var config array<float> ForceMult;
var config array<float> ImpactBonus;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.ForceMult[0] = 1.25f;
		default.ForceMult[1] = 1.50f;
		default.ImpactBonus[0] = 0.15f;
		default.ImpactBonus[1] = 0.30f;
		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static simulated function InitiateWeapon(int upgLevel, KFWeapon KFW, KFPawn OwnerPawn)
{
	local ZTUpgrade_Perk_Fastball_Helper H;

	if (KFPawn_Human(OwnerPawn) == None || OwnerPawn.Role != ROLE_Authority)
		return;

	H = class'ZTUpgrade_Perk_Fastball'.static.FindHelper(OwnerPawn);
	if (H != None)
		H.SetSkillForceMult(default.ForceMult[upgLevel - 1]);
}

static function WaveEnd(int upgLevel, KFPlayerController KFPC)
{
	if (KFPC != None && KFPC.Pawn != None)
		InitiateWeapon(upgLevel, None, KFPawn(KFPC.Pawn));
}

static function ModifyDamageGiven(out int InDamage, int DefaultDamage, int upgLevel, optional Actor DamageCauser, optional KFPawn_Monster MyKFPM, optional KFPlayerController DamageInstigator, optional class<KFDamageType> DamageType, optional int HitZoneIdx, optional KFWeapon MyKFW)
{
	if (DamageType == None || !ClassIsChildOf(DamageType, class'ZTDT_Fastball_Impact'))
		return;

	InDamage += Round(float(DefaultDamage) * default.ImpactBonus[upgLevel - 1]);
}

static simulated function DeleteHelperClass(Pawn OwnerPawn)
{
	local ZTUpgrade_Perk_Fastball_Helper H;

	if (OwnerPawn == None)
		return;

	H = class'ZTUpgrade_Perk_Fastball'.static.FindHelper(OwnerPawn);
	if (H != None)
		H.SetSkillForceMult(1.0f);
}

defaultproperties
{
	bShouldLocalize=True
	LocPackage="ZedternalTempered"
	LocSection="ZTUpgrade_Skill_Heater"

	UpgradeName="Heater"
	upgradeDescription(0)="<font color=\"#15d7fa\">Fastball only:</font> launch force <font color=\"#77d914\">+25%</font> and landing shockwave damage <font color=\"#ff3399\">+15%</font>."
	upgradeDescription(1)="<font color=\"#15d7fa\">Fastball only:</font> launch force <font color=\"#77d914\">+50%</font> and landing shockwave damage <font color=\"#ff3399\">+30%</font>."
	UpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_Heater'
	UpgradeIcon(1)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_Heater_Deluxe'
	Name="Default__ZTUpgrade_Skill_Heater"
}
