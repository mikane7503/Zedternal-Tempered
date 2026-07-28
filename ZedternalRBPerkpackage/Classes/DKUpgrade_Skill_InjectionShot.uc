// ===================================================================
// DKUpgrade_Skill_InjectionShot - wheel-ability unlock (Domain), action 7.
//
// Unlocks "Injection Shot": a piercing line that damages zeds along
// your aim, inside the Room. Deluxe widens the line and hits harder
// (perk config InjectionDamageDeluxe). Pushes its owned level into the
// Domain helper. Inert without the Domain perk.
// ===================================================================
class DKUpgrade_Skill_InjectionShot extends DKUpgrade_Skill;

static simulated function InitiateWeapon(int upgLevel, KFWeapon KFW, KFPawn OwnerPawn)
{
	local DKUpgrade_Perk_Domain_Helper H;

	if (KFPawn_Human(OwnerPawn) == None || OwnerPawn.Role != ROLE_Authority)
		return;

	H = class'DKUpgrade_Perk_Domain'.static.FindHelper(OwnerPawn);
	if (H != None)
		H.SetAbilityUnlock(7, upgLevel);
}

static function WaveEnd(int upgLevel, KFPlayerController KFPC)
{
	local DKUpgrade_Perk_Domain_Helper H;

	if (KFPC == None || KFPC.Pawn == None)
		return;

	H = class'DKUpgrade_Perk_Domain'.static.FindHelper(KFPC.Pawn);
	if (H != None)
		H.SetAbilityUnlock(7, upgLevel);
}

static simulated function DeleteHelperClass(Pawn OwnerPawn)
{
	local DKUpgrade_Perk_Domain_Helper H;

	if (OwnerPawn == None)
		return;

	H = class'DKUpgrade_Perk_Domain'.static.FindHelper(OwnerPawn);
	if (H != None)
		H.SetAbilityUnlock(7, 0);
}

defaultproperties
{
	bShouldLocalize=True
	LocPackage="ZedternalRBPerkpackage"
	LocSection="DKUpgrade_Skill_InjectionShot"

	UpgradeName="Injection Shot"
	upgradeDescription(0)="Wheel ability: fire a <font color=\"#be4d25\">piercing line</font> that hits every zed along your aim."
	upgradeDescription(1)="Wheel ability: a <font color=\"#77d914\">wider</font> piercing line for <font color=\"#77d914\">more damage</font>."

	UpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_InjectionShot'
	UpgradeIcon(1)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_InjectionShot_Deluxe'

	Name="Default__DKUpgrade_Skill_InjectionShot"
}
