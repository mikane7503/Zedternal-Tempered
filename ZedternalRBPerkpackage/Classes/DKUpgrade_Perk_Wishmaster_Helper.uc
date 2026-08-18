// ===================================================================
// DKUpgrade_Perk_Wishmaster_Helper - the wish machine.
//
// Lifecycle per trader:
//   WaveEnd -> StartWishOffer(): roll 3 (L20: 4) distinct wishes,
//   Stage 1 (pick wish) -> CycleSelection/ConfirmSelection ->
//   Stage 2 (pick target from up to 3 random players) -> Confirm ->
//   corruption roll -> ApplyWish -> Stage 3 (result flash) -> hidden.
//   Trader closing cancels any unfinished selection.
//
// Replication set matches Hyde/Goalkeeper (SimulatedProxy + owner-only)
// so the reliable client HUD RPCs work.
// ===================================================================
class DKUpgrade_Perk_Wishmaster_Helper extends Actor;

var int PerkLevel;

// --- Wish identities ---
const WISH_WINDFALL      = 0;  // +300 / -300 dosh
const WISH_VITALITY      = 1;  // +5 / -5 permanent max HP
const WISH_BULWARK       = 2;  // +50 armor / lose all armor
const WISH_RESUPPLY      = 3;  // full spare ammo / lose half
const WISH_ARSENAL       = 4;  // +2 grenades / lose all
const WISH_GUARDIAN      = 5;  // survive next lethal at 1 HP / first hit doubled
const WISH_REINFORCE     = 6;  // +15 / -15 permanent max armor
const WISH_HASTE         = 7;  // +10% / -10% speed next wave
const WISH_FORTUNE       = 8;  // +600 / -600 dosh
const WISH_OVERFLOW      = 9;  // +10 / -10 max HP next wave

const WISH_POOL_SIZE = 10;

// --- HUD stages ---
const WM_HUD_HIDDEN = 0;
const WM_HUD_PICK_WISH = 1;
const WM_HUD_PICK_TARGET = 2;
const WM_HUD_RESULT = 3;

// --- Selection state (server) ---
var byte Stage;
var int OfferedWishes[4];
var int OfferedCount;
var int HighlightIdx;
var int ChosenWish;
var array<KFPlayerController> Candidates;
var int WishesGrantedThisTrader;
var bool bWasTraderOpen;

// --- Skill overrides (set by DKUpgrade_Skill_* via setters; Possess pattern) ---
var float SkillCorruptionDelta;   // Silver Tongue (negative = safer wishes)
var float SkillPotencyMult;       // Greater Boon (scales numeric wish amounts)
var int SkillWishesPerTrader;     // Twin Wishes (default 1)
var int SkillCandidateCount;      // Wider Audience (default 3)
var float SkillKarmicScale;       // Karmic Bond (0 = off; granter gets scaled copy)

// Wish outcome stings (loaded via DKMutator/DKSoundManager)
var SoundCue WishGrantedSound;
var SoundCue WishCorruptedSound;

const RESULT_FLASH_SECONDS = 5.0f;

// ===================================================================
// SETUP
// ===================================================================
simulated event PostBeginPlay()
{
	local DKMutator Mutator;

	super.PostBeginPlay();

	if (Role == ROLE_Authority)
	{
		SetTimer(0.5f, True, NameOf(TraderWatch));

		foreach WorldInfo.AllActors(class'DKMutator', Mutator)
		{
			WishGrantedSound = Mutator.GetCustomSound('Wish_Granted');
			WishCorruptedSound = Mutator.GetCustomSound('Wish_Corrupted');
			break;
		}
	}
}

function SetPerkLevel(int L)
{
	PerkLevel = L;
}

// --- Skill setters (neutral values = revert) ---
function SetSkillCorruptionDelta(float D) { SkillCorruptionDelta = D; }
function SetSkillPotencyMult(float M) { SkillPotencyMult = (M > 0.0f) ? M : 1.0f; }
function SetSkillWishesPerTrader(int N) { SkillWishesPerTrader = Max(1, N); }
function SetSkillCandidateCount(int N) { SkillCandidateCount = Clamp(N, 1, 6); }
function SetSkillKarmicScale(float S) { SkillKarmicScale = FMax(0.0f, S); }

function KFPlayerController GetPC()
{
	local KFPawn_Human KFPH;

	KFPH = KFPawn_Human(Owner);
	if (KFPH == None)
		return None;

	return KFPlayerController(KFPH.Controller);
}

// ===================================================================
// TRADER EDGE WATCH - cancel unfinished selection when trader closes;
// safety-net offer if WaveEnd was missed (e.g. late join into trader).
// ===================================================================
function TraderWatch()
{
	local KFGameReplicationInfo KFGRI;
	local bool bOpen;

	KFGRI = KFGameReplicationInfo(WorldInfo.GRI);
	if (KFGRI == None)
		return;

	bOpen = KFGRI.bTraderIsOpen;

	if (!bOpen && bWasTraderOpen)
	{
		// Trader closed: unfinished selections lapse
		if (Stage == WM_HUD_PICK_WISH || Stage == WM_HUD_PICK_TARGET)
		{
			Stage = WM_HUD_HIDDEN;
			PushHUD();
			class'DKMessageManager'.static.SendMinor(GetPC(), "Wishmaster: the wish window has closed.");
		}
		WishesGrantedThisTrader = 0;
	}
	else if (bOpen && !bWasTraderOpen && Stage == WM_HUD_HIDDEN && WishesGrantedThisTrader == 0)
	{
		// Trader just opened and no offer rolled (missed WaveEnd) - roll now
		StartWishOffer();
	}

	bWasTraderOpen = bOpen;
}

// ===================================================================
// STAGE 1: OFFER
// ===================================================================
function StartWishOffer()
{
	local int i, Roll;
	local bool bDup;
	local int j;

	if (WishesGrantedThisTrader >= Max(1, SkillWishesPerTrader) || Stage != WM_HUD_HIDDEN)
		return;

	OfferedCount = (PerkLevel >= 20)
		? class'DKUpgrade_Perk_Wishmaster'.default.WishOffersL20
		: class'DKUpgrade_Perk_Wishmaster'.default.WishOffersBase;
	OfferedCount = Clamp(OfferedCount, 1, 4);

	// Distinct wishes from the pool
	i = 0;
	while (i < OfferedCount)
	{
		Roll = Rand(WISH_POOL_SIZE);
		bDup = False;
		for (j = 0; j < i; ++j)
		{
			if (OfferedWishes[j] == Roll)
			{
				bDup = True;
				break;
			}
		}

		if (!bDup)
		{
			OfferedWishes[i] = Roll;
			++i;
		}
	}

	HighlightIdx = 0;
	Stage = WM_HUD_PICK_WISH;
	PushHUD();
	class'DKMessageManager'.static.SendMinor(GetPC(), "Wishmaster: three wishes await. Comma cycles, Period confirms.");
}

// ===================================================================
// INPUT (from DKPlayerController server RPCs)
// ===================================================================
function CycleSelection()
{
	if (Stage == WM_HUD_PICK_WISH)
		HighlightIdx = (HighlightIdx + 1) % OfferedCount;
	else if (Stage == WM_HUD_PICK_TARGET && Candidates.Length > 0)
		HighlightIdx = (HighlightIdx + 1) % Candidates.Length;
	else
		return;

	PushHUD();
}

function ConfirmSelection()
{
	if (Stage == WM_HUD_PICK_WISH)
	{
		ChosenWish = OfferedWishes[HighlightIdx];
		RollCandidates();

		if (Candidates.Length == 0)
			return; // no valid targets right now - stay in wish stage

		HighlightIdx = 0;
		Stage = WM_HUD_PICK_TARGET;
		PushHUD();
	}
	else if (Stage == WM_HUD_PICK_TARGET)
	{
		if (HighlightIdx >= Candidates.Length || Candidates[HighlightIdx] == None
			|| KFPawn_Human(Candidates[HighlightIdx].Pawn) == None)
		{
			// Target vanished (left / died) - reroll candidates
			RollCandidates();
			HighlightIdx = 0;
			PushHUD();
			return;
		}

		GrantWish(ChosenWish, Candidates[HighlightIdx]);
	}
}

// ===================================================================
// STAGE 2: CANDIDATES - up to 3 random alive players, can include self.
// Solo: only yourself.
// ===================================================================
function RollCandidates()
{
	local array<KFPlayerController> Pool;
	local KFPlayerController KFPC;
	local int Pick;

	Candidates.Length = 0;

	foreach WorldInfo.AllControllers(class'KFGame.KFPlayerController', KFPC)
	{
		if (KFPawn_Human(KFPC.Pawn) != None && KFPC.Pawn.Health > 0)
			Pool.AddItem(KFPC);
	}

	while (Pool.Length > 0 && Candidates.Length < Max(1, SkillCandidateCount))
	{
		Pick = Rand(Pool.Length);
		Candidates.AddItem(Pool[Pick]);
		Pool.Remove(Pick, 1);
	}
}

// ===================================================================
// GRANT + CORRUPTION
// ===================================================================
function GrantWish(int WishID, KFPlayerController Target)
{
	local bool bCorrupted;
	local float Chance;
	local string ResultLine;

	Chance = (PerkLevel >= 10)
		? class'DKUpgrade_Perk_Wishmaster'.default.CorruptionChanceL10
		: class'DKUpgrade_Perk_Wishmaster'.default.CorruptionChance;
	Chance = FClamp(Chance + SkillCorruptionDelta, 0.02f, 0.95f);

	bCorrupted = (FRand() < Chance);

	ResultLine = ApplyWish(WishID, Target, bCorrupted, SkillPotencyMult);

	// Skill: Karmic Bond - wishing on a teammate echoes onto you
	if (SkillKarmicScale > 0.0f && Target != GetPC() && GetPC() != None)
		ApplyWish(WishID, GetPC(), bCorrupted, SkillPotencyMult * SkillKarmicScale);

	++WishesGrantedThisTrader;
	Stage = WM_HUD_RESULT;
	PushHUDResult(ResultLine, bCorrupted);
	SetTimer(RESULT_FLASH_SECONDS, False, NameOf(EndResultFlash));

	// Announce to granter + target
	PlayOutcomeSting(GetPC(), bCorrupted);
	if (Target != GetPC())
		PlayOutcomeSting(Target, bCorrupted);

	if (bCorrupted)
	{
		class'DKMessageManager'.static.SendMinor(GetPC(), "Wishmaster: THE WISH CORRUPTS!" @ ResultLine);
		if (Target != GetPC())
			class'DKMessageManager'.static.SendMinor(Target, "A corrupted wish twists your fate:" @ ResultLine);
	}
	else
	{
		class'DKMessageManager'.static.SendMinor(GetPC(), "Wishmaster: wish granted." @ ResultLine);
		if (Target != GetPC())
			class'DKMessageManager'.static.SendMinor(Target, "A wish was granted upon you:" @ ResultLine);
	}
}

// Outcome sting, heard only by the given player (client-side play).
function PlayOutcomeSting(KFPlayerController KFPC, bool bCorrupted)
{
	local SoundCue Cue;

	if (KFPC == None)
		return;

	Cue = bCorrupted ? WishCorruptedSound : WishGrantedSound;
	if (Cue != None)
		KFPC.ClientPlaySound(Cue);
}

function EndResultFlash()
{
	local KFGameReplicationInfo KFGRI;

	if (Stage == WM_HUD_RESULT)
	{
		Stage = WM_HUD_HIDDEN;
		PushHUD();

		// Skill: Twin Wishes - more wishes remaining this trader?
		KFGRI = KFGameReplicationInfo(WorldInfo.GRI);
		if (KFGRI != None && KFGRI.bTraderIsOpen
			&& WishesGrantedThisTrader < Max(1, SkillWishesPerTrader))
		{
			StartWishOffer();
		}
	}
}

// Applies the wish (or its corrupted opposite) at the given potency.
// Binary effects (Guardian/Curse, armor shatter, ammo halving) ignore
// potency; numeric amounts scale with it. Returns the result line.
function string ApplyWish(int WishID, KFPlayerController Target, bool bCorrupted, float Potency)
{
	local KFPawn_Human TP;
	local KFPlayerReplicationInfo TPRI;
	local DKWish_Buff Buff;
	local KFWeapon KFW;
	local KFInventoryManager KFIM;
	local string TName;
	local int Amt;

	TP = KFPawn_Human(Target.Pawn);
	if (TP == None)
		return "the wish fizzled.";

	if (Potency <= 0.0f)
		Potency = 1.0f;

	TPRI = KFPlayerReplicationInfo(Target.PlayerReplicationInfo);
	TName = (TPRI != None) ? TPRI.PlayerName : "someone";

	switch (WishID)
	{
		case WISH_WINDFALL:
			Amt = Round(300.0f * Potency);
			if (!bCorrupted)
			{
				TPRI.AddDosh(Amt);
				return TName @ "receives" @ Amt @ "Dosh.";
			}
			TPRI.AddDosh(-Min(Amt, TPRI.Score));
			return TName @ "loses" @ Amt @ "Dosh.";

		case WISH_VITALITY:
			Amt = Round(5.0f * Potency);
			Buff = GetBuff(TP);
			if (!bCorrupted)
			{
				Buff.AddPermHP(Amt);
				return TName @ "gains +" $ Amt @ "permanent Max Health.";
			}
			Buff.AddPermHP(-Amt);
			return TName @ "loses" @ Amt @ "Max Health.";

		case WISH_BULWARK:
			Amt = Round(50.0f * Potency);
			if (!bCorrupted)
			{
				TP.Armor = Min(TP.MaxArmor, TP.Armor + Amt);
				return TName @ "gains" @ Amt @ "Armor.";
			}
			TP.Armor = 0;
			return TName $ "'s armor shatters completely.";

		case WISH_RESUPPLY:
			foreach TP.InvManager.InventoryActors(class'KFGame.KFWeapon', KFW)
			{
				if (!bCorrupted)
					KFW.AddAmmo(100000);
				else
					KFW.SpareAmmoCount[0] = Max(0, KFW.SpareAmmoCount[0] / 2);
			}
			if (!bCorrupted)
				return TName $ "'s spare ammo is fully restocked.";
			return TName @ "loses half of all spare ammo.";

		case WISH_ARSENAL:
			KFIM = KFInventoryManager(TP.InvManager);
			if (KFIM == None)
				return "the wish fizzled.";
			Amt = Max(1, Round(2.0f * Potency));
			if (!bCorrupted)
			{
				KFIM.GrenadeCount = byte(Min(int(KFIM.GrenadeCount) + Amt, 15));
				return TName @ "receives" @ Amt @ "grenades.";
			}
			KFIM.GrenadeCount = 0;
			return TName $ "'s grenades vanish.";

		case WISH_GUARDIAN:
			Buff = GetBuff(TP);
			if (!bCorrupted)
			{
				Buff.GrantGuardian();
				return TName @ "will survive the next lethal hit at 1 HP.";
			}
			Buff.GrantCurse();
			return "the next hit" @ TName @ "takes is DOUBLED.";

		case WISH_REINFORCE:
			Amt = Round(15.0f * Potency);
			Buff = GetBuff(TP);
			if (!bCorrupted)
			{
				Buff.AddPermArmor(Amt);
				return TName @ "gains +" $ Amt @ "permanent Max Armor.";
			}
			Buff.AddPermArmor(-Amt);
			return TName @ "loses" @ Amt @ "Max Armor.";

		case WISH_HASTE:
			Buff = GetBuff(TP);
			if (!bCorrupted)
			{
				Buff.SetWaveSpeed(1.10f);
				return TName @ "moves 10% faster next wave.";
			}
			Buff.SetWaveSpeed(0.90f);
			return TName @ "moves 10% slower next wave.";

		case WISH_FORTUNE:
			Amt = Round(600.0f * Potency);
			if (!bCorrupted)
			{
				TPRI.AddDosh(Amt);
				return TName @ "receives" @ Amt @ "Dosh!";
			}
			TPRI.AddDosh(-Min(Amt, TPRI.Score));
			return TName @ "loses" @ Amt @ "Dosh!";

		case WISH_OVERFLOW:
			Amt = Round(10.0f * Potency);
			Buff = GetBuff(TP);
			if (!bCorrupted)
			{
				Buff.AddWaveHP(Amt);
				return TName @ "gains +" $ Amt @ "Max Health for the next wave.";
			}
			Buff.AddWaveHP(-Amt);
			return TName @ "loses" @ Amt @ "Max Health for the next wave.";
	}

	return "the wish fizzled.";
}

function DKWish_Buff GetBuff(KFPawn_Human TP)
{
	local DKWish_Buff B;

	foreach TP.ChildActors(class'DKWish_Buff', B)
		return B;

	return TP.Spawn(class'DKWish_Buff', TP);
}

// ===================================================================
// WISH DISPLAY NAMES (short, for the HUD card rows)
// ===================================================================
function string GetWishLabel(int WishID)
{
	switch (WishID)
	{
		case WISH_WINDFALL:  return "Windfall (+300 Dosh)";
		case WISH_VITALITY:  return "Vitality (+5 Max HP)";
		case WISH_BULWARK:   return "Bulwark (+50 Armor)";
		case WISH_RESUPPLY:  return "Resupply (full spare ammo)";
		case WISH_ARSENAL:   return "Arsenal (+2 Grenades)";
		case WISH_GUARDIAN:  return "Guardian Angel (cheat death)";
		case WISH_REINFORCE: return "Reinforcement (+15 Max Armor)";
		case WISH_HASTE:     return "Haste (+10% Speed, 1 wave)";
		case WISH_FORTUNE:   return "Fortune (+600 Dosh)";
		case WISH_OVERFLOW:  return "Overflow (+10 Max HP, 1 wave)";
	}
	return "???";
}

function string GetCandidateLabel(int Idx)
{
	local KFPlayerReplicationInfo TPRI;

	if (Idx >= Candidates.Length || Candidates[Idx] == None)
		return "---";

	TPRI = KFPlayerReplicationInfo(Candidates[Idx].PlayerReplicationInfo);
	if (TPRI == None)
		return "---";

	if (Candidates[Idx] == GetPC())
		return TPRI.PlayerName @ "(YOU)";

	return TPRI.PlayerName;
}

// ===================================================================
// HUD PUSH (server builds strings, client renders)
// ===================================================================
function PushHUD()
{
	local string S0, S1, S2, S3, S4, S5;
	local int Count;

	if (Stage == WM_HUD_PICK_WISH)
	{
		Count = OfferedCount;
		S0 = GetWishLabel(OfferedWishes[0]);
		if (Count > 1) S1 = GetWishLabel(OfferedWishes[1]);
		if (Count > 2) S2 = GetWishLabel(OfferedWishes[2]);
		if (Count > 3) S3 = GetWishLabel(OfferedWishes[3]);
	}
	else if (Stage == WM_HUD_PICK_TARGET)
	{
		Count = Candidates.Length;
		S0 = GetCandidateLabel(0);
		if (Count > 1) S1 = GetCandidateLabel(1);
		if (Count > 2) S2 = GetCandidateLabel(2);
		if (Count > 3) S3 = GetCandidateLabel(3);
		if (Count > 4) S4 = GetCandidateLabel(4);
		if (Count > 5) S5 = GetCandidateLabel(5);
	}

	ClientWishmasterHUD(Stage, byte(Count), byte(HighlightIdx), S0, S1, S2, S3, S4, S5, "", False);
}

function PushHUDResult(string ResultLine, bool bCorrupted)
{
	ClientWishmasterHUD(WM_HUD_RESULT, 0, 0, "", "", "", "", "", "", ResultLine, bCorrupted);
}

reliable client function ClientWishmasterHUD(byte InStage, byte InCount, byte InHighlight,
	string S0, string S1, string S2, string S3, string S4, string S5, string ResultLine, bool bInCorrupted)
{
	local KFPlayerController LocalPC;
	local DKHudWrapper HUD;

	LocalPC = KFPlayerController(GetALocalPlayerController());
	if (LocalPC == None)
		return;

	HUD = class'DKHudWrapper'.static.GetReaperHUD(LocalPC);
	if (HUD == None)
		return;

	if (InStage == WM_HUD_HIDDEN)
		HUD.ClearWishmasterDisplay();
	else
		HUD.UpdateWishmasterDisplay(InStage, InCount, InHighlight, S0, S1, S2, S3, S4, S5, ResultLine, bInCorrupted);
}

// ===================================================================
// CLEANUP
// ===================================================================
simulated function Destroyed()
{
	if (Role == ROLE_Authority)
		ClientWishmasterHUD(WM_HUD_HIDDEN, 0, 0, "", "", "", "", "", "", "", False);

	Super.Destroyed();
}

defaultproperties
{
	RemoteRole=ROLE_SimulatedProxy
	bOnlyRelevantToOwner=True
	bAlwaysRelevant=False
	bSkipActorPropertyReplication=False
	bHidden=True
	PerkLevel=1
	SkillPotencyMult=1.0f
	SkillWishesPerTrader=1
	SkillCandidateCount=3

	Name="Default__DKUpgrade_Perk_Wishmaster_Helper"
}
