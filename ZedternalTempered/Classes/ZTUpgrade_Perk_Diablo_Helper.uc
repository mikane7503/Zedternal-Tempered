class ZTUpgrade_Perk_Diablo_Helper extends Info transient;

var KFPawn_Human Player;
var int PerkLevel;
var int StoredDamage;
var float NextDeathwaveTime;
var float DemonSkinEndTime;
var float SkillStoredDamagePct;
var float SkillRadiusBonus;
var float SkillCooldownReduction;
var float SkillMeleeLedgerBonus;
var float SkillScorchedWakePct;
var float SkillEchoPct;
var float SkillDemonSkinResistance;
var float SkillBloodTributeHealPct;
var float SkillHellgateRadiusBonus;
var float SkillApocalypsePct;
var KFGameExplosion DeathwaveEffectTemplate;

function PostBeginPlay()
{
	Super.PostBeginPlay();
	Player = KFPawn_Human(Owner);
	NextDeathwaveTime = WorldInfo.TimeSeconds + class'ZTUpgrade_Perk_Diablo'.default.DeathwaveInterval;
	SetTimer(0.25f, True, nameof(UpdateDeathwave));
}

function SetPerkLevel(int NewLevel) { PerkLevel = Max(1, NewLevel); }

function AccumulateDamage(int Damage, class<KFDamageType> DamageType)
{
	local float Mult;
	if (PerkLevel < class'ZTConfig_Capstone'.default.Capstone_Rank1Level || Damage <= 0) return;
	Mult = 1.0f + SkillStoredDamagePct;
	if (DamageType != None && class'ZTUpgrade_Perk_Diablo'.static.IsMeleeDamageType(DamageType))
		Mult += SkillMeleeLedgerBonus;
	StoredDamage += Round(float(Damage) * Mult);
}

function bool HasDemonSkin()
{
	return WorldInfo.TimeSeconds < DemonSkinEndTime && SkillDemonSkinResistance > 0.0f;
}

function UpdateDeathwave()
{
	if (Player == None || Player.Health <= 0) { Destroy(); return; }
	if (PerkLevel < class'ZTConfig_Capstone'.default.Capstone_Rank1Level) return;
	if (WorldInfo.TimeSeconds < NextDeathwaveTime) return;
	FireDeathwave();
	NextDeathwaveTime = WorldInfo.TimeSeconds + FMax(5.0f,
		class'ZTUpgrade_Perk_Diablo'.default.DeathwaveInterval - SkillCooldownReduction);
}

function FireDeathwave()
{
	local KFPawn_Monster M;
	local KFExplosionActorReplicated ExploActor;
	local float Pct, Radius;
	local int Damage, Hits, RawStoredDamage;
	local vector Momentum, EffectLocation;

	Pct = class'ZTUpgrade_Perk_Diablo'.default.FearDeathwavePct;
	if (PerkLevel >= class'ZTConfig_Capstone'.default.Capstone_Rank2Level)
	{
		Pct = class'ZTUpgrade_Perk_Diablo'.default.HellDeathwavePct;
		Pct += SkillApocalypsePct;
	}
	RawStoredDamage = StoredDamage;
	Damage = Round(float(RawStoredDamage) * Pct);
	Radius = class'ZTUpgrade_Perk_Diablo'.default.DeathwaveRadius + SkillRadiusBonus + SkillHellgateRadiusBonus;
	StoredDamage = 0;
	if (SkillDemonSkinResistance > 0.0f) DemonSkinEndTime = WorldInfo.TimeSeconds + 5.0f;

	// The helper itself is server-only. Use KFExplosionActorReplicated so every
	// client sees and hears the capstone pulse at the player's position.
	EffectLocation = Player.Location + vect(0,0,30);
	DeathwaveEffectTemplate.Damage = 0.0f;
	DeathwaveEffectTemplate.DamageRadius = Radius;
	ExploActor = Player.Spawn(class'KFExplosionActorReplicated', Player, , EffectLocation, , , True);
	if (ExploActor != None)
	{
		ExploActor.InstigatorController = Player.Controller;
		ExploActor.Instigator = Player;
		ExploActor.Explode(DeathwaveEffectTemplate, vect(0,0,1));
	}

	`log("[ZT_DIABLO] Deathwave pulse: level=" $ PerkLevel
		@ "storedDamage=" $ RawStoredDamage @ "pulseDamage=" $ Damage @ "radius=" $ int(Radius));
	if (Damage <= 0) return;

	foreach DynamicActors(class'KFPawn_Monster', M)
	{
		if (!M.IsAliveAndWell() || VSizeSq(M.Location - Player.Location) > Radius * Radius) continue;
		Momentum = Normal(M.Location - Player.Location);
		if (IsZero(Momentum)) Momentum = vect(1,0,0);
		M.TakeDamage(Damage, Player.Controller, M.Location, Momentum * 300.0f, class'ZTDT_DiabloDeathwave', , Player);
		if (SkillScorchedWakePct > 0.0f && M.IsAliveAndWell())
			M.TakeDamage(Round(float(Damage) * SkillScorchedWakePct), Player.Controller, M.Location, vect(0,0,0), class'KFDT_Fire', , Player);
		if (SkillEchoPct > 0.0f && M.IsAliveAndWell())
			M.TakeDamage(Round(float(Damage) * SkillEchoPct), Player.Controller, M.Location, Momentum * 100.0f, class'ZTDT_DiabloDeathwave', , Player);
		Hits++;
	}
	if (Hits > 0 && SkillBloodTributeHealPct > 0.0f)
		Player.Health = Min(Player.HealthMax, Player.Health + Round(float(Player.HealthMax) * SkillBloodTributeHealPct * Hits));

	`log("[ZT_DIABLO] Deathwave resolved: damagePerTarget=" $ Damage @ "targets=" $ Hits);
}

function SetSkillValues(float StoredPct, float Radius, float Cooldown, float MeleeBonus,
	float Scorch, float Echo, float Skin, float Heal, float Gate, float Apocalypse)
{
	SkillStoredDamagePct=StoredPct; SkillRadiusBonus=Radius; SkillCooldownReduction=Cooldown;
	SkillMeleeLedgerBonus=MeleeBonus; SkillScorchedWakePct=Scorch; SkillEchoPct=Echo;
	SkillDemonSkinResistance=Skin; SkillBloodTributeHealPct=Heal; SkillHellgateRadiusBonus=Gate;
	SkillApocalypsePct=Apocalypse;
}

defaultproperties
{
	Begin Object Class=KFGameExplosion Name=DiabloDeathwaveEffectTemplate
		Damage=0.0f
		DamageRadius=200.0f
		DamageFalloffExponent=0.0f
		DamageDelay=0.0f
		bIgnoreInstigator=True
		ActorClassToIgnoreForDamage=class'KFGame.KFPawn_Human'
		MyDamageType=class'KFDT_Explosive'
		ExplosionEffects=KFImpactEffectInfo'FX_Impacts_ARCH.Explosions.HuskSuicide_Explosion'
		ExplosionSound=AkEvent'WW_WEP_Husk_Cannon.Play_WEP_Husk_Cannon_3P_Fire'
		KnockDownStrength=0.0f
		MomentumTransferScale=0.0f
		FractureMeshRadius=0.0f
		FracturePartVel=0.0f
		CamShake=CameraShake'FX_CameraShake_Arch.Misc_Explosions.Seeker6'
		CamShakeInnerRadius=200.0f
		CamShakeOuterRadius=500.0f
		CamShakeFalloff=1.5f
		bOrientCameraShakeTowardsEpicenter=True
	End Object
	DeathwaveEffectTemplate=DiabloDeathwaveEffectTemplate

	RemoteRole=ROLE_None
	bHidden=True
	bCollideActors=False
	bBlockActors=False
	Name="Default__ZTUpgrade_Perk_Diablo_Helper"
}
