// Hyde skill - Bloodlust: each kill while transformed extends the Hyde timer (capped per transform).
class ZTUpgrade_Skill_Bloodlust extends ZTUpgrade_Skill config(ZedternalUnlimited);

var config array<float> PerKill;
var config array<float> Cap;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.PerKill[0] = 0.5f;  default.PerKill[1] = 1.0f;
		default.Cap[0] = 5.0f;      default.Cap[1] = 10.0f;
		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static function ModifyDamageGiven(out int InDamage, int DefaultDamage, int upgLevel, optional Actor DamageCauser, optional KFPawn_Monster MyKFPM, optional KFPlayerController DamageInstigator, optional class<KFDamageType> DamageType, optional int HitZoneIdx, optional KFWeapon MyKFW)
{
	local ZTUpgrade_Perk_JekyllHyde_Helper H;

	if (DamageInstigator == None || DamageInstigator.Pawn == None || MyKFPM == None)
		return;
	if (!MyKFPM.IsAliveAndWell() || (MyKFPM.Health - InDamage) > 0)
		return;   // not a killing blow

	H = class'ZTUpgrade_Perk_JekyllHyde'.static.GetHelper(DamageInstigator.Pawn);
	if (H == None || !H.bHyde || H.bShockwaveActive)
		return;

	H.ExtendHyde(default.PerKill[upgLevel - 1], default.Cap[upgLevel - 1]);
}

defaultproperties
{
	bShouldLocalize=True
	LocPackage="ZedternalTempered"
	LocSection="ZTUpgrade_Skill_Bloodlust"
	UpgradeName="Bloodlust"
	upgradeDescription(0)="Each kill as <font color=\"#be4d25\">Mr. Hyde</font> extends the transform by <font color=\"#77d914\">+0.5s</font> (max <font color=\"#77d914\">+5s</font> per rampage)."
	upgradeDescription(1)="Each kill as <font color=\"#be4d25\">Mr. Hyde</font> extends the transform by <font color=\"#77d914\">+1s</font> (max <font color=\"#77d914\">+10s</font> per rampage)."
	UpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_Bloodlust'
	UpgradeIcon(1)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_Bloodlust_Deluxe'
	Name="Default__ZTUpgrade_Skill_Bloodlust"
}
