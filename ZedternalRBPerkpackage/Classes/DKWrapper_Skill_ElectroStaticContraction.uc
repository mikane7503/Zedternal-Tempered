// Wrapper for HowdyZTRExt.ZRUpgrade_Skill_ElectroStaticContraction
class DKWrapper_Skill_ElectroStaticContraction extends ZRUpgrade_Skill_ElectroStaticContraction
	config(ZedternalUnlimited);

var config array<float> Cfg_Knockdown;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Cfg_Knockdown[0] = 0.5f;
		default.Cfg_Knockdown[1] = 1.0f;

		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static function ModifyKnockdownPower(out float InKnockdownPower, float DefaultKnockdownPower, int upgLevel, KFPawn OwnerPawn, optional class<DamageType> DamageType, optional byte BodyPart, optional bool bIsSprinting=False)
{
	if (ClassIsChildOf(DamageType, class'KFDT_EMP') && OwnerPawn != None)
		InKnockdownPower += DefaultKnockdownPower * default.Cfg_Knockdown[1 + (upgLevel - 1) * 2];
}

defaultproperties
{
	Name="Default__DKWrapper_Skill_ElectroStaticContraction"
}
