class_name LevelSequenceResource extends Resource

@export var Id: String
@export var DataSet: DataSetResource
@export var Filter: String
@export var Name: String
@export var Levels: Array

var _records: Array = []
var _level_descriptions: Dictionary = {}
	
func get_level_descriptions() -> Dictionary:
	_initialize()
	return _level_descriptions


func get_next_level_id(previous_level_id: String) -> String:
	_initialize()
	var previous_level_description: LevelDescription = _level_descriptions[previous_level_id]
	var all_levels = _level_descriptions.values()
	if previous_level_description.Index + 1 >= all_levels.size():
		return ""
	var next_level_description: LevelDescription = all_levels[previous_level_description.Index + 1]
	return next_level_description.Id


func get_next_level_data(previous_level_id: String) -> LevelData:
	_initialize()
	var next_level_id = get_next_level_id(previous_level_id)
	if next_level_id == "":
		return null
	return get_level_data(next_level_id)


func get_first_level_data() -> LevelData:
	_initialize()
	var first_level_id = _level_descriptions.keys()[0]
	return get_level_data(first_level_id)


func get_level_data(level_id: String) -> LevelData:
	_initialize()
	var level_description: LevelDescription = _level_descriptions[level_id]
	if level_description.Type == LevelDescription.LevelType.LEARN:
		return _get_learn_level_data(level_description)
	else:
		return _get_test_level_data(level_description)


func _get_learn_level_data(level_description: LevelDescription) -> LevelData:
	var NUMBER_OF_ANSWERS = 5
	var records = DataSet.get_records(Filter)
	var learn_number = level_description.LearnNumber
	var old_records = records.slice(0, learn_number - 1)
	var new_record = records[learn_number - 1]
	var answers
	if old_records.size() <= NUMBER_OF_ANSWERS - 1:
		answers = old_records.duplicate()
	else:
		answers = Utils.Random.get_random_slice(old_records, NUMBER_OF_ANSWERS - 1)
	
	answers.append(new_record);
	answers.shuffle()
	var new_records = [new_record]
	return LevelData.new(DataSet.MapTexture, level_description, self, old_records, new_records, answers)


func _get_test_level_data(level_description: LevelDescription) -> LevelData:
	var records = DataSet.get_records(Filter)
	var old_records = records.slice(level_description.TestNumberFrom - 1, level_description.TestNumberTo)
	var answers = old_records.duplicate()
	answers.shuffle()
	return LevelData.new(DataSet.MapTexture, level_description, self, old_records, [], answers)


func _initialize() -> void:
	_init_records()
	_init_level_descriptions()


func _init_records() -> void:
	if _records.size() > 0:
		return
	if DataSet == null:
		return
	_records = DataSet.get_records(Filter)

	
func _init_level_descriptions() -> void:
	if _level_descriptions != null && _level_descriptions.size() > 0:
		return
	_level_descriptions = {}
	var level_index = 0

	for level_description in Levels:
		var parts = level_description.split(":")
		var type = parts[0]
		var indexes = parts[1].split("-")
		var from = indexes[0].to_int()
		var to = indexes[1].to_int()
		if type == "L":
			for level_number in range(from, to + 1):
				var id = "L-%d" % level_number
				var name = "%d" % level_number
				var full_id = "%s:%s:%s" % [DataSet.Id, Id, id]
				_level_descriptions[id] = LevelDescription.new(level_index, id, full_id, name)
				level_index += 1
		elif type == "T":
			var id = "T-%d-%d" % [from, to]
			var name = "%d-%d" % [from, to]
			var full_id = "%s:%s:%s" % [DataSet.Id, Id, id]
			_level_descriptions[id] = LevelDescription.new(level_index, id, full_id, name)
			level_index += 1


class LevelDescription:
	var Index: int
	var Id: String
	var FullId: String
	var Name: String
	var Type: LevelType
	
	var VisibleAnswers: int
	var KeepLearningHintsVisible: bool

	var LearnNumber: int
	var TestNumberFrom: int
	var TestNumberTo: int
	
	enum LevelType {LEARN, TEST}
	
	func _init(index: int, id: String, full_id: String, name: String):
		Index = index
		Id = id
		FullId = full_id
		Name = name
		var parts = id.split("-")
		var type = parts[0]
		match type:
			"L":
				Type = LevelType.LEARN
				LearnNumber = parts[1].to_int()
				TestNumberFrom = -1
				TestNumberTo = -1
				VisibleAnswers = 5
				KeepLearningHintsVisible = true
			"T":
				Type = LevelType.TEST
				LearnNumber = -1
				TestNumberFrom = parts[1].to_int()
				TestNumberTo = parts[2].to_int()
				VisibleAnswers = 1
				KeepLearningHintsVisible = false

