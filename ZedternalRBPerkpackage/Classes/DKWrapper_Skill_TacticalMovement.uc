// Wrapper for ZedternalReborn.WMUpgrade_Skill_TacticalMovement
class DKWrapper_Skill_TacticalMovement extends WMUpgrade_Skill_TacticalMovement
	config(ZedternalUnlimited);

var config float Cfg_MoveSpeed;
var config array<float> Cfg_Speed;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Cfg_MoveSpeed = 0.05f;
		default.Cfg_Speed[0] = 1.0f;
		default.Cfg_Speed[1] = 1.15f;

		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static simulated function GetIronSightSpeedModifier(out float InSpeed, float DefaultSpeed, int upgLevel)
{
	local float Fb_Speed;

	if (default.Cfg_Speed.Length > 0 && default.Cfg_Speed[0] != 0)
	{
		if (upgLevel > 1 && default.Cfg_Speed.Length > 1)
			Fb_Speed = default.Cfg_Speed[1];
		else
			Fb_Speed = default.Cfg_Speed[0];
	}
	else
	{
		if (upgLevel > 1 && default.Speed.Length > 1)
			Fb_Speed = default.Speed[1];
		else
			Fb_Speed = default.Speed[0];
	}
	InSpeed += DefaultSpeed * Fb_Speed;
}

static simulated function ModifySpeedPassive(out float speedFactor, int upgLevel)
{
	local float Fb_MoveSpeed;

	Fb_MoveSpeed = default.Cfg_MoveSpeed;
	if (Fb_MoveSpeed == 0)
		Fb_MoveSpeed = default.MoveSpeed;
	if (upgLevel > 1)
		speedFactor += Fb_MoveSpeed;
}

defaultproperties
{
	Name="Default__DKWrapper_Skill_TacticalMovement"
}
