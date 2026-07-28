// ===================================================================
// DKTrophyPickup - Physical trophy pickup for the Predator perk
//
// Extends KFDroppedPickup_Cash which has PROVEN mesh rendering.
// Spawned using the exact dosh wave pattern (SetPickupMesh etc.)
// Overrides GiveTo for owner-only trophy collection.
// ===================================================================
class DKTrophyPickup extends KFDroppedPickup_Cash;

// --- Trophy Data ---
var byte TrophyCategory;
var KFPawn_Human OwnerPawn;
var DKUpgrade_Perk_Predator_Helper OwnerHelper;

// ===================================================================
// GIVE TO - Override to collect trophy instead of giving dosh
// ===================================================================

function GiveTo(Pawn P)
{
    local KFPawn_Human KFPH;
    local DKUpgrade_Perk_Predator_Helper H;
    local bool bFoundHelper;

    `log("[DK_TROPHY] === GiveTo CALLED === Pawn:" @ P @ "OwnerPawn:" @ OwnerPawn);

    KFPH = KFPawn_Human(P);
    if (KFPH == None)
    {
        `log("[DK_TROPHY] ABORT: Not a KFPawn_Human");
        return;
    }

    if (KFPH != OwnerPawn)
    {
        `log("[DK_TROPHY] ABORT: Wrong owner. Toucher:" @ KFPH @ "Expected:" @ OwnerPawn);
        return;
    }

    `log("[DK_TROPHY] Owner match OK. Looking for helper via ChildActors...");

    bFoundHelper = False;
    foreach KFPH.ChildActors(class'DKUpgrade_Perk_Predator_Helper', H)
    {
        `log("[DK_TROPHY] Found helper:" @ H @ "- calling CollectTrophy cat:" @ TrophyCategory);
        H.CollectTrophy(TrophyCategory);
        bFoundHelper = True;
        break;
    }

    if (!bFoundHelper)
        `log("[DK_TROPHY] WARNING: No helper found via ChildActors on" @ KFPH);

    // Play pickup sound and destroy
    P.PlaySoundBase(PickUpSound);
    PickedUpBy(P);
}

// ===================================================================
// PICKED UP BY - Skip the parent's dosh-specific pickup factory logic
// ===================================================================

function PickedUpBy(Pawn P)
{
    `log("[DK_TROPHY] PickedUpBy called - destroying");
    Destroy();
}

// ===================================================================
// DESTROYED - Don't destroy inventory (matches cash pickup pattern)
// ===================================================================

event Destroyed()
{
    `log("[DK_TROPHY] Destroyed event, cat:" @ TrophyCategory);

    // Notify helper to clear drop tracking
    if (OwnerHelper != None)
        OwnerHelper.OnPickupDestroyed(self);

    TosserPRI = None;
    Inventory = None;
}

// ===================================================================
// DEFAULT PROPERTIES
// ===================================================================

defaultproperties
{
    CashAmount=0
    LifeSpan=30
    bUseLowHealthDelay=False

    Name="Default__DKTrophyPickup"
}
