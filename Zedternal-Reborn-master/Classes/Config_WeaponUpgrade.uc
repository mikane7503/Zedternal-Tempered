class Config_WeaponUpgrade extends Config_Common
	config(ZedternalReborn_Upgrades);

var config int MODEVERSION;

struct S_WeaponUpgrade
{
	var string WeaponPath;
	var int PriceUnit;
	var float PriceMultiplier;
	var int MaxLevel;
	var bool bIsStatic;

	structdefaultproperties
	{
		PriceUnit=50
		PriceMultiplier=0.15f
		MaxLevel=3
		bIsStatic=False
	}
};

var config array<S_WeaponUpgrade> WeaponUpgrade_Upgrade;

static function UpdateConfig()
{
	local int i;
	local S_WeaponUpgrade NewItem;

	if (default.MODEVERSION < 1)
	{
		default.WeaponUpgrade_Upgrade.Length = 23;
		default.WeaponUpgrade_Upgrade[0].WeaponPath = "ZedternalReborn.WMUpgrade_Weapon_Damage";
		default.WeaponUpgrade_Upgrade[0].bIsStatic = True;
		default.WeaponUpgrade_Upgrade[1].WeaponPath = "ZedternalReborn.WMUpgrade_Weapon_Damage_Clot";
		default.WeaponUpgrade_Upgrade[2].WeaponPath = "ZedternalReborn.WMUpgrade_Weapon_Damage_GroundFire";
		default.WeaponUpgrade_Upgrade[3].WeaponPath = "ZedternalReborn.WMUpgrade_Weapon_Damage_Headshot";
		default.WeaponUpgrade_Upgrade[4].WeaponPath = "ZedternalReborn.WMUpgrade_Weapon_DamageTaken";
		default.WeaponUpgrade_Upgrade[5].WeaponPath = "ZedternalReborn.WMUpgrade_Weapon_HardMeleeAttack";
		default.WeaponUpgrade_Upgrade[6].WeaponPath = "ZedternalReborn.WMUpgrade_Weapon_Heal";
		default.WeaponUpgrade_Upgrade[7].WeaponPath = "ZedternalReborn.WMUpgrade_Weapon_KnockdownPower";
		default.WeaponUpgrade_Upgrade[8].WeaponPath = "ZedternalReborn.WMUpgrade_Weapon_MagSize";
		default.WeaponUpgrade_Upgrade[9].WeaponPath = "ZedternalReborn.WMUpgrade_Weapon_MagSize_Small";
		default.WeaponUpgrade_Upgrade[10].WeaponPath = "ZedternalReborn.WMUpgrade_Weapon_MeleeAttackSpeed";
		default.WeaponUpgrade_Upgrade[11].WeaponPath = "ZedternalReborn.WMUpgrade_Weapon_Penetration";
		default.WeaponUpgrade_Upgrade[12].WeaponPath = "ZedternalReborn.WMUpgrade_Weapon_RateOfFire";
		default.WeaponUpgrade_Upgrade[13].WeaponPath = "ZedternalReborn.WMUpgrade_Weapon_Recoil";
		default.WeaponUpgrade_Upgrade[14].WeaponPath = "ZedternalReborn.WMUpgrade_Weapon_ReloadSpeed";
		default.WeaponUpgrade_Upgrade[15].WeaponPath = "ZedternalReborn.WMUpgrade_Weapon_SpareAmmo";
		default.WeaponUpgrade_Upgrade[16].WeaponPath = "ZedternalReborn.WMUpgrade_Weapon_SpareAmmo_C4";
		default.WeaponUpgrade_Upgrade[17].WeaponPath = "ZedternalReborn.WMUpgrade_Weapon_StumblePower";
		default.WeaponUpgrade_Upgrade[18].WeaponPath = "ZedternalReborn.WMUpgrade_Weapon_StunPower";
		default.WeaponUpgrade_Upgrade[19].WeaponPath = "ZedternalReborn.WMUpgrade_Weapon_SwitchSpeed";
		default.WeaponUpgrade_Upgrade[20].WeaponPath = "ZedternalReborn.WMUpgrade_Weapon_TightChoke";
		default.WeaponUpgrade_Upgrade[21].WeaponPath = "ZedternalReborn.WMUpgrade_Weapon_AmmunitionConsumption";
		default.WeaponUpgrade_Upgrade[22].WeaponPath = "ZedternalReborn.WMUpgrade_Weapon_Damage_Fleshpound";
	}

	if (default.MODEVERSION < 12)
	{
		for (i = 0; i < default.WeaponUpgrade_Upgrade.Length; ++i)
		{
			default.WeaponUpgrade_Upgrade[i].PriceUnit = 50;
			default.WeaponUpgrade_Upgrade[i].PriceMultiplier = 0.15f;
			default.WeaponUpgrade_Upgrade[i].MaxLevel = 3;
		}
	}

	if (default.MODEVERSION < 14)
	{
		i = default.WeaponUpgrade_Upgrade.Find('WeaponPath', "ZedternalReborn.WMUpgrade_Weapon_SpareAmmo_C4");
		if (i != INDEX_NONE)
			default.WeaponUpgrade_Upgrade[i].WeaponPath = "ZedternalReborn.WMUpgrade_Weapon_SpareAmmo_Small";
	}

	if (default.MODEVERSION < 15)
	{
		i = default.WeaponUpgrade_Upgrade.Find('WeaponPath', "ZedternalReborn.WMUpgrade_Weapon_Damage");
		if (i != INDEX_NONE && default.WeaponUpgrade_Upgrade[i].MaxLevel == 3)
			default.WeaponUpgrade_Upgrade[i].MaxLevel = 5;

		NewItem.WeaponPath = "ZedternalReborn.WMUpgrade_Weapon_TurretAmmo";
		NewItem.PriceMultiplier = 0.6f;
		default.WeaponUpgrade_Upgrade.AddItem(NewItem);

		NewItem.WeaponPath = "ZedternalReborn.WMUpgrade_Weapon_TurretLimit";
		NewItem.PriceMultiplier = 2.0f;
		NewItem.bIsStatic = True;
		default.WeaponUpgrade_Upgrade.AddItem(NewItem);

		NewItem.WeaponPath = "ZedternalReborn.WMUpgrade_Weapon_TurretVision";
		NewItem.PriceMultiplier = 0.15f;
		NewItem.bIsStatic = False;
		default.WeaponUpgrade_Upgrade.AddItem(NewItem);
	}

	if (default.MODEVERSION < class'ZedternalReborn.Config_Base'.const.CurrentVersion)
	{
		// BEGIN TEMPERED INI DEFAULTS (generated; do not edit by hand)
		default.WeaponUpgrade_Upgrade.Length = 35;
		default.WeaponUpgrade_Upgrade[0].WeaponPath = "ZedternalReborn.WMUpgrade_Weapon_Damage";
		default.WeaponUpgrade_Upgrade[0].PriceUnit = 100;
		default.WeaponUpgrade_Upgrade[0].PriceMultiplier = 0.300000f;
		default.WeaponUpgrade_Upgrade[0].MaxLevel = 10;
		default.WeaponUpgrade_Upgrade[0].bIsStatic = True;
		default.WeaponUpgrade_Upgrade[1].WeaponPath = "ZedternalReborn.WMUpgrade_Weapon_Damage_Clot";
		default.WeaponUpgrade_Upgrade[1].PriceUnit = 50;
		default.WeaponUpgrade_Upgrade[1].PriceMultiplier = 0.150000f;
		default.WeaponUpgrade_Upgrade[1].MaxLevel = 5;
		default.WeaponUpgrade_Upgrade[1].bIsStatic = True;
		default.WeaponUpgrade_Upgrade[2].WeaponPath = "ZedternalReborn.WMUpgrade_Weapon_Damage_GroundFire";
		default.WeaponUpgrade_Upgrade[2].PriceUnit = 50;
		default.WeaponUpgrade_Upgrade[2].PriceMultiplier = 0.150000f;
		default.WeaponUpgrade_Upgrade[2].MaxLevel = 5;
		default.WeaponUpgrade_Upgrade[2].bIsStatic = True;
		default.WeaponUpgrade_Upgrade[3].WeaponPath = "ZedternalReborn.WMUpgrade_Weapon_Damage_Headshot";
		default.WeaponUpgrade_Upgrade[3].PriceUnit = 100;
		default.WeaponUpgrade_Upgrade[3].PriceMultiplier = 0.300000f;
		default.WeaponUpgrade_Upgrade[3].MaxLevel = 10;
		default.WeaponUpgrade_Upgrade[3].bIsStatic = True;
		default.WeaponUpgrade_Upgrade[4].WeaponPath = "ZedternalReborn.WMUpgrade_Weapon_DamageTaken";
		default.WeaponUpgrade_Upgrade[4].PriceUnit = 100;
		default.WeaponUpgrade_Upgrade[4].PriceMultiplier = 0.150000f;
		default.WeaponUpgrade_Upgrade[4].MaxLevel = 5;
		default.WeaponUpgrade_Upgrade[4].bIsStatic = True;
		default.WeaponUpgrade_Upgrade[5].WeaponPath = "ZedternalReborn.WMUpgrade_Weapon_HardMeleeAttack";
		default.WeaponUpgrade_Upgrade[5].PriceUnit = 50;
		default.WeaponUpgrade_Upgrade[5].PriceMultiplier = 0.150000f;
		default.WeaponUpgrade_Upgrade[5].MaxLevel = 5;
		default.WeaponUpgrade_Upgrade[5].bIsStatic = True;
		default.WeaponUpgrade_Upgrade[6].WeaponPath = "ZedternalReborn.WMUpgrade_Weapon_Heal";
		default.WeaponUpgrade_Upgrade[6].PriceUnit = 50;
		default.WeaponUpgrade_Upgrade[6].PriceMultiplier = 0.150000f;
		default.WeaponUpgrade_Upgrade[6].MaxLevel = 5;
		default.WeaponUpgrade_Upgrade[6].bIsStatic = True;
		default.WeaponUpgrade_Upgrade[7].WeaponPath = "ZedternalReborn.WMUpgrade_Weapon_KnockdownPower";
		default.WeaponUpgrade_Upgrade[7].PriceUnit = 50;
		default.WeaponUpgrade_Upgrade[7].PriceMultiplier = 0.150000f;
		default.WeaponUpgrade_Upgrade[7].MaxLevel = 5;
		default.WeaponUpgrade_Upgrade[7].bIsStatic = True;
		default.WeaponUpgrade_Upgrade[8].WeaponPath = "ZedternalReborn.WMUpgrade_Weapon_MagSize";
		default.WeaponUpgrade_Upgrade[8].PriceUnit = 50;
		default.WeaponUpgrade_Upgrade[8].PriceMultiplier = 0.150000f;
		default.WeaponUpgrade_Upgrade[8].MaxLevel = 5;
		default.WeaponUpgrade_Upgrade[8].bIsStatic = True;
		default.WeaponUpgrade_Upgrade[9].WeaponPath = "ZedternalReborn.WMUpgrade_Weapon_MagSize_Small";
		default.WeaponUpgrade_Upgrade[9].PriceUnit = 50;
		default.WeaponUpgrade_Upgrade[9].PriceMultiplier = 0.150000f;
		default.WeaponUpgrade_Upgrade[9].MaxLevel = 5;
		default.WeaponUpgrade_Upgrade[9].bIsStatic = True;
		default.WeaponUpgrade_Upgrade[10].WeaponPath = "ZedternalReborn.WMUpgrade_Weapon_MeleeAttackSpeed";
		default.WeaponUpgrade_Upgrade[10].PriceUnit = 50;
		default.WeaponUpgrade_Upgrade[10].PriceMultiplier = 0.150000f;
		default.WeaponUpgrade_Upgrade[10].MaxLevel = 5;
		default.WeaponUpgrade_Upgrade[10].bIsStatic = True;
		default.WeaponUpgrade_Upgrade[11].WeaponPath = "ZedternalReborn.WMUpgrade_Weapon_Penetration";
		default.WeaponUpgrade_Upgrade[11].PriceUnit = 50;
		default.WeaponUpgrade_Upgrade[11].PriceMultiplier = 0.300000f;
		default.WeaponUpgrade_Upgrade[11].MaxLevel = 5;
		default.WeaponUpgrade_Upgrade[11].bIsStatic = True;
		default.WeaponUpgrade_Upgrade[12].WeaponPath = "ZedternalReborn.WMUpgrade_Weapon_RateOfFire";
		default.WeaponUpgrade_Upgrade[12].PriceUnit = 50;
		default.WeaponUpgrade_Upgrade[12].PriceMultiplier = 0.150000f;
		default.WeaponUpgrade_Upgrade[12].MaxLevel = 5;
		default.WeaponUpgrade_Upgrade[12].bIsStatic = True;
		default.WeaponUpgrade_Upgrade[13].WeaponPath = "ZedternalReborn.WMUpgrade_Weapon_Recoil";
		default.WeaponUpgrade_Upgrade[13].PriceUnit = 50;
		default.WeaponUpgrade_Upgrade[13].PriceMultiplier = 0.150000f;
		default.WeaponUpgrade_Upgrade[13].MaxLevel = 5;
		default.WeaponUpgrade_Upgrade[13].bIsStatic = True;
		default.WeaponUpgrade_Upgrade[14].WeaponPath = "ZedternalReborn.WMUpgrade_Weapon_ReloadSpeed";
		default.WeaponUpgrade_Upgrade[14].PriceUnit = 50;
		default.WeaponUpgrade_Upgrade[14].PriceMultiplier = 0.150000f;
		default.WeaponUpgrade_Upgrade[14].MaxLevel = 5;
		default.WeaponUpgrade_Upgrade[14].bIsStatic = True;
		default.WeaponUpgrade_Upgrade[15].WeaponPath = "ZedternalReborn.WMUpgrade_Weapon_SpareAmmo";
		default.WeaponUpgrade_Upgrade[15].PriceUnit = 50;
		default.WeaponUpgrade_Upgrade[15].PriceMultiplier = 0.150000f;
		default.WeaponUpgrade_Upgrade[15].MaxLevel = 5;
		default.WeaponUpgrade_Upgrade[15].bIsStatic = True;
		default.WeaponUpgrade_Upgrade[16].WeaponPath = "ZedternalReborn.WMUpgrade_Weapon_SpareAmmo_Small";
		default.WeaponUpgrade_Upgrade[16].PriceUnit = 50;
		default.WeaponUpgrade_Upgrade[16].PriceMultiplier = 0.150000f;
		default.WeaponUpgrade_Upgrade[16].MaxLevel = 5;
		default.WeaponUpgrade_Upgrade[16].bIsStatic = True;
		default.WeaponUpgrade_Upgrade[17].WeaponPath = "ZedternalReborn.WMUpgrade_Weapon_StumblePower";
		default.WeaponUpgrade_Upgrade[17].PriceUnit = 50;
		default.WeaponUpgrade_Upgrade[17].PriceMultiplier = 0.150000f;
		default.WeaponUpgrade_Upgrade[17].MaxLevel = 5;
		default.WeaponUpgrade_Upgrade[17].bIsStatic = True;
		default.WeaponUpgrade_Upgrade[18].WeaponPath = "ZedternalReborn.WMUpgrade_Weapon_StunPower";
		default.WeaponUpgrade_Upgrade[18].PriceUnit = 50;
		default.WeaponUpgrade_Upgrade[18].PriceMultiplier = 0.150000f;
		default.WeaponUpgrade_Upgrade[18].MaxLevel = 5;
		default.WeaponUpgrade_Upgrade[18].bIsStatic = True;
		default.WeaponUpgrade_Upgrade[19].WeaponPath = "ZedternalReborn.WMUpgrade_Weapon_SwitchSpeed";
		default.WeaponUpgrade_Upgrade[19].PriceUnit = 50;
		default.WeaponUpgrade_Upgrade[19].PriceMultiplier = 0.150000f;
		default.WeaponUpgrade_Upgrade[19].MaxLevel = 5;
		default.WeaponUpgrade_Upgrade[19].bIsStatic = True;
		default.WeaponUpgrade_Upgrade[20].WeaponPath = "ZedternalReborn.WMUpgrade_Weapon_TightChoke";
		default.WeaponUpgrade_Upgrade[20].PriceUnit = 50;
		default.WeaponUpgrade_Upgrade[20].PriceMultiplier = 0.150000f;
		default.WeaponUpgrade_Upgrade[20].MaxLevel = 5;
		default.WeaponUpgrade_Upgrade[20].bIsStatic = True;
		default.WeaponUpgrade_Upgrade[21].WeaponPath = "ZedternalReborn.WMUpgrade_Weapon_AmmunitionConsumption";
		default.WeaponUpgrade_Upgrade[21].PriceUnit = 50;
		default.WeaponUpgrade_Upgrade[21].PriceMultiplier = 0.150000f;
		default.WeaponUpgrade_Upgrade[21].MaxLevel = 5;
		default.WeaponUpgrade_Upgrade[21].bIsStatic = True;
		default.WeaponUpgrade_Upgrade[22].WeaponPath = "ZedternalReborn.WMUpgrade_Weapon_Damage_Fleshpound";
		default.WeaponUpgrade_Upgrade[22].PriceUnit = 100;
		default.WeaponUpgrade_Upgrade[22].PriceMultiplier = 0.300000f;
		default.WeaponUpgrade_Upgrade[22].MaxLevel = 5;
		default.WeaponUpgrade_Upgrade[22].bIsStatic = True;
		default.WeaponUpgrade_Upgrade[23].WeaponPath = "ZedternalReborn.WMUpgrade_Weapon_TurretAmmo";
		default.WeaponUpgrade_Upgrade[23].PriceUnit = 50;
		default.WeaponUpgrade_Upgrade[23].PriceMultiplier = 0.600000f;
		default.WeaponUpgrade_Upgrade[23].MaxLevel = 5;
		default.WeaponUpgrade_Upgrade[23].bIsStatic = True;
		default.WeaponUpgrade_Upgrade[24].WeaponPath = "ZedternalReborn.WMUpgrade_Weapon_TurretLimit";
		default.WeaponUpgrade_Upgrade[24].PriceUnit = 50;
		default.WeaponUpgrade_Upgrade[24].PriceMultiplier = 2.000000f;
		default.WeaponUpgrade_Upgrade[24].MaxLevel = 5;
		default.WeaponUpgrade_Upgrade[24].bIsStatic = True;
		default.WeaponUpgrade_Upgrade[25].WeaponPath = "ZedternalReborn.WMUpgrade_Weapon_TurretVision";
		default.WeaponUpgrade_Upgrade[25].PriceUnit = 50;
		default.WeaponUpgrade_Upgrade[25].PriceMultiplier = 0.200000f;
		default.WeaponUpgrade_Upgrade[25].MaxLevel = 5;
		default.WeaponUpgrade_Upgrade[25].bIsStatic = True;
		default.WeaponUpgrade_Upgrade[26].WeaponPath = "ZedternalTempered.DKUpgrade_Weapon_Infiltrator";
		default.WeaponUpgrade_Upgrade[26].PriceUnit = 200;
		default.WeaponUpgrade_Upgrade[26].PriceMultiplier = 0.200000f;
		default.WeaponUpgrade_Upgrade[26].MaxLevel = 5;
		default.WeaponUpgrade_Upgrade[26].bIsStatic = True;
		default.WeaponUpgrade_Upgrade[27].WeaponPath = "ZedternalTempered.DKUpgrade_Weapon_Hustler";
		default.WeaponUpgrade_Upgrade[27].PriceUnit = 50;
		default.WeaponUpgrade_Upgrade[27].PriceMultiplier = 0.100000f;
		default.WeaponUpgrade_Upgrade[27].MaxLevel = 20;
		default.WeaponUpgrade_Upgrade[27].bIsStatic = True;
		default.WeaponUpgrade_Upgrade[28].WeaponPath = "ZedternalTempered.DKUpgrade_Weapon_DualHitman";
		default.WeaponUpgrade_Upgrade[28].PriceUnit = 100;
		default.WeaponUpgrade_Upgrade[28].PriceMultiplier = 0.200000f;
		default.WeaponUpgrade_Upgrade[28].MaxLevel = 20;
		default.WeaponUpgrade_Upgrade[28].bIsStatic = True;
		default.WeaponUpgrade_Upgrade[29].WeaponPath = "ZedternalTempered.DKUpgrade_Weapon_DualPyromaniac";
		default.WeaponUpgrade_Upgrade[29].PriceUnit = 50;
		default.WeaponUpgrade_Upgrade[29].PriceMultiplier = 0.100000f;
		default.WeaponUpgrade_Upgrade[29].MaxLevel = 20;
		default.WeaponUpgrade_Upgrade[29].bIsStatic = True;
		default.WeaponUpgrade_Upgrade[30].WeaponPath = "ZedternalTempered.DKUpgrade_Weapon_DualEMT";
		default.WeaponUpgrade_Upgrade[30].PriceUnit = 50;
		default.WeaponUpgrade_Upgrade[30].PriceMultiplier = 0.100000f;
		default.WeaponUpgrade_Upgrade[30].MaxLevel = 20;
		default.WeaponUpgrade_Upgrade[30].bIsStatic = True;
		default.WeaponUpgrade_Upgrade[31].WeaponPath = "ZedternalTempered.DKUpgrade_Weapon_DualSprayAndPray";
		default.WeaponUpgrade_Upgrade[31].PriceUnit = 75;
		default.WeaponUpgrade_Upgrade[31].PriceMultiplier = 0.200000f;
		default.WeaponUpgrade_Upgrade[31].MaxLevel = 20;
		default.WeaponUpgrade_Upgrade[31].bIsStatic = True;
		default.WeaponUpgrade_Upgrade[32].WeaponPath = "ZedternalTempered.DKUpgrade_Weapon_DualArmory";
		default.WeaponUpgrade_Upgrade[32].PriceUnit = 50;
		default.WeaponUpgrade_Upgrade[32].PriceMultiplier = 0.100000f;
		default.WeaponUpgrade_Upgrade[32].MaxLevel = 20;
		default.WeaponUpgrade_Upgrade[32].bIsStatic = True;
		default.WeaponUpgrade_Upgrade[33].WeaponPath = "ZedternalTempered.DKUpgrade_Weapon_Ricochet";
		default.WeaponUpgrade_Upgrade[33].PriceUnit = 50;
		default.WeaponUpgrade_Upgrade[33].PriceMultiplier = 0.150000f;
		default.WeaponUpgrade_Upgrade[33].MaxLevel = 5;
		default.WeaponUpgrade_Upgrade[33].bIsStatic = True;
		default.WeaponUpgrade_Upgrade[34].WeaponPath = "ZedternalTempered.DKUpgrade_Weapon_DoubleStrike";
		default.WeaponUpgrade_Upgrade[34].PriceUnit = 50;
		default.WeaponUpgrade_Upgrade[34].PriceMultiplier = 0.150000f;
		default.WeaponUpgrade_Upgrade[34].MaxLevel = 10;
		default.WeaponUpgrade_Upgrade[34].bIsStatic = True;
		// END TEMPERED INI DEFAULTS
		default.MODEVERSION = class'ZedternalReborn.Config_Base'.const.CurrentVersion;
		static.StaticSaveConfig();
	}
}

static function CheckBasicConfigValues()
{
	local int i;

	for (i = 0; i < default.WeaponUpgrade_Upgrade.Length; ++i)
	{
		if (default.WeaponUpgrade_Upgrade[i].PriceUnit < 0)
		{
			LogBadConfigMessage("WeaponUpgrade_Upgrade - Line" @ string(i + 1) @ "- PriceUnit",
				string(default.WeaponUpgrade_Upgrade[i].PriceUnit),
				"0", "0 dosh, free", "value >= 0");
			default.WeaponUpgrade_Upgrade[i].PriceUnit = 0;
		}

		if (default.WeaponUpgrade_Upgrade[i].PriceMultiplier < 0)
		{
			LogBadConfigMessage("WeaponUpgrade_Upgrade - Line" @ string(i + 1) @ "- PriceMultiplier",
				string(default.WeaponUpgrade_Upgrade[i].PriceMultiplier),
				"0.0", "0% increase, no scaling", "value >= 0.0");
			default.WeaponUpgrade_Upgrade[i].PriceMultiplier = 0;
		}

		if (default.WeaponUpgrade_Upgrade[i].MaxLevel < 0)
		{
			LogBadConfigMessage("WeaponUpgrade_Upgrade - Line" @ string(i + 1) @ "- MaxLevel",
				string(default.WeaponUpgrade_Upgrade[i].MaxLevel),
				"0", "0 levels, disable upgrade", "value >= 0");
			default.WeaponUpgrade_Upgrade[i].MaxLevel = 0;
		}

		if (default.WeaponUpgrade_Upgrade[i].MaxLevel > 255)
		{
			LogBadConfigMessage("WeaponUpgrade_Upgrade - Line" @ string(i + 1) @ "- MaxLevel",
				string(default.WeaponUpgrade_Upgrade[i].MaxLevel),
				"255", "255 levels, max upgrade", "value >= 0");
			default.WeaponUpgrade_Upgrade[i].MaxLevel = 255;
		}
	}
}

static function LoadConfigObjects(out array<S_WeaponUpgrade> ValidUpgrades, out array< class<WMUpgrade_Weapon> > UpgradeObjects)
{
	local int i;
	local class<WMUpgrade_Weapon> Obj;

	ValidUpgrades.Length = 0;
	UpgradeObjects.Length = 0;

	for (i = 0; i < default.WeaponUpgrade_Upgrade.Length; ++i)
	{
		if (default.WeaponUpgrade_Upgrade[i].MaxLevel > 0)
		{
			Obj = class<WMUpgrade_Weapon>(DynamicLoadObject(default.WeaponUpgrade_Upgrade[i].WeaponPath, class'Class', True));
			if (Obj == None)
			{
				LogBadLoadObjectConfigMessage("WeaponUpgrade_Upgrade", i, default.WeaponUpgrade_Upgrade[i].WeaponPath);
			}
			else
			{
				ValidUpgrades.AddItem(default.WeaponUpgrade_Upgrade[i]);
				UpgradeObjects.AddItem(Obj);
			}
		}
		else
			`log("ZR Config Info: Weapon upgrade disabled because max level is zero:" @default.WeaponUpgrade_Upgrade[i].WeaponPath);
	}
}

defaultproperties
{
	Name="Default__Config_WeaponUpgrade"
}
