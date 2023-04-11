class_name Answers extends Control

@export var AnswerItemScene: PackedScene
@export var FadeDuration: float = 0.2
@export var AnswerSwapDuration: float = 0.2
@export var MaxAnswersLetters: int = 50

var _answer_items: Array
var _current_tween: Tween
var _visible_answers_letters: int
var _visible_answers_items: Array
var _invisible_answer_items: Array
var _max_visible_answers: int = 100


var AnswersSelectionGroup = SelectionGroup.new(false)


@onready var _items_holder: Control = get_node("HBoxContainer/Items")
@onready var _extra_answers_node: Label = get_node("HBoxContainer/MarginContainer/ExtraAnswersLabel")
@onready var _utils_holder: Node = get_node("Utils")
@onready var _placeholder_node: Placeholder = get_node("Utils/Placeholder")


func _ready():
	Utils.free_all_nodes(_items_holder)
	_extra_answers_node.text = ""
	_placeholder_node.modulate.a = 0
	_placeholder_node.Width = 0
	_utils_holder.remove_child(_placeholder_node)


func hide_records():
	var tween = _start_animation()
	tween.tween_property(_items_holder, "modulate:a", 0, FadeDuration)
	tween.parallel().tween_property(_extra_answers_node, "modulate:a", 0, FadeDuration)
	await tween.finished


func display_records(records: Array, max_visible_answers: int):
	clear()
	
	_max_visible_answers = max_visible_answers
	for record in records:
		var instance = AnswerItemScene.instantiate()
		instance.initialize(record, AnswersSelectionGroup)
		_answer_items.append(instance)

	var answers_count = 0
	var answers_letters = 0
	while answers_count < _max_visible_answers and answers_count < records.size():
		var index = answers_count
		var record = records[index]
		var instance = _answer_items[index]
		var letters = record.get_localized_name(LanguageSwitcher.CurrentLanguage).length()
		if answers_count == 0 or answers_letters + letters < MaxAnswersLetters and answers_count < _max_visible_answers:
			_items_holder.add_child(instance)
			_visible_answers_items.append(instance)
			answers_count += 1
			answers_letters += letters
		else:
			break
	
	if answers_count < records.size():
		_invisible_answer_items = _answer_items.slice(answers_count)
		_extra_answers_node.text = "+%d" % [_invisible_answer_items.size()]
	else:
		_invisible_answer_items = []
		_extra_answers_node.text = ""
	_visible_answers_letters = answers_letters
	
	_items_holder.modulate.a = 0
	_extra_answers_node.modulate.a = 0
	var tween = _start_animation()
	tween.tween_property(_items_holder, "modulate:a", 1, FadeDuration)
	tween.parallel().tween_property(_extra_answers_node, "modulate:a", 1, FadeDuration)
	await tween.finished

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
	AnswersSelectionGroup.clear_selection()
	Utils.free_all_nodes(_items_holder)
	_answer_items.clear()
	_extra_answers_node.text = ""
	_visible_answers_items.clear()
	_invisible_answer_items.clear()


func update_visible_answers():
	var correct_visible_answers = _visible_answers_items.filter(func(item): return item.is_disabled())
	if correct_visible_answers.size() <= 0:
		return
	if _invisible_answer_items.size() <= 0:
		return
		
	var item_to_hide = correct_visible_answers[0]
	_visible_answers_items.remove_at(_visible_answers_items.find(item_to_hide))
	var item_to_show = _invisible_answer_items.pop_front() as Node
	_visible_answers_items.append(item_to_show)

	# Add new item to the scene but not to the answers container.
	item_to_show.modulate.a = 0
	_utils_holder.add_child(item_to_show)

	# Make the old item invisible but do not remove it yet.
	var hide_tween = _start_animation()
	hide_tween.tween_property(item_to_hide, "modulate:a", 0, AnswerSwapDuration)
	await hide_tween.finished

	# Size of the invisible new item should be know by now. 
	# Replace the old item with the placeholder item.
	var old_width = item_to_hide.size.x
	var new_width = item_to_show.size.x
	_placeholder_node.Width = old_width
	_placeholder_node.Height = item_to_hide.size.y
	_items_holder.remove_child(item_to_hide)
	_items_holder.add_child(_placeholder_node)

	# Resize the placeholder to match the new item's size and then replace
	# the placeholder with the new item.
	var show_tween = _start_animation()
	show_tween.tween_property(_placeholder_node, "Width", new_width, AnswerSwapDuration)
	show_tween.tween_callback(_items_holder.remove_child.bind(_placeholder_node))
	show_tween.tween_callback(item_to_show.reparent.bind(_items_holder))
	if _invisible_answer_items.size() > 0:
		show_tween.tween_property(_extra_answers_node, "text", "+%d" % [_invisible_answer_items.size()], 0)
	else:
		show_tween.tween_property(_extra_answers_node, "modulate:a", 0, 0)
	show_tween.tween_property(item_to_show, "modulate:a", 1, AnswerSwapDuration)
	await show_tween.finished


func select_first_answer():
	var remaining_answers = _answer_items.filter(func(item): return not item.is_disabled())
	if remaining_answers.size() > 0:
		var item = remaining_answers[0]
		item.CurrentSelectionGroup.mark_selected(item)

		
func clear_errors():
	for item in _visible_answers_items:
		item.set_error(false)


func is_finished() -> bool:
	return _answer_items.all(func(item): return item.is_disabled())
