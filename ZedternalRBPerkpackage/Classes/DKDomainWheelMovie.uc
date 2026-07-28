// ===================================================================
// DKDomainWheelMovie - GFxMoviePlayer for the Domain ability wheel.
//
// REUSES the proven CommandWheel_SWF instead of a bespoke DomainWheel SWF
// (the custom SWF would not render). The CommandWheel SWF reads slotLabelN /
// slotCmdN + dataReady, highlights by mouse, and on click calls back
// Callback_SlotSelected(index). We:
//   - push 4 labels (the Domain actions) + a non-empty slotCmd marker so the
//     4 slots are active/highlightable,
//   - implement Callback_SlotSelected to fire that action by index,
//   - commit on CLICK (the SWF's model), not key release.
//
// Input model (driven by DKPlayerController.DomainPress):
//   - Press while Room active -> open this wheel (stays open).
//   - Move mouse to a wedge, LEFT-CLICK -> fires that action + closes.
//   - Right-click / Escape -> cancel.
//
// Action index order (must match DKUpgrade_Perk_Domain_Helper.FireAction):
//   0 Shift, 1 Sever/Swap, 2 Discharge, 3 Collapse.
// ===================================================================
class DKDomainWheelMovie extends GFxMoviePlayer;

var DKPlayerController DKPC;

// Captions for the 4 segments, index order.
var array<string> ActionLabels;

// Packed per-slot snapshot pushed in by the controller right before OpenWheel:
// "rem0,..,rem9|tot0,..,tot9|unl0,..,unl9". Cooldowns animate the fill; unlock
// (0 = locked) decides which slots are shown.
var string PendingCooldownData;

// Parsed from PendingCooldownData by ParsePayload().
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
		`log("[DK] DomainWheel: MovieInfo is None - CommandWheel_SWF not found in _Menus.upk!");
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
		DKPC.DomainWheelMovie = None;
		DKPC = None;
	}
}

// Push action labels. A slot is active (highlightable + clickable, non-empty
// slotCmd) if it is a base action (0-3) or its wheel ability is unlocked
// (UnlockArr[i] > 0). The action is fired by index in Callback_SlotSelected,
// not by running the command string.
function PushLabels()
{
	local int i;
	local bool bActive;

	for (i = 0; i < 10; i++)
	{
		bActive = (i < ActionLabels.Length)
			&& ((i < 4) || (i < UnlockArr.Length && UnlockArr[i] > 0));

		if (bActive)
		{
			SetVariableString("_root.slotLabel" $ i, ActionLabels[i]);
			SetVariableString("_root.slotCmd" $ i, "domain");
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

	if (PendingCooldownData == "")
		return;

	Sections = SplitString(PendingCooldownData, "|", false);
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

// Push the per-slot cooldown snapshot (remaining + total seconds) so the SWF
// can animate a radial fill locally on its own clock. dataReady is set by
// OpenWheel AFTER this, so the SWF reads labels + cooldowns in the same pass.
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

// Flash -> UnrealScript: a slot was clicked. Fire that Domain action by index.
function Callback_SlotSelected(int SlotIndex)
{
	local DKPlayerController PC;

	PC = DKPC;

	CloseWheel();

	if (PC != None && SlotIndex >= 0 && SlotIndex < 10)
		PC.ServerFireDomainAction(SlotIndex);
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

	ActionLabels(0)="Shift"
	ActionLabels(1)="Sever / Swap"
	ActionLabels(2)="Discharge"
	ActionLabels(3)="Collapse"
	ActionLabels(4)="Stasis"
	ActionLabels(5)="Shambles"
	ActionLabels(6)="Tact"
	ActionLabels(7)="Injection Shot"
	ActionLabels(8)="Mes"
	ActionLabels(9)="Counter Shock"

	bAutoPlay=true
	bCaptureInput=true
	bDisplayWithHudOff=false
	bIgnoreMouseInput=false
	bShowHardwareMouseCursor=true
}
