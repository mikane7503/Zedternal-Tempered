// Ascension balance wrapper for the original Medical Injection skill.
class ZUTUpgrade_Skill_MedicalInjection extends ZedternalReborn.WMUpgrade_Skill_MedicalInjection;

static simulated function InitiateWeapon(int upgLevel, KFWeapon KFW, KFPawn OwnerPawn)
{
	local ZUTUpgrade_Skill_MedicalInjection_Helper UPG;

	if (KFPawn_Human(OwnerPawn) == None || OwnerPawn.Role != Role_Authority)
		return;

	foreach OwnerPawn.ChildActors(class'ZUTUpgrade_Skill_MedicalInjection_Helper', UPG)
		return;

	UPG = OwnerPawn.Spawn(class'ZUTUpgrade_Skill_MedicalInjection_Helper', OwnerPawn);
	if (UPG != None)
		UPG.StartTimer(upgLevel > 1);
}

static simulated function DeleteHelperClass(Pawn OwnerPawn)
{
	local ZUTUpgrade_Skill_MedicalInjection_Helper UPG;

	if (OwnerPawn == None)
		return;

	foreach OwnerPawn.ChildActors(class'ZUTUpgrade_Skill_MedicalInjection_Helper', UPG)
		UPG.Destroy();
}

defaultproperties
{
	UpgradeName="ZedternalTempered.ZUTUpgrade_Skill_MedicalInjection"
	Name="Default__ZUTUpgrade_Skill_MedicalInjection"
}
