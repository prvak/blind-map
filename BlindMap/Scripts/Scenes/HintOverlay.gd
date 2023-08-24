class_name HintOverlay extends Control

var _hint_nodes = {}
var _current_hint_name = ""

signal hint_closed(hint_name: String)
signal hints_disabled

func _ready():
	_hint_nodes["level_selection"] = get_node("HintLevelSelection")
	_hint_nodes["level_answers"] = get_node("HintAnswers")
	_hint_nodes["next_level"] = get_node("HintNextLevel")
	_hint_nodes["give_up"] = get_node("HintGiveUp")
	for hint_node in _hint_nodes.values():
		hint_node.hint_closed.connect(_on_hint_closed)
		hint_node.hints_disabled.connect(_on_hints_disabled)


func show_hint(hint_name: String):
	if _current_hint_name != "":
		hide_hint(_current_hint_name)
	if hint_name in _hint_nodes:
		_current_hint_name = hint_name
		var hint_node = _hint_nodes[hint_name]
		modulate.a = 0
		visible = true
		hint_node.visible = true
		var tween = create_tween()
		tween.tween_property(self, "modulate:a", 1.0, 0.1)


func hide_hint(hint_name: String):
	if hint_name in _hint_nodes:
		_current_hint_name = ""
		var hint_node = _hint_nodes[hint_name]
		var tween = create_tween()
		tween.tween_property(self, "modulate:a", 0.0, 0.1)
		tween.tween_property(self, "visible", false, 0.0)
		tween.tween_property(hint_node, "visible", false, 0.0)


func await_current_hint_closed():
	var hint_name = _current_hint_name
	if hint_name in _hint_nodes:
		print("Waiting for hint: ", hint_name)
		await hint_closed
	

func _on_hint_closed():
	var hint_name = _current_hint_name
	hide_hint(hint_name)
	hint_closed.emit(hint_name)


func _on_hints_disabled():
	var hint_name = _current_hint_name
	hide_hint(hint_name)
	hint_closed.emit(hint_name)
	hints_disabled.emit()


func _on_panel_gui_input(event):
	if not visible:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_hint_closed()
