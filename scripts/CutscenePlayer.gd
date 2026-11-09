extends CanvasLayer
# CutscenePlayer: minimal hikarin compiled-JSON runtime (MVP: texts + sprite only).
# Input: res://data/cutscenes/*.json per FORMAT.md (meta,label,modify_background,show_sprite,dialogue,remove_sprite,finish_dialogue)
# No branching in MVP.

var _actions: Array = []
var _id_to_idx: Dictionary = {}
var _label_to_idx: Dictionary = {}
var _idx: int = 0
var _playing: bool = false

var _ui: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 10
	visible = false
	_build_ui()

func _build_ui() -> void:
	var bg: ColorRect = ColorRect.new()
	bg.name = "BG"
	bg.color = Color(0.12, 0.12, 0.18, 1.0)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	var portrait: ColorRect = ColorRect.new()
	portrait.name = "Portrait"
	portrait.color = Color(0.9, 0.7, 0.2, 1.0)
	portrait.position = Vector2(96, 120)
	portrait.size = Vector2(160, 220)
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(portrait)
	var speaker: Label = Label.new()
	speaker.name = "Speaker"
	speaker.position = Vector2(96, 400)
	speaker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(speaker)
	var body: Label = Label.new()
	body.name = "Body"
	body.position = Vector2(96, 430)
	body.size = Vector2(1000, 80)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(body)
	_ui["bg"] = bg
	_ui["portrait"] = portrait
	_ui["speaker"] = speaker
	_ui["body"] = body

func play(script_path: String, start_label: String = "start") -> void:
	if not FileAccess.file_exists(script_path):
		push_error("CutscenePlayer missing: " + script_path)
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(script_path))
	if parsed == null or typeof(parsed) != TYPE_ARRAY:
		push_error("CutscenePlayer bad JSON: " + script_path)
		return
	_actions = parsed as Array
	_id_to_idx.clear()
	_label_to_idx.clear()
	for i: int in _actions.size():
		var a: Dictionary = _actions[i] as Dictionary
		_id_to_idx[int(a.get("id", i))] = i
		if String(a.get("type", "")) == "label":
			_label_to_idx[String(a.get("label", ""))] = i
	_idx = 0
	if _label_to_idx.has(start_label):
		_idx = int(_label_to_idx[start_label])
	_playing = true
	visible = true
	get_tree().paused = true
	_apply_current()

func _input(event: InputEvent) -> void:
	if not _playing:
		return
	if event is InputEventMouseButton and (event as InputEventMouseButton).pressed and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		_advance()
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and (event as InputEventKey).pressed and not (event as InputEventKey).echo and ((event as InputEventKey).keycode == KEY_SPACE or (event as InputEventKey).keycode == KEY_ENTER):
		_advance()
		get_viewport().set_input_as_handled()

func _advance() -> void:
	_idx += 1
	if _idx >= _actions.size():
		_finish()
		return
	_apply_current()

func _apply_current() -> void:
	if _idx < 0 or _idx >= _actions.size():
		_finish()
		return
	var a: Dictionary = _actions[_idx] as Dictionary
	var t: String = String(a.get("type", ""))
	match t:
		"meta", "label":
			_advance()
		"modify_background":
			_advance()
		"show_sprite":
			(_ui["portrait"] as ColorRect).color = Color(0.5, 0.9, 1.0, 1.0)
			_advance()
		"remove_sprite":
			(_ui["portrait"] as ColorRect).color = Color(0, 0, 0, 0)
			_advance()
		"dialogue":
			(_ui["speaker"] as Label).text = String(a.get("label", ""))
			(_ui["body"] as Label).text = String(a.get("content", ""))
		"finish_dialogue":
			_finish()
		_:
			_advance()

func _finish() -> void:
	_playing = false
	visible = false
	get_tree().paused = false
