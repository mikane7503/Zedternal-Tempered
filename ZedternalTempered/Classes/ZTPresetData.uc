// =============================================================================
// ZTPresetData - Preset configuration system for GeForce Now / ephemeral sessions
// Usage: mutate zupreset 0|1|2
//   0 = Default ZR (10 vanilla perks, 100 skills)
//   1 = ZU Full (all perks + skills, minus Artificer)
//   2 = ZU No Symbiotes (Full minus Symbiote family)
// =============================================================================
class ZTPresetData extends Object;

// =============================================================================
// Public API
// =============================================================================
static function bool ApplyPreset(int PresetIndex, WorldInfo WI)
{
	switch (PresetIndex)
	{
		case 0:
			ApplyPreset_DefaultZR();
			SaveAndTravel(WI);
			return True;
		case 1:
			ApplyPreset_ZUFull();
			SaveAndTravel(WI);
			return True;
		case 2:
			ApplyPreset_ZUNoSymbiotes();
			SaveAndTravel(WI);
			return True;
		default:
			return False;
	}
}

static function string GetPresetName(int PresetIndex)
{
	switch (PresetIndex)
	{
		case 0:  return "Default ZR";
		case 1:  return "ZU Full";
		case 2:  return "ZU No Symbiotes";
		default: return "Unknown";
	}
}

static function int GetPresetCount()
{
	return 3;
}

// =============================================================================
// Preset Compositions
// =============================================================================
static function ApplyPreset_DefaultZR()
{
	ClearArrays();
	AddVanillaPerks();
	AddVanillaSkills();
}

static function ApplyPreset_ZUFull()
{
	ClearArrays();
	AddVanillaPerks();
	AddVanillaSkills();
	AddDKCorePerks();
	AddDKCoreSkills();
	AddDKSymbiotePerks();
	AddDKSymbioteSkills();
}

static function ApplyPreset_ZUNoSymbiotes()
{
	ClearArrays();
	AddVanillaPerks();
	AddVanillaSkills();
	AddDKCorePerks();
	AddDKCoreSkills();
}

// =============================================================================
// Save and Travel
// =============================================================================
static function SaveAndTravel(WorldInfo WI)
{
	class'ZedternalReborn.Config_PerkUpgrade'.default.MODEVERSION = class'ZedternalReborn.Config_Base'.const.CurrentVersion;
	class'ZedternalReborn.Config_SkillUpgrade'.default.MODEVERSION = class'ZedternalReborn.Config_Base'.const.CurrentVersion;
	class'ZedternalReborn.Config_PerkUpgrade'.static.StaticSaveConfig();
	class'ZedternalReborn.Config_SkillUpgrade'.static.StaticSaveConfig();
	WI.ServerTravel(WI.GetMapName(True) $ "?game=" $ PathName(WI.Game.Class), False);
}

// =============================================================================
// Array Management
// =============================================================================
static function ClearArrays()
{
	class'ZedternalReborn.Config_PerkUpgrade'.default.PerkUpgrade_Upgrade.Length = 0;
	class'ZedternalReborn.Config_SkillUpgrade'.default.SkillUpgrade_Upgrade.Length = 0;
}

static function AddPerk(string PerkPath, bool bIsStatic)
{
	local int i;
	i = class'ZedternalReborn.Config_PerkUpgrade'.default.PerkUpgrade_Upgrade.Length;
	class'ZedternalReborn.Config_PerkUpgrade'.default.PerkUpgrade_Upgrade.Length = i + 1;
	class'ZedternalReborn.Config_PerkUpgrade'.default.PerkUpgrade_Upgrade[i].PerkPath = PerkPath;
	class'ZedternalReborn.Config_PerkUpgrade'.default.PerkUpgrade_Upgrade[i].bIsStatic = bIsStatic;
}

static function AddSkill(string PerkPath, string SkillPath)
{
	local int i;
	i = class'ZedternalReborn.Config_SkillUpgrade'.default.SkillUpgrade_Upgrade.Length;
	class'ZedternalReborn.Config_SkillUpgrade'.default.SkillUpgrade_Upgrade.Length = i + 1;
	class'ZedternalReborn.Config_SkillUpgrade'.default.SkillUpgrade_Upgrade[i].PerkPath = PerkPath;
	class'ZedternalReborn.Config_SkillUpgrade'.default.SkillUpgrade_Upgrade[i].SkillPath = SkillPath;
}

// =============================================================================
// Vanilla ZR Perks
// =============================================================================
static function AddVanillaPerks()
{
	AddPerk("ZedternalReborn.WMUpgrade_Perk_Berserker", False);
	AddPerk("ZedternalReborn.WMUpgrade_Perk_Commando", False);
	AddPerk("ZedternalReborn.WMUpgrade_Perk_Demolitionist", False);
	AddPerk("ZedternalReborn.WMUpgrade_Perk_FieldMedic", False);
	AddPerk("ZedternalReborn.WMUpgrade_Perk_Firebug", False);
	AddPerk("ZedternalReborn.WMUpgrade_Perk_Gunslinger", False);
	AddPerk("ZedternalReborn.WMUpgrade_Perk_Sharpshooter", False);
	AddPerk("ZedternalReborn.WMUpgrade_Perk_Support", False);
	AddPerk("ZedternalReborn.WMUpgrade_Perk_SWAT", False);
	AddPerk("ZedternalReborn.WMUpgrade_Perk_Survivalist", False);
}

// =============================================================================
// Vanilla ZR Skills
// =============================================================================
static function AddVanillaSkills()
{
	// WMUpgrade_Perk_Berserker
	AddSkill("ZedternalReborn.WMUpgrade_Perk_Berserker", "ZedternalReborn.WMUpgrade_Skill_BerserkerRage");
	AddSkill("ZedternalReborn.WMUpgrade_Perk_Berserker", "ZedternalReborn.WMUpgrade_Skill_Brawler");
	AddSkill("ZedternalReborn.WMUpgrade_Perk_Berserker", "ZedternalReborn.WMUpgrade_Skill_Butcher");
	AddSkill("ZedternalReborn.WMUpgrade_Perk_Berserker", "ZedternalReborn.WMUpgrade_Skill_Dreadnaught");
	AddSkill("ZedternalReborn.WMUpgrade_Perk_Berserker", "ZedternalReborn.WMUpgrade_Skill_Massacre");
	AddSkill("ZedternalReborn.WMUpgrade_Perk_Berserker", "ZedternalReborn.WMUpgrade_Skill_Parry");
	AddSkill("ZedternalReborn.WMUpgrade_Perk_Berserker", "ZedternalReborn.WMUpgrade_Skill_Spartan");
	AddSkill("ZedternalReborn.WMUpgrade_Perk_Berserker", "ZedternalReborn.WMUpgrade_Skill_Tank");
	AddSkill("ZedternalReborn.WMUpgrade_Perk_Berserker", "ZedternalReborn.WMUpgrade_Skill_Vampire");
	AddSkill("ZedternalReborn.WMUpgrade_Perk_Berserker", "ZedternalReborn.WMUpgrade_Skill_Tempest");

	// WMUpgrade_Perk_Commando
	AddSkill("ZedternalReborn.WMUpgrade_Perk_Commando", "ZedternalReborn.WMUpgrade_Skill_CallOut");
	AddSkill("ZedternalReborn.WMUpgrade_Perk_Commando", "ZedternalReborn.WMUpgrade_Skill_Concentration");
	AddSkill("ZedternalReborn.WMUpgrade_Perk_Commando", "ZedternalReborn.WMUpgrade_Skill_Guerrilla");
	AddSkill("ZedternalReborn.WMUpgrade_Perk_Commando", "ZedternalReborn.WMUpgrade_Skill_GunMachine");
	AddSkill("ZedternalReborn.WMUpgrade_Perk_Commando", "ZedternalReborn.WMUpgrade_Skill_HighCapacityMags");
	AddSkill("ZedternalReborn.WMUpgrade_Perk_Commando", "ZedternalReborn.WMUpgrade_Skill_ImpactRounds");
	AddSkill("ZedternalReborn.WMUpgrade_Perk_Commando", "ZedternalReborn.WMUpgrade_Skill_Overload");
	AddSkill("ZedternalReborn.WMUpgrade_Perk_Commando", "ZedternalReborn.WMUpgrade_Skill_Supplier");
	AddSkill("ZedternalReborn.WMUpgrade_Perk_Commando", "ZedternalReborn.WMUpgrade_Skill_TacticalReload");
	AddSkill("ZedternalReborn.WMUpgrade_Perk_Commando", "ZedternalReborn.WMUpgrade_Skill_Tactician");

	// WMUpgrade_Perk_Demolitionist
	AddSkill("ZedternalReborn.WMUpgrade_Perk_Demolitionist", "ZedternalReborn.WMUpgrade_Skill_Bombardier");
	AddSkill("ZedternalReborn.WMUpgrade_Perk_Demolitionist", "ZedternalReborn.WMUpgrade_Skill_DestroyerOfWorlds");
	AddSkill("ZedternalReborn.WMUpgrade_Perk_Demolitionist", "ZedternalReborn.WMUpgrade_Skill_ExtraRounds");
	AddSkill("ZedternalReborn.WMUpgrade_Perk_Demolitionist", "ZedternalReborn.WMUpgrade_Skill_FrontLine");
	AddSkill("ZedternalReborn.WMUpgrade_Perk_Demolitionist", "ZedternalReborn.WMUpgrade_Skill_HighImpactRound");
	AddSkill("ZedternalReborn.WMUpgrade_Perk_Demolitionist", "ZedternalReborn.WMUpgrade_Skill_Kamikaze");
	AddSkill("ZedternalReborn.WMUpgrade_Perk_Demolitionist", "ZedternalReborn.WMUpgrade_Skill_MadBomber");
	AddSkill("ZedternalReborn.WMUpgrade_Perk_Demolitionist", "ZedternalReborn.WMUpgrade_Skill_ShockTrooper");
	AddSkill("ZedternalReborn.WMUpgrade_Perk_Demolitionist", "ZedternalReborn.WMUpgrade_Skill_SonicResistantRounds");
	AddSkill("ZedternalReborn.WMUpgrade_Perk_Demolitionist", "ZedternalReborn.WMUpgrade_Skill_QuickFuse");

	// WMUpgrade_Perk_FieldMedic
	AddSkill("ZedternalReborn.WMUpgrade_Perk_FieldMedic", "ZedternalReborn.WMUpgrade_Skill_AcidicRounds");
	AddSkill("ZedternalReborn.WMUpgrade_Perk_FieldMedic", "ZedternalReborn.WMUpgrade_Skill_AirborneAgent");
	AddSkill("ZedternalReborn.WMUpgrade_Perk_FieldMedic", "ZedternalReborn.WMUpgrade_Skill_BattleSurgeon");
	AddSkill("ZedternalReborn.WMUpgrade_Perk_FieldMedic", "ZedternalReborn.WMUpgrade_Skill_CoagulantBooster");
	AddSkill("ZedternalReborn.WMUpgrade_Perk_FieldMedic", "ZedternalReborn.WMUpgrade_Skill_CombatantDoctor");
	AddSkill("ZedternalReborn.WMUpgrade_Perk_FieldMedic", "ZedternalReborn.WMUpgrade_Skill_Hemoglobin");
	AddSkill("ZedternalReborn.WMUpgrade_Perk_FieldMedic", "ZedternalReborn.WMUpgrade_Skill_Safeguard");
	AddSkill("ZedternalReborn.WMUpgrade_Perk_FieldMedic", "ZedternalReborn.WMUpgrade_Skill_SymbioticHealth");
	AddSkill("ZedternalReborn.WMUpgrade_Perk_FieldMedic", "ZedternalReborn.WMUpgrade_Skill_Zedatif");
	AddSkill("ZedternalReborn.WMUpgrade_Perk_FieldMedic", "ZedternalReborn.WMUpgrade_Skill_FocusInjection");

	// WMUpgrade_Perk_Firebug
	AddSkill("ZedternalReborn.WMUpgrade_Perk_Firebug", "ZedternalReborn.WMUpgrade_Skill_Barbecue");
	AddSkill("ZedternalReborn.WMUpgrade_Perk_Firebug", "ZedternalReborn.WMUpgrade_Skill_BringTheHeat");
	AddSkill("ZedternalReborn.WMUpgrade_Perk_Firebug", "ZedternalReborn.WMUpgrade_Skill_Combustion");
	AddSkill("ZedternalReborn.WMUpgrade_Perk_Firebug", "ZedternalReborn.WMUpgrade_Skill_Firestorm");
	AddSkill("ZedternalReborn.WMUpgrade_Perk_Firebug", "ZedternalReborn.WMUpgrade_Skill_HeatWaves");
	AddSkill("ZedternalReborn.WMUpgrade_Perk_Firebug", "ZedternalReborn.WMUpgrade_Skill_Napalm");
	AddSkill("ZedternalReborn.WMUpgrade_Perk_Firebug", "ZedternalReborn.WMUpgrade_Skill_Pyromaniac");
	AddSkill("ZedternalReborn.WMUpgrade_Perk_Firebug", "ZedternalReborn.WMUpgrade_Skill_Resistance");
	AddSkill("ZedternalReborn.WMUpgrade_Perk_Firebug", "ZedternalReborn.WMUpgrade_Skill_ZedPlosion");
	AddSkill("ZedternalReborn.WMUpgrade_Perk_Firebug", "ZedternalReborn.WMUpgrade_Skill_HotPepper");

	// WMUpgrade_Perk_Gunslinger
	AddSkill("ZedternalReborn.WMUpgrade_Perk_Gunslinger", "ZedternalReborn.WMUpgrade_Skill_BoneBreaker");
	AddSkill("ZedternalReborn.WMUpgrade_Perk_Gunslinger", "ZedternalReborn.WMUpgrade_Skill_FirstBlood");
	AddSkill("ZedternalReborn.WMUpgrade_Perk_Gunslinger", "ZedternalReborn.WMUpgrade_Skill_Marksman");
	AddSkill("ZedternalReborn.WMUpgrade_Perk_Gunslinger", "ZedternalReborn.WMUpgrade_Skill_Penetrator");
	AddSkill("ZedternalReborn.WMUpgrade_Perk_Gunslinger", "ZedternalReborn.WMUpgrade_Skill_QuickDraw");
	AddSkill("ZedternalReborn.WMUpgrade_Perk_Gunslinger", "ZedternalReborn.WMUpgrade_Skill_RapidAssault");
	AddSkill("ZedternalReborn.WMUpgrade_Perk_Gunslinger", "ZedternalReborn.WMUpgrade_Skill_RankThemUp");
	AddSkill("ZedternalReborn.WMUpgrade_Perk_Gunslinger", "ZedternalReborn.WMUpgrade_Skill_ShootAndRun");
	AddSkill("ZedternalReborn.WMUpgrade_Perk_Gunslinger", "ZedternalReborn.WMUpgrade_Skill_Skirmisher");
	AddSkill("ZedternalReborn.WMUpgrade_Perk_Gunslinger", "ZedternalReborn.WMUpgrade_Skill_Speedloader");

	// WMUpgrade_Perk_Sharpshooter
	AddSkill("ZedternalReborn.WMUpgrade_Perk_Sharpshooter", "ZedternalReborn.WMUpgrade_Skill_Assassin");
	AddSkill("ZedternalReborn.WMUpgrade_Perk_Sharpshooter", "ZedternalReborn.WMUpgrade_Skill_Barrage");
	AddSkill("ZedternalReborn.WMUpgrade_Perk_Sharpshooter", "ZedternalReborn.WMUpgrade_Skill_DeadEye");
	AddSkill("ZedternalReborn.WMUpgrade_Perk_Sharpshooter", "ZedternalReborn.WMUpgrade_Skill_Hunter");
	AddSkill("ZedternalReborn.WMUpgrade_Perk_Sharpshooter", "ZedternalReborn.WMUpgrade_Skill_Pressure");
	AddSkill("ZedternalReborn.WMUpgrade_Perk_Sharpshooter", "ZedternalReborn.WMUpgrade_Skill_Ranger");
	AddSkill("ZedternalReborn.WMUpgrade_Perk_Sharpshooter", "ZedternalReborn.WMUpgrade_Skill_Ruthless");
	AddSkill("ZedternalReborn.WMUpgrade_Perk_Sharpshooter", "ZedternalReborn.WMUpgrade_Skill_Sniper");
	AddSkill("ZedternalReborn.WMUpgrade_Perk_Sharpshooter", "ZedternalReborn.WMUpgrade_Skill_Stability");
	AddSkill("ZedternalReborn.WMUpgrade_Perk_Sharpshooter", "ZedternalReborn.WMUpgrade_Skill_Steady");

	// WMUpgrade_Perk_Support
	AddSkill("ZedternalReborn.WMUpgrade_Perk_Support", "ZedternalReborn.WMUpgrade_Skill_Destruction");
	AddSkill("ZedternalReborn.WMUpgrade_Perk_Support", "ZedternalReborn.WMUpgrade_Skill_DoorTraps");
	AddSkill("ZedternalReborn.WMUpgrade_Perk_Support", "ZedternalReborn.WMUpgrade_Skill_Fortitude");
	AddSkill("ZedternalReborn.WMUpgrade_Perk_Support", "ZedternalReborn.WMUpgrade_Skill_HeavyArmor");
	AddSkill("ZedternalReborn.WMUpgrade_Perk_Support", "ZedternalReborn.WMUpgrade_Skill_HighCapacityMagsB");
	AddSkill("ZedternalReborn.WMUpgrade_Perk_Support", "ZedternalReborn.WMUpgrade_Skill_MagicBullet");
	AddSkill("ZedternalReborn.WMUpgrade_Perk_Support", "ZedternalReborn.WMUpgrade_Skill_ColdRiposte");
	AddSkill("ZedternalReborn.WMUpgrade_Perk_Support", "ZedternalReborn.WMUpgrade_Skill_Salvo");
	AddSkill("ZedternalReborn.WMUpgrade_Perk_Support", "ZedternalReborn.WMUpgrade_Skill_TightChoke");
	AddSkill("ZedternalReborn.WMUpgrade_Perk_Support", "ZedternalReborn.WMUpgrade_Skill_Cripple");

	// WMUpgrade_Perk_SWAT
	AddSkill("ZedternalReborn.WMUpgrade_Perk_SWAT", "ZedternalReborn.WMUpgrade_Skill_AssaultArmor");
	AddSkill("ZedternalReborn.WMUpgrade_Perk_SWAT", "ZedternalReborn.WMUpgrade_Skill_ConcussionRounds");
	AddSkill("ZedternalReborn.WMUpgrade_Perk_SWAT", "ZedternalReborn.WMUpgrade_Skill_Velocity");
	AddSkill("ZedternalReborn.WMUpgrade_Perk_SWAT", "ZedternalReborn.WMUpgrade_Skill_HighCapacityMags");
	AddSkill("ZedternalReborn.WMUpgrade_Perk_SWAT", "ZedternalReborn.WMUpgrade_Skill_RiotShield");
	AddSkill("ZedternalReborn.WMUpgrade_Perk_SWAT", "ZedternalReborn.WMUpgrade_Skill_ShootAndRun");
	AddSkill("ZedternalReborn.WMUpgrade_Perk_SWAT", "ZedternalReborn.WMUpgrade_Skill_SpecialUnit");
	AddSkill("ZedternalReborn.WMUpgrade_Perk_SWAT", "ZedternalReborn.WMUpgrade_Skill_SuppressionRounds");
	AddSkill("ZedternalReborn.WMUpgrade_Perk_SWAT", "ZedternalReborn.WMUpgrade_Skill_TacticalMovement");
	AddSkill("ZedternalReborn.WMUpgrade_Perk_SWAT", "ZedternalReborn.WMUpgrade_Skill_WhirlwindOfLead");

	// WMUpgrade_Perk_Survivalist
	AddSkill("ZedternalReborn.WMUpgrade_Perk_Survivalist", "ZedternalReborn.WMUpgrade_Skill_AmmoVest");
	AddSkill("ZedternalReborn.WMUpgrade_Perk_Survivalist", "ZedternalReborn.WMUpgrade_Skill_Emergency");
	AddSkill("ZedternalReborn.WMUpgrade_Perk_Survivalist", "ZedternalReborn.WMUpgrade_Skill_Empathy");
	AddSkill("ZedternalReborn.WMUpgrade_Perk_Survivalist", "ZedternalReborn.WMUpgrade_Skill_Fallback");
	AddSkill("ZedternalReborn.WMUpgrade_Perk_Survivalist", "ZedternalReborn.WMUpgrade_Skill_MedicalInjection");
	AddSkill("ZedternalReborn.WMUpgrade_Perk_Survivalist", "ZedternalReborn.WMUpgrade_Skill_Scrapper");
	AddSkill("ZedternalReborn.WMUpgrade_Perk_Survivalist", "ZedternalReborn.WMUpgrade_Skill_Strength");
	AddSkill("ZedternalReborn.WMUpgrade_Perk_Survivalist", "ZedternalReborn.WMUpgrade_Skill_TacticalArmor");
	AddSkill("ZedternalReborn.WMUpgrade_Perk_Survivalist", "ZedternalReborn.WMUpgrade_Skill_Watcher");
	AddSkill("ZedternalReborn.WMUpgrade_Perk_Survivalist", "ZedternalReborn.WMUpgrade_Skill_AmmoPickup");

}

// =============================================================================
// DK Core Perks (non-Symbiote)
// =============================================================================
static function AddDKCorePerks()
{
	AddPerk("ZedternalTempered.ZTUpgrade_Perk_Archangel", False);
	AddPerk("ZedternalTempered.ZTUpgrade_Perk_Bulwark", False);
	AddPerk("ZedternalTempered.ZTUpgrade_Perk_Cryophilite", False);
	AddPerk("ZedternalTempered.ZTUpgrade_Perk_Daredevil", False);
	AddPerk("ZedternalTempered.ZTUpgrade_Perk_ForgeWarden", False);
	AddPerk("ZedternalTempered.ZTUpgrade_Perk_Frost", False);
	AddPerk("ZedternalTempered.ZTUpgrade_Perk_Gambler", False);
	AddPerk("ZedternalTempered.ZTUpgrade_Perk_Haunted", False);
	AddPerk("ZedternalTempered.ZTUpgrade_Perk_Headhunter", False);
	AddPerk("ZedternalTempered.ZTUpgrade_Perk_Hydra", False);
	AddPerk("ZedternalTempered.ZTUpgrade_Perk_Hollow", False);
	AddPerk("ZedternalTempered.ZTUpgrade_Perk_Maniac", False);
	AddPerk("ZedternalTempered.ZTUpgrade_Perk_Medusa", False);
	AddPerk("ZedternalTempered.ZTUpgrade_Perk_Metronome", False);
	AddPerk("ZedternalTempered.ZTUpgrade_Perk_Pyrokinetic", False);
	AddPerk("ZedternalTempered.ZTUpgrade_Perk_Diablo", False);
	AddPerk("ZedternalTempered.ZTUpgrade_Perk_Reaper", False);
	AddPerk("ZedternalTempered.ZTUpgrade_Perk_Scavenger", False);
	AddPerk("ZedternalTempered.ZTUpgrade_Perk_Shapeshifter", False);
	AddPerk("ZedternalTempered.ZTUpgrade_Perk_SpecialAgent", False);
	AddPerk("ZedternalTempered.ZTUpgrade_Perk_Taskmaster", False);
	AddPerk("ZedternalTempered.ZTUpgrade_Perk_TimeTraveler", False);
	AddPerk("ZedternalTempered.ZTUpgrade_Perk_Tycoon", False);
	AddPerk("ZedternalTempered.ZTUpgrade_Perk_Venomancer", False);
	AddPerk("ZedternalTempered.ZTUpgrade_Perk_Voodoo", False);
	AddPerk("ZedternalTempered.ZTUpgrade_Perk_Warlord", False);
	AddPerk("ZedternalTempered.ZTUpgrade_Perk_Wendigo", False);
}

// =============================================================================
// DK Core Skills (non-Symbiote)
// =============================================================================
static function AddDKCoreSkills()
{
	// ZTUpgrade_Perk_Archangel
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Archangel", "ZedternalTempered.ZTUpgrade_Skill_CelestialVitality");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Archangel", "ZedternalTempered.ZTUpgrade_Skill_DivineFortitude");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Archangel", "ZedternalTempered.ZTUpgrade_Skill_HolyResilience");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Archangel", "ZedternalTempered.ZTUpgrade_Skill_MartyrBlessing");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Archangel", "ZedternalTempered.ZTUpgrade_Skill_OverflowingGrace");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Archangel", "ZedternalTempered.ZTUpgrade_Skill_PhoenixPrayer");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Archangel", "ZedternalTempered.ZTUpgrade_Skill_SanctifiedRounds");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Archangel", "ZedternalTempered.ZTUpgrade_Skill_TriageExpert");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Archangel", "ZedternalTempered.ZTUpgrade_Skill_UnwaveringFaith");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Archangel", "ZedternalTempered.ZTUpgrade_Skill_WingsOfMercy");

	// ZTUpgrade_Perk_Bulwark
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Bulwark", "ZedternalTempered.ZTUpgrade_Skill_Aware");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Bulwark", "ZedternalTempered.ZTUpgrade_Skill_BugFixing");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Bulwark", "ZedternalTempered.ZTUpgrade_Skill_Deflector");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Bulwark", "ZedternalTempered.ZTUpgrade_Skill_FLAK");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Bulwark", "ZedternalTempered.ZTUpgrade_Skill_Fencer");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Bulwark", "ZedternalTempered.ZTUpgrade_Skill_Indifferent");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Bulwark", "ZedternalTempered.ZTUpgrade_Skill_NoiseCancelling");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Bulwark", "ZedternalTempered.ZTUpgrade_Skill_SteelSkin");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Bulwark", "ZedternalTempered.ZTUpgrade_Skill_Stoic");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Bulwark", "ZedternalTempered.ZTUpgrade_Skill_ThickSkin");

	// ZTUpgrade_Perk_Cryophilite
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Cryophilite", "ZedternalTempered.ZTUpgrade_Skill_AvalancheProtocol");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Cryophilite", "ZedternalTempered.ZTUpgrade_Skill_BitterChill");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Cryophilite", "ZedternalTempered.ZTUpgrade_Skill_CrystalClarity");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Cryophilite", "ZedternalTempered.ZTUpgrade_Skill_Fimbulwinter");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Cryophilite", "ZedternalTempered.ZTUpgrade_Skill_FrostbiteArrows");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Cryophilite", "ZedternalTempered.ZTUpgrade_Skill_GlacialEndurance");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Cryophilite", "ZedternalTempered.ZTUpgrade_Skill_IceArmor");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Cryophilite", "ZedternalTempered.ZTUpgrade_Skill_Permafrost");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Cryophilite", "ZedternalTempered.ZTUpgrade_Skill_QuiverMastery");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Cryophilite", "ZedternalTempered.ZTUpgrade_Skill_WintersSwiftness");

	// ZTUpgrade_Perk_Daredevil
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Daredevil", "ZedternalTempered.ZTUpgrade_Skill_CloseCall");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Daredevil", "ZedternalTempered.ZTUpgrade_Skill_DeadeyeMomentum");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Daredevil", "ZedternalTempered.ZTUpgrade_Skill_FullMetalJacket");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Daredevil", "ZedternalTempered.ZTUpgrade_Skill_GlassCannon");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Daredevil", "ZedternalTempered.ZTUpgrade_Skill_ImpenetrableSkin");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Daredevil", "ZedternalTempered.ZTUpgrade_Skill_Primed");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Daredevil", "ZedternalTempered.ZTUpgrade_Skill_Resilience_Deluxe");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Daredevil", "ZedternalTempered.ZTUpgrade_Skill_Resilience_Deluxe1");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Daredevil", "ZedternalTempered.ZTUpgrade_Skill_ShowOff");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Daredevil", "ZedternalTempered.ZTUpgrade_Skill_TrueShot");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Daredevil", "ZedternalTempered.ZTUpgrade_Skill_TrueShot_Deluxe");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Daredevil", "ZedternalTempered.ZTUpgrade_Skill_Untouchable");

	// ZTUpgrade_Perk_ForgeWarden
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_ForgeWarden", "ZedternalTempered.ZTUpgrade_Skill_Armory");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_ForgeWarden", "ZedternalTempered.ZTUpgrade_Skill_Bellows");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_ForgeWarden", "ZedternalTempered.ZTUpgrade_Skill_ChainReaction");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_ForgeWarden", "ZedternalTempered.ZTUpgrade_Skill_Crucible");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_ForgeWarden", "ZedternalTempered.ZTUpgrade_Skill_EmberHarvest");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_ForgeWarden", "ZedternalTempered.ZTUpgrade_Skill_EternalForge");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_ForgeWarden", "ZedternalTempered.ZTUpgrade_Skill_InfernoRounds");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_ForgeWarden", "ZedternalTempered.ZTUpgrade_Skill_Ironclad");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_ForgeWarden", "ZedternalTempered.ZTUpgrade_Skill_Pyroclasm");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_ForgeWarden", "ZedternalTempered.ZTUpgrade_Skill_SlagArmor");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_ForgeWarden", "ZedternalTempered.ZTUpgrade_Skill_TemperedSteel");

	// ZTUpgrade_Perk_Frost
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Frost", "ZedternalTempered.ZTUpgrade_Skill_Absorb");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Frost", "ZedternalTempered.ZTUpgrade_Skill_AspectOfYmir");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Frost", "ZedternalTempered.ZTUpgrade_Skill_BlackIce");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Frost", "ZedternalTempered.ZTUpgrade_Skill_Blizzard");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Frost", "ZedternalTempered.ZTUpgrade_Skill_Cryosynthesis");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Frost", "ZedternalTempered.ZTUpgrade_Skill_FrozenHeart");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Frost", "ZedternalTempered.ZTUpgrade_Skill_Giantsbane");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Frost", "ZedternalTempered.ZTUpgrade_Skill_HarshConditions");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Frost", "ZedternalTempered.ZTUpgrade_Skill_Hypothermia");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Frost", "ZedternalTempered.ZTUpgrade_Skill_ImmovableObject");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Frost", "ZedternalTempered.ZTUpgrade_Skill_RegenerativeRounds");

	// ZTUpgrade_Perk_Gambler
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Gambler", "ZedternalTempered.ZTUpgrade_Skill_ArmoredUp");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Gambler", "ZedternalTempered.ZTUpgrade_Skill_DoubleDown");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Gambler", "ZedternalTempered.ZTUpgrade_Skill_FieryGambit");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Gambler", "ZedternalTempered.ZTUpgrade_Skill_GrenadeConjurer");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Gambler", "ZedternalTempered.ZTUpgrade_Skill_IcyGambit");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Gambler", "ZedternalTempered.ZTUpgrade_Skill_Jackpot");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Gambler", "ZedternalTempered.ZTUpgrade_Skill_LuckyPop");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Gambler", "ZedternalTempered.ZTUpgrade_Skill_NarrowEscape");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Gambler", "ZedternalTempered.ZTUpgrade_Skill_StrokeOfLuck");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Gambler", "ZedternalTempered.ZTUpgrade_Skill_ToxicGambit");

	// ZTUpgrade_Perk_Haunted (no skills)
	// ZTUpgrade_Perk_Headhunter
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Headhunter", "ZedternalTempered.ZTUpgrade_Skill_AmishParadise");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Headhunter", "ZedternalTempered.ZTUpgrade_Skill_CeaseAndDesist");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Headhunter", "ZedternalTempered.ZTUpgrade_Skill_Clotbuster");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Headhunter", "ZedternalTempered.ZTUpgrade_Skill_Dietician");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Headhunter", "ZedternalTempered.ZTUpgrade_Skill_Feminist");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Headhunter", "ZedternalTempered.ZTUpgrade_Skill_Firefighter");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Headhunter", "ZedternalTempered.ZTUpgrade_Skill_GorefastSlayer");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Headhunter", "ZedternalTempered.ZTUpgrade_Skill_Kingslayer");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Headhunter", "ZedternalTempered.ZTUpgrade_Skill_NoCloneZone");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Headhunter", "ZedternalTempered.ZTUpgrade_Skill_NoWomanNoCry");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Headhunter", "ZedternalTempered.ZTUpgrade_Skill_NoiseComplaint");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Headhunter", "ZedternalTempered.ZTUpgrade_Skill_SomeoneYourOwnSize");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Headhunter", "ZedternalTempered.ZTUpgrade_Skill_SupersizeMe");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Headhunter", "ZedternalTempered.ZTUpgrade_Skill_TexasChainsawMassacre");

	// ZTUpgrade_Perk_Hydra
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Hydra", "ZedternalTempered.ZTUpgrade_Skill_ApexPredator");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Hydra", "ZedternalTempered.ZTUpgrade_Skill_Bloodthirst");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Hydra", "ZedternalTempered.ZTUpgrade_Skill_CascadingMassacre");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Hydra", "ZedternalTempered.ZTUpgrade_Skill_EndlessRampage");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Hydra", "ZedternalTempered.ZTUpgrade_Skill_HuntDown");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Hydra", "ZedternalTempered.ZTUpgrade_Skill_LernaeanImmortality");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Hydra", "ZedternalTempered.ZTUpgrade_Skill_Overkill");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Hydra", "ZedternalTempered.ZTUpgrade_Skill_ReflectedFury");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Hydra", "ZedternalTempered.ZTUpgrade_Skill_SymphonyOfSlaughter");

	// ZTUpgrade_Perk_Maniac
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Maniac", "ZedternalTempered.ZTUpgrade_Skill_ArmedAndDangerous");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Maniac", "ZedternalTempered.ZTUpgrade_Skill_Arsonist");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Maniac", "ZedternalTempered.ZTUpgrade_Skill_BargainHunter");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Maniac", "ZedternalTempered.ZTUpgrade_Skill_Dauntless");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Maniac", "ZedternalTempered.ZTUpgrade_Skill_Elmo");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Maniac", "ZedternalTempered.ZTUpgrade_Skill_Fanatic");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Maniac", "ZedternalTempered.ZTUpgrade_Skill_MadBomber");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Maniac", "ZedternalTempered.ZTUpgrade_Skill_SafetyFirst");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Maniac", "ZedternalTempered.ZTUpgrade_Skill_SlowCooker");

	// ZTUpgrade_Perk_Medusa
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Medusa", "ZedternalTempered.ZTUpgrade_Skill_AthenasWrath");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Medusa", "ZedternalTempered.ZTUpgrade_Skill_CurseOfStone");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Medusa", "ZedternalTempered.ZTUpgrade_Skill_GorgonsCurse");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Medusa", "ZedternalTempered.ZTUpgrade_Skill_GorgonsLegacy");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Medusa", "ZedternalTempered.ZTUpgrade_Skill_Metamorphosis");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Medusa", "ZedternalTempered.ZTUpgrade_Skill_NestOfVipers");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Medusa", "ZedternalTempered.ZTUpgrade_Skill_PetrifyingPresence");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Medusa", "ZedternalTempered.ZTUpgrade_Skill_SerpentineReflexes");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Medusa", "ZedternalTempered.ZTUpgrade_Skill_ShedSkin");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Medusa", "ZedternalTempered.ZTUpgrade_Skill_SnakesCoil");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Medusa", "ZedternalTempered.ZTUpgrade_Skill_ToxicAura");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Medusa", "ZedternalTempered.ZTUpgrade_Skill_ToxicImmunity");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Medusa", "ZedternalTempered.ZTUpgrade_Skill_VenomExtraction");

	// ZTUpgrade_Perk_Pyrokinetic
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Pyrokinetic", "ZedternalTempered.ZTUpgrade_Skill_Backdraft");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Pyrokinetic", "ZedternalTempered.ZTUpgrade_Skill_Blaze");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Pyrokinetic", "ZedternalTempered.ZTUpgrade_Skill_ChosenOfTheSun");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Pyrokinetic", "ZedternalTempered.ZTUpgrade_Skill_ConsumingFlame");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Pyrokinetic", "ZedternalTempered.ZTUpgrade_Skill_Flashpoint");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Pyrokinetic", "ZedternalTempered.ZTUpgrade_Skill_Forger");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Pyrokinetic", "ZedternalTempered.ZTUpgrade_Skill_Heatstroke");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Pyrokinetic", "ZedternalTempered.ZTUpgrade_Skill_SearingGaze");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Pyrokinetic", "ZedternalTempered.ZTUpgrade_Skill_TrialByFire");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Pyrokinetic", "ZedternalTempered.ZTUpgrade_Skill_Wildfire");

	// ZTUpgrade_Perk_Reaper
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Reaper", "ZedternalTempered.ZTUpgrade_Skill_DanceOfDeath");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Reaper", "ZedternalTempered.ZTUpgrade_Skill_DeathlessFury");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Reaper", "ZedternalTempered.ZTUpgrade_Skill_DeathSentence");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Reaper", "ZedternalTempered.ZTUpgrade_Skill_DeathsGaze");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Reaper", "ZedternalTempered.ZTUpgrade_Skill_GrimTithe");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Reaper", "ZedternalTempered.ZTUpgrade_Skill_LastBreath");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Reaper", "ZedternalTempered.ZTUpgrade_Skill_MementoMori");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Reaper", "ZedternalTempered.ZTUpgrade_Skill_SoulChains");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Reaper", "ZedternalTempered.ZTUpgrade_Skill_SoulOverflow");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Reaper", "ZedternalTempered.ZTUpgrade_Skill_VeilWalker");

	// ZTUpgrade_Perk_Scavenger
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Scavenger", "ZedternalTempered.ZTUpgrade_Skill_AdrenalineReload");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Scavenger", "ZedternalTempered.ZTUpgrade_Skill_AmmoSiphon");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Scavenger", "ZedternalTempered.ZTUpgrade_Skill_BottomlessReserves");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Scavenger", "ZedternalTempered.ZTUpgrade_Skill_ChainFeed");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Scavenger", "ZedternalTempered.ZTUpgrade_Skill_DesperateMeasures");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Scavenger", "ZedternalTempered.ZTUpgrade_Skill_JuryRig");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Scavenger", "ZedternalTempered.ZTUpgrade_Skill_OneManArmy");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Scavenger", "ZedternalTempered.ZTUpgrade_Skill_QuickHands");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Scavenger", "ZedternalTempered.ZTUpgrade_Skill_WarProfileer");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Scavenger", "ZedternalTempered.ZTUpgrade_Skill_Windfall");

	// ZTUpgrade_Perk_Shapeshifter
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Shapeshifter", "ZedternalTempered.ZTUpgrade_Skill_ChimeraProtocol");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Shapeshifter", "ZedternalTempered.ZTUpgrade_Skill_FluxState");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Shapeshifter", "ZedternalTempered.ZTUpgrade_Skill_GeneticMemory");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Shapeshifter", "ZedternalTempered.ZTUpgrade_Skill_Monomorph");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Shapeshifter", "ZedternalTempered.ZTUpgrade_Skill_OverclockedForm");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Shapeshifter", "ZedternalTempered.ZTUpgrade_Skill_PolymorphicSynthesis");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Shapeshifter", "ZedternalTempered.ZTUpgrade_Skill_PrimordialVigor");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Shapeshifter", "ZedternalTempered.ZTUpgrade_Skill_ResidualForm");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Shapeshifter", "ZedternalTempered.ZTUpgrade_Skill_SurplusForm");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Shapeshifter", "ZedternalTempered.ZTUpgrade_Skill_VolatileShift");

	// ZTUpgrade_Perk_SpecialAgent
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_SpecialAgent", "ZedternalTempered.ZTUpgrade_Skill_ApronHunter");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_SpecialAgent", "ZedternalTempered.ZTUpgrade_Skill_Arachnophobia");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_SpecialAgent", "ZedternalTempered.ZTUpgrade_Skill_Extinguisher");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_SpecialAgent", "ZedternalTempered.ZTUpgrade_Skill_GoreFasting");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_SpecialAgent", "ZedternalTempered.ZTUpgrade_Skill_Muted");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_SpecialAgent", "ZedternalTempered.ZTUpgrade_Skill_Pounded");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_SpecialAgent", "ZedternalTempered.ZTUpgrade_Skill_RestrainingOrder");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_SpecialAgent", "ZedternalTempered.ZTUpgrade_Skill_Technophobe");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_SpecialAgent", "ZedternalTempered.ZTUpgrade_Skill_Untouchable");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_SpecialAgent", "ZedternalTempered.ZTUpgrade_Skill_Weightwatcher");

	// ZTUpgrade_Perk_Taskmaster
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Taskmaster", "ZedternalTempered.ZTUpgrade_Skill_BulletHell");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Taskmaster", "ZedternalTempered.ZTUpgrade_Skill_Deadshot");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Taskmaster", "ZedternalTempered.ZTUpgrade_Skill_HammerShot");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Taskmaster", "ZedternalTempered.ZTUpgrade_Skill_HippocraticOath");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Taskmaster", "ZedternalTempered.ZTUpgrade_Skill_Marathon");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Taskmaster", "ZedternalTempered.ZTUpgrade_Skill_Resourceful");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Taskmaster", "ZedternalTempered.ZTUpgrade_Skill_SurgicalPrecision");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Taskmaster", "ZedternalReborn.WMUpgrade_Skill_Tank");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Taskmaster", "ZedternalTempered.ZTUpgrade_Skill_ThreadTheNeedle");

	// ZTUpgrade_Perk_TimeTraveler
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_TimeTraveler", "ZedternalTempered.ZTUpgrade_Skill_BulletTime");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_TimeTraveler", "ZedternalTempered.ZTUpgrade_Skill_HighNoon");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_TimeTraveler", "ZedternalTempered.ZTUpgrade_Skill_Minuteman");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_TimeTraveler", "ZedternalTempered.ZTUpgrade_Skill_Pandemic");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_TimeTraveler", "ZedternalTempered.ZTUpgrade_Skill_Shifter");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_TimeTraveler", "ZedternalTempered.ZTUpgrade_Skill_TemporalFracture");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_TimeTraveler", "ZedternalTempered.ZTUpgrade_Skill_TimeHealsAllWounds");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_TimeTraveler", "ZedternalTempered.ZTUpgrade_Skill_TimeSpiral");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_TimeTraveler", "ZedternalTempered.ZTUpgrade_Skill_Timewalk");

	// ZTUpgrade_Perk_Tycoon
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Tycoon", "ZedternalTempered.ZTUpgrade_Skill_AssetLiquidation");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Tycoon", "ZedternalTempered.ZTUpgrade_Skill_BulkPurchasing");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Tycoon", "ZedternalTempered.ZTUpgrade_Skill_CorporateBailout");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Tycoon", "ZedternalTempered.ZTUpgrade_Skill_GoldenParachute");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Tycoon", "ZedternalTempered.ZTUpgrade_Skill_HODLing");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Tycoon", "ZedternalTempered.ZTUpgrade_Skill_HighRiskInvestment");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Tycoon", "ZedternalTempered.ZTUpgrade_Skill_HouseEdge");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Tycoon", "ZedternalTempered.ZTUpgrade_Skill_InsiderTrading");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Tycoon", "ZedternalTempered.ZTUpgrade_Skill_MercenaryContract");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Tycoon", "ZedternalTempered.ZTUpgrade_Skill_ProfitSharing");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Tycoon", "ZedternalTempered.ZTUpgrade_Skill_TaxLoopholes");

	// ZTUpgrade_Perk_Venomancer
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Venomancer", "ZedternalTempered.ZTUpgrade_Skill_AdaptiveVenom");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Venomancer", "ZedternalTempered.ZTUpgrade_Skill_Blight");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Venomancer", "ZedternalTempered.ZTUpgrade_Skill_EnvenomedArsenal");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Venomancer", "ZedternalTempered.ZTUpgrade_Skill_Miasma");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Venomancer", "ZedternalTempered.ZTUpgrade_Skill_Necrosis");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Venomancer", "ZedternalTempered.ZTUpgrade_Skill_Putrefaction");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Venomancer", "ZedternalTempered.ZTUpgrade_Skill_SymbioticToxin");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Venomancer", "ZedternalTempered.ZTUpgrade_Skill_ToxicAbsorption");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Venomancer", "ZedternalTempered.ZTUpgrade_Skill_VenomousRiposte");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Venomancer", "ZedternalTempered.ZTUpgrade_Skill_VenomWeave");

	// ZTUpgrade_Perk_Voodoo
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Voodoo", "ZedternalTempered.ZTUpgrade_Skill_BloodRush");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Voodoo", "ZedternalTempered.ZTUpgrade_Skill_DealWithTheDevil");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Voodoo", "ZedternalTempered.ZTUpgrade_Skill_NoStringsOnMe");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Voodoo", "ZedternalTempered.ZTUpgrade_Skill_OdeToGreed");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Voodoo", "ZedternalTempered.ZTUpgrade_Skill_PainSplit");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Voodoo", "ZedternalTempered.ZTUpgrade_Skill_PinpointAccuracy");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Voodoo", "ZedternalTempered.ZTUpgrade_Skill_PowerTransfer");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Voodoo", "ZedternalTempered.ZTUpgrade_Skill_SoulStealer");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Voodoo", "ZedternalTempered.ZTUpgrade_Skill_Triskelion");

	// ZTUpgrade_Perk_Diablo
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Diablo", "ZedternalTempered.ZTUpgrade_Skill_InfernalReservoir");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Diablo", "ZedternalTempered.ZTUpgrade_Skill_ExpandingHell");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Diablo", "ZedternalTempered.ZTUpgrade_Skill_ImpatienceOfHell");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Diablo", "ZedternalTempered.ZTUpgrade_Skill_ButchersLedger");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Diablo", "ZedternalTempered.ZTUpgrade_Skill_ScorchedWake");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Diablo", "ZedternalTempered.ZTUpgrade_Skill_EchoOfDamnation");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Diablo", "ZedternalTempered.ZTUpgrade_Skill_DemonSkin");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Diablo", "ZedternalTempered.ZTUpgrade_Skill_BloodTribute");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Diablo", "ZedternalTempered.ZTUpgrade_Skill_Hellgate");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Diablo", "ZedternalTempered.ZTUpgrade_Skill_Apocalypse");

	// ZTUpgrade_Perk_Warlord
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Warlord", "ZedternalTempered.ZTUpgrade_Skill_ArmorPiercingProtocol");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Warlord", "ZedternalTempered.ZTUpgrade_Skill_BattlefieldAwareness");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Warlord", "ZedternalTempered.ZTUpgrade_Skill_DeepReserves");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Warlord", "ZedternalTempered.ZTUpgrade_Skill_HuntersInstinct");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Warlord", "ZedternalTempered.ZTUpgrade_Skill_IronFortress");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Warlord", "ZedternalTempered.ZTUpgrade_Skill_LuckySalvage");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Warlord", "ZedternalTempered.ZTUpgrade_Skill_LuckyShot");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Warlord", "ZedternalTempered.ZTUpgrade_Skill_SuppressiveFire");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Warlord", "ZedternalTempered.ZTUpgrade_Skill_SymbioticRounds");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Warlord", "ZedternalTempered.ZTUpgrade_Skill_ThermalDrill");

	// ZTUpgrade_Perk_Wendigo
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Wendigo", "ZedternalTempered.ZTUpgrade_Skill_Consume");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Wendigo", "ZedternalTempered.ZTUpgrade_Skill_DeathChill");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Wendigo", "ZedternalTempered.ZTUpgrade_Skill_FaminesTouch");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Wendigo", "ZedternalTempered.ZTUpgrade_Skill_FrozenHide");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Wendigo", "ZedternalTempered.ZTUpgrade_Skill_HoardersCache");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Wendigo", "ZedternalTempered.ZTUpgrade_Skill_Isolation");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Wendigo", "ZedternalTempered.ZTUpgrade_Skill_Mimicry");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Wendigo", "ZedternalTempered.ZTUpgrade_Skill_PatientReload");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Wendigo", "ZedternalTempered.ZTUpgrade_Skill_PredatorsFocus");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Wendigo", "ZedternalTempered.ZTUpgrade_Skill_RavenousStrikes");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Wendigo", "ZedternalTempered.ZTUpgrade_Skill_Territorial");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Wendigo", "ZedternalTempered.ZTUpgrade_Skill_TrophyHunt");

	// ZTUpgrade_Perk_Hollow - compact Demolitionist specialization
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Hollow", "ZedternalTempered.ZTUpgrade_Skill_CompressedPowder");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Hollow", "ZedternalTempered.ZTUpgrade_Skill_VoidChamber");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Hollow", "ZedternalTempered.ZTUpgrade_Skill_GravityShock");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Hollow", "ZedternalTempered.ZTUpgrade_Skill_VoidStockpile");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Hollow", "ZedternalTempered.ZTUpgrade_Skill_RecycledFuse");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Hollow", "ZedternalTempered.ZTUpgrade_Skill_ImplosionArmor");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Hollow", "ZedternalTempered.ZTUpgrade_Skill_HastyEnd");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Hollow", "ZedternalTempered.ZTUpgrade_Skill_LargeCollapse");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Hollow", "ZedternalTempered.ZTUpgrade_Skill_ChainVoid");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Hollow", "ZedternalTempered.ZTUpgrade_Skill_PerfectAnnihilation");

}

// =============================================================================
// DK Symbiote Family Perks
// =============================================================================
static function AddDKSymbiotePerks()
{
	AddPerk("ZedternalTempered.ZTUpgrade_Perk_Agony", False);
	AddPerk("ZedternalTempered.ZTUpgrade_Perk_Cinder", False);
	AddPerk("ZedternalTempered.ZTUpgrade_Perk_Hivemind", False);
	AddPerk("ZedternalTempered.ZTUpgrade_Perk_Parasite", False);
	AddPerk("ZedternalTempered.ZTUpgrade_Perk_Riot", False);
	AddPerk("ZedternalTempered.ZTUpgrade_Perk_Symbiote", False);
}

// =============================================================================
// DK Symbiote Family Skills
// =============================================================================
static function AddDKSymbioteSkills()
{
	// ZTUpgrade_Perk_Agony
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Agony", "ZedternalTempered.ZTUpgrade_Skill_AcceleratedDecay");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Agony", "ZedternalTempered.ZTUpgrade_Skill_AgonizingPresence");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Agony", "ZedternalTempered.ZTUpgrade_Skill_ChronoCarapace");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Agony", "ZedternalTempered.ZTUpgrade_Skill_Chronoshift");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Agony", "ZedternalTempered.ZTUpgrade_Skill_EternalSuffering");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Agony", "ZedternalTempered.ZTUpgrade_Skill_PhantomPain");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Agony", "ZedternalTempered.ZTUpgrade_Skill_PocketDimension");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Agony", "ZedternalTempered.ZTUpgrade_Skill_TemporalAbsolution");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Agony", "ZedternalTempered.ZTUpgrade_Skill_TemporalRupture");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Agony", "ZedternalTempered.ZTUpgrade_Skill_TemporalSiphon");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Agony", "ZedternalTempered.ZTUpgrade_Skill_WarpPhase");

	// ZTUpgrade_Perk_Cinder
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Cinder", "ZedternalTempered.ZTUpgrade_Skill_AshenBulwark");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Cinder", "ZedternalTempered.ZTUpgrade_Skill_Conflagration");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Cinder", "ZedternalTempered.ZTUpgrade_Skill_Cremation");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Cinder", "ZedternalTempered.ZTUpgrade_Skill_FireEater");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Cinder", "ZedternalTempered.ZTUpgrade_Skill_Meltdown");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Cinder", "ZedternalTempered.ZTUpgrade_Skill_MoltenCore");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Cinder", "ZedternalTempered.ZTUpgrade_Skill_Pyre");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Cinder", "ZedternalTempered.ZTUpgrade_Skill_ScorchedEarth");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Cinder", "ZedternalTempered.ZTUpgrade_Skill_SearingFocus");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Cinder", "ZedternalTempered.ZTUpgrade_Skill_ThermalLance");

	// ZTUpgrade_Perk_Hivemind
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Hivemind", "ZedternalTempered.ZTUpgrade_Skill_BioelectricDischarge");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Hivemind", "ZedternalTempered.ZTUpgrade_Skill_EmpathicLink");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Hivemind", "ZedternalTempered.ZTUpgrade_Skill_Hivesight");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Hivemind", "ZedternalTempered.ZTUpgrade_Skill_InfestedRounds");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Hivemind", "ZedternalTempered.ZTUpgrade_Skill_Mitosis");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Hivemind", "ZedternalTempered.ZTUpgrade_Skill_NeuralFeedback");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Hivemind", "ZedternalTempered.ZTUpgrade_Skill_ParasiticBloom");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Hivemind", "ZedternalTempered.ZTUpgrade_Skill_PheromoneTrail");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Hivemind", "ZedternalTempered.ZTUpgrade_Skill_RegenerativeMembrane");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Hivemind", "ZedternalTempered.ZTUpgrade_Skill_SymbioticRestoration");

	// ZTUpgrade_Perk_Parasite
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Parasite", "ZedternalTempered.ZTUpgrade_Skill_BloodBank");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Parasite", "ZedternalTempered.ZTUpgrade_Skill_BloodShield");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Parasite", "ZedternalTempered.ZTUpgrade_Skill_Contagion");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Parasite", "ZedternalTempered.ZTUpgrade_Skill_CrimsonBond");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Parasite", "ZedternalTempered.ZTUpgrade_Skill_EssenceDrain");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Parasite", "ZedternalTempered.ZTUpgrade_Skill_LeechField");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Parasite", "ZedternalTempered.ZTUpgrade_Skill_LifeTap");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Parasite", "ZedternalTempered.ZTUpgrade_Skill_SiphonCascade");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Parasite", "ZedternalTempered.ZTUpgrade_Skill_SymbioticReload");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Parasite", "ZedternalTempered.ZTUpgrade_Skill_Transfusion");

	// ZTUpgrade_Perk_Riot
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Riot", "ZedternalTempered.ZTUpgrade_Skill_AdrenalineRush");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Riot", "ZedternalTempered.ZTUpgrade_Skill_BatteringRam");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Riot", "ZedternalTempered.ZTUpgrade_Skill_ChainFury");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Riot", "ZedternalTempered.ZTUpgrade_Skill_Counterforce");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Riot", "ZedternalTempered.ZTUpgrade_Skill_CrowdSurge");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Riot", "ZedternalTempered.ZTUpgrade_Skill_Deadlock");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Riot", "ZedternalTempered.ZTUpgrade_Skill_HoldTheLine");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Riot", "ZedternalTempered.ZTUpgrade_Skill_NoSurrender");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Riot", "ZedternalTempered.ZTUpgrade_Skill_PainEcho");

	// ZTUpgrade_Perk_Symbiote
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Symbiote", "ZedternalTempered.ZTUpgrade_Skill_AcidicBlood");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Symbiote", "ZedternalTempered.ZTUpgrade_Skill_BiomassRecycling");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Symbiote", "ZedternalTempered.ZTUpgrade_Skill_CellularRedundancy");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Symbiote", "ZedternalTempered.ZTUpgrade_Skill_DesperateSymbiosis");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Symbiote", "ZedternalTempered.ZTUpgrade_Skill_FleshWeaving");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Symbiote", "ZedternalTempered.ZTUpgrade_Skill_MetabolicOverdrive");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Symbiote", "ZedternalTempered.ZTUpgrade_Skill_MuscleFiberEnhancement");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Symbiote", "ZedternalTempered.ZTUpgrade_Skill_ParasiticBond");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Symbiote", "ZedternalTempered.ZTUpgrade_Skill_SurvivalInstinct");
	AddSkill("ZedternalTempered.ZTUpgrade_Perk_Symbiote", "ZedternalTempered.ZTUpgrade_Skill_SymbioticEfficiency");

}

defaultproperties
{
	Name="Default__ZTPresetData"
}
