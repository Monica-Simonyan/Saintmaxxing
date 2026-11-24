extends CanvasLayer
## Pause button plus a gray overlay with Resume/Restart (Autoload: PauseMenu).
## Hidden on the menu and the unicorn monologue.

var _button: Button
var _back_button: Button
var _overlay: ColorRect
var _title: Label
var _resume_button: Button
var _restart_button: Button
var _exit_button: Button
var _language_buttons: Dictionary = {}  # language code -> Button
var _ending: bool = false


func _ready() -> void:
	layer = 101
	process_mode = Node.PROCESS_MODE_ALWAYS

	_back_button = _make_corner_button("←", Vector2(16, 10), _go_back)
	_button = _make_corner_button("II", Vector2(64, 10), _pause)

	_overlay = ColorRect.new()
	_overlay.color = Color(0.25, 0.25, 0.25, 0.8)
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_overlay.visible = false
	add_child(_overlay)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.add_child(center)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	center.add_child(box)

	_title = Label.new()
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 36)
	box.add_child(_title)

	var languages := HBoxContainer.new()
	languages.alignment = BoxContainer.ALIGNMENT_CENTER
	languages.add_theme_constant_override("separation", 12)
	box.add_child(languages)
	for code in Localization.LANGUAGES:
		var language_button := Button.new()
		language_button.custom_minimum_size = Vector2(150, 44)
		MenuButtonStyle.apply(language_button, 20)
		language_button.pressed.connect(Localization.set_language.bind(code))
		languages.add_child(language_button)
		_language_buttons[code] = language_button

	_resume_button = _make_menu_button(_resume)
	box.add_child(_resume_button)
	_restart_button = _make_menu_button(_restart)
	box.add_child(_restart_button)
	_exit_button = _make_menu_button(_exit_game)
	box.add_child(_exit_button)
	Localization.language_changed.connect(_apply_language)
	_set_ending_mode(false)
	GameState.view_changed.connect(_refresh_buttons)
	_refresh_buttons.call_deferred()  # the first scene is not in the tree yet


func _make_menu_button(on_pressed: Callable) -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(220, 56)
	MenuButtonStyle.apply(button)
	button.pressed.connect(on_pressed)
	return button


func _make_corner_button(label: String, pos: Vector2, on_pressed: Callable) -> Button:
	var button := Button.new()
	button.text = label
	button.custom_minimum_size = Vector2(40, 40)
	button.position = pos
	button.pressed.connect(on_pressed)
	button.add_theme_stylebox_override("normal", _beige_style(Color(0.91, 0.84, 0.70)))
	button.add_theme_stylebox_override("hover", _beige_style(Color(0.96, 0.90, 0.78)))
	button.add_theme_stylebox_override("pressed", _beige_style(Color(0.82, 0.74, 0.60)))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	for color_name in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(color_name, Color(0.30, 0.20, 0.12))
	add_child(button)
	return button


func _beige_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(8)
	style.set_border_width_all(2)
	style.border_color = Color(0.62, 0.50, 0.36)
	return style


func _refresh_buttons() -> void:
	var intro: bool = GameState.is_intro_scene()
	var in_quest: bool = not get_tree().get_nodes_in_group(GameState.QUEST_GROUP).is_empty()
	_button.visible = not intro and not in_quest and not _overlay.visible
	_back_button.visible = not _overlay.visible and (in_quest or (_button.visible and _in_scene(GameState.DIALOGUE_SCENE)))


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and (_overlay.visible or _button.visible):
		if _overlay.visible:
			if _resume_button.visible:
				_resume()
			else:
				return
		else:
			_pause()
		get_viewport().set_input_as_handled()


## The closing screen: like the pause screen, but the only way forward is Restart.
func show_ending() -> void:
	_set_ending_mode(true)
	_pause()


func _set_ending_mode(ending: bool) -> void:
	_ending = ending
	_resume_button.visible = not ending
	_apply_language()


func _apply_language() -> void:
	_button.tooltip_text = Localization.t("ui.pause")
	_back_button.tooltip_text = Localization.t("ui.back")
	_title.text = Localization.t("ui.the-end" if _ending else "ui.paused")
	_resume_button.text = Localization.t("ui.resume")
	_restart_button.text = Localization.t("ui.restart")
	_exit_button.text = Localization.t("ui.exit")
	for code in _language_buttons:
		var language_button: Button = _language_buttons[code]
		var active: bool = code == Localization.language
		language_button.text = Localization.t("language." + code)
		language_button.disabled = active
		language_button.modulate.a = 1.0 if active else 0.6


func _in_scene(path: String) -> bool:
	var scene := get_tree().current_scene
	return scene != null and scene.scene_file_path == path


func _go_back() -> void:
	var from_quest: bool = not get_tree().get_nodes_in_group(GameState.QUEST_GROUP).is_empty()
	SceneTransition.change_scene(GameState.DIALOGUE_SCENE if from_quest else GameState.MAP_SCENE)


func _pause() -> void:
	_overlay.visible = true
	get_tree().paused = true
	_refresh_buttons()


func _resume() -> void:
	_overlay.visible = false
	get_tree().paused = false
	_refresh_buttons()


func _restart() -> void:
	_set_ending_mode(false)
	_resume()
	GameState.reset_state()
	SceneTransition.change_scene(GameState.MENU_SCENE)


func _exit_game() -> void:
	if OS.has_feature("web"):
		# Browsers usually refuse to close a tab the page didn't open, so fall back to the menu.
		JavaScriptBridge.eval("window.close()")
		_restart()
		return
	get_tree().quit()
