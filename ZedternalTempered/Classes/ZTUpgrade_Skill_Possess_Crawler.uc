// ===================================================================
// ZTUpgrade_Skill_Possess_Crawler - Possessor form unlock, wheel slot 1.
//
// Unlocks the Crawler form: wall-crawling leaper with pounce attacks.
// Deluxe makes the form tougher (perk config DeluxeFormHealthMult).
// Pushes its owned level into the Possessor helper, which gates the slot
// in FirePossess. Inert without the Possessor perk.
// ===================================================================
class ZTUpgrade_Skill_Possess_Crawler extends ZTUpgrade_Skill;

static simulated function InitiateWeapon(int upgLevel, KFWeapon KFW, KFPawn OwnerPawn)
{
	local ZTUpgrade_Perk_Possessor_Helper H;

	if (KFPawn_Human(OwnerPawn) == None || OwnerPawn.Role != ROLE_Authority)
		return;

	H = class'ZTUpgrade_Perk_Possessor'.static.FindHelper(OwnerPawn);
	if (H != None)
		H.SetFormUnlock(1, upgLevel);
}

static function WaveEnd(int upgLevel, KFPlayerController KFPC)
{
	local ZTUpgrade_Perk_Possessor_Helper H;

	if (KFPC == None || KFPC.Pawn == None)
		return;

	H = class'ZTUpgrade_Perk_Possessor'.static.FindHelper(KFPC.Pawn);
	if (H != None)
		H.SetFormUnlock(1, upgLevel);
}

static simulated function DeleteHelperClass(Pawn OwnerPawn)
{
	local ZTUpgrade_Perk_Possessor_Helper H;

	if (OwnerPawn == None)
		return;

	H = class'ZTUpgrade_Perk_Possessor'.static.FindHelper(OwnerPawn);
	if (H != None)
		H.SetFormUnlock(1, 0);
}

defaultproperties
{
	bShouldLocalize=True
	LocPackage="ZedternalTempered"
	LocSection="ZTUpgrade_Skill_Possess_Crawler"

	UpgradeName="Form: Crawler"
	upgradeDescription(0)="Possession form: transform into a <font color=\"#ff3399\">Crawler</font>."
	upgradeDescription(1)="Possession form: transform into a <font color=\"#ff3399\">Crawler</font> with <font color=\"#77d914\">bonus health</font>."

	UpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_Possess_Crawler'
	UpgradeIcon(1)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_Possess_Crawler_Deluxe'

	Name="Default__ZTUpgrade_Skill_Possess_Crawler"
}
