// ===================================================================
// ZTEventWaveManager — Server-side event wave logic controller
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

// Amogus — NOT replicated, server-only secret
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

// Event wave music — one SoundCue per event (None = no custom music)
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
const DONTBLINK_VIEW_RANGE = 12000.f;   // max watch distance (UU)
const DONTBLINK_FREEZE_SPEED = 1.0f;    // near-zero speed while frozen
var bool bDontBlinkUseTrace;            // optional line-of-sight trace (off by default)

struct DontBlinkZed
{
	var KFPawn_Monster Zed;
	var float Intensity;
	var float BaseGround;
	var float BaseSprint;
};
var array<DontBlinkZed> DBZeds;

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
	}

	ClearTimer('SwapTargetTimer');
	ClearTimer('CheckChainGangProximity');
	ClearTimer('ApplyOITCToAllWeapons');
	ClearTimer('EnforceVIPHealth');
	ClearTimer('UpdateFogOfWarVisibility');
	ClearTimer('ApplyRAGEModifiers');
	ClearTimer('EnforceXMenPawnMods');
	ClearTimer('UpdateDontBlink');

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
	ActiveEventID = 0;

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
	// R.A.G.E.: immediately enrage — speed boost handled by EnforceRAGESpeed timer
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
// DAMAGE MODIFICATION — Called from GameInfo.NetDamage
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
			// R.A.G.E. — players deal 1.5x damage to zeds
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
	}

	return Damage;
}

// Amogus FF — returns damage if impostor hits teammate (normally blocked by FF)
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
// 20. FOG OF WAR — Hide zeds beyond visibility range
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
// 21. NEMESIS — One massively buffed zed, kill it for bonus dosh
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
// 22. DUEL — Each player assigned zed categories, can only damage theirs
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

	// Player not in list (joined mid-event?) — allow damage
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
// 23. TO ME, MY X-MEN — Random superpowers for each player
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
	local Actor HitActor;
	local vector HitLoc, HitNorm;

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

		// Inside the view cone. Optional line-of-sight check (walls).
		if (bDontBlinkUseTrace)
		{
			HitActor = KFPC.Trace(HitLoc, HitNorm, Zed.Location, ViewLoc, true);
			if (HitActor != None && HitActor != Zed)
				continue; // view blocked
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
	bDontBlinkUseTrace=False

	Name="Default__ZTEventWaveManager"
}
