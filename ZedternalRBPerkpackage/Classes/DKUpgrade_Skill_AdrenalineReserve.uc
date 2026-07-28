// Jekyll skill - Adrenaline Reserve: kills as Jekyll bank bonus duration for your NEXT Hyde (capped).
class DKUpgrade_Skill_AdrenalineReserve extends DKUpgrade_Skill
	config(ZedternalUnlimited);

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
	local DKUpgrade_Perk_JekyllHyde_Helper H;

	if (DamageInstigator == None || DamageInstigator.Pawn == None || MyKFPM == None)
		return;
	if (!MyKFPM.IsAliveAndWell() || (MyKFPM.Health - InDamage) > 0)
		return;   // not a killing blow

	H = class'DKUpgrade_Perk_JekyllHyde'.static.GetHelper(DamageInstigator.Pawn);
	if (H == None || H.bHyde)
		return;   // only bank from Jekyll-form kills

	H.AddBankedDuration(default.PerKill[upgLevel - 1], default.Cap[upgLevel - 1]);
}

defaultproperties
{
	bShouldLocalize=True
	LocPackage="ZedternalRBPerkpackage"
	LocSection="DKUpgrade_Skill_AdrenalineReserve"
	UpgradeName="Adrenaline Reserve"
	upgradeDescription(0)="Kills as <font color=\"#15d7fa\">Dr. Jekyll</font> bank <font color=\"#77d914\">+0.5s</font> each onto your next <font color=\"#be4d25\">Hyde</font> (max <font color=\"#77d914\">+5s</font>)."
	upgradeDescription(1)="Kills as <font color=\"#15d7fa\">Dr. Jekyll</font> bank <font color=\"#77d914\">+1s</font> each onto your next <font color=\"#be4d25\">Hyde</font> (max <font color=\"#77d914\">+10s</font>)."
	UpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_AdrenalineReserve'
	UpgradeIcon(1)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_AdrenalineReserve_Deluxe'
	Name="Default__DKUpgrade_Skill_AdrenalineReserve"
}
