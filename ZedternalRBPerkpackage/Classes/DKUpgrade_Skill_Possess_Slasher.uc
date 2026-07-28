// ===================================================================
// DKUpgrade_Skill_Possess_Slasher - Possessor form upgrade, wheel slot 0.
//
// Upgrades the base form: your Clot becomes the faster, more aggressive
// Slasher. Deluxe makes the form tougher (perk config DeluxeFormHealthMult).
// Pushes its owned level into the Possessor helper, which swaps the slot 0
// class in GetFormClass. Inert without the Possessor perk.
// ===================================================================
class DKUpgrade_Skill_Possess_Slasher extends DKUpgrade_Skill;

static simulated function InitiateWeapon(int upgLevel, KFWeapon KFW, KFPawn OwnerPawn)
{
	local DKUpgrade_Perk_Possessor_Helper H;

	if (KFPawn_Human(OwnerPawn) == None || OwnerPawn.Role != ROLE_Authority)
		return;

	H = class'DKUpgrade_Perk_Possessor'.static.FindHelper(OwnerPawn);
	if (H != None)
		H.SetFormUnlock(0, upgLevel);
}

static function WaveEnd(int upgLevel, KFPlayerController KFPC)
{
	local DKUpgrade_Perk_Possessor_Helper H;

	if (KFPC == None || KFPC.Pawn == None)
		return;

	H = class'DKUpgrade_Perk_Possessor'.static.FindHelper(KFPC.Pawn);
	if (H != None)
		H.SetFormUnlock(0, upgLevel);
}

static simulated function DeleteHelperClass(Pawn OwnerPawn)
{
	local DKUpgrade_Perk_Possessor_Helper H;

	if (OwnerPawn == None)
		return;

	H = class'DKUpgrade_Perk_Possessor'.static.FindHelper(OwnerPawn);
	if (H != None)
		H.SetFormUnlock(0, 0);
}

defaultproperties
{
	bShouldLocalize=True
	LocPackage="ZedternalRBPerkpackage"
	LocSection="DKUpgrade_Skill_Possess_Slasher"

	UpgradeName="Form: Slasher"
	upgradeDescription(0)="Possession form: your base <font color=\"#15d7fa\">Clot</font> becomes the <font color=\"#ff3399\">Slasher</font>."
	upgradeDescription(1)="Possession form: your base <font color=\"#15d7fa\">Clot</font> becomes the <font color=\"#ff3399\">Slasher</font>, with <font color=\"#77d914\">bonus health</font>."

	UpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_Possess_Slasher'
	UpgradeIcon(1)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_Possess_Slasher_Deluxe'

	Name="Default__DKUpgrade_Skill_Possess_Slasher"
}
