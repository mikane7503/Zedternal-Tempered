// ===================================================================
// DKUpgrade_Skill_Mes - wheel-ability unlock (Domain), action 8.
//
// Unlocks "Mes": mark an aimed zed so it takes extra damage from you.
// Standard +100% for 8s; Deluxe +200% for 12s (perk config
// MesDamageBonusDeluxe / MesDurationDeluxe). Pushes its owned level
// into the Domain helper. Inert without the Domain perk.
// ===================================================================
class DKUpgrade_Skill_Mes extends DKUpgrade_Skill;

static simulated function InitiateWeapon(int upgLevel, KFWeapon KFW, KFPawn OwnerPawn)
{
	local DKUpgrade_Perk_Domain_Helper H;

	if (KFPawn_Human(OwnerPawn) == None || OwnerPawn.Role != ROLE_Authority)
		return;

	H = class'DKUpgrade_Perk_Domain'.static.FindHelper(OwnerPawn);
	if (H != None)
		H.SetAbilityUnlock(8, upgLevel);
}

static function WaveEnd(int upgLevel, KFPlayerController KFPC)
{
	local DKUpgrade_Perk_Domain_Helper H;

	if (KFPC == None || KFPC.Pawn == None)
		return;

	H = class'DKUpgrade_Perk_Domain'.static.FindHelper(KFPC.Pawn);
	if (H != None)
		H.SetAbilityUnlock(8, upgLevel);
}

static simulated function DeleteHelperClass(Pawn OwnerPawn)
{
	local DKUpgrade_Perk_Domain_Helper H;

	if (OwnerPawn == None)
		return;

	H = class'DKUpgrade_Perk_Domain'.static.FindHelper(OwnerPawn);
	if (H != None)
		H.SetAbilityUnlock(8, 0);
}

defaultproperties
{
	bShouldLocalize=True
	LocPackage="ZedternalRBPerkpackage"
	LocSection="DKUpgrade_Skill_Mes"

	UpgradeName="Mes"
	upgradeDescription(0)="Wheel ability: <font color=\"#ff3399\">mark</font> a zed; it takes <font color=\"#77d914\">+100%</font> of your damage for 8s."
	upgradeDescription(1)="Wheel ability: <font color=\"#ff3399\">mark</font> a zed; it takes <font color=\"#77d914\">+200%</font> of your damage for 12s."

	UpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_Mes'
	UpgradeIcon(1)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_Mes_Deluxe'

	Name="Default__DKUpgrade_Skill_Mes"
}
