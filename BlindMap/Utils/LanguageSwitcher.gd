extends Node

signal language_switched(locale: String)

const DEFAULT_LANGUAGE: String = "en"

var CurrentLanguage: String
var SystemLanguage: String


func _ready():
	SystemLanguage = OS.get_locale_language()
	if SystemLanguage != null:
		SystemLanguage = SystemLanguage.split("_")[0]
	CurrentLanguage = TranslationServer.get_locale()
	if CurrentLanguage != null:
		CurrentLanguage = CurrentLanguage.split("_")[0]
	if not GameData.Language.is_empty() && CurrentLanguage != GameData.Language:
		set_language(GameData.Language)
	else:
		print("Language is set to ", CurrentLanguage)


func set_language(language: String):
	if CurrentLanguage == language:
		return
	
	var loaded_languages = TranslationServer.get_loaded_locales()
	if not language in loaded_languages:
		language = DEFAULT_LANGUAGE
	
	if CurrentLanguage == language:
		return
	
	print("Language is set to ", language)
	TranslationServer.set_locale(language)
	CurrentLanguage = language
	language_switched.emit(language)
