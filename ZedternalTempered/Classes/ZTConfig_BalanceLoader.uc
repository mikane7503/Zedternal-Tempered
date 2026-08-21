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
// MUST be called from ZTGameInfo_Endless.PreBeginPlay() AFTER Super.PreBeginPlay()
// -- ConfigData is populated there, not in InitGame.
class ZTConfig_BalanceLoader extends Object;

static function LoadAllBalanceConfigs()
{
	local WMGameInfo_Endless GI;
	local int i;
	local class<ZTUpgrade_Perk> PerkCls;
	local class<ZTUpgrade_Skill> SkillCls;

	GI = WMGameInfo_Endless(class'WorldInfo'.static.GetWorldInfo().Game);

	if (GI != None && GI.ConfigData != None)
	{
		// --- Perks (drift-proof: iterate the enabled-perk registry) ---
		for (i = 0; i < GI.ConfigData.PerkUpgObjects.Length; ++i)
		{
			PerkCls = class<ZTUpgrade_Perk>(GI.ConfigData.PerkUpgObjects[i]);
			if (PerkCls != None)
				PerkCls.static.UpdateConfig();
		}

		// --- Skills (drift-proof: iterate the enabled-skill registry) ---
		for (i = 0; i < GI.ConfigData.SkillUpgObjects.Length; ++i)
		{
			SkillCls = class<ZTUpgrade_Skill>(GI.ConfigData.SkillUpgObjects[i]);
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
	class'ZedternalTempered.ZTWeaponUpg_Damage'.static.UpdateConfig();
	class'ZedternalTempered.ZTWeaponUpg_HeadshotDamage'.static.UpdateConfig();
	class'ZedternalTempered.ZTWeaponUpg_ClotDamage'.static.UpdateConfig();
	class'ZedternalTempered.ZTWeaponUpg_FleshpoundDamage'.static.UpdateConfig();
	class'ZedternalTempered.ZTWeaponUpg_GroundFireDamage'.static.UpdateConfig();
	class'ZedternalTempered.ZTWeaponUpg_DamageResist'.static.UpdateConfig();
	class'ZedternalTempered.ZTWeaponUpg_HeavyMelee'.static.UpdateConfig();
	class'ZedternalTempered.ZTWeaponUpg_Heal'.static.UpdateConfig();
	class'ZedternalTempered.ZTWeaponUpg_SpareAmmo'.static.UpdateConfig();
	class'ZedternalTempered.ZTWeaponUpg_SpareAmmoSmall'.static.UpdateConfig();
	class'ZedternalTempered.ZTWeaponUpg_MagSize'.static.UpdateConfig();
	class'ZedternalTempered.ZTWeaponUpg_MagSizeSmall'.static.UpdateConfig();
	class'ZedternalTempered.ZTWeaponUpg_AmmoConsumption'.static.UpdateConfig();
	class'ZedternalTempered.ZTWeaponUpg_FireRate'.static.UpdateConfig();
	class'ZedternalTempered.ZTWeaponUpg_ReloadSpeed'.static.UpdateConfig();
	class'ZedternalTempered.ZTWeaponUpg_MeleeSpeed'.static.UpdateConfig();
	class'ZedternalTempered.ZTWeaponUpg_SwitchSpeed'.static.UpdateConfig();
	class'ZedternalTempered.ZTWeaponUpg_Recoil'.static.UpdateConfig();
	class'ZedternalTempered.ZTWeaponUpg_TightChoke'.static.UpdateConfig();
	class'ZedternalTempered.ZTWeaponUpg_Penetration'.static.UpdateConfig();
	class'ZedternalTempered.ZTWeaponUpg_Knockdown'.static.UpdateConfig();
	class'ZedternalTempered.ZTWeaponUpg_Stumble'.static.UpdateConfig();
	class'ZedternalTempered.ZTWeaponUpg_Stun'.static.UpdateConfig();
	class'ZedternalTempered.ZTWeaponUpg_TurretAmmo'.static.UpdateConfig();
	class'ZedternalTempered.ZTWeaponUpg_TurretLimit'.static.UpdateConfig();
	class'ZedternalTempered.ZTWeaponUpg_TurretVision'.static.UpdateConfig();

	// Hollow skill-granted weapon upgrades (not in the trader registry)
	class'ZedternalTempered.ZTWeaponUpg_Execute'.static.UpdateConfig();
	class'ZedternalTempered.ZTWeaponUpg_Execute_Deluxe'.static.UpdateConfig();
	class'ZedternalTempered.ZTWeaponUpg_Headhunter'.static.UpdateConfig();
	class'ZedternalTempered.ZTWeaponUpg_Headhunter_Deluxe'.static.UpdateConfig();
	class'ZedternalTempered.ZTWeaponUpg_VoidInfusion'.static.UpdateConfig();
	class'ZedternalTempered.ZTWeaponUpg_VoidInfusion_Deluxe'.static.UpdateConfig();
	class'ZedternalTempered.ZTWeaponUpg_VoidSustain'.static.UpdateConfig();
	class'ZedternalTempered.ZTWeaponUpg_VoidSustain_Deluxe'.static.UpdateConfig();
	class'ZedternalTempered.ZTWeaponUpg_VoidReserves'.static.UpdateConfig();
	class'ZedternalTempered.ZTWeaponUpg_VoidReserves_Deluxe'.static.UpdateConfig();
	class'ZedternalTempered.ZTWeaponUpg_TitanSlayer'.static.UpdateConfig();
	class'ZedternalTempered.ZTWeaponUpg_TitanSlayer_Deluxe'.static.UpdateConfig();
	class'ZedternalTempered.ZTWeaponUpg_VoidSight'.static.UpdateConfig();
	class'ZedternalTempered.ZTWeaponUpg_VoidSight_Deluxe'.static.UpdateConfig();
	class'ZedternalTempered.ZTWeaponUpg_ZedTimeFocus'.static.UpdateConfig();
	class'ZedternalTempered.ZTWeaponUpg_ZedTimeFocus_Deluxe'.static.UpdateConfig();
	class'ZedternalTempered.ZTWeaponUpg_ReapersEdge'.static.UpdateConfig();
	class'ZedternalTempered.ZTWeaponUpg_ReapersEdge_Deluxe'.static.UpdateConfig();
}

defaultproperties
{
	Name="Default__ZTConfig_BalanceLoader"
}
