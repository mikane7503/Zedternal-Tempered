// ===================================================================
// ZTUpgrade_Skill_OpenSeason - Speedfreak Blink Strike skill.
//
// Blink Strike tags +1 (Standard) / +2 (Deluxe) extra ZEDs per cast.
// Pushes its owned level into the Speedster helper, which adds it into
// GetMaxTargets(). Does nothing without the Speedfreak perk
// (FindHelper returns None).
// ===================================================================
class ZTUpgrade_Skill_OpenSeason extends ZTUpgrade_Skill config(ZedternalUnlimited);

var config array<int> TargetBonus;    // [standard, deluxe] extra targets
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.TargetBonus[0] = 1;
		default.TargetBonus[1] = 2;

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
		H.ApplyOpenSeason(upgLevel);
}

static function WaveEnd(int upgLevel, KFPlayerController KFPC)
{
	local ZTUpgrade_Perk_Speedster_Helper H;

	if (KFPC == None || KFPC.Pawn == None)
		return;

	H = class'ZTUpgrade_Perk_Speedster'.static.FindHelper(KFPC.Pawn);
	if (H != None)
		H.ApplyOpenSeason(upgLevel);
}

static simulated function DeleteHelperClass(Pawn OwnerPawn)
{
	local ZTUpgrade_Perk_Speedster_Helper H;

	if (OwnerPawn == None)
		return;

	H = class'ZTUpgrade_Perk_Speedster'.static.FindHelper(OwnerPawn);
	if (H != None)
		H.ApplyOpenSeason(0);
}

defaultproperties
{
	bShouldLocalize=True
	LocPackage="ZedternalTempered"
	LocSection="ZTUpgrade_Skill_OpenSeason"

	UpgradeName="Open Season"
	upgradeDescription(0)="<font color=\"#be4d25\">Blink Strike</font> hits <font color=\"#77d914\">1 more</font> ZED per cast."
	upgradeDescription(1)="<font color=\"#be4d25\">Blink Strike</font> hits <font color=\"#77d914\">2 more</font> ZEDs per cast."

	UpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_OpenSeason'
	UpgradeIcon(1)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_OpenSeason_Deluxe'

	Name="Default__ZTUpgrade_Skill_OpenSeason"
}
