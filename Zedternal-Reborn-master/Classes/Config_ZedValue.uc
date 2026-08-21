class Config_ZedValue extends Config_Common
	config(ZedternalReborn_ZedWaves);

var config int MODEVERSION;

struct S_ZedValue
{
	var string ZedPath;
	var int Value;
	var int ValuePerExtraPlayer;

	structdefaultproperties
	{
		ValuePerExtraPlayer = 0;
	}
};
var config array<S_ZedValue> Zed_Value;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Zed_Value.Length = 45;

		// Clots

		default.Zed_Value[0].ZedPath = "KFGameContent.KFPawn_ZedClot_Cyst";
		default.Zed_Value[0].Value = 6;

		default.Zed_Value[1].ZedPath = "KFGameContent.KFPawn_ZedClot_Alpha";
		default.Zed_Value[1].Value = 6;

		default.Zed_Value[2].ZedPath = "ZedternalReborn.WMPawn_ZedClot_Alpha_NoRiot";
		default.Zed_Value[2].Value = 6;

		default.Zed_Value[3].ZedPath = "KFGameContent.KFPawn_ZedClot_AlphaKing";
		default.Zed_Value[3].Value = 20;

		default.Zed_Value[4].ZedPath = "KFGameContent.KFPawn_ZedClot_Slasher";
		default.Zed_Value[4].Value = 7;

		default.Zed_Value[5].ZedPath = "ZedternalReborn.WMPawn_ZedClot_Slasher_Omega";
		default.Zed_Value[5].Value = 24;

		//Crawler

		default.Zed_Value[6].ZedPath = "KFGameContent.KFPawn_ZedCrawler";
		default.Zed_Value[6].Value = 8;

		default.Zed_Value[7].ZedPath = "ZedternalReborn.WMPawn_ZedCrawler_NoElite";
		default.Zed_Value[7].Value = 8;

		default.Zed_Value[8].ZedPath = "KFGameContent.KFPawn_ZedCrawlerKing";
		default.Zed_Value[8].Value = 20;

		default.Zed_Value[9].ZedPath = "ZedternalReborn.WMPawn_ZedCrawler_Mini";
		default.Zed_Value[9].Value = 5;

		default.Zed_Value[10].ZedPath = "ZedternalReborn.WMPawn_ZedCrawler_Medium";
		default.Zed_Value[10].Value = 7;

		default.Zed_Value[11].ZedPath = "ZedternalReborn.WMPawn_ZedCrawler_Big";
		default.Zed_Value[11].Value = 20;

		default.Zed_Value[12].ZedPath = "ZedternalReborn.WMPawn_ZedCrawler_Huge";
		default.Zed_Value[12].Value = 45;

		default.Zed_Value[13].ZedPath = "ZedternalReborn.WMPawn_ZedCrawler_Ultra";
		default.Zed_Value[13].Value = 75;

		// Gorefast

		default.Zed_Value[14].ZedPath = "KFGameContent.KFPawn_ZedGorefast";
		default.Zed_Value[14].Value = 16;

		default.Zed_Value[15].ZedPath = "ZedternalReborn.WMPawn_ZedGorefast_NoDualBlade";
		default.Zed_Value[15].Value = 16;

		default.Zed_Value[16].ZedPath = "KFGameContent.KFPawn_ZedGorefastDualBlade";
		default.Zed_Value[16].Value = 35;

		default.Zed_Value[17].ZedPath = "ZedternalReborn.WMPawn_ZedGorefast_Omega";
		default.Zed_Value[17].Value = 40;

		// Stalker

		default.Zed_Value[18].ZedPath = "KFGameContent.KFPawn_ZedStalker";
		default.Zed_Value[18].Value = 10;

		default.Zed_Value[19].ZedPath = "ZedternalReborn.WMPawn_ZedStalker_NoDAR";
		default.Zed_Value[19].Value = 10;

		default.Zed_Value[20].ZedPath = "ZedternalReborn.WMPawn_ZedStalker_Omega";
		default.Zed_Value[20].Value = 25;

		// Bloat

		default.Zed_Value[21].ZedPath = "KFGameContent.KFPawn_ZedBloat";
		default.Zed_Value[21].Value = 25;

		default.Zed_Value[22].ZedPath = "KFGameContent.KFPawn_ZedBloatKingSubspawn";
		default.Zed_Value[22].Value = 15;

		// Husk

		default.Zed_Value[23].ZedPath = "KFGameContent.KFPawn_ZedHusk";
		default.Zed_Value[23].Value = 25;

		default.Zed_Value[24].ZedPath = "ZedternalReborn.WMPawn_ZedHusk_NoDAR";
		default.Zed_Value[24].Value = 25;

		default.Zed_Value[25].ZedPath = "ZedternalReborn.WMPawn_ZedHusk_Tiny_Green";
		default.Zed_Value[25].Value = 18;

		default.Zed_Value[26].ZedPath = "ZedternalReborn.WMPawn_ZedHusk_Tiny_Blue";
		default.Zed_Value[26].Value = 18;

		default.Zed_Value[27].ZedPath = "ZedternalReborn.WMPawn_ZedHusk_Tiny_Pink";
		default.Zed_Value[27].Value = 18;

		default.Zed_Value[28].ZedPath = "ZedternalReborn.WMPawn_ZedHusk_Omega";
		default.Zed_Value[28].Value = 70;

		// Siren

		default.Zed_Value[29].ZedPath = "KFGameContent.KFPawn_ZedSiren";
		default.Zed_Value[29].Value = 30;

		default.Zed_Value[30].ZedPath = "ZedternalReborn.WMPawn_ZedSiren_Omega";
		default.Zed_Value[30].Value = 50;
		default.Zed_Value[30].ValuePerExtraPlayer = 3;

		// DAR

		default.Zed_Value[31].ZedPath = "KFGameContent.KFPawn_ZedDAR_Rocket";
		default.Zed_Value[31].Value = 45;

		default.Zed_Value[32].ZedPath = "KFGameContent.KFPawn_ZedDAR_Laser";
		default.Zed_Value[32].Value = 45;

		default.Zed_Value[33].ZedPath = "KFGameContent.KFPawn_ZedDAR_EMP";
		default.Zed_Value[33].Value = 45;

		// Scrake

		default.Zed_Value[34].ZedPath = "ZedternalReborn.WMPawn_ZedScrake_Tiny";
		default.Zed_Value[34].Value = 80;

		default.Zed_Value[35].ZedPath = "KFGameContent.KFPawn_ZedScrake";
		default.Zed_Value[35].Value = 110;
		default.Zed_Value[35].ValuePerExtraPlayer = 9;

		default.Zed_Value[36].ZedPath = "ZedternalReborn.WMPawn_ZedScrake_Omega";
		default.Zed_Value[36].Value = 400;
		default.Zed_Value[36].ValuePerExtraPlayer = 32;

		// Fleshpound

		default.Zed_Value[37].ZedPath = "KFGameContent.KFPawn_ZedFleshpoundMini";
		default.Zed_Value[37].Value = 100;
		default.Zed_Value[37].ValuePerExtraPlayer = 8;

		default.Zed_Value[38].ZedPath = "KFGameContent.KFPawn_ZedFleshpound";
		default.Zed_Value[38].Value = 175;
		default.Zed_Value[38].ValuePerExtraPlayer = 14;

		default.Zed_Value[39].ZedPath = "ZedternalReborn.WMPawn_ZedFleshpound_Omega";
		default.Zed_Value[39].Value = 400;
		default.Zed_Value[39].ValuePerExtraPlayer = 32;

		// Bosses

		default.Zed_Value[40].ZedPath = "ZedternalReborn.WMPawn_ZedFleshpoundKing";
		default.Zed_Value[40].Value = 2400;
		default.Zed_Value[40].ValuePerExtraPlayer = 200;

		default.Zed_Value[41].ZedPath = "ZedternalReborn.WMPawn_ZedPatriarch";
		default.Zed_Value[41].Value = 2400;
		default.Zed_Value[41].ValuePerExtraPlayer = 200;

		default.Zed_Value[42].ZedPath = "ZedternalReborn.WMPawn_ZedMatriarch";
		default.Zed_Value[42].Value = 2400;
		default.Zed_Value[42].ValuePerExtraPlayer = 200;

		default.Zed_Value[43].ZedPath = "ZedternalReborn.WMPawn_ZedHans";
		default.Zed_Value[43].Value = 2400;
		default.Zed_Value[43].ValuePerExtraPlayer = 200;

		default.Zed_Value[44].ZedPath = "ZedternalReborn.WMPawn_ZedBloatKing";
		default.Zed_Value[44].Value = 2400;
		default.Zed_Value[44].ValuePerExtraPlayer = 200;
	}

	if (default.MODEVERSION < class'ZedternalReborn.Config_Base'.const.CurrentVersion)
	{
		// BEGIN TEMPERED INI DEFAULTS (generated; do not edit by hand)
		default.Zed_Value.Length = 43;
		default.Zed_Value[0].ZedPath = "KFGameContent.KFPawn_ZedClot_Cyst";
		default.Zed_Value[0].Value = 8;
		default.Zed_Value[0].ValuePerExtraPlayer = 0;
		default.Zed_Value[1].ZedPath = "KFGameContent.KFPawn_ZedClot_Alpha";
		default.Zed_Value[1].Value = 10;
		default.Zed_Value[1].ValuePerExtraPlayer = 0;
		default.Zed_Value[2].ZedPath = "ZedternalReborn.WMPawn_ZedClot_Alpha_NoRiot";
		default.Zed_Value[2].Value = 10;
		default.Zed_Value[2].ValuePerExtraPlayer = 0;
		default.Zed_Value[3].ZedPath = "KFGameContent.KFPawn_ZedClot_AlphaKing";
		default.Zed_Value[3].Value = 28;
		default.Zed_Value[3].ValuePerExtraPlayer = 2;
		default.Zed_Value[4].ZedPath = "KFGameContent.KFPawn_ZedClot_Slasher";
		default.Zed_Value[4].Value = 12;
		default.Zed_Value[4].ValuePerExtraPlayer = 0;
		default.Zed_Value[5].ZedPath = "ZedternalReborn.WMPawn_ZedClot_Slasher_Omega";
		default.Zed_Value[5].Value = 24;
		default.Zed_Value[5].ValuePerExtraPlayer = 0;
		default.Zed_Value[6].ZedPath = "KFGameContent.KFPawn_ZedCrawler";
		default.Zed_Value[6].Value = 10;
		default.Zed_Value[6].ValuePerExtraPlayer = 0;
		default.Zed_Value[7].ZedPath = "ZedternalReborn.WMPawn_ZedCrawler_NoElite";
		default.Zed_Value[7].Value = 10;
		default.Zed_Value[7].ValuePerExtraPlayer = 0;
		default.Zed_Value[8].ZedPath = "KFGameContent.KFPawn_ZedCrawlerKing";
		default.Zed_Value[8].Value = 16;
		default.Zed_Value[8].ValuePerExtraPlayer = 0;
		default.Zed_Value[9].ZedPath = "ZedternalRebornExt.WMPawn_ZedHellcrawler";
		default.Zed_Value[9].Value = 20;
		default.Zed_Value[9].ValuePerExtraPlayer = 0;
		default.Zed_Value[10].ZedPath = "ZedternalReborn.WMPawn_ZedCrawler_Mini";
		default.Zed_Value[10].Value = 5;
		default.Zed_Value[10].ValuePerExtraPlayer = 0;
		default.Zed_Value[11].ZedPath = "ZedternalReborn.WMPawn_ZedCrawler_Medium";
		default.Zed_Value[11].Value = 7;
		default.Zed_Value[11].ValuePerExtraPlayer = 0;
		default.Zed_Value[12].ZedPath = "ZedternalReborn.WMPawn_ZedCrawler_Big";
		default.Zed_Value[12].Value = 20;
		default.Zed_Value[12].ValuePerExtraPlayer = 0;
		default.Zed_Value[13].ZedPath = "ZedternalReborn.WMPawn_ZedCrawler_Huge";
		default.Zed_Value[13].Value = 45;
		default.Zed_Value[13].ValuePerExtraPlayer = 0;
		default.Zed_Value[14].ZedPath = "ZedternalReborn.WMPawn_ZedCrawler_Ultra";
		default.Zed_Value[14].Value = 75;
		default.Zed_Value[14].ValuePerExtraPlayer = 0;
		default.Zed_Value[15].ZedPath = "KFGameContent.KFPawn_ZedGorefast";
		default.Zed_Value[15].Value = 16;
		default.Zed_Value[15].ValuePerExtraPlayer = 0;
		default.Zed_Value[16].ZedPath = "ZedternalReborn.WMPawn_ZedGorefast_NoDualBlade";
		default.Zed_Value[16].Value = 16;
		default.Zed_Value[16].ValuePerExtraPlayer = 0;
		default.Zed_Value[17].ZedPath = "KFGameContent.KFPawn_ZedGorefastDualBlade";
		default.Zed_Value[17].Value = 28;
		default.Zed_Value[17].ValuePerExtraPlayer = 1;
		default.Zed_Value[18].ZedPath = "ZedternalReborn.WMPawn_ZedGorefast_Omega";
		default.Zed_Value[18].Value = 42;
		default.Zed_Value[18].ValuePerExtraPlayer = 0;
		default.Zed_Value[19].ZedPath = "KFGameContent.KFPawn_ZedStalker";
		default.Zed_Value[19].Value = 10;
		default.Zed_Value[19].ValuePerExtraPlayer = 0;
		default.Zed_Value[20].ZedPath = "ZedternalReborn.WMPawn_ZedStalker_NoDAR";
		default.Zed_Value[20].Value = 12;
		default.Zed_Value[20].ValuePerExtraPlayer = 0;
		default.Zed_Value[21].ZedPath = "ZedternalReborn.WMPawn_ZedStalker_Omega";
		default.Zed_Value[21].Value = 25;
		default.Zed_Value[21].ValuePerExtraPlayer = 0;
		default.Zed_Value[22].ZedPath = "KFGameContent.KFPawn_ZedBloat";
		default.Zed_Value[22].Value = 26;
		default.Zed_Value[22].ValuePerExtraPlayer = 2;
		default.Zed_Value[23].ZedPath = "KFGameContent.KFPawn_ZedHusk";
		default.Zed_Value[23].Value = 36;
		default.Zed_Value[23].ValuePerExtraPlayer = 2;
		default.Zed_Value[24].ZedPath = "ZedternalReborn.WMPawn_ZedHusk_NoDAR";
		default.Zed_Value[24].Value = 36;
		default.Zed_Value[24].ValuePerExtraPlayer = 2;
		default.Zed_Value[25].ZedPath = "ZedternalReborn.WMPawn_ZedHusk_Tiny";
		default.Zed_Value[25].Value = 32;
		default.Zed_Value[25].ValuePerExtraPlayer = 1;
		default.Zed_Value[26].ZedPath = "ZedternalReborn.WMPawn_ZedHusk_Omega";
		default.Zed_Value[26].Value = 72;
		default.Zed_Value[26].ValuePerExtraPlayer = 2;
		default.Zed_Value[27].ZedPath = "KFGameContent.KFPawn_ZedSiren";
		default.Zed_Value[27].Value = 28;
		default.Zed_Value[27].ValuePerExtraPlayer = 0;
		default.Zed_Value[28].ZedPath = "ZedternalReborn.WMPawn_ZedSiren_Omega";
		default.Zed_Value[28].Value = 52;
		default.Zed_Value[28].ValuePerExtraPlayer = 2;
		default.Zed_Value[29].ZedPath = "KFGameContent.KFPawn_ZedDAR_Rocket";
		default.Zed_Value[29].Value = 36;
		default.Zed_Value[29].ValuePerExtraPlayer = 2;
		default.Zed_Value[30].ZedPath = "KFGameContent.KFPawn_ZedDAR_Laser";
		default.Zed_Value[30].Value = 36;
		default.Zed_Value[30].ValuePerExtraPlayer = 2;
		default.Zed_Value[31].ZedPath = "KFGameContent.KFPawn_ZedDAR_EMP";
		default.Zed_Value[31].Value = 36;
		default.Zed_Value[31].ValuePerExtraPlayer = 2;
		default.Zed_Value[32].ZedPath = "ZedternalReborn.WMPawn_ZedScrake_Tiny";
		default.Zed_Value[32].Value = 128;
		default.Zed_Value[32].ValuePerExtraPlayer = 16;
		default.Zed_Value[33].ZedPath = "KFGameContent.KFPawn_ZedScrake";
		default.Zed_Value[33].Value = 96;
		default.Zed_Value[33].ValuePerExtraPlayer = 16;
		default.Zed_Value[34].ZedPath = "ZedternalReborn.WMPawn_ZedScrake_Omega";
		default.Zed_Value[34].Value = 360;
		default.Zed_Value[34].ValuePerExtraPlayer = 64;
		default.Zed_Value[35].ZedPath = "KFGameContent.KFPawn_ZedFleshpoundMini";
		default.Zed_Value[35].Value = 78;
		default.Zed_Value[35].ValuePerExtraPlayer = 6;
		default.Zed_Value[36].ZedPath = "KFGameContent.KFPawn_ZedFleshpound";
		default.Zed_Value[36].Value = 280;
		default.Zed_Value[36].ValuePerExtraPlayer = 32;
		default.Zed_Value[37].ZedPath = "ZedternalReborn.WMPawn_ZedFleshpound_Omega";
		default.Zed_Value[37].Value = 485;
		default.Zed_Value[37].ValuePerExtraPlayer = 64;
		default.Zed_Value[38].ZedPath = "ZedternalReborn.WMPawn_ZedFleshpoundKing";
		default.Zed_Value[38].Value = 9000;
		default.Zed_Value[38].ValuePerExtraPlayer = 600;
		default.Zed_Value[39].ZedPath = "ZedternalReborn.WMPawn_ZedPatriarch";
		default.Zed_Value[39].Value = 6000;
		default.Zed_Value[39].ValuePerExtraPlayer = 600;
		default.Zed_Value[40].ZedPath = "ZedternalReborn.WMPawn_ZedMatriarch";
		default.Zed_Value[40].Value = 9000;
		default.Zed_Value[40].ValuePerExtraPlayer = 600;
		default.Zed_Value[41].ZedPath = "ZedternalReborn.WMPawn_ZedHans";
		default.Zed_Value[41].Value = 12000;
		default.Zed_Value[41].ValuePerExtraPlayer = 600;
		default.Zed_Value[42].ZedPath = "ZedternalReborn.WMPawn_ZedBloatKing";
		default.Zed_Value[42].Value = 6000;
		default.Zed_Value[42].ValuePerExtraPlayer = 600;
		// END TEMPERED INI DEFAULTS
		default.MODEVERSION = class'ZedternalReborn.Config_Base'.const.CurrentVersion;
		static.StaticSaveConfig();
	}
}

static function CheckBasicConfigValues()
{
	local int i;

	for (i = 0; i < default.Zed_Value.Length; ++i)
	{
		if (default.Zed_Value[i].Value < 1)
		{
			LogBadConfigMessage("Zed_Value - Line" @ string(i + 1) @ "- Value",
				string(default.Zed_Value[i].Value),
				"1", "1 point", "value >= 1");
			default.Zed_Value[i].Value = 1;
		}

		if (default.Zed_Value[i].ValuePerExtraPlayer < 0)
		{
			LogBadConfigMessage("Zed_Value - Line" @ string(i + 1) @ "- ValuePerExtraPlayer",
				string(default.Zed_Value[i].ValuePerExtraPlayer),
				"0", "0 points, no additional points for extra players", "value >= 0");
			default.Zed_Value[i].ValuePerExtraPlayer = 0;
		}
	}
}

static function LoadConfigObjects(out array<S_ZedValue> ValidZedValues, out array< class<KFPawn_Monster> > ZedObjects)
{
	local int i, Ins;
	local class<KFPawn_Monster> Obj;

	ValidZedValues.Length = 0;
	ZedObjects.Length = 0;

	for (i = 0; i < default.Zed_Value.Length; ++i)
	{
		Obj = class<KFPawn_Monster>(DynamicLoadObject(default.Zed_Value[i].ZedPath, class'Class', True));
		if (Obj == None)
		{
			LogBadLoadObjectConfigMessage("Zed_Value", i + 1, default.Zed_Value[i].ZedPath);
		}
		else
		{
			if (class'ZedternalReborn.WMBinaryOps'.static.BinarySearchUnique(ZedObjects, PathName(Obj), Ins))
			{
				ValidZedValues.InsertItem(Ins, default.Zed_Value[i]);
				ZedObjects.InsertItem(Ins, Obj);
			}
			else
			{
				`log("ZR Config: Zed_Value - Line" @string(i + 1) @"- Only one value may be defined for a specific Zed"
					@"at a time. Skipping value line temporarily.");
			}
		}
	}
}

defaultproperties
{
	Name="Default__Config_ZedValue"
}
