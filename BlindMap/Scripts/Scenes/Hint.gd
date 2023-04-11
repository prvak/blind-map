class_name Hint extends Node2D

@export_multiline var HintText: String
@export var ArrowTargets: PackedVector2Array
@export var ArrowScene: PackedScene

@onready var _hint_label_node: Label = get_node("%Label")
@onready var _arrows_holder: Node2D = get_node("%ArrowsHolder")


signal hints_disabled
signal hint_closed


func _ready():
	LanguageSwitcher.language_switched.connect(_on_language_switched)
	_hint_label_node.text = tr(HintText)
	for arrow_target in ArrowTargets:
		var instance = ArrowScene.instantiate()
		instance.From = _arrows_holder.position
		instance.To = arrow_target - position
		_arrows_holder.add_child(instance)


func _on_hints_disabled():
	hints_disabled.emit()


func _on_hint_closed():
	hint_closed.emit()


func _on_language_switched(_lang: String):
	_hint_label_node.text = tr(HintText)
