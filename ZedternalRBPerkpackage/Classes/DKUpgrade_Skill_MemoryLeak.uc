// Memory Leak - universal glitch: your damage-over-time effects tick harder.
class DKUpgrade_Skill_MemoryLeak extends DKUpgrade_Skill
	config(ZedternalUnlimited);

var config array<float> DoTBonus;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.DoTBonus[0] = 0.25f;
		default.DoTBonus[1] = 0.50f;
		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static function ModifyDoTScaler(out float InDoTScaler, float DefaultDotScaler, int upgLevel, optional class<KFDamageType> KFDT, optional bool bNapalmInfected)
{
	InDoTScaler += DefaultDotScaler * default.DoTBonus[upgLevel - 1];
}

defaultproperties
{
	bShouldLocalize=True
	LocPackage="ZedternalRBPerkpackage"
	LocSection="DKUpgrade_Skill_MemoryLeak"

	UpgradeName="Memory Leak"
	upgradeDescription(0)="Your <font color=\"#00ff00\">damage-over-time effects</font> deal <font color=\"#ff3399\">+25% damage</font>."
	upgradeDescription(1)="Your <font color=\"#00ff00\">damage-over-time effects</font> deal <font color=\"#ff3399\">+50% damage</font>."
	UpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_MemoryLeak'
	UpgradeIcon(1)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_MemoryLeak_Deluxe'
	Name="Default__DKUpgrade_Skill_MemoryLeak"
}
