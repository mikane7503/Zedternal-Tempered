// Null Pointer - universal glitch: a fraction of your hits dereference a zed's
// aggression - proc'ing heavy snare that also cancels rage/sprint speed.
class DKUpgrade_Skill_NullPointer extends DKUpgrade_Skill
	config(ZedternalUnlimited);

var config array<float> ProcChance;
var config float ProcSnarePower;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.ProcChance[0] = 0.05f;
		default.ProcChance[1] = 0.10f;
		default.ProcSnarePower = 200.0f;
		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static function ModifySnarePower(out float InSnarePower, float DefaultSnarePower, int upgLevel, optional class<DamageType> DamageType, optional byte BodyPart)
{
	if (FRand() < default.ProcChance[upgLevel - 1])
		InSnarePower += default.ProcSnarePower;
}

defaultproperties
{
	bShouldLocalize=True
	LocPackage="ZedternalRBPerkpackage"
	LocSection="DKUpgrade_Skill_NullPointer"

	UpgradeName="Null Pointer"
	upgradeDescription(0)="<font color=\"#00ff00\">5%</font> of your hits <font color=\"#ff00ff\">null a zed's aggression</font>, heavily slowing it."
	upgradeDescription(1)="<font color=\"#00ff00\">10%</font> of your hits <font color=\"#ff00ff\">null a zed's aggression</font>, heavily slowing it."
	UpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_NullPointer'
	UpgradeIcon(1)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_NullPointer_Deluxe'
	Name="Default__DKUpgrade_Skill_NullPointer"
}
