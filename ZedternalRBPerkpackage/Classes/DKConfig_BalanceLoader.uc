// Seeds all DK perk/skill/weapon-upgrade balance configs on server start.
//
// Perks & skills are seeded by iterating the live ConfigData registry
// (ConfigData.PerkUpgObjects / SkillUpgObjects). This is drift-proof: every
// enabled DK perk/skill is covered automatically, so newly-added content can
// never silently seed to zero again (the bug that left MissingNO/Detonator
// passives reading 0). ZR wrapper/native classes are skipped by the cast --
// they seed through the wrapper system, not the Balance INI -- and DK perks/
// skills without their own UpdateConfig (e.g. Gambit) hit the no-op base stub
// harmlessly.
//
// Weapon upgrades remain an explicit list because the skill-granted Hollow
// upgrades (Execute, Void*, ReapersEdge, HollowCaliber, ...) are NOT part of
// the trader weapon-upgrade registry and would be missed by iteration.
//
// MUST be called from DKGameInfo_Endless.PreBeginPlay() AFTER Super.PreBeginPlay()
// -- ConfigData is populated there, not in InitGame.
class DKConfig_BalanceLoader extends Object;

static function LoadAllBalanceConfigs()
{
	local WMGameInfo_Endless GI;
	local int i;
	local class<DKUpgrade_Perk> PerkCls;
	local class<DKUpgrade_Skill> SkillCls;

	GI = WMGameInfo_Endless(class'WorldInfo'.static.GetWorldInfo().Game);

	if (GI != None && GI.ConfigData != None)
	{
		// --- Perks (drift-proof: iterate the enabled-perk registry) ---
		for (i = 0; i < GI.ConfigData.PerkUpgObjects.Length; ++i)
		{
			PerkCls = class<DKUpgrade_Perk>(GI.ConfigData.PerkUpgObjects[i]);
			if (PerkCls != None)
				PerkCls.static.UpdateConfig();
		}

		// --- Skills (drift-proof: iterate the enabled-skill registry) ---
		for (i = 0; i < GI.ConfigData.SkillUpgObjects.Length; ++i)
		{
			SkillCls = class<DKUpgrade_Skill>(GI.ConfigData.SkillUpgObjects[i]);
			if (SkillCls != None)
				SkillCls.static.UpdateConfig();
		}
	}
	else
	{
		`log("[DK_BALANCE] WARNING: ConfigData unavailable in LoadAllBalanceConfigs; perk/skill balance configs NOT seeded this boot");
	}

	// ===== Weapon Upgrades (explicit -- includes skill-granted Hollow upgrades
	//       that are not in the trader weapon-upgrade registry) =====
	class'ZedternalRBPerkpackage.DKWeaponUpg_Damage'.static.UpdateConfig();
	class'ZedternalRBPerkpackage.DKWeaponUpg_HeadshotDamage'.static.UpdateConfig();
	class'ZedternalRBPerkpackage.DKWeaponUpg_ClotDamage'.static.UpdateConfig();
	class'ZedternalRBPerkpackage.DKWeaponUpg_FleshpoundDamage'.static.UpdateConfig();
	class'ZedternalRBPerkpackage.DKWeaponUpg_GroundFireDamage'.static.UpdateConfig();
	class'ZedternalRBPerkpackage.DKWeaponUpg_DamageResist'.static.UpdateConfig();
	class'ZedternalRBPerkpackage.DKWeaponUpg_HeavyMelee'.static.UpdateConfig();
	class'ZedternalRBPerkpackage.DKWeaponUpg_Heal'.static.UpdateConfig();
	class'ZedternalRBPerkpackage.DKWeaponUpg_SpareAmmo'.static.UpdateConfig();
	class'ZedternalRBPerkpackage.DKWeaponUpg_SpareAmmoSmall'.static.UpdateConfig();
	class'ZedternalRBPerkpackage.DKWeaponUpg_MagSize'.static.UpdateConfig();
	class'ZedternalRBPerkpackage.DKWeaponUpg_MagSizeSmall'.static.UpdateConfig();
	class'ZedternalRBPerkpackage.DKWeaponUpg_AmmoConsumption'.static.UpdateConfig();
	class'ZedternalRBPerkpackage.DKWeaponUpg_FireRate'.static.UpdateConfig();
	class'ZedternalRBPerkpackage.DKWeaponUpg_ReloadSpeed'.static.UpdateConfig();
	class'ZedternalRBPerkpackage.DKWeaponUpg_MeleeSpeed'.static.UpdateConfig();
	class'ZedternalRBPerkpackage.DKWeaponUpg_SwitchSpeed'.static.UpdateConfig();
	class'ZedternalRBPerkpackage.DKWeaponUpg_Recoil'.static.UpdateConfig();
	class'ZedternalRBPerkpackage.DKWeaponUpg_TightChoke'.static.UpdateConfig();
	class'ZedternalRBPerkpackage.DKWeaponUpg_Penetration'.static.UpdateConfig();
	class'ZedternalRBPerkpackage.DKWeaponUpg_Knockdown'.static.UpdateConfig();
	class'ZedternalRBPerkpackage.DKWeaponUpg_Stumble'.static.UpdateConfig();
	class'ZedternalRBPerkpackage.DKWeaponUpg_Stun'.static.UpdateConfig();
	class'ZedternalRBPerkpackage.DKWeaponUpg_TurretAmmo'.static.UpdateConfig();
	class'ZedternalRBPerkpackage.DKWeaponUpg_TurretLimit'.static.UpdateConfig();
	class'ZedternalRBPerkpackage.DKWeaponUpg_TurretVision'.static.UpdateConfig();

	// Hollow skill-granted weapon upgrades (not in the trader registry)
	class'ZedternalRBPerkpackage.DKWeaponUpg_Execute'.static.UpdateConfig();
	class'ZedternalRBPerkpackage.DKWeaponUpg_Execute_Deluxe'.static.UpdateConfig();
	class'ZedternalRBPerkpackage.DKWeaponUpg_Headhunter'.static.UpdateConfig();
	class'ZedternalRBPerkpackage.DKWeaponUpg_Headhunter_Deluxe'.static.UpdateConfig();
	class'ZedternalRBPerkpackage.DKWeaponUpg_VoidInfusion'.static.UpdateConfig();
	class'ZedternalRBPerkpackage.DKWeaponUpg_VoidInfusion_Deluxe'.static.UpdateConfig();
	class'ZedternalRBPerkpackage.DKWeaponUpg_VoidSustain'.static.UpdateConfig();
	class'ZedternalRBPerkpackage.DKWeaponUpg_VoidSustain_Deluxe'.static.UpdateConfig();
	class'ZedternalRBPerkpackage.DKWeaponUpg_VoidReserves'.static.UpdateConfig();
	class'ZedternalRBPerkpackage.DKWeaponUpg_VoidReserves_Deluxe'.static.UpdateConfig();
	class'ZedternalRBPerkpackage.DKWeaponUpg_TitanSlayer'.static.UpdateConfig();
	class'ZedternalRBPerkpackage.DKWeaponUpg_TitanSlayer_Deluxe'.static.UpdateConfig();
	class'ZedternalRBPerkpackage.DKWeaponUpg_VoidSight'.static.UpdateConfig();
	class'ZedternalRBPerkpackage.DKWeaponUpg_VoidSight_Deluxe'.static.UpdateConfig();
	class'ZedternalRBPerkpackage.DKWeaponUpg_ZedTimeFocus'.static.UpdateConfig();
	class'ZedternalRBPerkpackage.DKWeaponUpg_ZedTimeFocus_Deluxe'.static.UpdateConfig();
	class'ZedternalRBPerkpackage.DKWeaponUpg_ReapersEdge'.static.UpdateConfig();
	class'ZedternalRBPerkpackage.DKWeaponUpg_ReapersEdge_Deluxe'.static.UpdateConfig();
	class'ZedternalRBPerkpackage.DKWeaponUpg_HollowCaliber'.static.UpdateConfig();
	class'ZedternalRBPerkpackage.DKWeaponUpg_HollowCaliber_Deluxe'.static.UpdateConfig();
}

defaultproperties
{
	Name="Default__DKConfig_BalanceLoader"
}
