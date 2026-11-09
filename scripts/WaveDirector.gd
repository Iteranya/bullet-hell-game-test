extends Node
# WaveDirector: spawns waves per wave_table.json, advances waves_cleared.
var _wave: int = 0
var _timer: float = 2.0

func _ready() -> void:
	add_to_group("wave_director")
	_wave = 0
	_spawn_current()

func _process(delta: float) -> void:
	_timer -= delta
	if _timer <= 0.0:
		_timer = 2.0
		# only spawn when few enemies remain to keep pool low
		if get_tree().get_nodes_in_group("enemies").size() <= 2:
			_advance_wave()

func _spawn_current() -> void:
	var root: Dictionary = DataLoader.get_data("wave_table")
	var waves: Array = root.get("waves", [])
	if _wave >= waves.size():
		_wave = waves.size() - 1
	GameState.set_wave(_wave + 1)
	var entry: Dictionary = waves[_wave] as Dictionary
	var main: Node = get_tree().get_first_node_in_group("main")
	if main and main.has_method("spawn_enemy"):
		var chaser: int = int(entry.get("chaser", 0))
		var spinner: int = int(entry.get("spinner", 0))
		for i: int in chaser:
			main.call("spawn_enemy", "chaser")
		for i: int in spinner:
			main.call("spawn_enemy", "spinner")

func _advance_wave() -> void:
	var root: Dictionary = DataLoader.get_data("wave_table")
	var waves: Array = root.get("waves", [])
	if _wave + 1 < waves.size():
		_wave += 1
	else:
		# Endless: loop last wave composition (MVP; data-driven hp_scale ignored for loop).
		_wave = waves.size() - 1
	_spawn_current()
