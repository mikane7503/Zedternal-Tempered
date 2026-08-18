// Interception Bonus - Goalkeeper synergy: catches pay dosh. Inert without the perk.
class DKUpgrade_Skill_InterceptionBonus extends DKUpgrade_Skill
	config(ZedternalUnlimited);

var config array<int> DoshPerCatch;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.DoshPerCatch[0] = 15;
		default.DoshPerCatch[1] = 35;
		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static simulated function InitiateWeapon(int upgLevel, KFWeapon KFW, KFPawn OwnerPawn)
{
	local DKUpgrade_Perk_Goalkeeper_Helper H;

	if (KFPawn_Human(OwnerPawn) == None || OwnerPawn.Role != ROLE_Authority)
		return;

	H = class'DKUpgrade_Perk_Goalkeeper'.static.FindHelper(OwnerPawn);
	if (H != None)
		H.SetSkillDoshPerCatch(default.DoshPerCatch[upgLevel - 1]);
}

static function WaveEnd(int upgLevel, KFPlayerController KFPC)
{
	if (KFPC != None && KFPC.Pawn != None)
		InitiateWeapon(upgLevel, None, KFPawn(KFPC.Pawn));
}

static simulated function DeleteHelperClass(Pawn OwnerPawn)
{
	local DKUpgrade_Perk_Goalkeeper_Helper H;

	if (OwnerPawn == None)
		return;

	H = class'DKUpgrade_Perk_Goalkeeper'.static.FindHelper(OwnerPawn);
	if (H != None)
		H.SetSkillDoshPerCatch(0);
}

defaultproperties
{
	bShouldLocalize=True
	LocPackage="ZedternalRBPerkpackage"
	LocSection="DKUpgrade_Skill_InterceptionBonus"

	UpgradeName="Interception Bonus"
	upgradeDescription(0)="<font color=\"#15d7fa\">Goalkeeper only:</font> every catch pays <font color=\"#ffc832\">15 Dosh</font>."
	upgradeDescription(1)="<font color=\"#15d7fa\">Goalkeeper only:</font> every catch pays <font color=\"#ffc832\">35 Dosh</font>."
	UpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_InterceptionBonus'
	UpgradeIcon(1)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_InterceptionBonus_Deluxe'
	Name="Default__DKUpgrade_Skill_InterceptionBonus"
}
