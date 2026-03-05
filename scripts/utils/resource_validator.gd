## Validates .tres resource data against schema rules.
## Catches missing fields, out-of-range values, and broken references.
class_name ResourceValidator
extends RefCounted


## Validation result for a single resource.
class ValidationResult extends RefCounted:
	var resource_path: String = ""
	var errors: Array[String] = []
	var warnings: Array[String] = []
	var is_valid: bool = true

	func add_error(msg: String) -> void:
		errors.append(msg)
		is_valid = false

	func add_warning(msg: String) -> void:
		warnings.append(msg)

	func to_string() -> String:
		var out: String = resource_path + ": "
		if is_valid:
			out += "VALID"
		else:
			out += "INVALID (%d errors)" % errors.size()
		return out


## Schema definition for field validation.
class FieldSchema extends RefCounted:
	var field_name: String = ""
	var field_type: String = ""  # "int", "float", "string", "stringname", "array", "dict"
	var required: bool = true
	var min_value: float = -INF
	var max_value: float = INF
	var min_length: int = 0
	var allowed_values: Array = []

	func _init(name: String = "", type: String = "", req: bool = true) -> void:
		field_name = name
		field_type = type
		required = req


## Validate a dictionary against a list of field schemas.
static func validate_dict(data: Dictionary, schemas: Array[FieldSchema], path: String = "") -> ValidationResult:
	var result := ValidationResult.new()
	result.resource_path = path
	for schema: FieldSchema in schemas:
		if schema.field_name not in data:
			if schema.required:
				result.add_error("Missing required field: '%s'" % schema.field_name)
			continue
		var value = data[schema.field_name]
		_validate_field(value, schema, result)
	return result


## Validate a CharacterDef dictionary.
static func validate_character_def(data: Dictionary, path: String = "") -> ValidationResult:
	var schemas: Array[FieldSchema] = _get_character_schemas()
	return validate_dict(data, schemas, path)


## Validate an EnemyDef dictionary.
static func validate_enemy_def(data: Dictionary, path: String = "") -> ValidationResult:
	var schemas: Array[FieldSchema] = _get_enemy_schemas()
	return validate_dict(data, schemas, path)


## Validate an AttackDef dictionary.
static func validate_attack_def(data: Dictionary, path: String = "") -> ValidationResult:
	var schemas: Array[FieldSchema] = _get_attack_schemas()
	return validate_dict(data, schemas, path)


static func _validate_field(value: Variant, schema: FieldSchema, result: ValidationResult) -> void:
	match schema.field_type:
		"int":
			if not (value is int):
				result.add_error("Field '%s': expected int, got %s" % [schema.field_name, typeof(value)])
				return
			if value < schema.min_value:
				result.add_error("Field '%s': value %d below minimum %d" % [schema.field_name, value, int(schema.min_value)])
			if value > schema.max_value:
				result.add_error("Field '%s': value %d above maximum %d" % [schema.field_name, value, int(schema.max_value)])
		"float":
			if not (value is float or value is int):
				result.add_error("Field '%s': expected float, got %s" % [schema.field_name, typeof(value)])
				return
			if float(value) < schema.min_value:
				result.add_error("Field '%s': value %f below minimum %f" % [schema.field_name, float(value), schema.min_value])
			if float(value) > schema.max_value:
				result.add_error("Field '%s': value %f above maximum %f" % [schema.field_name, float(value), schema.max_value])
		"string", "stringname":
			if not (value is String or value is StringName):
				result.add_error("Field '%s': expected string, got %s" % [schema.field_name, typeof(value)])
				return
			if schema.min_length > 0 and str(value).length() < schema.min_length:
				result.add_error("Field '%s': string too short (min %d)" % [schema.field_name, schema.min_length])
			if not schema.allowed_values.is_empty() and str(value) not in schema.allowed_values:
				result.add_error("Field '%s': value '%s' not in allowed values" % [schema.field_name, str(value)])
		"array":
			if not (value is Array):
				result.add_error("Field '%s': expected array, got %s" % [schema.field_name, typeof(value)])
				return
			if schema.min_length > 0 and value.size() < schema.min_length:
				result.add_error("Field '%s': array too short (min %d, got %d)" % [schema.field_name, schema.min_length, value.size()])
		"dict":
			if not (value is Dictionary):
				result.add_error("Field '%s': expected dictionary, got %s" % [schema.field_name, typeof(value)])


static func _get_character_schemas() -> Array[FieldSchema]:
	var schemas: Array[FieldSchema] = []
	var id := FieldSchema.new("id", "stringname")
	id.min_length = 1
	schemas.append(id)
	var name_s := FieldSchema.new("display_name", "string")
	name_s.min_length = 1
	schemas.append(name_s)
	var hp := FieldSchema.new("base_hp", "float")
	hp.min_value = 1.0
	hp.max_value = 9999.0
	schemas.append(hp)
	var str_s := FieldSchema.new("base_strength", "int")
	str_s.min_value = 1
	str_s.max_value = 99
	schemas.append(str_s)
	var def_s := FieldSchema.new("base_defense", "int")
	def_s.min_value = 1
	def_s.max_value = 99
	schemas.append(def_s)
	var agi := FieldSchema.new("base_agility", "int")
	agi.min_value = 1
	agi.max_value = 99
	schemas.append(agi)
	var mag := FieldSchema.new("base_magic", "int")
	mag.min_value = 1
	mag.max_value = 99
	schemas.append(mag)
	schemas.append(FieldSchema.new("combo_chain", "array"))
	schemas.append(FieldSchema.new("techniques", "array"))
	return schemas


static func _get_enemy_schemas() -> Array[FieldSchema]:
	var schemas: Array[FieldSchema] = []
	var id := FieldSchema.new("id", "stringname")
	id.min_length = 1
	schemas.append(id)
	var name_s := FieldSchema.new("display_name", "string")
	name_s.min_length = 1
	schemas.append(name_s)
	var hp := FieldSchema.new("hp", "float")
	hp.min_value = 1.0
	hp.max_value = 99999.0
	schemas.append(hp)
	var dmg := FieldSchema.new("damage", "float")
	dmg.min_value = 0.0
	schemas.append(dmg)
	var spd := FieldSchema.new("speed", "float")
	spd.min_value = 0.0
	schemas.append(spd)
	var xp := FieldSchema.new("xp_reward", "int")
	xp.min_value = 0
	schemas.append(xp)
	var ai := FieldSchema.new("ai_type", "stringname")
	ai.min_length = 1
	schemas.append(ai)
	return schemas


static func _get_attack_schemas() -> Array[FieldSchema]:
	var schemas: Array[FieldSchema] = []
	var id := FieldSchema.new("id", "stringname")
	id.min_length = 1
	schemas.append(id)
	var dmg := FieldSchema.new("base_damage", "float")
	dmg.min_value = 0.0
	schemas.append(dmg)
	var kb := FieldSchema.new("knockback", "float")
	kb.min_value = 0.0
	schemas.append(kb)
	var elem := FieldSchema.new("element", "stringname", false)
	elem.allowed_values = ["physical", "fire", "ice", "lightning", "dark"]
	schemas.append(elem)
	var hitstop := FieldSchema.new("hitstop_duration", "float", false)
	hitstop.min_value = 0.0
	hitstop.max_value = 1.0
	schemas.append(hitstop)
	return schemas
