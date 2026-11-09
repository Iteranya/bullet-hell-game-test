extends Node2D
# Player: WASD move, mouse aim, hold LMB fire. Base stats from player.json, buff from BuffManager.
# No magic numbers: speed/damage/fire_rate from DataLoader.

var _fire_timer: float = 0.0

func _ready() -> void:
	add_to_group("player")

func _process(delta: float) -> void:
	var main: Node = get_tree().get_first_node_in_group("main")
	if main and bool(main.get("placing")):
		return
	var cfg: Dictionary = DataLoader.get_data("player")
	var speed: float = float(cfg.get("speed", 260.0))
	var total_s: float = float(BuffManager.compute_total_s(global_position).get("total_s", 0.0))
	var move_speed: float = speed * (0.6 + 0.6 * total_s)
	var dir: Vector2 = Vector2.ZERO
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		dir.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		dir.x += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		dir.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		dir.y += 1.0
	if dir != Vector2.ZERO:
		dir = dir.normalized()
		global_position += dir * move_speed * delta
	# arena clamp from maps.json
	var maps: Dictionary = DataLoader.get_data("maps")
	var half: float = float(maps.get("arena_size_px", 1600)) * 0.5
	global_position.x = clampf(global_position.x, -half, half)
	global_position.y = clampf(global_position.y, -half, half)

	var fire_rate: float = float(cfg.get("fire_rate", 4.0)) * (0.5 + total_s)
	_fire_timer -= delta
	if (Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and _fire_timer <= 0.0):
		_fire_timer = 1.0 / maxf(fire_rate, 0.1)
		var aim: Vector2 = (get_global_mouse_position() - global_position).normalized()
		var dmg: float = float(cfg.get("damage", 6.0)) * (0.5 + total_s)
		var bullet_type: String = String(cfg.get("bullet_type", "player_bolt"))
		_spawn_bullet(aim, dmg, bullet_type)
	_busy_refit()

func _busy_refit() -> void:
	# ally cosmetic companion count = BuffManager count (no entity, pattern read in bullet spawn)
	pass

func _spawn_bullet(dir: Vector2, damage: float, bullet_type: String) -> void:
	if dir == Vector2.ZERO:
		return
	var main: Node = get_tree().get_first_node_in_group("main")
	if main and main.has_method("spawn_bullet"):
		main.call("spawn_bullet", global_position, dir, damage, bullet_type, true)
