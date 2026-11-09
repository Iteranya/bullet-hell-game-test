extends Node2D
# Tower: turret shoots nearest enemy, emits aura. Stats from towers.json (field template only).
# Homebase is not a separate type — instance boolean is_homebase marks invulnerability.
var aura_R: float = 250.0
var hp: float = 300.0
var is_homebase: bool = false
var tower_key: String = "field"
var _fire_timer: float = 0.0

func _ready() -> void:
	add_to_group("towers")
	_apply_data()
	BuffManager.register(self)
	_draw_aura()

func _exit_tree() -> void:
	BuffManager.unregister(self)

func _apply_data() -> void:
	var root: Dictionary = DataLoader.get_data("towers")
	var towers: Dictionary = root.get("towers", {})
	var entry: Dictionary = towers.get(tower_key, towers.get("field", {}))
	hp = float(entry.get("hp", 300.0))
	aura_R = float(entry.get("aura_R", 250.0))
	# is_homebase is set externally by Main (boolean marker). Entry invulnerable is ignored.

func _process(delta: float) -> void:
	_fire_timer -= delta
	var cfg_root: Dictionary = DataLoader.get_data("towers")
	var towers: Dictionary = cfg_root.get("towers", {})
	var entry: Dictionary = towers.get(tower_key, towers.get("field", {}))
	var fire_rate: float = float(entry.get("fire_rate", 2.0))
	if _fire_timer > 0.0:
		return
	var nearest: Node2D = _nearest_enemy()
	if nearest == null:
		return
	_fire_timer = 1.0 / maxf(fire_rate, 0.1)
	var dir: Vector2 = (nearest.global_position - global_position).normalized()
	var dmg: float = float(entry.get("damage", 8.0))
	var btype: String = String(entry.get("bullet_type", "tower_bolt"))
	var main: Node = get_tree().get_first_node_in_group("main")
	if main and main.has_method("spawn_bullet"):
		main.call("spawn_bullet", global_position, dir, dmg, btype, true)

func _nearest_enemy() -> Node2D:
	var best: Node2D = null
	var best_d: float = INF
	for n: Node2D in get_tree().get_nodes_in_group("enemies"):
		var d: float = global_position.distance_to(n.global_position)
		if d < best_d:
			best_d = d
			best = n
	if best_d > aura_R * 1.5:
		return null
	return best

func take_damage(amount: float) -> void:
	if is_homebase:
		return
	hp -= amount
	if hp <= 0.0:
		queue_free()

func _draw_aura() -> void:
	# MVP: translucent circle is drawn by a child Polygon2D created in scene; keep node ref update here.
	var aura: Node = get_node_or_null("Aura")
	if aura and aura.has_method("redraw"):
		aura.call("redraw", aura_R)
