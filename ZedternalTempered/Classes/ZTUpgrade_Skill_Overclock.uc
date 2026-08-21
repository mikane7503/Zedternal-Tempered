// ===================================================================
// ZTUpgrade_Skill_Overclock - Speedfreak Blink Strike skill.
//
// Shaves the Blink Strike cooldown (Standard -15%, Deluxe -25%).
// Pushes its owned level into the Speedster helper, which applies the
// reduction live in GetCooldown(). Does nothing without the Speedfreak
// perk.
// ===================================================================
class ZTUpgrade_Skill_Overclock extends ZTUpgrade_Skill config(ZedternalUnlimited);

var config array<float> CooldownReduction;    // [standard, deluxe] fraction
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.CooldownReduction[0] = 0.15f;
		default.CooldownReduction[1] = 0.25f;

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
		H.ApplyOverclock(upgLevel);
}

static function WaveEnd(int upgLevel, KFPlayerController KFPC)
{
	local ZTUpgrade_Perk_Speedster_Helper H;

	if (KFPC == None || KFPC.Pawn == None)
		return;

	H = class'ZTUpgrade_Perk_Speedster'.static.FindHelper(KFPC.Pawn);
	if (H != None)
		H.ApplyOverclock(upgLevel);
}

static simulated function DeleteHelperClass(Pawn OwnerPawn)
{
	local ZTUpgrade_Perk_Speedster_Helper H;

	if (OwnerPawn == None)
		return;

	H = class'ZTUpgrade_Perk_Speedster'.static.FindHelper(OwnerPawn);
	if (H != None)
		H.ApplyOverclock(0);
}

defaultproperties
{
	bShouldLocalize=True
	LocPackage="ZedternalTempered"
	LocSection="ZTUpgrade_Skill_Overclock"

	UpgradeName="Overclock"
	upgradeDescription(0)="<font color=\"#ffaa33\">15% shorter</font> <font color=\"#be4d25\">Blink Strike</font> cooldown."
	upgradeDescription(1)="<font color=\"#ffaa33\">25% shorter</font> <font color=\"#be4d25\">Blink Strike</font> cooldown."

	UpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_Overclock'
	UpgradeIcon(1)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_Overclock_Deluxe'

	Name="Default__ZTUpgrade_Skill_Overclock"
}
