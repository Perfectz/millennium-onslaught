## Centralized tunable values. Every gameplay number lives here.
## Zero hardcoded values in gameplay scripts.
class_name ConstantsSingleton
extends Node


# --- Movement ---
const PLAYER_RUN_SPEED: float = 8.0
const PLAYER_JUMP_VELOCITY: float = 14.0
const PLAYER_GRAVITY: float = 35.0
const PLAYER_FALL_GRAVITY_MULTIPLIER: float = 1.5
const PLAYER_COYOTE_TIME: float = 0.1
const PLAYER_JUMP_BUFFER_TIME: float = 0.12
const PLAYER_BELT_DEPTH_SPEED: float = 3.0
const PLAYER_BELT_DEPTH_RANGE: float = 2.0
const PLAYER_VARIABLE_JUMP_DAMPEN: float = 0.5

# --- Dodge ---
const DODGE_SPEED: float = 14.0
const DODGE_DURATION: float = 0.3
const DODGE_INVINCIBILITY_DURATION: float = 0.25
const DODGE_COOLDOWN: float = 0.5

# --- Combat ---
const LIGHT_ATTACK_DAMAGE: float = 10.0
const HEAVY_ATTACK_DAMAGE: float = 25.0
const HITSTOP_LIGHT_DURATION: float = 0.05
const HITSTOP_HEAVY_DURATION: float = 0.1
const HITSTOP_KILL_DURATION: float = 0.15
const COMBO_INPUT_WINDOW: float = 0.4
const KNOCKBACK_LIGHT: float = 3.0
const KNOCKBACK_HEAVY: float = 8.0
const Z_HIT_TOLERANCE: float = 1.0

# --- Juggle ---
const MAX_JUGGLE_COUNT: int = 5
const JUGGLE_LAUNCH_VELOCITY: float = 12.0
const JUGGLE_GRAVITY_MULTIPLIER: float = 0.8

# --- Block & Parry ---
const BLOCK_DAMAGE_REDUCTION: float = 0.9
const PARRY_WINDOW: float = 0.15
const PARRY_STUN_DURATION: float = 0.5

# --- Camera ---
const CAMERA_SHAKE_LIGHT: float = 0.2
const CAMERA_SHAKE_HEAVY: float = 0.5
const CAMERA_SHAKE_KILL: float = 0.8
const CAMERA_SHAKE_DURATION: float = 0.2
const CAMERA_FOLLOW_SMOOTHING: float = 5.0
const CAMERA_DEADZONE_Y: float = 1.0
const CAMERA_ZOOM_MIN: float = 0.8
const CAMERA_ZOOM_MAX: float = 1.5

# --- Enemy AI ---
const ENEMY_PERCEPTION_DELAY: float = 0.3
const ENEMY_ATTACK_TOKEN_COUNT: int = 2
const ENEMY_ATTACK_COOLDOWN: float = 1.5
const ENEMY_RUSHER_SPEED: float = 4.0
const ENEMY_RUSHER_ATTACK_RANGE: float = 1.5

# --- VFX ---
const HIT_PARTICLE_COUNT: int = 8
const DEATH_PARTICLE_COUNT: int = 16
const SCREEN_FLASH_DURATION: float = 0.05

# --- Physics ---
const DELTA_CAP: float = 0.1
const TERMINAL_VELOCITY: float = 50.0

# --- TP (Technique Points) ---
const TP_MAX: float = 100.0
const TP_REGEN_RATE: float = 2.0
const TP_COMBO_FINISHER_BONUS: float = 15.0
const TP_PARRY_BONUS: float = 10.0

# --- RPG ---
const XP_BASE_PER_KILL: int = 10
const LEVEL_XP_BASE: int = 100
const LEVEL_XP_GROWTH_RATE: float = 1.5
const STAT_POINTS_PER_LEVEL: int = 3
const PASSIVE_EFFECT_CAP: float = 0.5
const INN_COST_BASE: int = 50

# --- Performance ---
const OBJECT_POOL_ENEMY_COUNT: int = 20
const OBJECT_POOL_PROJECTILE_COUNT: int = 30
const OBJECT_POOL_VFX_COUNT: int = 40
const OBJECT_POOL_DAMAGE_NUMBER_COUNT: int = 20

# --- Frame Budgets ---
const FRAME_BUDGET_SYSTEM_MS: float = 4.0
const FRAME_BUDGET_TOTAL_MS_60FPS: float = 16.67
const FRAME_BUDGET_TOTAL_MS_30FPS: float = 33.33
const STRESS_TEST_ENEMY_COUNT: int = 50
const STRESS_TEST_FRAME_COUNT: int = 300
