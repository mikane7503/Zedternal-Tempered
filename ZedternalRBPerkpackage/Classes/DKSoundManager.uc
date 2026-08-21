// ===================================================================
// DKSoundManager - Native Audio System (NO WWISE REQUIRED!)
// Plays raw .wav files using UE3's native SoundCue system
// Bypasses AkEvent/Wwise completely
// SIMPLIFIED: No singleton, data stored in mutator
// UPDATED: Added The Watcher easter egg sounds
// UPDATED: Added Wraith Form (Haunted tree) activation sound
// UPDATED: Added PlaySound() convenience function for helpers
// ===================================================================
class DKSoundManager extends Object
    abstract;

// Sound registry entry - using native UE3 audio
struct CustomSoundEntry
{
    var name SoundID;
    var string SoundCuePath;
    var bool bCustomSoundLoaded;
    var SoundCue LoadedSound;
};

// Static storage (will be populated at runtime)
var array<CustomSoundEntry> RegisteredSounds;
var bool bInitialized;

// ===================================================================
// INITIALIZATION
// ===================================================================

static function Initialize(DKMutator Mutator)
{
    `log("===== DKSoundManager: Initializing Native Audio System =====");
    `log("DKSoundManager: Using UE3 SoundCue system (NO WWISE REQUIRED!)");
    
    RegisterDefaultSounds(Mutator);
    LoadCustomSounds(Mutator);
    
    `log("DKSoundManager: Initialization complete -" @ Mutator.CustomSounds.Length @ "sounds registered");
}

// ===================================================================
// SOUND REGISTRATION
// ===================================================================

static function RegisterDefaultSounds(DKMutator Mutator)
{
    // Chronoshift ability activation
    RegisterSound(Mutator, 'Chronoshift_Activate', 
        "ZedternalRBPerkpackage_Resources.Sounds.Chronoshift_Activate_Cue");
    
    // Speedfreak - Blink Strike dash activation
    RegisterSound(Mutator, 'BlinkStrike_Activate',
        "ZedternalRBPerkpackage_Resources.Sounds.BlinkStrike_Activate_Cue");
    
    // Perk unlock sound
    RegisterSound(Mutator, 'PerkUnlock_Epic',
        "ZedternalRBPerkpackage_Resources.Sounds.PerkUnlock_Epic_Cue");
    
    // Achievement unlock sound
    RegisterSound(Mutator, 'Achievement_Complete',
        "ZedternalRBPerkpackage_Resources.Sounds.Achievement_Complete_Cue");
    
    // Boss wave start
    RegisterSound(Mutator, 'BossWave_Start',
        "ZedternalRBPerkpackage_Resources.Sounds.BossWave_Start_Cue");
    
    // Inferno ability activation (Cinder perk)
    RegisterSound(Mutator, 'Inferno_Activate',
        "ZedternalRBPerkpackage_Resources.Sounds.Inferno_Activate_Cue");
    
    // Phoenix Protocol activation (Cinder level 20)
    RegisterSound(Mutator, 'Phoenix_Protocol',
        "ZedternalRBPerkpackage_Resources.Sounds.Phoenix_Protocol_Cue");
    
    // Hivemind - Swarm Collective activation (team-wide)
    RegisterSound(Mutator, 'Hivemind_Collective_Activate',
        "ZedternalRBPerkpackage_Resources.Sounds.Hivemind_Collective_Activate_Cue");
    
    // Wishmaster - wish outcome stings (granter + receiver only)
    RegisterSound(Mutator, 'Wish_Granted',
        "ZedternalRBPerkpackage_Resources.Sounds.Wish_Granted_Cue");
    
    RegisterSound(Mutator, 'Wish_Corrupted',
        "ZedternalRBPerkpackage_Resources.Sounds.Wish_Corrupted_Cue");
    
    // Parasite - Hemorrhage Pulse AOE life-drain
    RegisterSound(Mutator, 'Parasite_Hemorrhage_Pulse',
        "ZedternalRBPerkpackage_Resources.Sounds.Parasite_Hemorrhage_Pulse_Cue");
    
    // Parasite - Blood Harvest ready notification
    RegisterSound(Mutator, 'Parasite_BloodHarvest_Ready',
        "ZedternalRBPerkpackage_Resources.Sounds.Parasite_BloodHarvest_Ready_Cue");
    
    // ===================================================================
    // TREE ABILITY SOUNDS
    // ===================================================================
    
    // Wraith Form activation (Haunted tree - 5 second immunity)
    RegisterSound(Mutator, 'WraithForm_Activate',
        "ZedternalRBPerkpackage_Resources.Sounds.WraithForm_Activate_Cue");
    
    // ===================================================================
    // THE WATCHER - Easter Egg Sounds
    // ===================================================================
    
    // Watcher ambient drone (unsettling background hum)
    RegisterSound(Mutator, 'Watcher_Ambient',
        "ZedternalRBPerkpackage_Resources.Sounds.Watcher_Ambient_Cue");
    
    // Eye manifestation sound (wet organic/reversed gasp)
    RegisterSound(Mutator, 'Watcher_Eye_Appear',
        "ZedternalRBPerkpackage_Resources.Sounds.Watcher_Eye_Appear_Cue");
    
    // Eye blink sound (quick wet blink)
    RegisterSound(Mutator, 'Watcher_Eye_Blink',
        "ZedternalRBPerkpackage_Resources.Sounds.Watcher_Eye_Blink_Cue");
    
    // Whisper sound (distorted unintelligible whisper)
    RegisterSound(Mutator, 'Watcher_Whisper',
        "ZedternalRBPerkpackage_Resources.Sounds.Watcher_Whisper_Cue");
    
    // Static burst (TV/digital static)
    RegisterSound(Mutator, 'Watcher_Static',
        "ZedternalRBPerkpackage_Resources.Sounds.Watcher_Static_Cue");
    
    // Heartbeat (deep slow heartbeat for stage 4+)
    RegisterSound(Mutator, 'Watcher_Heartbeat',
        "ZedternalRBPerkpackage_Resources.Sounds.Watcher_Heartbeat_Cue");
    
    // Escalation sound (rising tension for stage changes)
    RegisterSound(Mutator, 'Watcher_Escalate',
        "ZedternalRBPerkpackage_Resources.Sounds.Watcher_Escalate_Cue");
    
    // ===================================================================
    // ELDRITCH CHARACTER SOUNDS
    // ===================================================================
    
    // AllSeeingOne - Glimpse Beyond
    RegisterSound(Mutator, 'Eldritch_GlimpseBeyond_Ready',
        "ZedternalRBPerkpackage_Resources.Sounds.Eldritch_GlimpseBeyond_Ready_Cue");
    RegisterSound(Mutator, 'Eldritch_GlimpseBeyond_Fire',
        "ZedternalRBPerkpackage_Resources.Sounds.Eldritch_GlimpseBeyond_Fire_Cue");
    
    // ConstructedOne - Reactive Plating
    RegisterSound(Mutator, 'Eldritch_ReactivePlating_Absorb',
        "ZedternalRBPerkpackage_Resources.Sounds.Eldritch_ReactivePlating_Absorb_Cue");
    
    // ElusiveOne - Phase Walk
    RegisterSound(Mutator, 'Eldritch_PhaseWalk_Activate',
        "ZedternalRBPerkpackage_Resources.Sounds.Eldritch_PhaseWalk_Activate_Cue");
    
    // ForcefulOne - Kinetic Burst
    RegisterSound(Mutator, 'Eldritch_KineticBurst_Activate',
        "ZedternalRBPerkpackage_Resources.Sounds.Eldritch_KineticBurst_Activate_Cue");
    
    // GrinningOne - Creeping Madness
    RegisterSound(Mutator, 'Eldritch_CreepingMadness_Stack',
        "ZedternalRBPerkpackage_Resources.Sounds.Eldritch_CreepingMadness_Stack_Cue");
    RegisterSound(Mutator, 'Eldritch_CreepingMadness_Decay',
        "ZedternalRBPerkpackage_Resources.Sounds.Eldritch_CreepingMadness_Decay_Cue");
    
    // MythicalOne - Forbidden Knowledge
    RegisterSound(Mutator, 'Eldritch_ForbiddenKnowledge_Tome',
        "ZedternalRBPerkpackage_Resources.Sounds.Eldritch_ForbiddenKnowledge_Tome_Cue");
    
    // ShapelessOne - Adaptive Form
    RegisterSound(Mutator, 'Eldritch_AdaptiveForm_Shift',
        "ZedternalRBPerkpackage_Resources.Sounds.Eldritch_AdaptiveForm_Shift_Cue");
    
    // SunkenOne - Abyssal Mark
    RegisterSound(Mutator, 'Eldritch_AbyssalMark_Apply',
        "ZedternalRBPerkpackage_Resources.Sounds.Eldritch_AbyssalMark_Apply_Cue");
    
    // ===================================================================
    // GAMBIT - Roll & Result Sounds (6)
    // ===================================================================

    // Roll sounds (one per rarity tier)
    RegisterSound(Mutator, 'Gambit_Roll_Normal',
        "ZedternalRBPerkpackage_Resources.Sounds.Gambit_Roll_Normal_Cue");
    RegisterSound(Mutator, 'Gambit_Roll_Rare',
        "ZedternalRBPerkpackage_Resources.Sounds.Gambit_Roll_Rare_Cue");
    RegisterSound(Mutator, 'Gambit_Roll_Legendary',
        "ZedternalRBPerkpackage_Resources.Sounds.Gambit_Roll_Legendary_Cue");
    RegisterSound(Mutator, 'Gambit_Roll_Mythic',
        "ZedternalRBPerkpackage_Resources.Sounds.Gambit_Roll_Mythic_Cue");

    // Result sounds
    RegisterSound(Mutator, 'Gambit_Complete',
        "ZedternalRBPerkpackage_Resources.Sounds.Gambit_Complete_Cue");
    RegisterSound(Mutator, 'Gambit_Failed',
        "ZedternalRBPerkpackage_Resources.Sounds.Gambit_Failed_Cue");

    // ===================================================================
    // GAMBIT - Skill Sounds (5)
    // ===================================================================

    // Wild Card - instant auto-complete proc
    RegisterSound(Mutator, 'Gambit_WildCard',
        "ZedternalRBPerkpackage_Resources.Sounds.Gambit_WildCard_Cue");

    // Double or Nothing - coin flip win
    RegisterSound(Mutator, 'Gambit_DoubleOrNothing_Win',
        "ZedternalRBPerkpackage_Resources.Sounds.Gambit_DoubleOrNothing_Win_Cue");

    // Double or Nothing - coin flip lose
    RegisterSound(Mutator, 'Gambit_DoubleOrNothing_Lose',
        "ZedternalRBPerkpackage_Resources.Sounds.Gambit_DoubleOrNothing_Lose_Cue");

    // Royal Flush - triple reward proc
    RegisterSound(Mutator, 'Gambit_RoyalFlush',
        "ZedternalRBPerkpackage_Resources.Sounds.Gambit_RoyalFlush_Cue");

    // Bluff - cheat death activation
    RegisterSound(Mutator, 'Gambit_Bluff',
        "ZedternalRBPerkpackage_Resources.Sounds.Gambit_Bluff_Cue");

    // ===================================================================
    // SHAPESHIFTER - Buff Activation Sounds (15)
    // ===================================================================

    // Offense
    RegisterSound(Mutator, 'Shapeshifter_Buff_Carnage',
        "ZedternalRBPerkpackage_Resources.Sounds.Shapeshifter_Buff_Carnage_Cue");
    RegisterSound(Mutator, 'Shapeshifter_Buff_Executioner',
        "ZedternalRBPerkpackage_Resources.Sounds.Shapeshifter_Buff_Executioner_Cue");
    RegisterSound(Mutator, 'Shapeshifter_Buff_Rampage',
        "ZedternalRBPerkpackage_Resources.Sounds.Shapeshifter_Buff_Rampage_Cue");
    RegisterSound(Mutator, 'Shapeshifter_Buff_Crusher',
        "ZedternalRBPerkpackage_Resources.Sounds.Shapeshifter_Buff_Crusher_Cue");
    RegisterSound(Mutator, 'Shapeshifter_Buff_Berserker',
        "ZedternalRBPerkpackage_Resources.Sounds.Shapeshifter_Buff_Berserker_Cue");

    // Defense
    RegisterSound(Mutator, 'Shapeshifter_Buff_Fortress',
        "ZedternalRBPerkpackage_Resources.Sounds.Shapeshifter_Buff_Fortress_Cue");
    RegisterSound(Mutator, 'Shapeshifter_Buff_Leech',
        "ZedternalRBPerkpackage_Resources.Sounds.Shapeshifter_Buff_Leech_Cue");

    // Handling
    RegisterSound(Mutator, 'Shapeshifter_Buff_Anchor',
        "ZedternalRBPerkpackage_Resources.Sounds.Shapeshifter_Buff_Anchor_Cue");
    RegisterSound(Mutator, 'Shapeshifter_Buff_Hawk',
        "ZedternalRBPerkpackage_Resources.Sounds.Shapeshifter_Buff_Hawk_Cue");
    RegisterSound(Mutator, 'Shapeshifter_Buff_Speedloader',
        "ZedternalRBPerkpackage_Resources.Sounds.Shapeshifter_Buff_Speedloader_Cue");
    RegisterSound(Mutator, 'Shapeshifter_Buff_Switchblade',
        "ZedternalRBPerkpackage_Resources.Sounds.Shapeshifter_Buff_Switchblade_Cue");

    // Utility
    RegisterSound(Mutator, 'Shapeshifter_Buff_Speedfreak',
        "ZedternalRBPerkpackage_Resources.Sounds.Shapeshifter_Buff_Speedfreak_Cue");
    RegisterSound(Mutator, 'Shapeshifter_Buff_Hoarder',
        "ZedternalRBPerkpackage_Resources.Sounds.Shapeshifter_Buff_Hoarder_Cue");
    RegisterSound(Mutator, 'Shapeshifter_Buff_Drumfire',
        "ZedternalRBPerkpackage_Resources.Sounds.Shapeshifter_Buff_Drumfire_Cue");
    RegisterSound(Mutator, 'Shapeshifter_Buff_Phantom',
        "ZedternalRBPerkpackage_Resources.Sounds.Shapeshifter_Buff_Phantom_Cue");

    // ===================================================================
    // SHAPESHIFTER - Mimicry Sounds (3)
    // ===================================================================

    RegisterSound(Mutator, 'Shapeshifter_Mimicry_Activate',
        "ZedternalRBPerkpackage_Resources.Sounds.Shapeshifter_Mimicry_Activate_Cue");
    RegisterSound(Mutator, 'Shapeshifter_Mimicry_Stack',
        "ZedternalRBPerkpackage_Resources.Sounds.Shapeshifter_Mimicry_Stack_Cue");
    RegisterSound(Mutator, 'Shapeshifter_Mimicry_Complete',
        "ZedternalRBPerkpackage_Resources.Sounds.Shapeshifter_Mimicry_Complete_Cue");

    // ===================================================================
    // PREDATOR - Trophy Sounds (5)
    // ===================================================================

    RegisterSound(Mutator, 'Predator_Trophy_Drop',
        "ZedternalRBPerkpackage_Resources.Sounds.Predator_Trophy_Drop_Cue");
    RegisterSound(Mutator, 'Predator_Trophy_Collect',
        "ZedternalRBPerkpackage_Resources.Sounds.Predator_Trophy_Collect_Cue");
    RegisterSound(Mutator, 'Predator_Set_Complete',
        "ZedternalRBPerkpackage_Resources.Sounds.Predator_Set_Complete_Cue");
    RegisterSound(Mutator, 'Predator_Tier3_Complete',
        "ZedternalRBPerkpackage_Resources.Sounds.Predator_Tier3_Complete_Cue");
    RegisterSound(Mutator, 'Predator_Legendary',
        "ZedternalRBPerkpackage_Resources.Sounds.Predator_Legendary_Cue");

    // ===================================================================
    // HOLLOW - Condition & Unlock Sounds (2)
    // ===================================================================

    // Condition complete (one of 3 trial conditions satisfied)
    RegisterSound(Mutator, 'Hollow_Condition_Complete',
        "ZedternalRBPerkpackage_Resources.Sounds.Hollow_Condition_Complete_Cue");

    // Weapon fully unlocked (all 3 conditions met, Hollow variant available)
    RegisterSound(Mutator, 'Hollow_Weapon_Unlock',
        "ZedternalRBPerkpackage_Resources.Sounds.Hollow_Weapon_Unlock_Cue");

    // ===================================================================
    // OMEN - Prophecy Sounds (4)
    // ===================================================================

    // Prophecy reveal (wave start, new prophecy drawn)
    RegisterSound(Mutator, 'Omen_Prophecy_Reveal',
        "ZedternalRBPerkpackage_Resources.Sounds.Omen_Prophecy_Reveal_Cue");

    // Blessing complete (prophecy fulfilled successfully)
    RegisterSound(Mutator, 'Omen_Blessing_Complete',
        "ZedternalRBPerkpackage_Resources.Sounds.Omen_Blessing_Complete_Cue");

    // Doom activate (prophecy failed, ZedBuff punishment applied)
    RegisterSound(Mutator, 'Omen_Doom_Activate',
        "ZedternalRBPerkpackage_Resources.Sounds.Omen_Doom_Activate_Cue");

    // Deny Fate (Level 20 ability, negates doom every 5 waves)
    RegisterSound(Mutator, 'Omen_Deny_Fate',
        "ZedternalRBPerkpackage_Resources.Sounds.Omen_Deny_Fate_Cue");

    // Metronome - Phase rotation perk
    RegisterSound(Mutator, 'Metronome_PhaseShift',
        "ZedternalRBPerkpackage_Resources.Sounds.Metronome_PhaseShift_Cue");
    RegisterSound(Mutator, 'Metronome_SyncKill',
        "ZedternalRBPerkpackage_Resources.Sounds.Metronome_SyncKill_Cue");
    RegisterSound(Mutator, 'Metronome_Crescendo',
        "ZedternalRBPerkpackage_Resources.Sounds.Metronome_Crescendo_Cue");

    // Detonator - Charge/detonate perk
    RegisterSound(Mutator, 'Detonator_WindowStart',
        "ZedternalRBPerkpackage_Resources.Sounds.Detonator_WindowStart_Cue");
    RegisterSound(Mutator, 'Detonator_WindowEnd',
        "ZedternalRBPerkpackage_Resources.Sounds.Detonator_WindowEnd_Cue");

    // ===================================================================
    // EVENT WAVE ANNOUNCEMENT SOUNDS (22)
    // Each plays once when the event wave begins
    // ===================================================================

    RegisterSound(Mutator, 'EventWave_Isolation',
        "ZedternalRBPerkpackage_Resources.Sounds.EventWave_Isolation_Cue");
    RegisterSound(Mutator, 'EventWave_BlackoutPulse',
        "ZedternalRBPerkpackage_Resources.Sounds.EventWave_BlackoutPulse_Cue");
    RegisterSound(Mutator, 'EventWave_VIP',
        "ZedternalRBPerkpackage_Resources.Sounds.EventWave_VIP_Cue");
    RegisterSound(Mutator, 'EventWave_HotPotato',
        "ZedternalRBPerkpackage_Resources.Sounds.EventWave_HotPotato_Cue");
    RegisterSound(Mutator, 'EventWave_DeadSilence',
        "ZedternalRBPerkpackage_Resources.Sounds.EventWave_DeadSilence_Cue");
    RegisterSound(Mutator, 'EventWave_Highlander',
        "ZedternalRBPerkpackage_Resources.Sounds.EventWave_Highlander_Cue");
    RegisterSound(Mutator, 'EventWave_RAGE',
        "ZedternalRBPerkpackage_Resources.Sounds.EventWave_RAGE_Cue");
    RegisterSound(Mutator, 'EventWave_Amogus',
        "ZedternalRBPerkpackage_Resources.Sounds.EventWave_Amogus_Cue");
    RegisterSound(Mutator, 'EventWave_ChainGang',
        "ZedternalRBPerkpackage_Resources.Sounds.EventWave_ChainGang_Cue");
    RegisterSound(Mutator, 'EventWave_OneInTheChamber',
        "ZedternalRBPerkpackage_Resources.Sounds.EventWave_OneInTheChamber_Cue");
    RegisterSound(Mutator, 'EventWave_Paranoia',
        "ZedternalRBPerkpackage_Resources.Sounds.EventWave_Paranoia_Cue");
    RegisterSound(Mutator, 'EventWave_MarkedForDeath',
        "ZedternalRBPerkpackage_Resources.Sounds.EventWave_MarkedForDeath_Cue");
    RegisterSound(Mutator, 'EventWave_Redacted',
        "ZedternalRBPerkpackage_Resources.Sounds.EventWave_Redacted_Cue");
    RegisterSound(Mutator, 'EventWave_FogOfWar',
        "ZedternalRBPerkpackage_Resources.Sounds.EventWave_FogOfWar_Cue");
    RegisterSound(Mutator, 'EventWave_Nemesis',
        "ZedternalRBPerkpackage_Resources.Sounds.EventWave_Nemesis_Cue");
    RegisterSound(Mutator, 'EventWave_Duel',
        "ZedternalRBPerkpackage_Resources.Sounds.EventWave_Duel_Cue");
    RegisterSound(Mutator, 'EventWave_XMen',
        "ZedternalRBPerkpackage_Resources.Sounds.EventWave_XMen_Cue");
    RegisterSound(Mutator, 'EventWave_Jitterbug',
        "ZedternalRBPerkpackage_Resources.Sounds.EventWave_Jitterbug_Cue");
    RegisterSound(Mutator, 'EventWave_CostumeParty',
        "ZedternalRBPerkpackage_Resources.Sounds.EventWave_CostumeParty_Cue");
    RegisterSound(Mutator, 'EventWave_DontBlink',
        "ZedternalRBPerkpackage_Resources.Sounds.EventWave_DontBlink_Cue");
    RegisterSound(Mutator, 'EventWave_PassTheBomb',
        "ZedternalRBPerkpackage_Resources.Sounds.EventWave_PassTheBomb_Cue");
    RegisterSound(Mutator, 'EventWave_RedLightGreenLight',
        "ZedternalRBPerkpackage_Resources.Sounds.EventWave_RedLightGreenLight_Cue");
    RegisterSound(Mutator, 'EventWave_FloorIsLava',
        "ZedternalRBPerkpackage_Resources.Sounds.EventWave_FloorIsLava_Cue");
    RegisterSound(Mutator, 'EventWave_BodyguardBond',
        "ZedternalRBPerkpackage_Resources.Sounds.EventWave_BodyguardBond_Cue");
    RegisterSound(Mutator, 'EventWave_BountyBoard',
        "ZedternalRBPerkpackage_Resources.Sounds.EventWave_BountyBoard_Cue");
    RegisterSound(Mutator, 'EventWave_GoldenZedRelay',
        "ZedternalRBPerkpackage_Resources.Sounds.EventWave_GoldenZedRelay_Cue");

    // ===================================================================
    // MINIGAME EVENT WAVES - in-event gameplay sounds (batch 27-32)
    // ===================================================================
    // Pass The Bomb
    RegisterSound(Mutator, 'EventBomb_Transfer',
        "ZedternalRBPerkpackage_Resources.Sounds.EventBomb_Transfer_Cue");
    RegisterSound(Mutator, 'EventBomb_Explode',
        "ZedternalRBPerkpackage_Resources.Sounds.EventBomb_Explode_Cue");
    // Red Light Green Light
    RegisterSound(Mutator, 'EventRLGL_Warning',
        "ZedternalRBPerkpackage_Resources.Sounds.EventRLGL_Warning_Cue");
    RegisterSound(Mutator, 'EventRLGL_Red',
        "ZedternalRBPerkpackage_Resources.Sounds.EventRLGL_Red_Cue");
    RegisterSound(Mutator, 'EventRLGL_Green',
        "ZedternalRBPerkpackage_Resources.Sounds.EventRLGL_Green_Cue");
    // The Floor Is Lava
    RegisterSound(Mutator, 'EventLava_Move',
        "ZedternalRBPerkpackage_Resources.Sounds.EventLava_Move_Cue");
    // Bounty Board
    RegisterSound(Mutator, 'EventBounty_Complete',
        "ZedternalRBPerkpackage_Resources.Sounds.EventBounty_Complete_Cue");
    // Golden Zed Relay
    RegisterSound(Mutator, 'EventGolden_Spawn',
        "ZedternalRBPerkpackage_Resources.Sounds.EventGolden_Spawn_Cue");
    RegisterSound(Mutator, 'EventGolden_Collected',
        "ZedternalRBPerkpackage_Resources.Sounds.EventGolden_Collected_Cue");

    // ===================================================================
    // MISSINGNO - Glitch Perk Sounds (3)
    // ===================================================================

    // DATA MISSING - fatal-hit survive proc activation (Lv 20)
    RegisterSound(Mutator, 'MissingNO_DataMissing',
        "ZedternalRBPerkpackage_Resources.Sounds.MissingNO_DataMissing_Cue");

    // Item Duplication - successful wave-end weapon dup (Lv 20)
    RegisterSound(Mutator, 'MissingNO_Duplicate',
        "ZedternalRBPerkpackage_Resources.Sounds.MissingNO_Duplicate_Cue");

    // Type Mismatch - new elemental rotation rolled (Lv 10+, every wave)
    RegisterSound(Mutator, 'MissingNO_TypeRoll',
        "ZedternalRBPerkpackage_Resources.Sounds.MissingNO_TypeRoll_Cue");

    // ===================================================================
    // JEKYLL & HYDE - Serum Sounds (2)
    // ===================================================================

    // Serum activation (Jekyll -> Hyde transform)
    RegisterSound(Mutator, 'Hyde_Activate',
        "ZedternalRBPerkpackage_Resources.Sounds.Hyde_Activate_Cue");

    // Hyde form expiry (Hyde -> Jekyll revert)
    RegisterSound(Mutator, 'Hyde_Deactivate',
        "ZedternalRBPerkpackage_Resources.Sounds.Hyde_Deactivate_Cue");

    // ===================================================================
    // DOMAIN - "Room" perk sounds (7)
    // ===================================================================

    // Room cast / deploy
    RegisterSound(Mutator, 'Domain_Activate',
        "ZedternalRBPerkpackage_Resources.Sounds.Domain_Activate_Cue");

    // Wheel abilities
    RegisterSound(Mutator, 'Domain_Shift',
        "ZedternalRBPerkpackage_Resources.Sounds.Domain_Shift_Cue");
    RegisterSound(Mutator, 'Domain_Sever',
        "ZedternalRBPerkpackage_Resources.Sounds.Domain_Sever_Cue");
    RegisterSound(Mutator, 'Domain_Discharge',
        "ZedternalRBPerkpackage_Resources.Sounds.Domain_Discharge_Cue");
    RegisterSound(Mutator, 'Domain_Collapse',
        "ZedternalRBPerkpackage_Resources.Sounds.Domain_Collapse_Cue");

    // Room expired (natural end) and recharge finished
    RegisterSound(Mutator, 'Domain_End',
        "ZedternalRBPerkpackage_Resources.Sounds.Domain_End_Cue");
    RegisterSound(Mutator, 'Domain_Ready',
        "ZedternalRBPerkpackage_Resources.Sounds.Domain_Ready_Cue");

    // Skill-unlocked wheel abilities (6)
    RegisterSound(Mutator, 'Domain_Freeze',
        "ZedternalRBPerkpackage_Resources.Sounds.Domain_Freeze_Cue");
    RegisterSound(Mutator, 'Domain_Shambles',
        "ZedternalRBPerkpackage_Resources.Sounds.Domain_Shambles_Cue");
    RegisterSound(Mutator, 'Domain_Tact',
        "ZedternalRBPerkpackage_Resources.Sounds.Domain_Tact_Cue");
    RegisterSound(Mutator, 'Domain_Injection',
        "ZedternalRBPerkpackage_Resources.Sounds.Domain_Injection_Cue");
    RegisterSound(Mutator, 'Domain_Mes',
        "ZedternalRBPerkpackage_Resources.Sounds.Domain_Mes_Cue");
    RegisterSound(Mutator, 'Domain_Tempest',
        "ZedternalRBPerkpackage_Resources.Sounds.Domain_Tempest_Cue");

    `log("DKSoundManager: Registered" @ Mutator.CustomSounds.Length @ "default sounds");
}

static function RegisterSound(DKMutator Mutator, name SoundID, string CustomPath)
{
    local DKMutator.CustomSoundEntry NewEntry;
    
    NewEntry.SoundID = SoundID;
    NewEntry.SoundCuePath = CustomPath;
    NewEntry.bCustomSoundLoaded = false;
    NewEntry.LoadedSound = None;
    
    Mutator.CustomSounds.AddItem(NewEntry);
}

// ===================================================================
// SOUND LOADING
// ===================================================================

static function LoadCustomSounds(DKMutator Mutator)
{
    local int i;
    local SoundCue LoadedCustomSound;
    
    `log("DKSoundManager: Attempting to load custom sounds...");
    
    for (i = 0; i < Mutator.CustomSounds.Length; i++)
    {
        LoadedCustomSound = SoundCue(DynamicLoadObject(
            Mutator.CustomSounds[i].SoundCuePath,
            class'SoundCue',
            true
        ));
        
        if (LoadedCustomSound != None)
        {
            Mutator.CustomSounds[i].bCustomSoundLoaded = true;
            Mutator.CustomSounds[i].LoadedSound = LoadedCustomSound;
            `log("DKSoundManager: Loaded custom sound:" @ Mutator.CustomSounds[i].SoundID);
        }
        else
        {
            Mutator.CustomSounds[i].bCustomSoundLoaded = false;
            Mutator.CustomSounds[i].LoadedSound = None;
            `log("DKSoundManager: Custom sound not found for" @ Mutator.CustomSounds[i].SoundID);
        }
    }
    
    `log("DKSoundManager: Custom sound loading complete");
}

// ===================================================================
// PUBLIC API - PLAY SOUNDS (Convenience function for helpers)
// ===================================================================

/**
 * PlaySound - Convenience function for playing sounds on a pawn
 * This is the main function helpers should call
 * @param SoundID - The registered sound ID (as string, will be converted to name)
 * @param TargetPawn - The pawn to play the sound on
 */
static function PlaySound(string SoundID, Pawn TargetPawn)
{
    local DKMutator Mutator;
    local SoundCue Sound;
    local name SoundName;
    
    if (TargetPawn == None)
    {
        `log("DKSoundManager::PlaySound - No target pawn!");
        return;
    }
    
    // Get the mutator
    Mutator = GetMutator(TargetPawn.WorldInfo);
    if (Mutator == None)
    {
        `log("DKSoundManager::PlaySound - Could not find DKMutator!");
        return;
    }
    
    // Convert string to name
    SoundName = name(SoundID);
    
    // Get the sound
    Sound = GetSound(Mutator, SoundName);
    if (Sound == None)
    {
        `log("DKSoundManager::PlaySound - Sound not found:" @ SoundID);
        return;
    }
    
    // Play the sound on the pawn
    TargetPawn.PlaySoundBase(Sound, true, true);
}

/**
 * PlaySoundByName - Same as PlaySound but takes a name directly
 */
static function PlaySoundByName(name SoundID, Pawn TargetPawn)
{
    local DKMutator Mutator;
    local SoundCue Sound;
    
    if (TargetPawn == None)
    {
        `log("DKSoundManager::PlaySoundByName - No target pawn!");
        return;
    }
    
    // Get the mutator
    Mutator = GetMutator(TargetPawn.WorldInfo);
    if (Mutator == None)
    {
        `log("DKSoundManager::PlaySoundByName - Could not find DKMutator!");
        return;
    }
    
    // Get the sound
    Sound = GetSound(Mutator, SoundID);
    if (Sound == None)
    {
        `log("DKSoundManager::PlaySoundByName - Sound not found:" @ SoundID);
        return;
    }
    
    // Play the sound on the pawn
    TargetPawn.PlaySoundBase(Sound, true, true);
}

/**
 * GetMutator - Helper to find the DKMutator in the world
 */
static function DKMutator GetMutator(WorldInfo WI)
{
    local Mutator M;
    
    if (WI == None || WI.Game == None)
        return None;
    
    M = WI.Game.BaseMutator;
    while (M != None)
    {
        if (DKMutator(M) != None)
            return DKMutator(M);
        M = M.NextMutator;
    }
    
    return None;
}

// ===================================================================
// PUBLIC API - RETRIEVE SOUNDS
// ===================================================================

static function SoundCue GetSound(DKMutator Mutator, name SoundID)
{
    local int i;
    
    for (i = 0; i < Mutator.CustomSounds.Length; i++)
    {
        if (Mutator.CustomSounds[i].SoundID == SoundID)
        {
            return Mutator.CustomSounds[i].LoadedSound;
        }
    }
    
    `log("DKSoundManager: WARNING - Unregistered sound ID:" @ SoundID);
    return None;
}

static function bool IsCustomSoundLoaded(DKMutator Mutator, name SoundID)
{
    local int i;
    
    for (i = 0; i < Mutator.CustomSounds.Length; i++)
    {
        if (Mutator.CustomSounds[i].SoundID == SoundID)
            return Mutator.CustomSounds[i].bCustomSoundLoaded;
    }
    
    return false;
}

static function string GetSoundInfo(DKMutator Mutator, name SoundID)
{
    local int i;
    local string Info;
    
    for (i = 0; i < Mutator.CustomSounds.Length; i++)
    {
        if (Mutator.CustomSounds[i].SoundID == SoundID)
        {
            Info = "Sound:" @ SoundID;
            Info $= " | Custom:" @ Mutator.CustomSounds[i].SoundCuePath;
            Info $= " | Loaded:" @ (Mutator.CustomSounds[i].bCustomSoundLoaded ? "YES" : "NO");
            return Info;
        }
    }
    
    return "Sound not registered:" @ SoundID;
}

static function LogAllSounds(DKMutator Mutator)
{
    local int i;
    
    `log("===== DKSoundManager: Registered Sounds (Native SoundCue) =====");
    
    for (i = 0; i < Mutator.CustomSounds.Length; i++)
    {
        `log("  [" $ i $ "]" @ Mutator.CustomSounds[i].SoundID 
            @ "| Custom:" @ Mutator.CustomSounds[i].bCustomSoundLoaded 
            @ "| Path:" @ Mutator.CustomSounds[i].SoundCuePath);
    }
    
    `log("==============================================================");
}

// ===================================================================
// RUNTIME SOUND REGISTRATION
// ===================================================================

static function RegisterSoundAtRuntime(DKMutator Mutator, name SoundID, string CustomPath)
{
    local int i;
    local SoundCue LoadedCustomSound;
    local DKMutator.CustomSoundEntry NewEntry;
    
    for (i = 0; i < Mutator.CustomSounds.Length; i++)
    {
        if (Mutator.CustomSounds[i].SoundID == SoundID)
        {
            `log("DKSoundManager: Sound already registered:" @ SoundID);
            return;
        }
    }
    
    NewEntry.SoundID = SoundID;
    NewEntry.SoundCuePath = CustomPath;
    
    LoadedCustomSound = SoundCue(DynamicLoadObject(CustomPath, class'SoundCue', true));
    
    if (LoadedCustomSound != None)
    {
        NewEntry.bCustomSoundLoaded = true;
        NewEntry.LoadedSound = LoadedCustomSound;
        `log("DKSoundManager: Registered custom sound at runtime:" @ SoundID);
    }
    else
    {
        NewEntry.bCustomSoundLoaded = false;
        NewEntry.LoadedSound = None;
        `log("DKSoundManager: Registered runtime sound" @ SoundID @ "(not loaded)");
    }
    
    Mutator.CustomSounds.AddItem(NewEntry);
}

defaultproperties
{
}