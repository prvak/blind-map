class_name LevelData extends Object

var MapTexture: Texture2D
var LevelDescription: LevelSequenceResource.LevelDescription
var LevelSequence: LevelSequenceResource
var AllMapRecords: Array
var OldMapRecords: Array
var NewMapRecords: Array
var AnswerRecords: Array


func _init(map_texture: Texture2D, level_description: LevelSequenceResource.LevelDescription, level_sequence: LevelSequenceResource, old_map_records: Array, new_map_records: Array, answer_records: Array):
	MapTexture = map_texture
	LevelDescription = level_description
	LevelSequence = level_sequence
	OldMapRecords = old_map_records
	NewMapRecords = new_map_records
	AnswerRecords = answer_records
	AllMapRecords = []
	AllMapRecords.append_array(old_map_records)
	AllMapRecords.append_array(new_map_records)


func get_id():
	return LevelDescription.Id


func get_full_id():
	return LevelDescription.FullId
