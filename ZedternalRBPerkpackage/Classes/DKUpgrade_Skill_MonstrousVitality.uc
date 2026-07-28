// Hyde skill - Monstrous Vitality: melee lifesteal while transformed, banked as armor you keep on revert.
class DKUpgrade_Skill_MonstrousVitality extends DKUpgrade_Skill
	config(ZedternalUnlimited);

var config array<int> ArmorPerHit;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.ArmorPerHit[0] = 2;  default.ArmorPerHit[1] = 4;
		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static function AddVampireHealth(out int InHealth, int DefaultHealth, int upgLevel, KFPlayerController KFPC, class<DamageType> DT)
{
	local DKUpgrade_Perk_JekyllHyde_Helper H;

	if (KFPC == None || KFPC.Pawn == None)
		return;
	if (DT == None || !IsMeleeDamageType(DT))
		return;

	H = class'DKUpgrade_Perk_JekyllHyde'.static.GetHelper(KFPC.Pawn);
	if (H == None || !H.bHyde)
		return;

	// Bank as armor instead of healing (Hyde is already immune/full HP).
	H.BankVampireArmor(default.ArmorPerHit[upgLevel - 1]);
}

defaultproperties
{
	bShouldLocalize=True
	LocPackage="ZedternalRBPerkpackage"
	LocSection="DKUpgrade_Skill_MonstrousVitality"
	UpgradeName="Monstrous Vitality"
	upgradeDescription(0)="As <font color=\"#be4d25\">Mr. Hyde</font>, melee hits bank <font color=\"#77d914\">+2 armor</font> each, granted when you revert."
	upgradeDescription(1)="As <font color=\"#be4d25\">Mr. Hyde</font>, melee hits bank <font color=\"#77d914\">+4 armor</font> each, granted when you revert."
	UpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_MonstrousVitality'
	UpgradeIcon(1)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_MonstrousVitality_Deluxe'
	Name="Default__DKUpgrade_Skill_MonstrousVitality"
}
