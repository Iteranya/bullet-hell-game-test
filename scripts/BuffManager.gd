extends Node
# BuffManager: registers Towers, computes total_S for a position with resonance stacking.
# All constants from DataLoader buff.json.

var towers: Array = []  # Array of Tower nodes (Node2D with aura_R property)

func _ready() -> void:
	pass

func register(tower: Node2D) -> void:
	if not towers.has(tower):
		towers.append(tower)

func unregister(tower: Node2D) -> void:
	towers.erase(tower)

func _buff_config() -> Dictionary:
	return DataLoader.get_data("buff")

func compute_total_s(pos: Vector2) -> Dictionary:
	var cfg: Dictionary = _buff_config()
	var s_max: float = float(cfg.get("s_max", 1.0))
	var s_min: float = float(cfg.get("s_min", 0.2))
	var resonance_bonus: float = float(cfg.get("resonance_bonus", 0.25))
	var stacking_cap: float = float(cfg.get("stacking_cap", 2.5))
	var raw_sum: float = 0.0
	var count: int = 0
	for tower: Node2D in towers:
		if not is_instance_valid(tower):
			continue
		var aura_r: float = float(tower.get("aura_R"))
		if aura_r <= 0.0:
			continue
		var d: float = pos.distance_to(tower.global_position)
		if d <= aura_r:
			count += 1
			var s: float = s_max * clampf(1.0 - d / aura_r, s_min, 1.0)
			raw_sum += s
	var total: float = raw_sum * (1.0 + resonance_bonus * float(maxi(0, count - 1)))
	total = minf(total, stacking_cap)
	return {"total_s": total, "count": count, "raw_sum": raw_sum}
