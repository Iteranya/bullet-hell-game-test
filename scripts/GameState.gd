extends Node
# GameState: alloy, waves, bond, flags. Read-only PLAYER facts for hikarin conditionals.
signal alloy_changed(value: int)
signal wave_changed(value: int)

var alloy: int = 0
var waves_cleared: int = 0
var towers_built: int = 0
var bond: Dictionary = {}  # ally_id -> int
var flags: Dictionary = {}
var scope_scene: Dictionary = {}
var scope_maid: Dictionary = {}
var scope_world: Dictionary = {}

func _ready() -> void:
	waves_cleared = 0
	towers_built = 0

func add_alloy(amount: int) -> void:
	alloy = maxi(0, alloy + amount)
	alloy_changed.emit(alloy)

func spend_alloy(amount: int) -> bool:
	if alloy < amount:
		return false
	alloy -= amount
	alloy_changed.emit(alloy)
	return true

func set_wave(value: int) -> void:
	waves_cleared = value
	wave_changed.emit(waves_cleared)

func get_bond(ally_id: String) -> int:
	return int(bond.get(ally_id, 0))

func add_bond(ally_id: String, amount: int, cap: int) -> void:
	var cur: int = int(bond.get(ally_id, 0))
	bond[ally_id] = mini(cap, cur + amount)

func get_player_fact(name: String) -> Variant:
	match name:
		"waves_cleared":
			return waves_cleared
		"towers_built":
			return towers_built
		"alloy":
			return alloy
		"isDay":
			return true
		"isNight":
			return false
		_:
			return null
