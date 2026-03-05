## Data definition for a playable character.
## Encapsulates identity, stats, combo chain, techniques, model, and skill tree reference.
class_name CharacterDef
extends Resource


## Unique identifier (e.g., "alys", "chaz", "rune", "wren").
@export var character_id: StringName = &""

## Display name for UI.
@export var display_name: String = ""

## Character role description.
@export var role: String = ""

## Base stats at level 1.
@export var base_stats: Dictionary = {
	"strength": 5,
	"magic": 5,
	"defense": 5,
	"agility": 5,
}

## Light combo chain (3 attacks in sequence).
@export var combo_chain: Array[AttackDef] = []

## Heavy attack definition.
@export var heavy_attack: AttackDef = null

## Launcher attack definition.
@export var launcher_attack: AttackDef = null

## Learnable techniques.
@export var techniques: Array[TechniqueDef] = []

## Skill tree resource path.
@export var skill_tree_id: StringName = &""

## 3D model paths.
@export var model_base_path: String = ""
@export var model_skin_path: String = ""
@export var model_scale: Vector3 = Vector3(1.0, 1.0, 1.0)
@export var model_offset: Vector3 = Vector3(0.0, 0.0, 0.0)
@export var model_rotation_y: float = 90.0
@export var model_animations: Dictionary = {}

## Per-character attack speed multiplier applied on top of PLAYER_ATTACK_SPEED_SCALE.
@export var attack_speed_scale: float = 1.0

## Tint color for placeholder model (until unique models exist).
@export var tint_color: Color = Color.WHITE
