## Guards fixed-size world labels (damage numbers): Label3D.fixed_size scales with view depth,
## so a label at or behind the camera plane blows up to fill the screen.
class_name WorldLabelPlacement
extends RefCounted


## True if `point` is at least `min_depth` in front of the camera along its view axis.
static func is_placeable(camera_pos: Vector3, camera_forward: Vector3, point: Vector3, min_depth: float) -> bool:
	return (point - camera_pos).dot(camera_forward.normalized()) >= min_depth
