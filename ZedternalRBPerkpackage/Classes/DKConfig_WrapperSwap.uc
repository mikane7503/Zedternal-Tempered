// ===================================================================
// DKConfig_WrapperSwap
//
// Auto-discovers DKWrapper_* classes by naming convention and swaps
// config path strings BEFORE super.InitGame() so ZR's own loading
// pipeline picks up wrappers naturally.
//
// Call SwapAll() from DKGameInfo_Endless.InitGame() BEFORE super.
//
// Naming convention:
//   Original: ZedternalReborn.WMUpgrade_Perk_Berserker
//   Wrapper:  ZedternalRBPerkpackage.DKWrapper_Perk_Berserker
//
// Any DKWrapper_* class that exists in the package is auto-swapped.
// No hardcoded entries needed — just create the wrapper file.
//
// NOTE: Weapon wrapper swap REMOVED for verification — testing whether
// weapon upgrade wrappers were the cause of Hustler/MagSize/SpareAmmo
// not working. Vanilla WMUpgrade_Weapon_* paths now stay as-is and
// values revert to ZR's hardcoded defaults. Cost/level/static remain
// INI-editable via Config_WeaponUpgrade. InjectHollowWeaponUpgrades
// is preserved (independent of wrapper system).
// ===================================================================
class DKConfig_WrapperSwap extends Object;

static function SwapAll()
{
	SwapPerkPaths();
	SwapSkillPaths();
	SwapEquipmentPaths();
	InjectHollowWeaponUpgrades();
}

static function SwapPerkPaths()
{
	local int i, Idx;
	local string OrigPath, ShortName, WrapperPath;

	for (i = 0; i < class'ZedternalReborn.Config_PerkUpgrade'.default.PerkUpgrade_Upgrade.Length; i++)
	{
		OrigPath = class'ZedternalReborn.Config_PerkUpgrade'.default.PerkUpgrade_Upgrade[i].PerkPath;

		Idx = InStr(OrigPath, "Upgrade_Perk_");
		if (Idx == INDEX_NONE)
			continue;

		ShortName = Mid(OrigPath, Idx + 13);
		WrapperPath = "ZedternalRBPerkpackage.DKWrapper_Perk_" $ ShortName;

		if (DynamicLoadObject(WrapperPath, class'Class', True) == None)
			WrapperPath = "ZedternalRBPerkpackage.DKWrapper_Perk_Psy_" $ ShortName;

		if (DynamicLoadObject(WrapperPath, class'Class', True) != None)
		{
			class'ZedternalReborn.Config_PerkUpgrade'.default.PerkUpgrade_Upgrade[i].PerkPath = WrapperPath;
			`log("[DK_SWAP] Perk:" @ OrigPath @ "->" @ WrapperPath);
		}
	}
}

static function SwapSkillPaths()
{
	local int i, Idx;
	local string OrigPath, ShortName, WrapperPath, OrigPerkPath;

	for (i = 0; i < class'ZedternalReborn.Config_SkillUpgrade'.default.SkillUpgrade_Upgrade.Length; i++)
	{
		// Swap PerkPath FIRST — must run for ALL skills (including third-party mods
		// like PCF whose SkillPath won't match "Upgrade_Skill_" pattern)
		OrigPerkPath = class'ZedternalReborn.Config_SkillUpgrade'.default.SkillUpgrade_Upgrade[i].PerkPath;
		Idx = InStr(OrigPerkPath, "Upgrade_Perk_");
		if (Idx != INDEX_NONE)
		{
			ShortName = Mid(OrigPerkPath, Idx + 13);
			WrapperPath = "ZedternalRBPerkpackage.DKWrapper_Perk_" $ ShortName;
			if (DynamicLoadObject(WrapperPath, class'Class', True) != None)
			{
				class'ZedternalReborn.Config_SkillUpgrade'.default.SkillUpgrade_Upgrade[i].PerkPath = WrapperPath;
				`log("[DK_SWAP] SkillPerkPath:" @ OrigPerkPath @ "->" @ WrapperPath);
			}
		}

		// Swap SkillPath — only for skills that follow the Upgrade_Skill_ naming convention
		OrigPath = class'ZedternalReborn.Config_SkillUpgrade'.default.SkillUpgrade_Upgrade[i].SkillPath;

		Idx = InStr(OrigPath, "Upgrade_Skill_");
		if (Idx == INDEX_NONE)
			continue;

		ShortName = Mid(OrigPath, Idx + 14);
		WrapperPath = "ZedternalRBPerkpackage.DKWrapper_Skill_" $ ShortName;

		if (DynamicLoadObject(WrapperPath, class'Class', True) == None)
			WrapperPath = "ZedternalRBPerkpackage.DKWrapper_Skill_Psy_" $ ShortName;

		if (DynamicLoadObject(WrapperPath, class'Class', True) != None)
		{
			class'ZedternalReborn.Config_SkillUpgrade'.default.SkillUpgrade_Upgrade[i].SkillPath = WrapperPath;
			`log("[DK_SWAP] Skill:" @ OrigPath @ "->" @ WrapperPath);
		}
	}
}

static function SwapEquipmentPaths()
{
	local int i, Idx;
	local string OrigPath, ShortName, WrapperPath;

	for (i = 0; i < class'ZedternalReborn.Config_EquipmentUpgrade'.default.EquipmentUpgrade_Upgrade.Length; i++)
	{
		OrigPath = class'ZedternalReborn.Config_EquipmentUpgrade'.default.EquipmentUpgrade_Upgrade[i].EquipmentPath;

		Idx = InStr(OrigPath, "Upgrade_Equipment_");
		if (Idx == INDEX_NONE)
			continue;

		ShortName = Mid(OrigPath, Idx + 18);
		WrapperPath = "ZedternalRBPerkpackage.DKWrapper_Equipment_" $ ShortName;

		if (DynamicLoadObject(WrapperPath, class'Class', True) == None)
			WrapperPath = "ZedternalRBPerkpackage.DKWrapper_Equipment_Psy_" $ ShortName;

		if (DynamicLoadObject(WrapperPath, class'Class', True) != None)
		{
			class'ZedternalReborn.Config_EquipmentUpgrade'.default.EquipmentUpgrade_Upgrade[i].EquipmentPath = WrapperPath;
			`log("[DK_SWAP] Equipment:" @ OrigPath @ "->" @ WrapperPath);
		}
	}
}

// ===================================================================
// HOLLOW SKILL WEAPON UPGRADES — Auto-injection
//
// Appends all 20 Hollow skill weapon upgrades (10 base + 10 deluxe)
// to Config_WeaponUpgrade at runtime before super.InitGame().
// This means no manual INI editing is required — the upgrades are
// registered automatically whenever the package is loaded.
//
// MaxLevel=10, bIsStatic=False so they participate in the random
// upgrade slot assignment per weapon alongside vanilla upgrades.
// PriceUnit and PriceMultiplier follow the same defaults as all
// other non-static upgrades (50 / 0.15).
//
// The Deluxe variants are injected alongside their base counterparts.
// DKUI_UPGMenu.BuildWeaponUpgradeList gates visibility by skill ownership:
//   - Base upgrade shown when skill is purchased (non-deluxe).
//   - Deluxe upgrade shown when skill is purchased at Deluxe tier.
//   - Neither is shown if the player doesn't own the skill at all.
// ===================================================================

static function InjectHollowWeaponUpgrades()
{
	local Config_WeaponUpgrade.S_WeaponUpgrade NewEntry;
	local array<string> UpgradePaths;
	local int i, ExistingIdx;
	local string Path;

	// All 20 Hollow weapon upgrade paths (base then deluxe for each skill)
	UpgradePaths.AddItem("ZedternalRBPerkpackage.DKWeaponUpg_Execute");
	UpgradePaths.AddItem("ZedternalRBPerkpackage.DKWeaponUpg_Execute_Deluxe");
	UpgradePaths.AddItem("ZedternalRBPerkpackage.DKWeaponUpg_Headhunter");
	UpgradePaths.AddItem("ZedternalRBPerkpackage.DKWeaponUpg_Headhunter_Deluxe");
	UpgradePaths.AddItem("ZedternalRBPerkpackage.DKWeaponUpg_VoidInfusion");
	UpgradePaths.AddItem("ZedternalRBPerkpackage.DKWeaponUpg_VoidInfusion_Deluxe");
	UpgradePaths.AddItem("ZedternalRBPerkpackage.DKWeaponUpg_VoidSustain");
	UpgradePaths.AddItem("ZedternalRBPerkpackage.DKWeaponUpg_VoidSustain_Deluxe");
	UpgradePaths.AddItem("ZedternalRBPerkpackage.DKWeaponUpg_VoidReserves");
	UpgradePaths.AddItem("ZedternalRBPerkpackage.DKWeaponUpg_VoidReserves_Deluxe");
	UpgradePaths.AddItem("ZedternalRBPerkpackage.DKWeaponUpg_TitanSlayer");
	UpgradePaths.AddItem("ZedternalRBPerkpackage.DKWeaponUpg_TitanSlayer_Deluxe");
	UpgradePaths.AddItem("ZedternalRBPerkpackage.DKWeaponUpg_VoidSight");
	UpgradePaths.AddItem("ZedternalRBPerkpackage.DKWeaponUpg_VoidSight_Deluxe");
	UpgradePaths.AddItem("ZedternalRBPerkpackage.DKWeaponUpg_ZedTimeFocus");
	UpgradePaths.AddItem("ZedternalRBPerkpackage.DKWeaponUpg_ZedTimeFocus_Deluxe");
	UpgradePaths.AddItem("ZedternalRBPerkpackage.DKWeaponUpg_ReapersEdge");
	UpgradePaths.AddItem("ZedternalRBPerkpackage.DKWeaponUpg_ReapersEdge_Deluxe");
	UpgradePaths.AddItem("ZedternalRBPerkpackage.DKWeaponUpg_HollowCaliber");
	UpgradePaths.AddItem("ZedternalRBPerkpackage.DKWeaponUpg_HollowCaliber_Deluxe");

	for (i = 0; i < UpgradePaths.Length; ++i)
	{
		Path = UpgradePaths[i];

		// Skip if already in the list (re-entrant safety)
		ExistingIdx = class'ZedternalReborn.Config_WeaponUpgrade'.default.WeaponUpgrade_Upgrade.Find('WeaponPath', Path);
		if (ExistingIdx != INDEX_NONE)
			continue;

		// Verify the class actually exists before registering
		if (DynamicLoadObject(Path, class'Class', True) == None)
		{
			`log("[DK_HOLLOW_UPGRADES] WARNING: Could not load class" @ Path @ "- skipping");
			continue;
		}

		NewEntry.WeaponPath = Path;
		NewEntry.PriceUnit = 50;
		NewEntry.PriceMultiplier = 0.15f;
		NewEntry.MaxLevel = 10;
		NewEntry.bIsStatic = False;

		class'ZedternalReborn.Config_WeaponUpgrade'.default.WeaponUpgrade_Upgrade.AddItem(NewEntry);
		`log("[DK_HOLLOW_UPGRADES] Injected weapon upgrade:" @ Path);
	}

	`log("[DK_HOLLOW_UPGRADES] Injection complete."
		@ class'ZedternalReborn.Config_WeaponUpgrade'.default.WeaponUpgrade_Upgrade.Length
		@ "total weapon upgrade types registered.");
}

defaultproperties
{
	Name="Default__DKConfig_WrapperSwap"
}
