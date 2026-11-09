extends Node2D
# Enemy_Base: chases player/tower, takes bullet damage, drops Alloy.
var enemy_key: String = "chaser"
var hp: float = 20.0
var speed: float = 90.0
var damage: float = 8.0
var _radial_timer: float = 2.0

func _ready() -> void:
	add_to_group("enemies")
	_apply_data()

func _apply_data() -> void:
	var root: Dictionary = DataLoader.get_data("enemies")
	var enemies: Dictionary = root.get("enemies", {})
	var entry: Dictionary = enemies.get(enemy_key, enemies.get("chaser", {}))
	hp = float(entry.get("hp", 20.0))
	speed = float(entry.get("speed", 90.0))
	damage = float(entry.get("damage", 8.0))

func _process(delta: float) -> void:
	var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return
	var dir: Vector2 = (player.global_position - global_position).normalized()
	global_position += dir * speed * delta

func take_damage(amount: float) -> void:
	hp -= amount
	if hp <= 0.0:
		var main: Node = get_tree().get_first_node_in_group("main")
		if main and main.has_method("on_enemy_died"):
			main.call("on_enemy_died", global_position, enemy_key)
		queue_free()
