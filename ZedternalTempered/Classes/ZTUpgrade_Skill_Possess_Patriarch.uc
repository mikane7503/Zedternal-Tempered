// ===================================================================
// ZTUpgrade_Skill_Possess_Patriarch - Possessor form unlock, wheel slot 9.
//
// Unlocks the Patriarch form: the de-bossed ZTPawn_ZedPatriarch_Puppet
// (no boss health bar / music / wave-boss tracking), driven like the
// Versus Patriarch. Deluxe makes the form tougher (perk config
// DeluxeFormHealthMult). Pushes its owned level into the Possessor
// helper, which gates the slot in FirePossess. Inert without the
// Possessor perk.
// ===================================================================
class ZTUpgrade_Skill_Possess_Patriarch extends ZTUpgrade_Skill;

static simulated function InitiateWeapon(int upgLevel, KFWeapon KFW, KFPawn OwnerPawn)
{
	local ZTUpgrade_Perk_Possessor_Helper H;

	if (KFPawn_Human(OwnerPawn) == None || OwnerPawn.Role != ROLE_Authority)
		return;

	H = class'ZTUpgrade_Perk_Possessor'.static.FindHelper(OwnerPawn);
	if (H != None)
		H.SetFormUnlock(9, upgLevel);
}

static function WaveEnd(int upgLevel, KFPlayerController KFPC)
{
	local ZTUpgrade_Perk_Possessor_Helper H;

	if (KFPC == None || KFPC.Pawn == None)
		return;

	H = class'ZTUpgrade_Perk_Possessor'.static.FindHelper(KFPC.Pawn);
	if (H != None)
		H.SetFormUnlock(9, upgLevel);
}

static simulated function DeleteHelperClass(Pawn OwnerPawn)
{
	local ZTUpgrade_Perk_Possessor_Helper H;

	if (OwnerPawn == None)
		return;

	H = class'ZTUpgrade_Perk_Possessor'.static.FindHelper(OwnerPawn);
	if (H != None)
		H.SetFormUnlock(9, 0);
}

defaultproperties
{
	bShouldLocalize=True
	LocPackage="ZedternalTempered"
	LocSection="ZTUpgrade_Skill_Possess_Patriarch"

	UpgradeName="Form: Patriarch"
	upgradeDescription(0)="Possession form: transform into the <font color=\"#ff3399\">Patriarch</font>."
	upgradeDescription(1)="Possession form: transform into the <font color=\"#ff3399\">Patriarch</font> with <font color=\"#77d914\">bonus health</font>."

	UpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_Possess_Patriarch'
	UpgradeIcon(1)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_Possess_Patriarch_Deluxe'

	Name="Default__ZTUpgrade_Skill_Possess_Patriarch"
}
