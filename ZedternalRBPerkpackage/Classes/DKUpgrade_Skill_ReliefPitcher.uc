// Relief Pitcher - Fastball synergy: reload + speed buff for 6s after your payload lands.
// State (ReliefEndTime) lives on the Fastball helper; hooks read it conditionally.
class DKUpgrade_Skill_ReliefPitcher extends DKUpgrade_Skill
	config(ZedternalUnlimited);

var config array<float> ReloadBonus;
var config array<float> SpeedBonus;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.ReloadBonus[0] = 0.20f;
		default.ReloadBonus[1] = 0.35f;
		default.SpeedBonus[0] = 0.10f;
		default.SpeedBonus[1] = 0.20f;
		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static simulated function InitiateWeapon(int upgLevel, KFWeapon KFW, KFPawn OwnerPawn)
{
	local DKUpgrade_Perk_Fastball_Helper H;

	if (KFPawn_Human(OwnerPawn) == None || OwnerPawn.Role != ROLE_Authority)
		return;

	H = class'DKUpgrade_Perk_Fastball'.static.FindHelper(OwnerPawn);
	if (H != None)
		H.SetSkillReliefLevel(upgLevel);
}

static function WaveEnd(int upgLevel, KFPlayerController KFPC)
{
	if (KFPC != None && KFPC.Pawn != None)
		InitiateWeapon(upgLevel, None, KFPawn(KFPC.Pawn));
}

static simulated function GetReloadRateScale(out float InReloadRateScale, int upgLevel, KFWeapon KFW, KFPawn OwnerPawn)
{
	local DKUpgrade_Perk_Fastball_Helper H;

	H = class'DKUpgrade_Perk_Fastball'.static.FindHelper(OwnerPawn);
	if (H == None || H.WorldInfo.TimeSeconds >= H.ReliefEndTime)
		return;

	InReloadRateScale = 1.0f / (1.0f / InReloadRateScale + default.ReloadBonus[upgLevel - 1]);
}

static simulated function ModifySpeed(out float InSpeed, float DefaultSpeed, int upgLevel, KFPawn OwnerPawn)
{
	local DKUpgrade_Perk_Fastball_Helper H;

	H = class'DKUpgrade_Perk_Fastball'.static.FindHelper(OwnerPawn);
	if (H == None || H.WorldInfo.TimeSeconds >= H.ReliefEndTime)
		return;

	InSpeed += DefaultSpeed * default.SpeedBonus[upgLevel - 1];
}

static simulated function DeleteHelperClass(Pawn OwnerPawn)
{
	local DKUpgrade_Perk_Fastball_Helper H;

	if (OwnerPawn == None)
		return;

	H = class'DKUpgrade_Perk_Fastball'.static.FindHelper(OwnerPawn);
	if (H != None)
		H.SetSkillReliefLevel(0);
}

defaultproperties
{
	bShouldLocalize=True
	LocPackage="ZedternalRBPerkpackage"
	LocSection="DKUpgrade_Skill_ReliefPitcher"

	UpgradeName="Relief Pitcher"
	upgradeDescription(0)="<font color=\"#15d7fa\">Fastball only:</font> when your payload lands you gain <font color=\"#77d914\">+20% Reload</font> and <font color=\"#77d914\">+10% Speed</font> for 6s."
	upgradeDescription(1)="<font color=\"#15d7fa\">Fastball only:</font> when your payload lands you gain <font color=\"#77d914\">+35% Reload</font> and <font color=\"#77d914\">+20% Speed</font> for 6s."
	UpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_ReliefPitcher'
	UpgradeIcon(1)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_ReliefPitcher_Deluxe'
	Name="Default__DKUpgrade_Skill_ReliefPitcher"
}
