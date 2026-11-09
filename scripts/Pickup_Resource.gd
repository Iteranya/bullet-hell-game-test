extends Node2D
# Pickup_Resource: Alloy shard. Magnet only inside aura (per resources.json).
func _ready() -> void:
	add_to_group("pickups")

func _process(delta: float) -> void:
	var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return
	var res: Dictionary = DataLoader.get_nested("resources", "resources")
	var alloy_cfg: Dictionary = res.get("alloy", {})
	var magnet_r: float = float(alloy_cfg.get("magnet_radius_px", 120.0))
	var total_s: float = float(BuffManager.compute_total_s(player.global_position).get("total_s", 0.0))
	var d: float = global_position.distance_to(player.global_position)
	if total_s > 0.0 and d < magnet_r:
		global_position = global_position.move_toward(player.global_position, 260.0 * delta)
	if d < 12.0:
		GameState.add_alloy(1)
		queue_free()
