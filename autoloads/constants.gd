## Centralized tunable values. Every gameplay number lives here.
## Zero hardcoded values in gameplay scripts.
class_name ConstantsSingleton
extends Node


# --- Movement ---
const PLAYER_MAX_HP: float = 100.0
const PLAYER_RUN_SPEED: float = 8.0
const INPUT_DEADZONE: float = 0.1
const BELT_DEPTH_DECEL_MULTIPLIER: float = 5.0
const PLAYER_JUMP_VELOCITY: float = 14.0
const PLAYER_GRAVITY: float = 35.0
const PLAYER_FALL_GRAVITY_MULTIPLIER: float = 1.5
const PLAYER_COYOTE_TIME: float = 0.1
const PLAYER_JUMP_BUFFER_TIME: float = 0.12
const PLAYER_BELT_DEPTH_SPEED: float = 3.0
const PLAYER_BELT_DEPTH_RANGE: float = 1.2
const PLAYER_VARIABLE_JUMP_DAMPEN: float = 0.5
const PLAYER_LAND_RECOVERY_TIME: float = 0.08

# --- Dodge ---
const DODGE_SPEED: float = 14.0
const DODGE_DURATION: float = 0.3
const DODGE_INVINCIBILITY_DURATION: float = 0.25
const DODGE_COOLDOWN: float = 0.5

# --- Input Buffering ---
const ACTION_BUFFER_WINDOW: float = 0.133
const DODGE_BUFFER_WINDOW: float = 0.133
const TECHNIQUE_BUFFER_WINDOW: float = 0.5

# --- Combat ---
const PLAYER_COMBO_MAX_STEPS: int = 3
const HITBOX_X_OFFSET: float = 1.5
const LIGHT_ATTACK_DAMAGE: float = 10.0
const HEAVY_ATTACK_DAMAGE: float = 25.0
const PLAYER_HIT_STUN_DURATION: float = 0.3
const KNOCKBACK_FRICTION: float = 20.0
const HITSTOP_LIGHT_DURATION: float = 0.08
const HITSTOP_HEAVY_DURATION: float = 0.14
const HITSTOP_KILL_DURATION: float = 0.22
const COMBO_INPUT_WINDOW: float = 0.4
const KNOCKBACK_LIGHT: float = 5.0
const KNOCKBACK_HEAVY: float = 8.0
const Z_HIT_TOLERANCE: float = 2.0
const PLAYER_ATTACK_SPEED_SCALE: float = 1.8
const PLAYER_ATTACK_LUNGE_SPEED: float = 4.0
const PLAYER_EDGE_KNOCKBACK_SAFE_MARGIN: float = 1.2
const PLAYER_EDGE_KNOCKBACK_MIN_SCALE: float = 0.0
const ROOM_BOUNDS_INNER_PADDING: float = 0.4

# --- Juggle ---
const MAX_JUGGLE_COUNT: int = 5
const JUGGLE_LAUNCH_VELOCITY: float = 12.0
const JUGGLE_GRAVITY_MULTIPLIER: float = 0.8

# --- Block & Parry ---
const BLOCK_DAMAGE_REDUCTION: float = 0.9
const PARRY_WINDOW: float = 0.15
const PARRY_STUN_DURATION: float = 0.5

# --- Camera ---
const CAMERA_SHAKE_LIGHT: float = 0.4
const CAMERA_SHAKE_HEAVY: float = 0.8
const CAMERA_SHAKE_KILL: float = 1.2
const CAMERA_SHAKE_DURATION: float = 0.3
const CAMERA_FOLLOW_SMOOTHING: float = 5.0
const CAMERA_DEADZONE_X: float = 1.5
const CAMERA_DEADZONE_Y: float = 1.0
const CAMERA_ZOOM_MIN: float = 0.8
const CAMERA_ZOOM_MAX: float = 1.5
const CAMERA_SPRING_STIFFNESS: float = 120.0
const CAMERA_SPRING_DAMPING: float = 22.0
const CAMERA_TRAUMA_DECAY_RATE: float = 2.5
const CAMERA_MAX_SHAKE_OFFSET: float = 0.15
const CAMERA_MAX_SHAKE_ROLL: float = 0.02
const CAMERA_BREATH_AMPLITUDE: float = 0.012
const CAMERA_BREATH_SPEED: float = 1.8
const CAMERA_LOOK_AHEAD_STRENGTH: float = 2.5
const CAMERA_LOOK_AHEAD_SMOOTHING: float = 3.0
const CAMERA_THREAT_BIAS_STRENGTH: float = 0.3
const CAMERA_THREAT_BIAS_SMOOTHING: float = 2.0
const CAMERA_VELOCITY_CAP: float = 30.0
const CAMERA_FOV_ZOOM_SPEED: float = 2.0
const CAMERA_DIRECTOR_EASE_TIME: float = 0.6

# --- Enemy AI ---
const ENEMY_HIT_STUN_DURATION: float = 0.7
const ENEMY_KNOCKBACK_FRICTION: float = 14.0
const ENEMY_POST_HURT_COOLDOWN: float = 0.8
const ENEMY_Z_DEADZONE: float = 0.2
const ENEMY_Z_SPEED_RATIO: float = 0.5
const ENEMY_SHIELD_BLOCK_RANGE_MULT: float = 2.0
const ENEMY_RUSHER_HP: float = 50.0
const ENEMY_PERCEPTION_DELAY: float = 0.3
const ENEMY_ATTACK_TOKEN_COUNT: int = 2
const ENEMY_ATTACK_COOLDOWN: float = 1.5
const ENEMY_RUSHER_SPEED: float = 4.0
const ENEMY_RUSHER_ATTACK_RANGE: float = 1.5

# --- Enemy: Ranged ---
const ENEMY_RANGED_HP: float = 35.0
const ENEMY_RANGED_SPEED: float = 3.0
const ENEMY_RANGED_ATTACK_RANGE: float = 8.0
const ENEMY_RANGED_PREFERRED_DISTANCE: float = 6.0
const ENEMY_RANGED_RETREAT_DISTANCE: float = 3.0
const ENEMY_RANGED_PERCEPTION_DELAY: float = 0.4
const ENEMY_RANGED_ATTACK_COOLDOWN: float = 2.0
const ENEMY_PROJECTILE_SPEED: float = 10.0
const ENEMY_PROJECTILE_DAMAGE: float = 8.0
const ENEMY_PROJECTILE_LIFETIME: float = 3.0

# --- Enemy: Shield ---
const ENEMY_SHIELD_HP: float = 70.0
const ENEMY_SHIELD_SPEED: float = 3.0
const ENEMY_SHIELD_ATTACK_RANGE: float = 1.8
const ENEMY_SHIELD_PERCEPTION_DELAY: float = 0.2
const ENEMY_SHIELD_ATTACK_COOLDOWN: float = 2.0
const ENEMY_SHIELD_BLOCK_REDUCTION: float = 0.9
const ENEMY_SHIELD_STAGGER_HITS: int = 3
const ENEMY_SHIELD_STAGGER_DURATION: float = 1.5

# --- Boss ---
const BOSS_HP: float = 300.0
const BOSS_SPEED: float = 5.0
const BOSS_ATTACK_RANGE: float = 2.0
const BOSS_PHASE_2_HP_THRESHOLD: float = 0.5
const BOSS_ENRAGE_SPEED_MULT: float = 1.5
const BOSS_ENRAGE_DAMAGE_MULT: float = 1.3

# --- Dungeon ---
const DUNGEON_WAVE_SPAWN_DELAY: float = 1.0
const WAVE_BREATHER_DURATION: float = 2.2
const DUNGEON_ROOM_TRANSITION_TIME: float = 1.5
const DUNGEON_ARENA_LOCK_EASE_TIME: float = 0.5

# --- Stage ---
const STAGE_CHUNK_WIDTH: float = 24.0
const STAGE_FORWARD_BUFFER: float = 8.0
const STAGE_TRIGGER_BOX_WIDTH: float = 2.0
const STAGE_TRIGGER_BOX_HEIGHT: float = 8.0
const STAGE_TRIGGER_BOX_DEPTH: float = 8.0
const STAGE_SPAWN_OFFSET_X: float = 2.0

# --- Throwable ---
const THROWABLE_INTERACT_RANGE: float = 2.0
const THROWABLE_SPEED: float = 15.0
const THROWABLE_DAMAGE: float = 30.0
const THROWABLE_LIFETIME: float = 2.0
const THROWABLE_KNOCKBACK: float = 12.0
const THROWABLE_HITSTOP: float = 0.12

# --- Hazards ---
const HAZARD_FIRE_DAMAGE: float = 5.0
const HAZARD_FIRE_TICK_INTERVAL: float = 0.5
const HAZARD_SPIKE_DAMAGE: float = 25.0
const HAZARD_KNOCKBACK_FORCE: float = 10.0

# --- HUD ---
const HUD_COMBO_DISPLAY_TIME: float = 2.0
const HUD_DAMAGE_NUMBER_RISE_SPEED: float = 60.0
const HUD_DAMAGE_NUMBER_LIFETIME: float = 0.8
const HUD_HP_BAR_LERP_SPEED: float = 5.0

# --- VFX ---
const HIT_PARTICLE_COUNT: int = 8
const DEATH_PARTICLE_COUNT: int = 16
const SCREEN_FLASH_DURATION: float = 0.05

# --- Physics ---
const WORLD_GRAVITY: float = 35.0
const DELTA_CAP: float = 0.1
const TERMINAL_VELOCITY: float = 50.0

# --- Collision Layers ---
const LAYER_ENVIRONMENT: int = 1
const LAYER_PLAYER: int = 2
const LAYER_ENEMY: int = 4
const LAYER_PLAYER_HITBOX: int = 8
const LAYER_ENEMY_HITBOX: int = 16
const LAYER_PLAYER_HURTBOX: int = 32
const LAYER_ENEMY_HURTBOX: int = 64
const LAYER_PLATFORM: int = 128

# --- TP (Technique Points) ---
const TP_MAX: float = 100.0
const TP_REGEN_RATE: float = 6.0
const TP_COMBO_FINISHER_BONUS: float = 15.0
const PLAYER_KILL_HEAL: float = 5.0
const TP_PARRY_BONUS: float = 10.0

# --- Player Projectile ---
const PLAYER_PROJECTILE_SPEED: float = 18.0
const PLAYER_PROJECTILE_DAMAGE: float = 20.0
const PLAYER_PROJECTILE_LIFETIME: float = 2.5
const PLAYER_PROJECTILE_KNOCKBACK: float = 10.0
const PLAYER_PROJECTILE_TP_COST: float = 25.0
const PLAYER_PROJECTILE_HITSTOP: float = 0.1

# --- RPG ---
const XP_BASE_PER_KILL: int = 10
const LEVEL_XP_BASE: int = 100
const LEVEL_XP_GROWTH_RATE: float = 1.5
const STAT_POINTS_PER_LEVEL: int = 3
const SKILL_POINTS_PER_LEVEL: int = 1

## Base stat growth per level-up, keyed by character id.
## Each stat increases by the listed amount automatically on every level-up.
const CHARACTER_STAT_GROWTH: Dictionary = {
	&"alys":  {&"strength": 2, &"magic": 1, &"defense": 1, &"agility": 2},
	&"chaz":  {&"strength": 3, &"magic": 0, &"defense": 2, &"agility": 1},
	&"rune":  {&"strength": 0, &"magic": 3, &"defense": 1, &"agility": 2},
	&"wren":  {&"strength": 2, &"magic": 0, &"defense": 3, &"agility": 1},
}
## Fallback growth for characters not in the table.
const DEFAULT_STAT_GROWTH: Dictionary = {&"strength": 1, &"magic": 1, &"defense": 1, &"agility": 1}
const PASSIVE_EFFECT_CAP: float = 0.5
const INN_COST_BASE: int = 50
const NEW_GAME_STARTING_GOLD: int = 100
const ENEMY_GOLD_BASE: int = 5

# --- Stat Scaling ---
const STRENGTH_DAMAGE_SCALE: float = 0.5
const MAGIC_DAMAGE_SCALE: float = 0.7
const DEFENSE_REDUCTION_SCALE: float = 0.3
const AGILITY_SPEED_SCALE: float = 0.02
const STAT_HP_SCALE: float = 5.0

# --- Elemental System ---
const ELEMENT_WEAKNESS_MULTIPLIER: float = 1.5
const ELEMENT_RESISTANCE_MULTIPLIER: float = 0.5
const BURN_DAMAGE_PER_SECOND: float = 3.0
const FREEZE_SPEED_REDUCTION: float = 0.5
const BLEED_DAMAGE_MULTIPLIER: float = 1.25
const SHOCK_CHAIN_RADIUS: float = 3.0
const SHOCK_CHAIN_DAMAGE_RATIO: float = 0.3

# --- Character Switching ---
const CHARACTER_SWITCH_COOLDOWN: float = 1.0
const CHARACTER_SWITCH_INVINCIBILITY: float = 0.5

# --- Scene Paths ---
const SCENE_MAIN_MENU: String = "res://scenes/ui/main_menu.tscn"
const SCENE_OVERWORLD: String = "res://scenes/overworld/overworld.tscn"
const SCENE_TOWN: String = "res://scenes/town/town.tscn"
const SCENE_DUNGEON: String = "res://scenes/dungeon/dungeon_run.tscn"
const SCENE_SPLASH: String = "res://scenes/ui/splash_screen.tscn"
const SCENE_TITLE: String = "res://scenes/ui/title_screen.tscn"
const SCENE_CUTSCENE: String = "res://scenes/ui/cutscene_player.tscn"

# --- Juice & Polish ---
const JUICE_SLOW_MO_SCALE: float = 0.15
const JUICE_SLOW_MO_RESTORE_TIME: float = 0.25
const JUICE_FLASH_ALPHA: float = 0.2
const JUICE_FLASH_DURATION: float = 0.06
const JUICE_VIGNETTE_INTENSITY: float = 0.45
const JUICE_VIGNETTE_DURATION: float = 0.4
const TOAST_LIFETIME: float = 2.5
const TOAST_MAX_VISIBLE: int = 4
const DISSOLVE_DEATH_DURATION: float = 1.2
const SPLASH_HOLD_TIME: float = 2.0

# --- Overworld Node Data ---
const OVERWORLD_NODES: Array[String] = [
	"res://resources/story/node_piata.tres",
	"res://resources/story/node_dungeon_1.tres",
	"res://resources/story/node_birth_valley.tres",
	"res://resources/story/node_zema.tres",
]

# --- Town Data ---
const TOWN_DATA: Dictionary = {
	"piata": "res://resources/towns/piata.tres",
}

# --- Player Model ---

# --- Character Definitions ---
const CHARACTER_DEFS: Dictionary = {
	&"alys": "res://resources/characters/alys.tres",
	&"chaz": "res://resources/characters/chaz.tres",
	&"rune": "res://resources/characters/rune.tres",
	&"wren": "res://resources/characters/wren.tres",
}

const CHARACTER_DISPLAY_NAMES: Dictionary = {
	&"alys": "Alys Landale",
	&"chaz": "Chaz Ashley",
	&"rune": "Rune Walsh",
	&"wren": "Wren",
}

const CHARACTER_ROLES: Dictionary = {
	&"alys": "Hunter",
	&"chaz": "Warrior",
	&"rune": "Mage",
	&"wren": "Android",
}

const PLAYER_MODEL_BASE_PATH: String = "res://assets/models/characters/alys/idle.fbx"
const PLAYER_MODEL_SKIN_PATH: String = "res://assets/models/characters/alys/alys_texture_0.png"
const PLAYER_MODEL_SCALE: Vector3 = Vector3(1.0, 1.0, 1.0)
const PLAYER_MODEL_OFFSET: Vector3 = Vector3(0.0, 0.0, 0.0)
const PLAYER_MODEL_ROTATION_Y: float = 90.0
const PLAYER_MODEL_ANIMATIONS: Dictionary = {
	"idle": "res://assets/models/characters/alys/idle.fbx",
	"run": "res://assets/models/characters/alys/run.fbx",
	"jump": "res://assets/models/characters/alys/jump.fbx",
	"attack_light_1": "res://assets/models/characters/alys/attack_light_1.fbx",
	"attack_light_2": "res://assets/models/characters/alys/attack_light_2.fbx",
	"attack_light_3": "res://assets/models/characters/alys/attack_light_3.fbx",
	"attack_heavy": "res://assets/models/characters/alys/attack_heavy.fbx",
	"attack_launcher": "res://assets/models/characters/alys/attack_launcher.fbx",
	"hurt": "res://assets/models/characters/alys/hurt.fbx",
	"dead": "res://assets/models/characters/alys/dead.fbx",
	"dodge": "res://assets/models/characters/alys/dodge.fbx",
}

# --- Enemy Model ---
const ENEMY_MODEL_BASE_PATH: String = "res://assets/models/enemies/xanafalgue/xanafalgue_rigged.fbx"
const ENEMY_MODEL_SKIN_PATH: String = "res://assets/models/enemies/xanafalgue/Meshy_AI_xanafalgue_0302021559_texture.png"
const ENEMY_MODEL_SCALE: Vector3 = Vector3(1.0, 1.0, 1.0)
const ENEMY_MODEL_OFFSET: Vector3 = Vector3(0.0, 0.0, 0.0)
const ENEMY_MODEL_ROTATION_Y: float = 90.0
const ENEMY_MODEL_ANIMATIONS: Dictionary = {
	"idle": "res://assets/models/enemies/xanafalgue/idle.fbx",
	"run": "res://assets/models/enemies/xanafalgue/run.fbx",
	"walk": "res://assets/models/enemies/xanafalgue/walk.fbx",
	"attack": "res://assets/models/enemies/xanafalgue/attack.fbx",
	"bite": "res://assets/models/enemies/xanafalgue/bite.fbx",
	"hurt": "res://assets/models/enemies/xanafalgue/hurt.fbx",
	"dead": "res://assets/models/enemies/xanafalgue/dead.fbx",
}

# --- Hit Lag ---
const HIT_LAG_DURATION: float = 0.06
const HIT_LAG_HEAVY_DURATION: float = 0.1

# --- Dodge Flash ---
const DODGE_FLASH_INTERVAL: float = 0.04

# --- Dust Particles ---
const DUST_RUN_INTERVAL: float = 0.15
const DUST_LAND_AMOUNT: int = 6
const DUST_RUN_AMOUNT: int = 3

# --- Enemy Corpse ---
const ENEMY_CORPSE_LINGER_TIME: float = 1.5
const ENEMY_CORPSE_FADE_TIME: float = 0.5

# --- Audio Settings ---
const AUDIO_SETTINGS_PATH: String = "user://audio_settings.cfg"

# --- Display Settings ---
const DISPLAY_SETTINGS_PATH: String = "user://display_settings.cfg"
const SFX_POOL_SIZE: int = 12

# --- Combat Audio (dB offsets — hierarchy: Tier A > B > C) ---
const SFX_VOL_HIT_LIGHT: float = 0.0
const SFX_VOL_HIT_HEAVY: float = 2.0
const SFX_VOL_HIT_LAUNCHER: float = 1.0
const SFX_VOL_HIT_BODY: float = -4.0
const SFX_VOL_PLAYER_HURT: float = 1.0
const SFX_VOL_PARRY: float = 3.0
const SFX_VOL_BLOCK: float = 2.0
const SFX_VOL_KILL: float = 2.0
const SFX_VOL_WHIFF_LIGHT: float = -6.0
const SFX_VOL_WHIFF_HEAVY: float = -3.0
const SFX_VOL_DODGE: float = -3.0
const SFX_VOL_KNOCKDOWN: float = -2.0
const SFX_VOL_FOOTSTEP: float = -12.0
const SFX_VOL_JUMP: float = -6.0
const SFX_VOL_LAND: float = -6.0
const SFX_VOL_UI_CLICK: float = -6.0
const SFX_VOL_UI_CONFIRM: float = -6.0
const SFX_VOL_UI_DENY: float = -6.0

# --- Combo Milestone ---
const COMBO_MILESTONE_INTERVAL: int = 5

# --- Damage Number Pool ---
const DAMAGE_NUMBER_POOL_SIZE: int = 20

# --- Spells (Right Stick) ---
const SPELL_STICK_DEADZONE: float = 0.6
const SPELL_BUFFER_WINDOW: float = 0.5
const SPELL_FIREBALL_TP_COST: float = 30.0
const SPELL_FIREBALL_DAMAGE: float = 8.0
const SPELL_FIREBALL_SPEED: float = 20.0
const SPELL_FIREBALL_BURN_DURATION: float = 5.0
const SPELL_FIREBALL_BURN_CHANCE: float = 1.0
const SPELL_HEAL_TP_COST: float = 35.0
const SPELL_HEAL_AMOUNT: float = 30.0
const SPELL_BURST_TP_COST: float = 40.0
const SPELL_BURST_DAMAGE: float = 20.0
const SPELL_BURST_RADIUS: float = 4.0
const SPELL_BARRIER_TP_COST: float = 25.0
const SPELL_BARRIER_DEFENSE_BONUS: float = 10.0
const SPELL_BARRIER_DURATION: float = 8.0
const SPELL_WINDUP_TIME: float = 0.15
const SPELL_RECOVERY_TIME: float = 0.3

# --- Save System ---
const SAVE_VERSION: int = 1

# --- Keyboard Bindings ---
const KEYBOARD_BINDINGS_PATH: String = "user://keyboard_bindings.cfg"

# --- Touch Controls ---
const TOUCH_JOYSTICK_SIZE: float = 200.0
const TOUCH_JOYSTICK_DEADZONE: float = 0.15
const TOUCH_BUTTON_SIZE: float = 80.0
const TOUCH_BUTTON_SMALL_SIZE: float = 60.0
const TOUCH_OPACITY_ACTIVE: float = 0.8
const TOUCH_OPACITY_IDLE: float = 0.4
const TOUCH_LAYER: int = 50

# --- Performance ---
const OBJECT_POOL_ENEMY_COUNT: int = 20
const OBJECT_POOL_PROJECTILE_COUNT: int = 30
const OBJECT_POOL_VFX_COUNT: int = 40
const OBJECT_POOL_DAMAGE_NUMBER_COUNT: int = 20
