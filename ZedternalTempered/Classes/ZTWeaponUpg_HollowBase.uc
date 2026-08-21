// Shared gating base for skill-linked weapon upgrades.  Despite the legacy
// name, this class is also used by Execute, Headhunter and Void skill upgrades.
class ZTWeaponUpg_HollowBase extends ZTUpgrade_Weapon abstract;

var string RequiredSkillClassPath;
var bool bRequiresDeluxe;

defaultproperties
{
	bShouldLocalize=True
	LocPackage="ZedternalTempered"
	LocSection="ZTWeaponUpg_HollowBase"
	RequiredSkillClassPath=""
	bRequiresDeluxe=False
	Name="Default__ZTWeaponUpg_HollowBase"
}
