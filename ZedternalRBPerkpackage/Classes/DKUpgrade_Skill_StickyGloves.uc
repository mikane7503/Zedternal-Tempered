// Sticky Gloves - Goalkeeper synergy: miss cooldown reduced. Inert without the perk.
class DKUpgrade_Skill_StickyGloves extends DKUpgrade_Skill
	config(ZedternalUnlimited);

var config array<float> CooldownMult;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.CooldownMult[0] = 0.67f;
		default.CooldownMult[1] = 0.40f;
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
		H.SetSkillCooldownMult(default.CooldownMult[upgLevel - 1]);
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
		H.SetSkillCooldownMult(1.0f);
}

defaultproperties
{
	bShouldLocalize=True
	LocPackage="ZedternalRBPerkpackage"
	LocSection="DKUpgrade_Skill_StickyGloves"

	UpgradeName="Sticky Gloves"
	upgradeDescription(0)="<font color=\"#15d7fa\">Goalkeeper only:</font> a missed catch window recovers <font color=\"#77d914\">33% faster</font>."
	upgradeDescription(1)="<font color=\"#15d7fa\">Goalkeeper only:</font> a missed catch window recovers <font color=\"#77d914\">60% faster</font>."
	UpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_StickyGloves'
	UpgradeIcon(1)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_StickyGloves_Deluxe'
	Name="Default__DKUpgrade_Skill_StickyGloves"
}
