class ZTUpgrade_Perk_Hollow_Helper extends Info;

struct SHollowMastery
{
	var string WeaponName;
	var int Kills;
	var bool bUnlocked;
};

var KFPawn_Human Player;
var KFPlayerController PlayerPC;
var int PerkLevel;
var int VoidCharges;
var array<SHollowMastery> Masteries;
var array<string> ClientUnlockCache;

replication
{
	if (bNetOwner && Role == ROLE_Authority)
		ClientSyncMastery, ClientNotifyMasteryUnlock;
}

function Initialize(KFPawn_Human InPlayer)
{
	Player = InPlayer;
	if (Player != None)
		PlayerPC = KFPlayerController(Player.Controller);
}

function int FindMastery(string WeaponName)
{
	local int i;
	for (i = 0; i < Masteries.Length; ++i)
		if (Masteries[i].WeaponName == WeaponName) return i;
	return INDEX_NONE;
}

function RegisterDemolitionKill(KFWeapon KFW)
{
	local int i;
	local SHollowMastery M;
	local string WeaponName;

	if (KFW == None || class'ZTUpgrade_Perk_Hollow'.static.IsHollowWeapon(KFW)
		|| !class'ZTUpgrade_Perk_Hollow'.static.IsDemolitionDamage(KFW, None))
		return;

	WeaponName = class'ZTUpgrade_Perk_Hollow'.static.NormalizeWeaponName(string(KFW.Class.Name));
	if (!class'ZTHollowWeaponData'.static.HasHollowVariant(WeaponName))
		return;

	i = FindMastery(WeaponName);
	if (i == INDEX_NONE)
	{
		M.WeaponName = WeaponName;
		Masteries.AddItem(M);
		i = Masteries.Length - 1;
	}
	if (!Masteries[i].bUnlocked)
	{
		Masteries[i].Kills++;
		if (Masteries[i].Kills >= class'ZTUpgrade_Perk_Hollow'.default.MasteryKillsRequired)
		{
			Masteries[i].Kills = class'ZTUpgrade_Perk_Hollow'.default.MasteryKillsRequired;
			Masteries[i].bUnlocked = true;
			ClientNotifyMasteryUnlock(WeaponName);
		}
		ClientSyncMastery(WeaponName, Masteries[i].Kills, Masteries[i].bUnlocked);
	}

	if (PerkLevel >= class'ZTConfig_Capstone'.default.Capstone_Rank2Level)
		VoidCharges = Min(VoidCharges + 1, class'ZTUpgrade_Perk_Hollow'.default.MaxVoidCharges);
}

function float ConsumeVoidChargeBonus()
{
	local float Bonus;
	if (VoidCharges <= 0) return 0.0f;
	Bonus = float(VoidCharges) * class'ZTUpgrade_Perk_Hollow'.default.DamagePerVoidCharge;
	VoidCharges = 0;
	return Bonus;
}

reliable client function ClientSyncMastery(string WeaponName, int Kills, bool bUnlocked)
{
	if (bUnlocked) AddToClientUnlockCache(WeaponName);
}

reliable client function ClientNotifyMasteryUnlock(string WeaponName)
{
	AddToClientUnlockCache(WeaponName);
	if (PlayerPC != None)
		PlayerPC.ClientMessage("Hollow mastery unlocked:" @ WeaponName);
}

simulated function AddToClientUnlockCache(string WeaponName)
{
	local int i;
	for (i = 0; i < ClientUnlockCache.Length; ++i)
		if (ClientUnlockCache[i] == WeaponName) return;
	ClientUnlockCache.AddItem(WeaponName);
}

simulated function bool IsWeaponUnlockedClient(string WeaponName)
{
	local int i;
	for (i = 0; i < ClientUnlockCache.Length; ++i)
		if (ClientUnlockCache[i] == WeaponName) return true;
	return false;
}

function bool IsWeaponUnlocked(string WeaponName)
{
	local int i;
	i = FindMastery(WeaponName);
	return i != INDEX_NONE && Masteries[i].bUnlocked;
}

function int GetUnlockCount()
{
	local int i, Count;
	for (i = 0; i < Masteries.Length; ++i)
		if (Masteries[i].bUnlocked) ++Count;
	return Count;
}

function ForceCompleteWeapon(string WeaponName, optional bool bUnused)
{
	local int i;
	local SHollowMastery M;
	if (!class'ZTHollowWeaponData'.static.HasHollowVariant(WeaponName)) return;
	i = FindMastery(WeaponName);
	if (i == INDEX_NONE)
	{
		M.WeaponName = WeaponName;
		Masteries.AddItem(M);
		i = Masteries.Length - 1;
	}
	Masteries[i].Kills = class'ZTUpgrade_Perk_Hollow'.default.MasteryKillsRequired;
	Masteries[i].bUnlocked = true;
	ClientSyncMastery(WeaponName, Masteries[i].Kills, true);
}

function ForceCompleteAll()
{
	local int i;
	for (i = 0; i < class'ZTHollowWeaponData'.static.GetHollowWeaponCount(); ++i)
		ForceCompleteWeapon(class'ZTHollowWeaponData'.static.GetHollowNormName(i));
}

defaultproperties
{
	bAlwaysRelevant=false
	bOnlyRelevantToOwner=true
	RemoteRole=ROLE_SimulatedProxy
	Name="Default__ZTUpgrade_Perk_Hollow_Helper"
}
