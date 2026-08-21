class ZTConfig_PerkReroll extends Config_Common config(ZedternalUnlimited);

var config int MODEVERSION;

var config bool PerkReroll_bEnable;
var config int PerkReroll_BasePrice;
var config float PerkReroll_NextRerollPriceMultiplier;

static function InitializeConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.PerkReroll_bEnable = True;
		default.PerkReroll_BasePrice = 500;
		default.PerkReroll_NextRerollPriceMultiplier = 1.5f;
	}

	if (default.MODEVERSION < 1)
	{
		// BEGIN TEMPERED INI DEFAULTS (generated; do not edit by hand)
		default.PerkReroll_BasePrice = 500;
		default.PerkReroll_NextRerollPriceMultiplier = 1.500000f;
		// END TEMPERED INI DEFAULTS
		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static function CheckBasicConfigValues()
{
	if (default.PerkReroll_bEnable)
	{
		if (default.PerkReroll_BasePrice < 0)
		{
			LogBadConfigMessage("PerkReroll_BasePrice",
				string(default.PerkReroll_BasePrice),
				"0", "0 dosh, free", "value >= 0");
			default.PerkReroll_BasePrice = 0;
		}

		if (default.PerkReroll_NextRerollPriceMultiplier < 1.0f)
		{
			LogBadConfigMessage("PerkReroll_NextRerollPriceMultiplier",
				string(default.PerkReroll_NextRerollPriceMultiplier),
				"1.0", "1x, no increase", "value >= 1.0");
			default.PerkReroll_NextRerollPriceMultiplier = 1.0f;
		}
	}
	else
	{
		SkipCheckConfigMessage("PerkReroll_BasePrice", "PerkReroll_bEnable");
		SkipCheckConfigMessage("PerkReroll_NextRerollPriceMultiplier", "PerkReroll_bEnable");
	}
}

defaultproperties
{
	Name="Default__ZTConfig_PerkReroll"
}
