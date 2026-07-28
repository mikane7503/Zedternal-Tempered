// ===================================================================
// DKUpgrade_Skill_Possess_Husk - Possessor form unlock, wheel slot 6.
//
// Unlocks the Husk form: ranged fireballs and flamethrower.
// Deluxe makes the form tougher (perk config DeluxeFormHealthMult).
// Pushes its owned level into the Possessor helper, which gates the slot
// in FirePossess. Inert without the Possessor perk.
// ===================================================================
class DKUpgrade_Skill_Possess_Husk extends DKUpgrade_Skill;

static simulated function InitiateWeapon(int upgLevel, KFWeapon KFW, KFPawn OwnerPawn)
{
	local DKUpgrade_Perk_Possessor_Helper H;

	if (KFPawn_Human(OwnerPawn) == None || OwnerPawn.Role != ROLE_Authority)
		return;

	H = class'DKUpgrade_Perk_Possessor'.static.FindHelper(OwnerPawn);
	if (H != None)
		H.SetFormUnlock(6, upgLevel);
}

static function WaveEnd(int upgLevel, KFPlayerController KFPC)
{
	local DKUpgrade_Perk_Possessor_Helper H;

	if (KFPC == None || KFPC.Pawn == None)
		return;

	H = class'DKUpgrade_Perk_Possessor'.static.FindHelper(KFPC.Pawn);
	if (H != None)
		H.SetFormUnlock(6, upgLevel);
}

static simulated function DeleteHelperClass(Pawn OwnerPawn)
{
	local DKUpgrade_Perk_Possessor_Helper H;

	if (OwnerPawn == None)
		return;

	H = class'DKUpgrade_Perk_Possessor'.static.FindHelper(OwnerPawn);
	if (H != None)
		H.SetFormUnlock(6, 0);
}

defaultproperties
{
	bShouldLocalize=True
	LocPackage="ZedternalRBPerkpackage"
	LocSection="DKUpgrade_Skill_Possess_Husk"

	UpgradeName="Form: Husk"
	upgradeDescription(0)="Possession form: transform into a <font color=\"#ff3399\">Husk</font>."
	upgradeDescription(1)="Possession form: transform into a <font color=\"#ff3399\">Husk</font> with <font color=\"#77d914\">bonus health</font>."

	UpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_Possess_Husk'
	UpgradeIcon(1)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_Possess_Husk_Deluxe'

	Name="Default__DKUpgrade_Skill_Possess_Husk"
}
