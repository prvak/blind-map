extends Node


var _overlay_node: HintOverlay


func _ready():
	pass


func register_overlay(overlay_node: HintOverlay):
	_overlay_node = overlay_node
	_overlay_node.hint_closed.connect(_on_hint_closed)
	_overlay_node.hints_disabled.connect(_on_hints_disabled)


func request_hint(hint_name: String):
	if _overlay_node == null:
		return
	if GameData.HintsDisabled:
		return
	if GameData.is_hint_known(hint_name):
		return
	return _overlay_node.show_hint(hint_name)


func await_current_hint_closed():
	await _overlay_node.await_current_hint_closed()


func _on_hint_closed(hint_name: String):
	GameData.mark_hint_known(hint_name)
	GameData.save_data()


func _on_hints_disabled():
	GameData.HintsDisabled = true
	GameData.save_data()
