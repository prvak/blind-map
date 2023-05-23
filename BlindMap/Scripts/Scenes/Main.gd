class_name Main extends Control

var original_size: Vector2 = Vector2(1920, 1080)
var SWAP_SCREEN_DURATION = 0.5

@onready var _menu_node: MainMenu = get_node("MainMenu")
@onready var _level_node: Level = get_node("Level")
@onready var _hint_overlay_node: HintOverlay = get_node("HintOverlay")

enum Screen {MENU, LEVEL}

var _current_screen: Screen = Screen.MENU
var _levels_with_changed_status: Array = []


func _ready():
	HintToggler.register_overlay(_hint_overlay_node)
	LanguageSwitcher.language_switched.connect(_on_language_switched)
	_set_localized_window_title()
	get_viewport().size_changed.connect(func(): _on_resized())
	_on_resized()
	
	_level_node.level_finished.connect(_on_level_finished)
	_level_node.level_quit.connect(_on_level_quit)
	_level_node.level_next.connect(_on_level_next)
	_menu_node.level_clicked.connect(_on_level_button_clicked)
	
	
	if GameData.CurrentLevelId == "":
		_set_screen(Screen.MENU)
	else:
		var last_level_data = _menu_node.get_level_data_by_full_id(GameData.CurrentLevelId)
		if last_level_data:
			_level_node.set_map_texture(last_level_data.MapTexture)
			_set_screen(Screen.LEVEL)
			_level_node.start_level(last_level_data)
		else:
			_set_screen(Screen.MENU)


func _unhandled_input(event):
	if event is InputEventKey:
		if Input.is_action_pressed("toggle_fullscreen"):
			FullscreenToggler.toggle_fullscreen()


func _on_level_finished(level_data: LevelData, level_status: GameData.LevelStatus) -> void:
	if _current_screen != Screen.LEVEL:
		return

	var previous_level_status = GameData.get_level_status(level_data.get_full_id())
	if previous_level_status < level_status:
		GameData.mark_level_status(level_data.get_full_id(), level_status)
		_levels_with_changed_status.append([level_data.get_full_id(), level_status])


func _on_level_quit(_level_data: LevelData) -> void:
	if _current_screen != Screen.LEVEL:
		return

	_level_node.clear()
	GameData.CurrentLevelId = ""
	GameData.save_data()
	_transition_to_screen(Screen.MENU)


func _on_level_next(level_data: LevelData) -> void:
	if _current_screen != Screen.LEVEL:
		return

	var next_level_data = level_data.LevelSequence.get_next_level_data(level_data.LevelDescription.Id)
	if next_level_data != null:
		GameData.CurrentLevelId = next_level_data.get_full_id()
	else:
		GameData.CurrentLevelId = ""
	GameData.save_data()

	if next_level_data != null:
		HintToggler.request_hint("next_level")
		await HintToggler.await_current_hint_closed()
		_level_node.start_level(next_level_data)
	else:
		_level_node.clear()
		_transition_to_screen(Screen.MENU)


func _on_language_switched(_lang: String):
	_set_localized_window_title()


func _set_localized_window_title():
	var localized_names = ProjectSettings.get_setting("application/config/name_localized")
	if LanguageSwitcher.CurrentLanguage in localized_names:
		get_window().title = localized_names[LanguageSwitcher.CurrentLanguage]
	else:
		get_window().title = ProjectSettings.get_setting("application/config/name")


func _on_resized():
	var new_size = get_viewport_rect().size
	var x_scale = new_size.x / original_size.x
	var y_scale = new_size.y / original_size.y
	var current_scale = min(x_scale, y_scale)
	scale.x = current_scale
	scale.y = current_scale


func _on_level_button_clicked(full_level_id: String):
	if _current_screen != Screen.MENU:
		return

	var level_data = _menu_node.get_level_data_by_full_id(full_level_id)
	if level_data == null:
		return
	
	_level_node.set_map_texture(level_data.MapTexture)
	_level_node.clear()
	_levels_with_changed_status.clear()
	await _transition_to_screen(Screen.LEVEL)
	_level_node.start_level(level_data)
	_menu_node.reset_level_button_hover(full_level_id)


func _set_screen(target: Screen):
	_current_screen = target

	if target == Screen.MENU:
		_level_node.position.y = -original_size.y
		_level_node.visible = false
		_level_node.modulate.a = 0
		_menu_node.position.y = 0
		_menu_node.visible = true
		_menu_node.modulate.a = 1
		HintToggler.request_hint("level_selection")
	elif target == Screen.LEVEL:
		_level_node.position.y = 0
		_level_node.visible = true
		_level_node.modulate.a = 1
		_menu_node.position.y = original_size.y
		_menu_node.visible = false
		_menu_node.modulate.a = 0


func _transition_to_screen(target: Screen):
	if target == _current_screen:
		return

	_current_screen = target
	var tween = get_tree().create_tween()
	if target == Screen.MENU:
		_menu_node.visible = true
		tween.tween_property(_level_node, "position:y", -original_size.y, SWAP_SCREEN_DURATION)
		tween.parallel().tween_property(_menu_node, "position:y", 0, SWAP_SCREEN_DURATION)
		tween.parallel().tween_property(_menu_node, "modulate:a", 1, SWAP_SCREEN_DURATION)
		tween.parallel().tween_property(_level_node, "modulate:a", 0, SWAP_SCREEN_DURATION)
		await tween.finished
		_menu_node.update_level_statuses(_levels_with_changed_status)
		_level_node.visible = false
		HintToggler.request_hint("level_selection")
	elif target == Screen.LEVEL:
		_level_node.visible = true
		tween.tween_property(_level_node, "position:y", 0, SWAP_SCREEN_DURATION)
		tween.parallel().tween_property(_menu_node, "position:y", original_size.y, SWAP_SCREEN_DURATION)
		tween.parallel().tween_property(_menu_node, "modulate:a", 0, SWAP_SCREEN_DURATION)
		tween.parallel().tween_property(_level_node, "modulate:a", 1, SWAP_SCREEN_DURATION)
		await tween.finished
		_menu_node.visible = false

		
