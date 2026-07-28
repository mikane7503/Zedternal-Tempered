// Jekyll skill - Practiced Hands: faster weapon switch and a little move speed while NOT transformed.
class DKUpgrade_Skill_PracticedHands extends DKUpgrade_Skill
	config(ZedternalUnlimited);

var config array<float> SwitchSpeed;
var config array<float> MoveSpeed;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.SwitchSpeed[0] = 0.20f;  default.SwitchSpeed[1] = 0.35f;
		default.MoveSpeed[0] = 0.03f;    default.MoveSpeed[1] = 0.06f;
		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static simulated function ModifyWeaponSwitchTime(out float InSwitchTime, float DefaultSwitchTime, int upgLevel, KFWeapon KFW)
{
	local DKUpgrade_Perk_JekyllHyde_Helper H;
	if (KFW == None) return;
	H = class'DKUpgrade_Perk_JekyllHyde'.static.FindHelper(KFPawn(KFW.Instigator));
	if (H != None && H.bHyde) return;
	InSwitchTime -= DefaultSwitchTime * default.SwitchSpeed[upgLevel - 1];
}

static simulated function ModifySpeed(out float InSpeed, float DefaultSpeed, int upgLevel, KFPawn OwnerPawn)
{
	local DKUpgrade_Perk_JekyllHyde_Helper H;
	if (OwnerPawn == None) return;
	H = class'DKUpgrade_Perk_JekyllHyde'.static.FindHelper(OwnerPawn);
	if (H != None && H.bHyde) return;
	InSpeed += DefaultSpeed * default.MoveSpeed[upgLevel - 1];
}

defaultproperties
{
	bShouldLocalize=True
	LocPackage="ZedternalRBPerkpackage"
	LocSection="DKUpgrade_Skill_PracticedHands"
	UpgradeName="Practiced Hands"
	upgradeDescription(0)="As <font color=\"#15d7fa\">Dr. Jekyll</font>: <font color=\"#77d914\">+20%</font> weapon switch speed and <font color=\"#77d914\">+3%</font> movement."
	upgradeDescription(1)="As <font color=\"#15d7fa\">Dr. Jekyll</font>: <font color=\"#77d914\">+35%</font> weapon switch speed and <font color=\"#77d914\">+6%</font> movement."
	UpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_PracticedHands'
	UpgradeIcon(1)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_PracticedHands_Deluxe'
	Name="Default__DKUpgrade_Skill_PracticedHands"
}
