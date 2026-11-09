extends Node
# DataLoader: loads every res://data/*.json at boot, validates schema_version, fail-fast.
# GDScript holds no balance numbers; all tuning lives in JSON.

var cache: Dictionary = {}

func _ready() -> void:
	_load_all()

func _load_all() -> void:
	var files: Array[String] = [
		"res://data/player.json",
		"res://data/towers.json",
		"res://data/area.json",
		"res://data/buff.json",
		"res://data/enemies.json",
		"res://data/bullets.json",
		"res://data/wave_table.json",
		"res://data/resources.json",
		"res://data/art_manifest.json",
		"res://data/tower_types.json",
		"res://data/ally_bond.json",
		"res://data/story_chapters.json",
		"res://data/maps.json",
		"res://data/strings.json",
		"res://data/cutscenes/triggers.json",
	]
	for path: String in files:
		_load_one(path)

func _load_one(path: String) -> void:
	if not FileAccess.file_exists(path):
		push_error("DataLoader missing file: " + path)
		return
	var text: String = FileAccess.get_file_as_string(path)
	var parsed: Variant = JSON.parse_string(text)
	if parsed == null or typeof(parsed) != TYPE_DICTIONARY:
		push_error("DataLoader invalid JSON: " + path)
		return
	var dict: Dictionary = parsed as Dictionary
	if not dict.has("schema_version"):
		push_error("DataLoader missing schema_version: " + path)
		return
	var key: String = path.get_file().get_basename()
	# map nested resources/ally ids accessible via get_data("resources")["resources"]["alloy"]
	cache[key] = dict

func get_data(key: String) -> Dictionary:
	if cache.has(key):
		return cache[key] as Dictionary
	push_error("DataLoader no data for key: " + key)
	return {}

func get_nested(key: String, sub: String) -> Dictionary:
	var root: Dictionary = get_data(key)
	if root.has(sub):
		return root[sub] as Dictionary
	return {}
