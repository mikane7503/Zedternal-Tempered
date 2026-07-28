// ===================================================================
// DKUpgrade_Skill_Momentum - Speedfreak Blink Strike skill.
//
// Refunds Blink Strike cooldown for every ZED the dash kills (Standard
// 1.0s/kill, Deluxe 1.5s/kill), capped at 75% of the cooldown. Pushes
// its owned level into the Speedster helper, which counts dash kills and
// trims the cooldown in EndBlink(). Does nothing without the Speedfreak
// perk.
// ===================================================================
class DKUpgrade_Skill_Momentum extends DKUpgrade_Skill
	config(ZedternalUnlimited);

var config array<float> RefundPerKill;    // [standard, deluxe] seconds per dash kill
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.RefundPerKill[0] = 1.0f;
		default.RefundPerKill[1] = 1.5f;

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
		H.ApplyMomentum(upgLevel);
}

static function WaveEnd(int upgLevel, KFPlayerController KFPC)
{
	local DKUpgrade_Perk_Speedster_Helper H;

	if (KFPC == None || KFPC.Pawn == None)
		return;

	H = class'DKUpgrade_Perk_Speedster'.static.FindHelper(KFPC.Pawn);
	if (H != None)
		H.ApplyMomentum(upgLevel);
}

static simulated function DeleteHelperClass(Pawn OwnerPawn)
{
	local DKUpgrade_Perk_Speedster_Helper H;

	if (OwnerPawn == None)
		return;

	H = class'DKUpgrade_Perk_Speedster'.static.FindHelper(OwnerPawn);
	if (H != None)
		H.ApplyMomentum(0);
}

defaultproperties
{
	bShouldLocalize=True
	LocPackage="ZedternalRBPerkpackage"
	LocSection="DKUpgrade_Skill_Momentum"

	UpgradeName="Momentum"
	upgradeDescription(0)="<font color=\"#be4d25\">Blink Strike</font> refunds <font color=\"#ffaa33\">1.0s</font> cooldown per ZED the dash kills."
	upgradeDescription(1)="<font color=\"#be4d25\">Blink Strike</font> refunds <font color=\"#ffaa33\">1.5s</font> cooldown per ZED the dash kills."

	UpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_Momentum'
	UpgradeIcon(1)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_Momentum_Deluxe'

	Name="Default__DKUpgrade_Skill_Momentum"
}
