class_name LevelButton extends MarginContainer

enum ButtonMode {SMALL, BIG}

const SMALL_SIZE = Vector2(50, 50)
const BIG_SIZE = Vector2(123, 50)
const STATUS_TRANSITION_DURATION := 0.3

@export var Style: LevelStyleResource
@export var StatusTextureFinished: Texture2D
@export var StatusTextureFinishedWithErrors: Texture2D
@export var StatusTextureTrophy: Texture2D
@export var Mode: ButtonMode :
	get:
		return Mode
	set(value):
		Mode = value
		_adjust_appearance()
@export var Text: String :
	get:
		return Text
	set(value):
		Text = value
		_adjust_appearance()
@export var Status: GameData.LevelStatus = GameData.LevelStatus.INITIAL:
	get:
		return Status
	set(value):
		Status = value
		_adjust_appearance()

signal level_button_clicked(id: String)

var _is_hover: bool
var _level_id: String

@onready var _level_number_node: Label = get_node("MarginContainer/LevelNumberLabel")
@onready var _level_status_node: TextureRect = get_node("MarginContainer/MarginContainer/StatusIcon")
@onready var _size_node: MarginContainer = get_node("MarginContainer")

func _ready():
	_adjust_appearance()


func initialize(level_id: String, text: String, mode: ButtonMode, status: GameData.LevelStatus):
	_level_id = level_id
	Text = text
	Mode = mode
	Status = status
	_adjust_appearance()


func set_hover(value: bool) -> void:
	_is_hover = value
	_adjust_appearance()

	
func transition_status(status: GameData.LevelStatus, tween: Tween):
	var target_color = _status_to_color(status)
	tween.tween_property(self, "modulate", target_color, STATUS_TRANSITION_DURATION)
	tween.tween_callback(func (): self.Status = status)


func _adjust_appearance():
	if _level_number_node == null:
		return

	_level_number_node.text = Text
	match Mode:
		ButtonMode.SMALL:
			_size_node.custom_minimum_size = SMALL_SIZE
		ButtonMode.BIG:
			_size_node.custom_minimum_size = BIG_SIZE

	var target_color = Style.NormalColor
	if _is_hover:
		target_color = Style.HighlightColor
	else:
		target_color = _status_to_color(Status)
		_level_status_node.texture = _status_to_icon(Status)
	modulate = target_color

func _status_to_color(status: GameData.LevelStatus) -> Color:
	match status:
		GameData.LevelStatus.INITIAL:
			return Style.NormalColor
		GameData.LevelStatus.FINISHED_WITH_ERRORS:
			return Style.FailureColor
		GameData.LevelStatus.FINISHED:
			return Style.SuccessColor
		GameData.LevelStatus.TROPHY_BRONZE:
			return Style.BronzeTrophyColor
		GameData.LevelStatus.TROPHY_SILVER:
			return Style.SilverTrophyColor
		GameData.LevelStatus.TROPHY_GOLD:
			return Style.GoldTrophyColor
	return Style.NormalColor


func _status_to_icon(status: GameData.LevelStatus) -> Texture2D:
	match status:
		GameData.LevelStatus.INITIAL:
			return null
		GameData.LevelStatus.FINISHED_WITH_ERRORS:
			return StatusTextureFinishedWithErrors
		GameData.LevelStatus.FINISHED:
			return StatusTextureFinished
		GameData.LevelStatus.TROPHY_BRONZE:
			return StatusTextureTrophy
		GameData.LevelStatus.TROPHY_SILVER:
			return StatusTextureTrophy
		GameData.LevelStatus.TROPHY_GOLD:
			return StatusTextureTrophy
	return null


func _on_mouse_entered():
	_is_hover = true
	_adjust_appearance()


func _on_mouse_exited():
	_is_hover = false
	_adjust_appearance()


func _on_gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		level_button_clicked.emit(_level_id)
