class_name Map extends Control

@export var ItemScene: PackedScene
@export var FadeDuration: float = 0.5
@export var SlowFadeDuration: float = 1
@export var NewItemsDisplayDuration: float = 2


var _map_items: Array
var _map_sprite_size: Vector2
var _map_sprite_scale: Vector2
var _current_tween: Tween
var MapClickableGroup: ClickableGroup = ClickableGroup.new()

@onready var _map_sprite: Sprite2D = get_node("MapSprite")
@onready var _items_holder: Node2D = get_node("Items")
@onready var _new_items_holder: Node2D = get_node("NewItems")


func _ready():
	_map_sprite_size = _map_sprite.texture.get_size()
	_map_sprite_scale = _map_sprite.scale
	Utils.free_all_nodes(_items_holder)


func _start_animation():
	if _current_tween != null:
		_current_tween.kill()
	_current_tween = get_tree().create_tween()
	return _current_tween


func stop_animation():
	if _current_tween != null:
		_current_tween.kill()
	_current_tween = null


func clear():
	_map_items.clear()
	Utils.free_all_nodes(_items_holder)
	Utils.free_all_nodes(_new_items_holder)
	MapClickableGroup.disable()


func set_map_texture(map_texture: Texture2D):
	_map_sprite.texture = map_texture
	_map_sprite_size = _map_sprite.texture.get_size()
	_map_sprite_scale = _map_sprite.scale


func display_records(old_records: Array, new_records: Array):
	# Hide all items.
	await _start_animation().tween_property(_items_holder, "modulate:a", 0, FadeDuration).finished
	
	clear()
	
	_new_items_holder.modulate.a = 0
	if new_records.size() > 0:
		for record in new_records:
			var instance = _instantiate_item(_new_items_holder, record, MapClickableGroup)
			instance.set_label_visible(true)
		
		# Show new items.
		await _start_animation().tween_property(_new_items_holder, "modulate:a", 1, FadeDuration).finished

	for record in old_records:
		_instantiate_item(_items_holder, record, MapClickableGroup)

	# Wait for a while and show old items.
	var tween = _start_animation()
	if new_records.size() > 0:
		tween.tween_interval(NewItemsDisplayDuration)
	tween.tween_property(_items_holder, "modulate:a", 1, SlowFadeDuration)
	for new_item in _new_items_holder.get_children():
		tween.parallel().tween_callback(new_item.set_label_visible.bind(false, SlowFadeDuration))
	await tween.finished
	
	for new_item in _new_items_holder.get_children():
		_new_items_holder.remove_child(new_item)
		_items_holder.add_child(new_item)
	MapClickableGroup.enable()


func _instantiate_item(holder: Node, record: Record, clickable_group: ClickableGroup):
	var instance = ItemScene.instantiate() as MapItem
	instance.position = _coordinates_to_position(record.X, record.Y)
	_map_items.append(instance)
	holder.add_child(instance)
	instance.initialize(record, clickable_group)
	return instance


func clear_errors():
	for item in _map_items:
		item.set_error(false)


func clear_labels():
	for item in _map_items:
		item.set_label_visible(false)


func clear_correct_answers():
	for item in _map_items:
		item.set_disabled(false)


func _coordinates_to_position(x: float, y: float) -> Vector2:
	var map_width = _map_sprite_size.x * _map_sprite_scale.x;
	var map_height = _map_sprite_size.y * _map_sprite_scale.y;
	return Vector2(x - map_width / 2, -(y - map_height / 2));


