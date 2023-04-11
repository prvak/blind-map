class_name ClickableGroup extends RefCounted

signal item_clicked(item)

var _hover_items: Array
var _hover_priorities: Array
var _is_disabled: bool

func disable():
	for i in _hover_items.size():
		_hover_items[i].set_hover_priority(false)
	_hover_items.clear()
	_hover_priorities.clear()
	_is_disabled = true


func enable():
	_hover_items.clear()
	_hover_priorities.clear()
	_is_disabled = false


func mark_clicked(item) -> void:
	item_clicked.emit(item)


func mark_hover(item, value: bool, priority: float) -> void:
	if _is_disabled:
		return

	var item_index = _hover_items.find(item)
	if item_index < 0:
		if value:
			var new_index = 0
			while new_index < _hover_items.size():
				var pr  = _hover_priorities[new_index]
				if pr < priority:
					break
				new_index += 1
			_hover_items.insert(new_index, item)
			_hover_priorities.insert(new_index, priority)
	else:
		if not value:
			_hover_items.remove_at(item_index)
			_hover_priorities.remove_at(item_index)
	
	for i in _hover_items.size():
		if i == 0:
			_hover_items[i].set_hover_priority(true)
		else:
			_hover_items[i].set_hover_priority(false)
