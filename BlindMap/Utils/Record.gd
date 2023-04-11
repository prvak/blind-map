class_name Record extends Object

var Id: String
var Name: String
var Picture: Texture2D
var X: float
var Y: float
var Z: float
var Filters: Dictionary
var Meta: Dictionary
var Lang: Dictionary

var CanScale: bool
var UseBitmask: bool
var UseWideBitmask: bool


func _init(id: String, name: String, picture: Texture2D, x: float, y: float, z: float, filters: Dictionary, meta: Dictionary, lang: Dictionary):
	Id = id
	Name = name
	Picture = picture
	X = x
	Y = y
	Z = z
	Filters = filters
	Meta = meta
	Lang = lang
	# Rivers do not scale well because of their shape.
	CanScale = false if id.begins_with("W") else true
	# Cities and mountains do not need bitmask.
	UseBitmask = false if id.begins_with("C") or id.begins_with("M") else true
	# Rivers are thin so they need igger bitmask.
	UseWideBitmask = true if id.begins_with("W") else false
	
	
func get_localized_name(lang: String):
	if lang in Lang:
		return Lang[lang]
	else:
		return Name
