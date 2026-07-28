// Wrapper for ZedternalReborn.WMUpgrade_Perk_Firebug
class DKWrapper_Perk_Firebug extends WMUpgrade_Perk_Firebug
	config(ZedternalUnlimited);

var config float Cfg_Damage;
var config float Cfg_Defense;
var config float Cfg_Ammo;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Cfg_Damage = 0.05f;
		default.Cfg_Defense = 0.04f;
		default.Cfg_Ammo = 0.05f;

		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
	static.StaticSaveConfig();

	// Update display values
}

static function ModifyDamageGiven(out int InDamage, int DefaultDamage, int upgLevel, optional Actor DamageCauser, optional KFPawn_Monster MyKFPM, optional KFPlayerController DamageInstigator, optional class<KFDamageType> DamageType, optional int HitZoneIdx, optional KFWeapon MyKFW)
{
	if (IsWeaponOnSpecificPerk(MyKFW, class'KFGame.KFPerk_Firebug') || IsDamageTypeOnSpecificPerk(DamageType, class'KFGame.KFPerk_Firebug'))
		InDamage += Round(float(DefaultDamage) * default.Cfg_Damage * upgLevel);
}

static function ModifyDamageTaken(out int InDamage, int DefaultDamage, int upgLevel, KFPawn OwnerPawn, optional class<DamageType> DamageType, optional Controller InstigatedBy, optional KFWeapon MyKFW)
{
	if (ClassIsChildOf(DamageType, class'KFDT_Fire') || ClassIsChildOf(DamageType, class'KFDT_Explosive') || ClassIsChildOf(DamageType, class'KFDT_Toxic') || ClassIsChildOf(DamageType, class'KFDT_Sonic'))
		InDamage -= Round(float(DefaultDamage) * FMin(default.Cfg_Defense * upgLevel, 0.4f));
}

static function WaveEnd(int upgLevel, KFPlayerController KFPC)
{
	local KFWeapon KFW;
	local KFPawn Player;
	local byte i;
	local int ExtraAmmo;

	Player = KFPawn(KFPC.Pawn);

	if (Player != None && Player.Health > 0 && Player.InvManager != None)
	{
		foreach Player.InvManager.InventoryActors(class'KFWeapon', KFW)
		{
			for(i = 0; i < 2; ++i)
			{
				ExtraAmmo = Min(FCeil(float(KFW.GetMaxAmmoAmount(i)) * FMin(default.Cfg_Ammo * float(upgLevel), 0.5f)), KFW.GetMaxAmmoAmount(i) - KFW.GetTotalAmmoAmount(i));
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
	Name="Default__DKWrapper_Perk_Firebug"
}
