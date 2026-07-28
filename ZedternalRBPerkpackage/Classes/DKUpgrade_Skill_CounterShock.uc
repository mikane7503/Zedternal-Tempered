// ===================================================================
// DKUpgrade_Skill_CounterShock - wheel-ability unlock (Domain), action 9.
//
// Unlocks "CounterShock": an EMP + stun pulse across the Room (disrupts
// Husks/Sirens/specials, stuns trash). Deluxe also deals real damage
// (perk config CounterShockDamageDeluxe). Pushes its owned level into the
// Domain helper. Inert without the Domain perk.
// ===================================================================
class DKUpgrade_Skill_CounterShock extends DKUpgrade_Skill;

static simulated function InitiateWeapon(int upgLevel, KFWeapon KFW, KFPawn OwnerPawn)
{
	local DKUpgrade_Perk_Domain_Helper H;

	if (KFPawn_Human(OwnerPawn) == None || OwnerPawn.Role != ROLE_Authority)
		return;

	H = class'DKUpgrade_Perk_Domain'.static.FindHelper(OwnerPawn);
	if (H != None)
		H.SetAbilityUnlock(9, upgLevel);
}

static function WaveEnd(int upgLevel, KFPlayerController KFPC)
{
	local DKUpgrade_Perk_Domain_Helper H;

	if (KFPC == None || KFPC.Pawn == None)
		return;

	H = class'DKUpgrade_Perk_Domain'.static.FindHelper(KFPC.Pawn);
	if (H != None)
		H.SetAbilityUnlock(9, upgLevel);
}

static simulated function DeleteHelperClass(Pawn OwnerPawn)
{
	local DKUpgrade_Perk_Domain_Helper H;

	if (OwnerPawn == None)
		return;

	H = class'DKUpgrade_Perk_Domain'.static.FindHelper(OwnerPawn);
	if (H != None)
		H.SetAbilityUnlock(9, 0);
}

defaultproperties
{
	bShouldLocalize=True
	LocPackage="ZedternalRBPerkpackage"
	LocSection="DKUpgrade_Skill_CounterShock"

	UpgradeName="Counter Shock"
	upgradeDescription(0)="Wheel ability: <font color=\"#15d7fa\">EMP + stun</font> every zed in your Room (shuts down Husks and Sirens)."
	upgradeDescription(1)="Wheel ability: <font color=\"#15d7fa\">EMP + stun</font> every zed in your Room and <font color=\"#77d914\">deal damage</font>."

	UpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_CounterShock'
	UpgradeIcon(1)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_CounterShock_Deluxe'

	Name="Default__DKUpgrade_Skill_CounterShock"
}
