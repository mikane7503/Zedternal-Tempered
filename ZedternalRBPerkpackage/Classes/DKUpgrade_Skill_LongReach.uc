// ===================================================================
// DKUpgrade_Skill_LongReach - Speedfreak Blink Strike skill.
//
// Widens the Blink Strike tag range (Standard +30%, Deluxe +60%), so
// the dash pulls in ZEDs from farther away. Pushes its owned level into
// the Speedster helper, which scales the gather radius in
// GatherTargets(). Does nothing without the Speedfreak perk.
// ===================================================================
class DKUpgrade_Skill_LongReach extends DKUpgrade_Skill
	config(ZedternalUnlimited);

var config array<float> RangeBonus;    // [standard, deluxe] fraction
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.RangeBonus[0] = 0.30f;
		default.RangeBonus[1] = 0.60f;

		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static simulated function InitiateWeapon(int upgLevel, KFWeapon KFW, KFPawn OwnerPawn)
{
	local DKUpgrade_Perk_Speedster_Helper H;

	if (KFPawn_Human(OwnerPawn) == None || OwnerPawn.Role != ROLE_Authority)
		return;

	H = class'DKUpgrade_Perk_Speedster'.static.FindHelper(OwnerPawn);
	if (H != None)
		H.ApplyLongReach(upgLevel);
}

static function WaveEnd(int upgLevel, KFPlayerController KFPC)
{
	local DKUpgrade_Perk_Speedster_Helper H;

	if (KFPC == None || KFPC.Pawn == None)
		return;

	H = class'DKUpgrade_Perk_Speedster'.static.FindHelper(KFPC.Pawn);
	if (H != None)
		H.ApplyLongReach(upgLevel);
}

static simulated function DeleteHelperClass(Pawn OwnerPawn)
{
	local DKUpgrade_Perk_Speedster_Helper H;

	if (OwnerPawn == None)
		return;

	H = class'DKUpgrade_Perk_Speedster'.static.FindHelper(OwnerPawn);
	if (H != None)
		H.ApplyLongReach(0);
}

defaultproperties
{
	bShouldLocalize=True
	LocPackage="ZedternalRBPerkpackage"
	LocSection="DKUpgrade_Skill_LongReach"

	UpgradeName="Long Reach"
	upgradeDescription(0)="<font color=\"#be4d25\">Blink Strike</font> reaches <font color=\"#77d914\">30% farther</font> for targets."
	upgradeDescription(1)="<font color=\"#be4d25\">Blink Strike</font> reaches <font color=\"#77d914\">60% farther</font> for targets."

	UpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_LongReach'
	UpgradeIcon(1)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_LongReach_Deluxe'

	Name="Default__DKUpgrade_Skill_LongReach"
}
