extends Node2D
# Bullet: moves in dir, damages on distance check. Damage/speed from bullets.json.
var vel: Vector2 = Vector2.RIGHT
var damage: float = 6.0
var from_player: bool = true

func setup(pos: Vector2, dir: Vector2, dmg: float, is_player: bool) -> void:
	global_position = pos
	vel = dir.normalized()
	damage = dmg
	from_player = is_player

func _ready() -> void:
	add_to_group("bullets")

func _process(delta: float) -> void:
	global_position += vel * 420.0 * delta
	_check_hits()
	# lifetime: despawn if far from origin
	if global_position.length() > 2000.0:
		queue_free()

func _check_hits() -> void:
	if from_player:
		for e: Node2D in get_tree().get_nodes_in_group("enemies"):
			if global_position.distance_to(e.global_position) < 14.0:
				if e.has_method("take_damage"):
					e.call("take_damage", damage)
				queue_free()
				return
	else:
		var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
		if player != null and global_position.distance_to(player.global_position) < 12.0:
			queue_free()
