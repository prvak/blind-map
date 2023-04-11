class_name AnswerItem extends MarginContainer

@export var Style: LevelStyleResource
@export var StyleTransitionSpeed: float = 0.1
@export var ErrorDisplayDuration: float = 2

var ItemRecord: Record
var CurrentSelectionGroup: SelectionGroup

var _is_hover: bool
var _is_selected: bool
var _is_disabled: bool
var _is_error: bool
var _transition_tween: Tween

@onready var AnswerLabel: Label = get_node("%Label")
@onready var AnswerBorder: NinePatchRect = get_node("%Border")
@onready var SelectionIndicator: TextureRect = get_node("%SelectionIndicator")


func _ready():
	if ItemRecord != null:
		AnswerLabel.text = ItemRecord.get_localized_name(LanguageSwitcher.CurrentLanguage)
	_transition_style(true)


func initialize(record: Record, selection_group: SelectionGroup):
	ItemRecord = record
	CurrentSelectionGroup = selection_group


func set_selected(value: bool) -> void:
	_is_selected = value
	_transition_style()


func set_disabled(value: bool) -> void:
	_is_disabled = value
	_transition_style()


func set_error(value: bool) -> void:
	_is_error = value
	_transition_style()
	if (value):
		var tween = create_tween()
		tween.tween_interval(ErrorDisplayDuration)
		tween.tween_callback(set_error.bind(false))


func is_disabled() -> bool:
	return _is_disabled


func _on_mouse_entered():
	if _is_disabled: return
	_is_hover = true
	_transition_style()


func _on_mouse_exited():
	if _is_disabled: return
	_is_hover = false
	_transition_style()


func _on_gui_input(event):
	if _is_disabled: return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if not _is_selected or _is_error:
			CurrentSelectionGroup.mark_selected(self)


func _transition_style(instant: bool = false):
	if AnswerLabel == null || AnswerBorder == null:
		return

	if _transition_tween != null:
		_transition_tween.kill()

	var target_color: Color = Style.NormalColor
	if _is_disabled:
		target_color = Style.SuccessColor
	elif _is_error:
		target_color = Style.FailureColor
	elif _is_selected:
		target_color = Style.SelectedColor
	elif _is_hover:
		target_color = Style.HighlightColor
	else:
		target_color = Style.NormalColor
	
	var selection_indicator_alpha: int = 1 if _is_selected else 0
	var selection_indicator_color = target_color
	selection_indicator_color.a = selection_indicator_alpha
	
	if instant:
		AnswerLabel.modulate = target_color
		AnswerBorder.modulate = target_color
		SelectionIndicator.modulate = selection_indicator_color
	else:
		_transition_tween = create_tween()
		if _transition_tween == null:
			return
		_transition_tween.tween_property(AnswerLabel, "modulate", target_color, StyleTransitionSpeed)
		_transition_tween.parallel().tween_property(AnswerBorder, "modulate", target_color, StyleTransitionSpeed)
		_transition_tween.parallel().tween_property(SelectionIndicator, "modulate", selection_indicator_color, StyleTransitionSpeed)
