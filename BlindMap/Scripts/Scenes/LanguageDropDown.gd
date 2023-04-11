extends OptionButton

const LANGUAGES = [
	["cs", "Czech (Čeština)"],
	["en", "English"],
]


func _ready():
	var popup: PopupMenu = get_popup()
	for i in LANGUAGES.size():
		var lang = LANGUAGES[i]
		add_icon_item(load("res://Graphics/Icons/Globe.png"), lang[1], i)
		popup.set_item_as_radio_checkable(i, false)
	_select_language(LanguageSwitcher.CurrentLanguage)


func _on_item_selected(index):
	LanguageSwitcher.set_language(LANGUAGES[index][0])
	GameData.Language = LanguageSwitcher.CurrentLanguage
	GameData.save_data()


func _select_language(lang):
	var selected_language_index = -1
	for i in LANGUAGES.size():
		if LANGUAGES[i][0] == lang:
			selected_language_index = i
			break
	select(selected_language_index)
