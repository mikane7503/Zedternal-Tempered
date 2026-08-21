class ZUTUpgrade_Skill_AirborneAgent extends ZUTUpgrade_Skill_Base;

static simulated function InitiateWeapon(int upgLevel, KFWeapon KFW, KFPawn OwnerPawn)
{
	local ZUTUpgrade_Skill_AirborneAgent_Helper UPG;
	local bool bFound;

	if (KFPawn_Human(OwnerPawn) != None && OwnerPawn.Role == Role_Authority)
	{
		foreach OwnerPawn.ChildActors(class'ZUTUpgrade_Skill_AirborneAgent_Helper', UPG)
		{
			bFound = True;
			break;
		}
		if (!bFound)
		{
			UPG = OwnerPawn.Spawn(class'ZUTUpgrade_Skill_AirborneAgent_Helper', OwnerPawn);
			UPG.bDeluxe = upgLevel > 1;
		}
	}
}

static function WaveEnd(int upgLevel, KFPlayerController KFPC)
{
	local ZUTUpgrade_Skill_AirborneAgent_Helper UPG;
	if (KFPC == None || KFPC.Pawn == None) return;
	foreach KFPC.Pawn.ChildActors(class'ZUTUpgrade_Skill_AirborneAgent_Helper', UPG)
		UPG.ResetForWave();
}

static simulated function DeleteHelperClass(Pawn OwnerPawn)
{
	local ZUTUpgrade_Skill_AirborneAgent_Helper UPG;
	if (OwnerPawn == None) return;
	foreach OwnerPawn.ChildActors(class'ZUTUpgrade_Skill_AirborneAgent_Helper', UPG)
		UPG.Destroy();
}

defaultproperties
{
	bShouldLocalize=True
	LocPackage="ZedternalTempered"
	LocSection="ZUTUpgrade_Skill_AirborneAgent"
	UpgradeName="ZedternalReborn.WMUpgrade_Skill_AirborneAgent"
	UpgradeIcon(0)=Texture2D'ZedternalReborn_Resource.Skills.UI_Skill_AirborneAgent'
	UpgradeIcon(1)=Texture2D'ZedternalReborn_Resource.Skills.UI_Skill_AirborneAgent_Deluxe'
	Name="Default__ZUTUpgrade_Skill_AirborneAgent"
}
