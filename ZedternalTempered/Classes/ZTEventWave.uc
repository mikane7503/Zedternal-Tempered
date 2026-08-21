// ===================================================================
// ZTEventWave - Static data and rendering helpers for Event Waves
//
// Icon UPK paths (create folder ZedternalRBPerkpackage_Resources > EventWaves):
//   UI_EventWave_Nightfall       UI_EventWave_BloodMoon
//   UI_EventWave_Whiteout        UI_EventWave_DenseFog
//   UI_EventWave_Interference    UI_EventWave_Eclipse
//   UI_EventWave_Isolation       UI_EventWave_BlackoutPulse
//   UI_EventWave_VIP             UI_EventWave_HotPotato
//   UI_EventWave_DeadSilence     UI_EventWave_Highlander
//   UI_EventWave_RAGE            UI_EventWave_Amogus
//   UI_EventWave_ChainGang       UI_EventWave_OneInTheChamber
//   UI_EventWave_Paranoia        UI_EventWave_MarkedForDeath
//   UI_EventWave_Redacted
// ===================================================================
class ZTEventWave extends Object;

var const Texture2D EventIcons[27];
var const Color EventColors[27];

static function DrawOverlay(Canvas C, byte EventID, float Alpha, float WaveElapsedTime)
{
	switch (EventID)
	{
		case 7: DrawIsolation(C, Alpha, WaveElapsedTime); break;
		case 8: DrawBlackoutPulse(C, Alpha, WaveElapsedTime); break;
		case 17: DrawParanoia(C, Alpha, WaveElapsedTime); break;
		case 20: DrawFogOfWar(C, Alpha, WaveElapsedTime); break;
		case 26: DrawDontBlink(C, Alpha, WaveElapsedTime); break;
	}
}

// ===================================================================
// EDGE VIGNETTE HELPER
// Draws only along screen edges to avoid the ugly flat-color banding
// of the old rectangular vignette. Uses thin strips at each edge
// with graduated widths and falling alpha for a smooth darkening.
// ===================================================================

static function DrawEdgeVignette(Canvas C, float W, float H, float Alpha,
	byte R, byte G, byte B, float MaxAlpha, int Layers)
{
	local int i;
	local float Frac, StripW, StripH, LayerAlpha;

	for (i = 0; i < Layers; ++i)
	{
		// Outermost layer (i=0) is strongest, innermost is weakest
		Frac = float(i) / float(Layers);
		LayerAlpha = (1.0f - Frac) * (1.0f - Frac) * MaxAlpha * Alpha;

		if (LayerAlpha < 1.0f)
			continue;

		// Each layer is a thin strip; outer layers are wider
		StripH = H * 0.02f * (1.0f - Frac * 0.5f);
		StripW = W * 0.02f * (1.0f - Frac * 0.5f);

		C.SetDrawColor(R, G, B, byte(LayerAlpha));

		// Top edge
		C.SetPos(0, H * Frac * 0.5f);
		C.DrawRect(W, StripH);

		// Bottom edge
		C.SetPos(0, H - H * Frac * 0.5f - StripH);
		C.DrawRect(W, StripH);

		// Left edge
		C.SetPos(W * Frac * 0.5f, 0);
		C.DrawRect(StripW, H);

		// Right edge
		C.SetPos(W - W * Frac * 0.5f - StripW, 0);
		C.DrawRect(StripW, H);
	}
}

// ===================================================================
// CORNER SHADOW HELPER
// Draws darkened corners only — 4 small triangular-ish regions.
// Canvas can't do real triangles, so we approximate with small rects.
// ===================================================================

static function DrawCornerShadows(Canvas C, float W, float H, float Alpha,
	byte R, byte G, byte B, float MaxAlpha)
{
	local int i;
	local float Size, StepSize, LayerAlpha, Offset;

	Size = FMin(W, H) * 0.12f;
	StepSize = Size / 8.0f;

	for (i = 0; i < 8; ++i)
	{
		Offset = float(i) * StepSize;
		LayerAlpha = (1.0f - float(i) / 8.0f) * MaxAlpha * Alpha;
		if (LayerAlpha < 1.0f) continue;

		C.SetDrawColor(R, G, B, byte(LayerAlpha));

		// Top-left
		C.SetPos(0, Offset);
		C.DrawRect(Size - Offset, StepSize);

		// Top-right
		C.SetPos(W - Size + Offset, Offset);
		C.DrawRect(Size - Offset, StepSize);

		// Bottom-left
		C.SetPos(0, H - Offset - StepSize);
		C.DrawRect(Size - Offset, StepSize);

		// Bottom-right
		C.SetPos(W - Size + Offset, H - Offset - StepSize);
		C.DrawRect(Size - Offset, StepSize);
	}
}

// ===================================================================
// 7. ISOLATION — Lonely cold feel, edge darkening only
// ===================================================================

static function DrawIsolation(Canvas C, float Alpha, float Time)
{
	local float W, H, PulseAlpha;
	W = C.SizeX;
	H = C.SizeY;

	// Slow breathing pulse on edge darkness
	PulseAlpha = (Sin(Time * 1.2f) * 0.15f + 0.85f) * Alpha;

	// Dark blue-tinted edge vignette
	DrawEdgeVignette(C, W, H, PulseAlpha, 3, 3, 12, 50.0f, 8);

	// Corner shadows for extra claustrophobia
	DrawCornerShadows(C, W, H, Alpha, 3, 3, 10, 35.0f);
}

// ===================================================================
// 8. BLACKOUT PULSE — Full black for 2s every 20s
// ===================================================================

static function DrawBlackoutPulse(Canvas C, float Alpha, float Time)
{
	local float W, H, CyclePos, BlackAlpha;
	W = C.SizeX;
	H = C.SizeY;

	// 20-second cycle: 14.5s normal, 0.5s fade in, 4.5s black, 0.5s fade out
	CyclePos = Time % 20.0f;

	if (CyclePos < 14.5f)
	{
		// Between pulses: subtle corner shadows only
		DrawCornerShadows(C, W, H, Alpha * 0.5f, 0, 0, 0, 25.0f);
		return;
	}

	if (CyclePos < 15.0f)
		BlackAlpha = (CyclePos - 14.5f) / 0.5f;
	else if (CyclePos < 19.5f)
		BlackAlpha = 1.0f;
	else
		BlackAlpha = (20.0f - CyclePos) / 0.5f;

	C.SetPos(0, 0);
	C.SetDrawColor(0, 0, 0, byte(255.0f * BlackAlpha * Alpha));
	C.DrawRect(W, H);
}

// ===================================================================
// 11. DEAD SILENCE — Cold, sterile edge darkening + heartbeat pulse
// Audio muting handled by ZTHudWrapper
// ===================================================================

static function DrawDeadSilence(Canvas C, float Alpha, float Time)
{
	local float W, H, PulseAlpha;
	W = C.SizeX;
	H = C.SizeY;

	// Heartbeat pulse (60 BPM) — brief edge flash
	PulseAlpha = Abs(Sin(Time * 3.14159f));
	PulseAlpha = PulseAlpha * PulseAlpha * PulseAlpha; // Sharp spike, long fade

	// Cold grey-blue edge vignette
	DrawEdgeVignette(C, W, H, Alpha, 5, 5, 12, 35.0f, 6);

	// Heartbeat — momentary edge pulse on top
	if (PulseAlpha > 0.3f)
	{
		DrawEdgeVignette(C, W, H, (PulseAlpha - 0.3f) * Alpha, 0, 0, 0, 20.0f, 4);
	}
}

// ===================================================================
// 13. R.A.G.E. — Red edge glow, pulsing
// ===================================================================

static function DrawRAGE(Canvas C, float Alpha, float Time)
{
	local float W, H, PulseAlpha;
	W = C.SizeX;
	H = C.SizeY;

	// Fast aggressive pulse
	PulseAlpha = (Sin(Time * 4.0f) * 0.3f + 0.7f) * Alpha;

	// Red edge vignette only
	DrawEdgeVignette(C, W, H, PulseAlpha, 35, 0, 0, 40.0f, 6);

	// Red corner shadows
	DrawCornerShadows(C, W, H, PulseAlpha, 40, 0, 0, 30.0f);
}

// ===================================================================
// 17. PARANOIA — Barely perceptible, audio-focused event
// ===================================================================

static function DrawParanoia(Canvas C, float Alpha, float Time)
{
	local float W, H, PulseAlpha;
	W = C.SizeX;
	H = C.SizeY;

	// Very subtle asymmetric pulse
	PulseAlpha = (Sin(Time * 1.5f) * 0.5f + 0.5f) * Alpha;

	// Barely visible purple corner shadows
	DrawCornerShadows(C, W, H, PulseAlpha, 8, 0, 12, 15.0f);
}

// ===================================================================
// 20. FOG OF WAR — Murky green-grey edge vignette
// Zed hiding handled by ZTEventWaveManager
// ===================================================================

static function DrawFogOfWar(Canvas C, float Alpha, float Time)
{
	local float W, H, PulseAlpha;
	W = C.SizeX;
	H = C.SizeY;

	// Slow drifting pulse
	PulseAlpha = (Sin(Time * 0.8f) * 0.15f + 0.85f) * Alpha;

	// Murky green-grey edge vignette
	DrawEdgeVignette(C, W, H, PulseAlpha, 15, 25, 15, 45.0f, 8);

	// Heavy corner shadows
	DrawCornerShadows(C, W, H, Alpha, 10, 18, 10, 40.0f);
}

// ===================================================================
// 26. DON'T BLINK — Pale, watchful edge darkening with a slow blink-pulse
// Cosmetic only; the freeze/charge behaviour lives in ZTEventWaveManager
// ===================================================================

static function DrawDontBlink(Canvas C, float Alpha, float Time)
{
	local float W, H, BlinkAlpha;
	W = C.SizeX;
	H = C.SizeY;

	// Cold pale edge vignette - the feeling of being watched back
	DrawEdgeVignette(C, W, H, Alpha, 12, 14, 20, 42.0f, 8);

	// Slow "blink" - a brief darkening sweep every ~6 seconds
	BlinkAlpha = Abs(Sin(Time * 0.52f));
	BlinkAlpha = BlinkAlpha * BlinkAlpha * BlinkAlpha * BlinkAlpha; // sharp, infrequent
	if (BlinkAlpha > 0.25f)
		DrawEdgeVignette(C, W, H, (BlinkAlpha - 0.25f) * Alpha, 0, 0, 0, 60.0f, 6);

	DrawCornerShadows(C, W, H, Alpha, 10, 12, 18, 35.0f);
}

// ===================================================================
// ICON + COLOR ACCESS
// ===================================================================

static function Texture2D GetEventIcon(byte EventID)
{
	if (EventID >= 1 && EventID <= 26)
		return default.EventIcons[EventID];
	return None;
}

static function Color GetEventColor(byte EventID)
{
	if (EventID >= 1 && EventID <= 26)
		return default.EventColors[EventID];
	return default.EventColors[0];
}

defaultproperties
{
	EventIcons(0)=None
	EventIcons(1)=None
	EventIcons(2)=None
	EventIcons(3)=None
	EventIcons(4)=None
	EventIcons(5)=None
	EventIcons(6)=None
	EventIcons(7)=Texture2D'ZedternalRBPerkpackage_Resources.EventWaves.UI_EventWave_Isolation'
	EventIcons(8)=Texture2D'ZedternalRBPerkpackage_Resources.EventWaves.UI_EventWave_BlackoutPulse'
	EventIcons(9)=Texture2D'ZedternalRBPerkpackage_Resources.EventWaves.UI_EventWave_VIP'
	EventIcons(10)=Texture2D'ZedternalRBPerkpackage_Resources.EventWaves.UI_EventWave_HotPotato'
	EventIcons(11)=Texture2D'ZedternalRBPerkpackage_Resources.EventWaves.UI_EventWave_DeadSilence'
	EventIcons(12)=Texture2D'ZedternalRBPerkpackage_Resources.EventWaves.UI_EventWave_Highlander'
	EventIcons(13)=Texture2D'ZedternalRBPerkpackage_Resources.EventWaves.UI_EventWave_RAGE'
	EventIcons(14)=Texture2D'ZedternalRBPerkpackage_Resources.EventWaves.UI_EventWave_Amogus'
	EventIcons(15)=Texture2D'ZedternalRBPerkpackage_Resources.EventWaves.UI_EventWave_ChainGang'
	EventIcons(16)=Texture2D'ZedternalRBPerkpackage_Resources.EventWaves.UI_EventWave_OneInTheChamber'
	EventIcons(17)=Texture2D'ZedternalRBPerkpackage_Resources.EventWaves.UI_EventWave_Paranoia'
	EventIcons(18)=Texture2D'ZedternalRBPerkpackage_Resources.EventWaves.UI_EventWave_MarkedForDeath'
	EventIcons(19)=Texture2D'ZedternalRBPerkpackage_Resources.EventWaves.UI_EventWave_Redacted'
	EventIcons(20)=Texture2D'ZedternalRBPerkpackage_Resources.EventWaves.UI_EventWave_FogOfWar'
	EventIcons(21)=Texture2D'ZedternalRBPerkpackage_Resources.EventWaves.UI_EventWave_Nemesis'
	EventIcons(22)=Texture2D'ZedternalRBPerkpackage_Resources.EventWaves.UI_EventWave_Duel'
	EventIcons(23)=Texture2D'ZedternalRBPerkpackage_Resources.EventWaves.UI_EventWave_XMen'
	// Costume Party event trio (24-26) -- art created and imported.
	EventIcons(24)=Texture2D'ZedternalRBPerkpackage_Resources.EventWaves.UI_EventWave_Jitterbug'
	EventIcons(25)=Texture2D'ZedternalRBPerkpackage_Resources.EventWaves.UI_EventWave_CostumeParty'
	EventIcons(26)=Texture2D'ZedternalRBPerkpackage_Resources.EventWaves.UI_EventWave_DontBlink'

	EventColors(0)=(R=255,G=255,B=255,A=255)
	EventColors(1)=(R=0,G=0,B=0,A=0)
	EventColors(2)=(R=0,G=0,B=0,A=0)
	EventColors(3)=(R=0,G=0,B=0,A=0)
	EventColors(4)=(R=0,G=0,B=0,A=0)
	EventColors(5)=(R=0,G=0,B=0,A=0)
	EventColors(6)=(R=0,G=0,B=0,A=0)
	EventColors(7)=(R=100,G=100,B=130,A=255)
	EventColors(8)=(R=180,G=180,B=180,A=255)
	EventColors(9)=(R=255,G=215,B=0,A=255)
	EventColors(10)=(R=255,G=100,B=30,A=255)
	EventColors(11)=(R=80,G=80,B=100,A=255)
	EventColors(12)=(R=200,G=170,B=50,A=255)
	EventColors(13)=(R=255,G=30,B=30,A=255)
	EventColors(14)=(R=200,G=50,B=50,A=255)
	EventColors(15)=(R=180,G=140,B=60,A=255)
	EventColors(16)=(R=220,G=220,B=220,A=255)
	EventColors(17)=(R=130,G=50,B=180,A=255)
	EventColors(18)=(R=255,G=50,B=50,A=255)
	EventColors(19)=(R=40,G=40,B=40,A=255)
	EventColors(20)=(R=60,G=120,B=80,A=255)
	EventColors(21)=(R=255,G=180,B=0,A=255)
	EventColors(22)=(R=100,G=180,B=255,A=255)
	EventColors(23)=(R=255,G=220,B=0,A=255)
	EventColors(24)=(R=0,G=220,B=255,A=255)
	EventColors(25)=(R=255,G=80,B=200,A=255)
	EventColors(26)=(R=200,G=210,B=230,A=255)

	Name="Default__ZTEventWave"
}
