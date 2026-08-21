// ===================================================================
// ZTUpgrade_Perk_Hivemind - Collective Symbiosis
// Theme: Your evolution empowers the swarm
// Color: Emerald Green + Purple (RGB: 50, 255, 50 / 150, 50, 255)
// Unlock Requirement: Firebug Level 10 + Symbiote Level 10
// ===================================================================
class ZTUpgrade_Perk_Hivemind extends ZTUpgrade_Perk config(ZedternalUnlimited);

// Passive scaling bonuses (Levels 1-20)
var config float TeamDamagePerLevel;           // +2% team damage per level
var config float TeamReloadSpeedPerLevel;      // +3% team reload speed per level
var config float TeamMovementPerSymbioteStage; // +1% movement per Symbiote evolution stage

// Level 10 - Neural Network
var config float NeuralNetworkDamagePerStage;  // +5% damage per Symbiote stage
var config float NeuralNetworkRadius;          // 10m (1000 UU)

// Level 20 - Swarm Collective
var config int SwarmCollectiveKillsRequired;   // 20 kills needed
var config float SwarmCollectiveDuration;      // 8 seconds
var config float SwarmDamageBonus;             // +30% damage
var config float SwarmReloadBonus;             // +50% reload speed
var config float SwarmMovementBonus;           // +15% movement speed
var config float SwarmCooldownSeconds;         // recharge delay after the buff ends - kills do not count during it
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.TeamDamagePerLevel = 0.02f;
		default.TeamReloadSpeedPerLevel = 0.03f;
		default.TeamMovementPerSymbioteStage = 0.01f;
		default.NeuralNetworkDamagePerStage = 0.05f;
		default.NeuralNetworkRadius = 1000.0f;
		default.SwarmCollectiveKillsRequired = 20;
		default.SwarmCollectiveDuration = 8.0f;
		default.SwarmDamageBonus = 0.30f;
		default.SwarmReloadBonus = 0.50f;
		default.SwarmMovementBonus = 0.15f;

		// BEGIN TEMPERED INI DEFAULTS (generated; do not edit by hand)
		default.TeamDamagePerLevel = 0.005000f;
		default.TeamReloadSpeedPerLevel = 0.010000f;
		default.TeamMovementPerSymbioteStage = 0.005000f;
		default.NeuralNetworkDamagePerStage = 0.012500f;
		default.NeuralNetworkRadius = 500.000000f;
		default.SwarmCollectiveKillsRequired = 20;
		default.SwarmCollectiveDuration = 8.000000f;
		default.SwarmDamageBonus = 0.100000f;
		default.SwarmReloadBonus = 0.125000f;
		default.SwarmMovementBonus = 0.075000f;
		// END TEMPERED INI DEFAULTS
		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}

	// v2: Swarm Collective cooldown. Without it, late-wave zed density
	// refills the 20-kill counter the moment the buff ends, re-triggering
	// roughly every 10 seconds. Kills do not count while on cooldown.
	if (default.MODEVERSION < 2)
	{
		default.SwarmCooldownSeconds = 45.0f;

		default.MODEVERSION = 2;
		static.StaticSaveConfig();
	}
}


// ===================================================================
// Team Damage Bonus
// ===================================================================
static function ModifyDamageGiven(out int InDamage, int DefaultDamage, int upgLevel,
	optional Actor DamageCauser, optional KFPawn_Monster MyKFPM,
	optional KFPlayerController DamageInstigator, optional class<KFDamageType> DamageType,
	optional int HitZoneIdx, optional KFWeapon MyKFW)
{
	local ZTUpgrade_Perk_Hivemind_Helper HivemindHelper;
	local ZTUpgrade_Perk_Symbiote_Helper SymbioteHelper;
	local KFPawn_Human HivemindPlayer;
	local float TotalBonus;
	local int SymbioteEvolutions;
	local float Distance;
	
	if (DamageInstigator == None || DamageInstigator.Pawn == None)
		return;
	
	TotalBonus = 0.0f;
	
	// Find nearby Hivemind players and check their buffs
	foreach DamageInstigator.WorldInfo.AllPawns(class'KFPawn_Human', HivemindPlayer)
	{
		if (HivemindPlayer == None || !HivemindPlayer.IsAliveAndWell())
			continue;
		
		// Check if this player has Hivemind helper
		HivemindHelper = GetHelper(HivemindPlayer);
		if (HivemindHelper == None)
			continue;
		
		// Check if we're within buff radius of this Hivemind player
		Distance = VSize(DamageInstigator.Pawn.Location - HivemindPlayer.Location);
		if (Distance > default.NeuralNetworkRadius)
			continue;
		
		// Apply passive team damage bonus
		TotalBonus += default.TeamDamagePerLevel * HivemindHelper.UpgradeLevel;
		
		// Level 10+: Neural Network - bonus based on Symbiote stage
		if (HivemindHelper.UpgradeLevel >= class'ZTConfig_Capstone'.default.Capstone_Rank1Level)
		{
			// Get Hivemind player's Symbiote evolution count
			SymbioteHelper = class'ZTUpgrade_Perk_Symbiote'.static.GetHelper(HivemindPlayer);
			if (SymbioteHelper != None)
			{
				SymbioteEvolutions = SymbioteHelper.TotalEvolutions;
				if (SymbioteEvolutions > 0)
				{
					TotalBonus += default.NeuralNetworkDamagePerStage * float(SymbioteEvolutions);
				}
			}
		}
		
		// Level 20: Swarm Collective active bonus
		if (HivemindHelper.UpgradeLevel >= class'ZTConfig_Capstone'.default.Capstone_Rank2Level && HivemindHelper.bSwarmCollectiveActive)
		{
			TotalBonus += default.SwarmDamageBonus;
		}
	}
	
	if (TotalBonus > 0.0f)
	{
		InDamage += Round(float(DefaultDamage) * TotalBonus);
	}
	
	// ===================================================================
	// KILL TRACKING FOR SWARM COLLECTIVE
	// ===================================================================
	// Track kills for the damage instigator if they have Hivemind
	if (DamageInstigator != None && DamageInstigator.Pawn != None && MyKFPM != None)
	{
		HivemindHelper = GetHelper(DamageInstigator.Pawn);
		if (HivemindHelper != None)
		{
			// Check if this damage will kill the monster
			if ((MyKFPM.Health - InDamage) <= 0)
			{
				`log("Hivemind: Detected kill - calling OnKill for" @ DamageInstigator.PlayerReplicationInfo.PlayerName);
				HivemindHelper.OnKill(MyKFPM);
			}
		}
	}
}

// ===================================================================
// Team Reload Speed Bonus
// ===================================================================
static simulated function GetReloadRateScale(out float InReloadRateScale, int upgLevel, KFWeapon KFW, KFPawn OwnerPawn)
{
	local ZTUpgrade_Perk_Hivemind_Helper HivemindHelper;
	local KFPawn_Human HivemindPlayer;
	local float ReloadBonus;
	local float Distance;
	
	if (OwnerPawn == None)
		return;
	
	ReloadBonus = 0.0f;
	
	// Find nearby Hivemind players and check their buffs
	foreach OwnerPawn.WorldInfo.AllPawns(class'KFPawn_Human', HivemindPlayer)
	{
		if (HivemindPlayer == None || !HivemindPlayer.IsAliveAndWell())
			continue;
		
		// Check if this player has Hivemind helper
		HivemindHelper = GetHelper(HivemindPlayer);
		if (HivemindHelper == None)
			continue;
		
		// Check if we're within buff radius of this Hivemind player
		Distance = VSize(OwnerPawn.Location - HivemindPlayer.Location);
		if (Distance > default.NeuralNetworkRadius)
			continue;
		
		// Apply passive team reload speed bonus
		ReloadBonus += default.TeamReloadSpeedPerLevel * HivemindHelper.UpgradeLevel;
		
		// Level 20: Swarm Collective active bonus
		if (HivemindHelper.UpgradeLevel >= class'ZTConfig_Capstone'.default.Capstone_Rank2Level && HivemindHelper.bSwarmCollectiveActive)
		{
			ReloadBonus += default.SwarmReloadBonus;
		}
	}
	
	if (ReloadBonus > 0.0f)
	{
		InReloadRateScale = 1.f / (1.f/InReloadRateScale + ReloadBonus);
	}
}

// ===================================================================
// Team Movement Speed Bonus
// ===================================================================
static simulated function ModifySpeed(out float InSpeed, float DefaultSpeed, int upgLevel, KFPawn OwnerPawn)
{
	local ZTUpgrade_Perk_Hivemind_Helper HivemindHelper;
	local ZTUpgrade_Perk_Symbiote_Helper SymbioteHelper;
	local KFPawn_Human HivemindPlayer;
	local float SpeedBonus;
	local int SymbioteEvolutions;
	local float Distance;
	
	if (OwnerPawn == None)
		return;
	
	SpeedBonus = 0.0f;
	
	// Find nearby Hivemind players and check their buffs
	foreach OwnerPawn.WorldInfo.AllPawns(class'KFPawn_Human', HivemindPlayer)
	{
		if (HivemindPlayer == None || !HivemindPlayer.IsAliveAndWell())
			continue;
		
		// Check if this player has Hivemind helper
		HivemindHelper = GetHelper(HivemindPlayer);
		if (HivemindHelper == None)
			continue;
		
		// Check if we're within buff radius of this Hivemind player
		Distance = VSize(OwnerPawn.Location - HivemindPlayer.Location);
		if (Distance > default.NeuralNetworkRadius)
			continue;
		
		// Passive bonus: Movement speed per Symbiote evolution
		SymbioteHelper = class'ZTUpgrade_Perk_Symbiote'.static.GetHelper(HivemindPlayer);
		if (SymbioteHelper != None)
		{
			SymbioteEvolutions = SymbioteHelper.TotalEvolutions;
			if (SymbioteEvolutions > 0)
			{
				SpeedBonus += default.TeamMovementPerSymbioteStage * float(SymbioteEvolutions);
			}
		}
		
		// Level 20: Swarm Collective active bonus
		if (HivemindHelper.UpgradeLevel >= class'ZTConfig_Capstone'.default.Capstone_Rank2Level && HivemindHelper.bSwarmCollectiveActive)
		{
			SpeedBonus += default.SwarmMovementBonus;
		}
	}
	
	if (SpeedBonus > 0.0f)
	{
		InSpeed += DefaultSpeed * SpeedBonus;
	}
}

// ===================================================================
// Helper Management
// ===================================================================
static simulated function InitiateWeapon(int upgLevel, KFWeapon KFW, KFPawn OwnerPawn)
{
	local ZTUpgrade_Perk_Hivemind_Helper Helper;
	local KFPawn_Human HumanPawn;
	
	HumanPawn = KFPawn_Human(OwnerPawn);
	if (HumanPawn == None)
		return;
	
	// Only create helper on server
	if (OwnerPawn.Role != ROLE_Authority)
		return;
	
	// Check if helper already exists
	foreach OwnerPawn.ChildActors(class'ZTUpgrade_Perk_Hivemind_Helper', Helper)
	{
		Helper.SetUpgradeLevel(upgLevel);
		return;
	}
	
	// Spawn new helper
	Helper = OwnerPawn.Spawn(class'ZTUpgrade_Perk_Hivemind_Helper', OwnerPawn);
	if (Helper != None)
	{
		Helper.Initialize(HumanPawn, upgLevel);
		`log("Hivemind: Spawned helper for" @ OwnerPawn.PlayerReplicationInfo.PlayerName);
	}
}

static function ZTUpgrade_Perk_Hivemind_Helper GetHelper(Pawn OwnerPawn)
{
	local ZTUpgrade_Perk_Hivemind_Helper Helper;
	
	if (KFPawn_Human(OwnerPawn) != None)
	{
		foreach OwnerPawn.ChildActors(class'ZTUpgrade_Perk_Hivemind_Helper', Helper)
			return Helper;
	}
	
	return None;
}

static simulated function DeleteHelperClass(Pawn OwnerPawn)
{
	local ZTUpgrade_Perk_Hivemind_Helper Helper;
	
	if (OwnerPawn != None)
	{
		foreach OwnerPawn.ChildActors(class'ZTUpgrade_Perk_Hivemind_Helper', Helper)
		{
			Helper.Cleanup();
			Helper.Destroy();
		}
	}
}

// ===================================================================
// Default Properties
// ===================================================================
defaultproperties
{
	UpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Hivemind_Rank_0'
    // --- Localization (auto-generated by mass_localize_dk_upgrades.py) ---
    // Strings live in KFGame/Localization/<lang>/ZedternalTempered.<langext>
    // Section: [ZTUpgrade_Perk_Hivemind]  -- see DKUpgrade_* base class for details.
    bShouldLocalize=True
    LocPackage="ZedternalTempered"
    LocSection="ZTUpgrade_Perk_Hivemind"
    LocalizeDescriptionLineCount=5

	// Passive bonuses (Levels 1-20)
	
	// Level 10 - Neural Network
	
	// Level 20 - Swarm Collective
	
	// UI and description
	upgradeName="Hivemind"
	
	// PerkBonus for UI display
	PerkBonus(0)=(baseValue=0, incValue=1, maxValue=-1)    // Team damage %
	PerkBonus(1)=(baseValue=0, incValue=1, maxValue=-1)    // Team reload speed %
	PerkBonus(2)=(baseValue=1, incValue=0, maxValue=50)    // Neural Network % per stage
	PerkBonus(3)=(baseValue=10, incValue=0, maxValue=10)   // Swarm Collective damage %
	
	upgradeDescription(0)="<font color=\"#32FF32\">Synaptic Link:</font> <font color=\"#FFFFFF\">+%x%%</font> <font color=\"#7FFF7F\">Team Damage</font> within <font color=\"#FFFFFF\">10m</font>"
	upgradeDescription(1)="<font color=\"#32FF32\">Neural Efficiency:</font> <font color=\"#FFFFFF\">+%x%%</font> <font color=\"#7FFF7F\">Team Reload Speed</font> within <font color=\"#FFFFFF\">10m</font>"
	upgradeDescription(2)="<font color=\"#32FF32\">Hive Movement:</font> <font color=\"#FFFFFF\">+0.5%</font> <font color=\"#7FFF7F\">Team Movement Speed</font> per <font color=\"#7FFF7F\">Symbiote evolution stage</font> (within 10m)"
	upgradeDescription(3)="<font color=\"#8B0000\">LEVEL 5:</font> <font color=\"#FFD700\">Neural Network</font> - Teammates within <font color=\"#FFFFFF\">5m</font> gain <font color=\"#FFFFFF\">+1.25%</font> damage per <font color=\"#7FFF7F\">Symbiote evolution stage</font> (max <font color=\"#FFFFFF\">+12.5%</font>)"
	upgradeDescription(4)="<font color=\"#8B0000\">LEVEL 20:</font> <font color=\"#FFD700\">Swarm Collective</font> - Every <font color=\"#FFFFFF\">20</font> kills triggers a team-wide buff: <font color=\"#FFFFFF\">+10%</font> Damage, <font color=\"#FFFFFF\">+12.5%</font> Reload Speed, <font color=\"#FFFFFF\">+7.5%</font> Movement Speed for <font color=\"#FFFFFF\">8 seconds</font>"
	
	// Icon references (21 total: Rank_0 through Rank_20)
	
	// Legacy (hand-made) artwork icons

	Name="Default__ZTUpgrade_Perk_Hivemind"
}
