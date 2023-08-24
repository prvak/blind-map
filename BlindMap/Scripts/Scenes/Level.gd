class_name Level extends Control

@export var LearnLevelAnswers: int = 5
@export var TestLevelAnswers: int = 1

@export var GoldTrophyTexture: Texture2D
@export var SilverTrophyTexture: Texture2D
@export var BronzeTrophyTexture: Texture2D

@export var LevelStyle: LevelStyleResource

var _level_data: LevelData
var _quitting: bool
var _correct_answers: int
var _wrong_answers: int
var _wrong_answers_since_last_correct_answer: int


signal level_finished(level_data: LevelData, correct_answers: int, wrong_answers: int)
signal level_quit(level_data: LevelData)
signal level_next(level_data: LevelData)


@onready var map_node: Map = get_node("Map")
@onready var answers_node: Answers = get_node("MarginContainer/Navigation/Answers")
@onready var level_number_node: Label = get_node("MarginContainer/Navigation/LevelLabel")
@onready var _trophy_animation_player: AnimationPlayer = get_node("%TrophyAnimationPlayer")
@onready var _trophy_scene_container: Container = get_node("%TrophySceneContainer")
@onready var _trophy_icon_container: Container = get_node("%TrophyIconContainer")
@onready var _trophy_buttons_container: Container = get_node("%TrophyButtonsContainer")
@onready var _trophy_sprite: Sprite2D = get_node("%TrophySprite")
@onready var _trophy_panel: Panel = get_node("%TrophyPanel")
@onready var _percents_node: Label = get_node("%PercentsLabel")

func _ready():
	map_node.MapClickableGroup.item_clicked.connect(_on_map_item_clicked)
	answers_node.AnswersSelectionGroup.item_selected.connect(_on_answer_item_selected)


func set_map_texture(map_texture: Texture2D):
	map_node.set_map_texture(map_texture)


func clear():
	_quitting = true
	answers_node.stop_animation()
	map_node.stop_animation()
	answers_node.clear()
	map_node.clear()
	_hide_trophy_container()


func start_level(level_data: LevelData):
	_hide_trophy_container(true)
	_level_data = level_data
	_correct_answers = 0
	_wrong_answers = 0
	_wrong_answers_since_last_correct_answer = 0
	_quitting = false
	var visible_answers = level_data.LevelDescription.VisibleAnswers
	level_number_node.text = level_data.LevelDescription.Name
	answers_node.hide_records()
	answers_node.AnswersSelectionGroup.clear_selection()
	await map_node.display_records(level_data.OldMapRecords, level_data.NewMapRecords)
	if _quitting: return
	level_data.AnswerRecords.shuffle()
	await answers_node.display_records(level_data.AnswerRecords, visible_answers)
	
	answers_node.select_first_answer()
	HintToggler.request_hint("level_answers")


func _hide_trophy_container(immediately: bool = true):
	if immediately:
		_trophy_scene_container.visible = false
		_trophy_sprite.scale = Vector2.ZERO
		_trophy_icon_container.modulate.a = 1
		_trophy_panel.modulate.a = 0
		_trophy_buttons_container.modulate.a = 0
		_trophy_animation_player.seek(0, true)
	else:
		var tween = create_tween()
		tween.tween_property(_trophy_buttons_container, "modulate:a", 0, 0.2)
		tween.tween_property(_trophy_icon_container, "modulate:a", 0, 0.2)
		tween.tween_property(_trophy_panel, "modulate:a", 0, 0.2)
		tween.tween_callback(_hide_trophy_container.bind(true))


func _on_answer_item_selected(_item):
	answers_node.clear_errors()
	map_node.clear_errors()


func _on_map_item_clicked(item):
	answers_node.clear_errors()
	map_node.clear_errors()
	var answer_selection = answers_node.AnswersSelectionGroup.get_selected_item()
	if answer_selection == null:
		return
	if not _level_data.LevelDescription.KeepLearningHintsVisible:
		map_node.clear_labels()
		map_node.clear_correct_answers()
	if item.ItemRecord.Id == answer_selection.ItemRecord.Id:
		_correct_answers += 1
		_wrong_answers_since_last_correct_answer = 0
		item.set_disabled(true)
		answer_selection.set_disabled(true)
		answers_node.AnswersSelectionGroup.mark_unselected(answer_selection)
		if answers_node.is_finished():
			map_node.MapClickableGroup.disable()

			# Report level status.
			var level_status = GameData.LevelStatus.INITIAL
			if _level_data.LevelDescription.Type == LevelSequenceResource.LevelDescription.LevelType.TEST:
				if _wrong_answers == 0:
					level_status = GameData.LevelStatus.TROPHY_GOLD
					_trophy_sprite.texture = GoldTrophyTexture
				elif _wrong_answers == 1 or _wrong_answers < _correct_answers / 10.0:
					level_status = GameData.LevelStatus.TROPHY_SILVER
					_trophy_sprite.texture = SilverTrophyTexture
				else:
					level_status = GameData.LevelStatus.TROPHY_BRONZE
					_trophy_sprite.texture = BronzeTrophyTexture
			else:
				if _wrong_answers > 0:
					level_status = GameData.LevelStatus.FINISHED_WITH_ERRORS
				elif _correct_answers > 0:
					level_status = GameData.LevelStatus.FINISHED
			level_finished.emit(_level_data, level_status)
			
			# Play level finish animation.
			var tween = create_tween()
			tween.tween_interval(item.SuccessDisplayDuration)
			if _level_data.LevelDescription.Type == LevelSequenceResource.LevelDescription.LevelType.TEST:
				tween.tween_callback(func (): _trophy_scene_container.visible = true)
				tween.tween_property(_trophy_panel, "modulate:a", 1, 0.2)
				tween.tween_property(_trophy_sprite, "scale", Vector2.ONE, 0.5)
				tween.tween_callback(_trophy_animation_player.play.bind("Glint"))
				tween.tween_interval(0.2)
				tween.tween_property(_trophy_buttons_container, "modulate:a", 1, 0.2)
				var percents = floor(100.0 * _correct_answers / (_wrong_answers + _correct_answers))
				_percents_node.text = "%d%%" % percents
				if percents >= 100:
					_percents_node.add_theme_color_override("font_color", LevelStyle.SuccessColor)
				else:
					_percents_node.add_theme_color_override("font_color", LevelStyle.FailureColor)
			else:	
				tween.tween_callback(func (): level_next.emit(_level_data))
		else:
			answers_node.select_first_answer()
			answers_node.update_visible_answers()
	else:
		_wrong_answers += 1
		_wrong_answers_since_last_correct_answer += 1
		item.set_error(true)
		item.set_label_visible(true)
		answer_selection.set_error(true)
		if _wrong_answers_since_last_correct_answer >= 5:
			HintToggler.request_hint("give_up")
 

func _on_home_button_pressed():
	_hide_trophy_container(false)
	level_quit.emit(_level_data)


func _on_give_up_button_pressed():
	var answer_selection = answers_node.AnswersSelectionGroup.get_selected_item()
	if answer_selection == null:
		return
	map_node.highlight_item(answer_selection.ItemRecord)
	_wrong_answers += 10 # Penalty for revealing the correct answer.


func _on_replay_button_button_clicked():
	_hide_trophy_container(false)
	start_level(_level_data)


func _on_next_level_button_button_clicked():
	_hide_trophy_container(false)
	level_next.emit(_level_data)


