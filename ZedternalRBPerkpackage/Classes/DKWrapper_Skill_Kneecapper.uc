// Wrapper for HowdyZTRExt.ZRUpgrade_Skill_Kneecapper
class DKWrapper_Skill_Kneecapper extends ZRUpgrade_Skill_Kneecapper
	config(ZedternalUnlimited);

var config array<float> Cfg_Knockdown;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Cfg_Knockdown[0] = 0.6f;
		default.Cfg_Knockdown[1] = 0.7f;
		default.Cfg_Knockdown[2] = 0.9f;
		default.Cfg_Knockdown[3] = 1.0f;

		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static function ModifyKnockdownPower(out float InKnockdownPower, float DefaultKnockdownPower, int upgLevel, KFPawn OwnerPawn, optional class<DamageType> DamageType, optional byte BodyPart, optional bool bIsSprinting=False)
{
	if (default.BoneBreakerBodyParts.Find(class'KFGame.KFPawn_Monster'.default.HitZones[BodyPart].Limb) != INDEX_NONE)
		InKnockdownPower += DefaultKnockdownPower * default.Cfg_Knockdown[1 + (upgLevel - 1) * 2];
}

defaultproperties
{
	Name="Default__DKWrapper_Skill_Kneecapper"
}
