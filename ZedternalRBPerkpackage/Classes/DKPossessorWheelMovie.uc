// ===================================================================
// DKPossessorWheelMovie - GFxMoviePlayer for the Possessor form wheel.
//
// REUSES the proven CommandWheel_SWF (same as the Domain wheel). The SWF
// reads slotLabelN / slotCmdN + dataReady, highlights by mouse, and on
// click calls back Callback_SlotSelected(index). We:
//   - push up to 10 form labels; slot 0 (Clot, or Slasher once that skill
//     is owned) is ALWAYS active, slots 1-9 are active only when their
//     form skill is unlocked (UnlockArr[i] > 0),
//   - implement Callback_SlotSelected to possess that form by index,
//   - commit on CLICK (the SWF's model).
//
// Input model (driven by DKPlayerController.PossessorPress):
//   - Press O while human + ability ready -> open this wheel (stays open).
//   - Move mouse to a wedge, LEFT-CLICK -> possess that form + close.
//   - Right-click / Escape -> cancel.
//   - Press O while possessed -> revert (handled server-side, no wheel).
//
// Form index order (must match DKUpgrade_Perk_Possessor_Helper.GetFormClass):
//   0 Clot/Slasher, 1 Crawler, 2 Stalker, 3 Bloat, 4 Gorefast, 5 Siren,
//   6 Husk, 7 Scrake, 8 Fleshpound, 9 Patriarch.
// ===================================================================
class DKPossessorWheelMovie extends GFxMoviePlayer;

var DKPlayerController DKPC;

// Captions for the 10 segments, form index order.
var array<string> FormLabels;

// Slot 0 caption once the Slasher skill upgrades the base form.
var string SlasherLabel;

// Packed per-slot snapshot pushed in by the controller right before OpenWheel:
// "rem0,..,rem9|tot0,..,tot9|unl0,..,unl9". The wheel only opens when the
// ability is off cooldown, so rem/tot are zeros; unlock decides which slots
// are active (slot 0 is always active, its unlock only swaps the label).
var string PendingSnapshotData;

// Parsed from PendingSnapshotData by ParsePayload().
var array<string> CdRemainArr;
var array<string> CdTotalArr;
var array<int>    UnlockArr;

function Init(optional LocalPlayer LocPlay)
{
	Super.Init(LocPlay);
}

function bool OpenWheel(DKPlayerController NewOwner)
{
	DKPC = NewOwner;

	if (MovieInfo == None)
	{
		`log("[DK] PossessorWheel: MovieInfo is None - CommandWheel_SWF not found in _Menus.upk!");
		return false;
	}

	Start();
	Advance(0.f);

	ParsePayload();
	PushLabels();
	PushCooldowns();
	SetVariableBool("_root.dataReady", true);

	if (DKPC != None && DKPC.PlayerInput != None)
		DKPC.PlayerInput.ResetInput();

	return true;
}

function CloseWheel()
{
	Close(false);

	if (DKPC != None)
	{
		DKPC.PossessorWheelMovie = None;
		DKPC = None;
	}
}

// Push form labels. Slot 0 is always active (Clot, relabelled Slasher once
// that skill is owned); slots 1-9 are active only when unlocked. The form is
// fired by index in Callback_SlotSelected, not by running the command string.
function PushLabels()
{
	local int i;
	local bool bActive;
	local string LabelText;

	for (i = 0; i < 10; i++)
	{
		bActive = (i == 0) || (i < UnlockArr.Length && UnlockArr[i] > 0);

		if (bActive && i < FormLabels.Length)
		{
			LabelText = FormLabels[i];
			if (i == 0 && UnlockArr.Length > 0 && UnlockArr[0] > 0)
				LabelText = SlasherLabel;

			SetVariableString("_root.slotLabel" $ i, LabelText);
			SetVariableString("_root.slotCmd" $ i, "possess");
		}
		else
		{
			SetVariableString("_root.slotLabel" $ i, "");
			SetVariableString("_root.slotCmd" $ i, "");
		}
	}
}

// Parse the packed snapshot from the controller into per-slot arrays:
// "rem0,..,rem9|tot0,..,tot9|unl0,..,unl9". Cooldown values stay strings
// (forwarded verbatim to the SWF); unlock is an int (0 = locked).
function ParsePayload()
{
	local array<string> Sections, U;
	local int i;

	CdRemainArr.Length = 0;
	CdTotalArr.Length = 0;
	UnlockArr.Length = 0;

	if (PendingSnapshotData == "")
		return;

	Sections = SplitString(PendingSnapshotData, "|", false);
	if (Sections.Length >= 2)
	{
		CdRemainArr = SplitString(Sections[0], ",", false);
		CdTotalArr = SplitString(Sections[1], ",", false);
	}
	if (Sections.Length >= 3)
	{
		U = SplitString(Sections[2], ",", false);
		UnlockArr.Length = U.Length;
		for (i = 0; i < U.Length; i++)
			UnlockArr[i] = int(U[i]);
	}
}

// Push the per-slot cooldown snapshot (remaining + total seconds). The wheel
// only opens when Possession is ready, so these are zeros - pushed anyway so
// the SWF's radial-fill variables are always defined.
function PushCooldowns()
{
	local int i;

	for (i = 0; i < 10; i++)
	{
		if (i < CdRemainArr.Length && i < CdTotalArr.Length)
		{
			SetVariableString("_root.slotCdRemain" $ i, CdRemainArr[i]);
			SetVariableString("_root.slotCdTotal" $ i, CdTotalArr[i]);
		}
		else
		{
			SetVariableString("_root.slotCdRemain" $ i, "0");
			SetVariableString("_root.slotCdTotal" $ i, "0");
		}
	}
}

// Flash -> UnrealScript: a slot was clicked. Possess that form by index.
function Callback_SlotSelected(int SlotIndex)
{
	local DKPlayerController PC;

	PC = DKPC;

	CloseWheel();

	if (PC != None && SlotIndex >= 0 && SlotIndex < 10)
		PC.ServerFirePossessorForm(SlotIndex);
}

// Right-click / Escape cancels without firing.
event bool FilterButtonInput(int ControllerId, name ButtonName, EInputEvent InputEvent)
{
	if (InputEvent == IE_Pressed)
	{
		if (ButtonName == 'Escape' || ButtonName == 'XboxTypeS_B' || ButtonName == 'RightMouseButton')
		{
			CloseWheel();
			return true;
		}
	}
	return false;
}

defaultproperties
{
	// Reuse the already-working command wheel SWF.
	MovieInfo=SwfMovie'ZedternalRBPerkpackage_Menus.CommandWheel_SWF'

	FormLabels(0)="Clot"
	FormLabels(1)="Crawler"
	FormLabels(2)="Stalker"
	FormLabels(3)="Bloat"
	FormLabels(4)="Gorefast"
	FormLabels(5)="Siren"
	FormLabels(6)="Husk"
	FormLabels(7)="Scrake"
	FormLabels(8)="Fleshpound"
	FormLabels(9)="Patriarch"

	SlasherLabel="Slasher"

	bAutoPlay=true
	bCaptureInput=true
	bDisplayWithHudOff=false
	bIgnoreMouseInput=false
	bShowHardwareMouseCursor=true
}
