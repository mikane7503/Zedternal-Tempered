class ZTUpgrade_Skill_BottomlessReserves_Helper extends Info transient;

var KFPawn_Human Player;

function PostBeginPlay()
{
	super.PostBeginPlay();

	Player = KFPawn_Human(Owner);
	if (Player == None || Player.Health <= 0)
		Destroy();
}

function StartTimer(float Interval)
{
	SetTimer(Interval, True);
}

function Timer()
{
	local Inventory Inv;
	local KFWeapon KFW;

	if (Player == None || Player.Health <= 0 || Player.InvManager == None)
	{
		Destroy();
		return;
	}

	// Iterate all weapons in inventory
	for (Inv = Player.InvManager.InventoryChain; Inv != None; Inv = Inv.Inventory)
	{
		KFW = KFWeapon(Inv);

		// Only regen for holstered weapons (not the currently held weapon)
		// Only weapons that actually use spare ammo
		if (KFW != None && KFW != Player.Weapon && KFW.SpareAmmoCapacity[0] > 0)
		{
			if (KFW.SpareAmmoCount[0] < KFW.SpareAmmoCapacity[0])
			{
				KFW.SpareAmmoCount[0] = Min(KFW.SpareAmmoCount[0] + 1, KFW.SpareAmmoCapacity[0]);
			}
		}
	}
}

defaultproperties
{
	Name="Default__ZTUpgrade_Skill_BottomlessReserves_Helper"
}
