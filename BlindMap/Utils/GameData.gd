extends Node

const GAME_SAVE_FILE = "user://game.json"

var CurrentAreaId: String = ""
var CurrentLevelId: String = ""
var LevelResults: Dictionary = {}
var Hints: Dictionary = {}
var HintsDisabled: bool = false
var Language: String = ""

enum LevelStatus {INITIAL, FINISHED_WITH_ERRORS, FINISHED, TROPHY_BRONZE, TROPHY_SILVER, TROPHY_GOLD}

func _ready():
	load_data()


func save_data() -> void:
	var data = {
		"version": 1,
		"area_id": CurrentAreaId,
		"level_id": CurrentLevelId,
		"results": LevelResults,
		"language": Language,
		"hints": Hints,
		"hints_disabled": HintsDisabled,
	}
	var json_string = JSON.stringify(data, "  ")
	
	var file = FileAccess.open(GAME_SAVE_FILE, FileAccess.WRITE)
	file.store_string(json_string)
	file.close()


func load_data() -> void:
	if not FileAccess.file_exists(GAME_SAVE_FILE):
		return
	
	var file = FileAccess.open(GAME_SAVE_FILE, FileAccess.READ)
	var json_string = file.get_as_text()
	file.close()
	
	var data = JSON.parse_string(json_string)
	if data == null:
		return
	
	CurrentAreaId = _try_get(data, "area_id", "")
	CurrentLevelId = _try_get(data, "level_id", "")
	LevelResults = _try_get(data, "results", {})
	Language = _try_get(data, "language", "")
	Hints = _try_get(data, "hints", {})
	HintsDisabled = _try_get(data, "hints_disabled", false)

func _try_get(data: Dictionary, key: String, default_value: Variant) -> Variant:
	if key in data:
		return data[key]
	else:
		return default_value

func mark_level_status(full_level_id: String, level_status: LevelStatus):
	var parts = full_level_id.split(":")
	var data_set_id = parts[0]
	var level_sequence_id = parts[1]
	var level_id = parts[2]
	if not data_set_id in LevelResults:
		LevelResults[data_set_id] = {}
	if not level_sequence_id in LevelResults[data_set_id]:
		LevelResults[data_set_id][level_sequence_id] = {}
	if not level_id in LevelResults[data_set_id][level_sequence_id]:
		LevelResults[data_set_id][level_sequence_id][level_id] = { "status": LevelStatus.INITIAL }
	var current_level_status = LevelResults[data_set_id][level_sequence_id][level_id]["status"]
	if current_level_status == LevelStatus.INITIAL or current_level_status == LevelStatus.FINISHED_WITH_ERRORS:
		LevelResults[data_set_id][level_sequence_id][level_id]["status"] = level_status


func get_level_status(full_level_id: String) -> LevelStatus:
	var parts = full_level_id.split(":")
	var data_set_id = parts[0]
	var level_sequence_id = parts[1]
	var level_id = parts[2]
	if not data_set_id in LevelResults:
		return LevelStatus.INITIAL
	if not level_sequence_id in LevelResults[data_set_id]:
		return LevelStatus.INITIAL
	if not level_id in LevelResults[data_set_id][level_sequence_id]:
		return LevelStatus.INITIAL
	if not "status" in LevelResults[data_set_id][level_sequence_id][level_id]:
		return LevelStatus.INITIAL
	return LevelResults[data_set_id][level_sequence_id][level_id]["status"]


func get_sequence_level_results(data_set_id: String, sequence_id: String):
	if data_set_id in LevelResults and sequence_id in LevelResults[data_set_id]:
		return LevelResults[data_set_id][sequence_id]
	else:
		return {}


func mark_hint_known(hint_name: String):
	Hints[hint_name] = true


func is_hint_known(hint_name: String):
	if hint_name in Hints:
		return Hints[hint_name]
