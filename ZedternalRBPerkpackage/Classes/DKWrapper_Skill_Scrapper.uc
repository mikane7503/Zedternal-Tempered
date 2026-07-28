// Wrapper for ZedternalReborn.WMUpgrade_Skill_Scrapper
class DKWrapper_Skill_Scrapper extends WMUpgrade_Skill_Scrapper
	config(ZedternalUnlimited);

var config array<float> Cfg_Probability;
var config float Cfg_AmmoDivider;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Cfg_Probability[0] = 0.125f;
		default.Cfg_Probability[1] = 0.25f;
		default.Cfg_AmmoDivider = 40.0f;

		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static function AddAmmunition(Pawn Player, int upgLevel)
{
	local KFWeapon KFW;
	local byte i;
	local int ExtraAmmo;

	if (Player != None && Player.Health > 0 && Player.InvManager != None && FRand() <= default.Cfg_Probability[upgLevel - 1])
	{
		foreach Player.InvManager.InventoryActors(class'KFWeapon', KFW)
		{
			if (KFW != KFWeapon(Player.Weapon))
			{
				for (i = 0; i < 2; ++i)
				{
					ExtraAmmo = Min(FCeil(float(KFW.GetMaxAmmoAmount(i)) / default.Cfg_AmmoDivider), KFW.GetMaxAmmoAmount(i) - KFW.GetTotalAmmoAmount(i));
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
}

defaultproperties
{
	Name="Default__DKWrapper_Skill_Scrapper"
}
