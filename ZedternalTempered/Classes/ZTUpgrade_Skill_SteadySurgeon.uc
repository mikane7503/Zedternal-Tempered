// Jekyll skill - Steady Surgeon: sharply reduced recoil & spread while NOT transformed.
class ZTUpgrade_Skill_SteadySurgeon extends ZTUpgrade_Skill config(ZedternalUnlimited);

var config array<float> Recoil;
var config array<float> Spread;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Recoil[0] = 0.30f;  default.Recoil[1] = 0.50f;
		default.Spread[0] = 0.30f;  default.Spread[1] = 0.50f;
		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static simulated function ModifyRecoil(out float InRecoilModifier, float DefaultRecoilModifier, int upgLevel, KFWeapon KFW)
{
	local ZTUpgrade_Perk_JekyllHyde_Helper H;
	if (KFW == None) return;
	H = class'ZTUpgrade_Perk_JekyllHyde'.static.FindHelper(KFPawn(KFW.Instigator));
	if (H != None && H.bHyde) return;
	InRecoilModifier -= DefaultRecoilModifier * default.Recoil[upgLevel - 1];
}

static simulated function ModifySpread(out float InSpreadModifier, float DefaultSpreadModifier, int upgLevel, KFWeapon KFW)
{
	local ZTUpgrade_Perk_JekyllHyde_Helper H;
	if (KFW == None) return;
	H = class'ZTUpgrade_Perk_JekyllHyde'.static.FindHelper(KFPawn(KFW.Instigator));
	if (H != None && H.bHyde) return;
	InSpreadModifier -= DefaultSpreadModifier * default.Spread[upgLevel - 1];
}

defaultproperties
{
	bShouldLocalize=True
	LocPackage="ZedternalTempered"
	LocSection="ZTUpgrade_Skill_SteadySurgeon"
	UpgradeName="Steady Surgeon"
	upgradeDescription(0)="As <font color=\"#15d7fa\">Dr. Jekyll</font>, weapon <font color=\"#66cc00\">recoil and spread</font> are reduced by <font color=\"#77d914\">30%</font>."
	upgradeDescription(1)="As <font color=\"#15d7fa\">Dr. Jekyll</font>, weapon <font color=\"#66cc00\">recoil and spread</font> are reduced by <font color=\"#77d914\">50%</font>."
	UpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_SteadySurgeon'
	UpgradeIcon(1)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_SteadySurgeon_Deluxe'
	Name="Default__ZTUpgrade_Skill_SteadySurgeon"
}
