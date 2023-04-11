class_name VectorHashMap extends RefCounted


var _keys := {}
var _values := {}


func set_value(key: Vector2i, value: Variant):
	var string_key: String = _to_string_key(key)
	_keys[string_key] = key
	_values[string_key] = value

func get_value(key: Vector2i) -> Variant:
	var string_key: String = _to_string_key(key)
	if not string_key in _values:
		return null
	return _values[string_key]

func get_any_key() -> Variant:
	if _values.is_empty():
		return null
	return _keys.values()[0]

func contains(key: Vector2i) -> bool:
	var string_key: String = _to_string_key(key)
	return string_key in _values

func remove_key(key: Vector2i):
	var string_key: String = _to_string_key(key)
	if not string_key in _values:
		return
	_keys.erase(string_key)
	_values.erase(string_key)

func is_empty() -> bool:
	return _values.is_empty()

func size() -> int:
	return _values.size()


func _to_string_key(key: Vector2i):
	return "%d:%d" % [key.x, key.y]
