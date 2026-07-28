// Hyde skill - Feral Sprint: big move-speed boost while transformed.
class DKUpgrade_Skill_FeralSprint extends DKUpgrade_Skill
	config(ZedternalUnlimited);

var config array<float> MoveSpeed;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.MoveSpeed[0] = 0.15f;  default.MoveSpeed[1] = 0.30f;
		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static simulated function ModifySpeed(out float InSpeed, float DefaultSpeed, int upgLevel, KFPawn OwnerPawn)
{
	local DKUpgrade_Perk_JekyllHyde_Helper H;
	if (OwnerPawn == None) return;
	H = class'DKUpgrade_Perk_JekyllHyde'.static.FindHelper(OwnerPawn);
	if (H == None || !H.bHyde) return;
	InSpeed += DefaultSpeed * default.MoveSpeed[upgLevel - 1];
}

defaultproperties
{
	bShouldLocalize=True
	LocPackage="ZedternalRBPerkpackage"
	LocSection="DKUpgrade_Skill_FeralSprint"
	UpgradeName="Feral Sprint"
	upgradeDescription(0)="As <font color=\"#be4d25\">Mr. Hyde</font>, move <font color=\"#77d914\">+15%</font> faster - run them down."
	upgradeDescription(1)="As <font color=\"#be4d25\">Mr. Hyde</font>, move <font color=\"#77d914\">+30%</font> faster - run them down."
	UpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_FeralSprint'
	UpgradeIcon(1)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_FeralSprint_Deluxe'
	Name="Default__DKUpgrade_Skill_FeralSprint"
}
