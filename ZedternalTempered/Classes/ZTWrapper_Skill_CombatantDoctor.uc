// Wrapper for ZedternalReborn.WMUpgrade_Skill_CombatantDoctor
class ZTWrapper_Skill_CombatantDoctor extends WMUpgrade_Skill_CombatantDoctor config(ZedternalUnlimited);

var config float Cfg_AmmoDivider;
var config array<int> Cfg_HealthThreshold;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Cfg_AmmoDivider = 30.0f;
		default.Cfg_HealthThreshold[0] = 50;
		default.Cfg_HealthThreshold[1] = 25;

		// BEGIN TEMPERED INI DEFAULTS (generated; do not edit by hand)
		default.Cfg_AmmoDivider = 30.000000f;
		default.Cfg_HealthThreshold.Length = 2;
		default.Cfg_HealthThreshold[0] = 50;
		default.Cfg_HealthThreshold[1] = 25;
		// END TEMPERED INI DEFAULTS
		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static function HealingDamage(int upgLevel, int HealAmount, KFPawn HealedPawn, KFPawn InstigatorPawn, class<DamageType> DamageType)
{
	local WMUpgrade_Skill_CombatantDoctor_Helper UPG;

	if (HealedPawn != None && InstigatorPawn != None && HealAmount > 0 && HealedPawn.GetHealthPercentage() < 1.0f)
	{
		UPG = GetHelper(InstigatorPawn);
		if (UPG != None)
		{
			UPG.AddHealedHealth(Min(HealAmount, HealedPawn.HealthMax - HealedPawn.Health));
			AddAmmunition(InstigatorPawn, UPG.GetAmmoMultiplier(default.Cfg_HealthThreshold[upgLevel - 1]));
		}
	}
}

static function AddAmmunition(KFPawn Player, int Multiplier)
{
	local KFWeapon KFW;
	local byte i;
	local int ExtraAmmo;

	if (Player != None && Player.Health > 0 && Player.InvManager != None && Multiplier > 0)
	{
		foreach Player.InvManager.InventoryActors(class'KFWeapon', KFW)
		{
			for (i = 0; i < 2; ++i)
			{
				ExtraAmmo = Min(FCeil(float(KFW.GetMaxAmmoAmount(i)) / default.Cfg_AmmoDivider) * Multiplier, KFW.GetMaxAmmoAmount(i) - KFW.GetTotalAmmoAmount(i));
				if (ExtraAmmo > 0)
				{
					if (i == 0)
						KFW.AddAmmo(ExtraAmmo);
					else
						KFW.AddSecondaryAmmo(ExtraAmmo);
				}
			}
		}
	}
}

defaultproperties
{
	Name="Default__ZTWrapper_Skill_CombatantDoctor"
}
