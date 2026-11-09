extends Node2D
# Main: owns arena, spawns bullets/enemies, places field towers, HUD, cutscene trigger.
var player_scene: PackedScene = preload("res://scenes/Player.tscn")
var tower_scene: PackedScene = preload("res://scenes/Tower.tscn")
var enemy_scene: PackedScene = preload("res://scenes/Enemy.tscn")
var bullet_scene: PackedScene = preload("res://scenes/Bullet.tscn")
var pickup_scene: PackedScene = preload("res://scenes/Pickup_Resource.tscn")
var placing: bool = false
var hud: Label
var ghost: Polygon2D
var _prev_q: bool = false
var _prev_c: bool = false

func _ready() -> void:
	add_to_group("main")
	_make_hud()
	_make_ghost()
	_make_homebase()
	_place_player()
	_make_cutscene()

func _make_ghost() -> void:
	ghost = Polygon2D.new()
	ghost.polygon = PackedVector2Array([Vector2(-16, -16), Vector2(16, -16), Vector2(16, 16), Vector2(-16, 16)])
	ghost.color = Color(0.9, 0.7, 0.2, 0.45)
	ghost.visible = false
	add_child(ghost)

func _make_hud() -> void:
	var layer: CanvasLayer = CanvasLayer.new()
	layer.layer = 5
	add_child(layer)
	hud = Label.new()
	hud.position = Vector2(16, 16)
	hud.name = "HUD"
	layer.add_child(hud)
	_update_hud()

func _next_cost() -> int:
	var area: Dictionary = DataLoader.get_data("area")
	var limits: Dictionary = area.get("limits", {})
	var root: Dictionary = DataLoader.get_data("towers")
	var towers: Dictionary = root.get("towers", {})
	var field: Dictionary = towers.get("field", {})
	var base: int = int(limits.get("base_build_cost", field.get("build_cost", 20)))
	var scale: float = float(limits.get("cost_scale_per_tower", 0.5))
	var towers_count: int = get_tree().get_nodes_in_group("towers").size() - 1
	return int(float(base) * (1.0 + scale * float(maxi(0, towers_count))))

func _update_hud() -> void:
	if hud:
		var cost: int = _next_cost()
		var mode: String = "PLACING" if placing else "mobility"
		hud.text = "Alloy: %d  |  Wave: %d  |  [%s] Q: place (%d)  L/R-click: confirm  Esc: cancel  C: intro" % [GameState.alloy, GameState.waves_cleared, mode, cost]

func _make_homebase() -> void:
	var t: Node2D = tower_scene.instantiate() as Node2D
	t.set("is_homebase", true)
	t.set("tower_key", "field")
	t.global_position = Vector2.ZERO
	add_child(t)

func _place_player() -> void:
	var p: Node2D = player_scene.instantiate() as Node2D
	p.global_position = Vector2(0, 80)
	add_child(p)

func _make_cutscene() -> void:
	var layer: CanvasLayer = CanvasLayer.new()
	layer.name = "CutsceneLayer"
	add_child(layer)
	var script_res: GDScript = load("res://scripts/CutscenePlayer.gd") as GDScript
	var cp: CanvasLayer = CanvasLayer.new()
	cp.set_script(script_res)
	layer.add_child(cp)
	cp.name = "CutscenePlayer"

func _process(_delta: float) -> void:
	_update_hud()
	var q_down: bool = Input.is_key_pressed(KEY_Q)
	if q_down and not _prev_q:
		placing = not placing
	_prev_q = q_down
	var c_down: bool = Input.is_key_pressed(KEY_C)
	if c_down and not _prev_c:
		_play_intro()
	_prev_c = c_down
	if Input.is_key_pressed(KEY_ESCAPE):
		placing = false
	if ghost:
		ghost.visible = placing
		if placing:
			ghost.global_position = get_global_mouse_position()
	var confirm_place: bool = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)
	if confirm_place and placing:
		placing = false
		_try_place()

func _try_place() -> void:
	var cost: int = _next_cost()
	var area: Dictionary = DataLoader.get_data("area")
	var limits: Dictionary = area.get("limits", {})
	var max_range: float = float(limits.get("max_place_range_px", 520))
	var max_towers: int = int(limits.get("max_towers", 6))
	var grid: Dictionary = area.get("grid", {})
	var cell: int = int(grid.get("cell_size_px", 100))
	var cols: int = int(grid.get("cols", 16))
	var rows: int = int(grid.get("rows", 16))
	var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	var pos: Vector2 = get_global_mouse_position()
	if player and pos.distance_to(player.global_position) > max_range:
		return
	if get_tree().get_nodes_in_group("towers").size() >= max_towers:
		return
	var col: int = clampi(int(floor((pos.x + float(cols * cell) * 0.5) / float(cell))), 0, cols - 1)
	var row: int = clampi(int(floor((pos.y + float(rows * cell) * 0.5) / float(cell))), 0, rows - 1)
	var areas: Array = area.get("areas", [])
	for entry in areas:
		var a: Dictionary = entry as Dictionary
		var acol: int = int(a.get("col", 0))
		var arow: int = int(a.get("row", 0))
		var acols: int = int(a.get("cols", 1))
		var arows: int = int(a.get("rows", 1))
		if col >= acol and col < acol + acols and row >= arow and row < arow + arows and not bool(a.get("placeable", true)):
			return
	if GameState.spend_alloy(cost):
		var t: Node2D = tower_scene.instantiate() as Node2D
		t.set("tower_key", "field")
		t.global_position = pos
		add_child(t)
		GameState.towers_built += 1

func _play_intro() -> void:
	var cp: Node = get_node_or_null("CutsceneLayer/CutscenePlayer")
	if cp and cp.has_method("play"):
		cp.call("play", "res://data/cutscenes/towerchain.json", "start")

func spawn_bullet(pos: Vector2, dir: Vector2, dmg: float, _btype: String, from_player: bool) -> void:
	var b: Node2D = bullet_scene.instantiate() as Node2D
	b.global_position = pos
	add_child(b)
	b.call("setup", pos, dir, dmg, from_player)

func spawn_enemy(key: String) -> void:
	var e: Node2D = enemy_scene.instantiate() as Node2D
	e.set("enemy_key", key)
	var maps: Dictionary = DataLoader.get_data("maps")
	var r: float = float(maps.get("spawn_radius_px", 700))
	e.global_position = Vector2(randf_range(-r, r), randf_range(-r, r))
	add_child(e)

func on_enemy_died(pos: Vector2, enemy_key: String) -> void:
	var root: Dictionary = DataLoader.get_data("enemies")
	var enemies: Dictionary = root.get("enemies", {})
	var entry: Dictionary = enemies.get(enemy_key, enemies.get("chaser", {}))
	var drop: Array = entry.get("drop", [1, 1]) as Array
	var n: int = int(drop[0])
	for i: int in n:
		var pk: Node2D = pickup_scene.instantiate() as Node2D
		pk.global_position = pos + Vector2(randf_range(-16, 16), randf_range(-16, 16))
		add_child(pk)
