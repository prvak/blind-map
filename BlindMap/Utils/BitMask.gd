class_name BitMask extends RefCounted


var _mask: BitMap = BitMap.new()
var _rect: Rect2i

func _init(texture: Texture2D):
	_mask.create_from_image_alpha(texture.get_image(), 0)
	var size = _mask.get_size()
	_rect = Rect2i(0, 0, size.x, size.y)


func get_mask_as_texture() -> ImageTexture:
	return ImageTexture.create_from_image(_mask.convert_to_image())


func get_mask_as_polygons() -> Array[PackedVector2Array]:
	return _mask.opaque_to_polygons(_rect)


func grow_mask(pixels: int) -> void:
	_mask.grow_mask(pixels, _rect)


func is_true(point: Vector2) -> bool:
	return is_true_xy(int(point.x), int(point.y))


func is_true_xy(x: int, y: int) -> bool:
	return x >= 0 and x < _rect.size.x and y >= 0 and y < _rect.size.y and _mask.get_bit(x, y)


func is_true_in_range(point: Vector2, distance: int) -> bool:
	if is_true(point):
		return true
	var x: int = int(point.x)
	var y: int = int(point.y)
	for i in range(1, distance):
		var a = is_true_xy(x + i, y + i)
		var b = is_true_xy(x + i, y - i)
		var c = is_true_xy(x - i, y + i)
		var d = is_true_xy(x - i, y - i)
		var e = is_true_xy(x + i, y)
		var f = is_true_xy(x - i, y)
		var g = is_true_xy(x, y + i)
		var h = is_true_xy(x, y - i)
		if a or b or c or d or e or f or g or h:
			return true
	return false
