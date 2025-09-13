local SOUNDS = {  }
SOUNDS.BGM = {  }
SOUNDS.SFX = {  }
local Array = require("utils.classes.array")
local BGM = struct("source", "origVolume")
local unusedSounds = Array.EMPTY
if DebugOptions.REPORT_UNUSED_SOUNDS then
    unusedSounds = Array:Convert(filesystem.getDirectoryItems("sfx"))
end

local function loadBGM(filename, volume, pitch)
    local bgm = audio.newSource("bgm/" .. filename .. "", "stream")
    bgm:setLooping(true)
    bgm:setPitch(pitch or 1)
    return BGM:new(bgm, volume or 1)
end

local SFX = struct("source", "origVolume", "origPitch")
local function loadSFX(filename, volume, pitch, isLooping)
    local source
    if isLooping then
        source = audio.newSource("sfx/" .. filename, "stream")
        source:setLooping(true)
    else
        source = audio.newSource("sfx/" .. filename, "static")
        source:setLooping(false)
    end

    if DebugOptions.REPORT_UNUSED_SOUNDS then
        unusedSounds:delete(filename)
    end

    return SFX:new(source, volume or 1, pitch or 1)
end

local function loadStinger(filename, volume)
    local source = audio.newSource("bgm/" .. filename .. "", "stream")
    source:setLooping(false)
    source:setPitch(pitch or 1)
    if DebugOptions.REPORT_UNUSED_SOUNDS then
        unusedSounds:delete(filename)
    end

    return BGM:new(source, volume or 1)
end

function SOUNDS.load()
    audio.setVolume(1)
    local BGM, SFX = SOUNDS.BGM, SOUNDS.SFX
    BGM.INTRO = loadBGM("title_a8_labyrinth_of_legendary_loot.mp3", 1, 1)
    BGM.DUNGEON_1 = loadBGM("track_1_a5_the_first_passage.mp3", 1, 1)
    BGM.DUNGEON_2 = loadBGM("track_2_a2.mp3", 1, 1)
    BGM.DUNGEON_3 = loadBGM("track_3_a1.mp3", 1, 1)
    BGM.DUNGEON_4 = loadBGM("track_4_a3_strike_with_the_legendary_blade.mp3", 1, 1)
    BGM.DUNGEON_5 = loadBGM("track_5_a4_sleepless_shadows.mp3", 1, 1)
    BGM.DUNGEON_6 = loadBGM("track_6_a6_deepest_darkness.mp3", 1, 1)
    BGM.LAST_BOSS = loadBGM("track_7_a7_giant_beast.mp3", 0.95, 1)
    BGM.VICTORY = loadStinger("a9_reached_the_end.mp3", 1, 1)
    BGM.DEFEAT = loadStinger("brpg_defeat_stinger.mp3", 1, 1)
    SFX.EQUIP = loadSFX("dd_equip.wav", 1.5, 1.0)
    SFX.ANVIL = loadSFX("dd_anvil.wav", 0.7, 1)
    SFX.SALVAGE = loadSFX("dd_salvage.wav", 0.8, 1)
    SFX.CONFIRM = loadSFX("dd_confirm.wav", 0.75, 1)
    SFX.CANCEL = loadSFX("dd_cancel.wav", 0.8, 1.0)
    SFX.CURSOR = loadSFX("dd_cursor.wav", 0.8, 1.0)
    SFX.AMBIENT_FIRE = loadSFX("spell_fire_loop.mp3", 1, 1, true)
    SFX.SLOT_ALERT = loadSFX("dd_slot_alert_2.wav", 0.0, 1.6)
    SFX.ORB_DROP = loadSFX("dd_orb_drop.wav", 1, 1)
    SFX.SLIME_LAND = loadSFX("button2.mp3", 1, 1.5)
    SFX.VENOM_SPIT = loadSFX("dd_venom_spit.wav", 0.7, 2)
    SFX.CAST_CANCEL = loadSFX("dd_cast_cancel.wav", 0.6, 1.0)
    SFX.GENERIC_HIT = loadSFX("dd_generic_hit.wav", 1, 1.1)
    SFX.HIT_BLOCKED = loadSFX("punch_general_body_impact_01.wav", 0.5, 1.4)
    SFX.WHOOSH = loadSFX("dd_whoosh.wav", 0.8, 1)
    SFX.WHOOSH_MAGIC = loadSFX("dd_whoosh_magic.wav", 1, 1.8)
    SFX.WHOOSH_BIG = loadSFX("whoosh_slow_deep_01.wav", 1., 1.55)
    SFX.THROW = loadSFX("dd_throw.wav", 0.4, 1.0)
    SFX.WHIRLWIND = loadSFX("dd_whirlwind_2.wav", 0.8, 1.1, true)
    SFX.DASH = loadSFX("dash_whoosh_magic_spell_03.wav", 1, 1.5)
    SFX.DASH_SHORT = loadSFX("whoosh_swish_small_harsh_03.wav", 0.8, 1.5)
    SFX.EXPLOSION_MEDIUM = loadSFX("dd_explosion_medium_edit.wav", 1.0, 0.9)
    SFX.EXPLOSION_ICE = loadSFX("dd_ice_explosion.wav", 1.0, 1.6)
    SFX.EXPLOSION_SMALL = loadSFX("dd_explosion_small.wav", 0.4, 0.9)
    SFX.EXPLOSION_POISON = loadSFX("dd_explosion_poison.wav", 1, 0.75)
    SFX.ROCK_SHAKE = loadSFX("rock_impact_heavy_slam_02.wav", 0.8, 1)
    SFX.BLIZZARD = loadSFX("dd_blizzard.wav", 0.9, 0.8)
    SFX.BURN_DAMAGE = loadSFX("dragon_step_1.mp3", 0.65, 1.5)
    SFX.POISON_DAMAGE = loadSFX("venom_dps.mp3", 0.8, 1.2)
    SFX.ICE_DAMAGE = loadSFX("ice_spell_freeze_small_01.wav", 0.4, 1)
    SFX.LIGHTNING = loadSFX("electric_lightning_blast_01.wav", 0.42, 1.0)
    SFX.LIGHTNING_LOOP = loadSFX("dd_lightning_loop.wav", 0.6, 1.4, true)
    SFX.GRAVITY = loadSFX("dd_gravity.wav", 0.3, 1.5, true)
    SFX.DOOM = loadSFX("dd_doom.wav", 0.6, 1.1)
    SFX.HEAL = loadSFX("mana_potion_1.mp3", 1.0, 1.0)
    SFX.AFFLICT = loadSFX("afflict.wav", 1.0, 1.0)
    SFX.BEAM = loadSFX("dd_beam.wav", 0.6, 1.0)
    SFX.TIME_STOP = loadSFX("dd_time_stop.wav", 1.0, 1.0)
    SFX.TIME_STOP_LOOP = loadSFX("sfx_clock_timer_10s_02.wav", 1.0, 0.9, true)
    SFX.BOW_SHOOT = loadSFX("dd_bow_shoot.wav", 1, 1)
    SFX.SPIN = loadSFX("dd_cleave.wav", 0.9, 1.0)
    SFX.CLEAVE = loadSFX("dd_cleave_2.wav", 0.8, 1.0)
    SFX.BITE = loadSFX("beast_4.mp3", 1, 1)
    SFX.PEST_BITE = loadSFX("insect_attack_1.wav", 1, 1)
    SFX.WEAPON_CHARGE = loadSFX("raise3.wav", 0.9, 1.0)
    SFX.ENCHANT = loadSFX("dd_enchant.wav", 0.8, 1.4)
    SFX.CAST_CHARGE = loadSFX("dd_cast_charge.wav", 1, 0.7)
    SFX.GLOW_MODAL = loadSFX("dd_glow_modal.wav", 0.5, 1.1)
    SFX.DRAIN = loadSFX("dd_drain.wav", 1, 1.9, true)
    SFX.TELEPORT = loadSFX("dd_teleport.wav", 0.55, 1.4)
    SFX.BOSS_KILLING_HIT = loadSFX("dd_boss_killing_hit_2.wav", 1, 1)
    SFX.BOSS_DEATH_EXPLOSION = loadSFX("dd_boss_death_explosion.wav", 1, 0.8)
    if DebugOptions.REPORT_UNUSED_SOUNDS then
        Debugger.log("Unused Sounds: ", unusedSounds)
    end

    SOUNDS.load = doNothing
end

return SOUNDS

