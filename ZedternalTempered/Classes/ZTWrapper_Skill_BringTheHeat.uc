// Wrapper for ZedternalReborn.WMUpgrade_Skill_BringTheHeat
//
// Adds config-driven fire bonus (Cfg_FireBonus) and an explicit
// ModifyDamageTaken override.
//
// On the ModifyDamageTaken override:
// The parent (WMUpgrade_Skill_BringTheHeat) sets InDamage = 0 unconditionally
// for WMDT_BringTheHeat damage. That is intentional self-immunity — the
// thermite shockwave damage type is unique to this skill and the player
// should never take damage from their own thermite reflection. The overwrite
// is defensible because no other contributor in the aggregator handles this
// damage type. We override at the DK layer (instead of inheriting silently
// from parent) so the intent is documented in DK code. If we ever want
// partial damage from own thermite (e.g. as a balance lever), edit InDamage
// here instead of letting the silent parent override govern.
class ZTWrapper_Skill_BringTheHeat extends WMUpgrade_Skill_BringTheHeat config(ZedternalUnlimited);

var config float Cfg_FireBonus;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Cfg_FireBonus = 1.4f;

		// BEGIN TEMPERED INI DEFAULTS (generated; do not edit by hand)
		default.Cfg_FireBonus = 1.400000f;
		// END TEMPERED INI DEFAULTS
		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static function ModifyDamageGiven(out int InDamage, int DefaultDamage, int upgLevel, optional Actor DamageCauser, optional KFPawn_Monster MyKFPM, optional KFPlayerController DamageInstigator, optional class<KFDamageType> DamageType, optional int HitZoneIdx, optional KFWeapon MyKFW)
{
	local WMUpgrade_Skill_BringTheHeat_Helper UPG;

	if (DamageType != None && DamageInstigator.Pawn != None)
	{
		UPG = GetHelper(DamageInstigator.Pawn);
		if (UPG != None)
		{
			if (ClassIsChildOf(DamageType, class'KFDT_Fire'))
				UPG.CumulativeDamage += Round(InDamage * default.Cfg_FireBonus * upgLevel);
			else
				UPG.CumulativeDamage += InDamage * upgLevel;
		}
	}
}

static function ModifyDamageTaken(out int InDamage, int DefaultDamage, int upgLevel, KFPawn OwnerPawn, optional class<DamageType> DamageType, optional Controller InstigatedBy, optional KFWeapon MyKFW)
{
	// Self-immunity to own thermite. See class comment for rationale.
	if (ClassIsChildOf(DamageType, class'ZedternalReborn.WMDT_BringTheHeat'))
		InDamage = 0;
}

defaultproperties
{
	Name="Default__ZTWrapper_Skill_BringTheHeat"
}
