class_name HintOverlay extends Control

var _hint_nodes = {}
var _current_hint_name = ""

signal hint_closed(hint_name: String)
signal hints_disabled

func _ready():
	_hint_nodes["level_selection"] = get_node("HintLevelSelection")
	_hint_nodes["level_answers"] = get_node("HintAnswers")
	_hint_nodes["next_level"] = get_node("HintNextLevel")
	for hint_node in _hint_nodes.values():
		hint_node.hint_closed.connect(_on_hint_closed)
		hint_node.hints_disabled.connect(_on_hints_disabled)


func show_hint(hint_name: String):
	if _current_hint_name != "":
		hide_hint(_current_hint_name)
	if hint_name in _hint_nodes:
		print("Showing hint: ", hint_name)
		_current_hint_name = hint_name
		var hint_node = _hint_nodes[hint_name]
		visible = true
		hint_node.visible = true


func hide_hint(hint_name: String):
	if hint_name in _hint_nodes:
		print("Hiding hint: ", hint_name)
		_current_hint_name = ""
		var hint_node = _hint_nodes[hint_name]
		visible = false
		hint_node.visible = false


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
