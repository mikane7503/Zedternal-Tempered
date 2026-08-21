// Sweeper Keeper - Goalkeeper synergy: wider + longer catch reach. Inert without the perk.
class ZTUpgrade_Skill_SweeperKeeper extends ZTUpgrade_Skill
	config(ZedternalUnlimited);

var config array<float> RangeMult;
var config array<float> ConeMult; // multiplies the dot THRESHOLD down = wider cone
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.RangeMult[0] = 1.30f;
		default.RangeMult[1] = 1.60f;
		default.ConeMult[0] = 0.70f;
		default.ConeMult[1] = 0.40f;
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
		H.SetSkillReach(default.RangeMult[upgLevel - 1], default.ConeMult[upgLevel - 1]);
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
		H.SetSkillReach(1.0f, 1.0f);
}

defaultproperties
{
	bShouldLocalize=True
	LocPackage="ZedternalTempered"
	LocSection="ZTUpgrade_Skill_SweeperKeeper"

	UpgradeName="Sweeper Keeper"
	upgradeDescription(0)="<font color=\"#15d7fa\">Goalkeeper only:</font> catch range <font color=\"#77d914\">+30%</font> and a noticeably <font color=\"#77d914\">wider catch cone</font>."
	upgradeDescription(1)="<font color=\"#15d7fa\">Goalkeeper only:</font> catch range <font color=\"#77d914\">+60%</font> and a <font color=\"#77d914\">massively wider catch cone</font>."
	UpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_SweeperKeeper'
	UpgradeIcon(1)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_SweeperKeeper_Deluxe'
	Name="Default__ZTUpgrade_Skill_SweeperKeeper"
}
