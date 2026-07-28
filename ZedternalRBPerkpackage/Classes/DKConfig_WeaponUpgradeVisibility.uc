// ===================================================================
// DKConfig_WeaponUpgradeVisibility
//
// CLIENT-SIDE preference config for hiding weapon upgrades in the
// UPG Menu. Saved to KFZedternalRBPerkpackage_Local.ini.
//
// Each entry maps a base KF2 weapon class path to a visibility flag.
// Setting bVisible=False hides ALL upgrade entries for that weapon
// (and all its variants: Precious, Reforged, Hollow) in the UPG Menu.
//
// This is per-player only — other players are unaffected.
//
// Auto-generated on first UPG Menu open with all weapons visible.
// Players edit the INI to hide weapons they don't want to see.
// ===================================================================
class DKConfig_WeaponUpgradeVisibility extends Object
	config(ZedternalUnlimited_Local);

var config int MODEVERSION;

struct S_WeaponVisibility
{
	var string WeaponClassPath;
	var bool bVisible;

	structdefaultproperties
	{
		bVisible=True
	}
};

var config array<S_WeaponVisibility> WeaponUpgrade_Visibility;

// ===================================================================
// AUTO-GENERATION
// ===================================================================

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.WeaponUpgrade_Visibility.Length = 0;

		// ----- Pistols (Single) -----
		AddEntry("KFGameContent.KFWeap_Pistol_9mm");
		AddEntry("KFGameContent.KFWeap_Pistol_Colt1911");
		AddEntry("KFGameContent.KFWeap_Pistol_Deagle");
		AddEntry("KFGameContent.KFWeap_Pistol_AF2011");
		AddEntry("KFGameContent.KFWeap_Pistol_Bladed");
		AddEntry("KFGameContent.KFWeap_Pistol_Flare");
		AddEntry("KFGameContent.KFWeap_Pistol_G18C");
		AddEntry("KFGameContent.KFWeap_Pistol_ChiappaRhino");
		AddEntry("KFGameContent.KFWeap_Pistol_HRGWinterbite");
		AddEntry("KFGameContent.KFWeap_Pistol_HRGScorcher");
		AddEntry("KFGameContent.KFWeap_Pistol_Medic");
		AddEntry("KFGameContent.KFWeap_Pistol_Blunderbuss");

		// ----- Pistols (Dual) -----
		AddEntry("KFGameContent.KFWeap_Pistol_Dual9mm");
		AddEntry("KFGameContent.KFWeap_Pistol_DualColt1911");
		AddEntry("KFGameContent.KFWeap_Pistol_DualDeagle");
		AddEntry("KFGameContent.KFWeap_Pistol_DualAF2011");
		AddEntry("KFGameContent.KFWeap_Pistol_DualBladed");
		AddEntry("KFGameContent.KFWeap_Pistol_DualFlare");
		AddEntry("KFGameContent.KFWeap_Pistol_DualG18");
		AddEntry("KFGameContent.KFWeap_Pistol_ChiappaRhinoDual");
		AddEntry("KFGameContent.KFWeap_Pistol_DualHRGWinterbite");

		// ----- Revolvers -----
		AddEntry("KFGameContent.KFWeap_Revolver_Rem1858");
		AddEntry("KFGameContent.KFWeap_Revolver_DualRem1858");
		AddEntry("KFGameContent.KFWeap_Revolver_SW500");
		AddEntry("KFGameContent.KFWeap_Revolver_DualSW500");
		AddEntry("KFGameContent.KFWeap_HRG_Revolver_Buckshot");
		AddEntry("KFGameContent.KFWeap_HRG_Revolver_DualBuckshot");

		// ----- SMGs -----
		AddEntry("KFGameContent.KFWeap_SMG_MP7");
		AddEntry("KFGameContent.KFWeap_SMG_MP5RAS");
		AddEntry("KFGameContent.KFWeap_SMG_P90");
		AddEntry("KFGameContent.KFWeap_SMG_Kriss");
		AddEntry("KFGameContent.KFWeap_SMG_Mac10");
		AddEntry("KFGameContent.KFWeap_SMG_HK_UMP");
		AddEntry("KFGameContent.KFWeap_SMG_G18");
		AddEntry("KFGameContent.KFWeap_SMG_Medic");

		// ----- Assault Rifles -----
		AddEntry("KFGameContent.KFWeap_AssaultRifle_AK12");
		AddEntry("KFGameContent.KFWeap_AssaultRifle_AR15");
		AddEntry("KFGameContent.KFWeap_AssaultRifle_Bullpup");
		AddEntry("KFGameContent.KFWeap_AssaultRifle_FAMAS");
		AddEntry("KFGameContent.KFWeap_AssaultRifle_FNFal");
		AddEntry("KFGameContent.KFWeap_AssaultRifle_G36C");
		AddEntry("KFGameContent.KFWeap_AssaultRifle_MKB42");
		AddEntry("KFGameContent.KFWeap_AssaultRifle_SCAR");
		AddEntry("KFGameContent.KFWeap_AssaultRifle_Thompson");
		AddEntry("KFGameContent.KFWeap_AssaultRifle_M16M203");
		AddEntry("KFGameContent.KFWeap_AssaultRifle_Medic");
		AddEntry("KFGameContent.KFWeap_AssaultRifle_MedicRifleGrenadeLauncher");
		AddEntry("KFGameContent.KFWeap_AssaultRifle_Doshinegun");
		AddEntry("KFGameContent.KFWeap_AssaultRifle_LazerCutter");
		AddEntry("KFGameContent.KFWeap_AssaultRifle_Microwave");
		AddEntry("KFGameContent.KFWeap_AssaultRifle_HRGIncendiaryRifle");
		AddEntry("KFGameContent.KFWeap_AssaultRifle_HRGTeslauncher");

		// ----- LMGs -----
		AddEntry("KFGameContent.KFWeap_LMG_Stoner63A");
		AddEntry("KFGameContent.KFWeap_LMG_MG3");

		// ----- Rifles -----
		AddEntry("KFGameContent.KFWeap_Rifle_Winchester1894");
		AddEntry("KFGameContent.KFWeap_Rifle_CenterfireMB464");
		AddEntry("KFGameContent.KFWeap_Rifle_M14EBR");
		AddEntry("KFGameContent.KFWeap_Rifle_RailGun");
		AddEntry("KFGameContent.KFWeap_Rifle_M99");
		AddEntry("KFGameContent.KFWeap_Rifle_MosinNagant");
		AddEntry("KFGameContent.KFWeap_Rifle_FrostShotgunAxe");
		AddEntry("KFGameContent.KFWeap_Rifle_Hemogoblin");
		AddEntry("KFGameContent.KFWeap_Rifle_HRGIncision");
		AddEntry("KFGameContent.KFWeap_Rifle_ParasiteImplanter");

		// ----- Shotguns -----
		AddEntry("KFGameContent.KFWeap_Shotgun_MB500");
		AddEntry("KFGameContent.KFWeap_Shotgun_DoubleBarrel");
		AddEntry("KFGameContent.KFWeap_Shotgun_M4");
		AddEntry("KFGameContent.KFWeap_Shotgun_AA12");
		AddEntry("KFGameContent.KFWeap_Shotgun_HZ12");
		AddEntry("KFGameContent.KFWeap_Shotgun_S12");
		AddEntry("KFGameContent.KFWeap_Shotgun_ElephantGun");
		AddEntry("KFGameContent.KFWeap_Shotgun_DragonsBreath");
		AddEntry("KFGameContent.KFWeap_Shotgun_Nailgun");
		AddEntry("KFGameContent.KFWeap_Shotgun_Medic");
		AddEntry("KFGameContent.KFWeap_Shotgun_HRG_Kaboomstick");

		// ----- Melee (Blunt) -----
		AddEntry("KFGameContent.KFWeap_Blunt_Crovel");
		AddEntry("KFGameContent.KFWeap_Blunt_Pulverizer");
		AddEntry("KFGameContent.KFWeap_Blunt_MaceAndShield");
		AddEntry("KFGameContent.KFWeap_Blunt_PowerGloves");
		AddEntry("KFGameContent.KFWeap_Blunt_ChainBat");
		AddEntry("KFGameContent.KFWeap_Blunt_MedicBat");

		// ----- Melee (Edged) -----
		AddEntry("KFGameContent.KFWeap_Edged_Katana");
		AddEntry("KFGameContent.KFWeap_Edged_Zweihander");
		AddEntry("KFGameContent.KFWeap_Edged_FireAxe");
		AddEntry("KFGameContent.KFWeap_Edged_AbominationAxe");
		AddEntry("KFGameContent.KFWeap_Edged_Scythe");
		AddEntry("KFGameContent.KFWeap_Edged_IonThruster");

		// ----- Bows / Crossbows -----
		AddEntry("KFGameContent.KFWeap_Bow_Crossbow");
		AddEntry("KFGameContent.KFWeap_Bow_CompoundBow");
		AddEntry("KFGameContent.KFWeap_Eviscerator");

		// ----- Grenade / Rocket Launchers -----
		AddEntry("KFGameContent.KFWeap_GrenadeLauncher_HX25");
		AddEntry("KFGameContent.KFWeap_GrenadeLauncher_M79");
		AddEntry("KFGameContent.KFWeap_GrenadeLauncher_M32");
		AddEntry("KFGameContent.KFWeap_RocketLauncher_RPG7");
		AddEntry("KFGameContent.KFWeap_RocketLauncher_SealSqueal");
		AddEntry("KFGameContent.KFWeap_RocketLauncher_Seeker6");
		AddEntry("KFGameContent.KFWeap_RocketLauncher_ThermiteBore");
		AddEntry("KFGameContent.KFWeap_Thrown_C4");

		// ----- Flame -----
		AddEntry("KFGameContent.KFWeap_Flame_CaulkBurn");
		AddEntry("KFGameContent.KFWeap_Flame_Flamethrower");

		// ----- Ice -----
		AddEntry("KFGameContent.KFWeap_Ice_FreezeThrower");

		// ----- Beam -----
		AddEntry("KFGameContent.KFWeap_Beam_Microwave");

		// ----- Heavy / Special -----
		AddEntry("KFGameContent.KFWeap_Minigun");
		AddEntry("KFGameContent.KFWeap_Mine_Reconstructor");
		AddEntry("KFGameContent.KFWeap_GravityImploder");
		AddEntry("KFGameContent.KFWeap_HVStormCannon");
		AddEntry("KFGameContent.KFWeap_HuskCannon");
		AddEntry("KFGameContent.KFWeap_ShrinkRayGun");
		AddEntry("KFGameContent.KFWeap_ZedMKIII");

		// ----- HRG Weapons -----
		AddEntry("KFGameContent.KFWeap_HRG_93R");
		AddEntry("KFGameContent.KFWeap_HRG_93R_Dual");
		AddEntry("KFGameContent.KFWeap_HRG_BallisticBouncer");
		AddEntry("KFGameContent.KFWeap_HRG_BarrierRifle");
		AddEntry("KFGameContent.KFWeap_HRG_BlastBrawlers");
		AddEntry("KFGameContent.KFWeap_HRG_Boomy");
		AddEntry("KFGameContent.KFWeap_HRG_CranialPopper");
		AddEntry("KFGameContent.KFWeap_HRG_Crossboom");
		AddEntry("KFGameContent.KFWeap_HRG_Dragonbreath");
		AddEntry("KFGameContent.KFWeap_HRG_EMP_ArcGenerator");
		AddEntry("KFGameContent.KFWeap_HRG_Energy");
		AddEntry("KFGameContent.KFWeap_HRG_Healthrower");
		AddEntry("KFGameContent.KFWeap_HRG_Locust");
		AddEntry("KFGameContent.KFWeap_HRG_MedicMissile");
		AddEntry("KFGameContent.KFWeap_HRG_Nailgun");
		AddEntry("KFGameContent.KFWeap_HRG_SonicGun");
		AddEntry("KFGameContent.KFWeap_HRG_Stunner");
		AddEntry("KFGameContent.KFWeap_HRG_Vampire");
		AddEntry("KFGameContent.KFWeap_HRG_Warthog");

		// ----- Deployables -----
		AddEntry("KFGameContent.KFWeap_AutoTurret");
	}

	if (default.MODEVERSION < 1)
	{
		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

// Helper to add an entry during config generation
static function AddEntry(string Path)
{
	local S_WeaponVisibility Entry;

	Entry.WeaponClassPath = Path;
	Entry.bVisible = True;
	default.WeaponUpgrade_Visibility.AddItem(Entry);
}

// ===================================================================
// RUNTIME QUERY
//
// Loads all hidden weapon base classes (bVisible=False entries) into
// the provided output array. Uses DynamicLoadObject + ClassIsChildOf
// so hiding a base weapon also hides Precious/Reforged/Hollow variants.
//
// Called once per UPG Menu open — cached in DKUI_UPGMenu.
// ===================================================================

static function LoadHiddenWeaponClasses(out array< class<KFWeapon> > OutHiddenClasses)
{
	local int i;
	local class<KFWeapon> BaseClass;

	OutHiddenClasses.Length = 0;

	for (i = 0; i < default.WeaponUpgrade_Visibility.Length; ++i)
	{
		if (!default.WeaponUpgrade_Visibility[i].bVisible)
		{
			BaseClass = class<KFWeapon>(DynamicLoadObject(
				default.WeaponUpgrade_Visibility[i].WeaponClassPath,
				class'Class', True));

			if (BaseClass != None)
				OutHiddenClasses.AddItem(BaseClass);
		}
	}
}

defaultproperties
{
	Name="Default__DKConfig_WeaponUpgradeVisibility"
}
