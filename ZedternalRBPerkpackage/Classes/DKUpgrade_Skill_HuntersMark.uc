// ===================================================================
// DKUpgrade_Skill_HuntersMark - Speedfreak Blink Strike skill.
//
// ZEDs hit by Blink Strike are MARKED and take extra damage from YOU for
// a short time afterward (Standard +20%, Deluxe +35% for 6s) - rewarding
// the melee follow-up after the dash drops you back at your start.
//
// Two halves:
//   1) InitiateWeapon/WaveEnd/DeleteHelperClass push the owned level into
//      the Speedster helper so StrikeTarget() actually marks struck ZEDs.
//   2) ModifyDamageGiven reads the helper's mark registry live (same shape
//      as Gamma Knife) and adds the bonus to marked targets.
//
// Does nothing without the Speedfreak perk.
// ===================================================================
class DKUpgrade_Skill_HuntersMark extends DKUpgrade_Skill
	config(ZedternalUnlimited);

var config array<float> DamageBonus;    // [standard, deluxe] fraction of default damage
var config float MarkDuration;          // seconds a mark lasts
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.DamageBonus[0] = 0.20f;
		default.DamageBonus[1] = 0.35f;
		default.MarkDuration = 6.0f;

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
		H.ApplyHuntersMark(upgLevel);
}

static function WaveEnd(int upgLevel, KFPlayerController KFPC)
{
	local DKUpgrade_Perk_Speedster_Helper H;

	if (KFPC == None || KFPC.Pawn == None)
		return;

	H = class'DKUpgrade_Perk_Speedster'.static.FindHelper(KFPC.Pawn);
	if (H != None)
		H.ApplyHuntersMark(upgLevel);
}

static simulated function DeleteHelperClass(Pawn OwnerPawn)
{
	local DKUpgrade_Perk_Speedster_Helper H;

	if (OwnerPawn == None)
		return;

	H = class'DKUpgrade_Perk_Speedster'.static.FindHelper(OwnerPawn);
	if (H != None)
		H.ApplyHuntersMark(0);
}

static function ModifyDamageGiven(out int InDamage, int DefaultDamage, int upgLevel, optional Actor DamageCauser, optional KFPawn_Monster MyKFPM, optional KFPlayerController DamageInstigator, optional class<KFDamageType> DamageType, optional int HitZoneIdx, optional KFWeapon MyKFW)
{
	local DKUpgrade_Perk_Speedster_Helper H;

	if (MyKFPM == None || DamageInstigator == None || DamageInstigator.Pawn == None)
		return;

	H = class'DKUpgrade_Perk_Speedster'.static.FindHelper(DamageInstigator.Pawn);
	if (H != None && H.IsMarked(MyKFPM))
		InDamage += Round(float(DefaultDamage) * default.DamageBonus[upgLevel - 1]);
}

defaultproperties
{
	bShouldLocalize=True
	LocPackage="ZedternalRBPerkpackage"
	LocSection="DKUpgrade_Skill_HuntersMark"

	UpgradeName="Hunter's Mark"
	upgradeDescription(0)="ZEDs hit by <font color=\"#be4d25\">Blink Strike</font> take <font color=\"#77d914\">+20% damage</font> from you for 6s."
	upgradeDescription(1)="ZEDs hit by <font color=\"#be4d25\">Blink Strike</font> take <font color=\"#77d914\">+35% damage</font> from you for 6s."

	UpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_HuntersMark'
	UpgradeIcon(1)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_HuntersMark_Deluxe'

	Name="Default__DKUpgrade_Skill_HuntersMark"
}
