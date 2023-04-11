class_name LevelSetMenu extends MarginContainer

@export var HeaderNode: Label
@export var MenuItemsHolder: Container
@export var LevelButtonScene: PackedScene


var LevelSequence: LevelSequenceResource


var _level_button_nodes_by_level_id = {}


func _ready():
	LanguageSwitcher.language_switched.connect(_on_language_switched)


func show_level_sequence(level_sequence: LevelSequenceResource, sequence_level_results: Dictionary, level_selection_handler: Callable):
	LevelSequence = level_sequence
	Utils.free_all_nodes(MenuItemsHolder)
	HeaderNode.text = tr(LevelSequence.Name)
	for d in level_sequence.get_level_descriptions().values():
		var level_description = d as LevelSequenceResource.LevelDescription
		var button = LevelButtonScene.instantiate() as LevelButton
		var type = level_description.Type
		MenuItemsHolder.add_child(button)
		var status = GameData.LevelStatus.INITIAL
		if level_description.Id in sequence_level_results:
			status = sequence_level_results[level_description.Id]["status"]
		var mode = LevelButton.ButtonMode.SMALL
		if type == LevelSequenceResource.LevelDescription.LevelType.TEST: mode = LevelButton.ButtonMode.BIG
		button.initialize(level_description.FullId, level_description.Name, mode, status)
		button.level_button_clicked.connect(level_selection_handler)
		_level_button_nodes_by_level_id[level_description.FullId] = button


func update_level_statuses(changed_levels: Array):
	if changed_levels.size() <= 0:
		return

	var full_id = changed_levels[0][0]
	if not full_id in _level_button_nodes_by_level_id:
		# Assume that all levels are from the same level sequence.
		return

	var tween = get_tree().create_tween()
	for changed_level in changed_levels:
		full_id = changed_level[0]
		if not full_id in _level_button_nodes_by_level_id:
			continue
		var status = changed_level[1]
		var level_node = _level_button_nodes_by_level_id[full_id]
		level_node.transition_status(status, tween)


func reset_level_button_hover(full_level_id):
	var level_node = _level_button_nodes_by_level_id[full_level_id]
	level_node.set_hover(false)


func _on_language_switched(_language: String):
	if LevelSequence != null:
		HeaderNode.text = tr(LevelSequence.Name)
