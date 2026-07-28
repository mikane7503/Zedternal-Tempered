// ===================================================================
// DKConfig_HowdyProjectiles
//
// Server-side config for Howdy's skill-spawned projectile damage/radius.
// Values are read by DKProj_* subclasses in PostBeginPlay.
// ===================================================================
class DKConfig_HowdyProjectiles extends Object
	config(ZedternalUnlimited);

// BileBomb (Plaguebearer skill)
var config float BileBomb_Damage;
var config float BileBomb_Radius;
var config float BileBomb_Deluxe_Damage;
var config float BileBomb_Deluxe_Radius;

// EMPExplosion (Completed Circuit skill)
var config float EMPExplosion_Damage;
var config float EMPExplosion_Radius;
var config float EMPExplosion_Deluxe_Damage;
var config float EMPExplosion_Deluxe_Radius;

// GroundIce (Death Chill skill)
var config float GroundIce_Damage;
var config float GroundIce_Radius;
var config float GroundIce_Deluxe_Damage;
var config float GroundIce_Deluxe_Radius;

// BleedNailBomb (Shatterspleen skill)
var config float BleedNailBomb_Damage;
var config float BleedNailBomb_Radius;
var config float BleedNailBomb_Deluxe_Damage;
var config float BleedNailBomb_Deluxe_Radius;

// ToxicGas (Sudden Bloating skill)
var config float ToxicGas_Damage;
var config float ToxicGas_Radius;
var config float ToxicGas_Deluxe_Damage;
var config float ToxicGas_Deluxe_Radius;

var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.BileBomb_Damage = 20.0f;
		default.BileBomb_Radius = 200.0f;
		default.BileBomb_Deluxe_Damage = 40.0f;
		default.BileBomb_Deluxe_Radius = 400.0f;

		default.EMPExplosion_Damage = 20.0f;
		default.EMPExplosion_Radius = 500.0f;
		default.EMPExplosion_Deluxe_Damage = 40.0f;
		default.EMPExplosion_Deluxe_Radius = 1000.0f;

		default.GroundIce_Damage = 10.0f;
		default.GroundIce_Radius = 100.0f;
		default.GroundIce_Deluxe_Damage = 20.0f;
		default.GroundIce_Deluxe_Radius = 200.0f;

		default.BleedNailBomb_Damage = 15.0f;
		default.BleedNailBomb_Radius = 500.0f;
		default.BleedNailBomb_Deluxe_Damage = 30.0f;
		default.BleedNailBomb_Deluxe_Radius = 1000.0f;

		default.ToxicGas_Damage = 20.0f;
		default.ToxicGas_Radius = 500.0f;
		default.ToxicGas_Deluxe_Damage = 40.0f;
		default.ToxicGas_Deluxe_Radius = 1000.0f;

		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

defaultproperties
{
	Name="Default__DKConfig_HowdyProjectiles"
}
