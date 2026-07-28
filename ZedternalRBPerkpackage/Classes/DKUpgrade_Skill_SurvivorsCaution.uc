// Jekyll skill - Survivor's Caution: reduced damage taken while NOT transformed.
class DKUpgrade_Skill_SurvivorsCaution extends DKUpgrade_Skill
	config(ZedternalUnlimited);

var config array<float> Resist;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Resist[0] = 0.12f;  default.Resist[1] = 0.20f;
		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static function ModifyDamageTaken(out int InDamage, int DefaultDamage, int upgLevel, KFPawn OwnerPawn, optional class<DamageType> DamageType, optional Controller InstigatedBy, optional KFWeapon MyKFW)
{
	local DKUpgrade_Perk_JekyllHyde_Helper H;
	if (OwnerPawn == None) return;
	H = class'DKUpgrade_Perk_JekyllHyde'.static.FindHelper(OwnerPawn);
	if (H != None && H.bHyde) return;   // Hyde is already fully immune
	InDamage -= Round(float(InDamage) * default.Resist[upgLevel - 1]);
}

defaultproperties
{
	bShouldLocalize=True
	LocPackage="ZedternalRBPerkpackage"
	LocSection="DKUpgrade_Skill_SurvivorsCaution"
	UpgradeName="Survivor's Caution"
	upgradeDescription(0)="As <font color=\"#15d7fa\">Dr. Jekyll</font>, you take <font color=\"#77d914\">12% less</font> damage."
	upgradeDescription(1)="As <font color=\"#15d7fa\">Dr. Jekyll</font>, you take <font color=\"#77d914\">20% less</font> damage."
	UpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_SurvivorsCaution'
	UpgradeIcon(1)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_SurvivorsCaution_Deluxe'
	Name="Default__DKUpgrade_Skill_SurvivorsCaution"
}
