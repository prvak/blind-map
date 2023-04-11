class_name FullscreenButton extends Button


@export var FullscreenSprite: Texture2D
@export var WindowedSprite: Texture2D


func _ready():
	FullscreenToggler.fullscreen_toggled.connect(_adjust_appearance)
	

func _on_pressed():
	FullscreenToggler.toggle_fullscreen()


func _adjust_appearance():
	if FullscreenToggler.is_fullscreen():
		icon = WindowedSprite
	else:
		icon = FullscreenSprite
