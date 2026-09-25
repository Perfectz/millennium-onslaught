## Limits how many horde grunts may attack the player at once (the rest circle and posture).
class_name AttackTokenPool
extends RefCounted


var _capacity: int
var _holders: Dictionary = {}


func _init(capacity: int = Constants.HORDE_ATTACK_TOKENS) -> void:
	_capacity = maxi(capacity, 0)


## Try to take a token. Holders asking again keep theirs.
func request(holder_id: int) -> bool:
	if _holders.has(holder_id):
		return true
	if _holders.size() >= _capacity:
		return false
	_holders[holder_id] = true
	return true


## Give a token back. Unknown holders are ignored.
func release(holder_id: int) -> void:
	_holders.erase(holder_id)


## True if the holder currently owns a token.
func has_token(holder_id: int) -> bool:
	return _holders.has(holder_id)


## Change capacity (e.g. from morale). Existing holders keep their tokens.
func set_capacity(capacity: int) -> void:
	_capacity = maxi(capacity, 0)


## Number of tokens currently held.
func get_holder_count() -> int:
	return _holders.size()


## Drop all tokens.
func clear() -> void:
	_holders.clear()
