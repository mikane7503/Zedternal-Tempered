// ===================================================================
// ZTUpgrade_Skill_MobileRoom - passive Domain skill.
//
// The Room re-centers on you every tick instead of staying where it was
// cast, so it roams with you. Deluxe also extends the Room's duration by
// DeluxeDurationBonus seconds. Pushes its owned level into the Domain
// helper (UpdateAbility re-centers when MobileRoomLevel >= 1). Does
// nothing without the Domain perk.
// ===================================================================
class ZTUpgrade_Skill_MobileRoom extends ZTUpgrade_Skill config(ZedternalUnlimited);

var config float DeluxeDurationBonus;    // extra seconds at Deluxe tier
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.DeluxeDurationBonus = 3.0f;

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
		H.ApplyMobileRoom(upgLevel);
}

static function WaveEnd(int upgLevel, KFPlayerController KFPC)
{
	local ZTUpgrade_Perk_Domain_Helper H;

	if (KFPC == None || KFPC.Pawn == None)
		return;

	H = class'ZTUpgrade_Perk_Domain'.static.FindHelper(KFPC.Pawn);
	if (H != None)
		H.ApplyMobileRoom(upgLevel);
}

static simulated function DeleteHelperClass(Pawn OwnerPawn)
{
	local ZTUpgrade_Perk_Domain_Helper H;

	if (OwnerPawn == None)
		return;

	H = class'ZTUpgrade_Perk_Domain'.static.FindHelper(OwnerPawn);
	if (H != None)
		H.ApplyMobileRoom(0);
}

defaultproperties
{
	bShouldLocalize=True
	LocPackage="ZedternalTempered"
	LocSection="ZTUpgrade_Skill_MobileRoom"

	UpgradeName="Mobile Room"
	upgradeDescription(0)="Your <font color=\"#be4d25\">Room</font> follows you instead of staying where it was cast."
	upgradeDescription(1)="Your <font color=\"#be4d25\">Room</font> follows you and lasts <font color=\"#77d914\">3s longer</font>."

	UpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_MobileRoom'
	UpgradeIcon(1)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_MobileRoom_Deluxe'

	Name="Default__ZTUpgrade_Skill_MobileRoom"
}
