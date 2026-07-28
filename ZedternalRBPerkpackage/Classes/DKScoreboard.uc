// ===================================================================
// DKScoreboard - Custom scoreboard for Zedternal Unlimited
// Extends WMGFxHudScoreBoard for full functionality:
//   - Resolution-aware font scaling
//   - Rounded rectangle styling (DrawRectBox)
//   - All columns: Perk, Player, Kills, Assists, Dosh, Health, Armor, Ping, Platform
//   - QuickSort player ordering
//   - Color-coded health/armor/ping
//
// Only overrides Draw() to change branding from ZedternalReborn
// to Zedternal Unlimited with gold accent colors.
// ===================================================================
class DKScoreboard extends WMGFxHudScoreBoard;

event Draw(Canvas canvas)
{
	local String S;
	local PlayerController PC;
	local KFGameReplicationInfo KFGRI;
	local WMPlayerReplicationInfo WMPRI;
	local array<WMPlayerReplicationInfo> WMPRIArray;
	local float XPos, YPos, XL, YL, FontScalar, XPosCenter;
	local int i, j, PlayerIndex, NumSpec, NumPlayer, NumAlivePlayer, Width;
	local DKPlayerReplicationInfo DKPRI;
	local Color RankColor;
	local float RankXL;

	PC = GetPlayer();
	if (KFGRI == None)
	{
		KFGRI = KFGameReplicationInfo(PC.WorldInfo.GRI);
		if (KFGRI == None)
			return;
	}

	QuickSort(KFGRI.PRIArray, 0, KFGRI.PRIArray.Length - 1);

	////// Check players
	PlayerIndex = INDEX_NONE;
	NumPlayer = 0;
	for (i = (KFGRI.PRIArray.Length - 1); i >= 0; --i)
	{
		WMPRI = WMPlayerReplicationInfo(KFGRI.PRIArray[i]);
		if (WMPRI == None)
			continue;

		if (WMPRI.bOnlySpectator)
		{
			++NumSpec;
			continue;
		}

		if (WMPRI.PlayerHealthInt > 0 && WMPRI.GetTeamNum() == 0)
			++NumAlivePlayer;

		++NumPlayer;
	}
	//////

	////// Build WMPRIArray for scoreboard
	WMPRIArray.Length = NumSpec + NumPlayer;

	j = WMPRIArray.Length;
	for (i = (KFGRI.PRIArray.Length - 1); i >= 0; --i)
	{
		WMPRI = WMPlayerReplicationInfo(KFGRI.PRIArray[i]);
		if (WMPRI != None)
		{
			WMPRIArray[--j] = WMPRI;
			if (WMPRI == PC.PlayerReplicationInfo)
				PlayerIndex = j;
		}
	}
	//////

	////// Header font info
	ScoreBoardCanvas = canvas;
	ScoreBoardCanvas.Font = DrawFont;

	PickDefaultFontSize(canvas.SizeX, FontScalar);

	YL = DefaultHeight;
	XPosCenter = (ScoreBoardCanvas.ClipX * 0.5);
	//////

	////// ServerName - DK: Gold color instead of red
	XPos = XPosCenter;
	YPos = ScoreBoardCanvas.ClipY * 0.05;

	if (PC.WorldInfo.NetMode != NM_Standalone)
		S = " " $KFGRI.ServerName $" ";
	else
		S = " Zedternal Unlimited" @class'KFCommon_LocalizedStrings'.default.DiscordSoloMatchString $" ";

	ScoreBoardCanvas.TextSize(S, XL, YL, FontScalar, FontScalar);

	XPos -= (XL * 0.5);

	ScoreBoardCanvas.SetDrawColor(10, 10, 10, 150);
	DrawRectBox(XPos, YPos, XL, YL, 4);

	ScoreBoardCanvas.DrawColor = MakeColor(255, 200, 50, 255); // DK: Gold

	XPos += 5;

	if (PC.WorldInfo.NetMode != NM_Standalone)
		S = KFGRI.ServerName;
	else
		S = "Zedternal Unlimited" @class'KFCommon_LocalizedStrings'.default.DiscordSoloMatchString;

	ScoreBoardCanvas.SetPos(XPos, YPos);
	ScoreBoardCanvas.DrawText(S, , FontScalar, FontScalar);
	//////

	////// Difficulty | Wave | MapName | ElapsedTime
	XPos = XPosCenter;
	YPos += YL;

	S = Class'KFCommon_LocalizedStrings'.Static.GetDifficultyString(KFGRI.GameDifficulty);
	if (S ~= class'KFCommon_LocalizedStrings'.default.NoPreferenceString)
		S = class'KFCommon_LocalizedStrings'.default.CustomString;

	S = " " $S $"  |  " $class'KFGFxHUD_ScoreboardMapInfoContainer'.default.WaveString @KFGRI.WaveNum $"  |  " $PC.WorldInfo.Title $"  |  00 : 00 : 00 ";
	ScoreBoardCanvas.TextSize(S, XL, YL, FontScalar, FontScalar);

	XPos -= (XL * 0.5);

	ScoreBoardCanvas.SetDrawColor(10, 10, 10, 150);
	DrawRectBox(XPos, YPos, XL, YL, 4);

	ScoreBoardCanvas.DrawColor = MakeColor(98, 83, 62, 255);
	XPos += 5;

	S = Class'KFCommon_LocalizedStrings'.Static.GetDifficultyString(KFGRI.GameDifficulty);
	if (S ~= class'KFCommon_LocalizedStrings'.default.NoPreferenceString)
		S = class'KFCommon_LocalizedStrings'.default.CustomString;
	ScoreBoardCanvas.SetPos(XPos, YPos);
	ScoreBoardCanvas.DrawText(S, , FontScalar, FontScalar);
	ScoreBoardCanvas.TextSize(S, XL, YL, FontScalar, FontScalar);

	XPos += XL;
	S = "  |  " $class'KFGFxHUD_ScoreboardMapInfoContainer'.default.WaveString @KFGRI.WaveNum;
	ScoreBoardCanvas.SetPos(XPos, YPos);
	ScoreBoardCanvas.DrawText(S, , FontScalar, FontScalar);
	ScoreBoardCanvas.TextSize(S, XL, YL, FontScalar, FontScalar);

	XPos += XL;
	S = "  |  " $PC.WorldInfo.Title;
	ScoreBoardCanvas.SetPos(XPos, YPos);
	ScoreBoardCanvas.DrawText(S, , FontScalar, FontScalar);
	ScoreBoardCanvas.TextSize(S, XL, YL, FontScalar, FontScalar);

	XPos += XL;
	S = "  |  " $FormatTimeSMH(KFGRI.ElapsedTime);
	ScoreBoardCanvas.SetPos(XPos, YPos);
	ScoreBoardCanvas.DrawText(S, , FontScalar, FontScalar);
	//////

	////// Players | Alive | Spectators - DK: Gold accent
	XPos = XPosCenter;
	YPos += YL;

	S = " " $class'WMGFxHudScoreBoard'.default.PlayersString $" : " $NumPlayer $"  |  " $class'WMGFxHudScoreBoard'.default.AliveString $" : " $NumAlivePlayer $"  |  " $class'WMGFxHudScoreBoard'.default.SpectatorsString $" : " $NumSpec $" ";
	ScoreBoardCanvas.TextSize(S, XL, YL, FontScalar, FontScalar);

	XPos -= (XL * 0.5);

	ScoreBoardCanvas.SetDrawColor(10, 10, 10, 150);
	DrawRectBox(XPos, YPos, XL, YL, 4);

	ScoreBoardCanvas.DrawColor = MakeColor(255, 200, 50, 255); // DK: Gold
	XPos += 5;

	S = class'WMGFxHudScoreBoard'.default.PlayersString $" : " $NumPlayer;
	ScoreBoardCanvas.SetPos(XPos, YPos);
	ScoreBoardCanvas.DrawText(S, , FontScalar, FontScalar);
	ScoreBoardCanvas.TextSize(S, XL, YL, FontScalar, FontScalar);

	XPos += XL;
	S = "  |  " $class'WMGFxHudScoreBoard'.default.AliveString $" : " $NumAlivePlayer;
	ScoreBoardCanvas.SetPos(XPos, YPos);
	ScoreBoardCanvas.DrawText(S, , FontScalar, FontScalar);
	ScoreBoardCanvas.TextSize(S, XL, YL, FontScalar, FontScalar);

	XPos += XL;
	S = "  |  " $class'WMGFxHudScoreBoard'.default.SpectatorsString $" : " $NumSpec;
	ScoreBoardCanvas.SetPos(XPos, YPos);
	ScoreBoardCanvas.DrawText(S, , FontScalar, FontScalar);
	//////

	////// Column header row
	Width = ScoreBoardCanvas.ClipX * 0.7;

	XPos = (ScoreBoardCanvas.ClipX - Width) * 0.5;
	YPos += YL * 2.0;

	ScoreBoardCanvas.SetDrawColor(10, 10, 10, 150);
	DrawRectBox(XPos, YPos, Width, YL, 4);

	ScoreBoardCanvas.DrawColor = MakeColor(255, 255, 255, 255);

	// Calculate X offsets
	PerkXPos = Width * 0.0125;
	PlayerXPos = Width * 0.100;
	KillsXPos = Width * 0.300;
	AssistXPos = Width * 0.400;
	CashXPos = Width * 0.500;
	HealthXPos = Width * 0.600;
	ArmorXPos = Width * 0.700;
	PingXPos = Width * 0.800;
	PlatformXPos = Width * 0.8625;

	// Header texts
	ScoreBoardCanvas.SetPos(XPos + PerkXPos, YPos);
	ScoreBoardCanvas.DrawText(class'WMGFxHudScoreBoard'.default.PerkString, , FontScalar, FontScalar);

	ScoreBoardCanvas.SetPos(XPos + PlayerXPos, YPos);
	ScoreBoardCanvas.DrawText(class'KFGFxHUD_ScoreboardWidget'.default.PlayerString, , FontScalar, FontScalar);

	ScoreBoardCanvas.SetPos(XPos + KillsXPos, YPos);
	ScoreBoardCanvas.DrawText(class'KFGFxHUD_ScoreboardWidget'.default.KillsString, , FontScalar, FontScalar);

	ScoreBoardCanvas.SetPos(XPos + AssistXPos, YPos);
	ScoreBoardCanvas.DrawText(class'KFGFxHUD_ScoreboardWidget'.default.AssistsString, , FontScalar, FontScalar);

	ScoreBoardCanvas.SetPos(XPos + CashXPos, YPos);
	ScoreBoardCanvas.DrawText(class'KFGFxHUD_ScoreboardWidget'.default.DoshString, , FontScalar, FontScalar);

	ScoreBoardCanvas.SetPos(XPos + HealthXPos, YPos);
	ScoreBoardCanvas.DrawText(class'WMGFxHudScoreBoard'.default.HealthString, , FontScalar, FontScalar);

	ScoreBoardCanvas.SetPos(XPos + ArmorXPos, YPos);
	ScoreBoardCanvas.DrawText(class'WMGFxHudScoreBoard'.default.ArmorString, , FontScalar, FontScalar);

	ScoreBoardCanvas.SetPos(XPos + PingXPos, YPos);
	ScoreBoardCanvas.DrawText(class'KFGFxHUD_ScoreboardWidget'.default.PingString, , FontScalar, FontScalar);

	ScoreBoardCanvas.SetPos(XPos + PlatformXPos, YPos);
	ScoreBoardCanvas.DrawText(class'WMGFxHudScoreBoard'.default.PlatformString, , FontScalar, FontScalar);
	//////

	for (i = 0; i < WMPRIArray.length; ++i)
	{
		////// Player slot
		WMPRI = WMPRIArray[i];

		Width = ScoreBoardCanvas.ClipX * 0.7;

		XPos = (ScoreBoardCanvas.ClipX - Width) * 0.5;
		YPos += YL + 4;

		if (i == PlayerIndex)
			ScoreBoardCanvas.SetDrawColor(80, 70, 30, 150); // DK: Gold tint for local player
		else
			ScoreBoardCanvas.SetDrawColor(30, 30, 30, 150);

		DrawRectBox(XPos, YPos, Width, YL, 4);

		// Draw tier-colored background overlay for ranked players
		DKPRI = DKPlayerReplicationInfo(WMPRIArray[i]);
		if (DKPRI != None && DKPRI.PlayerRank > 0
			&& !WMPRIArray[i].bOnlySpectator && !WMPRIArray[i].bWaitingPlayer)
		{
			RankColor = class'ZedternalRBPerkpackage.DKRank'.static.GetTierColor(DKPRI.PlayerRank);
			ScoreBoardCanvas.SetDrawColor(RankColor.R, RankColor.G, RankColor.B, 30);
			ScoreBoardCanvas.SetPos(XPos, YPos);
			ScoreBoardCanvas.DrawRect(Width, YL);
		}

		ScoreBoardCanvas.DrawColor = MakeColor(255, 255, 255, 255);
		//////

		////// Perk
		ScoreBoardCanvas.SetPos(XPos + PerkXPos, YPos);

		if (WMPRI.bOnlySpectator)
			S = class'WMGFxHudScoreBoard'.default.SpectatorString;
		else if (WMPRI.bWaitingPlayer)
			S = class'WMGFxHudScoreBoard'.default.LobbyString;
		else
			S = " Lv" @string(WMPRI.PlayerLevel);

		ScoreBoardCanvas.DrawText(S, , FontScalar, FontScalar);
		//////

		////// Player (with Rank)
		DKPRI = DKPlayerReplicationInfo(WMPRI);

		if (DKPRI != None && DKPRI.PlayerRank > 0 && !WMPRI.bOnlySpectator && !WMPRI.bWaitingPlayer)
		{
			// Draw rank title text + player name (no icon on scoreboard)
			RankColor = class'ZedternalRBPerkpackage.DKRank'.static.GetTierColor(DKPRI.PlayerRank);

			S = class'ZedternalRBPerkpackage.DKRank'.static.GetRankDisplayString(DKPRI.PlayerRank);
			ScoreBoardCanvas.TextSize(S, RankXL, YL, FontScalar * 0.7f, FontScalar);

			// Dark shadow for readability
			ScoreBoardCanvas.SetDrawColor(0, 0, 0, 200);
			ScoreBoardCanvas.SetPos(XPos + PlayerXPos + 1, YPos + 1);
			ScoreBoardCanvas.DrawText(S, , FontScalar * 0.7f, FontScalar);

			// Rank text in tier color — Y uses full FontScalar to match player name height
			ScoreBoardCanvas.DrawColor = RankColor;
			ScoreBoardCanvas.SetPos(XPos + PlayerXPos, YPos);
			ScoreBoardCanvas.DrawText(S, , FontScalar * 0.7f, FontScalar);

			// Draw player name in WHITE after rank text
			ScoreBoardCanvas.DrawColor = MakeColor(255, 255, 255, 255);
			if (Len(WMPRI.PlayerName) > 20)
				S = Left(WMPRI.PlayerName, 20);
			else
				S = WMPRI.PlayerName;

			ScoreBoardCanvas.SetPos(XPos + PlayerXPos + RankXL + YL * 0.3f, YPos);
			ScoreBoardCanvas.DrawText(S, , AdjustPlayerNameScaler(FontScalar, Len(S) + 8, DefaultFontSize), FontScalar);
		}
		else
		{
			// Default: no rank or spectator/lobby
			ScoreBoardCanvas.DrawColor = MakeColor(255, 255, 255, 255);
			ScoreBoardCanvas.SetPos(XPos + PlayerXPos, YPos);

			if (Len(WMPRI.PlayerName) > 32)
				S = Left(WMPRI.PlayerName, 32);
			else
				S = WMPRI.PlayerName;

			ScoreBoardCanvas.DrawText(S, , AdjustPlayerNameScaler(FontScalar, Len(S), DefaultFontSize), FontScalar);
		}
		//////

		////// Kills
		if (WMPRI.bOnlySpectator || WMPRI.bWaitingPlayer)
			S = "-";
		else
			S = string(WMPRI.Kills);

		ScoreBoardCanvas.SetPos(XPos + KillsXPos, YPos);
		ScoreBoardCanvas.DrawText(S, , FontScalar, FontScalar);
		//////

		////// Assists
		if (WMPRI.bOnlySpectator || WMPRI.bWaitingPlayer)
			S = "-";
		else
			S = string(WMPRI.Assists);

		ScoreBoardCanvas.SetPos(XPos + AssistXPos, YPos);
		ScoreBoardCanvas.DrawText(S, , FontScalar, FontScalar);
		//////

		////// Dosh
		if (WMPRI.bOnlySpectator || WMPRI.bWaitingPlayer)
			S = "-";
		else
			S = string(int(WMPRI.Score));

		ScoreBoardCanvas.SetPos(XPos + CashXPos, YPos);
		ScoreBoardCanvas.DrawText(S, , FontScalar, FontScalar);
		//////

		////// Health
		if (WMPRI.bOnlySpectator || WMPRI.bWaitingPlayer)
		{
			S = "-";
		}
		else if (WMPRI.PlayerHealthInt <= 0)
		{
			ScoreBoardCanvas.DrawColor = MakeColor(255, 0, 0, 255);
			S = class'WMGFxHudScoreBoard'.default.DeadString;
		}
		else
		{
			if (WMPRI.PlayerHealthInt >= 150)
				ScoreBoardCanvas.DrawColor = MakeColor(46, 139, 87, 255);
			else if (WMPRI.PlayerHealthInt >= 70)
				ScoreBoardCanvas.DrawColor = MakeColor(0, 255, 0, 255);
			else if (WMPRI.PlayerHealthInt >= 30)
				ScoreBoardCanvas.DrawColor = MakeColor(255, 255, 0, 255);
			else
				ScoreBoardCanvas.DrawColor = MakeColor(255, 99, 71, 255);

			S = string(WMPRI.PlayerHealthInt) @"HP";
		}

		ScoreBoardCanvas.SetPos(XPos + HealthXPos, YPos);
		ScoreBoardCanvas.DrawText(S, , FontScalar, FontScalar);

		ScoreBoardCanvas.DrawColor = MakeColor(255, 255, 255, 255);
		//////

		////// Armor
		if (WMPRI.bOnlySpectator || WMPRI.bWaitingPlayer)
		{
			S = "-";
		}
		else if (WMPRI.PlayerArmorInt <= 0 || WMPRI.PlayerHealthInt <= 0)
		{
			ScoreBoardCanvas.DrawColor = MakeColor(255, 0, 0, 255);
			if (WMPRI.PlayerHealthInt <= 0)
				S = class'WMGFxHudScoreBoard'.default.DeadString;
			else
				S = string(0) @"AP";
		}
		else
		{
			if (WMPRI.PlayerArmorInt >= 150)
				ScoreBoardCanvas.DrawColor = MakeColor(147, 112, 219, 255);
			else if (WMPRI.PlayerArmorInt >= 70)
				ScoreBoardCanvas.DrawColor = MakeColor(0, 255, 255, 255);
			else if (WMPRI.PlayerArmorInt >= 30)
				ScoreBoardCanvas.DrawColor = MakeColor(255, 255, 0, 255);
			else
				ScoreBoardCanvas.DrawColor = MakeColor(255, 99, 71, 255);

			S = string(WMPRI.PlayerArmorInt) @"AP";
		}

		ScoreBoardCanvas.SetPos(XPos + ArmorXPos, YPos);
		ScoreBoardCanvas.DrawText(S, , FontScalar, FontScalar);

		ScoreBoardCanvas.DrawColor = MakeColor(255, 255, 255, 255);
		//////

		////// Ping
		if (WMPRI.bBot || WMPRI.bOnlySpectator || WMPRI.bWaitingPlayer)
		{
			S = "-";
		}
		else
		{
			if (WMPRI.UncompressedPing <= 100)
				ScoreBoardCanvas.DrawColor = MakeColor(0, 255, 0, 255);
			else if (WMPRI.UncompressedPing <= 200)
				ScoreBoardCanvas.DrawColor = MakeColor(255, 255, 0, 255);
			else if (WMPRI.UncompressedPing <= 300)
				ScoreBoardCanvas.DrawColor = MakeColor(255, 99, 71, 255);
			else
				ScoreBoardCanvas.DrawColor = MakeColor(255, 0, 0, 255);

			S = string(WMPRI.UncompressedPing);
		}

		ScoreBoardCanvas.SetPos(XPos + PingXPos, YPos);
		ScoreBoardCanvas.DrawText(S, , FontScalar, FontScalar);

		ScoreBoardCanvas.DrawColor = MakeColor(255, 255, 255, 255);
		//////

		////// Platform
		if (WMPRI.bBot)
			S = class'WMGFxHudScoreBoard'.default.BotPlatformString;
		else if (WMPRI.PlatformType == 2)
			S = class'WMGFxHudScoreBoard'.default.EpicPlatformString;
		else if (WMPRI.PlatformType == 1)
			S = class'WMGFxHudScoreBoard'.default.SteamPlatformString;
		else
			S = class'WMGFxHudScoreBoard'.default.UnknownPlatformString;

		ScoreBoardCanvas.SetPos(XPos + PlatformXPos, YPos);
		ScoreBoardCanvas.DrawText(S, , FontScalar, FontScalar);
		//////
	}
}

// Animated glow effect drawn behind rank icons on the scoreboard
// Uses ScoreBoardCanvas instead of Canvas (scoreboard has its own canvas)
function DrawScoreboardIconGlow(float CenterX, float CenterY, float Size, byte TierIdx, Color TierCol)
{
	local float T, Pulse, GlowSize, Alpha;
	local float DotAngle, DotDist, DotSize;
	local int i;

	T = WorldInfo.TimeSeconds;

	// Tiers 3-4: Subtle pulsing outer glow
	if (TierIdx >= 3)
	{
		Pulse = 0.5f + 0.5f * Sin(T * 2.5f);
		GlowSize = Size * (1.3f + 0.2f * Pulse);
		Alpha = 15.0f + 15.0f * Pulse;

		ScoreBoardCanvas.SetDrawColor(TierCol.R, TierCol.G, TierCol.B, byte(Alpha));
		ScoreBoardCanvas.SetPos(CenterX - GlowSize * 0.5f, CenterY - GlowSize * 0.5f);
		ScoreBoardCanvas.DrawRect(GlowSize, GlowSize);
	}

	// Tiers 5-6: Stronger pulse
	if (TierIdx >= 5)
	{
		Pulse = 0.5f + 0.5f * Sin(T * 3.0f);
		GlowSize = Size * (1.5f + 0.3f * Pulse);
		Alpha = 10.0f + 12.0f * Pulse;

		ScoreBoardCanvas.SetDrawColor(TierCol.R, TierCol.G, TierCol.B, byte(Alpha));
		ScoreBoardCanvas.SetPos(CenterX - GlowSize * 0.5f, CenterY - GlowSize * 0.5f);
		ScoreBoardCanvas.DrawRect(GlowSize, GlowSize);
	}

	// Tiers 7-9: Full glow + orbiting dots
	if (TierIdx >= 7)
	{
		Pulse = 0.5f + 0.5f * Sin(T * 4.0f);
		GlowSize = Size * (1.7f + 0.4f * Pulse);
		Alpha = 8.0f + 10.0f * Pulse;

		ScoreBoardCanvas.SetDrawColor(TierCol.R, TierCol.G, TierCol.B, byte(Alpha));
		ScoreBoardCanvas.SetPos(CenterX - GlowSize * 0.5f, CenterY - GlowSize * 0.5f);
		ScoreBoardCanvas.DrawRect(GlowSize, GlowSize);

		// Orbiting shimmer dots
		DotSize = 2.0f;
		DotDist = Size * 0.75f;

		for (i = 0; i < 4; ++i)
		{
			DotAngle = (float(i) * 1.5708f) + T * 1.5f;
			ScoreBoardCanvas.SetDrawColor(255, 255, 255, byte(40.0f + 30.0f * Sin(T * 5.0f + float(i))));
			ScoreBoardCanvas.SetPos(
				CenterX + Cos(DotAngle) * DotDist - DotSize * 0.5f,
				CenterY + Sin(DotAngle) * DotDist - DotSize * 0.5f
			);
			ScoreBoardCanvas.DrawRect(DotSize, DotSize);
		}
	}
}

defaultproperties
{
	Name="Default__DKScoreboard"
}
