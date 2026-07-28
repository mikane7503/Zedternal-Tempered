// Jekyll skill - Field Chemist: faster reloads and bigger mags while NOT transformed.
class DKUpgrade_Skill_FieldChemist extends DKUpgrade_Skill
	config(ZedternalUnlimited);

var config array<float> ReloadRate;
var config array<float> MagCapacity;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.ReloadRate[0] = 0.15f;   default.ReloadRate[1] = 0.25f;
		default.MagCapacity[0] = 0.10f;  default.MagCapacity[1] = 0.20f;
		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static simulated function GetReloadRateScale(out float InReloadRateScale, int upgLevel, KFWeapon KFW, KFPawn OwnerPawn)
{
	local DKUpgrade_Perk_JekyllHyde_Helper H;
	if (OwnerPawn == None) return;
	H = class'DKUpgrade_Perk_JekyllHyde'.static.FindHelper(OwnerPawn);
	if (H != None && H.bHyde) return;
	InReloadRateScale = 1.0f / (1.0f / InReloadRateScale + default.ReloadRate[upgLevel - 1]);
}

static simulated function ModifyMagSizeAndNumber(out int InMagazineCapacity, int DefaultMagazineCapacity, int upgLevel, KFWeapon KFW, optional array< class<KFPerk> > WeaponPerkClass, optional bool bSecondary=False, optional name WeaponClassname)
{
	local DKUpgrade_Perk_JekyllHyde_Helper H;
	if (KFW == None) return;
	H = class'DKUpgrade_Perk_JekyllHyde'.static.FindHelper(KFPawn(KFW.Instigator));
	if (H != None && H.bHyde) return;
	InMagazineCapacity += Round(float(DefaultMagazineCapacity) * default.MagCapacity[upgLevel - 1]);
}

defaultproperties
{
	bShouldLocalize=True
	LocPackage="ZedternalRBPerkpackage"
	LocSection="DKUpgrade_Skill_FieldChemist"
	UpgradeName="Field Chemist"
	upgradeDescription(0)="As <font color=\"#15d7fa\">Dr. Jekyll</font>: <font color=\"#77d914\">+15%</font> reload speed and <font color=\"#77d914\">+10%</font> magazine size."
	upgradeDescription(1)="As <font color=\"#15d7fa\">Dr. Jekyll</font>: <font color=\"#77d914\">+25%</font> reload speed and <font color=\"#77d914\">+20%</font> magazine size."
	UpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_FieldChemist'
	UpgradeIcon(1)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_FieldChemist_Deluxe'
	Name="Default__DKUpgrade_Skill_FieldChemist"
}
