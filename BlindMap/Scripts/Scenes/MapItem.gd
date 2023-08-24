class_name MapItem extends Area2D

@export var Style: LevelStyleResource
@export var StyleTransitionSpeed: float = 0.1
@export var LabelTransitionSpeed: float = 0.3
@export var SelectionScaleFactor: float = 1.05
@export var ErrorDisplayDuration: float = 2
@export var SuccessDisplayDuration: float = 1
@export var ShowMask: bool = false

signal map_item_clicked(item)

var ItemRecord: Record
var CurrentClickableGroup: ClickableGroup

var _is_hover: bool
var _is_hover_priority: bool
var _is_disabled: bool
var _is_error: bool
var _is_label_visible: bool

var _bit_mask: BitMask
var _transition_tween: Tween = null
var _label_transition_tween: Tween = null

@onready var Sprite: Sprite2D = get_node("%Sprite")
@onready var CollisionShape: CollisionShape2D = get_node("CollisionShape")
@onready var ItemLabel: Label = get_node("%Label")
@onready var _original_scale: Vector2 = scale


func _ready():
	_is_label_visible = ItemLabel.visible
	ItemLabel.modulate.a = 1 if _is_label_visible else 0
	ItemLabel.visible = true
	_transition_style(true)


func initialize(record: Record, clickable_group: ClickableGroup):
	ItemRecord = record
	CurrentClickableGroup = clickable_group
	ItemLabel.text = ItemRecord.get_localized_name(LanguageSwitcher.CurrentLanguage)
	Sprite.texture = ItemRecord.Picture
	var shape = RectangleShape2D.new()
	shape.size = ItemRecord.Picture.get_size()
	CollisionShape.shape = shape
	if ItemRecord.UseBitmask:
		_bit_mask = BitMask.new(ItemRecord.Picture)
	if ShowMask && _bit_mask != null:
		Sprite.texture = _bit_mask.get_mask_as_texture()


func set_disabled(value: bool) -> void:
	_is_disabled = value
	_transition_style()
	if (value):
		var tween = create_tween()
		tween.tween_callback(set_label_visible.bind(true))
		tween.tween_interval(SuccessDisplayDuration)
		tween.tween_callback(set_label_visible.bind(false))


func set_error(value: bool) -> void:
	_is_error = value
	_transition_style()
	if (value):
		var tween = create_tween()
		tween.tween_interval(ErrorDisplayDuration)
		tween.tween_callback(set_error.bind(false))


func set_hover_priority(value: bool) -> void:
	_is_hover_priority = value
	_transition_style()


func set_label_visible(value: bool, transition_speed: float = LabelTransitionSpeed) -> void:
	_is_label_visible = value
	_transition_label_visible(transition_speed)


func blink() -> void:
	var tween = create_tween()
	for i in range(2):
		tween.tween_property(self, "modulate:a", 0.0, 0.1)
		tween.tween_interval(0.1)
		tween.tween_property(self, "modulate:a", 1.0, 0.1)
		tween.tween_interval(0.3)


func _on_mouse_entered():
	if _bit_mask == null:
		_is_hover = true
		CurrentClickableGroup.mark_hover(self, _is_hover, ItemRecord.Z)
	if _is_disabled: return
	_transition_style()


func _on_mouse_exited():
	_is_hover = false
	_is_hover_priority = false
	CurrentClickableGroup.mark_hover(self, _is_hover, ItemRecord.Z)
	if _is_disabled: return
	_transition_style()


func _on_input_event(_viewport, event, _shape_idx):
	if _bit_mask != null and event is InputEventMouse:
		if _is_disabled:
			if _is_hover:
				_is_hover = false
				_is_hover_priority = false
				CurrentClickableGroup.mark_hover(self, _is_hover, ItemRecord.Z)
				_transition_style()
			return
		var pos = get_local_mouse_position() + Sprite.texture.get_size() / 2
		if ItemRecord.UseWideBitmask and _bit_mask.is_true_in_range(pos, 20):
			_is_hover = true
			CurrentClickableGroup.mark_hover(self, _is_hover, ItemRecord.Z)
			_transition_style()
		elif _bit_mask.is_true(pos):
			_is_hover = true
			CurrentClickableGroup.mark_hover(self, _is_hover, ItemRecord.Z)
			_transition_style()
		elif _is_hover:
			_is_hover = false
			_is_hover_priority = false
			CurrentClickableGroup.mark_hover(self, _is_hover, ItemRecord.Z)
			_transition_style()
	if not _is_disabled and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if _is_hover and _is_hover_priority:
			var pos = get_local_mouse_position() + Sprite.texture.get_size() / 2
			if _bit_mask == null:
				CurrentClickableGroup.mark_clicked(self)
			elif ItemRecord.UseWideBitmask and _bit_mask.is_true_in_range(pos, 20):
				CurrentClickableGroup.mark_clicked(self)
			elif _bit_mask.is_true(pos):
				CurrentClickableGroup.mark_clicked(self)


func _transition_style(instant: bool = false):
	if _transition_tween != null:
		_transition_tween.kill()
	var z: int = (int)(0.0 if ItemRecord == null else ItemRecord.Z)
	var target_color: Color = Style.NormalColor
	var target_scale: Vector2 = _original_scale
	if _is_disabled:
		target_color = Style.SuccessColor
		target_scale = _original_scale
		z_index = z + 1
	elif _is_error:
		target_color = Style.FailureColor
		target_scale = _original_scale * SelectionScaleFactor
		z_index = z + 2
	elif _is_hover and _is_hover_priority:
		target_color = Style.SelectedColor
		target_scale = _original_scale * SelectionScaleFactor
		z_index = z + 3
	else:
		target_color = Style.NormalColor
		target_scale = _original_scale
		z_index = z

	if ItemRecord != null && not ItemRecord.CanScale:
		target_scale = _original_scale
	
	if instant:
		scale = target_scale
		Sprite.modulate = target_color
		ItemLabel.add_theme_color_override("font_color", target_color)
	else:
		_transition_tween = create_tween()
		if _transition_tween == null:
			return
		_transition_tween.tween_property(self, "scale", target_scale, StyleTransitionSpeed)
		_transition_tween.parallel().tween_property(Sprite, "modulate", target_color, StyleTransitionSpeed)
		_transition_tween.parallel().tween_property(ItemLabel, "theme_override_colors/font_color", target_color, StyleTransitionSpeed)


func _transition_label_visible(transition_speed: float = LabelTransitionSpeed) -> void:
	if _label_transition_tween != null:
		_label_transition_tween.kill()

	var alpha = 1 if _is_label_visible else 0
	_label_transition_tween = create_tween()
	_label_transition_tween.tween_property(ItemLabel, "modulate:a", alpha, transition_speed)
