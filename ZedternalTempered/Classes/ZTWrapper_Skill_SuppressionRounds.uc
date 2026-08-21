// Wrapper for ZedternalReborn.WMUpgrade_Skill_SuppressionRounds
class ZTWrapper_Skill_SuppressionRounds extends WMUpgrade_Skill_SuppressionRounds config(ZedternalUnlimited);

var config array<float> Cfg_KnockDown;
var config float Cfg_Snare;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Cfg_KnockDown[0] = 0.3f;
		default.Cfg_KnockDown[1] = 0.75f;
		default.Cfg_Snare = 20.0f;

		// BEGIN TEMPERED INI DEFAULTS (generated; do not edit by hand)
		default.Cfg_Knockdown.Length = 2;
		default.Cfg_Knockdown[0] = 0.150000f;
		default.Cfg_Knockdown[1] = 0.375000f;
		default.Cfg_Snare = 10.000000f;
		// END TEMPERED INI DEFAULTS
		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static function ModifyKnockdownPower(out float InKnockdownPower, float DefaultKnockdownPower, int upgLevel, KFPawn OwnerPawn, optional class<DamageType> DamageType, optional byte BodyPart, optional bool bIsSprinting=False)
{
	if (bIsSprinting)
		InKnockdownPower += DefaultKnockdownPower * default.Cfg_KnockDown[upgLevel - 1];
}

static function ModifySnarePower(out float InSnarePower, float DefaultSnarePower, int upgLevel, optional class<DamageType> DamageType, optional byte BodyPart)
{
	if (BodyPart != HZI_Head)
		InSnarePower += DefaultSnarePower * default.Cfg_Snare;
}

defaultproperties
{
	Name="Default__ZTWrapper_Skill_SuppressionRounds"
}
