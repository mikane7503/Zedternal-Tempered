// Hex Edit - MissingNO synergy: GLITCH procs gain an armor outcome. Inert without the perk.
class ZTUpgrade_Skill_HexEdit extends ZTUpgrade_Skill;

static simulated function InitiateWeapon(int upgLevel, KFWeapon KFW, KFPawn OwnerPawn)
{
	local ZTUpgrade_Perk_MissingNO_Helper H;

	if (KFPawn_Human(OwnerPawn) == None || OwnerPawn.Role != ROLE_Authority)
		return;

	H = class'ZTUpgrade_Perk_MissingNO'.static.GetHelper(OwnerPawn);
	if (H != None)
		H.SetSkillArmorProc(upgLevel);
}

static function WaveEnd(int upgLevel, KFPlayerController KFPC)
{
	if (KFPC != None && KFPC.Pawn != None)
		InitiateWeapon(upgLevel, None, KFPawn(KFPC.Pawn));
}

static simulated function DeleteHelperClass(Pawn OwnerPawn)
{
	local ZTUpgrade_Perk_MissingNO_Helper H;

	if (OwnerPawn == None)
		return;

	H = class'ZTUpgrade_Perk_MissingNO'.static.GetHelper(OwnerPawn);
	if (H != None)
		H.SetSkillArmorProc(0);
}

defaultproperties
{
	bShouldLocalize=True
	LocPackage="ZedternalTempered"
	LocSection="ZTUpgrade_Skill_HexEdit"

	UpgradeName="Hex Edit"
	upgradeDescription(0)="<font color=\"#ff00ff\">MissingNO only:</font> GLITCH procs can roll a 5th outcome: <font color=\"#00ffff\">+5 Armor</font>."
	upgradeDescription(1)="<font color=\"#ff00ff\">MissingNO only:</font> GLITCH procs can roll a 5th outcome: <font color=\"#00ffff\">+10 Armor</font>."
	UpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_HexEdit'
	UpgradeIcon(1)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_HexEdit_Deluxe'
	Name="Default__ZTUpgrade_Skill_HexEdit"
}
