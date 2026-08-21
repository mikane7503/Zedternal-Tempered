// =============================================================================
// DKPresetData - Preset configuration system for GeForce Now / ephemeral sessions
// Usage: mutate zupreset 0|1|2
//   0 = Default ZR (10 vanilla perks, 100 skills)
//   1 = ZU Full (all perks + skills, minus Artificer)
//   2 = ZU No Symbiotes (Full minus Symbiote family)
// =============================================================================
class DKPresetData extends Object;

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
	AddPerk("ZedternalRBPerkpackage.DKUpgrade_Perk_Archangel", False);
	AddPerk("ZedternalRBPerkpackage.DKUpgrade_Perk_Bulwark", False);
	AddPerk("ZedternalRBPerkpackage.DKUpgrade_Perk_Cryophilite", False);
	AddPerk("ZedternalRBPerkpackage.DKUpgrade_Perk_Daredevil", False);
	AddPerk("ZedternalRBPerkpackage.DKUpgrade_Perk_ForgeWarden", False);
	AddPerk("ZedternalRBPerkpackage.DKUpgrade_Perk_Frost", False);
	AddPerk("ZedternalRBPerkpackage.DKUpgrade_Perk_Gambler", False);
	AddPerk("ZedternalRBPerkpackage.DKUpgrade_Perk_Haunted", False);
	AddPerk("ZedternalRBPerkpackage.DKUpgrade_Perk_Headhunter", False);
	AddPerk("ZedternalRBPerkpackage.DKUpgrade_Perk_Hydra", False);
	AddPerk("ZedternalRBPerkpackage.DKUpgrade_Perk_Maniac", False);
	AddPerk("ZedternalRBPerkpackage.DKUpgrade_Perk_Medusa", False);
	AddPerk("ZedternalRBPerkpackage.DKUpgrade_Perk_Metronome", False);
	AddPerk("ZedternalRBPerkpackage.DKUpgrade_Perk_Pyrokinetic", False);
	AddPerk("ZedternalRBPerkpackage.DKUpgrade_Perk_Reaper", False);
	AddPerk("ZedternalRBPerkpackage.DKUpgrade_Perk_Scavenger", False);
	AddPerk("ZedternalRBPerkpackage.DKUpgrade_Perk_Shapeshifter", False);
	AddPerk("ZedternalRBPerkpackage.DKUpgrade_Perk_SpecialAgent", False);
	AddPerk("ZedternalRBPerkpackage.DKUpgrade_Perk_Taskmaster", False);
	AddPerk("ZedternalRBPerkpackage.DKUpgrade_Perk_TimeTraveler", False);
	AddPerk("ZedternalRBPerkpackage.DKUpgrade_Perk_Tycoon", False);
	AddPerk("ZedternalRBPerkpackage.DKUpgrade_Perk_Venomancer", False);
	AddPerk("ZedternalRBPerkpackage.DKUpgrade_Perk_Voodoo", False);
	AddPerk("ZedternalRBPerkpackage.DKUpgrade_Perk_Warlord", False);
	AddPerk("ZedternalRBPerkpackage.DKUpgrade_Perk_Wendigo", False);
}

// =============================================================================
// DK Core Skills (non-Symbiote)
// =============================================================================
static function AddDKCoreSkills()
{
	// DK skills granted on VANILLA perks (previously missing from presets
	// entirely - only the hand-edited server INI had them)
	AddSkill("ZedternalReborn.WMUpgrade_Perk_Sharpshooter", "ZedternalRBPerkpackage.DKUpgrade_Skill_EagleEye");
	AddSkill("ZedternalReborn.WMUpgrade_Perk_Gunslinger", "ZedternalRBPerkpackage.DKUpgrade_Skill_FastHands");

	// DKUpgrade_Perk_Archangel
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Archangel", "ZedternalRBPerkpackage.DKUpgrade_Skill_CelestialVitality");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Archangel", "ZedternalRBPerkpackage.DKUpgrade_Skill_DivineFortitude");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Archangel", "ZedternalRBPerkpackage.DKUpgrade_Skill_HolyResilience");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Archangel", "ZedternalRBPerkpackage.DKUpgrade_Skill_MartyrBlessing");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Archangel", "ZedternalRBPerkpackage.DKUpgrade_Skill_OverflowingGrace");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Archangel", "ZedternalRBPerkpackage.DKUpgrade_Skill_PhoenixPrayer");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Archangel", "ZedternalRBPerkpackage.DKUpgrade_Skill_SanctifiedRounds");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Archangel", "ZedternalRBPerkpackage.DKUpgrade_Skill_TriageExpert");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Archangel", "ZedternalRBPerkpackage.DKUpgrade_Skill_UnwaveringFaith");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Archangel", "ZedternalRBPerkpackage.DKUpgrade_Skill_WingsOfMercy");

	// DKUpgrade_Perk_Bulwark
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Bulwark", "ZedternalRBPerkpackage.DKUpgrade_Skill_Aware");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Bulwark", "ZedternalRBPerkpackage.DKUpgrade_Skill_BugFixing");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Bulwark", "ZedternalRBPerkpackage.DKUpgrade_Skill_Deflector");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Bulwark", "ZedternalRBPerkpackage.DKUpgrade_Skill_FLAK");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Bulwark", "ZedternalRBPerkpackage.DKUpgrade_Skill_Fencer");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Bulwark", "ZedternalRBPerkpackage.DKUpgrade_Skill_Indifferent");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Bulwark", "ZedternalRBPerkpackage.DKUpgrade_Skill_NoiseCancelling");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Bulwark", "ZedternalRBPerkpackage.DKUpgrade_Skill_SteelSkin");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Bulwark", "ZedternalRBPerkpackage.DKUpgrade_Skill_Stoic");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Bulwark", "ZedternalRBPerkpackage.DKUpgrade_Skill_ThickSkin");

	// DKUpgrade_Perk_Cryophilite
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Cryophilite", "ZedternalRBPerkpackage.DKUpgrade_Skill_AvalancheProtocol");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Cryophilite", "ZedternalRBPerkpackage.DKUpgrade_Skill_BitterChill");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Cryophilite", "ZedternalRBPerkpackage.DKUpgrade_Skill_CrystalClarity");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Cryophilite", "ZedternalRBPerkpackage.DKUpgrade_Skill_Fimbulwinter");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Cryophilite", "ZedternalRBPerkpackage.DKUpgrade_Skill_FrostbiteArrows");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Cryophilite", "ZedternalRBPerkpackage.DKUpgrade_Skill_GlacialEndurance");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Cryophilite", "ZedternalRBPerkpackage.DKUpgrade_Skill_IceArmor");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Cryophilite", "ZedternalRBPerkpackage.DKUpgrade_Skill_Permafrost");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Cryophilite", "ZedternalRBPerkpackage.DKUpgrade_Skill_QuiverMastery");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Cryophilite", "ZedternalRBPerkpackage.DKUpgrade_Skill_WintersSwiftness");

	// DKUpgrade_Perk_Daredevil
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Daredevil", "ZedternalRBPerkpackage.DKUpgrade_Skill_CloseCall");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Daredevil", "ZedternalRBPerkpackage.DKUpgrade_Skill_DeadeyeMomentum");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Daredevil", "ZedternalRBPerkpackage.DKUpgrade_Skill_FullMetalJacket");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Daredevil", "ZedternalRBPerkpackage.DKUpgrade_Skill_GlassCannon");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Daredevil", "ZedternalRBPerkpackage.DKUpgrade_Skill_ImpenetrableSkin");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Daredevil", "ZedternalRBPerkpackage.DKUpgrade_Skill_Primed");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Daredevil", "ZedternalRBPerkpackage.DKUpgrade_Skill_Resilience_Deluxe");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Daredevil", "ZedternalRBPerkpackage.DKUpgrade_Skill_Resilience_Deluxe1");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Daredevil", "ZedternalRBPerkpackage.DKUpgrade_Skill_ShowOff");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Daredevil", "ZedternalRBPerkpackage.DKUpgrade_Skill_TrueShot");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Daredevil", "ZedternalRBPerkpackage.DKUpgrade_Skill_TrueShot_Deluxe");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Daredevil", "ZedternalRBPerkpackage.DKUpgrade_Skill_Untouchable");

	// DKUpgrade_Perk_ForgeWarden
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_ForgeWarden", "ZedternalRBPerkpackage.DKUpgrade_Skill_Armory");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_ForgeWarden", "ZedternalRBPerkpackage.DKUpgrade_Skill_Bellows");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_ForgeWarden", "ZedternalRBPerkpackage.DKUpgrade_Skill_ChainReaction");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_ForgeWarden", "ZedternalRBPerkpackage.DKUpgrade_Skill_Crucible");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_ForgeWarden", "ZedternalRBPerkpackage.DKUpgrade_Skill_EmberHarvest");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_ForgeWarden", "ZedternalRBPerkpackage.DKUpgrade_Skill_EternalForge");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_ForgeWarden", "ZedternalRBPerkpackage.DKUpgrade_Skill_InfernoRounds");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_ForgeWarden", "ZedternalRBPerkpackage.DKUpgrade_Skill_Ironclad");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_ForgeWarden", "ZedternalRBPerkpackage.DKUpgrade_Skill_Pyroclasm");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_ForgeWarden", "ZedternalRBPerkpackage.DKUpgrade_Skill_SlagArmor");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_ForgeWarden", "ZedternalRBPerkpackage.DKUpgrade_Skill_TemperedSteel");

	// DKUpgrade_Perk_Frost
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Frost", "ZedternalRBPerkpackage.DKUpgrade_Skill_Absorb");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Frost", "ZedternalRBPerkpackage.DKUpgrade_Skill_AspectOfYmir");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Frost", "ZedternalRBPerkpackage.DKUpgrade_Skill_BlackIce");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Frost", "ZedternalRBPerkpackage.DKUpgrade_Skill_Blizzard");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Frost", "ZedternalRBPerkpackage.DKUpgrade_Skill_Cryosynthesis");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Frost", "ZedternalRBPerkpackage.DKUpgrade_Skill_FrozenHeart");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Frost", "ZedternalRBPerkpackage.DKUpgrade_Skill_Giantsbane");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Frost", "ZedternalRBPerkpackage.DKUpgrade_Skill_HarshConditions");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Frost", "ZedternalRBPerkpackage.DKUpgrade_Skill_Hypothermia");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Frost", "ZedternalRBPerkpackage.DKUpgrade_Skill_ImmovableObject");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Frost", "ZedternalRBPerkpackage.DKUpgrade_Skill_RegenerativeRounds");

	// DKUpgrade_Perk_Gambler
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Gambler", "ZedternalRBPerkpackage.DKUpgrade_Skill_ArmoredUp");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Gambler", "ZedternalRBPerkpackage.DKUpgrade_Skill_DoubleDown");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Gambler", "ZedternalRBPerkpackage.DKUpgrade_Skill_FieryGambit");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Gambler", "ZedternalRBPerkpackage.DKUpgrade_Skill_GrenadeConjurer");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Gambler", "ZedternalRBPerkpackage.DKUpgrade_Skill_IcyGambit");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Gambler", "ZedternalRBPerkpackage.DKUpgrade_Skill_Jackpot");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Gambler", "ZedternalRBPerkpackage.DKUpgrade_Skill_LuckyPop");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Gambler", "ZedternalRBPerkpackage.DKUpgrade_Skill_NarrowEscape");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Gambler", "ZedternalRBPerkpackage.DKUpgrade_Skill_StrokeOfLuck");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Gambler", "ZedternalRBPerkpackage.DKUpgrade_Skill_ToxicGambit");

	// DKUpgrade_Perk_Haunted (no skills)
	// DKUpgrade_Perk_Headhunter
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Headhunter", "ZedternalRBPerkpackage.DKUpgrade_Skill_AmishParadise");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Headhunter", "ZedternalRBPerkpackage.DKUpgrade_Skill_CeaseAndDesist");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Headhunter", "ZedternalRBPerkpackage.DKUpgrade_Skill_Clotbuster");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Headhunter", "ZedternalRBPerkpackage.DKUpgrade_Skill_Dietician");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Headhunter", "ZedternalRBPerkpackage.DKUpgrade_Skill_Feminist");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Headhunter", "ZedternalRBPerkpackage.DKUpgrade_Skill_Firefighter");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Headhunter", "ZedternalRBPerkpackage.DKUpgrade_Skill_GorefastSlayer");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Headhunter", "ZedternalRBPerkpackage.DKUpgrade_Skill_Kingslayer");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Headhunter", "ZedternalRBPerkpackage.DKUpgrade_Skill_NoCloneZone");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Headhunter", "ZedternalRBPerkpackage.DKUpgrade_Skill_NoWomanNoCry");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Headhunter", "ZedternalRBPerkpackage.DKUpgrade_Skill_NoiseComplaint");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Headhunter", "ZedternalRBPerkpackage.DKUpgrade_Skill_SomeoneYourOwnSize");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Headhunter", "ZedternalRBPerkpackage.DKUpgrade_Skill_SupersizeMe");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Headhunter", "ZedternalRBPerkpackage.DKUpgrade_Skill_TexasChainsawMassacre");

	// DKUpgrade_Perk_Hydra
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Hydra", "ZedternalRBPerkpackage.DKUpgrade_Skill_ApexPredator");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Hydra", "ZedternalRBPerkpackage.DKUpgrade_Skill_Bloodthirst");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Hydra", "ZedternalRBPerkpackage.DKUpgrade_Skill_CascadingMassacre");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Hydra", "ZedternalRBPerkpackage.DKUpgrade_Skill_EndlessRampage");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Hydra", "ZedternalRBPerkpackage.DKUpgrade_Skill_HuntDown");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Hydra", "ZedternalRBPerkpackage.DKUpgrade_Skill_LernaeanImmortality");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Hydra", "ZedternalRBPerkpackage.DKUpgrade_Skill_Overkill");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Hydra", "ZedternalRBPerkpackage.DKUpgrade_Skill_PrimalRoar");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Hydra", "ZedternalRBPerkpackage.DKUpgrade_Skill_ReflectedFury");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Hydra", "ZedternalRBPerkpackage.DKUpgrade_Skill_SymphonyOfSlaughter");

	// DKUpgrade_Perk_Maniac
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Maniac", "ZedternalRBPerkpackage.DKUpgrade_Skill_ArmedAndDangerous");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Maniac", "ZedternalRBPerkpackage.DKUpgrade_Skill_Arsonist");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Maniac", "ZedternalRBPerkpackage.DKUpgrade_Skill_BargainHunter");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Maniac", "ZedternalRBPerkpackage.DKUpgrade_Skill_Dauntless");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Maniac", "ZedternalRBPerkpackage.DKUpgrade_Skill_Elmo");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Maniac", "ZedternalRBPerkpackage.DKUpgrade_Skill_Fanatic");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Maniac", "ZedternalRBPerkpackage.DKUpgrade_Skill_Fireproof");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Maniac", "ZedternalRBPerkpackage.DKUpgrade_Skill_MadBomber");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Maniac", "ZedternalRBPerkpackage.DKUpgrade_Skill_SafetyFirst");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Maniac", "ZedternalRBPerkpackage.DKUpgrade_Skill_SlowCooker");

	// DKUpgrade_Perk_Medusa
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Medusa", "ZedternalRBPerkpackage.DKUpgrade_Skill_AthenasWrath");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Medusa", "ZedternalRBPerkpackage.DKUpgrade_Skill_CurseOfStone");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Medusa", "ZedternalRBPerkpackage.DKUpgrade_Skill_GorgonsCurse");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Medusa", "ZedternalRBPerkpackage.DKUpgrade_Skill_GorgonsLegacy");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Medusa", "ZedternalRBPerkpackage.DKUpgrade_Skill_Metamorphosis");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Medusa", "ZedternalRBPerkpackage.DKUpgrade_Skill_NestOfVipers");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Medusa", "ZedternalRBPerkpackage.DKUpgrade_Skill_PetrifyingPresence");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Medusa", "ZedternalRBPerkpackage.DKUpgrade_Skill_SerpentineReflexes");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Medusa", "ZedternalRBPerkpackage.DKUpgrade_Skill_ShedSkin");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Medusa", "ZedternalRBPerkpackage.DKUpgrade_Skill_SnakesCoil");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Medusa", "ZedternalRBPerkpackage.DKUpgrade_Skill_ToxicAura");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Medusa", "ZedternalRBPerkpackage.DKUpgrade_Skill_ToxicImmunity");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Medusa", "ZedternalRBPerkpackage.DKUpgrade_Skill_VenomExtraction");

	// DKUpgrade_Perk_Pyrokinetic
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Pyrokinetic", "ZedternalRBPerkpackage.DKUpgrade_Skill_Backdraft");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Pyrokinetic", "ZedternalRBPerkpackage.DKUpgrade_Skill_Blaze");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Pyrokinetic", "ZedternalRBPerkpackage.DKUpgrade_Skill_ChosenOfTheSun");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Pyrokinetic", "ZedternalRBPerkpackage.DKUpgrade_Skill_ConsumingFlame");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Pyrokinetic", "ZedternalRBPerkpackage.DKUpgrade_Skill_Flashpoint");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Pyrokinetic", "ZedternalRBPerkpackage.DKUpgrade_Skill_Forger");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Pyrokinetic", "ZedternalRBPerkpackage.DKUpgrade_Skill_Heatstroke");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Pyrokinetic", "ZedternalRBPerkpackage.DKUpgrade_Skill_SearingGaze");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Pyrokinetic", "ZedternalRBPerkpackage.DKUpgrade_Skill_TrialByFire");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Pyrokinetic", "ZedternalRBPerkpackage.DKUpgrade_Skill_Wildfire");

	// DKUpgrade_Perk_Reaper
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Reaper", "ZedternalRBPerkpackage.DKUpgrade_Skill_DanceOfDeath");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Reaper", "ZedternalRBPerkpackage.DKUpgrade_Skill_DeathlessFury");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Reaper", "ZedternalRBPerkpackage.DKUpgrade_Skill_DeathSentence");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Reaper", "ZedternalRBPerkpackage.DKUpgrade_Skill_DeathsGaze");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Reaper", "ZedternalRBPerkpackage.DKUpgrade_Skill_GrimTithe");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Reaper", "ZedternalRBPerkpackage.DKUpgrade_Skill_LastBreath");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Reaper", "ZedternalRBPerkpackage.DKUpgrade_Skill_MementoMori");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Reaper", "ZedternalRBPerkpackage.DKUpgrade_Skill_SoulChains");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Reaper", "ZedternalRBPerkpackage.DKUpgrade_Skill_SoulOverflow");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Reaper", "ZedternalRBPerkpackage.DKUpgrade_Skill_VeilWalker");

	// DKUpgrade_Perk_Scavenger
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Scavenger", "ZedternalRBPerkpackage.DKUpgrade_Skill_AdrenalineReload");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Scavenger", "ZedternalRBPerkpackage.DKUpgrade_Skill_AmmoSiphon");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Scavenger", "ZedternalRBPerkpackage.DKUpgrade_Skill_BottomlessReserves");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Scavenger", "ZedternalRBPerkpackage.DKUpgrade_Skill_ChainFeed");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Scavenger", "ZedternalRBPerkpackage.DKUpgrade_Skill_DesperateMeasures");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Scavenger", "ZedternalRBPerkpackage.DKUpgrade_Skill_JuryRig");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Scavenger", "ZedternalRBPerkpackage.DKUpgrade_Skill_OneManArmy");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Scavenger", "ZedternalRBPerkpackage.DKUpgrade_Skill_QuickHands");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Scavenger", "ZedternalRBPerkpackage.DKUpgrade_Skill_WarProfileer");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Scavenger", "ZedternalRBPerkpackage.DKUpgrade_Skill_Windfall");

	// DKUpgrade_Perk_Shapeshifter
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Shapeshifter", "ZedternalRBPerkpackage.DKUpgrade_Skill_ChimeraProtocol");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Shapeshifter", "ZedternalRBPerkpackage.DKUpgrade_Skill_FluxState");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Shapeshifter", "ZedternalRBPerkpackage.DKUpgrade_Skill_GeneticMemory");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Shapeshifter", "ZedternalRBPerkpackage.DKUpgrade_Skill_Monomorph");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Shapeshifter", "ZedternalRBPerkpackage.DKUpgrade_Skill_OverclockedForm");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Shapeshifter", "ZedternalRBPerkpackage.DKUpgrade_Skill_PolymorphicSynthesis");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Shapeshifter", "ZedternalRBPerkpackage.DKUpgrade_Skill_PrimordialVigor");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Shapeshifter", "ZedternalRBPerkpackage.DKUpgrade_Skill_ResidualForm");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Shapeshifter", "ZedternalRBPerkpackage.DKUpgrade_Skill_SurplusForm");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Shapeshifter", "ZedternalRBPerkpackage.DKUpgrade_Skill_VolatileShift");

	// DKUpgrade_Perk_SpecialAgent
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_SpecialAgent", "ZedternalRBPerkpackage.DKUpgrade_Skill_ApronHunter");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_SpecialAgent", "ZedternalRBPerkpackage.DKUpgrade_Skill_Arachnophobia");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_SpecialAgent", "ZedternalRBPerkpackage.DKUpgrade_Skill_Extinguisher");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_SpecialAgent", "ZedternalRBPerkpackage.DKUpgrade_Skill_GoreFasting");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_SpecialAgent", "ZedternalRBPerkpackage.DKUpgrade_Skill_Muted");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_SpecialAgent", "ZedternalRBPerkpackage.DKUpgrade_Skill_Pounded");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_SpecialAgent", "ZedternalRBPerkpackage.DKUpgrade_Skill_RestrainingOrder");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_SpecialAgent", "ZedternalRBPerkpackage.DKUpgrade_Skill_Technophobe");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_SpecialAgent", "ZedternalRBPerkpackage.DKUpgrade_Skill_Untouchable");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_SpecialAgent", "ZedternalRBPerkpackage.DKUpgrade_Skill_Weightwatcher");

	// DKUpgrade_Perk_Taskmaster
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Taskmaster", "ZedternalRBPerkpackage.DKUpgrade_Skill_BulletHell");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Taskmaster", "ZedternalRBPerkpackage.DKUpgrade_Skill_Deadshot");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Taskmaster", "ZedternalRBPerkpackage.DKUpgrade_Skill_HammerShot");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Taskmaster", "ZedternalRBPerkpackage.DKUpgrade_Skill_HippocraticOath");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Taskmaster", "ZedternalRBPerkpackage.DKUpgrade_Skill_Marathon");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Taskmaster", "ZedternalRBPerkpackage.DKUpgrade_Skill_Overpower");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Taskmaster", "ZedternalRBPerkpackage.DKUpgrade_Skill_Resourceful");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Taskmaster", "ZedternalRBPerkpackage.DKUpgrade_Skill_SurgicalPrecision");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Taskmaster", "ZedternalRBPerkpackage.DKUpgrade_Skill_Tank");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Taskmaster", "ZedternalRBPerkpackage.DKUpgrade_Skill_ThreadTheNeedle");

	// DKUpgrade_Perk_TimeTraveler
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_TimeTraveler", "ZedternalRBPerkpackage.DKUpgrade_Skill_BulletTime");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_TimeTraveler", "ZedternalRBPerkpackage.DKUpgrade_Skill_HighNoon");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_TimeTraveler", "ZedternalRBPerkpackage.DKUpgrade_Skill_Minuteman");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_TimeTraveler", "ZedternalRBPerkpackage.DKUpgrade_Skill_Pandemic");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_TimeTraveler", "ZedternalRBPerkpackage.DKUpgrade_Skill_Shifter");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_TimeTraveler", "ZedternalRBPerkpackage.DKUpgrade_Skill_TemporalFracture");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_TimeTraveler", "ZedternalRBPerkpackage.DKUpgrade_Skill_TimeHealsAllWounds");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_TimeTraveler", "ZedternalRBPerkpackage.DKUpgrade_Skill_TimeSpiral");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_TimeTraveler", "ZedternalRBPerkpackage.DKUpgrade_Skill_Timeburst");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_TimeTraveler", "ZedternalRBPerkpackage.DKUpgrade_Skill_Timewalk");

	// DKUpgrade_Perk_Tycoon
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Tycoon", "ZedternalRBPerkpackage.DKUpgrade_Skill_AssetLiquidation");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Tycoon", "ZedternalRBPerkpackage.DKUpgrade_Skill_BulkPurchasing");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Tycoon", "ZedternalRBPerkpackage.DKUpgrade_Skill_CorporateBailout");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Tycoon", "ZedternalRBPerkpackage.DKUpgrade_Skill_GoldenParachute");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Tycoon", "ZedternalRBPerkpackage.DKUpgrade_Skill_HODLing");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Tycoon", "ZedternalRBPerkpackage.DKUpgrade_Skill_HighRiskInvestment");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Tycoon", "ZedternalRBPerkpackage.DKUpgrade_Skill_HouseEdge");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Tycoon", "ZedternalRBPerkpackage.DKUpgrade_Skill_InsiderTrading");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Tycoon", "ZedternalRBPerkpackage.DKUpgrade_Skill_MercenaryContract");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Tycoon", "ZedternalRBPerkpackage.DKUpgrade_Skill_ProfitSharing");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Tycoon", "ZedternalRBPerkpackage.DKUpgrade_Skill_TaxLoopholes");

	// DKUpgrade_Perk_Venomancer
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Venomancer", "ZedternalRBPerkpackage.DKUpgrade_Skill_AdaptiveVenom");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Venomancer", "ZedternalRBPerkpackage.DKUpgrade_Skill_Blight");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Venomancer", "ZedternalRBPerkpackage.DKUpgrade_Skill_EnvenomedArsenal");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Venomancer", "ZedternalRBPerkpackage.DKUpgrade_Skill_Miasma");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Venomancer", "ZedternalRBPerkpackage.DKUpgrade_Skill_Necrosis");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Venomancer", "ZedternalRBPerkpackage.DKUpgrade_Skill_Outbreak");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Venomancer", "ZedternalRBPerkpackage.DKUpgrade_Skill_Putrefaction");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Venomancer", "ZedternalRBPerkpackage.DKUpgrade_Skill_SymbioticToxin");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Venomancer", "ZedternalRBPerkpackage.DKUpgrade_Skill_ToxicAbsorption");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Venomancer", "ZedternalRBPerkpackage.DKUpgrade_Skill_ToxicOverload");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Venomancer", "ZedternalRBPerkpackage.DKUpgrade_Skill_VenomousRiposte");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Venomancer", "ZedternalRBPerkpackage.DKUpgrade_Skill_VenomWeave");

	// DKUpgrade_Perk_Voodoo
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Voodoo", "ZedternalRBPerkpackage.DKUpgrade_Skill_BloodRush");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Voodoo", "ZedternalRBPerkpackage.DKUpgrade_Skill_DealWithTheDevil");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Voodoo", "ZedternalRBPerkpackage.DKUpgrade_Skill_NoStringsOnMe");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Voodoo", "ZedternalRBPerkpackage.DKUpgrade_Skill_OdeToGreed");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Voodoo", "ZedternalRBPerkpackage.DKUpgrade_Skill_PainSplit");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Voodoo", "ZedternalRBPerkpackage.DKUpgrade_Skill_PinpointAccuracy");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Voodoo", "ZedternalRBPerkpackage.DKUpgrade_Skill_PowerTransfer");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Voodoo", "ZedternalRBPerkpackage.DKUpgrade_Skill_Reaper");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Voodoo", "ZedternalRBPerkpackage.DKUpgrade_Skill_SoulStealer");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Voodoo", "ZedternalRBPerkpackage.DKUpgrade_Skill_Triskelion");

	// DKUpgrade_Perk_Warlord
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Warlord", "ZedternalRBPerkpackage.DKUpgrade_Skill_ArmorPiercingProtocol");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Warlord", "ZedternalRBPerkpackage.DKUpgrade_Skill_BattlefieldAwareness");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Warlord", "ZedternalRBPerkpackage.DKUpgrade_Skill_DeepReserves");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Warlord", "ZedternalRBPerkpackage.DKUpgrade_Skill_HuntersInstinct");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Warlord", "ZedternalRBPerkpackage.DKUpgrade_Skill_IronFortress");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Warlord", "ZedternalRBPerkpackage.DKUpgrade_Skill_LuckySalvage");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Warlord", "ZedternalRBPerkpackage.DKUpgrade_Skill_LuckyShot");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Warlord", "ZedternalRBPerkpackage.DKUpgrade_Skill_SuppressiveFire");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Warlord", "ZedternalRBPerkpackage.DKUpgrade_Skill_SymbioticRounds");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Warlord", "ZedternalRBPerkpackage.DKUpgrade_Skill_ThermalDrill");

	// DKUpgrade_Perk_Wendigo
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Wendigo", "ZedternalRBPerkpackage.DKUpgrade_Skill_Consume");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Wendigo", "ZedternalRBPerkpackage.DKUpgrade_Skill_DeathChill");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Wendigo", "ZedternalRBPerkpackage.DKUpgrade_Skill_FaminesTouch");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Wendigo", "ZedternalRBPerkpackage.DKUpgrade_Skill_FrozenHide");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Wendigo", "ZedternalRBPerkpackage.DKUpgrade_Skill_HoardersCache");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Wendigo", "ZedternalRBPerkpackage.DKUpgrade_Skill_Isolation");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Wendigo", "ZedternalRBPerkpackage.DKUpgrade_Skill_Mimicry");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Wendigo", "ZedternalRBPerkpackage.DKUpgrade_Skill_PatientReload");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Wendigo", "ZedternalRBPerkpackage.DKUpgrade_Skill_PredatorsFocus");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Wendigo", "ZedternalRBPerkpackage.DKUpgrade_Skill_RavenousStrikes");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Wendigo", "ZedternalRBPerkpackage.DKUpgrade_Skill_Territorial");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Wendigo", "ZedternalRBPerkpackage.DKUpgrade_Skill_TrophyHunt");

}

// =============================================================================
// DK Symbiote Family Perks
// =============================================================================
static function AddDKSymbiotePerks()
{
	AddPerk("ZedternalRBPerkpackage.DKUpgrade_Perk_Agony", False);
	AddPerk("ZedternalRBPerkpackage.DKUpgrade_Perk_Cinder", False);
	AddPerk("ZedternalRBPerkpackage.DKUpgrade_Perk_Hivemind", False);
	AddPerk("ZedternalRBPerkpackage.DKUpgrade_Perk_Parasite", False);
	AddPerk("ZedternalRBPerkpackage.DKUpgrade_Perk_Riot", False);
	AddPerk("ZedternalRBPerkpackage.DKUpgrade_Perk_Symbiote", False);
}

// =============================================================================
// DK Symbiote Family Skills
// =============================================================================
static function AddDKSymbioteSkills()
{
	// DKUpgrade_Perk_Agony
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Agony", "ZedternalRBPerkpackage.DKUpgrade_Skill_AcceleratedDecay");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Agony", "ZedternalRBPerkpackage.DKUpgrade_Skill_AgonizingPresence");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Agony", "ZedternalRBPerkpackage.DKUpgrade_Skill_ChronoCarapace");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Agony", "ZedternalRBPerkpackage.DKUpgrade_Skill_Chronoshift");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Agony", "ZedternalRBPerkpackage.DKUpgrade_Skill_EternalSuffering");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Agony", "ZedternalRBPerkpackage.DKUpgrade_Skill_PhantomPain");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Agony", "ZedternalRBPerkpackage.DKUpgrade_Skill_PocketDimension");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Agony", "ZedternalRBPerkpackage.DKUpgrade_Skill_TemporalAbsolution");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Agony", "ZedternalRBPerkpackage.DKUpgrade_Skill_TemporalRupture");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Agony", "ZedternalRBPerkpackage.DKUpgrade_Skill_TemporalSiphon");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Agony", "ZedternalRBPerkpackage.DKUpgrade_Skill_WarpPhase");

	// DKUpgrade_Perk_Cinder
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Cinder", "ZedternalRBPerkpackage.DKUpgrade_Skill_AshenBulwark");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Cinder", "ZedternalRBPerkpackage.DKUpgrade_Skill_Conflagration");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Cinder", "ZedternalRBPerkpackage.DKUpgrade_Skill_Cremation");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Cinder", "ZedternalRBPerkpackage.DKUpgrade_Skill_FireEater");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Cinder", "ZedternalRBPerkpackage.DKUpgrade_Skill_Meltdown");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Cinder", "ZedternalRBPerkpackage.DKUpgrade_Skill_MoltenCore");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Cinder", "ZedternalRBPerkpackage.DKUpgrade_Skill_Pyre");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Cinder", "ZedternalRBPerkpackage.DKUpgrade_Skill_ScorchedEarth");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Cinder", "ZedternalRBPerkpackage.DKUpgrade_Skill_SearingFocus");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Cinder", "ZedternalRBPerkpackage.DKUpgrade_Skill_ThermalLance");

	// DKUpgrade_Perk_Hivemind
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Hivemind", "ZedternalRBPerkpackage.DKUpgrade_Skill_BioelectricDischarge");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Hivemind", "ZedternalRBPerkpackage.DKUpgrade_Skill_EmpathicLink");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Hivemind", "ZedternalRBPerkpackage.DKUpgrade_Skill_Hivesight");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Hivemind", "ZedternalRBPerkpackage.DKUpgrade_Skill_InfestedRounds");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Hivemind", "ZedternalRBPerkpackage.DKUpgrade_Skill_Mitosis");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Hivemind", "ZedternalRBPerkpackage.DKUpgrade_Skill_NeuralFeedback");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Hivemind", "ZedternalRBPerkpackage.DKUpgrade_Skill_ParasiticBloom");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Hivemind", "ZedternalRBPerkpackage.DKUpgrade_Skill_PheromoneTrail");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Hivemind", "ZedternalRBPerkpackage.DKUpgrade_Skill_RegenerativeMembrane");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Hivemind", "ZedternalRBPerkpackage.DKUpgrade_Skill_SymbioticRestoration");

	// DKUpgrade_Perk_Parasite
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Parasite", "ZedternalRBPerkpackage.DKUpgrade_Skill_BloodBank");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Parasite", "ZedternalRBPerkpackage.DKUpgrade_Skill_BloodShield");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Parasite", "ZedternalRBPerkpackage.DKUpgrade_Skill_Contagion");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Parasite", "ZedternalRBPerkpackage.DKUpgrade_Skill_CrimsonBond");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Parasite", "ZedternalRBPerkpackage.DKUpgrade_Skill_EssenceDrain");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Parasite", "ZedternalRBPerkpackage.DKUpgrade_Skill_LeechField");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Parasite", "ZedternalRBPerkpackage.DKUpgrade_Skill_LifeTap");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Parasite", "ZedternalRBPerkpackage.DKUpgrade_Skill_SiphonCascade");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Parasite", "ZedternalRBPerkpackage.DKUpgrade_Skill_SymbioticReload");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Parasite", "ZedternalRBPerkpackage.DKUpgrade_Skill_Transfusion");

	// DKUpgrade_Perk_Riot
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Riot", "ZedternalRBPerkpackage.DKUpgrade_Skill_AdrenalineRush");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Riot", "ZedternalRBPerkpackage.DKUpgrade_Skill_BatteringRam");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Riot", "ZedternalRBPerkpackage.DKUpgrade_Skill_ChainFury");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Riot", "ZedternalRBPerkpackage.DKUpgrade_Skill_Counterforce");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Riot", "ZedternalRBPerkpackage.DKUpgrade_Skill_CrowdSurge");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Riot", "ZedternalRBPerkpackage.DKUpgrade_Skill_Deadlock");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Riot", "ZedternalRBPerkpackage.DKUpgrade_Skill_HoldTheLine");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Riot", "ZedternalRBPerkpackage.DKUpgrade_Skill_NoSurrender");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Riot", "ZedternalRBPerkpackage.DKUpgrade_Skill_PainEcho");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Riot", "ZedternalRBPerkpackage.DKUpgrade_Skill_Shockwave");

	// DKUpgrade_Perk_Symbiote
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Symbiote", "ZedternalRBPerkpackage.DKUpgrade_Skill_AcidicBlood");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Symbiote", "ZedternalRBPerkpackage.DKUpgrade_Skill_BiomassRecycling");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Symbiote", "ZedternalRBPerkpackage.DKUpgrade_Skill_CellularRedundancy");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Symbiote", "ZedternalRBPerkpackage.DKUpgrade_Skill_DesperateSymbiosis");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Symbiote", "ZedternalRBPerkpackage.DKUpgrade_Skill_FleshWeaving");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Symbiote", "ZedternalRBPerkpackage.DKUpgrade_Skill_MetabolicOverdrive");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Symbiote", "ZedternalRBPerkpackage.DKUpgrade_Skill_MuscleFiberEnhancement");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Symbiote", "ZedternalRBPerkpackage.DKUpgrade_Skill_ParasiticBond");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Symbiote", "ZedternalRBPerkpackage.DKUpgrade_Skill_SurvivalInstinct");
	AddSkill("ZedternalRBPerkpackage.DKUpgrade_Perk_Symbiote", "ZedternalRBPerkpackage.DKUpgrade_Skill_SymbioticEfficiency");

}

defaultproperties
{
	Name="Default__DKPresetData"
}