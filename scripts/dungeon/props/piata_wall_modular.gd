extends Node3D

const PIATA_WALL_MATERIAL := preload("res://assets/materials/stages/piata/piata_wall.tres")

@onready var wall_mesh: MeshInstance3D = $Wall/Wall_Modular

func _ready() -> void:
	wall_mesh.material_override = PIATA_WALL_MATERIAL
