// Punt - Goalkeeper synergy: perfect-catch range widened. Inert without the perk.
class ZTUpgrade_Skill_Punt extends ZTUpgrade_Skill
	config(ZedternalUnlimited);

var config array<float> PerfectMult;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.PerfectMult[0] = 1.75f;
		default.PerfectMult[1] = 2.50f;
		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static simulated function InitiateWeapon(int upgLevel, KFWeapon KFW, KFPawn OwnerPawn)
{
	local ZTUpgrade_Perk_Goalkeeper_Helper H;

	if (KFPawn_Human(OwnerPawn) == None || OwnerPawn.Role != ROLE_Authority)
		return;

	H = class'ZTUpgrade_Perk_Goalkeeper'.static.FindHelper(OwnerPawn);
	if (H != None)
		H.SetSkillPerfectMult(default.PerfectMult[upgLevel - 1]);
}

static function WaveEnd(int upgLevel, KFPlayerController KFPC)
{
	if (KFPC != None && KFPC.Pawn != None)
		InitiateWeapon(upgLevel, None, KFPawn(KFPC.Pawn));
}

static simulated function DeleteHelperClass(Pawn OwnerPawn)
{
	local ZTUpgrade_Perk_Goalkeeper_Helper H;

	if (OwnerPawn == None)
		return;

	H = class'ZTUpgrade_Perk_Goalkeeper'.static.FindHelper(OwnerPawn);
	if (H != None)
		H.SetSkillPerfectMult(1.0f);
}

defaultproperties
{
	bShouldLocalize=True
	LocPackage="ZedternalTempered"
	LocSection="ZTUpgrade_Skill_Punt"

	UpgradeName="Punt"
	upgradeDescription(0)="<font color=\"#15d7fa\">Goalkeeper only:</font> <font color=\"#FFD700\">Perfect catch</font> range <font color=\"#77d914\">+75%</font>."
	upgradeDescription(1)="<font color=\"#15d7fa\">Goalkeeper only:</font> <font color=\"#FFD700\">Perfect catch</font> range <font color=\"#77d914\">+150%</font>."
	UpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_Punt'
	UpgradeIcon(1)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_Punt_Deluxe'
	Name="Default__ZTUpgrade_Skill_Punt"
}
