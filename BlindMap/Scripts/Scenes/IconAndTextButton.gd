class_name IconAndTextButton extends Control

signal button_clicked()

@export var Style: LevelStyleResource
@export var Icon: Texture2D
@export var Text: String

@onready var ButtonIcon: TextureRect = get_node("%Icon")
@onready var ButtonLabel: Label = get_node("%Label")

func _ready():
	ButtonIcon.texture = Icon
	ButtonLabel.text = tr(Text)
	_adjust_appearance()
	LanguageSwitcher.language_switched.connect(_on_language_switched)


var _is_hover: bool


func _adjust_appearance():
	if _is_hover:
		modulate = Style.HighlightColor
	else:
		modulate = Style.NormalColor


func _on_mouse_entered():
	_is_hover = true
	_adjust_appearance()


func _on_mouse_exited():
	_is_hover = false
	_adjust_appearance()


func _on_gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		button_clicked.emit()
		_is_hover = false
		_adjust_appearance()


func _on_language_switched(_lang: String):
	ButtonLabel.text = tr(Text)
