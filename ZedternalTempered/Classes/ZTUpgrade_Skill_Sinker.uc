// Sinker - Fastball landing shockwave snares zeds. Pure hook gated on the impact DT.
class ZTUpgrade_Skill_Sinker extends ZTUpgrade_Skill
	config(ZedternalUnlimited);

var config array<float> SnarePower;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.SnarePower[0] = 100.0f;
		default.SnarePower[1] = 250.0f;
		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static function ModifySnarePower(out float InSnarePower, float DefaultSnarePower, int upgLevel, optional class<DamageType> DamageType, optional byte BodyPart)
{
	if (DamageType == None || !ClassIsChildOf(DamageType, class'ZTDT_Fastball_Impact'))
		return;

	InSnarePower += default.SnarePower[upgLevel - 1];
}

defaultproperties
{
	bShouldLocalize=True
	LocPackage="ZedternalTempered"
	LocSection="ZTUpgrade_Skill_Sinker"

	UpgradeName="Sinker"
	upgradeDescription(0)="<font color=\"#15d7fa\">Fastball only:</font> landing shockwaves <font color=\"#77d914\">slow</font> every zed they hit."
	upgradeDescription(1)="<font color=\"#15d7fa\">Fastball only:</font> landing shockwaves <font color=\"#77d914\">heavily slow</font> every zed they hit."
	UpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_Sinker'
	UpgradeIcon(1)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_Sinker_Deluxe'
	Name="Default__ZTUpgrade_Skill_Sinker"
}
