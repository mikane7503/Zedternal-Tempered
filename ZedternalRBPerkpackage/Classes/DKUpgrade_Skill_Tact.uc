// ===================================================================
// DKUpgrade_Skill_Tact - wheel-ability unlock (Domain), action 6.
//
// Unlocks "Tact": launches every non-boss zed in the Room skyward for
// slam damage + knockdown. Deluxe launches higher and hits harder
// (perk config TactDamageDeluxe). Pushes its owned level into the
// Domain helper. Inert without the Domain perk.
// ===================================================================
class DKUpgrade_Skill_Tact extends DKUpgrade_Skill;

static simulated function InitiateWeapon(int upgLevel, KFWeapon KFW, KFPawn OwnerPawn)
{
	local DKUpgrade_Perk_Domain_Helper H;

	if (KFPawn_Human(OwnerPawn) == None || OwnerPawn.Role != ROLE_Authority)
		return;

	H = class'DKUpgrade_Perk_Domain'.static.FindHelper(OwnerPawn);
	if (H != None)
		H.SetAbilityUnlock(6, upgLevel);
}

static function WaveEnd(int upgLevel, KFPlayerController KFPC)
{
	local DKUpgrade_Perk_Domain_Helper H;

	if (KFPC == None || KFPC.Pawn == None)
		return;

	H = class'DKUpgrade_Perk_Domain'.static.FindHelper(KFPC.Pawn);
	if (H != None)
		H.SetAbilityUnlock(6, upgLevel);
}

static simulated function DeleteHelperClass(Pawn OwnerPawn)
{
	local DKUpgrade_Perk_Domain_Helper H;

	if (OwnerPawn == None)
		return;

	H = class'DKUpgrade_Perk_Domain'.static.FindHelper(OwnerPawn);
	if (H != None)
		H.SetAbilityUnlock(6, 0);
}

defaultproperties
{
	bShouldLocalize=True
	LocPackage="ZedternalRBPerkpackage"
	LocSection="DKUpgrade_Skill_Tact"

	UpgradeName="Tact"
	upgradeDescription(0)="Wheel ability: <font color=\"#be4d25\">launch</font> every non-boss zed in your Room skyward for slam damage."
	upgradeDescription(1)="Wheel ability: <font color=\"#be4d25\">launch</font> them <font color=\"#77d914\">higher</font> for <font color=\"#77d914\">more damage</font>."

	UpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_Tact'
	UpgradeIcon(1)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_Tact_Deluxe'

	Name="Default__DKUpgrade_Skill_Tact"
}
