extends Node
## Translation tables and the active language (Autoload: Localization).
## Every player-facing string lives in res://locales/<code>.json under a dotted key.

signal language_changed

const LANGUAGES: Array[String] = ["en", "ru"]
const DEFAULT_LANGUAGE: String = "en"
const SETTINGS_PATH: String = "user://settings.cfg"
# The story fonts have no Cyrillic glyphs, so Russian text falls back to these.
const CYRILLIC_STORY_FONT: Font = preload("res://assets/fonts/RuslanDisplay.ttf")
const CYRILLIC_DIALOGUE_FONT: Font = preload("res://assets/fonts/Underdog.ttf")

var language: String = DEFAULT_LANGUAGE
var _tables: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for code in LANGUAGES:
		_tables[code] = _load_table(code)
	var settings := ConfigFile.new()
	if settings.load(SETTINGS_PATH) == OK:
		var saved: String = settings.get_value("game", "language", DEFAULT_LANGUAGE)
		if saved in LANGUAGES:
			language = saved
	var story_font: Font = GameState.STORY_FONT
	story_font.fallbacks = [CYRILLIC_STORY_FONT]
	var dialogue_font: Font = GameState.DIALOGUE_FONT
	dialogue_font.fallbacks = [CYRILLIC_DIALOGUE_FONT]


## The text for a key in the active language, falling back to English and then to the key itself.
func t(key: String) -> String:
	var table: Dictionary = _tables.get(language, {})
	if table.has(key):
		return table[key]
	push_warning("Localization: missing '%s' for language '%s'." % [key, language])
	return _tables.get(DEFAULT_LANGUAGE, {}).get(key, key)


func set_language(code: String) -> void:
	if code == language or not code in LANGUAGES:
		return
	language = code
	var settings := ConfigFile.new()
	settings.load(SETTINGS_PATH)
	settings.set_value("game", "language", code)
	if settings.save(SETTINGS_PATH) != OK:
		push_warning("Localization: could not save the language choice.")
	language_changed.emit()


func _load_table(code: String) -> Dictionary:
	var resource := load("res://locales/%s.json" % code) as JSON
	if resource == null or not resource.data is Dictionary:
		push_error("Localization: could not load the '%s' table." % code)
		return {}
	return resource.data
