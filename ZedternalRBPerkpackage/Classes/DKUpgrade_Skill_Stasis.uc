// ===================================================================
// DKUpgrade_Skill_Stasis - wheel-ability unlock (Domain), action 4.
//
// Unlocks "Stasis": freezes every non-boss zed in the Room. Deluxe
// extends the freeze duration (perk config FreezeDurationDeluxe).
// Pushes its owned level into the Domain helper, which gates the
// ability in FireAction. Inert without the Domain perk.
// ===================================================================
class DKUpgrade_Skill_Stasis extends DKUpgrade_Skill;

static simulated function InitiateWeapon(int upgLevel, KFWeapon KFW, KFPawn OwnerPawn)
{
	local DKUpgrade_Perk_Domain_Helper H;

	if (KFPawn_Human(OwnerPawn) == None || OwnerPawn.Role != ROLE_Authority)
		return;

	H = class'DKUpgrade_Perk_Domain'.static.FindHelper(OwnerPawn);
	if (H != None)
		H.SetAbilityUnlock(4, upgLevel);
}

static function WaveEnd(int upgLevel, KFPlayerController KFPC)
{
	local DKUpgrade_Perk_Domain_Helper H;

	if (KFPC == None || KFPC.Pawn == None)
		return;

	H = class'DKUpgrade_Perk_Domain'.static.FindHelper(KFPC.Pawn);
	if (H != None)
		H.SetAbilityUnlock(4, upgLevel);
}

static simulated function DeleteHelperClass(Pawn OwnerPawn)
{
	local DKUpgrade_Perk_Domain_Helper H;

	if (OwnerPawn == None)
		return;

	H = class'DKUpgrade_Perk_Domain'.static.FindHelper(OwnerPawn);
	if (H != None)
		H.SetAbilityUnlock(4, 0);
}

defaultproperties
{
	bShouldLocalize=True
	LocPackage="ZedternalRBPerkpackage"
	LocSection="DKUpgrade_Skill_Stasis"

	UpgradeName="Stasis"
	upgradeDescription(0)="Wheel ability: <font color=\"#15d7fa\">freeze</font> every non-boss zed in your <font color=\"#be4d25\">Room</font>."
	upgradeDescription(1)="Wheel ability: <font color=\"#15d7fa\">freeze</font> every non-boss zed in your <font color=\"#be4d25\">Room</font> for <font color=\"#77d914\">longer</font>."

	UpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_Stasis'
	UpgradeIcon(1)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_Stasis_Deluxe'

	Name="Default__DKUpgrade_Skill_Stasis"
}
