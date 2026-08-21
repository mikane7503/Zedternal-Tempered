class Config_EquipmentUpgrade extends Config_Common
	config(ZedternalReborn_Upgrades);

var config int MODEVERSION;

struct S_EquipmentUpgrade
{
	var string EquipmentPath;
	var int BasePrice;
	var int MaxPrice;
	var int MaxLevel;
};

var config array<S_EquipmentUpgrade> EquipmentUpgrade_Upgrade;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.EquipmentUpgrade_Upgrade.Length = 7;

		default.EquipmentUpgrade_Upgrade[0].EquipmentPath = "ZedternalReborn.WMUpgrade_Equipment_FallCompensatorBoots";
		default.EquipmentUpgrade_Upgrade[0].BasePrice = 400;
		default.EquipmentUpgrade_Upgrade[0].MaxPrice = 800;
		default.EquipmentUpgrade_Upgrade[0].MaxLevel = 2;

		default.EquipmentUpgrade_Upgrade[1].EquipmentPath = "ZedternalReborn.WMUpgrade_Equipment_GasMask";
		default.EquipmentUpgrade_Upgrade[1].BasePrice = 1250;
		default.EquipmentUpgrade_Upgrade[1].MaxPrice = 0;
		default.EquipmentUpgrade_Upgrade[1].MaxLevel = 1;

		default.EquipmentUpgrade_Upgrade[2].EquipmentPath = "ZedternalReborn.WMUpgrade_Equipment_NightVision";
		default.EquipmentUpgrade_Upgrade[2].BasePrice = 250;
		default.EquipmentUpgrade_Upgrade[2].MaxPrice = 0;
		default.EquipmentUpgrade_Upgrade[2].MaxLevel = 1;

		default.EquipmentUpgrade_Upgrade[3].EquipmentPath = "ZedternalReborn.WMUpgrade_Equipment_HealthUp";
		default.EquipmentUpgrade_Upgrade[3].BasePrice = 400;
		default.EquipmentUpgrade_Upgrade[3].MaxPrice = 2000;
		default.EquipmentUpgrade_Upgrade[3].MaxLevel = 5;

		default.EquipmentUpgrade_Upgrade[4].EquipmentPath = "ZedternalReborn.WMUpgrade_Equipment_ArmorUp";
		default.EquipmentUpgrade_Upgrade[4].BasePrice = 300;
		default.EquipmentUpgrade_Upgrade[4].MaxPrice = 1500;
		default.EquipmentUpgrade_Upgrade[4].MaxLevel = 5;

		default.EquipmentUpgrade_Upgrade[5].EquipmentPath = "ZedternalReborn.WMUpgrade_Equipment_SpareBatteries";
		default.EquipmentUpgrade_Upgrade[5].BasePrice = 200;
		default.EquipmentUpgrade_Upgrade[5].MaxPrice = 800;
		default.EquipmentUpgrade_Upgrade[5].MaxLevel = 4;

		default.EquipmentUpgrade_Upgrade[6].EquipmentPath = "ZedternalReborn.WMUpgrade_Equipment_HUDStabilizer";
		default.EquipmentUpgrade_Upgrade[6].BasePrice = 1250;
		default.EquipmentUpgrade_Upgrade[6].MaxPrice = 0;
		default.EquipmentUpgrade_Upgrade[6].MaxLevel = 1;
	}

	if (default.MODEVERSION < class'ZedternalReborn.Config_Base'.const.CurrentVersion)
	{
		// BEGIN TEMPERED INI DEFAULTS (generated; do not edit by hand)
		default.EquipmentUpgrade_Upgrade.Length = 15;
		default.EquipmentUpgrade_Upgrade[0].EquipmentPath = "ZedternalReborn.WMUpgrade_Equipment_FallCompensatorBoots";
		default.EquipmentUpgrade_Upgrade[0].BasePrice = 200;
		default.EquipmentUpgrade_Upgrade[0].MaxPrice = 400;
		default.EquipmentUpgrade_Upgrade[0].MaxLevel = 2;
		default.EquipmentUpgrade_Upgrade[1].EquipmentPath = "ZedternalReborn.WMUpgrade_Equipment_GasMask";
		default.EquipmentUpgrade_Upgrade[1].BasePrice = 1250;
		default.EquipmentUpgrade_Upgrade[1].MaxPrice = 0;
		default.EquipmentUpgrade_Upgrade[1].MaxLevel = 1;
		default.EquipmentUpgrade_Upgrade[2].EquipmentPath = "ZedternalReborn.WMUpgrade_Equipment_NightVision";
		default.EquipmentUpgrade_Upgrade[2].BasePrice = 150;
		default.EquipmentUpgrade_Upgrade[2].MaxPrice = 0;
		default.EquipmentUpgrade_Upgrade[2].MaxLevel = 1;
		default.EquipmentUpgrade_Upgrade[3].EquipmentPath = "ZedternalReborn.WMUpgrade_Equipment_HealthUp";
		default.EquipmentUpgrade_Upgrade[3].BasePrice = 300;
		default.EquipmentUpgrade_Upgrade[3].MaxPrice = 1000;
		default.EquipmentUpgrade_Upgrade[3].MaxLevel = 30;
		default.EquipmentUpgrade_Upgrade[4].EquipmentPath = "ZedternalReborn.WMUpgrade_Equipment_ArmorUp";
		default.EquipmentUpgrade_Upgrade[4].BasePrice = 300;
		default.EquipmentUpgrade_Upgrade[4].MaxPrice = 1000;
		default.EquipmentUpgrade_Upgrade[4].MaxLevel = 30;
		default.EquipmentUpgrade_Upgrade[5].EquipmentPath = "ZedternalReborn.WMUpgrade_Equipment_SpareBatteries";
		default.EquipmentUpgrade_Upgrade[5].BasePrice = 200;
		default.EquipmentUpgrade_Upgrade[5].MaxPrice = 800;
		default.EquipmentUpgrade_Upgrade[5].MaxLevel = 4;
		default.EquipmentUpgrade_Upgrade[6].EquipmentPath = "ZedternalReborn.WMUpgrade_Equipment_HUDStabilizer";
		default.EquipmentUpgrade_Upgrade[6].BasePrice = 1250;
		default.EquipmentUpgrade_Upgrade[6].MaxPrice = 0;
		default.EquipmentUpgrade_Upgrade[6].MaxLevel = 1;
		default.EquipmentUpgrade_Upgrade[7].EquipmentPath = "HowdyZTRExt.ZRUpgrade_Equipment_Exchange_ShapedGlass";
		default.EquipmentUpgrade_Upgrade[7].BasePrice = 5000;
		default.EquipmentUpgrade_Upgrade[7].MaxPrice = 7500;
		default.EquipmentUpgrade_Upgrade[7].MaxLevel = 1;
		default.EquipmentUpgrade_Upgrade[8].EquipmentPath = "HowdyZTRExt.ZRUpgrade_Equipment_Exchange_Pacifist";
		default.EquipmentUpgrade_Upgrade[8].BasePrice = 5000;
		default.EquipmentUpgrade_Upgrade[8].MaxPrice = 10000;
		default.EquipmentUpgrade_Upgrade[8].MaxLevel = 2;
		default.EquipmentUpgrade_Upgrade[9].EquipmentPath = "HowdyZTRExt.ZRUpgrade_Equipment_Exchange_Bulwark";
		default.EquipmentUpgrade_Upgrade[9].BasePrice = 5000;
		default.EquipmentUpgrade_Upgrade[9].MaxPrice = 10000;
		default.EquipmentUpgrade_Upgrade[9].MaxLevel = 2;
		default.EquipmentUpgrade_Upgrade[10].EquipmentPath = "HowdyZTRExt.ZRUpgrade_Equipment_Exchange_LightPacker";
		default.EquipmentUpgrade_Upgrade[10].BasePrice = 10000;
		default.EquipmentUpgrade_Upgrade[10].MaxPrice = 12500;
		default.EquipmentUpgrade_Upgrade[10].MaxLevel = 1;
		default.EquipmentUpgrade_Upgrade[11].EquipmentPath = "HowdyZTRExt.ZRUpgrade_Equipment_Exchange_ExcessiveMag";
		default.EquipmentUpgrade_Upgrade[11].BasePrice = 3000;
		default.EquipmentUpgrade_Upgrade[11].MaxPrice = 10000;
		default.EquipmentUpgrade_Upgrade[11].MaxLevel = 2;
		default.EquipmentUpgrade_Upgrade[12].EquipmentPath = "HowdyZTRExt.ZRUpgrade_Equipment_Exchange_TriggerHappy";
		default.EquipmentUpgrade_Upgrade[12].BasePrice = 5000;
		default.EquipmentUpgrade_Upgrade[12].MaxPrice = 10000;
		default.EquipmentUpgrade_Upgrade[12].MaxLevel = 1;
		default.EquipmentUpgrade_Upgrade[13].EquipmentPath = "HowdyZTRExt.ZRUpgrade_Equipment_SnakesBandana";
		default.EquipmentUpgrade_Upgrade[13].BasePrice = 50000;
		default.EquipmentUpgrade_Upgrade[13].MaxPrice = 100000;
		default.EquipmentUpgrade_Upgrade[13].MaxLevel = 1;
		default.EquipmentUpgrade_Upgrade[14].EquipmentPath = "HowdyZTRExt.ZRUpgrade_Equipment_Untouchable";
		default.EquipmentUpgrade_Upgrade[14].BasePrice = 25000;
		default.EquipmentUpgrade_Upgrade[14].MaxPrice = 100000;
		default.EquipmentUpgrade_Upgrade[14].MaxLevel = 1;
		// END TEMPERED INI DEFAULTS
		default.MODEVERSION = class'ZedternalReborn.Config_Base'.const.CurrentVersion;
		static.StaticSaveConfig();
	}
}

static function CheckBasicConfigValues()
{
	local int i;

	for (i = 0; i < default.EquipmentUpgrade_Upgrade.Length; ++i)
	{
		if (default.EquipmentUpgrade_Upgrade[i].BasePrice < 0)
		{
			LogBadConfigMessage("EquipmentUpgrade_Upgrade - Line" @ string(i + 1) @ "- BasePrice",
				string(default.EquipmentUpgrade_Upgrade[i].BasePrice),
				"0", "0 dosh, free", "value >= 0");
			default.EquipmentUpgrade_Upgrade[i].BasePrice = 0;
		}

		if (default.EquipmentUpgrade_Upgrade[i].MaxPrice < 0)
		{
			LogBadConfigMessage("EquipmentUpgrade_Upgrade - Line" @ string(i + 1) @ "- MaxPrice",
				string(default.EquipmentUpgrade_Upgrade[i].MaxPrice),
				"0", "0 dosh, free", "value >= 0");
			default.EquipmentUpgrade_Upgrade[i].MaxPrice = 0;
		}

		if (default.EquipmentUpgrade_Upgrade[i].MaxLevel < 0)
		{
			LogBadConfigMessage("EquipmentUpgrade_Upgrade - Line" @ string(i + 1) @ "- MaxLevel",
				string(default.EquipmentUpgrade_Upgrade[i].MaxLevel),
				"0", "0 levels, disable upgrade", "value >= 0");
			default.EquipmentUpgrade_Upgrade[i].MaxLevel = 0;
		}

		if (default.EquipmentUpgrade_Upgrade[i].MaxLevel > 255)
		{
			LogBadConfigMessage("EquipmentUpgrade_Upgrade - Line" @ string(i + 1) @ "- MaxLevel",
				string(default.EquipmentUpgrade_Upgrade[i].MaxLevel),
				"255", "255 levels, max upgrade", "value >= 0");
			default.EquipmentUpgrade_Upgrade[i].MaxLevel = 255;
		}
	}
}

static function LoadConfigObjects(out array<S_EquipmentUpgrade> ValidUpgrades, out array< class<WMUpgrade_Equipment> > UpgradeObjects)
{
	local int i;
	local class<WMUpgrade_Equipment> Obj;

	ValidUpgrades.Length = 0;
	UpgradeObjects.Length = 0;

	for (i = 0; i < default.EquipmentUpgrade_Upgrade.Length; ++i)
	{
		if (default.EquipmentUpgrade_Upgrade[i].MaxLevel > 0)
		{
			Obj = class<WMUpgrade_Equipment>(DynamicLoadObject(default.EquipmentUpgrade_Upgrade[i].EquipmentPath, class'Class', True));
			if (Obj == None)
			{
				LogBadLoadObjectConfigMessage("EquipmentUpgrade_Upgrade", i, default.EquipmentUpgrade_Upgrade[i].EquipmentPath);
			}
			else
			{
				ValidUpgrades.AddItem(default.EquipmentUpgrade_Upgrade[i]);
				UpgradeObjects.AddItem(Obj);
			}
		}
		else
			`log("ZR Config Info: Equipment upgrade disabled because max level is zero:" @default.EquipmentUpgrade_Upgrade[i].EquipmentPath);
	}
}

defaultproperties
{
	Name="Default__Config_EquipmentUpgrade"
}
