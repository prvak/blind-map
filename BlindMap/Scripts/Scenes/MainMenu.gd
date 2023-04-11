class_name MainMenu extends Control

@export var LevelSetMenuScene: PackedScene
@export var LevelSetsHolder: Node
@export var AreaItemScene: PackedScene
@export var AreaItemsHolder: Node
@export var Areas: Array[AreaResource] = []

var AreaSelectionGroup = SelectionGroup.new(false)

signal level_clicked(String)

func _ready():
	LanguageSwitcher.language_switched.connect(_on_language_switched)
	Utils.free_all_nodes(LevelSetsHolder)
	Utils.free_all_nodes(AreaItemsHolder)
	AreaSelectionGroup.item_selected.connect(_on_area_selected)

	for i in Areas.size():
		var area = Areas[i]
		add_area(area)

	_order_areas_by_language()
	
	# Select first area or the last selected area.
	if GameData.CurrentAreaId == "":
		AreaSelectionGroup.mark_selected(AreaItemsHolder.get_child(0))
	else:
		var found = false
		for area_item in AreaItemsHolder.get_children():
			if area_item.ItemArea.Id == GameData.CurrentAreaId:
				AreaSelectionGroup.mark_selected(area_item)
				found = true
				break
		if not found:
			AreaSelectionGroup.mark_selected(AreaItemsHolder.get_child(0))


func add_area(area: AreaResource):
	var instance: AreaItem = AreaItemScene.instantiate() as AreaItem
	instance.initialize(area, AreaSelectionGroup)
	AreaItemsHolder.add_child(instance)


func get_first_level_data() -> LevelData:
	return Areas[0].LevelSequences[0].get_first_level_data()


func get_level_data_by_full_id(full_level_id: String) -> LevelData:
	var parts = full_level_id.split(":")
	var data_set_id = parts[0]
	var sequence_id = parts[1]
	var level_id = parts[2]
	for area in Areas:
		for sequence in area.LevelSequences:
			if sequence.DataSet.Id == data_set_id and sequence.Id == sequence_id:
				return sequence.get_level_data(level_id)
	return null


func show_level_sequence(level_sequence: LevelSequenceResource, sequence_level_results: Dictionary):
	var instance := LevelSetMenuScene.instantiate() as LevelSetMenu
	instance.show_level_sequence(level_sequence, sequence_level_results, _on_level_clicked)
	LevelSetsHolder.add_child(instance)


func update_level_statuses(changed_levels: Array):
	for level_set_menu in LevelSetsHolder.get_children():
		level_set_menu.update_level_statuses(changed_levels)


# Workaround for hover state sometimes being stuck.
func reset_level_button_hover(full_level_id):
	var parts = full_level_id.split(":")
	var data_set_id = parts[0]
	var sequence_id = parts[1]
	for level_set_menu in LevelSetsHolder.get_children():
		var sequence = level_set_menu.LevelSequence
		if sequence.DataSet.Id == data_set_id and sequence.Id == sequence_id:
			level_set_menu.reset_level_button_hover(full_level_id)


func _on_language_switched(_language: String):
	var children = AreaItemsHolder.get_children()
	for area in children:
		area.ItemLabel.text = tr(area.ItemArea.Name)
	_order_areas_by_language()


func _on_level_clicked(full_id: String):
	level_clicked.emit(full_id)


func _on_area_selected(area_item: AreaItem):
	GameData.CurrentAreaId = area_item.ItemArea.Id
	GameData.save_data()
	Utils.free_all_nodes(LevelSetsHolder)
	for sequence in area_item.ItemArea.LevelSequences:
		var sequence_results = GameData.get_sequence_level_results(sequence.DataSet.Id, sequence.Id)
		show_level_sequence(sequence, sequence_results)


func _order_areas_by_language():
	var lang = LanguageSwitcher.CurrentLanguage
	var children = AreaItemsHolder.get_children()

	var area_comparator = func (a: AreaItem, b: AreaItem) -> bool:
		var is_lang_a = lang in a.ItemArea.LanguagePriorities
		var is_lang_b = lang in b.ItemArea.LanguagePriorities
		if is_lang_a and is_lang_b:
			var priority_a = a.ItemArea.LanguagePriorities[lang]
			var priority_b = b.ItemArea.LanguagePriorities[lang]
			if priority_a != priority_b:
				return priority_a > priority_b
		elif is_lang_a:
			return true
		elif is_lang_b:
			return false
		
		var name_a = a.ItemLabel.text
		var name_b = a.ItemLabel.text
		if name_a != name_b:
			return name_a < name_b
		var index_a = children.find(a)
		var index_b = children.find(b)
		return index_a < index_b

	children.sort_custom(area_comparator)
	for i in children.size():
		var child = children[i]
		AreaItemsHolder.move_child(child, i)
	


func _on_hints_button_pressed():
	GameData.HintsDisabled = false
	GameData.Hints = {}
	GameData.save_data()
	HintToggler.request_hint("level_selection")
