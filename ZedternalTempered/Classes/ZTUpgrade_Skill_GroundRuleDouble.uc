// Ground Rule Double - Fastball synergy: bigger landing shockwave. Inert without the perk.
class ZTUpgrade_Skill_GroundRuleDouble extends ZTUpgrade_Skill
	config(ZedternalUnlimited);

var config array<float> RadiusMult;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.RadiusMult[0] = 1.25f;
		default.RadiusMult[1] = 1.50f;
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
		H.SetSkillRadiusMult(default.RadiusMult[upgLevel - 1]);
}

static function WaveEnd(int upgLevel, KFPlayerController KFPC)
{
	if (KFPC != None && KFPC.Pawn != None)
		InitiateWeapon(upgLevel, None, KFPawn(KFPC.Pawn));
}

static simulated function DeleteHelperClass(Pawn OwnerPawn)
{
	local ZTUpgrade_Perk_Fastball_Helper H;

	if (OwnerPawn == None)
		return;

	H = class'ZTUpgrade_Perk_Fastball'.static.FindHelper(OwnerPawn);
	if (H != None)
		H.SetSkillRadiusMult(1.0f);
}

defaultproperties
{
	bShouldLocalize=True
	LocPackage="ZedternalTempered"
	LocSection="ZTUpgrade_Skill_GroundRuleDouble"

	UpgradeName="Ground Rule Double"
	upgradeDescription(0)="<font color=\"#15d7fa\">Fastball only:</font> landing shockwave radius <font color=\"#77d914\">+25%</font>."
	upgradeDescription(1)="<font color=\"#15d7fa\">Fastball only:</font> landing shockwave radius <font color=\"#77d914\">+50%</font>."
	UpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_GroundRuleDouble'
	UpgradeIcon(1)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_GroundRuleDouble_Deluxe'
	Name="Default__ZTUpgrade_Skill_GroundRuleDouble"
}
