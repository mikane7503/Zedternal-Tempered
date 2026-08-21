class Config_WeaponVariant extends Config_Common
	config(ZedternalReborn_Weapons);

var config int MODEVERSION;

var config bool WeaponVariant_bAllowWeaponVariant; //Allow weapon variants

struct S_Variant
{
	var string WeaponDef;
	var string WeaponDefVariant;
	var string DualWeaponDefVariant;
	var float Probability;

	structdefaultproperties
	{
		DualWeaponDefVariant=""
		Probability=0.05f
	}
};
var config array<S_Variant> Weapon_VariantWeaponDef; //List of weapon variants

static function UpdateConfig()
{
	local S_Variant NewVariant;

	if (default.MODEVERSION < 1)
	{
		default.WeaponVariant_bAllowWeaponVariant = True;

		default.Weapon_VariantWeaponDef.Length = 97;
		default.Weapon_VariantWeaponDef[0].WeaponDef = "KFGame.KFWeapDef_AA12";
		default.Weapon_VariantWeaponDef[0].WeaponDefVariant = "ZedternalReborn.WMWeapDef_AA12_Precious";
		default.Weapon_VariantWeaponDef[1].WeaponDef = "KFGame.KFWeapDef_AbominationAxe";
		default.Weapon_VariantWeaponDef[1].WeaponDefVariant = "ZedternalReborn.WMWeapDef_AbominationAxe_Precious";
		default.Weapon_VariantWeaponDef[2].WeaponDef = "KFGame.KFWeapDef_AF2011";
		default.Weapon_VariantWeaponDef[2].WeaponDefVariant = "ZedternalReborn.WMWeapDef_AF2011_Precious";
		default.Weapon_VariantWeaponDef[2].DualWeaponDefVariant = "ZedternalReborn.WMWeapDef_AF2011Dual_Precious";
		default.Weapon_VariantWeaponDef[3].WeaponDef = "KFGame.KFWeapDef_AK12";
		default.Weapon_VariantWeaponDef[3].WeaponDefVariant = "ZedternalReborn.WMWeapDef_AK12_Precious";
		default.Weapon_VariantWeaponDef[4].WeaponDef = "KFGame.KFWeapDef_AR15";
		default.Weapon_VariantWeaponDef[4].WeaponDefVariant = "ZedternalReborn.WMWeapDef_AR15_Precious";
		default.Weapon_VariantWeaponDef[5].WeaponDef = "KFGame.KFWeapDef_BladedPistol";
		default.Weapon_VariantWeaponDef[5].WeaponDefVariant = "ZedternalReborn.WMWeapDef_BladedPistol_Precious";
		default.Weapon_VariantWeaponDef[5].DualWeaponDefVariant = "ZedternalReborn.WMWeapDef_DualBladed_Precious";
		default.Weapon_VariantWeaponDef[6].WeaponDef = "KFGame.KFWeapDef_Blunderbuss";
		default.Weapon_VariantWeaponDef[6].WeaponDefVariant = "ZedternalReborn.WMWeapDef_Blunderbuss_Precious";
		default.Weapon_VariantWeaponDef[7].WeaponDef = "KFGame.KFWeapDef_Bullpup";
		default.Weapon_VariantWeaponDef[7].WeaponDefVariant = "ZedternalReborn.WMWeapDef_Bullpup_Precious";
		default.Weapon_VariantWeaponDef[8].WeaponDef = "KFGame.KFWeapDef_C4";
		default.Weapon_VariantWeaponDef[8].WeaponDefVariant = "ZedternalReborn.WMWeapDef_C4_Precious";
		default.Weapon_VariantWeaponDef[9].WeaponDef = "KFGame.KFWeapDef_CaulkBurn";
		default.Weapon_VariantWeaponDef[9].WeaponDefVariant = "ZedternalReborn.WMWeapDef_CaulkBurn_Precious";
		default.Weapon_VariantWeaponDef[10].WeaponDef = "KFGame.KFWeapDef_CenterfireMB464";
		default.Weapon_VariantWeaponDef[10].WeaponDefVariant = "ZedternalReborn.WMWeapDef_CenterfireMB464_Precious";
		default.Weapon_VariantWeaponDef[11].WeaponDef = "KFGame.KFWeapDef_ChainBat";
		default.Weapon_VariantWeaponDef[11].WeaponDefVariant = "ZedternalReborn.WMWeapDef_ChainBat_Precious";
		default.Weapon_VariantWeaponDef[12].WeaponDef = "KFGame.KFWeapDef_ChiappaRhino";
		default.Weapon_VariantWeaponDef[12].WeaponDefVariant = "ZedternalReborn.WMWeapDef_ChiappaRhino_Precious";
		default.Weapon_VariantWeaponDef[12].DualWeaponDefVariant = "ZedternalReborn.WMWeapDef_ChiappaRhinoDual_Precious";
		default.Weapon_VariantWeaponDef[13].WeaponDef = "KFGame.KFWeapDef_Colt1911";
		default.Weapon_VariantWeaponDef[13].WeaponDefVariant = "ZedternalReborn.WMWeapDef_Colt1911_Precious";
		default.Weapon_VariantWeaponDef[13].DualWeaponDefVariant = "ZedternalReborn.WMWeapDef_Colt1911Dual_Precious";
		default.Weapon_VariantWeaponDef[14].WeaponDef = "KFGame.KFWeapDef_CompoundBow";
		default.Weapon_VariantWeaponDef[14].WeaponDefVariant = "ZedternalReborn.WMWeapDef_CompoundBow_Precious";
		default.Weapon_VariantWeaponDef[15].WeaponDef = "KFGame.KFWeapDef_Crossbow";
		default.Weapon_VariantWeaponDef[15].WeaponDefVariant = "ZedternalReborn.WMWeapDef_Crossbow_Precious";
		default.Weapon_VariantWeaponDef[16].WeaponDef = "KFGame.KFWeapDef_Crovel";
		default.Weapon_VariantWeaponDef[16].WeaponDefVariant = "ZedternalReborn.WMWeapDef_Crovel_Precious";
		default.Weapon_VariantWeaponDef[17].WeaponDef = "KFGame.KFWeapDef_Deagle";
		default.Weapon_VariantWeaponDef[17].WeaponDefVariant = "ZedternalReborn.WMWeapDef_Deagle_Precious";
		default.Weapon_VariantWeaponDef[17].DualWeaponDefVariant = "ZedternalReborn.WMWeapDef_DeagleDual_Precious";
		default.Weapon_VariantWeaponDef[18].WeaponDef = "KFGame.KFWeapDef_DoubleBarrel";
		default.Weapon_VariantWeaponDef[18].WeaponDefVariant = "ZedternalReborn.WMWeapDef_DoubleBarrel_Precious";
		default.Weapon_VariantWeaponDef[19].WeaponDef = "KFGame.KFWeapDef_DragonsBreath";
		default.Weapon_VariantWeaponDef[19].WeaponDefVariant = "ZedternalReborn.WMWeapDef_DragonsBreath_Precious";
		default.Weapon_VariantWeaponDef[20].WeaponDef = "KFGame.KFWeapDef_ElephantGun";
		default.Weapon_VariantWeaponDef[20].WeaponDefVariant = "ZedternalReborn.WMWeapDef_ElephantGun_Precious";
		default.Weapon_VariantWeaponDef[21].WeaponDef = "KFGame.KFWeapDef_Eviscerator";
		default.Weapon_VariantWeaponDef[21].WeaponDefVariant = "ZedternalReborn.WMWeapDef_Eviscerator_Precious";
		default.Weapon_VariantWeaponDef[22].WeaponDef = "KFGame.KFWeapDef_FAMAS";
		default.Weapon_VariantWeaponDef[22].WeaponDefVariant = "ZedternalReborn.WMWeapDef_FAMAS_Precious";
		default.Weapon_VariantWeaponDef[23].WeaponDef = "KFGame.KFWeapDef_FireAxe";
		default.Weapon_VariantWeaponDef[23].WeaponDefVariant = "ZedternalReborn.WMWeapDef_FireAxe_Precious";
		default.Weapon_VariantWeaponDef[24].WeaponDef = "KFGame.KFWeapDef_FlameThrower";
		default.Weapon_VariantWeaponDef[24].WeaponDefVariant = "ZedternalReborn.WMWeapDef_FlameThrower_Precious";
		default.Weapon_VariantWeaponDef[25].WeaponDef = "KFGame.KFWeapDef_FlareGun";
		default.Weapon_VariantWeaponDef[25].WeaponDefVariant = "ZedternalReborn.WMWeapDef_FlareGun_Precious";
		default.Weapon_VariantWeaponDef[25].DualWeaponDefVariant = "ZedternalReborn.WMWeapDef_FlareGunDual_Precious";
		default.Weapon_VariantWeaponDef[26].WeaponDef = "KFGame.KFWeapDef_FNFal";
		default.Weapon_VariantWeaponDef[26].WeaponDefVariant = "ZedternalReborn.WMWeapDef_FNFal_Precious";
		default.Weapon_VariantWeaponDef[27].WeaponDef = "KFGame.KFWeapDef_FreezeThrower";
		default.Weapon_VariantWeaponDef[27].WeaponDefVariant = "ZedternalReborn.WMWeapDef_FreezeThrower_Precious";
		default.Weapon_VariantWeaponDef[28].WeaponDef = "KFGame.KFWeapDef_G18";
		default.Weapon_VariantWeaponDef[28].WeaponDefVariant = "ZedternalReborn.WMWeapDef_G18_Precious";
		default.Weapon_VariantWeaponDef[29].WeaponDef = "KFGame.KFWeapDef_GravityImploder";
		default.Weapon_VariantWeaponDef[29].WeaponDefVariant = "ZedternalReborn.WMWeapDef_GravityImploder_Precious";
		default.Weapon_VariantWeaponDef[30].WeaponDef = "KFGame.KFWeapDef_Healthrower_HRG";
		default.Weapon_VariantWeaponDef[30].WeaponDefVariant = "ZedternalReborn.WMWeapDef_Healthrower_HRG_Precious";
		default.Weapon_VariantWeaponDef[31].WeaponDef = "KFGame.KFWeapDef_Hemogoblin";
		default.Weapon_VariantWeaponDef[31].WeaponDefVariant = "ZedternalReborn.WMWeapDef_Hemogoblin_Precious";
		default.Weapon_VariantWeaponDef[32].WeaponDef = "KFGame.KFWeapDef_HK_UMP";
		default.Weapon_VariantWeaponDef[32].WeaponDefVariant = "ZedternalReborn.WMWeapDef_HK_UMP_Precious";
		default.Weapon_VariantWeaponDef[33].WeaponDef = "KFGame.KFWeapDef_HRG_BarrierRifle";
		default.Weapon_VariantWeaponDef[33].WeaponDefVariant = "ZedternalReborn.WMWeapDef_HRG_BarrierRifle_Precious";
		default.Weapon_VariantWeaponDef[34].WeaponDef = "KFGame.KFWeapDef_HRG_BlastBrawlers";
		default.Weapon_VariantWeaponDef[34].WeaponDefVariant = "ZedternalReborn.WMWeapDef_HRG_BlastBrawlers_Precious";
		default.Weapon_VariantWeaponDef[35].WeaponDef = "KFGame.KFWeapDef_HRG_Boomy";
		default.Weapon_VariantWeaponDef[35].WeaponDefVariant = "ZedternalReborn.WMWeapDef_HRG_Boomy_Precious";
		default.Weapon_VariantWeaponDef[36].WeaponDef = "KFGame.KFWeapDef_HRG_EMP_ArcGenerator";
		default.Weapon_VariantWeaponDef[36].WeaponDefVariant = "ZedternalReborn.WMWeapDef_HRG_EMP_ArcGenerator_Precious";
		default.Weapon_VariantWeaponDef[37].WeaponDef = "KFGame.KFWeapDef_HRG_Energy";
		default.Weapon_VariantWeaponDef[37].WeaponDefVariant = "ZedternalReborn.WMWeapDef_HRG_Energy_Precious";
		default.Weapon_VariantWeaponDef[38].WeaponDef = "KFGame.KFWeapDef_HRGIncendiaryRifle";
		default.Weapon_VariantWeaponDef[38].WeaponDefVariant = "ZedternalReborn.WMWeapDef_HRGIncendiaryRifle_Precious";
		default.Weapon_VariantWeaponDef[39].WeaponDef = "KFGame.KFWeapDef_HRGIncision";
		default.Weapon_VariantWeaponDef[39].WeaponDefVariant = "ZedternalReborn.WMWeapDef_HRGIncision_Precious";
		default.Weapon_VariantWeaponDef[40].WeaponDef = "KFGame.KFWeapDef_HRG_Kaboomstick";
		default.Weapon_VariantWeaponDef[40].WeaponDefVariant = "ZedternalReborn.WMWeapDef_HRG_Kaboomstick_Precious";
		default.Weapon_VariantWeaponDef[41].WeaponDef = "KFGame.KFWeapDef_HRGScorcher";
		default.Weapon_VariantWeaponDef[41].WeaponDefVariant = "ZedternalReborn.WMWeapDef_HRGScorcher_Precious";
		default.Weapon_VariantWeaponDef[42].WeaponDef = "KFGame.KFWeapDef_HRG_SonicGun";
		default.Weapon_VariantWeaponDef[42].WeaponDefVariant = "ZedternalReborn.WMWeapDef_HRG_SonicGun_Precious";
		default.Weapon_VariantWeaponDef[43].WeaponDef = "KFGame.KFWeapDef_HRGTeslauncher";
		default.Weapon_VariantWeaponDef[43].WeaponDefVariant = "ZedternalReborn.WMWeapDef_HRGTeslauncher_Precious";
		default.Weapon_VariantWeaponDef[44].WeaponDef = "KFGame.KFWeapDef_HRG_Vampire";
		default.Weapon_VariantWeaponDef[44].WeaponDefVariant = "ZedternalReborn.WMWeapDef_HRG_Vampire_Precious";
		default.Weapon_VariantWeaponDef[45].WeaponDef = "KFGame.KFWeapDef_HRGWinterbite";
		default.Weapon_VariantWeaponDef[45].WeaponDefVariant = "ZedternalReborn.WMWeapDef_HRGWinterbite_Precious";
		default.Weapon_VariantWeaponDef[45].DualWeaponDefVariant = "ZedternalReborn.WMWeapDef_HRGWinterbiteDual_Precious";
		default.Weapon_VariantWeaponDef[46].WeaponDef = "KFGame.KFWeapDef_HuskCannon";
		default.Weapon_VariantWeaponDef[46].WeaponDefVariant = "ZedternalReborn.WMWeapDef_HuskCannon_Precious";
		default.Weapon_VariantWeaponDef[47].WeaponDef = "KFGame.KFWeapDef_HX25";
		default.Weapon_VariantWeaponDef[47].WeaponDefVariant = "ZedternalReborn.WMWeapDef_HX25_Precious";
		default.Weapon_VariantWeaponDef[48].WeaponDef = "KFGame.KFWeapDef_HZ12";
		default.Weapon_VariantWeaponDef[48].WeaponDefVariant = "ZedternalReborn.WMWeapDef_HZ12_Precious";
		default.Weapon_VariantWeaponDef[49].WeaponDef = "KFGame.KFWeapDef_IonThruster";
		default.Weapon_VariantWeaponDef[49].WeaponDefVariant = "ZedternalReborn.WMWeapDef_IonThruster_Precious";
		default.Weapon_VariantWeaponDef[50].WeaponDef = "KFGame.KFWeapDef_Katana";
		default.Weapon_VariantWeaponDef[50].WeaponDefVariant = "ZedternalReborn.WMWeapDef_Katana_Precious";
		default.Weapon_VariantWeaponDef[51].WeaponDef = "KFGame.KFWeapDef_Kriss";
		default.Weapon_VariantWeaponDef[51].WeaponDefVariant = "ZedternalReborn.WMWeapDef_Kriss_Precious";
		default.Weapon_VariantWeaponDef[52].WeaponDef = "KFGame.KFWeapDef_LazerCutter";
		default.Weapon_VariantWeaponDef[52].WeaponDefVariant = "ZedternalReborn.WMWeapDef_LazerCutter_Precious";
		default.Weapon_VariantWeaponDef[53].WeaponDef = "KFGame.KFWeapDef_M4";
		default.Weapon_VariantWeaponDef[53].WeaponDefVariant = "ZedternalReborn.WMWeapDef_M4_Precious";
		default.Weapon_VariantWeaponDef[54].WeaponDef = "KFGame.KFWeapDef_M14EBR";
		default.Weapon_VariantWeaponDef[54].WeaponDefVariant = "ZedternalReborn.WMWeapDef_M14EBR_Precious";
		default.Weapon_VariantWeaponDef[55].WeaponDef = "KFGame.KFWeapDef_M16M203";
		default.Weapon_VariantWeaponDef[55].WeaponDefVariant = "ZedternalReborn.WMWeapDef_M16M203_Precious";
		default.Weapon_VariantWeaponDef[56].WeaponDef = "KFGame.KFWeapDef_M32";
		default.Weapon_VariantWeaponDef[56].WeaponDefVariant = "ZedternalReborn.WMWeapDef_M32_Precious";
		default.Weapon_VariantWeaponDef[57].WeaponDef = "KFGame.KFWeapDef_M79";
		default.Weapon_VariantWeaponDef[57].WeaponDefVariant = "ZedternalReborn.WMWeapDef_M79_Precious";
		default.Weapon_VariantWeaponDef[58].WeaponDef = "KFGame.KFWeapDef_M99";
		default.Weapon_VariantWeaponDef[58].WeaponDefVariant = "ZedternalReborn.WMWeapDef_M99_Precious";
		default.Weapon_VariantWeaponDef[59].WeaponDef = "KFGame.KFWeapDef_Mac10";
		default.Weapon_VariantWeaponDef[59].WeaponDefVariant = "ZedternalReborn.WMWeapDef_Mac10_Precious";
		default.Weapon_VariantWeaponDef[60].WeaponDef = "KFGame.KFWeapDef_MaceAndShield";
		default.Weapon_VariantWeaponDef[60].WeaponDefVariant = "ZedternalReborn.WMWeapDef_MaceAndShield_Precious";
		default.Weapon_VariantWeaponDef[61].WeaponDef = "KFGame.KFWeapDef_MB500";
		default.Weapon_VariantWeaponDef[61].WeaponDefVariant = "ZedternalReborn.WMWeapDef_MB500_Precious";
		default.Weapon_VariantWeaponDef[62].WeaponDef = "KFGame.KFWeapDef_MedicBat";
		default.Weapon_VariantWeaponDef[62].WeaponDefVariant = "ZedternalReborn.WMWeapDef_MedicBat_Precious";
		default.Weapon_VariantWeaponDef[63].WeaponDef = "KFGame.KFWeapDef_MedicPistol";
		default.Weapon_VariantWeaponDef[63].WeaponDefVariant = "ZedternalReborn.WMWeapDef_MedicPistol_Precious";
		default.Weapon_VariantWeaponDef[64].WeaponDef = "KFGame.KFWeapDef_MedicRifle";
		default.Weapon_VariantWeaponDef[64].WeaponDefVariant = "ZedternalReborn.WMWeapDef_MedicRifle_Precious";
		default.Weapon_VariantWeaponDef[65].WeaponDef = "KFGame.KFWeapDef_MedicRifleGrenadeLauncher";
		default.Weapon_VariantWeaponDef[65].WeaponDefVariant = "ZedternalReborn.WMWeapDef_MedicRifleGrenadeLauncher_Precious";
		default.Weapon_VariantWeaponDef[66].WeaponDef = "KFGame.KFWeapDef_MedicShotgun";
		default.Weapon_VariantWeaponDef[66].WeaponDefVariant = "ZedternalReborn.WMWeapDef_MedicShotgun_Precious";
		default.Weapon_VariantWeaponDef[67].WeaponDef = "KFGame.KFWeapDef_MedicSMG";
		default.Weapon_VariantWeaponDef[67].WeaponDefVariant = "ZedternalReborn.WMWeapDef_MedicSMG_Precious";
		default.Weapon_VariantWeaponDef[68].WeaponDef = "KFGame.KFWeapDef_MicrowaveGun";
		default.Weapon_VariantWeaponDef[68].WeaponDefVariant = "ZedternalReborn.WMWeapDef_MicrowaveGun_Precious";
		default.Weapon_VariantWeaponDef[69].WeaponDef = "KFGame.KFWeapDef_MicrowaveRifle";
		default.Weapon_VariantWeaponDef[69].WeaponDefVariant = "ZedternalReborn.WMWeapDef_MicrowaveRifle_Precious";
		default.Weapon_VariantWeaponDef[70].WeaponDef = "KFGame.KFWeapDef_Mine_Reconstructor";
		default.Weapon_VariantWeaponDef[70].WeaponDefVariant = "ZedternalReborn.WMWeapDef_Mine_Reconstructor_Precious";
		default.Weapon_VariantWeaponDef[71].WeaponDef = "KFGame.KFWeapDef_Minigun";
		default.Weapon_VariantWeaponDef[71].WeaponDefVariant = "ZedternalReborn.WMWeapDef_Minigun_Precious";
		default.Weapon_VariantWeaponDef[72].WeaponDef = "KFGame.KFWeapDef_MKB42";
		default.Weapon_VariantWeaponDef[72].WeaponDefVariant = "ZedternalReborn.WMWeapDef_MKB42_Precious";
		default.Weapon_VariantWeaponDef[73].WeaponDef = "KFGame.KFWeapDef_MosinNagant";
		default.Weapon_VariantWeaponDef[73].WeaponDefVariant = "ZedternalReborn.WMWeapDef_MosinNagant_Precious";
		default.Weapon_VariantWeaponDef[74].WeaponDef = "KFGame.KFWeapDef_MP5RAS";
		default.Weapon_VariantWeaponDef[74].WeaponDefVariant = "ZedternalReborn.WMWeapDef_MP5RAS_Precious";
		default.Weapon_VariantWeaponDef[75].WeaponDef = "KFGame.KFWeapDef_MP7";
		default.Weapon_VariantWeaponDef[75].WeaponDefVariant = "ZedternalReborn.WMWeapDef_MP7_Precious";
		default.Weapon_VariantWeaponDef[76].WeaponDef = "KFGame.KFWeapDef_Nailgun";
		default.Weapon_VariantWeaponDef[76].WeaponDefVariant = "ZedternalReborn.WMWeapDef_Nailgun_Precious";
		default.Weapon_VariantWeaponDef[77].WeaponDef = "KFGame.KFWeapDef_Nailgun_HRG";
		default.Weapon_VariantWeaponDef[77].WeaponDefVariant = "ZedternalReborn.WMWeapDef_Nailgun_HRG_Precious";
		default.Weapon_VariantWeaponDef[78].WeaponDef = "KFGame.KFWeapDef_P90";
		default.Weapon_VariantWeaponDef[78].WeaponDefVariant = "ZedternalReborn.WMWeapDef_P90_Precious";
		default.Weapon_VariantWeaponDef[79].WeaponDef = "KFGame.KFWeapDef_ParasiteImplanter";
		default.Weapon_VariantWeaponDef[79].WeaponDefVariant = "ZedternalReborn.WMWeapDef_ParasiteImplanter_Precious";
		default.Weapon_VariantWeaponDef[80].WeaponDef = "KFGame.KFWeapDef_Pistol_G18C";
		default.Weapon_VariantWeaponDef[80].WeaponDefVariant = "ZedternalReborn.WMWeapDef_Pistol_G18C_Precious";
		default.Weapon_VariantWeaponDef[80].DualWeaponDefVariant = "ZedternalReborn.WMWeapDef_Pistol_DualG18_Precious";
		default.Weapon_VariantWeaponDef[81].WeaponDef = "KFGame.KFWeapDef_PowerGloves";
		default.Weapon_VariantWeaponDef[81].WeaponDefVariant = "ZedternalReborn.WMWeapDef_PowerGloves_Precious";
		default.Weapon_VariantWeaponDef[82].WeaponDef = "KFGame.KFWeapDef_Pulverizer";
		default.Weapon_VariantWeaponDef[82].WeaponDefVariant = "ZedternalReborn.WMWeapDef_Pulverizer_Precious";
		default.Weapon_VariantWeaponDef[83].WeaponDef = "KFGame.KFWeapDef_RailGun";
		default.Weapon_VariantWeaponDef[83].WeaponDefVariant = "ZedternalReborn.WMWeapDef_RailGun_Precious";
		default.Weapon_VariantWeaponDef[84].WeaponDef = "KFGame.KFWeapDef_Remington1858";
		default.Weapon_VariantWeaponDef[84].WeaponDefVariant = "ZedternalReborn.WMWeapDef_Remington1858_Precious";
		default.Weapon_VariantWeaponDef[84].DualWeaponDefVariant = "ZedternalReborn.WMWeapDef_Remington1858Dual_Precious";
		default.Weapon_VariantWeaponDef[85].WeaponDef = "KFGame.KFWeapDef_Rifle_FrostShotgunAxe";
		default.Weapon_VariantWeaponDef[85].WeaponDefVariant = "ZedternalReborn.WMWeapDef_Rifle_FrostShotgunAxe_Precious";
		default.Weapon_VariantWeaponDef[86].WeaponDef = "KFGame.KFWeapDef_RPG7";
		default.Weapon_VariantWeaponDef[86].WeaponDefVariant = "ZedternalReborn.WMWeapDef_RPG7_Precious";
		default.Weapon_VariantWeaponDef[87].WeaponDef = "KFGame.KFWeapDef_SCAR";
		default.Weapon_VariantWeaponDef[87].WeaponDefVariant = "ZedternalReborn.WMWeapDef_SCAR_Precious";
		default.Weapon_VariantWeaponDef[88].WeaponDef = "KFGame.KFWeapDef_SealSqueal";
		default.Weapon_VariantWeaponDef[88].WeaponDefVariant = "ZedternalReborn.WMWeapDef_SealSqueal_Precious";
		default.Weapon_VariantWeaponDef[89].WeaponDef = "KFGame.KFWeapDef_Seeker6";
		default.Weapon_VariantWeaponDef[89].WeaponDefVariant = "ZedternalReborn.WMWeapDef_Seeker6_Precious";
		default.Weapon_VariantWeaponDef[90].WeaponDef = "KFGame.KFWeapDef_Stoner63A";
		default.Weapon_VariantWeaponDef[90].WeaponDefVariant = "ZedternalReborn.WMWeapDef_Stoner63A_Precious";
		default.Weapon_VariantWeaponDef[91].WeaponDef = "KFGame.KFWeapDef_SW500";
		default.Weapon_VariantWeaponDef[91].WeaponDefVariant = "ZedternalReborn.WMWeapDef_SW500_Precious";
		default.Weapon_VariantWeaponDef[91].DualWeaponDefVariant = "ZedternalReborn.WMWeapDef_SW500Dual_Precious";
		default.Weapon_VariantWeaponDef[92].WeaponDef = "KFGame.KFWeapDef_SW500_HRG";
		default.Weapon_VariantWeaponDef[92].WeaponDefVariant = "ZedternalReborn.WMWeapDef_SW500_HRG_Precious";
		default.Weapon_VariantWeaponDef[92].DualWeaponDefVariant = "ZedternalReborn.WMWeapDef_SW500Dual_HRG_Precious";
		default.Weapon_VariantWeaponDef[93].WeaponDef = "KFGame.KFWeapDef_ThermiteBore";
		default.Weapon_VariantWeaponDef[93].WeaponDefVariant = "ZedternalReborn.WMWeapDef_ThermiteBore_Precious";
		default.Weapon_VariantWeaponDef[94].WeaponDef = "KFGame.KFWeapDef_Thompson";
		default.Weapon_VariantWeaponDef[94].WeaponDefVariant = "ZedternalReborn.WMWeapDef_Thompson_Precious";
		default.Weapon_VariantWeaponDef[95].WeaponDef = "KFGame.KFWeapDef_Winchester1894";
		default.Weapon_VariantWeaponDef[95].WeaponDefVariant = "ZedternalReborn.WMWeapDef_Winchester1894_Precious";
		default.Weapon_VariantWeaponDef[96].WeaponDef = "KFGame.KFWeapDef_Zweihander";
		default.Weapon_VariantWeaponDef[96].WeaponDefVariant = "ZedternalReborn.WMWeapDef_Zweihander_Precious";
	}

	if (default.MODEVERSION < 11)
	{
		NewVariant.WeaponDef = "KFGame.KFWeapDef_HRG_Stunner";
		NewVariant.WeaponDefVariant = "ZedternalReborn.WMWeapDef_HRG_Stunner_Precious";
		default.Weapon_VariantWeaponDef.AddItem(NewVariant);

		NewVariant.WeaponDef = "KFGame.KFWeapDef_Doshinegun";
		NewVariant.WeaponDefVariant = "ZedternalReborn.WMWeapDef_Doshinegun_Precious";
		default.Weapon_VariantWeaponDef.AddItem(NewVariant);
	}

	if (default.MODEVERSION < 13)
	{
		NewVariant.WeaponDef = "KFGame.KFWeapDef_HRG_CranialPopper";
		NewVariant.WeaponDefVariant = "ZedternalReborn.WMWeapDef_HRG_CranialPopper_Precious";
		default.Weapon_VariantWeaponDef.AddItem(NewVariant);

		NewVariant.WeaponDef = "KFGame.KFWeapDef_HRG_Crossboom";
		NewVariant.WeaponDefVariant = "ZedternalReborn.WMWeapDef_HRG_Crossboom_Precious";
		default.Weapon_VariantWeaponDef.AddItem(NewVariant);

		NewVariant.WeaponDef = "KFGame.KFWeapDef_ShrinkRayGun";
		NewVariant.WeaponDefVariant = "ZedternalReborn.WMWeapDef_ShrinkRayGun_Precious";
		default.Weapon_VariantWeaponDef.AddItem(NewVariant);

		NewVariant.WeaponDef = "KFGame.KFWeapDef_AutoTurret";
		NewVariant.WeaponDefVariant = "ZedternalReborn.WMWeapDef_AutoTurret_Precious";
		default.Weapon_VariantWeaponDef.AddItem(NewVariant);
	}

	if (default.MODEVERSION < 14)
	{
		NewVariant.WeaponDef = "KFGame.KFWeapDef_G36C";
		NewVariant.WeaponDefVariant = "ZedternalReborn.WMWeapDef_G36C_Precious";
		default.Weapon_VariantWeaponDef.AddItem(NewVariant);

		NewVariant.WeaponDef = "KFGame.KFWeapDef_HRG_Dragonbreath";
		NewVariant.WeaponDefVariant = "ZedternalReborn.WMWeapDef_HRG_Dragonbreath_Precious";
		default.Weapon_VariantWeaponDef.AddItem(NewVariant);

		NewVariant.WeaponDef = "KFGame.KFWeapDef_HRG_Locust";
		NewVariant.WeaponDefVariant = "ZedternalReborn.WMWeapDef_HRG_Locust_Precious";
		default.Weapon_VariantWeaponDef.AddItem(NewVariant);

		NewVariant.WeaponDef = "KFGame.KFWeapDef_Scythe";
		NewVariant.WeaponDefVariant = "ZedternalReborn.WMWeapDef_Scythe_Precious";
		default.Weapon_VariantWeaponDef.AddItem(NewVariant);
	}

	if (default.MODEVERSION < 15)
	{
		NewVariant.WeaponDef = "KFGame.KFWeapDef_HRG_BallisticBouncer";
		NewVariant.WeaponDefVariant = "ZedternalReborn.WMWeapDef_HRG_BallisticBouncer_Precious";
		default.Weapon_VariantWeaponDef.AddItem(NewVariant);

		NewVariant.WeaponDef = "KFGame.KFWeapDef_HRG_MedicMissile";
		NewVariant.WeaponDefVariant = "ZedternalReborn.WMWeapDef_HRG_MedicMissile_Precious";
		default.Weapon_VariantWeaponDef.AddItem(NewVariant);

		NewVariant.WeaponDef = "KFGame.KFWeapDef_HVStormCannon";
		NewVariant.WeaponDefVariant = "ZedternalReborn.WMWeapDef_HVStormCannon_Precious";
		default.Weapon_VariantWeaponDef.AddItem(NewVariant);

		NewVariant.WeaponDef = "KFGame.KFWeapDef_ZedMKIII";
		NewVariant.WeaponDefVariant = "ZedternalReborn.WMWeapDef_ZedMKIII_Precious";
		default.Weapon_VariantWeaponDef.AddItem(NewVariant);
	}

	if (default.MODEVERSION < 17)
	{
		NewVariant.WeaponDef = "KFGame.KFWeapDef_HRG_Warthog";
		NewVariant.WeaponDefVariant = "ZedternalReborn.WMWeapDef_HRG_Warthog_Precious";
		default.Weapon_VariantWeaponDef.AddItem(NewVariant);

		NewVariant.WeaponDef = "KFGame.KFWeapDef_Shotgun_S12";
		NewVariant.WeaponDefVariant = "ZedternalReborn.WMWeapDef_Shotgun_S12_Precious";
		default.Weapon_VariantWeaponDef.AddItem(NewVariant);
	}

	if (default.MODEVERSION < 19)
	{
		NewVariant.WeaponDef = "KFGame.KFWeapDef_MG3";
		NewVariant.WeaponDefVariant = "ZedternalReborn.WMWeapDef_MG3_Precious";
		default.Weapon_VariantWeaponDef.AddItem(NewVariant);
	}

	if (default.MODEVERSION < class'ZedternalReborn.Config_Base'.const.CurrentVersion)
	{
		// BEGIN TEMPERED INI DEFAULTS (generated; do not edit by hand)
		default.Weapon_VariantWeaponDef.Length = 114;
		default.Weapon_VariantWeaponDef[0].WeaponDef = "KFGame.KFWeapDef_AA12";
		default.Weapon_VariantWeaponDef[0].WeaponDefVariant = "ZedternalReborn.WMWeapDef_AA12_Precious";
		default.Weapon_VariantWeaponDef[0].DualWeaponDefVariant = "";
		default.Weapon_VariantWeaponDef[0].Probability = 0.050000f;
		default.Weapon_VariantWeaponDef[1].WeaponDef = "KFGame.KFWeapDef_AbominationAxe";
		default.Weapon_VariantWeaponDef[1].WeaponDefVariant = "ZedternalReborn.WMWeapDef_AbominationAxe_Precious";
		default.Weapon_VariantWeaponDef[1].DualWeaponDefVariant = "";
		default.Weapon_VariantWeaponDef[1].Probability = 0.050000f;
		default.Weapon_VariantWeaponDef[2].WeaponDef = "KFGame.KFWeapDef_AF2011";
		default.Weapon_VariantWeaponDef[2].WeaponDefVariant = "ZedternalReborn.WMWeapDef_AF2011_Precious";
		default.Weapon_VariantWeaponDef[2].DualWeaponDefVariant = "ZedternalReborn.WMWeapDef_AF2011Dual_Precious";
		default.Weapon_VariantWeaponDef[2].Probability = 0.050000f;
		default.Weapon_VariantWeaponDef[3].WeaponDef = "KFGame.KFWeapDef_AK12";
		default.Weapon_VariantWeaponDef[3].WeaponDefVariant = "ZedternalReborn.WMWeapDef_AK12_Precious";
		default.Weapon_VariantWeaponDef[3].DualWeaponDefVariant = "";
		default.Weapon_VariantWeaponDef[3].Probability = 0.050000f;
		default.Weapon_VariantWeaponDef[4].WeaponDef = "KFGame.KFWeapDef_AR15";
		default.Weapon_VariantWeaponDef[4].WeaponDefVariant = "ZedternalReborn.WMWeapDef_AR15_Precious";
		default.Weapon_VariantWeaponDef[4].DualWeaponDefVariant = "";
		default.Weapon_VariantWeaponDef[4].Probability = 0.050000f;
		default.Weapon_VariantWeaponDef[5].WeaponDef = "KFGame.KFWeapDef_BladedPistol";
		default.Weapon_VariantWeaponDef[5].WeaponDefVariant = "ZedternalReborn.WMWeapDef_BladedPistol_Precious";
		default.Weapon_VariantWeaponDef[5].DualWeaponDefVariant = "ZedternalReborn.WMWeapDef_DualBladed_Precious";
		default.Weapon_VariantWeaponDef[5].Probability = 0.050000f;
		default.Weapon_VariantWeaponDef[6].WeaponDef = "KFGame.KFWeapDef_Blunderbuss";
		default.Weapon_VariantWeaponDef[6].WeaponDefVariant = "ZedternalReborn.WMWeapDef_Blunderbuss_Precious";
		default.Weapon_VariantWeaponDef[6].DualWeaponDefVariant = "";
		default.Weapon_VariantWeaponDef[6].Probability = 0.050000f;
		default.Weapon_VariantWeaponDef[7].WeaponDef = "KFGame.KFWeapDef_Bullpup";
		default.Weapon_VariantWeaponDef[7].WeaponDefVariant = "ZedternalReborn.WMWeapDef_Bullpup_Precious";
		default.Weapon_VariantWeaponDef[7].DualWeaponDefVariant = "";
		default.Weapon_VariantWeaponDef[7].Probability = 0.050000f;
		default.Weapon_VariantWeaponDef[8].WeaponDef = "KFGame.KFWeapDef_C4";
		default.Weapon_VariantWeaponDef[8].WeaponDefVariant = "ZedternalReborn.WMWeapDef_C4_Precious";
		default.Weapon_VariantWeaponDef[8].DualWeaponDefVariant = "";
		default.Weapon_VariantWeaponDef[8].Probability = 0.050000f;
		default.Weapon_VariantWeaponDef[9].WeaponDef = "KFGame.KFWeapDef_CaulkBurn";
		default.Weapon_VariantWeaponDef[9].WeaponDefVariant = "ZedternalReborn.WMWeapDef_CaulkBurn_Precious";
		default.Weapon_VariantWeaponDef[9].DualWeaponDefVariant = "";
		default.Weapon_VariantWeaponDef[9].Probability = 0.050000f;
		default.Weapon_VariantWeaponDef[10].WeaponDef = "KFGame.KFWeapDef_CenterfireMB464";
		default.Weapon_VariantWeaponDef[10].WeaponDefVariant = "ZedternalReborn.WMWeapDef_CenterfireMB464_Precious";
		default.Weapon_VariantWeaponDef[10].DualWeaponDefVariant = "";
		default.Weapon_VariantWeaponDef[10].Probability = 0.050000f;
		default.Weapon_VariantWeaponDef[11].WeaponDef = "KFGame.KFWeapDef_ChainBat";
		default.Weapon_VariantWeaponDef[11].WeaponDefVariant = "ZedternalReborn.WMWeapDef_ChainBat_Precious";
		default.Weapon_VariantWeaponDef[11].DualWeaponDefVariant = "";
		default.Weapon_VariantWeaponDef[11].Probability = 0.050000f;
		default.Weapon_VariantWeaponDef[12].WeaponDef = "KFGame.KFWeapDef_ChiappaRhino";
		default.Weapon_VariantWeaponDef[12].WeaponDefVariant = "ZedternalReborn.WMWeapDef_ChiappaRhino_Precious";
		default.Weapon_VariantWeaponDef[12].DualWeaponDefVariant = "ZedternalReborn.WMWeapDef_ChiappaRhinoDual_Precious";
		default.Weapon_VariantWeaponDef[12].Probability = 0.050000f;
		default.Weapon_VariantWeaponDef[13].WeaponDef = "KFGame.KFWeapDef_Colt1911";
		default.Weapon_VariantWeaponDef[13].WeaponDefVariant = "ZedternalReborn.WMWeapDef_Colt1911_Precious";
		default.Weapon_VariantWeaponDef[13].DualWeaponDefVariant = "ZedternalReborn.WMWeapDef_Colt1911Dual_Precious";
		default.Weapon_VariantWeaponDef[13].Probability = 0.050000f;
		default.Weapon_VariantWeaponDef[14].WeaponDef = "KFGame.KFWeapDef_CompoundBow";
		default.Weapon_VariantWeaponDef[14].WeaponDefVariant = "ZedternalReborn.WMWeapDef_CompoundBow_Precious";
		default.Weapon_VariantWeaponDef[14].DualWeaponDefVariant = "";
		default.Weapon_VariantWeaponDef[14].Probability = 0.050000f;
		default.Weapon_VariantWeaponDef[15].WeaponDef = "KFGame.KFWeapDef_Crossbow";
		default.Weapon_VariantWeaponDef[15].WeaponDefVariant = "ZedternalReborn.WMWeapDef_Crossbow_Precious";
		default.Weapon_VariantWeaponDef[15].DualWeaponDefVariant = "";
		default.Weapon_VariantWeaponDef[15].Probability = 0.050000f;
		default.Weapon_VariantWeaponDef[16].WeaponDef = "KFGame.KFWeapDef_Crovel";
		default.Weapon_VariantWeaponDef[16].WeaponDefVariant = "ZedternalReborn.WMWeapDef_Crovel_Precious";
		default.Weapon_VariantWeaponDef[16].DualWeaponDefVariant = "";
		default.Weapon_VariantWeaponDef[16].Probability = 0.050000f;
		default.Weapon_VariantWeaponDef[17].WeaponDef = "KFGame.KFWeapDef_Deagle";
		default.Weapon_VariantWeaponDef[17].WeaponDefVariant = "ZedternalReborn.WMWeapDef_Deagle_Precious";
		default.Weapon_VariantWeaponDef[17].DualWeaponDefVariant = "ZedternalReborn.WMWeapDef_DeagleDual_Precious";
		default.Weapon_VariantWeaponDef[17].Probability = 0.050000f;
		default.Weapon_VariantWeaponDef[18].WeaponDef = "KFGame.KFWeapDef_DoubleBarrel";
		default.Weapon_VariantWeaponDef[18].WeaponDefVariant = "ZedternalReborn.WMWeapDef_DoubleBarrel_Precious";
		default.Weapon_VariantWeaponDef[18].DualWeaponDefVariant = "";
		default.Weapon_VariantWeaponDef[18].Probability = 0.050000f;
		default.Weapon_VariantWeaponDef[19].WeaponDef = "KFGame.KFWeapDef_DragonsBreath";
		default.Weapon_VariantWeaponDef[19].WeaponDefVariant = "ZedternalReborn.WMWeapDef_DragonsBreath_Precious";
		default.Weapon_VariantWeaponDef[19].DualWeaponDefVariant = "";
		default.Weapon_VariantWeaponDef[19].Probability = 0.050000f;
		default.Weapon_VariantWeaponDef[20].WeaponDef = "KFGame.KFWeapDef_ElephantGun";
		default.Weapon_VariantWeaponDef[20].WeaponDefVariant = "ZedternalReborn.WMWeapDef_ElephantGun_Precious";
		default.Weapon_VariantWeaponDef[20].DualWeaponDefVariant = "";
		default.Weapon_VariantWeaponDef[20].Probability = 0.050000f;
		default.Weapon_VariantWeaponDef[21].WeaponDef = "KFGame.KFWeapDef_Eviscerator";
		default.Weapon_VariantWeaponDef[21].WeaponDefVariant = "ZedternalReborn.WMWeapDef_Eviscerator_Precious";
		default.Weapon_VariantWeaponDef[21].DualWeaponDefVariant = "";
		default.Weapon_VariantWeaponDef[21].Probability = 0.050000f;
		default.Weapon_VariantWeaponDef[22].WeaponDef = "KFGame.KFWeapDef_FAMAS";
		default.Weapon_VariantWeaponDef[22].WeaponDefVariant = "ZedternalReborn.WMWeapDef_FAMAS_Precious";
		default.Weapon_VariantWeaponDef[22].DualWeaponDefVariant = "";
		default.Weapon_VariantWeaponDef[22].Probability = 0.050000f;
		default.Weapon_VariantWeaponDef[23].WeaponDef = "KFGame.KFWeapDef_FireAxe";
		default.Weapon_VariantWeaponDef[23].WeaponDefVariant = "ZedternalReborn.WMWeapDef_FireAxe_Precious";
		default.Weapon_VariantWeaponDef[23].DualWeaponDefVariant = "";
		default.Weapon_VariantWeaponDef[23].Probability = 0.050000f;
		default.Weapon_VariantWeaponDef[24].WeaponDef = "KFGame.KFWeapDef_FlameThrower";
		default.Weapon_VariantWeaponDef[24].WeaponDefVariant = "ZedternalReborn.WMWeapDef_FlameThrower_Precious";
		default.Weapon_VariantWeaponDef[24].DualWeaponDefVariant = "";
		default.Weapon_VariantWeaponDef[24].Probability = 0.050000f;
		default.Weapon_VariantWeaponDef[25].WeaponDef = "KFGame.KFWeapDef_FlareGun";
		default.Weapon_VariantWeaponDef[25].WeaponDefVariant = "ZedternalReborn.WMWeapDef_FlareGun_Precious";
		default.Weapon_VariantWeaponDef[25].DualWeaponDefVariant = "ZedternalReborn.WMWeapDef_FlareGunDual_Precious";
		default.Weapon_VariantWeaponDef[25].Probability = 0.050000f;
		default.Weapon_VariantWeaponDef[26].WeaponDef = "KFGame.KFWeapDef_FNFal";
		default.Weapon_VariantWeaponDef[26].WeaponDefVariant = "ZedternalReborn.WMWeapDef_FNFal_Precious";
		default.Weapon_VariantWeaponDef[26].DualWeaponDefVariant = "";
		default.Weapon_VariantWeaponDef[26].Probability = 0.050000f;
		default.Weapon_VariantWeaponDef[27].WeaponDef = "KFGame.KFWeapDef_FreezeThrower";
		default.Weapon_VariantWeaponDef[27].WeaponDefVariant = "ZedternalReborn.WMWeapDef_FreezeThrower_Precious";
		default.Weapon_VariantWeaponDef[27].DualWeaponDefVariant = "";
		default.Weapon_VariantWeaponDef[27].Probability = 0.050000f;
		default.Weapon_VariantWeaponDef[28].WeaponDef = "KFGame.KFWeapDef_G18";
		default.Weapon_VariantWeaponDef[28].WeaponDefVariant = "ZedternalReborn.WMWeapDef_G18_Precious";
		default.Weapon_VariantWeaponDef[28].DualWeaponDefVariant = "";
		default.Weapon_VariantWeaponDef[28].Probability = 0.050000f;
		default.Weapon_VariantWeaponDef[29].WeaponDef = "KFGame.KFWeapDef_GravityImploder";
		default.Weapon_VariantWeaponDef[29].WeaponDefVariant = "ZedternalReborn.WMWeapDef_GravityImploder_Precious";
		default.Weapon_VariantWeaponDef[29].DualWeaponDefVariant = "";
		default.Weapon_VariantWeaponDef[29].Probability = 0.050000f;
		default.Weapon_VariantWeaponDef[30].WeaponDef = "KFGame.KFWeapDef_Healthrower_HRG";
		default.Weapon_VariantWeaponDef[30].WeaponDefVariant = "ZedternalReborn.WMWeapDef_Healthrower_HRG_Precious";
		default.Weapon_VariantWeaponDef[30].DualWeaponDefVariant = "";
		default.Weapon_VariantWeaponDef[30].Probability = 0.050000f;
		default.Weapon_VariantWeaponDef[31].WeaponDef = "KFGame.KFWeapDef_Hemogoblin";
		default.Weapon_VariantWeaponDef[31].WeaponDefVariant = "ZedternalReborn.WMWeapDef_Hemogoblin_Precious";
		default.Weapon_VariantWeaponDef[31].DualWeaponDefVariant = "";
		default.Weapon_VariantWeaponDef[31].Probability = 0.050000f;
		default.Weapon_VariantWeaponDef[32].WeaponDef = "KFGame.KFWeapDef_HK_UMP";
		default.Weapon_VariantWeaponDef[32].WeaponDefVariant = "ZedternalReborn.WMWeapDef_HK_UMP_Precious";
		default.Weapon_VariantWeaponDef[32].DualWeaponDefVariant = "";
		default.Weapon_VariantWeaponDef[32].Probability = 0.050000f;
		default.Weapon_VariantWeaponDef[33].WeaponDef = "KFGame.KFWeapDef_HRG_BarrierRifle";
		default.Weapon_VariantWeaponDef[33].WeaponDefVariant = "ZedternalReborn.WMWeapDef_HRG_BarrierRifle_Precious";
		default.Weapon_VariantWeaponDef[33].DualWeaponDefVariant = "";
		default.Weapon_VariantWeaponDef[33].Probability = 0.050000f;
		default.Weapon_VariantWeaponDef[34].WeaponDef = "KFGame.KFWeapDef_HRG_BlastBrawlers";
		default.Weapon_VariantWeaponDef[34].WeaponDefVariant = "ZedternalReborn.WMWeapDef_HRG_BlastBrawlers_Precious";
		default.Weapon_VariantWeaponDef[34].DualWeaponDefVariant = "";
		default.Weapon_VariantWeaponDef[34].Probability = 0.050000f;
		default.Weapon_VariantWeaponDef[35].WeaponDef = "KFGame.KFWeapDef_HRG_Boomy";
		default.Weapon_VariantWeaponDef[35].WeaponDefVariant = "ZedternalReborn.WMWeapDef_HRG_Boomy_Precious";
		default.Weapon_VariantWeaponDef[35].DualWeaponDefVariant = "";
		default.Weapon_VariantWeaponDef[35].Probability = 0.050000f;
		default.Weapon_VariantWeaponDef[36].WeaponDef = "KFGame.KFWeapDef_HRG_EMP_ArcGenerator";
		default.Weapon_VariantWeaponDef[36].WeaponDefVariant = "ZedternalReborn.WMWeapDef_HRG_EMP_ArcGenerator_Precious";
		default.Weapon_VariantWeaponDef[36].DualWeaponDefVariant = "";
		default.Weapon_VariantWeaponDef[36].Probability = 0.050000f;
		default.Weapon_VariantWeaponDef[37].WeaponDef = "KFGame.KFWeapDef_HRG_Energy";
		default.Weapon_VariantWeaponDef[37].WeaponDefVariant = "ZedternalReborn.WMWeapDef_HRG_Energy_Precious";
		default.Weapon_VariantWeaponDef[37].DualWeaponDefVariant = "";
		default.Weapon_VariantWeaponDef[37].Probability = 0.050000f;
		default.Weapon_VariantWeaponDef[38].WeaponDef = "KFGame.KFWeapDef_HRGIncendiaryRifle";
		default.Weapon_VariantWeaponDef[38].WeaponDefVariant = "ZedternalReborn.WMWeapDef_HRGIncendiaryRifle_Precious";
		default.Weapon_VariantWeaponDef[38].DualWeaponDefVariant = "";
		default.Weapon_VariantWeaponDef[38].Probability = 0.050000f;
		default.Weapon_VariantWeaponDef[39].WeaponDef = "KFGame.KFWeapDef_HRGIncision";
		default.Weapon_VariantWeaponDef[39].WeaponDefVariant = "ZedternalReborn.WMWeapDef_HRGIncision_Precious";
		default.Weapon_VariantWeaponDef[39].DualWeaponDefVariant = "";
		default.Weapon_VariantWeaponDef[39].Probability = 0.050000f;
		default.Weapon_VariantWeaponDef[40].WeaponDef = "KFGame.KFWeapDef_HRG_Kaboomstick";
		default.Weapon_VariantWeaponDef[40].WeaponDefVariant = "ZedternalReborn.WMWeapDef_HRG_Kaboomstick_Precious";
		default.Weapon_VariantWeaponDef[40].DualWeaponDefVariant = "";
		default.Weapon_VariantWeaponDef[40].Probability = 0.050000f;
		default.Weapon_VariantWeaponDef[41].WeaponDef = "KFGame.KFWeapDef_HRGScorcher";
		default.Weapon_VariantWeaponDef[41].WeaponDefVariant = "ZedternalReborn.WMWeapDef_HRGScorcher_Precious";
		default.Weapon_VariantWeaponDef[41].DualWeaponDefVariant = "";
		default.Weapon_VariantWeaponDef[41].Probability = 0.050000f;
		default.Weapon_VariantWeaponDef[42].WeaponDef = "KFGame.KFWeapDef_HRG_SonicGun";
		default.Weapon_VariantWeaponDef[42].WeaponDefVariant = "ZedternalReborn.WMWeapDef_HRG_SonicGun_Precious";
		default.Weapon_VariantWeaponDef[42].DualWeaponDefVariant = "";
		default.Weapon_VariantWeaponDef[42].Probability = 0.050000f;
		default.Weapon_VariantWeaponDef[43].WeaponDef = "KFGame.KFWeapDef_HRGTeslauncher";
		default.Weapon_VariantWeaponDef[43].WeaponDefVariant = "ZedternalReborn.WMWeapDef_HRGTeslauncher_Precious";
		default.Weapon_VariantWeaponDef[43].DualWeaponDefVariant = "";
		default.Weapon_VariantWeaponDef[43].Probability = 0.050000f;
		default.Weapon_VariantWeaponDef[44].WeaponDef = "KFGame.KFWeapDef_HRG_Vampire";
		default.Weapon_VariantWeaponDef[44].WeaponDefVariant = "ZedternalReborn.WMWeapDef_HRG_Vampire_Precious";
		default.Weapon_VariantWeaponDef[44].DualWeaponDefVariant = "";
		default.Weapon_VariantWeaponDef[44].Probability = 0.050000f;
		default.Weapon_VariantWeaponDef[45].WeaponDef = "KFGame.KFWeapDef_HRG_Wintorbite";
		default.Weapon_VariantWeaponDef[45].WeaponDefVariant = "ZedternalReborn.WMWeapDef_HRGWinterbite_Precious";
		default.Weapon_VariantWeaponDef[45].DualWeaponDefVariant = "ZedternalReborn.WMWeapDef_HRGWinterbiteDual_Precious";
		default.Weapon_VariantWeaponDef[45].Probability = 0.050000f;
		default.Weapon_VariantWeaponDef[46].WeaponDef = "KFGame.KFWeapDef_HuskCannon";
		default.Weapon_VariantWeaponDef[46].WeaponDefVariant = "ZedternalReborn.WMWeapDef_HuskCannon_Precious";
		default.Weapon_VariantWeaponDef[46].DualWeaponDefVariant = "";
		default.Weapon_VariantWeaponDef[46].Probability = 0.050000f;
		default.Weapon_VariantWeaponDef[47].WeaponDef = "KFGame.KFWeapDef_HRG_Crossboom";
		default.Weapon_VariantWeaponDef[47].WeaponDefVariant = "ZedternalReborn.WMWeapDef_HRG_Crossboom_Precious";
		default.Weapon_VariantWeaponDef[47].DualWeaponDefVariant = "";
		default.Weapon_VariantWeaponDef[47].Probability = 0.050000f;
		default.Weapon_VariantWeaponDef[48].WeaponDef = "KFGame.KFWeapDef_HZ12";
		default.Weapon_VariantWeaponDef[48].WeaponDefVariant = "ZedternalReborn.WMWeapDef_HZ12_Precious";
		default.Weapon_VariantWeaponDef[48].DualWeaponDefVariant = "";
		default.Weapon_VariantWeaponDef[48].Probability = 0.050000f;
		default.Weapon_VariantWeaponDef[49].WeaponDef = "KFGame.KFWeapDef_IonThruster";
		default.Weapon_VariantWeaponDef[49].WeaponDefVariant = "ZedternalReborn.WMWeapDef_IonThruster_Precious";
		default.Weapon_VariantWeaponDef[49].DualWeaponDefVariant = "";
		default.Weapon_VariantWeaponDef[49].Probability = 0.050000f;
		default.Weapon_VariantWeaponDef[50].WeaponDef = "KFGame.KFWeapDef_Katana";
		default.Weapon_VariantWeaponDef[50].WeaponDefVariant = "ZedternalReborn.WMWeapDef_Katana_Precious";
		default.Weapon_VariantWeaponDef[50].DualWeaponDefVariant = "";
		default.Weapon_VariantWeaponDef[50].Probability = 0.050000f;
		default.Weapon_VariantWeaponDef[51].WeaponDef = "KFGame.KFWeapDef_Kriss";
		default.Weapon_VariantWeaponDef[51].WeaponDefVariant = "ZedternalReborn.WMWeapDef_Kriss_Precious";
		default.Weapon_VariantWeaponDef[51].DualWeaponDefVariant = "";
		default.Weapon_VariantWeaponDef[51].Probability = 0.050000f;
		default.Weapon_VariantWeaponDef[52].WeaponDef = "KFGame.KFWeapDef_LazerCutter";
		default.Weapon_VariantWeaponDef[52].WeaponDefVariant = "ZedternalReborn.WMWeapDef_LazerCutter_Precious";
		default.Weapon_VariantWeaponDef[52].DualWeaponDefVariant = "";
		default.Weapon_VariantWeaponDef[52].Probability = 0.050000f;
		default.Weapon_VariantWeaponDef[53].WeaponDef = "KFGame.KFWeapDef_M4";
		default.Weapon_VariantWeaponDef[53].WeaponDefVariant = "ZedternalReborn.WMWeapDef_M4_Precious";
		default.Weapon_VariantWeaponDef[53].DualWeaponDefVariant = "";
		default.Weapon_VariantWeaponDef[53].Probability = 0.050000f;
		default.Weapon_VariantWeaponDef[54].WeaponDef = "KFGame.KFWeapDef_M14EBR";
		default.Weapon_VariantWeaponDef[54].WeaponDefVariant = "ZedternalReborn.WMWeapDef_M14EBR_Precious";
		default.Weapon_VariantWeaponDef[54].DualWeaponDefVariant = "";
		default.Weapon_VariantWeaponDef[54].Probability = 0.050000f;
		default.Weapon_VariantWeaponDef[55].WeaponDef = "KFGame.KFWeapDef_M16M203";
		default.Weapon_VariantWeaponDef[55].WeaponDefVariant = "ZedternalReborn.WMWeapDef_M16M203_Precious";
		default.Weapon_VariantWeaponDef[55].DualWeaponDefVariant = "";
		default.Weapon_VariantWeaponDef[55].Probability = 0.050000f;
		default.Weapon_VariantWeaponDef[56].WeaponDef = "KFGame.KFWeapDef_M32";
		default.Weapon_VariantWeaponDef[56].WeaponDefVariant = "ZedternalReborn.WMWeapDef_M32_Precious";
		default.Weapon_VariantWeaponDef[56].DualWeaponDefVariant = "";
		default.Weapon_VariantWeaponDef[56].Probability = 0.050000f;
		default.Weapon_VariantWeaponDef[57].WeaponDef = "KFGame.KFWeapDef_M79";
		default.Weapon_VariantWeaponDef[57].WeaponDefVariant = "ZedternalReborn.WMWeapDef_M79_Precious";
		default.Weapon_VariantWeaponDef[57].DualWeaponDefVariant = "";
		default.Weapon_VariantWeaponDef[57].Probability = 0.050000f;
		default.Weapon_VariantWeaponDef[58].WeaponDef = "KFGame.KFWeapDef_M99";
		default.Weapon_VariantWeaponDef[58].WeaponDefVariant = "ZedternalReborn.WMWeapDef_M99_Precious";
		default.Weapon_VariantWeaponDef[58].DualWeaponDefVariant = "";
		default.Weapon_VariantWeaponDef[58].Probability = 0.050000f;
		default.Weapon_VariantWeaponDef[59].WeaponDef = "KFGame.KFWeapDef_Mac10";
		default.Weapon_VariantWeaponDef[59].WeaponDefVariant = "ZedternalReborn.WMWeapDef_Mac10_Precious";
		default.Weapon_VariantWeaponDef[59].DualWeaponDefVariant = "";
		default.Weapon_VariantWeaponDef[59].Probability = 0.050000f;
		default.Weapon_VariantWeaponDef[60].WeaponDef = "KFGame.KFWeapDef_MaceAndShield";
		default.Weapon_VariantWeaponDef[60].WeaponDefVariant = "ZedternalReborn.WMWeapDef_MaceAndShield_Precious";
		default.Weapon_VariantWeaponDef[60].DualWeaponDefVariant = "";
		default.Weapon_VariantWeaponDef[60].Probability = 0.050000f;
		default.Weapon_VariantWeaponDef[61].WeaponDef = "KFGame.KFWeapDef_MB500";
		default.Weapon_VariantWeaponDef[61].WeaponDefVariant = "ZedternalReborn.WMWeapDef_MB500_Precious";
		default.Weapon_VariantWeaponDef[61].DualWeaponDefVariant = "";
		default.Weapon_VariantWeaponDef[61].Probability = 0.050000f;
		default.Weapon_VariantWeaponDef[62].WeaponDef = "KFGame.KFWeapDef_MedicBat";
		default.Weapon_VariantWeaponDef[62].WeaponDefVariant = "ZedternalReborn.WMWeapDef_MedicBat_Precious";
		default.Weapon_VariantWeaponDef[62].DualWeaponDefVariant = "";
		default.Weapon_VariantWeaponDef[62].Probability = 0.050000f;
		default.Weapon_VariantWeaponDef[63].WeaponDef = "KFGame.KFWeapDef_MedicPistol";
		default.Weapon_VariantWeaponDef[63].WeaponDefVariant = "ZedternalReborn.WMWeapDef_MedicPistol_Precious";
		default.Weapon_VariantWeaponDef[63].DualWeaponDefVariant = "";
		default.Weapon_VariantWeaponDef[63].Probability = 0.050000f;
		default.Weapon_VariantWeaponDef[64].WeaponDef = "KFGame.KFWeapDef_MedicRifle";
		default.Weapon_VariantWeaponDef[64].WeaponDefVariant = "ZedternalReborn.WMWeapDef_MedicRifle_Precious";
		default.Weapon_VariantWeaponDef[64].DualWeaponDefVariant = "";
		default.Weapon_VariantWeaponDef[64].Probability = 0.050000f;
		default.Weapon_VariantWeaponDef[65].WeaponDef = "KFGame.KFWeapDef_MedicRifleGrenadeLauncher";
		default.Weapon_VariantWeaponDef[65].WeaponDefVariant = "ZedternalReborn.WMWeapDef_MedicRifleGrenadeLauncher_Precious";
		default.Weapon_VariantWeaponDef[65].DualWeaponDefVariant = "";
		default.Weapon_VariantWeaponDef[65].Probability = 0.050000f;
		default.Weapon_VariantWeaponDef[66].WeaponDef = "KFGame.KFWeapDef_MedicShotgun";
		default.Weapon_VariantWeaponDef[66].WeaponDefVariant = "ZedternalReborn.WMWeapDef_MedicShotgun_Precious";
		default.Weapon_VariantWeaponDef[66].DualWeaponDefVariant = "";
		default.Weapon_VariantWeaponDef[66].Probability = 0.050000f;
		default.Weapon_VariantWeaponDef[67].WeaponDef = "KFGame.KFWeapDef_MedicSMG";
		default.Weapon_VariantWeaponDef[67].WeaponDefVariant = "ZedternalReborn.WMWeapDef_MedicSMG_Precious";
		default.Weapon_VariantWeaponDef[67].DualWeaponDefVariant = "";
		default.Weapon_VariantWeaponDef[67].Probability = 0.050000f;
		default.Weapon_VariantWeaponDef[68].WeaponDef = "KFGame.KFWeapDef_MicrowaveGun";
		default.Weapon_VariantWeaponDef[68].WeaponDefVariant = "ZedternalReborn.WMWeapDef_MicrowaveGun_Precious";
		default.Weapon_VariantWeaponDef[68].DualWeaponDefVariant = "";
		default.Weapon_VariantWeaponDef[68].Probability = 0.050000f;
		default.Weapon_VariantWeaponDef[69].WeaponDef = "KFGame.KFWeapDef_MicrowaveRifle";
		default.Weapon_VariantWeaponDef[69].WeaponDefVariant = "ZedternalReborn.WMWeapDef_MicrowaveRifle_Precious";
		default.Weapon_VariantWeaponDef[69].DualWeaponDefVariant = "";
		default.Weapon_VariantWeaponDef[69].Probability = 0.050000f;
		default.Weapon_VariantWeaponDef[70].WeaponDef = "KFGame.KFWeapDef_Mine_Reconstructor";
		default.Weapon_VariantWeaponDef[70].WeaponDefVariant = "ZedternalReborn.WMWeapDef_Mine_Reconstructor_Precious";
		default.Weapon_VariantWeaponDef[70].DualWeaponDefVariant = "";
		default.Weapon_VariantWeaponDef[70].Probability = 0.050000f;
		default.Weapon_VariantWeaponDef[71].WeaponDef = "KFGame.KFWeapDef_Minigun";
		default.Weapon_VariantWeaponDef[71].WeaponDefVariant = "ZedternalReborn.WMWeapDef_Minigun_Precious";
		default.Weapon_VariantWeaponDef[71].DualWeaponDefVariant = "";
		default.Weapon_VariantWeaponDef[71].Probability = 0.050000f;
		default.Weapon_VariantWeaponDef[72].WeaponDef = "KFGame.KFWeapDef_MKB42";
		default.Weapon_VariantWeaponDef[72].WeaponDefVariant = "ZedternalReborn.WMWeapDef_MKB42_Precious";
		default.Weapon_VariantWeaponDef[72].DualWeaponDefVariant = "";
		default.Weapon_VariantWeaponDef[72].Probability = 0.050000f;
		default.Weapon_VariantWeaponDef[73].WeaponDef = "KFGame.KFWeapDef_MosinNagant";
		default.Weapon_VariantWeaponDef[73].WeaponDefVariant = "ZedternalReborn.WMWeapDef_MosinNagant_Precious";
		default.Weapon_VariantWeaponDef[73].DualWeaponDefVariant = "";
		default.Weapon_VariantWeaponDef[73].Probability = 0.050000f;
		default.Weapon_VariantWeaponDef[74].WeaponDef = "KFGame.KFWeapDef_MP5RAS";
		default.Weapon_VariantWeaponDef[74].WeaponDefVariant = "ZedternalReborn.WMWeapDef_MP5RAS_Precious";
		default.Weapon_VariantWeaponDef[74].DualWeaponDefVariant = "";
		default.Weapon_VariantWeaponDef[74].Probability = 0.050000f;
		default.Weapon_VariantWeaponDef[75].WeaponDef = "KFGame.KFWeapDef_MP7";
		default.Weapon_VariantWeaponDef[75].WeaponDefVariant = "ZedternalReborn.WMWeapDef_MP7_Precious";
		default.Weapon_VariantWeaponDef[75].DualWeaponDefVariant = "";
		default.Weapon_VariantWeaponDef[75].Probability = 0.050000f;
		default.Weapon_VariantWeaponDef[76].WeaponDef = "KFGame.KFWeapDef_Nailgun";
		default.Weapon_VariantWeaponDef[76].WeaponDefVariant = "ZedternalReborn.WMWeapDef_Nailgun_Precious";
		default.Weapon_VariantWeaponDef[76].DualWeaponDefVariant = "";
		default.Weapon_VariantWeaponDef[76].Probability = 0.050000f;
		default.Weapon_VariantWeaponDef[77].WeaponDef = "KFGame.KFWeapDef_Nailgun_HRG";
		default.Weapon_VariantWeaponDef[77].WeaponDefVariant = "ZedternalReborn.WMWeapDef_Nailgun_HRG_Precious";
		default.Weapon_VariantWeaponDef[77].DualWeaponDefVariant = "";
		default.Weapon_VariantWeaponDef[77].Probability = 0.050000f;
		default.Weapon_VariantWeaponDef[78].WeaponDef = "KFGame.KFWeapDef_P90";
		default.Weapon_VariantWeaponDef[78].WeaponDefVariant = "ZedternalReborn.WMWeapDef_P90_Precious";
		default.Weapon_VariantWeaponDef[78].DualWeaponDefVariant = "";
		default.Weapon_VariantWeaponDef[78].Probability = 0.050000f;
		default.Weapon_VariantWeaponDef[79].WeaponDef = "KFGame.KFWeapDef_ParasiteImplanter";
		default.Weapon_VariantWeaponDef[79].WeaponDefVariant = "ZedternalReborn.WMWeapDef_ParasiteImplanter_Precious";
		default.Weapon_VariantWeaponDef[79].DualWeaponDefVariant = "";
		default.Weapon_VariantWeaponDef[79].Probability = 0.050000f;
		default.Weapon_VariantWeaponDef[80].WeaponDef = "KFGame.KFWeapDef_Pistol_G18C";
		default.Weapon_VariantWeaponDef[80].WeaponDefVariant = "ZedternalReborn.WMWeapDef_Pistol_G18C_Precious";
		default.Weapon_VariantWeaponDef[80].DualWeaponDefVariant = "ZedternalReborn.WMWeapDef_Pistol_DualG18_Precious";
		default.Weapon_VariantWeaponDef[80].Probability = 0.050000f;
		default.Weapon_VariantWeaponDef[81].WeaponDef = "KFGame.KFWeapDef_PowerGloves";
		default.Weapon_VariantWeaponDef[81].WeaponDefVariant = "ZedternalReborn.WMWeapDef_PowerGloves_Precious";
		default.Weapon_VariantWeaponDef[81].DualWeaponDefVariant = "";
		default.Weapon_VariantWeaponDef[81].Probability = 0.050000f;
		default.Weapon_VariantWeaponDef[82].WeaponDef = "KFGame.KFWeapDef_Pulverizer";
		default.Weapon_VariantWeaponDef[82].WeaponDefVariant = "ZedternalReborn.WMWeapDef_Pulverizer_Precious";
		default.Weapon_VariantWeaponDef[82].DualWeaponDefVariant = "";
		default.Weapon_VariantWeaponDef[82].Probability = 0.050000f;
		default.Weapon_VariantWeaponDef[83].WeaponDef = "KFGame.KFWeapDef_RailGun";
		default.Weapon_VariantWeaponDef[83].WeaponDefVariant = "ZedternalReborn.WMWeapDef_RailGun_Precious";
		default.Weapon_VariantWeaponDef[83].DualWeaponDefVariant = "";
		default.Weapon_VariantWeaponDef[83].Probability = 0.050000f;
		default.Weapon_VariantWeaponDef[84].WeaponDef = "KFGame.KFWeapDef_Remington1858";
		default.Weapon_VariantWeaponDef[84].WeaponDefVariant = "ZedternalReborn.WMWeapDef_Remington1858_Precious";
		default.Weapon_VariantWeaponDef[84].DualWeaponDefVariant = "ZedternalReborn.WMWeapDef_Remington1858Dual_Precious";
		default.Weapon_VariantWeaponDef[84].Probability = 0.050000f;
		default.Weapon_VariantWeaponDef[85].WeaponDef = "KFGame.KFWeapDef_Rifle_FrostShotgunAxe";
		default.Weapon_VariantWeaponDef[85].WeaponDefVariant = "ZedternalReborn.WMWeapDef_Rifle_FrostShotgunAxe_Precious";
		default.Weapon_VariantWeaponDef[85].DualWeaponDefVariant = "";
		default.Weapon_VariantWeaponDef[85].Probability = 0.050000f;
		default.Weapon_VariantWeaponDef[86].WeaponDef = "KFGame.KFWeapDef_RPG7";
		default.Weapon_VariantWeaponDef[86].WeaponDefVariant = "ZedternalReborn.WMWeapDef_RPG7_Precious";
		default.Weapon_VariantWeaponDef[86].DualWeaponDefVariant = "";
		default.Weapon_VariantWeaponDef[86].Probability = 0.050000f;
		default.Weapon_VariantWeaponDef[87].WeaponDef = "KFGame.KFWeapDef_SCAR";
		default.Weapon_VariantWeaponDef[87].WeaponDefVariant = "ZedternalReborn.WMWeapDef_SCAR_Precious";
		default.Weapon_VariantWeaponDef[87].DualWeaponDefVariant = "";
		default.Weapon_VariantWeaponDef[87].Probability = 0.050000f;
		default.Weapon_VariantWeaponDef[88].WeaponDef = "KFGame.KFWeapDef_SealSqueal";
		default.Weapon_VariantWeaponDef[88].WeaponDefVariant = "ZedternalReborn.WMWeapDef_SealSqueal_Precious";
		default.Weapon_VariantWeaponDef[88].DualWeaponDefVariant = "";
		default.Weapon_VariantWeaponDef[88].Probability = 0.050000f;
		default.Weapon_VariantWeaponDef[89].WeaponDef = "KFGame.KFWeapDef_Seeker6";
		default.Weapon_VariantWeaponDef[89].WeaponDefVariant = "ZedternalReborn.WMWeapDef_Seeker6_Precious";
		default.Weapon_VariantWeaponDef[89].DualWeaponDefVariant = "";
		default.Weapon_VariantWeaponDef[89].Probability = 0.050000f;
		default.Weapon_VariantWeaponDef[90].WeaponDef = "KFGame.KFWeapDef_Stoner63A";
		default.Weapon_VariantWeaponDef[90].WeaponDefVariant = "ZedternalReborn.WMWeapDef_Stoner63A_Precious";
		default.Weapon_VariantWeaponDef[90].DualWeaponDefVariant = "";
		default.Weapon_VariantWeaponDef[90].Probability = 0.050000f;
		default.Weapon_VariantWeaponDef[91].WeaponDef = "KFGame.KFWeapDef_SW500";
		default.Weapon_VariantWeaponDef[91].WeaponDefVariant = "ZedternalReborn.WMWeapDef_SW500_Precious";
		default.Weapon_VariantWeaponDef[91].DualWeaponDefVariant = "ZedternalReborn.WMWeapDef_SW500Dual_Precious";
		default.Weapon_VariantWeaponDef[91].Probability = 0.050000f;
		default.Weapon_VariantWeaponDef[92].WeaponDef = "KFGame.KFWeapDef_SW500_HRG";
		default.Weapon_VariantWeaponDef[92].WeaponDefVariant = "ZedternalReborn.WMWeapDef_SW500_HRG_Precious";
		default.Weapon_VariantWeaponDef[92].DualWeaponDefVariant = "ZedternalReborn.WMWeapDef_SW500Dual_HRG_Precious";
		default.Weapon_VariantWeaponDef[92].Probability = 0.050000f;
		default.Weapon_VariantWeaponDef[93].WeaponDef = "KFGame.KFWeapDef_ThermiteBore";
		default.Weapon_VariantWeaponDef[93].WeaponDefVariant = "ZedternalReborn.WMWeapDef_ThermiteBore_Precious";
		default.Weapon_VariantWeaponDef[93].DualWeaponDefVariant = "";
		default.Weapon_VariantWeaponDef[93].Probability = 0.050000f;
		default.Weapon_VariantWeaponDef[94].WeaponDef = "KFGame.KFWeapDef_Thompson";
		default.Weapon_VariantWeaponDef[94].WeaponDefVariant = "ZedternalReborn.WMWeapDef_Thompson_Precious";
		default.Weapon_VariantWeaponDef[94].DualWeaponDefVariant = "";
		default.Weapon_VariantWeaponDef[94].Probability = 0.050000f;
		default.Weapon_VariantWeaponDef[95].WeaponDef = "KFGame.KFWeapDef_Winchester1894";
		default.Weapon_VariantWeaponDef[95].WeaponDefVariant = "ZedternalReborn.WMWeapDef_Winchester1894_Precious";
		default.Weapon_VariantWeaponDef[95].DualWeaponDefVariant = "";
		default.Weapon_VariantWeaponDef[95].Probability = 0.050000f;
		default.Weapon_VariantWeaponDef[96].WeaponDef = "KFGame.KFWeapDef_Zweihander";
		default.Weapon_VariantWeaponDef[96].WeaponDefVariant = "ZedternalReborn.WMWeapDef_Zweihander_Precious";
		default.Weapon_VariantWeaponDef[96].DualWeaponDefVariant = "";
		default.Weapon_VariantWeaponDef[96].Probability = 0.050000f;
		default.Weapon_VariantWeaponDef[97].WeaponDef = "KFGame.KFWeapDef_HRG_Stunner";
		default.Weapon_VariantWeaponDef[97].WeaponDefVariant = "ZedternalReborn.WMWeapDef_HRG_Stunner_Precious";
		default.Weapon_VariantWeaponDef[97].DualWeaponDefVariant = "";
		default.Weapon_VariantWeaponDef[97].Probability = 0.050000f;
		default.Weapon_VariantWeaponDef[98].WeaponDef = "KFGame.KFWeapDef_Doshinegun";
		default.Weapon_VariantWeaponDef[98].WeaponDefVariant = "ZedternalReborn.WMWeapDef_Doshinegun_Precious";
		default.Weapon_VariantWeaponDef[98].DualWeaponDefVariant = "";
		default.Weapon_VariantWeaponDef[98].Probability = 0.050000f;
		default.Weapon_VariantWeaponDef[99].WeaponDef = "KFGame.KFWeapDef_HRG_CranialPopper";
		default.Weapon_VariantWeaponDef[99].WeaponDefVariant = "ZedternalReborn.WMWeapDef_HRG_CranialPopper_Precious";
		default.Weapon_VariantWeaponDef[99].DualWeaponDefVariant = "";
		default.Weapon_VariantWeaponDef[99].Probability = 0.050000f;
		default.Weapon_VariantWeaponDef[100].WeaponDef = "KFGame.KFWeapDef_HRG_Crossboom";
		default.Weapon_VariantWeaponDef[100].WeaponDefVariant = "ZedternalReborn.WMWeapDef_HRG_Crossboom_Precious";
		default.Weapon_VariantWeaponDef[100].DualWeaponDefVariant = "";
		default.Weapon_VariantWeaponDef[100].Probability = 0.050000f;
		default.Weapon_VariantWeaponDef[101].WeaponDef = "KFGame.KFWeapDef_ShrinkRayGun";
		default.Weapon_VariantWeaponDef[101].WeaponDefVariant = "ZedternalReborn.WMWeapDef_ShrinkRayGun_Precious";
		default.Weapon_VariantWeaponDef[101].DualWeaponDefVariant = "";
		default.Weapon_VariantWeaponDef[101].Probability = 0.050000f;
		default.Weapon_VariantWeaponDef[102].WeaponDef = "KFGame.KFWeapDef_AutoTurret";
		default.Weapon_VariantWeaponDef[102].WeaponDefVariant = "ZedternalReborn.WMWeapDef_AutoTurret_Precious";
		default.Weapon_VariantWeaponDef[102].DualWeaponDefVariant = "";
		default.Weapon_VariantWeaponDef[102].Probability = 0.050000f;
		default.Weapon_VariantWeaponDef[103].WeaponDef = "KFGame.KFWeapDef_G36C";
		default.Weapon_VariantWeaponDef[103].WeaponDefVariant = "ZedternalReborn.WMWeapDef_G36C_Precious";
		default.Weapon_VariantWeaponDef[103].DualWeaponDefVariant = "";
		default.Weapon_VariantWeaponDef[103].Probability = 0.050000f;
		default.Weapon_VariantWeaponDef[104].WeaponDef = "KFGame.KFWeapDef_HRG_Dragonbreath";
		default.Weapon_VariantWeaponDef[104].WeaponDefVariant = "ZedternalReborn.WMWeapDef_HRG_Dragonbreath_Precious";
		default.Weapon_VariantWeaponDef[104].DualWeaponDefVariant = "";
		default.Weapon_VariantWeaponDef[104].Probability = 0.050000f;
		default.Weapon_VariantWeaponDef[105].WeaponDef = "KFGame.KFWeapDef_HRG_Locust";
		default.Weapon_VariantWeaponDef[105].WeaponDefVariant = "ZedternalReborn.WMWeapDef_HRG_Locust_Precious";
		default.Weapon_VariantWeaponDef[105].DualWeaponDefVariant = "";
		default.Weapon_VariantWeaponDef[105].Probability = 0.050000f;
		default.Weapon_VariantWeaponDef[106].WeaponDef = "KFGame.KFWeapDef_Scythe";
		default.Weapon_VariantWeaponDef[106].WeaponDefVariant = "ZedternalReborn.WMWeapDef_Scythe_Precious";
		default.Weapon_VariantWeaponDef[106].DualWeaponDefVariant = "";
		default.Weapon_VariantWeaponDef[106].Probability = 0.050000f;
		default.Weapon_VariantWeaponDef[107].WeaponDef = "KFGame.KFWeapDef_HRG_BallisticBouncer";
		default.Weapon_VariantWeaponDef[107].WeaponDefVariant = "ZedternalReborn.WMWeapDef_HRG_BallisticBouncer_Precious";
		default.Weapon_VariantWeaponDef[107].DualWeaponDefVariant = "";
		default.Weapon_VariantWeaponDef[107].Probability = 0.050000f;
		default.Weapon_VariantWeaponDef[108].WeaponDef = "KFGame.KFWeapDef_HRG_MedicMissile";
		default.Weapon_VariantWeaponDef[108].WeaponDefVariant = "ZedternalReborn.WMWeapDef_HRG_MedicMissile_Precious";
		default.Weapon_VariantWeaponDef[108].DualWeaponDefVariant = "";
		default.Weapon_VariantWeaponDef[108].Probability = 0.050000f;
		default.Weapon_VariantWeaponDef[109].WeaponDef = "KFGame.KFWeapDef_HVStormCannon";
		default.Weapon_VariantWeaponDef[109].WeaponDefVariant = "ZedternalReborn.WMWeapDef_HVStormCannon_Precious";
		default.Weapon_VariantWeaponDef[109].DualWeaponDefVariant = "";
		default.Weapon_VariantWeaponDef[109].Probability = 0.050000f;
		default.Weapon_VariantWeaponDef[110].WeaponDef = "KFGame.KFWeapDef_ZedMKIII";
		default.Weapon_VariantWeaponDef[110].WeaponDefVariant = "ZedternalReborn.WMWeapDef_ZedMKIII_Precious";
		default.Weapon_VariantWeaponDef[110].DualWeaponDefVariant = "";
		default.Weapon_VariantWeaponDef[110].Probability = 0.050000f;
		default.Weapon_VariantWeaponDef[111].WeaponDef = "KFGame.KFWeapDef_HRG_Warthog";
		default.Weapon_VariantWeaponDef[111].WeaponDefVariant = "ZedternalReborn.WMWeapDef_HRG_Warthog_Precious";
		default.Weapon_VariantWeaponDef[111].DualWeaponDefVariant = "";
		default.Weapon_VariantWeaponDef[111].Probability = 0.050000f;
		default.Weapon_VariantWeaponDef[112].WeaponDef = "KFGame.KFWeapDef_Shotgun_S12";
		default.Weapon_VariantWeaponDef[112].WeaponDefVariant = "ZedternalReborn.WMWeapDef_Shotgun_S12_Precious";
		default.Weapon_VariantWeaponDef[112].DualWeaponDefVariant = "";
		default.Weapon_VariantWeaponDef[112].Probability = 0.050000f;
		default.Weapon_VariantWeaponDef[113].WeaponDef = "KFGame.KFWeapDef_MG3";
		default.Weapon_VariantWeaponDef[113].WeaponDefVariant = "ZedternalReborn.WMWeapDef_MG3_Precious";
		default.Weapon_VariantWeaponDef[113].DualWeaponDefVariant = "";
		default.Weapon_VariantWeaponDef[113].Probability = 0.050000f;
		// END TEMPERED INI DEFAULTS
		default.MODEVERSION = class'ZedternalReborn.Config_Base'.const.CurrentVersion;
		static.StaticSaveConfig();
	}
}

static function CheckBasicConfigValues()
{
	local int i;

	if (default.WeaponVariant_bAllowWeaponVariant)
	{
		for (i = 0; i < default.Weapon_VariantWeaponDef.Length; ++i)
		{
			if (default.Weapon_VariantWeaponDef[i].Probability < 0.0f)
			{
				LogBadConfigMessage("Weapon_VariantWeaponDef - Line" @ string(i + 1) @ "- Probability",
					string(default.Weapon_VariantWeaponDef[i].Probability),
					"0.0", "0%, never selected", "1.0 >= value >= 0.0");
				default.Weapon_VariantWeaponDef[i].Probability = 0.0f;
			}

			if (default.Weapon_VariantWeaponDef[i].Probability > 1.0f)
			{
				LogBadConfigMessage("Weapon_VariantWeaponDef - Line" @ string(i + 1) @ "- Probability",
					string(default.Weapon_VariantWeaponDef[i].Probability),
					"1.0", "100%, always selected", "1.0 >= value >= 0.0");
				default.Weapon_VariantWeaponDef[i].Probability = 1.0f;
			}
		}
	}
	else
		SkipCheckConfigMessage("Weapon_VariantWeaponDef", "WeaponVariant_bAllowWeaponVariant");
}

static function LoadConfigObjects(out array<float> VariantProbability, out array< class<KFWeaponDefinition> > WeaponDefObjects,
	out array< class<KFWeaponDefinition> > WeaponVarObjects, out array< class<KFWeaponDefinition> > WeaponDualObjects)
{
	local bool Dual;
	local int i;
	local class<KFWeaponDefinition> Obj, VarObj, DualObj;

	VariantProbability.Length = 0;
	WeaponDefObjects.Length = 0;
	WeaponVarObjects.Length = 0;
	WeaponDualObjects.Length = 0;

	if (default.WeaponVariant_bAllowWeaponVariant)
	{
		for (i = 0; i < default.Weapon_VariantWeaponDef.Length; ++i)
		{
			Obj = class<KFWeaponDefinition>(DynamicLoadObject(default.Weapon_VariantWeaponDef[i].WeaponDef, class'Class', True));
			if (Obj == None)
			{
				LogBadLoadObjectConfigMessage("Weapon_VariantWeaponDef", i + 1, default.Weapon_VariantWeaponDef[i].WeaponDef);
				continue;
			}

			VarObj = class<KFWeaponDefinition>(DynamicLoadObject(default.Weapon_VariantWeaponDef[i].WeaponDefVariant, class'Class', True));
			if (VarObj == None)
			{
				LogBadLoadObjectConfigMessage("Weapon_VariantWeaponDef", i + 1, default.Weapon_VariantWeaponDef[i].WeaponDefVariant);
				continue;
			}

			Dual = False;
			if (default.Weapon_VariantWeaponDef[i].DualWeaponDefVariant != "")
			{
				DualObj = class<KFWeaponDefinition>(DynamicLoadObject(default.Weapon_VariantWeaponDef[i].DualWeaponDefVariant, class'Class', True));
				if (DualObj == None)
					LogBadLoadObjectConfigMessage("Weapon_VariantWeaponDef", i + 1, default.Weapon_VariantWeaponDef[i].DualWeaponDefVariant);
				else
					Dual = True;
			}

			VariantProbability.AddItem(default.Weapon_VariantWeaponDef[i].Probability);
			WeaponDefObjects.AddItem(Obj);
			WeaponVarObjects.AddItem(VarObj);
			if (Dual)
				WeaponDualObjects.AddItem(DualObj);
			else
				WeaponDualObjects.AddItem(None);
		}
	}
}

defaultproperties
{
	Name="Default__Config_WeaponVariant"
}
