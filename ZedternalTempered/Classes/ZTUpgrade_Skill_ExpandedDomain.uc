// ===================================================================
// ZTUpgrade_Skill_ExpandedDomain - passive Domain skill.
//
// Grows the Room's radius and duration (Standard +15%, Deluxe +30%).
// Pushes its owned level into the Domain helper, which factors it into
// the room math in SetPerkLevel(). Does nothing without the Domain perk
// (FindHelper returns None).
// ===================================================================
class ZTUpgrade_Skill_ExpandedDomain extends ZTUpgrade_Skill config(ZedternalUnlimited);

var config array<float> RadiusBonus;    // [standard, deluxe] fraction
var config array<float> DurationBonus;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.RadiusBonus[0] = 0.15f;
		default.RadiusBonus[1] = 0.30f;
		default.DurationBonus[0] = 0.15f;
		default.DurationBonus[1] = 0.30f;

		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static simulated function InitiateWeapon(int upgLevel, KFWeapon KFW, KFPawn OwnerPawn)
{
	local ZTUpgrade_Perk_Domain_Helper H;

	if (KFPawn_Human(OwnerPawn) == None || OwnerPawn.Role != ROLE_Authority)
		return;

	H = class'ZTUpgrade_Perk_Domain'.static.FindHelper(OwnerPawn);
	if (H != None)
		H.ApplyExpandedDomain(upgLevel);
}

static function WaveEnd(int upgLevel, KFPlayerController KFPC)
{
	local ZTUpgrade_Perk_Domain_Helper H;

	if (KFPC == None || KFPC.Pawn == None)
		return;

	H = class'ZTUpgrade_Perk_Domain'.static.FindHelper(KFPC.Pawn);
	if (H != None)
		H.ApplyExpandedDomain(upgLevel);
}

static simulated function DeleteHelperClass(Pawn OwnerPawn)
{
	local ZTUpgrade_Perk_Domain_Helper H;

	if (OwnerPawn == None)
		return;

	H = class'ZTUpgrade_Perk_Domain'.static.FindHelper(OwnerPawn);
	if (H != None)
		H.ApplyExpandedDomain(0);
}

defaultproperties
{
	bShouldLocalize=True
	LocPackage="ZedternalTempered"
	LocSection="ZTUpgrade_Skill_ExpandedDomain"

	UpgradeName="Expanded Domain"
	upgradeDescription(0)="Your <font color=\"#be4d25\">Room</font> is <font color=\"#77d914\">15% larger</font> and lasts <font color=\"#77d914\">15% longer</font>."
	upgradeDescription(1)="Your <font color=\"#be4d25\">Room</font> is <font color=\"#77d914\">30% larger</font> and lasts <font color=\"#77d914\">30% longer</font>."

	UpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_ExpandedDomain'
	UpgradeIcon(1)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_ExpandedDomain_Deluxe'

	Name="Default__ZTUpgrade_Skill_ExpandedDomain"
}
