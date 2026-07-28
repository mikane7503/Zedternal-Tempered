// Hyde skill - Titanic Frame: Hyde transforms even bigger, with extra shockwave reach.
// Feeds the helper (scale override + radius); applied at transform time.
class DKUpgrade_Skill_TitanicFrame extends DKUpgrade_Skill
	config(ZedternalUnlimited);

var config array<float> Scale;
var config array<float> RadiusBonus;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Scale[0] = 2.3f;        default.Scale[1] = 2.6f;
		default.RadiusBonus[0] = 0.15f; default.RadiusBonus[1] = 0.30f;
		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static simulated function InitiateWeapon(int upgLevel, KFWeapon KFW, KFPawn OwnerPawn)
{
	local DKUpgrade_Perk_JekyllHyde_Helper H;
	if (KFPawn_Human(OwnerPawn) == None || OwnerPawn.Role != ROLE_Authority)
		return;
	H = class'DKUpgrade_Perk_JekyllHyde'.static.GetHelper(OwnerPawn);
	if (H == None) return;
	H.TitanicScaleOverride = default.Scale[upgLevel - 1];
	H.TitanicRadiusBonus = default.RadiusBonus[upgLevel - 1];
}

static simulated function DeleteHelperClass(Pawn OwnerPawn)
{
	local DKUpgrade_Perk_JekyllHyde_Helper H;
	if (OwnerPawn == None) return;
	H = class'DKUpgrade_Perk_JekyllHyde'.static.FindHelper(OwnerPawn);
	if (H != None) H.ResetTitanic();
}

defaultproperties
{
	bShouldLocalize=True
	LocPackage="ZedternalRBPerkpackage"
	LocSection="DKUpgrade_Skill_TitanicFrame"
	UpgradeName="Titanic Frame"
	upgradeDescription(0)="<font color=\"#be4d25\">Mr. Hyde</font> grows to <font color=\"#77d914\">2.3x</font> size with <font color=\"#77d914\">+15%</font> shockwave reach."
	upgradeDescription(1)="<font color=\"#be4d25\">Mr. Hyde</font> grows to <font color=\"#77d914\">2.6x</font> size with <font color=\"#77d914\">+30%</font> shockwave reach."
	UpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_TitanicFrame'
	UpgradeIcon(1)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_TitanicFrame_Deluxe'
	Name="Default__DKUpgrade_Skill_TitanicFrame"
}
