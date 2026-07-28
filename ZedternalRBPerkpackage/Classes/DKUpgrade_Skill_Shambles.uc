// ===================================================================
// DKUpgrade_Skill_Shambles - wheel-ability unlock (Domain), action 5.
//
// Unlocks "Shambles": yanks every non-boss zed in the Room to a point
// in front of you. Deluxe also knocks the clumped horde down on arrival.
// Pushes its owned level into the Domain helper. Inert without the
// Domain perk.
// ===================================================================
class DKUpgrade_Skill_Shambles extends DKUpgrade_Skill;

static simulated function InitiateWeapon(int upgLevel, KFWeapon KFW, KFPawn OwnerPawn)
{
	local DKUpgrade_Perk_Domain_Helper H;

	if (KFPawn_Human(OwnerPawn) == None || OwnerPawn.Role != ROLE_Authority)
		return;

	H = class'DKUpgrade_Perk_Domain'.static.FindHelper(OwnerPawn);
	if (H != None)
		H.SetAbilityUnlock(5, upgLevel);
}

static function WaveEnd(int upgLevel, KFPlayerController KFPC)
{
	local DKUpgrade_Perk_Domain_Helper H;

	if (KFPC == None || KFPC.Pawn == None)
		return;

	H = class'DKUpgrade_Perk_Domain'.static.FindHelper(KFPC.Pawn);
	if (H != None)
		H.SetAbilityUnlock(5, upgLevel);
}

static simulated function DeleteHelperClass(Pawn OwnerPawn)
{
	local DKUpgrade_Perk_Domain_Helper H;

	if (OwnerPawn == None)
		return;

	H = class'DKUpgrade_Perk_Domain'.static.FindHelper(OwnerPawn);
	if (H != None)
		H.SetAbilityUnlock(5, 0);
}

defaultproperties
{
	bShouldLocalize=True
	LocPackage="ZedternalRBPerkpackage"
	LocSection="DKUpgrade_Skill_Shambles"

	UpgradeName="Shambles"
	upgradeDescription(0)="Wheel ability: <font color=\"#be4d25\">pull</font> every non-boss zed in your Room to a point in front of you."
	upgradeDescription(1)="Wheel ability: <font color=\"#be4d25\">pull</font> every non-boss zed in your Room together and <font color=\"#77d914\">knock them down</font>."

	UpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_Shambles'
	UpgradeIcon(1)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_Shambles_Deluxe'

	Name="Default__DKUpgrade_Skill_Shambles"
}
