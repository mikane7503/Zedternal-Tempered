// Wrapper for ZedternalReborn.WMUpgrade_Skill_BoneBreaker
class DKWrapper_Skill_BoneBreaker extends WMUpgrade_Skill_BoneBreaker
	config(ZedternalUnlimited);

var config array<float> Cfg_Stumble;
var config array<float> Cfg_Knockdown;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Cfg_Stumble[0] = 0.3f;
		default.Cfg_Stumble[1] = 0.75f;
		default.Cfg_Knockdown[0] = 0.2f;
		default.Cfg_Knockdown[1] = 0.3f;
		default.Cfg_Knockdown[2] = 0.5f;
		default.Cfg_Knockdown[3] = 0.6f;

		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static function ModifyStumblePower(out float InStumblePower, float DefaultStumblePower, int upgLevel, optional KFPawn KFP, optional class<KFDamageType> DamageType, optional out float CooldownModifier, optional byte BodyPart, optional KFPawn OwnerPawn)
{
	if (BodyPart == HZI_Head && default.BoneBreakerBodyParts.Find(class'KFGame.KFPawn_Monster'.default.HitZones[BodyPart].Limb) != INDEX_NONE)
		InStumblePower += DefaultStumblePower * default.Cfg_Stumble[upgLevel - 1];
}

static function ModifyKnockdownPower(out float InKnockdownPower, float DefaultKnockdownPower, int upgLevel, KFPawn OwnerPawn, optional class<DamageType> DamageType, optional byte BodyPart, optional bool bIsSprinting=False)
{
	if (BodyPart == HZI_Head)
		InKnockdownPower += DefaultKnockdownPower * default.Cfg_Knockdown[0 + (upgLevel - 1) * 2];

	if (default.BoneBreakerBodyParts.Find(class'KFGame.KFPawn_Monster'.default.HitZones[BodyPart].Limb) != INDEX_NONE)
		InKnockdownPower += DefaultKnockdownPower * default.Cfg_Knockdown[1 + (upgLevel - 1) * 2];
}

defaultproperties
{
	Name="Default__DKWrapper_Skill_BoneBreaker"
}
