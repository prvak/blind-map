extends Node


signal fullscreen_toggled


var _last_window_mode
var _current_window_mode

func _ready():
	_last_window_mode = DisplayServer.window_get_mode()


func toggle_fullscreen():
	var current_mode = DisplayServer.window_get_mode()
	if current_mode == DisplayServer.WINDOW_MODE_FULLSCREEN:
		_current_window_mode = _last_window_mode
		DisplayServer.window_set_mode(_last_window_mode)
	else:
		_last_window_mode = current_mode
		_current_window_mode = DisplayServer.WINDOW_MODE_FULLSCREEN
		DisplayServer.window_set_mode(_current_window_mode)
	fullscreen_toggled.emit()


func is_fullscreen():
	return _current_window_mode == DisplayServer.WINDOW_MODE_FULLSCREEN
