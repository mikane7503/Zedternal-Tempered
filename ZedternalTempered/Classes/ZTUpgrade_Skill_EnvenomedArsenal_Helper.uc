// Helper for Envenomed Arsenal.
// Tracks weapon swaps and manages guaranteed poison proc counter.
// When a weapon swap is detected (via InitiateWeapon), grants X guaranteed poison procs.
// ModifyDamageGiven on the main skill checks and consumes these procs.
class ZTUpgrade_Skill_EnvenomedArsenal_Helper extends Info transient;

var KFPawn_Human Player;
var bool bDeluxe;
var class<KFWeapon> LastWeaponClass;
var int ProcsRemaining;

function PostBeginPlay()
{
	super.PostBeginPlay();

	Player = KFPawn_Human(Owner);
	if (Player == None || Player.Health <= 0)
		Destroy();
}

function WeaponSwapped(KFWeapon NewWeapon)
{
	local class<KFWeapon> NewClass;

	if (NewWeapon == None)
		return;

	NewClass = NewWeapon.Class;

	// Only trigger on actual weapon change (not re-equipping same weapon)
	if (LastWeaponClass != None && NewClass != LastWeaponClass)
	{
		if (bDeluxe)
			ProcsRemaining = 5;
		else
			ProcsRemaining = 3;
	}

	LastWeaponClass = NewClass;
}

function bool ConsumeProc()
{
	if (ProcsRemaining > 0)
	{
		ProcsRemaining--;
		return True;
	}

	return False;
}

defaultproperties
{
	bDeluxe=False
	ProcsRemaining=0

	Name="Default__ZTUpgrade_Skill_EnvenomedArsenal_Helper"
}
