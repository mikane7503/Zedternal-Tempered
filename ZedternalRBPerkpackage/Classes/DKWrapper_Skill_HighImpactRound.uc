// Wrapper for ZedternalReborn.WMUpgrade_Skill_HighImpactRound
class DKWrapper_Skill_HighImpactRound extends WMUpgrade_Skill_HighImpactRound
	config(ZedternalUnlimited);

var config array<float> Cfg_Knockdown;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Cfg_Knockdown[0] = 0.4f;
		default.Cfg_Knockdown[1] = 1.0f;

		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static function ModifyKnockdownPower(out float InKnockdownPower, float DefaultKnockdownPower, int upgLevel, KFPawn OwnerPawn, optional class<DamageType> DamageType, optional byte BodyPart, optional bool bIsSprinting=False)
{
	if (ClassIsChildOf(DamageType, class'KFDT_Explosive'))
		InKnockdownPower += DefaultKnockdownPower * default.Cfg_Knockdown[upgLevel - 1];
}

defaultproperties
{
	Name="Default__DKWrapper_Skill_HighImpactRound"
}
