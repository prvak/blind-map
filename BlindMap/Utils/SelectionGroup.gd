class_name SelectionGroup extends Object

var _selected_item = null
var _allow_no_selection = false

signal item_selected(item)

func _init(allow_no_selection):
	_allow_no_selection = allow_no_selection


func get_selected_item():
	return _selected_item


func clear_selection() -> void:
	_selected_item = null


func mark_selected(item) -> void:
	if _selected_item != null and _selected_item != item:
		_selected_item.set_selected(false)
	_selected_item = item
	item.set_selected(true)
	item_selected.emit(item)


func mark_unselected(item) -> void:
	if _allow_no_selection and _selected_item != null and _selected_item == item:
		_selected_item = null
