// ===================================================================
// DKUpgrade_Skill_ConcussiveBlink - Speedfreak Blink Strike skill.
//
// Makes each Blink Strike's knockdown far stronger (Standard +50%,
// Deluxe +100% knockdown force), flooring larger ZEDs more reliably.
// Pushes its owned level into the Speedster helper, which scales the
// Knockdown() call in StrikeTarget(). Does nothing without the
// Speedfreak perk.
// ===================================================================
class DKUpgrade_Skill_ConcussiveBlink extends DKUpgrade_Skill
	config(ZedternalUnlimited);

var config array<float> KnockdownBonus;    // [standard, deluxe] fraction added to knockdown force
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.KnockdownBonus[0] = 0.50f;
		default.KnockdownBonus[1] = 1.00f;

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
		H.ApplyConcussive(upgLevel);
}

static function WaveEnd(int upgLevel, KFPlayerController KFPC)
{
	local DKUpgrade_Perk_Speedster_Helper H;

	if (KFPC == None || KFPC.Pawn == None)
		return;

	H = class'DKUpgrade_Perk_Speedster'.static.FindHelper(KFPC.Pawn);
	if (H != None)
		H.ApplyConcussive(upgLevel);
}

static simulated function DeleteHelperClass(Pawn OwnerPawn)
{
	local DKUpgrade_Perk_Speedster_Helper H;

	if (OwnerPawn == None)
		return;

	H = class'DKUpgrade_Perk_Speedster'.static.FindHelper(OwnerPawn);
	if (H != None)
		H.ApplyConcussive(0);
}

defaultproperties
{
	bShouldLocalize=True
	LocPackage="ZedternalRBPerkpackage"
	LocSection="DKUpgrade_Skill_ConcussiveBlink"

	UpgradeName="Concussive Blink"
	upgradeDescription(0)="<font color=\"#be4d25\">Blink Strike</font> knockdowns are <font color=\"#77d914\">50% stronger</font>."
	upgradeDescription(1)="<font color=\"#be4d25\">Blink Strike</font> knockdowns are <font color=\"#77d914\">twice as strong</font>, flooring bigger ZEDs."

	UpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_ConcussiveBlink'
	UpgradeIcon(1)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_ConcussiveBlink_Deluxe'

	Name="Default__DKUpgrade_Skill_ConcussiveBlink"
}
