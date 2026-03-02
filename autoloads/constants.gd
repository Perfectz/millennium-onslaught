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
const PLAYER_BELT_DEPTH_RANGE: float = 2.0
const PLAYER_VARIABLE_JUMP_DAMPEN: float = 0.5
const PLAYER_LAND_RECOVERY_TIME: float = 0.08

# --- Dodge ---
const DODGE_SPEED: float = 14.0
const DODGE_DURATION: float = 0.3
const DODGE_INVINCIBILITY_DURATION: float = 0.25
const DODGE_COOLDOWN: float = 0.5

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
const CAMERA_DEADZONE_Y: float = 1.0
const CAMERA_ZOOM_MIN: float = 0.8
const CAMERA_ZOOM_MAX: float = 1.5

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
const DUNGEON_ROOM_TRANSITION_TIME: float = 1.5
const DUNGEON_ARENA_LOCK_EASE_TIME: float = 0.5

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
const PASSIVE_EFFECT_CAP: float = 0.5
const INN_COST_BASE: int = 50

# --- Player Model ---
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
	"attack_launcher": "res://humandropbox/alys animations/Mma Kick.fbx",
	"hurt": "res://assets/models/characters/alys/hurt.fbx",
	"dead": "res://assets/models/characters/alys/dead.fbx",
	"dodge": "res://assets/models/characters/alys/dodge.fbx",
}

# --- Performance ---
const OBJECT_POOL_ENEMY_COUNT: int = 20
const OBJECT_POOL_PROJECTILE_COUNT: int = 30
const OBJECT_POOL_VFX_COUNT: int = 40
const OBJECT_POOL_DAMAGE_NUMBER_COUNT: int = 20
