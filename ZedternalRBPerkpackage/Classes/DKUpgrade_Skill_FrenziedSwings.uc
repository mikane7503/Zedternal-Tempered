// Hyde skill - Frenzied Swings: faster melee attack speed while transformed.
class DKUpgrade_Skill_FrenziedSwings extends DKUpgrade_Skill
	config(ZedternalUnlimited);

var config array<float> AtkSpeed;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.AtkSpeed[0] = 0.20f;  default.AtkSpeed[1] = 0.35f;
		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static simulated function ModifyMeleeAttackSpeed(out float InDuration, float DefaultDuration, int upgLevel, KFWeapon KFW)
{
	local DKUpgrade_Perk_JekyllHyde_Helper H;
	if (KFW == None) return;
	H = class'DKUpgrade_Perk_JekyllHyde'.static.FindHelper(KFPawn(KFW.Instigator));
	if (H == None || !H.bHyde) return;
	InDuration = InDuration / (1.0f + default.AtkSpeed[upgLevel - 1]);
}

defaultproperties
{
	bShouldLocalize=True
	LocPackage="ZedternalRBPerkpackage"
	LocSection="DKUpgrade_Skill_FrenziedSwings"
	UpgradeName="Frenzied Swings"
	upgradeDescription(0)="As <font color=\"#be4d25\">Mr. Hyde</font>, melee <font color=\"#77d914\">+20%</font> faster."
	upgradeDescription(1)="As <font color=\"#be4d25\">Mr. Hyde</font>, melee <font color=\"#77d914\">+35%</font> faster."
	UpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_FrenziedSwings'
	UpgradeIcon(1)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_FrenziedSwings_Deluxe'
	Name="Default__DKUpgrade_Skill_FrenziedSwings"
}
