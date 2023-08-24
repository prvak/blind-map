@tool
class_name HoldableButton
extends Control


signal button_filled


@export var hold_duration := 3.0
@export_range(0.0, 1.0) var _fill_ratio := 0.5:
	get:
		return _fill_ratio
	set(value):
		if _fill_ratio == value:
			return
		_fill_ratio = clampf(value, 0.0, 1.0)
		_update_fill()
@export var _style: LevelStyleResource


var _is_disabled := false
var _mouse_over_button := false
var _held := false


@onready var _normal_texture: TextureRect = get_node("%Normal")
@onready var _background_texture: NinePatchRect = get_node("%Background")
@onready var _normal_outer_node: MarginContainer = get_node("%NormalOuter")
@onready var _normal_inner_node: MarginContainer = get_node("%NormalInner")
@onready var _filled_outer_node: MarginContainer = get_node("%FilledOuter")
@onready var _filled_inner_node: MarginContainer = get_node("%FilledInner")


func _ready():
	_update_fill()
	_normal_texture.modulate = _style.NormalColor
	_background_texture.modulate = _style.NormalColor


func _process(delta):
	if _held:
		if _fill_ratio < 1.0:
			_fill_ratio = clampf(_fill_ratio + delta * 1.0 / hold_duration, 0.0, 1.0)
			_update_fill()
			if _fill_ratio >= 1.0:
				button_filled.emit()
	elif _fill_ratio > 0.0:
		_fill_ratio = clampf(_fill_ratio - 4 * delta * 1.0 / hold_duration, 0.0, 1.0)
		_update_fill()


func _update_fill():
	if not _normal_texture:
		return
	var height := _normal_texture.size.y
	var filled_height := roundi(height * _fill_ratio)
	var normal_height := height - filled_height
	_normal_outer_node.add_theme_constant_override("margin_bottom", filled_height)
	_normal_inner_node.add_theme_constant_override("margin_bottom", -filled_height)
	_filled_outer_node.add_theme_constant_override("margin_top", normal_height)
	_filled_inner_node.add_theme_constant_override("margin_top", -normal_height)


func _on_gui_input(event):
	if _is_disabled:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_held = true
		elif not event.pressed:
			_held = false
		else:
			print(event)


func _on_mouse_entered():
	_mouse_over_button = true
	_normal_texture.modulate = _style.HighlightColor
	_background_texture.modulate = _style.HighlightColor


func _on_mouse_exited():
	_mouse_over_button = false
	_held = false
	_normal_texture.modulate = _style.NormalColor
	_background_texture.modulate = _style.NormalColor
