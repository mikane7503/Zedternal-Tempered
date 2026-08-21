// Wrapper for ZedternalReborn.WMUpgrade_Skill_FocusInjection
//
// Fixes the byte-overwrite bug in the parent class.
// Parent uses `InHealingDamageBoost = Fb_Bonus;` which silently wipes any
// contribution from earlier skills/upgrades in the WMPerk aggregator loop
// (see WMPerk.GetHealingDamageBoost — it passes one shared byte through
// every contributor).
//
// This wrapper switches all four byte getters to clamped accumulation:
//     InX = byte(Min(int(InX) + Fb_Bonus, 255));
// so multiple healing-byte contributors stack correctly and never wrap.
class ZTWrapper_Skill_FocusInjection extends WMUpgrade_Skill_FocusInjection config(ZedternalUnlimited);

var config array<byte> Cfg_Bonus;
var config array<byte> Cfg_MaxBonus;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Cfg_Bonus[0] = 5;
		default.Cfg_Bonus[1] = 10;
		default.Cfg_MaxBonus[0] = 20;
		default.Cfg_MaxBonus[1] = 50;

		// BEGIN TEMPERED INI DEFAULTS (generated; do not edit by hand)
		default.Cfg_Bonus.Length = 2;
		default.Cfg_Bonus[0] = 5;
		default.Cfg_Bonus[1] = 8;
		default.Cfg_MaxBonus.Length = 2;
		default.Cfg_MaxBonus[0] = 15;
		default.Cfg_MaxBonus[1] = 30;
		// END TEMPERED INI DEFAULTS
		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static simulated function GetHealingDamageBoost(out byte InHealingDamageBoost, int upgLevel)
{
	local byte Fb_Bonus;

	if (default.Cfg_Bonus.Length > 0 && default.Cfg_Bonus[0] != 0)
	{
		if (upgLevel > 1 && default.Cfg_Bonus.Length > 1)
			Fb_Bonus = default.Cfg_Bonus[1];
		else
			Fb_Bonus = default.Cfg_Bonus[0];
	}
	else
	{
		if (upgLevel > 1 && default.Bonus.Length > 1)
			Fb_Bonus = default.Bonus[1];
		else
			Fb_Bonus = default.Bonus[0];
	}

	// Clamped accumulation: protects against byte rollover and preserves
	// any contribution from earlier upgrades in the aggregator loop.
	InHealingDamageBoost = byte(Min(int(InHealingDamageBoost) + int(Fb_Bonus), 255));
}

static simulated function GetMaxHealingDamageBoost(out byte InMaxHealingDamageBoost, int upgLevel)
{
	local byte Fb_MaxBonus;

	if (default.Cfg_MaxBonus.Length > 0 && default.Cfg_MaxBonus[0] != 0)
	{
		if (upgLevel > 1 && default.Cfg_MaxBonus.Length > 1)
			Fb_MaxBonus = default.Cfg_MaxBonus[1];
		else
			Fb_MaxBonus = default.Cfg_MaxBonus[0];
	}
	else
	{
		if (upgLevel > 1 && default.MaxBonus.Length > 1)
			Fb_MaxBonus = default.MaxBonus[1];
		else
			Fb_MaxBonus = default.MaxBonus[0];
	}

	InMaxHealingDamageBoost = byte(Min(int(InMaxHealingDamageBoost) + int(Fb_MaxBonus), 255));
}

static simulated function GetHealingShield(out byte InHealingShield, int upgLevel)
{
	local byte Fb_Bonus;

	if (default.Cfg_Bonus.Length > 0 && default.Cfg_Bonus[0] != 0)
	{
		if (upgLevel > 1 && default.Cfg_Bonus.Length > 1)
			Fb_Bonus = default.Cfg_Bonus[1];
		else
			Fb_Bonus = default.Cfg_Bonus[0];
	}
	else
	{
		if (upgLevel > 1 && default.Bonus.Length > 1)
			Fb_Bonus = default.Bonus[1];
		else
			Fb_Bonus = default.Bonus[0];
	}

	InHealingShield = byte(Min(int(InHealingShield) + int(Fb_Bonus), 255));
}

static simulated function GetMaxHealingShield(out byte InMaxHealingShield, int upgLevel)
{
	local byte Fb_MaxBonus;

	if (default.Cfg_MaxBonus.Length > 0 && default.Cfg_MaxBonus[0] != 0)
	{
		if (upgLevel > 1 && default.Cfg_MaxBonus.Length > 1)
			Fb_MaxBonus = default.Cfg_MaxBonus[1];
		else
			Fb_MaxBonus = default.Cfg_MaxBonus[0];
	}
	else
	{
		if (upgLevel > 1 && default.MaxBonus.Length > 1)
			Fb_MaxBonus = default.MaxBonus[1];
		else
			Fb_MaxBonus = default.MaxBonus[0];
	}

	InMaxHealingShield = byte(Min(int(InMaxHealingShield) + int(Fb_MaxBonus), 255));
}

defaultproperties
{
	Name="Default__ZTWrapper_Skill_FocusInjection"
}
