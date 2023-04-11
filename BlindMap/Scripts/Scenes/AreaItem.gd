class_name AreaItem extends MarginContainer

@export var ItemArea: AreaResource
@export var Style: LevelStyleResource
@export var StyleTransitionSpeed: float = 0.1

var CurrentSelectionGroup: SelectionGroup

var _is_hover: bool
var _is_selected: bool
var _is_disabled: bool
var _transition_tween: Tween

@onready var ItemLabel: Label = get_node("%Label")
@onready var ItemBorder: NinePatchRect = get_node("%Border")
@onready var ItemImage: TextureRect = get_node("%Image")
@onready var SelectionIndicator: TextureRect = get_node("%SelectionIndicator")


func _ready():
	if ItemArea != null:
		ItemLabel.text = tr(ItemArea.Name)
		ItemImage.texture = ItemArea.MiniMapTexture
	_transition_style(true)


func initialize(area: AreaResource, selection_group: SelectionGroup):
	ItemArea = area
	CurrentSelectionGroup = selection_group


func set_selected(value: bool) -> void:
	_is_selected = value
	_transition_style()


func set_disabled(value: bool) -> void:
	_is_disabled = value
	_transition_style()


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
		if not _is_selected and CurrentSelectionGroup != null:
			CurrentSelectionGroup.mark_selected(self)


func _transition_style(instant: bool = false):
	if ItemLabel == null || ItemImage == null || ItemBorder == null:
		return

	if _transition_tween != null:
		_transition_tween.kill()

	var target_color: Color = Style.NormalColor
	if _is_disabled:
		target_color = Style.SuccessColor
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
		ItemLabel.modulate = target_color
		ItemBorder.modulate = target_color
		SelectionIndicator.modulate = selection_indicator_color
	else:
		_transition_tween = create_tween()
		if _transition_tween == null:
			return
		_transition_tween.tween_property(ItemLabel, "modulate", target_color, StyleTransitionSpeed)
		_transition_tween.parallel().tween_property(ItemBorder, "modulate", target_color, StyleTransitionSpeed)
		_transition_tween.parallel().tween_property(SelectionIndicator, "modulate", selection_indicator_color, StyleTransitionSpeed)
