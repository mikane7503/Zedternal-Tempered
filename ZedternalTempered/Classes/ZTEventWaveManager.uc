// ===================================================================
// ZTEventWaveManager ? Server-side event wave logic controller
//
// Spawned by GameInfo when an event that needs server logic starts.
// Handles: target selection, swap timers, damage modification,
// proximity checks, magazine clamping, zed enrage.
//
// One instance per match, reused across waves.
// ===================================================================
class ZTEventWaveManager extends Info;

// Current active event
var byte ActiveEventID;

// Target tracking (VIP, Hot Potato, Highlander, Marked for Death)
var KFPlayerController TargetPC;
var PlayerReplicationInfo TargetPRI;

// Amogus ? NOT replicated, server-only secret
var KFPlayerController ImpostorPC;

// Swap timer for events 10, 12, 18
var float SwapInterval;
var float SwapTimer;

// VIP tracking
var KFPawn_Human VIPPawn;
var bool bVIPDied;

// Chain Gang
const CHAIN_GANG_RADIUS = 1000.f;
const CHAIN_GANG_BLEED = 5;

// One in the Chamber
var bool bChamberActive;

// Fog of War
const FOW_VISIBILITY_RANGE = 900.0f; // ~15 meters (1 UU = ~1.9cm, 900 UU = ~17m)

// Nemesis
var KFPawn_Monster NemesisPawn;
var byte NemesisCategory; // Which zed category is the Nemesis type
var bool bNemesisSpawned;

// Duel
var array<KFPlayerController> DuelPlayers;
var byte CategoryOwner[10]; // Player index that owns each zed category (255 = unassigned)

// Event wave music ? one SoundCue per event (None = no custom music)
var SoundCue EventMusic_Isolation;
var SoundCue EventMusic_BlackoutPulse;
var SoundCue EventMusic_VIP;
var SoundCue EventMusic_HotPotato;
var SoundCue EventMusic_Highlander;
var SoundCue EventMusic_RAGE;
var SoundCue EventMusic_Amogus;
var SoundCue EventMusic_ChainGang;
var SoundCue EventMusic_OneInTheChamber;
var SoundCue EventMusic_Paranoia;
var SoundCue EventMusic_MarkedForDeath;
var SoundCue EventMusic_Redacted;
var SoundCue EventMusic_FogOfWar;
var SoundCue EventMusic_Nemesis;
var SoundCue EventMusic_Duel;
var SoundCue EventMusic_XMen;
var SoundCue EventMusic_Jitterbug;
var SoundCue EventMusic_CostumeParty;
var SoundCue EventMusic_DontBlink;
var SoundCue EventMusic_PassTheBomb;
var SoundCue EventMusic_RedLightGreenLight;
var SoundCue EventMusic_FloorIsLava;
var SoundCue EventMusic_BodyguardBond;
var SoundCue EventMusic_BountyBoard;
var SoundCue EventMusic_GoldenZedRelay;
var bool bEventMusicLoaded;
var float EventMusicFadeOutDuration;

// R.A.G.E. modifiers
const RAGE_ZED_SPAWN_MULTIPLIER = 3;
const RAGE_ZED_SPEED_MULTIPLIER = 2.0;
const RAGE_PLAYER_DAMAGE_MULTIPLIER = 1.5;

// X-Men power constants
const POWER_WOLVERINE = 0;
const POWER_COLOSSUS = 1;
const POWER_CYCLOPS = 2;
const POWER_HULK = 3;
const POWER_STORM = 4;
const POWER_DOMINO = 5;
const POWER_SUNSPOT = 6;
const POWER_ROGUE = 7;
const POWER_QUICKSILVER = 8;
const POWER_JUGGERNAUT = 9;
const NUM_XMEN_POWERS = 10;
const STORM_AOE_RADIUS = 500.0;
const STORM_AOE_DAMAGE = 200;

struct XMenPlayerState
{
	var KFPlayerController PC;
	var byte PowerID;
	var int KillCount;
	var float StoredGroundSpeed;
	var float StoredSprintSpeed;
	var int StoredHealth;
	var int StoredHealthMax;
	var int StoredArmor;
	var int StoredArmorMax;
};
var array<XMenPlayerState> XMenPlayers;

// Zed category constants
const ZCAT_CLOT = 0;
const ZCAT_CRAWLER = 1;
const ZCAT_STALKER = 2;
const ZCAT_GOREFAST = 3;
const ZCAT_BLOAT = 4;
const ZCAT_HUSK = 5;
const ZCAT_SIREN = 6;
const ZCAT_SCRAKE = 7;
const ZCAT_FLESHPOUND = 8;
const ZCAT_EDAR = 9;
const ZCAT_UNKNOWN = 255;

// ===================================================================
// 24. JITTERBUG - per-zed randomized walk + sprint speed
// ===================================================================
const JITTERBUG_MIN_SPEED_MULT = 0.35f;
const JITTERBUG_MAX_SPEED_MULT = 2.25f;

// ===================================================================
// 25. COSTUME PARTY - per-zed randomized visual draw scale (cosmetic only)
// ===================================================================
const COSTUME_MIN_SCALE = 0.5f;
const COSTUME_MAX_SCALE = 2.5f;

// ===================================================================
// 26. DON'T BLINK - zeds freeze + charge while watched, lunge on blink
// ===================================================================
const DONTBLINK_TICK = 0.1f;            // gaze loop interval (s)
const DONTBLINK_CHARGE_RATE = 0.35f;    // intensity gained per second while watched
const DONTBLINK_DECAY_RATE = 0.20f;     // intensity lost per second while unwatched
const DONTBLINK_SPEED_BONUS = 2.0f;     // speed  = base * (1 + BONUS * intensity)
const DONTBLINK_DAMAGE_BONUS = 2.5f;    // damage = base * (1 + BONUS * intensity)
const DONTBLINK_VIEW_DOT = 0.93f;       // cos of half view-cone (~21.5 deg)
const DONTBLINK_VIEW_RANGE = 4000.f;    // max watch distance (UU, ~80 m - was 12000 which froze zeds map-wide)
const DONTBLINK_FREEZE_SPEED = 1.0f;    // near-zero speed while frozen
var bool bDontBlinkUseTrace;            // line-of-sight trace so walls break the gaze (on by default)

struct DontBlinkZed
{
	var KFPawn_Monster Zed;
	var float Intensity;
	var float BaseGround;
	var float BaseSprint;
};
var array<DontBlinkZed> DBZeds;

// --- 27. Pass The Bomb ---
const BOMB_FUSE_BASE = 20.f;      // starting fuse per cycle (s)
const BOMB_FUSE_MIN = 8.f;        // fuse never shorter than this
const BOMB_FUSE_DECAY = 2.f;      // fuse lost per successful pass (s)
const BOMB_TRANSFER_RADIUS = 300.f;   // touch range to hand off (UU)
const BOMB_TRANSFER_LOCK = 3.f;   // no hand-off possible right after a pass (s)
const BOMB_BLAST_RADIUS = 600.f;  // splash range on detonation (UU)
var float BombFuseEnd;
var float BombLockUntil;
var int BombPassCount;
var KFPlayerController BombPrevHolder;

// --- 28. Red Light, Green Light ---
const RLGL_GREEN_MIN = 8.f;
const RLGL_GREEN_MAX = 15.f;
const RLGL_WARN_TIME = 1.2f;
const RLGL_RED_TIME = 4.f;
const RLGL_MOVE_THRESHOLD = 60.f;   // velocity above this during red = punished
const RLGL_TICK_DMG_PCT = 0.02f;    // fraction of max HP per punish tick

// --- 29. The Floor Is Lava ---
const LAVA_RADIUS = 900.f;          // safe zone radius (UU, ~18 m)
const LAVA_RELOCATE = 25.f;         // zone lifetime before moving (s)
const LAVA_TELEGRAPH = 5.f;         // warning before the move lands (s)
const LAVA_TICK_DMG_PCT = 0.025f;   // fraction of max HP per 0.5s tick outside
const LAVA_KILL_DOSH = 15;          // bonus dosh per kill scored inside the zone
var array<vector> LavaAnchors;
var vector NextLavaLoc;

// --- 30. Bodyguard Bond ---
const BOND_NEAR_RADIUS = 600.f;     // partners within this: protected (UU, ~12 m)
const BOND_NEAR_RESIST = 0.75f;     // damage taken multiplier while together
const BOND_MIRROR_FRACTION = 0.5f;  // share of damage mirrored to a distant partner
var array<KFPlayerController> BondPCs;
var array<int> BondPartner;         // index into BondPCs; parallel to BondPCs
var bool bBondMirroring;            // recursion guard for the mirrored TakeDamage

// --- 31. Bounty Board ---
const BOUNTY_REWARD_DOSH = 400;     // per player, only if EVERY quota completes
var array<KFPlayerController> BountyPCs;
var array<byte> BountyCat;
var array<int> BountyNeed;
var array<int> BountyHave;

// --- 32. Golden Zed Relay ---
const GOLDEN_INTERVAL = 20.f;       // time between golden picks (s)
const GOLDEN_SCALE = 1.4f;          // body scale multiplier
const GOLDEN_SPEED = 1.25f;         // speed multiplier
const GOLDEN_DROP_WINDOW = 10.f;    // trophy lifetime on the ground (s)
const GOLDEN_DROP_RADIUS = 200.f;   // pickup touch range (UU)
const GOLDEN_TEAM_DOSH = 100;       // paid to EVERY player per banked trophy
var KFPawn_Monster GoldenZed;
var PlayerReplicationInfo GoldenKillerPRI;
var vector GoldenDropLoc;
var float GoldenDropExpire;

// ===================================================================
// EVENT START / STOP
// ===================================================================

function StartEvent(byte EventID)
{
	local SoundCue MusicCue;

	ActiveEventID = EventID;

	// Lazy-load event music SoundCues on first event start
	if (!bEventMusicLoaded)
	{
		LoadEventMusic();
	}

	// Play event music (if a SoundCue exists for this event)
	MusicCue = GetEventMusicCue(EventID);
	if (MusicCue != None)
	{
		PlayEventMusicToAll(MusicCue);
	}

	switch (EventID)
	{
		case 9:  StartVIP(); break;
		case 10: StartHotPotato(); break;
		case 12: StartHighlander(); break;
		case 13: StartRAGE(); break;
		case 14: StartAmogus(); break;
		case 15: StartChainGang(); break;
		case 16: StartOneInTheChamber(); break;
		case 18: StartMarkedForDeath(); break;
		case 20: StartFogOfWar(); break;
		case 21: StartNemesis(); break;
		case 22: StartDuel(); break;
		case 23: StartXMen(); break;
		case 24: StartJitterbug(); break;
		case 25: StartCostumeParty(); break;
		case 26: StartDontBlink(); break;
		case 27: StartPassTheBomb(); break;
		case 28: StartRedLightGreenLight(); break;
		case 29: StartFloorIsLava(); break;
		case 30: StartBodyguardBond(); break;
		case 31: StartBountyBoard(); break;
		case 32: StartGoldenZedRelay(); break;
	}

	`log("[DK_EVENTWAVE_MGR] Started event:" @ class'ZTConfig_EventWave'.static.GetEventName(EventID));
}

function EndEvent()
{
	`log("[DK_EVENTWAVE_MGR] Ending event:" @ class'ZTConfig_EventWave'.static.GetEventName(ActiveEventID));

	// Stop event music before clearing state
	StopEventMusicForAll();

	switch (ActiveEventID)
	{
		case 9:  EndVIP(); break;
		case 16: EndOneInTheChamber(); break;
		case 20: EndFogOfWar(); break;
		case 21: EndNemesis(); break;
		case 22: EndDuel(); break;
		case 23: EndXMen(); break;
		case 26: EndDontBlink(); break;
		case 31: EndBountyBoard(); break;
	}

	ClearTimer('SwapTargetTimer');
	ClearTimer('CheckChainGangProximity');
	ClearTimer('ApplyOITCToAllWeapons');
	ClearTimer('EnforceVIPHealth');
	ClearTimer('UpdateFogOfWarVisibility');
	ClearTimer('ApplyRAGEModifiers');
	ClearTimer('EnforceXMenPawnMods');
	ClearTimer('UpdateDontBlink');
	ClearTimer('BombTick');
	ClearTimer('RLGLWarn');
	ClearTimer('RLGLRed');
	ClearTimer('RLGLGreen');
	ClearTimer('RLGLRedTick');
	ClearTimer('LavaTelegraph');
	ClearTimer('LavaRelocate');
	ClearTimer('LavaTick');
	ClearTimer('PickGoldenZed');
	ClearTimer('GoldenTick');

	TargetPC = None;
	TargetPRI = None;
	ImpostorPC = None;
	VIPPawn = None;
	bVIPDied = False;
	bChamberActive = False;
	NemesisPawn = None;
	bNemesisSpawned = False;
	DuelPlayers.Length = 0;
	DBZeds.Length = 0;
	BombPassCount = 0;
	BombPrevHolder = None;
	LavaAnchors.Length = 0;
	BondPCs.Length = 0;
	BondPartner.Length = 0;
	bBondMirroring = False;
	BountyPCs.Length = 0;
	BountyCat.Length = 0;
	BountyNeed.Length = 0;
	BountyHave.Length = 0;
	GoldenZed = None;
	GoldenKillerPRI = None;
	ActiveEventID = 0;

	ClearGRIMinigameExtras();
	ClearAllClientMinigameData();
	UpdateGRITarget(None);
}

// ===================================================================
// TARGET SELECTION HELPER
// ===================================================================

function KFPlayerController PickRandomPlayer(optional KFPlayerController Exclude)
{
	local array<KFPlayerController> Candidates;
	local KFPlayerController KFPC;

	foreach WorldInfo.AllControllers(class'KFPlayerController', KFPC)
	{
		if (KFPC.Pawn != None && KFPC.Pawn.IsAliveAndWell() && KFPC != Exclude)
			Candidates.AddItem(KFPC);
	}

	if (Candidates.Length == 0)
		return None;

	return Candidates[Rand(Candidates.Length)];
}

function UpdateGRITarget(PlayerReplicationInfo NewTarget)
{
	local ZTGameReplicationInfo DKGRI;

	DKGRI = ZTGameReplicationInfo(WorldInfo.GRI);
	if (DKGRI != None)
	{
		DKGRI.EventWaveTargetPRI = NewTarget;

		// Publish the auto-swap period so the HUD can show a countdown.
		// VIP (9) is fixed for the wave -> 0 (no countdown); other targeted
		// events use the manager's SwapInterval (15s Potato/Highlander, 20s Marked).
		if (NewTarget == None || ActiveEventID == 9)
			DKGRI.EventSwapInterval = 0;
		else
			DKGRI.EventSwapInterval = byte(SwapInterval);

		DKGRI.bForceNetUpdate = True;
	}
}

// ===================================================================
// 9. VIP
// ===================================================================

function StartVIP()
{
	TargetPC = PickRandomPlayer();
	if (TargetPC == None) return;

	TargetPRI = TargetPC.PlayerReplicationInfo;
	VIPPawn = KFPawn_Human(TargetPC.Pawn);
	bVIPDied = False;

	UpdateGRITarget(TargetPRI);

	SetTimer(0.25f, true, 'EnforceVIPHealth');

	`log("[DK_EVENTWAVE_MGR] VIP:" @ TargetPRI.PlayerName);
}

function EnforceVIPHealth()
{
	if (VIPPawn == None || !VIPPawn.IsAliveAndWell())
		return;

	if (VIPPawn.HealthMax != 1)
		VIPPawn.HealthMax = 1;
	if (VIPPawn.Health > 1)
		VIPPawn.Health = 1;
}

function EndVIP()
{
	local KFPlayerController KFPC;
	local KFPlayerReplicationInfo KFPRI;
	local int DoshChange;

	// Restore VIP health
	if (VIPPawn != None && VIPPawn.IsAliveAndWell())
	{
		VIPPawn.HealthMax = VIPPawn.default.Health;
		VIPPawn.Health = VIPPawn.HealthMax;
	}

	if (bVIPDied)
		DoshChange = -500;
	else
		DoshChange = 500;

	foreach WorldInfo.AllControllers(class'KFPlayerController', KFPC)
	{
		KFPRI = KFPlayerReplicationInfo(KFPC.PlayerReplicationInfo);
		if (KFPRI != None)
		{
			KFPRI.AddDosh(DoshChange);
			if (bVIPDied)
				KFPC.ClientMessage("VIP DIED! -500 Dosh");
			else
				KFPC.ClientMessage("VIP SURVIVED! +500 Dosh");
		}
	}
}

function NotifyPlayerDied(KFPlayerController DeadPC)
{
	if (ActiveEventID == 9 && DeadPC == TargetPC)
	{
		bVIPDied = True;
		`log("[DK_EVENTWAVE_MGR] VIP died:" @ TargetPRI.PlayerName);
	}
	else if (ActiveEventID == 22)
	{
		ReassignDuelCategories(DeadPC);
	}
}

// ===================================================================
// 10. HOT POTATO
// ===================================================================

function StartHotPotato()
{
	SwapInterval = 15.f;
	TargetPC = PickRandomPlayer();
	if (TargetPC == None) return;

	TargetPRI = TargetPC.PlayerReplicationInfo;
	UpdateGRITarget(TargetPRI);
	SetTimer(SwapInterval, true, 'SwapTargetTimer');

	`log("[DK_EVENTWAVE_MGR] Hot Potato marked:" @ TargetPRI.PlayerName);
}

// ===================================================================
// 12. HIGHLANDER
// ===================================================================

function StartHighlander()
{
	SwapInterval = 15.f;
	TargetPC = PickRandomPlayer();
	if (TargetPC == None) return;

	TargetPRI = TargetPC.PlayerReplicationInfo;
	UpdateGRITarget(TargetPRI);
	SetTimer(SwapInterval, true, 'SwapTargetTimer');

	`log("[DK_EVENTWAVE_MGR] Highlander active:" @ TargetPRI.PlayerName);
}

// ===================================================================
// 13. R.A.G.E.
// ===================================================================

function StartRAGE()
{
	// Delay spawn tripling until after Super.StartWave()
	// populates GroupList via SetupNextWave
	SetTimer(0.5, false, 'ApplyRAGEModifiers');

	`log("[DK_EVENTWAVE_MGR] R.A.G.E. started");
}

function ApplyRAGEModifiers()
{
	// Triple the spawn queue (GroupList is now populated)
	TripleSpawnQueue();

	// Enrage any zeds already alive
	EnrageAllZeds();

	`log("[DK_EVENTWAVE_MGR] R.A.G.E. spawn tripling applied");
}

function EnrageAllZeds()
{
	local KFPawn_Monster KFPM;

	foreach WorldInfo.AllPawns(class'KFPawn_Monster', KFPM)
	{
		if (KFPM.IsAliveAndWell())
		{
			KFPM.SetEnraged(True);
			KFPM.SetSprinting(True);
		}
	}
}

function TripleSpawnQueue()
{
	local WMAISpawnManager SM;
	local KFGameReplicationInfo KFGRI;
	local int i, OrigLen;
	local WMAISpawnManager.S_Spawn_Group TempGroup;

	SM = WMAISpawnManager(KFGameInfo(WorldInfo.Game).SpawnManager);
	KFGRI = KFGameReplicationInfo(WorldInfo.GRI);

	if (SM == None || KFGRI == None)
	{
		return;
	}

	OrigLen = SM.GroupList.Length;
	if (OrigLen == 0)
	{
		return;
	}

	// Duplicate the entire GroupList twice (original + 2 copies = 3x total)
	for (i = 0; i < OrigLen * (RAGE_ZED_SPAWN_MULTIPLIER - 1); i++)
	{
		TempGroup = SM.GroupList[i % OrigLen];
		SM.GroupList.AddItem(TempGroup);
	}

	SM.WaveTotalAI *= RAGE_ZED_SPAWN_MULTIPLIER;
	KFGRI.AIRemaining = SM.WaveTotalAI;

	`log("[DK_EVENTWAVE_MGR] R.A.G.E. tripled spawns: WaveTotalAI=" $ SM.WaveTotalAI @ "GroupList=" $ SM.GroupList.Length);
}

function OnZedSpawned(KFPawn_Monster Zed)
{
	// R.A.G.E.: immediately enrage ? speed boost handled by EnforceRAGESpeed timer
	if (ActiveEventID == 13 && Zed != None)
	{
		Zed.SetEnraged(True);
		Zed.SetSprinting(True);
	}

	// Nemesis: buff the first zed of the chosen category
	if (ActiveEventID == 21 && Zed != None && !bNemesisSpawned)
	{
		if (GetZedCategory(Zed) == NemesisCategory)
		{
			ApplyNemesisBuffs(Zed);
		}
	}

	// Jitterbug: randomize this zed's walk + sprint speed
	if (ActiveEventID == 24 && Zed != None)
	{
		ApplyJitterbugSpeed(Zed);
	}

	// Costume Party: randomize this zed's visual scale (cosmetic only)
	if (ActiveEventID == 25 && Zed != None)
	{
		ApplyCostumeScale(Zed);
	}

	// Don't Blink: register this zed so the gaze loop tracks it from birth
	if (ActiveEventID == 26 && Zed != None)
	{
		RegisterDontBlinkZed(Zed);
	}
}

// ===================================================================
// 14. AMOGUS
// ===================================================================

function StartAmogus()
{
	ImpostorPC = PickRandomPlayer();
	if (ImpostorPC != None)
		`log("[DK_EVENTWAVE_MGR] Amogus impostor:" @ ImpostorPC.PlayerReplicationInfo.PlayerName @ "(SECRET)");
}

function bool IsImpostor(Controller C)
{
	return (ActiveEventID == 14 && C != None && C == ImpostorPC);
}

// ===================================================================
// 15. CHAIN GANG
// ===================================================================

function StartChainGang()
{
	SetTimer(1.f, true, 'CheckChainGangProximity');
}

function CheckChainGangProximity()
{
	local KFPlayerController KFPC;
	local array<KFPawn_Human> AlivePawns;
	local KFPawn_Human KFPH;
	local vector GroupCenter;
	local int i;
	local float Dist;

	foreach WorldInfo.AllControllers(class'KFPlayerController', KFPC)
	{
		KFPH = KFPawn_Human(KFPC.Pawn);
		if (KFPH != None && KFPH.IsAliveAndWell())
		{
			AlivePawns.AddItem(KFPH);
			GroupCenter += KFPH.Location;
		}
	}

	if (AlivePawns.Length <= 1)
		return;

	GroupCenter /= float(AlivePawns.Length);

	for (i = 0; i < AlivePawns.Length; ++i)
	{
		Dist = VSize(AlivePawns[i].Location - GroupCenter);
		if (Dist > CHAIN_GANG_RADIUS)
		{
			AlivePawns[i].TakeDamage(CHAIN_GANG_BLEED, None, AlivePawns[i].Location, vect(0,0,0), class'DmgType_Fell');
		}
	}
}

// ===================================================================
// 16. ONE IN THE CHAMBER
// ===================================================================

function StartOneInTheChamber()
{
	bChamberActive = True;
	ApplyOITCToAllWeapons();
	SetTimer(2.0f, true, 'ApplyOITCToAllWeapons');
}

// Apply OITC magazine limit to all weapons for all players
// Uses MagazineCapacity instead of AmmoCount to avoid fighting the reload state machine
function ApplyOITCToAllWeapons()
{
	local KFPlayerController KFPC;
	local KFWeapon KFW;
	local Inventory Inv;
	local KFPawn_Human KFPH;

	if (!bChamberActive)
		return;

	foreach WorldInfo.AllControllers(class'KFPlayerController', KFPC)
	{
		KFPH = KFPawn_Human(KFPC.Pawn);
		if (KFPH == None || KFPH.InvManager == None) continue;

		for (Inv = KFPH.InvManager.InventoryChain; Inv != None; Inv = Inv.Inventory)
		{
			KFW = KFWeapon(Inv);
			if (KFW == None) continue;
			if (KFW.bMeleeWeapon) continue;
			if (KFW.IsA('KFWeap_Welder')) continue;
			if (KFW.IsA('KFWeap_Healer_Syringe')) continue;

			// Set capacity to 1 (only needs to happen once per weapon)
			if (KFW.MagazineCapacity[0] > 1)
			{
				KFW.MagazineCapacity[0] = 1;
			}

			// Always clamp current ammo (may need repeated enforcement)
			if (KFW.AmmoCount[0] > 1)
			{
				KFW.AmmoCount[0] = 1;
			}
		}
	}
}

// Grant 1 ammo to the killer's current weapon on zed kill during OITC
function NotifyZedKilledOITC(Controller Killer)
{
	local KFWeapon KFW;
	local KFPawn_Human KFPH;

	if (!bChamberActive || Killer == None) return;

	KFPH = KFPawn_Human(Killer.Pawn);
	if (KFPH == None) return;

	KFW = KFWeapon(KFPH.Weapon);
	if (KFW == None || KFW.bMeleeWeapon) return;
	if (KFW.IsA('KFWeap_Welder')) return;
	if (KFW.IsA('KFWeap_Healer_Syringe')) return;

	// Grant 1 round to the magazine (the capacity is already clamped to 1,
	// so this just refills it without exceeding the cap)
	if (KFW.AmmoCount[0] < 1)
		KFW.AmmoCount[0] = 1;
}

function EndOneInTheChamber()
{
	local KFPlayerController KFPC;
	local KFWeapon KFW;
	local Inventory Inv;
	local KFPawn_Human KFPH;

	bChamberActive = False;
	ClearTimer('ApplyOITCToAllWeapons');

	// Restore all magazine capacities from class defaults
	foreach WorldInfo.AllControllers(class'KFPlayerController', KFPC)
	{
		KFPH = KFPawn_Human(KFPC.Pawn);
		if (KFPH == None || KFPH.InvManager == None) continue;

		for (Inv = KFPH.InvManager.InventoryChain; Inv != None; Inv = Inv.Inventory)
		{
			KFW = KFWeapon(Inv);
			if (KFW == None) continue;
			if (KFW.bMeleeWeapon) continue;
			if (KFW.IsA('KFWeap_Welder')) continue;
			if (KFW.IsA('KFWeap_Healer_Syringe')) continue;

			// Restore original magazine capacity from class defaults
			KFW.MagazineCapacity[0] = KFW.default.MagazineCapacity[0];
			// Give a full magazine so the player isn't stuck with 1 round
			KFW.AmmoCount[0] = KFW.MagazineCapacity[0];
		}
	}

	`log("[DK_EVENTWAVE_MGR] OITC ended - restored all magazine capacities");
}

// ===================================================================
// 18. MARKED FOR DEATH
// ===================================================================

function StartMarkedForDeath()
{
	SwapInterval = 20.f;
	TargetPC = PickRandomPlayer();
	if (TargetPC == None) return;

	TargetPRI = TargetPC.PlayerReplicationInfo;
	UpdateGRITarget(TargetPRI);
	SetTimer(SwapInterval, true, 'SwapTargetTimer');

	ForceZedsToTarget();

	`log("[DK_EVENTWAVE_MGR] Marked for Death:" @ TargetPRI.PlayerName);
}

function ForceZedsToTarget()
{
	local KFPawn_Monster KFPM;
	local KFAIController KFAIC;

	if (TargetPC == None || TargetPC.Pawn == None) return;

	foreach WorldInfo.AllPawns(class'KFPawn_Monster', KFPM)
	{
		if (KFPM.IsAliveAndWell())
		{
			KFAIC = KFAIController(KFPM.Controller);
			if (KFAIC != None)
			{
				KFAIC.SetEnemy(TargetPC.Pawn);
			}
		}
	}
}

// ===================================================================
// SHARED SWAP TIMER
// ===================================================================

function SwapTargetTimer()
{
	local KFPlayerController NewTarget;

	NewTarget = PickRandomPlayer(TargetPC);
	if (NewTarget == None)
		return;

	TargetPC = NewTarget;
	TargetPRI = TargetPC.PlayerReplicationInfo;
	UpdateGRITarget(TargetPRI);

	`log("[DK_EVENTWAVE_MGR] Swapped target to:" @ TargetPRI.PlayerName @ "for event" @ ActiveEventID);

	if (ActiveEventID == 18)
		ForceZedsToTarget();
}

// ===================================================================
// DAMAGE MODIFICATION ? Called from GameInfo.NetDamage
// ===================================================================

function int ModifyEventDamage(int Damage, Pawn Injured, Controller InstigatedBy)
{
	switch (ActiveEventID)
	{
		case 10:
			if (KFPawn_Human(Injured) != None && TargetPC != None && Injured == TargetPC.Pawn)
				return Damage * 3;
			break;

		case 12:
			if (KFPawn_Monster(Injured) != None && InstigatedBy != TargetPC)
				return 0;
			break;

		case 13:
			// R.A.G.E. ? players deal 1.5x damage to zeds
			if (KFPawn_Monster(Injured) != None && KFPlayerController(InstigatedBy) != None)
				return Round(float(Damage) * RAGE_PLAYER_DAMAGE_MULTIPLIER);
			break;

		case 22:
			if (KFPawn_Monster(Injured) != None && !CanDuelDamage(InstigatedBy, Injured))
				return 0;
			break;

		case 23:
			return ModifyXMenDamage(Damage, Injured, InstigatedBy);

		case 26:
			// Don't Blink: a charged zed's hit scales with its stored intensity
			if (KFPawn_Human(Injured) != None && InstigatedBy != None && KFPawn_Monster(InstigatedBy.Pawn) != None)
				return Round(float(Damage) * (1.0f + DONTBLINK_DAMAGE_BONUS * GetDontBlinkIntensity(KFPawn_Monster(InstigatedBy.Pawn))));
			break;

		case 30:
			// Bodyguard Bond: protected together, mirrored apart
			return ApplyBondDamage(Damage, Injured);
	}

	return Damage;
}

// Amogus FF ? returns damage if impostor hits teammate (normally blocked by FF)
function int GetAmogusFFDamage(int OriginalDamage, Pawn Injured, Controller InstigatedBy)
{
	if (ActiveEventID != 14) return 0;
	if (ImpostorPC == None) return 0;
	if (InstigatedBy != ImpostorPC) return 0;
	if (KFPawn_Human(Injured) == None) return 0;
	if (Injured == ImpostorPC.Pawn) return 0;

	return OriginalDamage / 2;
}

// ===================================================================
// ZED CATEGORY HELPER
// ===================================================================

function byte GetZedCategory(Pawn P)
{
	local string ClassName;

	if (P == None) return ZCAT_UNKNOWN;

	ClassName = Caps(string(P.Class.Name));

	if (InStr(ClassName, "CLOT") != INDEX_NONE || InStr(ClassName, "CYST") != INDEX_NONE
		|| InStr(ClassName, "SLASHER") != INDEX_NONE || InStr(ClassName, "ALPHA") != INDEX_NONE
		|| InStr(ClassName, "RIOTER") != INDEX_NONE)
		return ZCAT_CLOT;

	if (InStr(ClassName, "CRAWLER") != INDEX_NONE)
		return ZCAT_CRAWLER;

	if (InStr(ClassName, "STALKER") != INDEX_NONE)
		return ZCAT_STALKER;

	if (InStr(ClassName, "GOREFAST") != INDEX_NONE || InStr(ClassName, "GOREFIEND") != INDEX_NONE)
		return ZCAT_GOREFAST;

	if (InStr(ClassName, "BLOAT") != INDEX_NONE && InStr(ClassName, "KING") == INDEX_NONE)
		return ZCAT_BLOAT;

	if (InStr(ClassName, "HUSK") != INDEX_NONE)
		return ZCAT_HUSK;

	if (InStr(ClassName, "SIREN") != INDEX_NONE)
		return ZCAT_SIREN;

	if (InStr(ClassName, "SCRAKE") != INDEX_NONE)
		return ZCAT_SCRAKE;

	if (InStr(ClassName, "FLESHPOUND") != INDEX_NONE)
		return ZCAT_FLESHPOUND;

	if (InStr(ClassName, "EDAR") != INDEX_NONE || InStr(ClassName, "DAR_") != INDEX_NONE)
		return ZCAT_EDAR;

	return ZCAT_UNKNOWN;
}

function string GetCategoryName(byte Cat)
{
	switch (Cat)
	{
		case ZCAT_CLOT: return "Clots";
		case ZCAT_CRAWLER: return "Crawlers";
		case ZCAT_STALKER: return "Stalkers";
		case ZCAT_GOREFAST: return "Gorefasts";
		case ZCAT_BLOAT: return "Bloats";
		case ZCAT_HUSK: return "Husks";
		case ZCAT_SIREN: return "Sirens";
		case ZCAT_SCRAKE: return "Scrakes";
		case ZCAT_FLESHPOUND: return "Fleshpounds";
		case ZCAT_EDAR: return "EDARs";
		default: return "Unknown";
	}
}

// Returns 0=trash, 1=medium, 2=large
function byte GetZedTier(byte Cat)
{
	switch (Cat)
	{
		case ZCAT_CLOT:
		case ZCAT_CRAWLER:
		case ZCAT_STALKER:
			return 0;
		case ZCAT_GOREFAST:
		case ZCAT_BLOAT:
		case ZCAT_HUSK:
		case ZCAT_SIREN:
		case ZCAT_EDAR:
			return 1;
		case ZCAT_SCRAKE:
		case ZCAT_FLESHPOUND:
			return 2;
		default:
			return 1;
	}
}

// ===================================================================
// 20. FOG OF WAR ? Hide zeds beyond visibility range
// ===================================================================

function StartFogOfWar()
{
	SetTimer(0.5f, true, 'UpdateFogOfWarVisibility');
	`log("[DK_EVENTWAVE_MGR] Fog of War started - visibility range:" @ FOW_VISIBILITY_RANGE @ "UU");
}

function UpdateFogOfWarVisibility()
{
	local KFPawn_Monster KFPM;
	local KFPlayerController KFPC;
	local float ClosestDist, Dist;
	local bool bShouldBeVisible;

	foreach WorldInfo.AllPawns(class'KFPawn_Monster', KFPM)
	{
		if (!KFPM.IsAliveAndWell()) continue;

		// Find distance to nearest living player
		ClosestDist = 999999.f;
		foreach WorldInfo.AllControllers(class'KFPlayerController', KFPC)
		{
			if (KFPC.Pawn != None && KFPC.Pawn.IsAliveAndWell())
			{
				Dist = VSize(KFPM.Location - KFPC.Pawn.Location);
				if (Dist < ClosestDist)
					ClosestDist = Dist;
			}
		}

		bShouldBeVisible = (ClosestDist <= FOW_VISIBILITY_RANGE);

		if (bShouldBeVisible && KFPM.bHidden)
		{
			KFPM.SetHidden(False);
		}
		else if (!bShouldBeVisible && !KFPM.bHidden)
		{
			KFPM.SetHidden(True);
		}
	}
}

function EndFogOfWar()
{
	local KFPawn_Monster KFPM;

	ClearTimer('UpdateFogOfWarVisibility');

	// Restore all zed visibility
	foreach WorldInfo.AllPawns(class'KFPawn_Monster', KFPM)
	{
		if (KFPM.bHidden)
			KFPM.SetHidden(False);
	}

	`log("[DK_EVENTWAVE_MGR] Fog of War ended - all zeds visible");
}

// ===================================================================
// 21. NEMESIS ? One massively buffed zed, kill it for bonus dosh
// ===================================================================

function StartNemesis()
{
	// Pick a random category (0-9)
	NemesisCategory = byte(Rand(10));
	bNemesisSpawned = False;
	NemesisPawn = None;

	`log("[DK_EVENTWAVE_MGR] Nemesis: hunting a" @ GetCategoryName(NemesisCategory));
}

function ApplyNemesisBuffs(KFPawn_Monster Zed)
{
	local byte Tier;
	local float BaseHPMult, SpeedMult, ScaleMult, MinHP;
	local float WaveFactor, PlayerFactor, FinalHP;
	local int WaveNum, PlayerCount;

	Tier = GetZedTier(NemesisCategory);

	// --- Base multipliers per tier ---
	switch (Tier)
	{
		case 0: // Trash
			BaseHPMult = 100.f;
			SpeedMult = 2.0f;
			ScaleMult = 2.5f;
			MinHP = 7500.f;
			break;
		case 1: // Medium
			BaseHPMult = 50.f;
			SpeedMult = 1.75f;
			ScaleMult = 2.0f;
			MinHP = 12000.f;
			break;
		default: // Large
			BaseHPMult = 15.f;
			SpeedMult = 1.5f;
			ScaleMult = 1.5f;
			MinHP = 25000.f;
			break;
	}

	// --- Wave scaling: 1.0 + (WaveNum * 0.06) ---
	WaveNum = KFGameInfo_Endless(WorldInfo.Game).WaveNum;
	WaveFactor = 1.0f + (float(WaveNum) * 0.06f);

	// --- Player scaling: 1.0 + (PlayerCount - 1) * 0.4 ---
	PlayerCount = KFGameInfo_Endless(WorldInfo.Game).GetLivingPlayerCount();
	if (PlayerCount < 1)
		PlayerCount = 1;
	PlayerFactor = 1.0f + (float(PlayerCount - 1) * 0.4f);

	// --- Final HP with floor ---
	FinalHP = float(Zed.Health) * BaseHPMult * WaveFactor * PlayerFactor;
	if (FinalHP < MinHP * PlayerFactor)
		FinalHP = MinHP * PlayerFactor;

	Zed.Health = int(FinalHP);
	Zed.HealthMax = Zed.Health;
	Zed.GroundSpeed *= SpeedMult;
	Zed.SprintSpeed *= SpeedMult;
	Zed.NormalGroundSpeed = Zed.GroundSpeed;
	Zed.NormalSprintSpeed = Zed.SprintSpeed;
	// Resize via the body-scale system, not SetDrawScale. SetDrawScale scales the
	// whole actor including the skeletal mesh's seating translation (~ -86 Z), so an
	// upscaled zed's mesh sinks ~half underground. IntendedBodyScale (replicated) +
	// UpdateBodyScale use Mesh.SetScale, which keeps the feet grounded. Collision is
	// untouched either way (visual only).
	Zed.IntendedBodyScale = Zed.IntendedBodyScale * ScaleMult;
	Zed.UpdateBodyScale(Zed.IntendedBodyScale);

	Zed.SetEnraged(True);
	Zed.SetSprinting(True);

	NemesisPawn = Zed;
	bNemesisSpawned = True;

	`log("[DK_EVENTWAVE_MGR] Nemesis spawned:" @ Zed.Class.Name
		@ "| HP:" @ Zed.Health @ "| Tier:" @ Tier
		@ "| Wave:" @ WaveNum @ "(x" @ WaveFactor $ ")"
		@ "| Players:" @ PlayerCount @ "(x" @ PlayerFactor $ ")");
}

// Called from GameInfo.Killed when a zed dies during Nemesis event
function NotifyNemesisKilled(Pawn KilledPawn)
{
	local KFPlayerController KFPC;
	local ZTGameReplicationInfo DKGRI;
	local int BonusDosh;

	if (ActiveEventID != 21) return;
	if (KilledPawn != NemesisPawn) return;

	BonusDosh = 250 + (KFGameInfo_Endless(WorldInfo.Game).WaveNum * 50);

	// Award bonus dosh to all living players
	foreach WorldInfo.AllControllers(class'KFPlayerController', KFPC)
	{
		if (KFPC.Pawn != None && KFPC.Pawn.IsAliveAndWell())
		{
			KFPlayerReplicationInfo(KFPC.PlayerReplicationInfo).Score += BonusDosh;
		}
	}

	`log("[DK_EVENTWAVE_MGR] Nemesis killed! Awarded" @ BonusDosh @ "dosh to all players");

	// End the event early
	StopEventMusicForAll();
	DKGRI = ZTGameReplicationInfo(WorldInfo.GRI);
	if (DKGRI != None)
		DKGRI.ActiveEventWaveID = 0;

	NemesisPawn = None;
}

function EndNemesis()
{
	NemesisPawn = None;
	bNemesisSpawned = False;
	`log("[DK_EVENTWAVE_MGR] Nemesis event ended");
}

// ===================================================================
// 22. DUEL ? Each player assigned zed categories, can only damage theirs
// ===================================================================

function StartDuel()
{
	local KFPlayerController KFPC;
	local int PlayerIdx, CatIdx, i;

	DuelPlayers.Length = 0;

	// Build player list
	foreach WorldInfo.AllControllers(class'KFPlayerController', KFPC)
	{
		if (KFPC.Pawn != None && KFPC.Pawn.IsAliveAndWell())
			DuelPlayers.AddItem(KFPC);
	}

	if (DuelPlayers.Length < 2)
	{
		`log("[DK_EVENTWAVE_MGR] Duel: Not enough players, skipping");
		return;
	}

	// Initialize all categories as unassigned
	for (i = 0; i < 10; ++i)
	{
		CategoryOwner[i] = 255;
	}

	// Round-robin distribute categories across players
	PlayerIdx = 0;
	for (CatIdx = 0; CatIdx < 10; ++CatIdx)
	{
		CategoryOwner[CatIdx] = byte(PlayerIdx);
		PlayerIdx = (PlayerIdx + 1) % DuelPlayers.Length;
	}

	// Notify each player of their assignment
	for (PlayerIdx = 0; PlayerIdx < DuelPlayers.Length; ++PlayerIdx)
	{
		NotifyDuelAssignment(DuelPlayers[PlayerIdx], PlayerIdx);
	}

	`log("[DK_EVENTWAVE_MGR] Duel started with" @ DuelPlayers.Length @ "players");
}

function NotifyDuelAssignment(KFPlayerController KFPC, int PlayerIdx)
{
	local string Msg;
	local int i;

	Msg = "DUEL: Your targets are";
	for (i = 0; i < 10; ++i)
	{
		if (CategoryOwner[i] == PlayerIdx)
			Msg = Msg @ GetCategoryName(byte(i));
	}

	KFPC.ClientMessage(Msg);
}

// Check if a player is allowed to damage a specific zed during Duel
function bool CanDuelDamage(Controller Attacker, Pawn Victim)
{
	local byte Cat;
	local int PlayerIdx;

	if (ActiveEventID != 22) return True;
	if (DuelPlayers.Length == 0) return True;

	// Bosses are free-for-all - never lock a boss to one player's category,
	// or everyone else does chip (1) damage to it for the whole wave.
	if (KFPawn_Monster(Victim) != None && KFPawn_Monster(Victim).IsABoss())
		return True;

	Cat = GetZedCategory(Victim);

	// Unknown zed types are free for all
	if (Cat == ZCAT_UNKNOWN) return True;

	// Owner died with no living player to inherit the category (255) -> free
	// for all, otherwise those zeds would be unkillable for the rest of the wave.
	if (CategoryOwner[Cat] == 255) return True;

	// Find the attacker in the player list
	for (PlayerIdx = 0; PlayerIdx < DuelPlayers.Length; ++PlayerIdx)
	{
		if (DuelPlayers[PlayerIdx] == Attacker)
		{
			return (CategoryOwner[Cat] == PlayerIdx);
		}
	}

	// Player not in list (joined mid-event?) ? allow damage
	return True;
}

function EndDuel()
{
	DuelPlayers.Length = 0;
	`log("[DK_EVENTWAVE_MGR] Duel ended");
}

// When a Duel player dies, hand their zed categories to a still-living duel
// player so those zeds stay killable. If nobody is left alive to inherit, the
// category is marked ownerless (255) and CanDuelDamage treats it as free-for-all.
function ReassignDuelCategories(KFPlayerController DeadPC)
{
	local int DeadIdx, Cat, j, n;
	local array<int> AliveIdx;

	DeadIdx = INDEX_NONE;
	for (j = 0; j < DuelPlayers.Length; ++j)
	{
		if (DuelPlayers[j] == DeadPC)
		{
			DeadIdx = j;
			break;
		}
	}
	if (DeadIdx == INDEX_NONE)
		return;

	// Collect indices of duel players still alive (excluding the one who died).
	for (j = 0; j < DuelPlayers.Length; ++j)
	{
		if (DuelPlayers[j] != None && DuelPlayers[j] != DeadPC
			&& DuelPlayers[j].Pawn != None && DuelPlayers[j].Pawn.IsAliveAndWell())
			AliveIdx.AddItem(j);
	}

	n = 0;
	for (Cat = 0; Cat < 10; ++Cat)
	{
		if (CategoryOwner[Cat] == DeadIdx)
		{
			if (AliveIdx.Length == 0)
				CategoryOwner[Cat] = 255; // nobody left -> free for all
			else
			{
				CategoryOwner[Cat] = byte(AliveIdx[n % AliveIdx.Length]);
				++n;
			}
		}
	}

	// Re-notify survivors of their (possibly expanded) assignments.
	for (j = 0; j < DuelPlayers.Length; ++j)
	{
		if (DuelPlayers[j] != None && DuelPlayers[j] != DeadPC
			&& DuelPlayers[j].Pawn != None && DuelPlayers[j].Pawn.IsAliveAndWell())
			NotifyDuelAssignment(DuelPlayers[j], j);
	}

	`log("[DK_EVENTWAVE_MGR] Duel: reassigned dead idx" @ DeadIdx @ "to" @ AliveIdx.Length @ "survivors");
}

// ===================================================================
// 23. TO ME, MY X-MEN ? Random superpowers for each player
// ===================================================================

function StartXMen()
{
	local KFPlayerController KFPC;
	local array<KFPlayerController> Players;
	local array<byte> PowerPool;
	local XMenPlayerState NewState;
	local KFPawn_Human KFPH;
	local int i, RandIdx;
	local byte TempPower;

	// Build player list
	foreach WorldInfo.AllControllers(class'KFPlayerController', KFPC)
	{
		if (KFPC.Pawn != None && KFPC.Pawn.IsAliveAndWell())
		{
			Players.AddItem(KFPC);
		}
	}

	if (Players.Length == 0)
	{
		return;
	}

	// Build shuffled power pool
	for (i = 0; i < NUM_XMEN_POWERS; i++)
	{
		PowerPool.AddItem(byte(i));
	}

	// Fisher-Yates shuffle
	for (i = PowerPool.Length - 1; i > 0; i--)
	{
		RandIdx = Rand(i + 1);
		TempPower = PowerPool[i];
		PowerPool[i] = PowerPool[RandIdx];
		PowerPool[RandIdx] = TempPower;
	}

	// Assign powers
	XMenPlayers.Length = 0;
	for (i = 0; i < Players.Length; i++)
	{
		NewState.PC = Players[i];
		NewState.PowerID = PowerPool[i % NUM_XMEN_POWERS];
		NewState.KillCount = 0;
		NewState.StoredGroundSpeed = 0;
		NewState.StoredSprintSpeed = 0;
		NewState.StoredHealth = 0;
		NewState.StoredHealthMax = 0;
		NewState.StoredArmor = 0;
		NewState.StoredArmorMax = 0;

		KFPH = KFPawn_Human(Players[i].Pawn);

		// Apply pawn-modifying powers (store originals for safe restore)
		if (NewState.PowerID == POWER_QUICKSILVER && KFPH != None)
		{
			NewState.StoredGroundSpeed = KFPH.GroundSpeed;
			NewState.StoredSprintSpeed = KFPH.SprintSpeed;
		}
		else if (NewState.PowerID == POWER_JUGGERNAUT && KFPH != None)
		{
			NewState.StoredHealth = KFPH.Health;
			NewState.StoredHealthMax = KFPH.HealthMax;
			NewState.StoredArmor = KFPH.Armor;
			NewState.StoredArmorMax = KFPH.MaxArmor;
			KFPH.HealthMax *= 2;
			KFPH.Health *= 2;
			KFPH.MaxArmor *= 2;
			KFPH.Armor *= 2;
		}

		XMenPlayers.AddItem(NewState);

		// Send power info to client for HUD display
		if (ZTPlayerController(Players[i]) != None)
		{
			ZTPlayerController(Players[i]).ClientReceiveXMenPower(
				GetPowerName(NewState.PowerID),
				GetPowerDescription(NewState.PowerID)
			);
		}

		`log("[DK_XMEN] Assigned" @ GetPowerName(NewState.PowerID) @ "to" @ Players[i].PlayerReplicationInfo.PlayerName);
	}

	// Start repeating timer to enforce Quicksilver speed
	// (weapon switches and other state changes recalculate GroundSpeed from defaults)
	SetTimer(0.25, true, 'EnforceXMenPawnMods');
}

function EndXMen()
{
	local int i;
	local KFPawn_Human KFPH;

	for (i = 0; i < XMenPlayers.Length; i++)
	{
		if (XMenPlayers[i].PC == None || XMenPlayers[i].PC.Pawn == None)
		{
			continue;
		}

		KFPH = KFPawn_Human(XMenPlayers[i].PC.Pawn);
		if (KFPH == None || !KFPH.IsAliveAndWell())
		{
			continue;
		}

		// Restore pawn-modifying powers to stored values
		if (XMenPlayers[i].PowerID == POWER_QUICKSILVER && XMenPlayers[i].StoredGroundSpeed > 0)
		{
			KFPH.GroundSpeed = XMenPlayers[i].StoredGroundSpeed;
			KFPH.SprintSpeed = XMenPlayers[i].StoredSprintSpeed;
		}
		else if (XMenPlayers[i].PowerID == POWER_JUGGERNAUT && XMenPlayers[i].StoredHealthMax > 0)
		{
			KFPH.HealthMax = XMenPlayers[i].StoredHealthMax;
			if (KFPH.Health > KFPH.HealthMax)
			{
				KFPH.Health = KFPH.HealthMax;
			}
			KFPH.MaxArmor = XMenPlayers[i].StoredArmorMax;
			if (KFPH.Armor > KFPH.MaxArmor)
			{
				KFPH.Armor = KFPH.MaxArmor;
			}
		}

		// Clear HUD display
		if (ZTPlayerController(XMenPlayers[i].PC) != None)
		{
			ZTPlayerController(XMenPlayers[i].PC).ClientReceiveXMenPower("", "");
		}
	}

	XMenPlayers.Length = 0;
	ClearTimer('EnforceXMenPawnMods');
	`log("[DK_EVENTWAVE_MGR] X-Men ended - all powers removed");
}

/** Repeating timer: enforces Quicksilver speed boost.
 *  KF2 recalculates GroundSpeed on weapon switch/state changes,
 *  so we must continuously re-apply the 2x multiplier. */
function EnforceXMenPawnMods()
{
	local int i;
	local KFPawn_Human KFPH;

	for (i = 0; i < XMenPlayers.Length; i++)
	{
		if (XMenPlayers[i].PowerID != POWER_QUICKSILVER)
		{
			continue;
		}

		if (XMenPlayers[i].PC == None || XMenPlayers[i].PC.Pawn == None)
		{
			continue;
		}

		KFPH = KFPawn_Human(XMenPlayers[i].PC.Pawn);
		if (KFPH == None || !KFPH.IsAliveAndWell())
		{
			continue;
		}

		// Re-apply 2x speed from stored base values
		KFPH.GroundSpeed = XMenPlayers[i].StoredGroundSpeed * 2.0;
		KFPH.SprintSpeed = XMenPlayers[i].StoredSprintSpeed * 2.0;
	}
}

function byte GetPlayerPower(Controller C)
{
	local int i;

	for (i = 0; i < XMenPlayers.Length; i++)
	{
		if (XMenPlayers[i].PC == C)
		{
			return XMenPlayers[i].PowerID;
		}
	}

	return 255;
}

function int GetPlayerXMenIndex(Controller C)
{
	local int i;

	for (i = 0; i < XMenPlayers.Length; i++)
	{
		if (XMenPlayers[i].PC == C)
		{
			return i;
		}
	}

	return INDEX_NONE;
}

function string GetPowerName(byte PowerID)
{
	switch (PowerID)
	{
		case POWER_WOLVERINE:  return "Wolverine";
		case POWER_COLOSSUS:   return "Colossus";
		case POWER_CYCLOPS:    return "Cyclops";
		case POWER_HULK:       return "Hulk";
		case POWER_STORM:      return "Storm";
		case POWER_DOMINO:     return "Domino";
		case POWER_SUNSPOT:    return "Sunspot";
		case POWER_ROGUE:      return "Rogue";
		case POWER_QUICKSILVER: return "Quicksilver";
		case POWER_JUGGERNAUT: return "Juggernaut";
		default: return "Unknown";
	}
}

function string GetPowerDescription(byte PowerID)
{
	switch (PowerID)
	{
		case POWER_WOLVERINE:  return "Regeneration: Kills restore 25 HP";
		case POWER_COLOSSUS:   return "Organic Steel: Take 75% less damage";
		case POWER_CYCLOPS:    return "Optic Blast: Deal 3x damage";
		case POWER_HULK:       return "Hulk Smash: Melee deals 5x, guns deal nothing";
		case POWER_STORM:      return "Lightning Strike: Kills zap nearby zeds for 200 damage";
		case POWER_DOMINO:     return "Probability Field: 15% chance to instakill, +10 bonus dosh per kill";
		case POWER_SUNSPOT:    return "Solar Flare: All weapons deal 3x burn damage";
		case POWER_ROGUE:      return "Power Absorption: Each kill increases damage by 3%";
		case POWER_QUICKSILVER: return "Superspeed: Move twice as fast";
		case POWER_JUGGERNAUT: return "Unstoppable: Double health and armor";
		default: return "";
	}
}

// Called from ModifyEventDamage for case 23
function int ModifyXMenDamage(int Damage, Pawn Injured, Controller InstigatedBy)
{
	local byte AttackerPower, DefenderPower;
	local int Idx;
	local KFWeapon KFW;
	local KFPawn_Human KFPH;

	// Attacker power modifications (player damaging zed)
	if (KFPawn_Monster(Injured) != None && InstigatedBy != None)
	{
		AttackerPower = GetPlayerPower(InstigatedBy);

		switch (AttackerPower)
		{
			case POWER_CYCLOPS:
				return Damage * 3;

			case POWER_SUNSPOT:
				return Damage * 3;

			case POWER_HULK:
				KFPH = KFPawn_Human(InstigatedBy.Pawn);
				if (KFPH != None)
				{
					KFW = KFWeapon(KFPH.Weapon);
					if (KFW != None && KFW.bMeleeWeapon)
					{
						return Damage * 5;
					}
				}
				return 0;

			case POWER_DOMINO:
				if (FRand() < 0.15)
				{
					return 99999;
				}
				break;

			case POWER_ROGUE:
				Idx = GetPlayerXMenIndex(InstigatedBy);
				if (Idx != INDEX_NONE)
				{
					return Round(float(Damage) * (1.0 + float(XMenPlayers[Idx].KillCount) * 0.03));
				}
				break;
		}
	}

	// Defender power modifications (zed damaging player)
	if (KFPawn_Human(Injured) != None)
	{
		DefenderPower = GetPlayerPower(Injured.Controller);

		if (DefenderPower == POWER_COLOSSUS)
		{
			return Round(float(Damage) * 0.25);
		}
	}

	return Damage;
}

// Called from GameInfo.Killed for case 23
function NotifyXMenKill(Controller Killer, Pawn KilledPawn)
{
	local byte KillerPower;
	local int Idx;
	local KFPawn_Human KFPH;
	local KFPawn_Monster KFPM;
	local KFPawn_Monster NearbyZed;
	local float Dist;

	if (Killer == None || KilledPawn == None)
	{
		return;
	}

	Idx = GetPlayerXMenIndex(Killer);
	if (Idx == INDEX_NONE)
	{
		return;
	}

	KillerPower = XMenPlayers[Idx].PowerID;
	KFPH = KFPawn_Human(Killer.Pawn);
	KFPM = KFPawn_Monster(KilledPawn);

	if (KFPM == None)
	{
		return;
	}

	switch (KillerPower)
	{
		case POWER_WOLVERINE:
			if (KFPH != None && KFPH.IsAliveAndWell())
			{
				KFPH.Health = Min(KFPH.Health + 25, KFPH.HealthMax);
			}
			break;

		case POWER_STORM:
			foreach WorldInfo.AllPawns(class'KFPawn_Monster', NearbyZed)
			{
				if (NearbyZed != KFPM && NearbyZed.IsAliveAndWell())
				{
					Dist = VSize(NearbyZed.Location - KFPM.Location);
					if (Dist <= STORM_AOE_RADIUS)
					{
						NearbyZed.TakeDamage(STORM_AOE_DAMAGE, Killer, NearbyZed.Location, vect(0,0,0), class'DmgType_Fell');
					}
				}
			}
			break;

		case POWER_DOMINO:
			if (KFPlayerReplicationInfo(Killer.PlayerReplicationInfo) != None)
			{
				KFPlayerReplicationInfo(Killer.PlayerReplicationInfo).AddDosh(10);
			}
			break;

		case POWER_ROGUE:
			XMenPlayers[Idx].KillCount++;
			break;
	}
}

// ===================================================================
// MINIGAME EVENT HELPERS (batch 27-32)
// ===================================================================

function ZTGameReplicationInfo GetDKGRI()
{
	return ZTGameReplicationInfo(WorldInfo.GRI);
}

function SetGRIPhase(byte Phase)
{
	local ZTGameReplicationInfo ZTGRI;

	ZTGRI = GetDKGRI();
	if (ZTGRI != None)
	{
		ZTGRI.EventPhase = Phase;
		ZTGRI.bForceNetUpdate = True;
	}
}

function SetGRIZoneLoc(vector Loc)
{
	local ZTGameReplicationInfo ZTGRI;

	ZTGRI = GetDKGRI();
	if (ZTGRI != None)
	{
		ZTGRI.EventZoneLoc = Loc;
		ZTGRI.bForceNetUpdate = True;
	}
}

function ClearGRIMinigameExtras()
{
	local ZTGameReplicationInfo ZTGRI;

	ZTGRI = GetDKGRI();
	if (ZTGRI != None)
	{
		ZTGRI.EventZoneLoc = vect(0,0,0);
		ZTGRI.EventPhase = 0;
		ZTGRI.EventDataA = 0;
		ZTGRI.EventDataB = 0;
		ZTGRI.bForceNetUpdate = True;
	}
}

function ClearAllClientMinigameData()
{
	local ZTPlayerController ZTPC;

	foreach WorldInfo.AllControllers(class'ZTPlayerController', ZTPC)
	{
		ZTPC.ClientClearEventMinigameData();
	}
}

// Plays a ZTSoundManager-registered one-shot cue to every player
function PlayCueToAll(name CueID)
{
	local ZTMutator Mut;
	local SoundCue Cue;
	local ZTPlayerController ZTPC;

	Mut = class'ZTSoundManager'.static.GetMutator(WorldInfo);
	if (Mut == None)
		return;

	Cue = class'ZTSoundManager'.static.GetSound(Mut, CueID);
	if (Cue == None)
		return;

	foreach WorldInfo.AllControllers(class'ZTPlayerController', ZTPC)
	{
		ZTPC.ClientPlayBuffSound(Cue);
	}
}

function PlayCueToPC(name CueID, KFPlayerController KFPC)
{
	local ZTMutator Mut;
	local SoundCue Cue;
	local ZTPlayerController ZTPC;

	ZTPC = ZTPlayerController(KFPC);
	if (ZTPC == None)
		return;

	Mut = class'ZTSoundManager'.static.GetMutator(WorldInfo);
	if (Mut == None)
		return;

	Cue = class'ZTSoundManager'.static.GetSound(Mut, CueID);
	if (Cue != None)
		ZTPC.ClientPlayBuffSound(Cue);
}

// Shared kill hook for the minigame events. Called from BOTH GameInfos'
// Killed() next to the existing OITC/Nemesis/XMen notifies.
function NotifyZedKilledGeneric(Controller Killer, Pawn KilledPawn)
{
	local ZTGameReplicationInfo ZTGRI;
	local KFPlayerController KFPC;
	local int Idx;

	KFPC = KFPlayerController(Killer);

	switch (ActiveEventID)
	{
		case 29: // Floor Is Lava: kills scored from inside the zone pay bonus dosh
			ZTGRI = GetDKGRI();
			if (ZTGRI != None && KFPC != None && KFPC.Pawn != None
				&& VSize2D(KFPC.Pawn.Location - ZTGRI.EventZoneLoc) <= LAVA_RADIUS
				&& KFPlayerReplicationInfo(KFPC.PlayerReplicationInfo) != None)
			{
				KFPlayerReplicationInfo(KFPC.PlayerReplicationInfo).AddDosh(LAVA_KILL_DOSH);
			}
			break;

		case 31: // Bounty Board: count kills of the killer's assigned category
			if (KFPC == None)
				break;
			Idx = BountyPCs.Find(KFPC);
			if (Idx == INDEX_NONE || BountyHave[Idx] >= BountyNeed[Idx])
				break;
			if (GetZedCategory(KilledPawn) != BountyCat[Idx])
				break;
			++BountyHave[Idx];
			if (ZTPlayerController(KFPC) != None)
				ZTPlayerController(KFPC).ClientUpdateEventQuota(BountyHave[Idx]);
			if (BountyHave[Idx] >= BountyNeed[Idx])
			{
				PlayCueToPC('EventBounty_Complete', KFPC);
				class'ZTMessageManager'.static.SendImportant(KFPC, "BOUNTY COMPLETE!");
				UpdateBountyTeamProgress();
			}
			break;

		case 32: // Golden Zed Relay: golden died -> trophy drops, killer excluded
			if (KilledPawn != None && KilledPawn == GoldenZed)
			{
				if (Killer != None)
					GoldenKillerPRI = Killer.PlayerReplicationInfo;
				else
					GoldenKillerPRI = None;
				GoldenDropLoc = KilledPawn.Location;
				GoldenDropExpire = WorldInfo.TimeSeconds + GOLDEN_DROP_WINDOW;
				GoldenZed = None;
				SetGRIZoneLoc(GoldenDropLoc);
				SetGRIPhase(2);
				BroadcastMinigameMessage("GOLDEN ZED DOWN! A teammate (not the killer) must grab the trophy!");
			}
			break;
	}
}

function BroadcastMinigameMessage(string Msg)
{
	local KFPlayerController KFPC;

	foreach WorldInfo.AllControllers(class'KFPlayerController', KFPC)
	{
		class'ZTMessageManager'.static.SendImportant(KFPC, Msg);
	}
}

// ===================================================================
// 27. PASS THE BOMB
// A live bomb on one player. Touch a teammate to hand it off; the fuse
// shortens with every pass. Detonation hurts the holder badly and
// splashes nearby players, then a fresh bomb re-arms on a random player.
// ===================================================================

function StartPassTheBomb()
{
	BombPassCount = 0;
	BombPrevHolder = None;
	ArmBombOn(PickRandomPlayer(), BOMB_FUSE_BASE);
	SetTimer(0.25f, true, 'BombTick');
}

function ArmBombOn(KFPlayerController NewHolder, float Fuse)
{
	if (NewHolder == None)
		return;

	TargetPC = NewHolder;
	TargetPRI = NewHolder.PlayerReplicationInfo;
	SwapInterval = Fuse;
	BombFuseEnd = WorldInfo.TimeSeconds + Fuse;
	BombLockUntil = WorldInfo.TimeSeconds + BOMB_TRANSFER_LOCK;
	UpdateGRITarget(TargetPRI);

	class'ZTMessageManager'.static.SendCritical(TargetPC, "YOU HAVE THE BOMB! Touch a teammate to pass it!");
}

function BombTick()
{
	local KFPlayerController KFPC;
	local KFPawn_Human HolderPawn, OtherPawn;

	if (ActiveEventID != 27)
		return;

	// Holder died or left: bomb fizzles onto a new random player
	if (TargetPC == None || TargetPC.Pawn == None || !TargetPC.Pawn.IsAliveAndWell())
	{
		BombPassCount = 0;
		BombPrevHolder = None;
		ArmBombOn(PickRandomPlayer(), BOMB_FUSE_BASE);
		return;
	}

	// Fuse expired: detonate
	if (WorldInfo.TimeSeconds >= BombFuseEnd)
	{
		ExplodeBomb();
		return;
	}

	// Transfer scan (locked briefly after each pass so it cannot ping-pong)
	if (WorldInfo.TimeSeconds < BombLockUntil)
		return;

	HolderPawn = KFPawn_Human(TargetPC.Pawn);
	if (HolderPawn == None)
		return;

	foreach WorldInfo.AllControllers(class'KFPlayerController', KFPC)
	{
		if (KFPC == TargetPC || KFPC == BombPrevHolder)
			continue;

		OtherPawn = KFPawn_Human(KFPC.Pawn);
		if (OtherPawn == None || !OtherPawn.IsAliveAndWell())
			continue;

		if (VSize(OtherPawn.Location - HolderPawn.Location) <= BOMB_TRANSFER_RADIUS)
		{
			TransferBomb(KFPC);
			return;
		}
	}
}

function TransferBomb(KFPlayerController NewHolder)
{
	local float NewFuse;

	++BombPassCount;
	NewFuse = FMax(BOMB_FUSE_MIN, BOMB_FUSE_BASE - BOMB_FUSE_DECAY * float(BombPassCount));

	class'ZTMessageManager'.static.SendMinor(TargetPC, "Bomb passed to" @ NewHolder.PlayerReplicationInfo.PlayerName $ "!");
	BombPrevHolder = TargetPC;
	ArmBombOn(NewHolder, NewFuse);
	PlayCueToAll('EventBomb_Transfer');
}

function ExplodeBomb()
{
	local KFPawn_Human HolderPawn, OtherPawn;
	local KFPlayerController KFPC;
	local string HolderName;

	HolderPawn = KFPawn_Human(TargetPC.Pawn);
	HolderName = TargetPC.PlayerReplicationInfo.PlayerName;

	if (HolderPawn != None && HolderPawn.IsAliveAndWell())
	{
		// 60% of max HP: brutal, never lethal from full health
		HolderPawn.TakeDamage(Max(1, Round(float(HolderPawn.HealthMax) * 0.6f)), None, HolderPawn.Location, vect(0,0,0), class'DmgType_Fell');

		// Splash: 30% to anyone standing too close
		foreach WorldInfo.AllControllers(class'KFPlayerController', KFPC)
		{
			if (KFPC == TargetPC)
				continue;
			OtherPawn = KFPawn_Human(KFPC.Pawn);
			if (OtherPawn != None && OtherPawn.IsAliveAndWell()
				&& VSize(OtherPawn.Location - HolderPawn.Location) <= BOMB_BLAST_RADIUS)
			{
				OtherPawn.TakeDamage(Max(1, Round(float(OtherPawn.HealthMax) * 0.3f)), None, OtherPawn.Location, vect(0,0,0), class'DmgType_Fell');
			}
		}
	}

	PlayCueToAll('EventBomb_Explode');
	BroadcastMinigameMessage("THE BOMB EXPLODED ON " $ HolderName $ "!");

	// Fresh cycle on a new random holder
	BombPassCount = 0;
	BombPrevHolder = None;
	ArmBombOn(PickRandomPlayer(), BOMB_FUSE_BASE);
}

// ===================================================================
// 28. RED LIGHT, GREEN LIGHT
// Green: play normally. A warning chirp, then RED for 4s: any player
// who MOVES takes %HP ticks. Shooting while standing still is legal.
// ===================================================================

function StartRedLightGreenLight()
{
	SetGRIPhase(0);
	SetTimer(RLGL_GREEN_MIN + FRand() * (RLGL_GREEN_MAX - RLGL_GREEN_MIN), false, 'RLGLWarn');
}

function RLGLWarn()
{
	if (ActiveEventID != 28)
		return;
	SetGRIPhase(1);
	PlayCueToAll('EventRLGL_Warning');
	SetTimer(RLGL_WARN_TIME, false, 'RLGLRed');
}

function RLGLRed()
{
	if (ActiveEventID != 28)
		return;
	SetGRIPhase(2);
	PlayCueToAll('EventRLGL_Red');
	SetTimer(0.25f, true, 'RLGLRedTick');
	SetTimer(RLGL_RED_TIME, false, 'RLGLGreen');
}

function RLGLRedTick()
{
	local KFPlayerController KFPC;
	local KFPawn_Human KFPH;

	if (ActiveEventID != 28)
		return;

	foreach WorldInfo.AllControllers(class'KFPlayerController', KFPC)
	{
		KFPH = KFPawn_Human(KFPC.Pawn);
		if (KFPH != None && KFPH.IsAliveAndWell() && VSize(KFPH.Velocity) > RLGL_MOVE_THRESHOLD)
		{
			KFPH.TakeDamage(Max(1, Round(float(KFPH.HealthMax) * RLGL_TICK_DMG_PCT)), None, KFPH.Location, vect(0,0,0), class'DmgType_Fell');
		}
	}
}

function RLGLGreen()
{
	if (ActiveEventID != 28)
		return;
	ClearTimer('RLGLRedTick');
	SetGRIPhase(0);
	PlayCueToAll('EventRLGL_Green');
	SetTimer(RLGL_GREEN_MIN + FRand() * (RLGL_GREEN_MAX - RLGL_GREEN_MIN), false, 'RLGLWarn');
}

// ===================================================================
// 29. THE FLOOR IS LAVA
// One safe zone anchored at a PlayerStart / trader node. Outside it
// players cook; kills scored inside pay bonus dosh. The zone telegraphs
// then relocates on a fixed cycle - migrate together or burn.
// ===================================================================

function StartFloorIsLava()
{
	BuildLavaAnchors();
	SetGRIZoneLoc(PickLavaAnchor(vect(0,0,0), true));
	SetGRIPhase(0);
	SetGRISwapSeconds(byte(LAVA_RELOCATE));
	SetTimer(LAVA_RELOCATE - LAVA_TELEGRAPH, false, 'LavaTelegraph');
	SetTimer(0.5f, true, 'LavaTick');
}

function SetGRISwapSeconds(byte Seconds)
{
	local ZTGameReplicationInfo ZTGRI;

	ZTGRI = GetDKGRI();
	if (ZTGRI != None)
	{
		ZTGRI.EventSwapInterval = Seconds;
		ZTGRI.bForceNetUpdate = True;
	}
}

function BuildLavaAnchors()
{
	local PlayerStart PS;
	local KFTraderTrigger TT;

	LavaAnchors.Length = 0;

	foreach AllActors(class'PlayerStart', PS)
		LavaAnchors.AddItem(PS.Location);

	foreach AllActors(class'KFTraderTrigger', TT)
		LavaAnchors.AddItem(TT.Location);

	`log("[ZT_EVENTWAVE_MGR] Lava anchors:" @ LavaAnchors.Length);
}

// Picks an anchor. bNearPlayers: closest to the living players' centroid
// (used for the opening zone so it never spawns across the map).
// Otherwise: random anchor that differs from Current, preferring ones
// within reachable range.
function vector PickLavaAnchor(vector Current, bool bNearPlayers)
{
	local KFPlayerController KFPC;
	local vector Centroid, Best;
	local int Count, i, Tries;
	local float Dist, BestDist;

	if (LavaAnchors.Length == 0)
	{
		// Degenerate map: anchor on the players themselves
		foreach WorldInfo.AllControllers(class'KFPlayerController', KFPC)
		{
			if (KFPC.Pawn != None && KFPC.Pawn.IsAliveAndWell())
			{
				Centroid += KFPC.Pawn.Location;
				++Count;
			}
		}
		if (Count > 0)
			Centroid /= float(Count);
		return Centroid;
	}

	if (bNearPlayers)
	{
		foreach WorldInfo.AllControllers(class'KFPlayerController', KFPC)
		{
			if (KFPC.Pawn != None && KFPC.Pawn.IsAliveAndWell())
			{
				Centroid += KFPC.Pawn.Location;
				++Count;
			}
		}
		if (Count > 0)
			Centroid /= float(Count);

		BestDist = 999999.f;
		Best = LavaAnchors[0];
		for (i = 0; i < LavaAnchors.Length; ++i)
		{
			Dist = VSize(LavaAnchors[i] - Centroid);
			if (Dist < BestDist)
			{
				BestDist = Dist;
				Best = LavaAnchors[i];
			}
		}
		return Best;
	}

	// Random pick, prefer a different anchor within 5000 UU of the current zone
	for (Tries = 0; Tries < 12; ++Tries)
	{
		Best = LavaAnchors[Rand(LavaAnchors.Length)];
		if (VSize(Best - Current) > 200.f && VSize(Best - Current) < 5000.f)
			return Best;
	}

	// Fallback: any different anchor
	for (Tries = 0; Tries < 12; ++Tries)
	{
		Best = LavaAnchors[Rand(LavaAnchors.Length)];
		if (VSize(Best - Current) > 200.f)
			return Best;
	}

	return LavaAnchors[Rand(LavaAnchors.Length)];
}

function LavaTelegraph()
{
	local ZTGameReplicationInfo ZTGRI;

	if (ActiveEventID != 29)
		return;

	ZTGRI = GetDKGRI();
	if (ZTGRI == None)
		return;

	NextLavaLoc = PickLavaAnchor(ZTGRI.EventZoneLoc, false);
	SetGRIPhase(1);
	PlayCueToAll('EventLava_Move');
	BroadcastMinigameMessage("THE ZONE IS MOVING!");
	SetTimer(LAVA_TELEGRAPH, false, 'LavaRelocate');
}

function LavaRelocate()
{
	if (ActiveEventID != 29)
		return;

	SetGRIZoneLoc(NextLavaLoc);
	SetGRIPhase(0);
	SetTimer(LAVA_RELOCATE - LAVA_TELEGRAPH, false, 'LavaTelegraph');
}

function LavaTick()
{
	local ZTGameReplicationInfo ZTGRI;
	local KFPlayerController KFPC;
	local KFPawn_Human KFPH;

	if (ActiveEventID != 29)
		return;

	ZTGRI = GetDKGRI();
	if (ZTGRI == None)
		return;

	foreach WorldInfo.AllControllers(class'KFPlayerController', KFPC)
	{
		KFPH = KFPawn_Human(KFPC.Pawn);
		if (KFPH != None && KFPH.IsAliveAndWell()
			&& VSize2D(KFPH.Location - ZTGRI.EventZoneLoc) > LAVA_RADIUS)
		{
			KFPH.TakeDamage(Max(1, Round(float(KFPH.HealthMax) * LAVA_TICK_DMG_PCT)), None, KFPH.Location, vect(0,0,0), class'DmgType_Fell');
		}
	}
}

// ===================================================================
// 30. BODYGUARD BOND
// Players are paired at wave start. Together (<= 12 m): both take 25%
// less damage. Apart: half of any damage you take is mirrored onto
// your distant partner. Stay with your buddy.
// ===================================================================

function StartBodyguardBond()
{
	local KFPlayerController KFPC;
	local ZTPlayerController ZTPC;
	local int i, j, Tmp;
	local array<int> Order;

	BondPCs.Length = 0;
	BondPartner.Length = 0;

	foreach WorldInfo.AllControllers(class'KFPlayerController', KFPC)
	{
		if (KFPC.Pawn != None && KFPC.Pawn.IsAliveAndWell())
			BondPCs.AddItem(KFPC);
	}

	if (BondPCs.Length < 2)
		return;

	// Fisher-Yates shuffle of indices, then pair sequential entries
	Order.Length = BondPCs.Length;
	for (i = 0; i < Order.Length; ++i)
		Order[i] = i;
	for (i = Order.Length - 1; i > 0; --i)
	{
		j = Rand(i + 1);
		Tmp = Order[i];
		Order[i] = Order[j];
		Order[j] = Tmp;
	}

	BondPartner.Length = BondPCs.Length;
	for (i = 0; i + 1 < Order.Length; i += 2)
	{
		BondPartner[Order[i]] = Order[i + 1];
		BondPartner[Order[i + 1]] = Order[i];
	}
	// Odd player out bonds onto the first pair's first member (one-way triple)
	if (Order.Length % 2 == 1)
		BondPartner[Order[Order.Length - 1]] = Order[0];

	for (i = 0; i < BondPCs.Length; ++i)
	{
		ZTPC = ZTPlayerController(BondPCs[i]);
		if (ZTPC != None && BondPCs[BondPartner[i]] != None)
		{
			ZTPC.ClientSetEventPartner(BondPCs[BondPartner[i]].PlayerReplicationInfo.PlayerName);
			class'ZTMessageManager'.static.SendImportant(ZTPC, "BONDED with" @ BondPCs[BondPartner[i]].PlayerReplicationInfo.PlayerName $ "! Stay close!");
		}
	}
}

// Damage shaping for Bodyguard Bond. Called from ModifyEventDamage.
function int ApplyBondDamage(int Damage, Pawn Injured)
{
	local int Idx;
	local KFPawn_Human PartnerPawn;
	local KFPlayerController InjuredPC;

	if (bBondMirroring)
		return Damage;

	if (KFPawn_Human(Injured) == None || Injured.Controller == None)
		return Damage;

	InjuredPC = KFPlayerController(Injured.Controller);
	if (InjuredPC == None)
		return Damage;

	Idx = BondPCs.Find(InjuredPC);
	if (Idx == INDEX_NONE || BondPCs[BondPartner[Idx]] == None)
		return Damage;

	PartnerPawn = KFPawn_Human(BondPCs[BondPartner[Idx]].Pawn);
	if (PartnerPawn == None || !PartnerPawn.IsAliveAndWell())
		return Damage;

	if (VSize(Injured.Location - PartnerPawn.Location) <= BOND_NEAR_RADIUS)
	{
		// Together: both protected
		return Max(1, Round(float(Damage) * BOND_NEAR_RESIST));
	}

	// Apart: distant partner feels your pain
	if (Damage > 1)
	{
		bBondMirroring = True;
		PartnerPawn.TakeDamage(Max(1, Round(float(Damage) * BOND_MIRROR_FRACTION)), None, PartnerPawn.Location, vect(0,0,0), class'DmgType_Fell');
		bBondMirroring = False;
	}

	return Damage;
}

// ===================================================================
// 31. BOUNTY BOARD
// Every player gets a personal zed-category quota. If EVERY quota
// completes before the wave ends, the whole team gets a dosh payout.
// One straggler voids it - call out your targets.
// ===================================================================

function StartBountyBoard()
{
	local KFPlayerController KFPC;
	local ZTPlayerController ZTPC;
	local ZTGameReplicationInfo ZTGRI;
	local byte Cat;
	local int Need;

	BountyPCs.Length = 0;
	BountyCat.Length = 0;
	BountyNeed.Length = 0;
	BountyHave.Length = 0;

	foreach WorldInfo.AllControllers(class'KFPlayerController', KFPC)
	{
		if (KFPC.Pawn == None || !KFPC.Pawn.IsAliveAndWell())
			continue;

		Cat = byte(Rand(7)); // ZCAT_CLOT .. ZCAT_SIREN
		Need = GetBountyQuota(Cat);

		BountyPCs.AddItem(KFPC);
		BountyCat.AddItem(Cat);
		BountyNeed.AddItem(Need);
		BountyHave.AddItem(0);

		ZTPC = ZTPlayerController(KFPC);
		if (ZTPC != None)
			ZTPC.ClientSetEventQuota(GetCategoryName(Cat), Need);

		class'ZTMessageManager'.static.SendImportant(KFPC, "YOUR BOUNTY:" @ Need @ GetCategoryName(Cat) $ "!");
	}

	ZTGRI = GetDKGRI();
	if (ZTGRI != None)
	{
		ZTGRI.EventDataA = 0;
		ZTGRI.EventDataB = byte(BountyPCs.Length);
		ZTGRI.bForceNetUpdate = True;
	}
}

function int GetBountyQuota(byte Cat)
{
	switch (Cat)
	{
		case ZCAT_CLOT: return 12;
		case ZCAT_CRAWLER: return 10;
		case ZCAT_STALKER: return 8;
		case ZCAT_GOREFAST: return 8;
		case ZCAT_BLOAT: return 5;
		case ZCAT_HUSK: return 5;
		case ZCAT_SIREN: return 4;
		default: return 8;
	}
}

function UpdateBountyTeamProgress()
{
	local ZTGameReplicationInfo ZTGRI;
	local int i, Done;

	for (i = 0; i < BountyPCs.Length; ++i)
	{
		if (BountyHave[i] >= BountyNeed[i])
			++Done;
	}

	ZTGRI = GetDKGRI();
	if (ZTGRI != None)
	{
		ZTGRI.EventDataA = byte(Done);
		ZTGRI.bForceNetUpdate = True;
	}

	if (Done == BountyPCs.Length && BountyPCs.Length > 0)
		BroadcastMinigameMessage("ALL BOUNTIES COMPLETE! Payout at wave end!");
}

// Payout check. EndEvent runs when the wave ends (or trader opens), so
// this is the natural settle-up point.
function EndBountyBoard()
{
	local int i, Done;
	local KFPlayerReplicationInfo KFPRI;

	if (BountyPCs.Length == 0)
		return;

	for (i = 0; i < BountyPCs.Length; ++i)
	{
		if (BountyHave[i] >= BountyNeed[i])
			++Done;
	}

	if (Done < BountyPCs.Length)
	{
		BroadcastMinigameMessage("Bounty Board failed:" @ Done @ "/" @ BountyPCs.Length @ "bounties completed. No payout.");
		return;
	}

	for (i = 0; i < BountyPCs.Length; ++i)
	{
		if (BountyPCs[i] == None)
			continue;
		KFPRI = KFPlayerReplicationInfo(BountyPCs[i].PlayerReplicationInfo);
		if (KFPRI != None)
			KFPRI.AddDosh(BOUNTY_REWARD_DOSH);
		class'ZTMessageManager'.static.SendCritical(BountyPCs[i], "BOUNTY BOARD COMPLETE! +" $ BOUNTY_REWARD_DOSH @ "Dosh!");
	}
}

// ===================================================================
// 32. GOLDEN ZED RELAY
// A random zed turns golden every 20s. Kill it and it drops a trophy -
// but the killer CANNOT collect it. A different player must stand on it
// within 10s to bank a team-wide dosh payout. Forced two-person play.
// ===================================================================

function StartGoldenZedRelay()
{
	SetGRIPhase(0);
	SetTimer(5.f, false, 'PickGoldenZed');
	SetTimer(0.5f, true, 'GoldenTick');
}

function PickGoldenZed()
{
	local KFPawn_Monster KFPM;
	local array<KFPawn_Monster> Candidates;
	local ZTGameReplicationInfo ZTGRI;

	if (ActiveEventID != 32)
		return;

	ZTGRI = GetDKGRI();

	// One golden at a time; also pause while a trophy sits on the ground
	if ((GoldenZed != None && GoldenZed.IsAliveAndWell()) || (ZTGRI != None && ZTGRI.EventPhase == 2))
	{
		SetTimer(GOLDEN_INTERVAL, false, 'PickGoldenZed');
		return;
	}

	foreach WorldInfo.AllPawns(class'KFPawn_Monster', KFPM)
	{
		// Skip bosses / giants - a golden Scrake is fine, a golden Patriarch is not
		if (KFPM.IsAliveAndWell() && KFPM.Health <= 4000 && PlayerController(KFPM.Controller) == None)
			Candidates.AddItem(KFPM);
	}

	if (Candidates.Length == 0)
	{
		SetTimer(5.f, false, 'PickGoldenZed');
		return;
	}

	GoldenZed = Candidates[Rand(Candidates.Length)];

	// Gold treatment: bigger + faster (Costume Party / Jitterbug tech)
	GoldenZed.IntendedBodyScale = GoldenZed.IntendedBodyScale * GOLDEN_SCALE;
	GoldenZed.UpdateBodyScale(GoldenZed.IntendedBodyScale);
	GoldenZed.GroundSpeed = GoldenZed.NormalGroundSpeed * GOLDEN_SPEED;
	GoldenZed.SprintSpeed = GoldenZed.NormalSprintSpeed * GOLDEN_SPEED;

	SetGRIZoneLoc(GoldenZed.Location);
	SetGRIPhase(1);
	PlayCueToAll('EventGolden_Spawn');
	BroadcastMinigameMessage("A GOLDEN ZED has appeared! Kill it - but the killer can't collect the trophy!");

	SetTimer(GOLDEN_INTERVAL, false, 'PickGoldenZed');
}

function GoldenTick()
{
	local ZTGameReplicationInfo ZTGRI;
	local KFPlayerController KFPC;
	local KFPlayerController KFPC2;
	local KFPawn_Human KFPH;
	local KFPlayerReplicationInfo KFPRI;

	if (ActiveEventID != 32)
		return;

	ZTGRI = GetDKGRI();
	if (ZTGRI == None)
		return;

	// Track the living golden zed for the HUD marker
	if (ZTGRI.EventPhase == 1)
	{
		if (GoldenZed != None && GoldenZed.IsAliveAndWell())
		{
			SetGRIZoneLoc(GoldenZed.Location);
		}
		else if (GoldenZed != None)
		{
			// Died without our kill hook seeing it (e.g. turret owner edge cases):
			// still drop the trophy where it fell, with no killer restriction.
			GoldenKillerPRI = None;
			GoldenDropLoc = GoldenZed.Location;
			GoldenDropExpire = WorldInfo.TimeSeconds + GOLDEN_DROP_WINDOW;
			GoldenZed = None;
			SetGRIZoneLoc(GoldenDropLoc);
			SetGRIPhase(2);
		}
		return;
	}

	// Trophy on the ground: expire or collect
	if (ZTGRI.EventPhase == 2)
	{
		if (WorldInfo.TimeSeconds > GoldenDropExpire)
		{
			SetGRIPhase(0);
			BroadcastMinigameMessage("The golden trophy crumbled away...");
			return;
		}

		foreach WorldInfo.AllControllers(class'KFPlayerController', KFPC)
		{
			if (KFPC.PlayerReplicationInfo == GoldenKillerPRI)
				continue;

			KFPH = KFPawn_Human(KFPC.Pawn);
			if (KFPH == None || !KFPH.IsAliveAndWell())
				continue;

			if (VSize(KFPH.Location - GoldenDropLoc) <= GOLDEN_DROP_RADIUS)
			{
				// Banked! Team-wide payout
				foreach WorldInfo.AllControllers(class'KFPlayerController', KFPC2)
				{
					KFPRI = KFPlayerReplicationInfo(KFPC2.PlayerReplicationInfo);
					if (KFPRI != None && !KFPRI.bOnlySpectator)
						KFPRI.AddDosh(GOLDEN_TEAM_DOSH);
				}
				PlayCueToAll('EventGolden_Collected');
				BroadcastMinigameMessage("TROPHY BANKED by " $ KFPH.PlayerReplicationInfo.PlayerName $ "! +" $ GOLDEN_TEAM_DOSH @ "Dosh for everyone!");
				SetGRIPhase(0);
				return;
			}
		}
	}
}

// ===================================================================
// EVENT WAVE MUSIC SYSTEM
// ===================================================================

function LoadEventMusic()
{
	if (bEventMusicLoaded)
	{
		return;
	}

	EventMusic_Isolation = SoundCue(DynamicLoadObject("ZedternalRBPerkpackage_Resources.Sounds.EventMusic_Isolation_Cue", class'SoundCue', True));
	EventMusic_BlackoutPulse = SoundCue(DynamicLoadObject("ZedternalRBPerkpackage_Resources.Sounds.EventMusic_BlackoutPulse_Cue", class'SoundCue', True));
	EventMusic_VIP = SoundCue(DynamicLoadObject("ZedternalRBPerkpackage_Resources.Sounds.EventMusic_VIP_Cue", class'SoundCue', True));
	EventMusic_HotPotato = SoundCue(DynamicLoadObject("ZedternalRBPerkpackage_Resources.Sounds.EventMusic_HotPotato_Cue", class'SoundCue', True));
	EventMusic_Highlander = SoundCue(DynamicLoadObject("ZedternalRBPerkpackage_Resources.Sounds.EventMusic_Highlander_Cue", class'SoundCue', True));
	EventMusic_RAGE = SoundCue(DynamicLoadObject("ZedternalRBPerkpackage_Resources.Sounds.EventMusic_RAGE_Cue", class'SoundCue', True));
	EventMusic_Amogus = SoundCue(DynamicLoadObject("ZedternalRBPerkpackage_Resources.Sounds.EventMusic_Amogus_Cue", class'SoundCue', True));
	EventMusic_ChainGang = SoundCue(DynamicLoadObject("ZedternalRBPerkpackage_Resources.Sounds.EventMusic_ChainGang_Cue", class'SoundCue', True));
	EventMusic_OneInTheChamber = SoundCue(DynamicLoadObject("ZedternalRBPerkpackage_Resources.Sounds.EventMusic_OneInTheChamber_Cue", class'SoundCue', True));
	EventMusic_Paranoia = SoundCue(DynamicLoadObject("ZedternalRBPerkpackage_Resources.Sounds.EventMusic_Paranoia_Cue", class'SoundCue', True));
	EventMusic_MarkedForDeath = SoundCue(DynamicLoadObject("ZedternalRBPerkpackage_Resources.Sounds.EventMusic_MarkedForDeath_Cue", class'SoundCue', True));
	EventMusic_Redacted = SoundCue(DynamicLoadObject("ZedternalRBPerkpackage_Resources.Sounds.EventMusic_Redacted_Cue", class'SoundCue', True));
	EventMusic_FogOfWar = SoundCue(DynamicLoadObject("ZedternalRBPerkpackage_Resources.Sounds.EventMusic_FogOfWar_Cue", class'SoundCue', True));
	EventMusic_Nemesis = SoundCue(DynamicLoadObject("ZedternalRBPerkpackage_Resources.Sounds.EventMusic_Nemesis_Cue", class'SoundCue', True));
	EventMusic_Duel = SoundCue(DynamicLoadObject("ZedternalRBPerkpackage_Resources.Sounds.EventMusic_Duel_Cue", class'SoundCue', True));
	EventMusic_XMen = SoundCue(DynamicLoadObject("ZedternalRBPerkpackage_Resources.Sounds.EventMusic_XMen_Cue", class'SoundCue', True));
	EventMusic_Jitterbug = SoundCue(DynamicLoadObject("ZedternalRBPerkpackage_Resources.Sounds.EventMusic_Jitterbug_Cue", class'SoundCue', True));
	EventMusic_CostumeParty = SoundCue(DynamicLoadObject("ZedternalRBPerkpackage_Resources.Sounds.EventMusic_CostumeParty_Cue", class'SoundCue', True));
	EventMusic_DontBlink = SoundCue(DynamicLoadObject("ZedternalRBPerkpackage_Resources.Sounds.EventMusic_DontBlink_Cue", class'SoundCue', True));
	EventMusic_PassTheBomb = SoundCue(DynamicLoadObject("ZedternalRBPerkpackage_Resources.Sounds.EventMusic_PassTheBomb_Cue", class'SoundCue', True));
	EventMusic_RedLightGreenLight = SoundCue(DynamicLoadObject("ZedternalRBPerkpackage_Resources.Sounds.EventMusic_RedLightGreenLight_Cue", class'SoundCue', True));
	EventMusic_FloorIsLava = SoundCue(DynamicLoadObject("ZedternalRBPerkpackage_Resources.Sounds.EventMusic_FloorIsLava_Cue", class'SoundCue', True));
	EventMusic_BodyguardBond = SoundCue(DynamicLoadObject("ZedternalRBPerkpackage_Resources.Sounds.EventMusic_BodyguardBond_Cue", class'SoundCue', True));
	EventMusic_BountyBoard = SoundCue(DynamicLoadObject("ZedternalRBPerkpackage_Resources.Sounds.EventMusic_BountyBoard_Cue", class'SoundCue', True));
	EventMusic_GoldenZedRelay = SoundCue(DynamicLoadObject("ZedternalRBPerkpackage_Resources.Sounds.EventMusic_GoldenZedRelay_Cue", class'SoundCue', True));

	bEventMusicLoaded = True;

	`log("[DK_EVENTWAVE_MGR] Event music loaded");
}

/** Map EventID to its SoundCue. Returns None if no music for that event. */
function SoundCue GetEventMusicCue(byte EventID)
{
	switch (EventID)
	{
		case 7:  return EventMusic_Isolation;
		case 8:  return EventMusic_BlackoutPulse;
		case 9:  return EventMusic_VIP;
		case 10: return EventMusic_HotPotato;
		case 12: return EventMusic_Highlander;
		case 13: return EventMusic_RAGE;
		case 14: return EventMusic_Amogus;
		case 15: return EventMusic_ChainGang;
		case 16: return EventMusic_OneInTheChamber;
		case 17: return EventMusic_Paranoia;
		case 18: return EventMusic_MarkedForDeath;
		case 19: return EventMusic_Redacted;
		case 20: return EventMusic_FogOfWar;
		case 21: return EventMusic_Nemesis;
		case 22: return EventMusic_Duel;
		case 23: return EventMusic_XMen;
		case 24: return EventMusic_Jitterbug;
		case 25: return EventMusic_CostumeParty;
		case 26: return EventMusic_DontBlink;
		case 27: return EventMusic_PassTheBomb;
		case 28: return EventMusic_RedLightGreenLight;
		case 29: return EventMusic_FloorIsLava;
		case 30: return EventMusic_BodyguardBond;
		case 31: return EventMusic_BountyBoard;
		case 32: return EventMusic_GoldenZedRelay;
		default: return None;
	}
}

function PlayEventMusicToAll(SoundCue MusicCue)
{
	local ZTPlayerController DKPC;

	if (MusicCue == None)
	{
		return;
	}

	foreach WorldInfo.AllControllers(class'ZTPlayerController', DKPC)
	{
		DKPC.ClientPlayEventMusic(MusicCue);
	}

	`log("[DK_EVENTWAVE_MGR] Playing event music to all players");
}

function StopEventMusicForAll()
{
	local ZTPlayerController DKPC;

	foreach WorldInfo.AllControllers(class'ZTPlayerController', DKPC)
	{
		DKPC.ClientStopEventMusic(EventMusicFadeOutDuration);
	}
}

// ===================================================================
// 24. JITTERBUG
// ===================================================================

function StartJitterbug()
{
	local KFPawn_Monster KFPM;

	// Apply to any zeds already alive when the event begins
	foreach WorldInfo.AllPawns(class'KFPawn_Monster', KFPM)
	{
		if (KFPM.IsAliveAndWell())
			ApplyJitterbugSpeed(KFPM);
	}

	`log("[DK_EVENTWAVE_MGR] Jitterbug started");
}

function ApplyJitterbugSpeed(KFPawn_Monster Zed)
{
	local float Mult;

	if (Zed == None)
		return;

	Mult = JITTERBUG_MIN_SPEED_MULT + FRand() * (JITTERBUG_MAX_SPEED_MULT - JITTERBUG_MIN_SPEED_MULT);

	// All four fields: GroundSpeed/SprintSpeed are current, Normal* are what the
	// engine restores from on state transitions (this is the R.A.G.E. walk fix).
	Zed.GroundSpeed = Zed.NormalGroundSpeed * Mult;
	Zed.SprintSpeed = Zed.NormalSprintSpeed * Mult;
	Zed.NormalGroundSpeed = Zed.GroundSpeed;
	Zed.NormalSprintSpeed = Zed.SprintSpeed;
}

// ===================================================================
// 25. COSTUME PARTY
// ===================================================================

function StartCostumeParty()
{
	local KFPawn_Monster KFPM;

	foreach WorldInfo.AllPawns(class'KFPawn_Monster', KFPM)
	{
		if (KFPM.IsAliveAndWell())
			ApplyCostumeScale(KFPM);
	}

	`log("[DK_EVENTWAVE_MGR] Costume Party started");
}

function ApplyCostumeScale(KFPawn_Monster Zed)
{
	local float Scale;

	if (Zed == None)
		return;

	// Visual draw scale only - collision/hitboxes are left untouched, so this is
	// pure cosmetic chaos with zero balance impact. OnZedSpawned fires once per
	// zed, so there is no compounding.
	// Resize via the body-scale system rather than SetDrawScale: SetDrawScale also
	// scales the mesh's seating translation, sinking big zeds halfway underground
	// (and floating tiny ones). IntendedBodyScale + UpdateBodyScale (Mesh.SetScale)
	// keep feet grounded. Still cosmetic only -- collision is untouched.
	Scale = COSTUME_MIN_SCALE + FRand() * (COSTUME_MAX_SCALE - COSTUME_MIN_SCALE);
	Zed.IntendedBodyScale = Zed.IntendedBodyScale * Scale;
	Zed.UpdateBodyScale(Zed.IntendedBodyScale);
}

// ===================================================================
// 26. DON'T BLINK  (reading A: charge-the-spring)
// While any living player looks at a zed it FREEZES and charges intensity
// (0..1). The instant nobody is looking it releases: its speed and its next
// hit scale with the banked intensity, which then decays back to normal.
// ===================================================================

function StartDontBlink()
{
	DBZeds.Length = 0;
	SetTimer(DONTBLINK_TICK, true, 'UpdateDontBlink');
	`log("[DK_EVENTWAVE_MGR] Don't Blink started");
}

function RegisterDontBlinkZed(KFPawn_Monster Zed)
{
	local DontBlinkZed Entry;
	local int i;

	if (Zed == None)
		return;

	for (i = 0; i < DBZeds.Length; ++i)
	{
		if (DBZeds[i].Zed == Zed)
			return; // already tracked
	}

	Entry.Zed = Zed;
	Entry.Intensity = 0.f;
	Entry.BaseGround = Zed.NormalGroundSpeed;
	Entry.BaseSprint = Zed.NormalSprintSpeed;
	DBZeds.AddItem(Entry);
}

function UpdateDontBlink()
{
	local int i;
	local KFPawn_Monster KFPM;
	local bool bWatched;
	local float NewSpeedG, NewSpeedS;

	// Discover live zeds not yet tracked (covers zeds alive before the event
	// started, mirroring how Fog of War iterates fresh each tick).
	foreach WorldInfo.AllPawns(class'KFPawn_Monster', KFPM)
	{
		if (KFPM.IsAliveAndWell())
			RegisterDontBlinkZed(KFPM);
	}

	for (i = DBZeds.Length - 1; i >= 0; --i)
	{
		// Prune dead/None entries (no restore needed - they are gone)
		if (DBZeds[i].Zed == None || !DBZeds[i].Zed.IsAliveAndWell())
		{
			DBZeds.Remove(i, 1);
			continue;
		}

		bWatched = IsZedWatched(DBZeds[i].Zed);

		if (bWatched)
		{
			// Freeze and charge the spring
			DBZeds[i].Intensity = FMin(DBZeds[i].Intensity + DONTBLINK_CHARGE_RATE * DONTBLINK_TICK, 1.0f);

			DBZeds[i].Zed.GroundSpeed = DONTBLINK_FREEZE_SPEED;
			DBZeds[i].Zed.SprintSpeed = DONTBLINK_FREEZE_SPEED;
			DBZeds[i].Zed.NormalGroundSpeed = DONTBLINK_FREEZE_SPEED;
			DBZeds[i].Zed.NormalSprintSpeed = DONTBLINK_FREEZE_SPEED;
		}
		else
		{
			// Released: lunge at the banked speed, decay the charge
			DBZeds[i].Intensity = FMax(DBZeds[i].Intensity - DONTBLINK_DECAY_RATE * DONTBLINK_TICK, 0.0f);

			NewSpeedG = DBZeds[i].BaseGround * (1.0f + DONTBLINK_SPEED_BONUS * DBZeds[i].Intensity);
			NewSpeedS = DBZeds[i].BaseSprint * (1.0f + DONTBLINK_SPEED_BONUS * DBZeds[i].Intensity);

			DBZeds[i].Zed.GroundSpeed = NewSpeedG;
			DBZeds[i].Zed.SprintSpeed = NewSpeedS;
			DBZeds[i].Zed.NormalGroundSpeed = NewSpeedG;
			DBZeds[i].Zed.NormalSprintSpeed = NewSpeedS;

			if (DBZeds[i].Intensity > 0.05f)
			{
				DBZeds[i].Zed.SetEnraged(True);
				DBZeds[i].Zed.SetSprinting(True);
			}
		}
	}
}

function bool IsZedWatched(KFPawn_Monster Zed)
{
	local KFPlayerController KFPC;
	local vector ViewLoc, ToZed;
	local rotator ViewRot;
	local float Dist;

	if (Zed == None)
		return false;

	foreach WorldInfo.AllControllers(class'KFPlayerController', KFPC)
	{
		if (KFPC.Pawn == None || !KFPC.Pawn.IsAliveAndWell())
			continue;

		KFPC.GetPlayerViewPoint(ViewLoc, ViewRot);

		ToZed = Zed.Location - ViewLoc;
		Dist = VSize(ToZed);
		if (Dist > DONTBLINK_VIEW_RANGE || Dist < 1.f)
			continue;

		ToZed = ToZed / Dist; // normalize
		if ((ToZed dot vector(ViewRot)) < DONTBLINK_VIEW_DOT)
			continue;

		// Inside the view cone. Line-of-sight check: world geometry (walls,
		// floors, doors) breaks the gaze, so zeds you cannot actually see
		// keep moving. FastTrace is geometry-only and cheap; it runs last so
		// only zeds that already passed the range and cone checks pay for it.
		if (bDontBlinkUseTrace)
		{
			if (!FastTrace(Zed.Location, ViewLoc))
				continue; // view blocked by a wall
		}

		return true; // watched by at least one player
	}

	return false;
}

function float GetDontBlinkIntensity(KFPawn_Monster Zed)
{
	local int i;

	if (Zed == None)
		return 0.f;

	for (i = 0; i < DBZeds.Length; ++i)
	{
		if (DBZeds[i].Zed == Zed)
			return DBZeds[i].Intensity;
	}

	return 0.f;
}

function EndDontBlink()
{
	local int i;

	ClearTimer('UpdateDontBlink');

	// Restore base speeds on any survivors (e.g. event cleared mid-wave)
	for (i = 0; i < DBZeds.Length; ++i)
	{
		if (DBZeds[i].Zed != None && DBZeds[i].Zed.IsAliveAndWell())
		{
			DBZeds[i].Zed.GroundSpeed = DBZeds[i].BaseGround;
			DBZeds[i].Zed.SprintSpeed = DBZeds[i].BaseSprint;
			DBZeds[i].Zed.NormalGroundSpeed = DBZeds[i].BaseGround;
			DBZeds[i].Zed.NormalSprintSpeed = DBZeds[i].BaseSprint;
		}
	}

	DBZeds.Length = 0;
	`log("[DK_EVENTWAVE_MGR] Don't Blink ended");
}

defaultproperties
{
	ActiveEventID=0
	bChamberActive=False
	bVIPDied=False
	SwapInterval=15.f

	bEventMusicLoaded=False
	EventMusicFadeOutDuration=3.0
	bDontBlinkUseTrace=True

	Name="Default__ZTEventWaveManager"
}
