// ===================================================================
// ZTUpgrade_Skill_Shockfront - Speedfreak Blink Strike skill.
//
// Each Blink Strike emits a small damaging shockwave around the landing
// point (Standard 30% of the strike in 250uu, Deluxe 50% in 300uu).
// This is INDEPENDENT of the Level 20 capstone cleave, so it is useful
// the moment you buy it and stacks with the capstone. Pushes its owned
// level into the Speedster helper, which fires DoShockfront() inside
// StrikeTarget(). Does nothing without the Speedfreak perk.
// ===================================================================
class ZTUpgrade_Skill_Shockfront extends ZTUpgrade_Skill config(ZedternalUnlimited);

var config array<float> Radius;        // [standard, deluxe] uu
var config array<float> DamageFrac;    // [standard, deluxe] fraction of strike damage
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Radius[0] = 250.0f;
		default.Radius[1] = 300.0f;
		default.DamageFrac[0] = 0.30f;
		default.DamageFrac[1] = 0.50f;

		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static simulated function InitiateWeapon(int upgLevel, KFWeapon KFW, KFPawn OwnerPawn)
{
	local ZTUpgrade_Perk_Speedster_Helper H;

	if (KFPawn_Human(OwnerPawn) == None || OwnerPawn.Role != ROLE_Authority)
		return;

	H = class'ZTUpgrade_Perk_Speedster'.static.FindHelper(OwnerPawn);
	if (H != None)
		H.ApplyShockfront(upgLevel);
}

static function WaveEnd(int upgLevel, KFPlayerController KFPC)
{
	local ZTUpgrade_Perk_Speedster_Helper H;

	if (KFPC == None || KFPC.Pawn == None)
		return;

	H = class'ZTUpgrade_Perk_Speedster'.static.FindHelper(KFPC.Pawn);
	if (H != None)
		H.ApplyShockfront(upgLevel);
}

static simulated function DeleteHelperClass(Pawn OwnerPawn)
{
	local ZTUpgrade_Perk_Speedster_Helper H;

	if (OwnerPawn == None)
		return;

	H = class'ZTUpgrade_Perk_Speedster'.static.FindHelper(OwnerPawn);
	if (H != None)
		H.ApplyShockfront(0);
}

defaultproperties
{
	bShouldLocalize=True
	LocPackage="ZedternalTempered"
	LocSection="ZTUpgrade_Skill_Shockfront"

	UpgradeName="Shockfront"
	upgradeDescription(0)="Each <font color=\"#be4d25\">Blink Strike</font> blasts nearby ZEDs for <font color=\"#77d914\">30%</font> of the strike."
	upgradeDescription(1)="Each <font color=\"#be4d25\">Blink Strike</font> blasts a wider area for <font color=\"#77d914\">50%</font> of the strike."

	UpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_Shockfront'
	UpgradeIcon(1)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_Shockfront_Deluxe'

	Name="Default__ZTUpgrade_Skill_Shockfront"
}
