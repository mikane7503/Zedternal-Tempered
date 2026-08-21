// Hyde skill - Seismic Slam: wider melee shockwave with stronger knockback.
// Feeds the helper's shockwave (radius + momentum); no per-hit hook.
class ZTUpgrade_Skill_SeismicSlam extends ZTUpgrade_Skill config(ZedternalUnlimited);

var config array<float> RadiusBonus;
var config array<float> MomentumMult;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.RadiusBonus[0] = 0.25f;   default.RadiusBonus[1] = 0.50f;
		default.MomentumMult[0] = 1.5f;   default.MomentumMult[1] = 2.0f;
		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static simulated function InitiateWeapon(int upgLevel, KFWeapon KFW, KFPawn OwnerPawn)
{
	local ZTUpgrade_Perk_JekyllHyde_Helper H;
	if (KFPawn_Human(OwnerPawn) == None || OwnerPawn.Role != ROLE_Authority)
		return;
	H = class'ZTUpgrade_Perk_JekyllHyde'.static.GetHelper(OwnerPawn);
	if (H == None) return;
	H.SeismicRadiusBonus = default.RadiusBonus[upgLevel - 1];
	H.SeismicMomentumMult = default.MomentumMult[upgLevel - 1];
}

static simulated function DeleteHelperClass(Pawn OwnerPawn)
{
	local ZTUpgrade_Perk_JekyllHyde_Helper H;
	if (OwnerPawn == None) return;
	H = class'ZTUpgrade_Perk_JekyllHyde'.static.FindHelper(OwnerPawn);
	if (H != None) H.ResetSeismic();
}

defaultproperties
{
	bShouldLocalize=True
	LocPackage="ZedternalTempered"
	LocSection="ZTUpgrade_Skill_SeismicSlam"
	UpgradeName="Seismic Slam"
	upgradeDescription(0)="<font color=\"#be4d25\">Hyde</font> melee shockwave is <font color=\"#77d914\">+25%</font> wider with stronger knockback."
	upgradeDescription(1)="<font color=\"#be4d25\">Hyde</font> melee shockwave is <font color=\"#77d914\">+50%</font> wider with much stronger knockback."
	UpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_SeismicSlam'
	UpgradeIcon(1)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_SeismicSlam_Deluxe'
	Name="Default__ZTUpgrade_Skill_SeismicSlam"
}
