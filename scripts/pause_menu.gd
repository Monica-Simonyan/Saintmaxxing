extends CanvasLayer
## Pause button plus a gray overlay with Resume/Restart (Autoload: PauseMenu).
## Hidden on the menu and the unicorn monologue.

var _button: Button
var _overlay: ColorRect


func _ready() -> void:
	layer = 101
	process_mode = Node.PROCESS_MODE_ALWAYS

	_button = Button.new()
	_button.text = "II"
	_button.tooltip_text = "Pause"
	_button.custom_minimum_size = Vector2(40, 40)
	_button.position = Vector2(16, 10)
	_button.pressed.connect(_pause)
	_button.add_theme_stylebox_override("normal", _beige_style(Color(0.91, 0.84, 0.70)))
	_button.add_theme_stylebox_override("hover", _beige_style(Color(0.96, 0.90, 0.78)))
	_button.add_theme_stylebox_override("pressed", _beige_style(Color(0.82, 0.74, 0.60)))
	_button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	for color_name in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		_button.add_theme_color_override(color_name, Color(0.30, 0.20, 0.12))
	add_child(_button)

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

	var title := Label.new()
	title.text = "Paused"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	box.add_child(title)

	box.add_child(_make_menu_button("Resume", _resume))
	box.add_child(_make_menu_button("Restart", _restart))


func _make_menu_button(text: String, on_pressed: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(200, 44)
	button.pressed.connect(on_pressed)
	return button


func _beige_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(8)
	style.set_border_width_all(2)
	style.border_color = Color(0.62, 0.50, 0.36)
	return style


func _process(_delta: float) -> void:
	var intro: bool = GameState.is_intro_scene()
	_button.visible = not intro and not _overlay.visible


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and (_overlay.visible or _button.visible):
		if _overlay.visible:
			_resume()
		else:
			_pause()
		get_viewport().set_input_as_handled()


func _pause() -> void:
	_overlay.visible = true
	get_tree().paused = true


func _resume() -> void:
	_overlay.visible = false
	get_tree().paused = false


func _restart() -> void:
	_resume()
	GameState.reset_state()
	SceneTransition.change_scene(GameState.MENU_SCENE)
