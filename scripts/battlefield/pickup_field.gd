## Pooled item pickups on the battlefield (Monomates dropped by KO'd Bio-monsters, etc.).
## Mates heal on touch (musou "meat bun" style) and stay on the ground if they'd be wasted;
## other items go to the party inventory.
class_name PickupField
extends Node3D


const BOB_HEIGHT: float = 0.15
const BOB_SPEED: float = 3.0
const SPIN_SPEED: float = 2.0
const ORB_HEIGHT: float = 0.6

var player: PlayerController = null

var _free: Array[MeshInstance3D] = []
var _active: Array[MeshInstance3D] = []
var _items: Dictionary = {}  # MeshInstance3D -> {item: ItemDef, age: float}
var _time: float = 0.0
var _mesh := PrismMesh.new()


func _ready() -> void:
	_mesh.size = Vector3(0.35, 0.45, 0.35)
	for i in Constants.PICKUP_POOL_SIZE:
		var orb := MeshInstance3D.new()
		orb.mesh = _mesh
		var mat := StandardMaterial3D.new()
		mat.emission_enabled = true
		mat.emission_energy_multiplier = 1.4
		orb.material_override = mat
		orb.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		orb.visible = false
		add_child(orb)
		_free.append(orb)


## Drop an item at a world position. Returns false if unknown or the pool is full.
func spawn(item_id: StringName, pos: Vector3) -> bool:
	var item := GameState.load_item_def(item_id)
	if item == null or _free.is_empty():
		return false
	var orb: MeshInstance3D = _free.pop_back()
	var mat := orb.material_override as StandardMaterial3D
	mat.albedo_color = item.pickup_color
	mat.emission = item.pickup_color
	orb.position = Vector3(pos.x, ORB_HEIGHT, pos.z)
	orb.visible = true
	_items[orb] = {"item": item, "age": 0.0}
	_active.append(orb)
	return true


## Number of pickups lying on the field.
func get_active_count() -> int:
	return _active.size()


func _process(delta: float) -> void:
	_time += delta
	var has_player := player != null and is_instance_valid(player) and not player.health.is_dead()
	var ppos := player.global_position if has_player else Vector3.ZERO
	for i in range(_active.size() - 1, -1, -1):
		var orb := _active[i]
		var data: Dictionary = _items[orb]
		data["age"] = float(data["age"]) + delta
		if float(data["age"]) >= Constants.PICKUP_LIFETIME:
			_release(i)
			continue
		orb.rotation.y += SPIN_SPEED * delta
		var p := orb.position
		p.y = ORB_HEIGHT + sin(_time * BOB_SPEED + float(i)) * BOB_HEIGHT
		if has_player:
			var flat := Vector2(ppos.x - p.x, ppos.z - p.z)
			var dist := flat.length()
			var item: ItemDef = data["item"]
			var wanted := not item.auto_use_on_pickup or player.health.get_current_hp() < player.health.get_max_hp()
			if wanted and dist <= Constants.PICKUP_COLLECT_RADIUS:
				if _collect(item):
					_release(i)
					continue
			elif wanted and dist <= Constants.PICKUP_MAGNET_RADIUS and dist > 0.001:
				var step := minf(Constants.PICKUP_MAGNET_SPEED * delta, dist)
				p.x += flat.x / dist * step
				p.z += flat.y / dist * step
		orb.position = p


func _collect(item: ItemDef) -> bool:
	if item.auto_use_on_pickup:
		if not player.use_item(item):
			return false
		ToastSystem.show_toast(item.display_name, item.pickup_color)
	else:
		GameState.add_inventory_item({"item_id": item.item_id}, 1)
		ToastSystem.show_toast("Got %s" % item.display_name, item.pickup_color)
	EventBus.rpg_item_picked_up.emit(item.item_id)
	return true


func _release(index: int) -> void:
	var orb := _active[index]
	_active.remove_at(index)
	_items.erase(orb)
	orb.visible = false
	_free.append(orb)
