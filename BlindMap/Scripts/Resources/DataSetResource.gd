class_name DataSetResource extends Resource

@export var Id: String
@export var MapTexture: Texture2D
@export_file("*.txt") var SourceFile: String

var _records: Array

func get_records(filter: String) -> Array:
	if _records.size() <= 0:
		_load_records()
	if filter == "all":
		return _records
		
	var filtered_records = _records.filter(func(record: Record): return record.Filters[filter] != 0)
	return filtered_records


func _load_records() -> void:
	var lines = _read_lines(SourceFile)
	var headers = _parse_headers(lines[0])
	for i in range(1, lines.size()):
		var line: String = lines[i].strip_edges()
		if line.is_empty():
			continue
		_records.append(_parse_line(line, headers))
	
func _parse_headers(headers_line: String) -> Dictionary:
	var result = {}
	var headers = headers_line.split(";")
	for i in headers.size():
		var header: String = headers[i].strip_edges()
		result[header] = i
	return result
	
func _parse_line(line: String, headers: Dictionary) -> Record:
	var items = line.split(";")
	var id: String = items[headers["id"]]
	var name: String = items[headers["name"]]
	var picture = load("res://%s" % items[headers["sprite"]]) as Texture2D
	var x: float = items[headers["x"]].to_float()
	var y: float = items[headers["y"]].to_float()
	var z: float = 0
	if "z" in headers:
		z = items[headers["z"]].to_float()
	var meta = {}
	var filters = {}
	var lang = {}
	for header in headers.keys():
		if header.begins_with("meta:"):
			var parts: Array = header.split(":")
			var key: String = parts[1].strip_edges()
			var type: String = parts[2].strip_edges()
			var value: String = items[headers[header]].strip_edges()
			match type:
				"int":
					meta[key] = value.to_int()
				"float":
					meta[key] = value.to_float()
				_:
					meta[key] = value
		elif header.begins_with("filter:"):
			var parts: Array = header.split(":")
			var key: String = parts[1].strip_edges()
			var value: String = items[headers[header]].strip_edges()
			filters[key] = value.to_int()
		elif header.begins_with("name:"):
			var parts: Array = header.split(":")
			var key: String = parts[1].strip_edges()
			var value: String = items[headers[header]].strip_edges()
			lang[key] = value
	return Record.new(id, name, picture, x, y, z, filters, meta, lang)


func _read_lines(path: String) -> Array:
	var file = FileAccess.open(path, FileAccess.READ)
	var lines = Array()
	while not file.eof_reached():
		lines.append(file.get_line())
	return lines
