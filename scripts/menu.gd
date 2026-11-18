extends Control

const UNICORN_TEXTURE: Texture2D = preload("res://assets/unicorn_hair.png")

@onready var play_button: Button = $CenterContainer/MarginContainer/PlayButton
@onready var unicorn: TextureRect = $PortraitTexture

var _starting: bool = false
var _language_button: Button
var _language_popup: Control
var _popup_buttons: Dictionary = {}  # language code -> Button


func _ready() -> void:
	MenuButtonStyle.apply(play_button, 28)
	play_button.pressed.connect(_on_play_pressed)
	_build_language_ui()
	_apply_language()
	Localization.language_changed.connect(_apply_language)
	unicorn.texture = UNICORN_TEXTURE
	unicorn.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	unicorn.stretch_mode = TextureRect.STRETCH_SCALE
	unicorn.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	UnicornPose.apply(unicorn, get_viewport_rect().size.x, 0.0)


## Adds a Language button under Play, and a translucent popup it opens.
func _build_language_ui() -> void:
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	var holder: Node = play_button.get_parent()
	holder.add_child(column)
	play_button.reparent(column, false)

	_language_button = Button.new()
	_language_button.custom_minimum_size = Vector2(340, 56)
	_language_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_language_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	MenuButtonStyle.apply(_language_button, 24)
	_language_button.pressed.connect(_set_popup_open.bind(true))
	column.add_child(_language_button)

	_language_popup = Control.new()
	_language_popup.set_anchors_preset(Control.PRESET_FULL_RECT)
	_language_popup.visible = false
	_language_popup.gui_input.connect(_on_popup_input)
	add_child(_language_popup)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.35)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_language_popup.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_language_popup.add_child(center)

	var panel := PanelContainer.new()
	var box := StyleBoxFlat.new()
	box.bg_color = Color(1, 1, 1, 0.22)
	box.set_corner_radius_all(18)
	box.set_content_margin_all(24)
	panel.add_theme_stylebox_override("panel", box)
	center.add_child(panel)

	var options := VBoxContainer.new()
	options.add_theme_constant_override("separation", 12)
	panel.add_child(options)
	for code in Localization.LANGUAGES:
		var option := Button.new()
		option.custom_minimum_size = Vector2(300, 60)
		option.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		MenuButtonStyle.apply(option, 26)
		option.pressed.connect(_choose_language.bind(code))
		options.add_child(option)
		_popup_buttons[code] = option


func _choose_language(code: String) -> void:
	Localization.set_language(code)
	_set_popup_open(false)


func _set_popup_open(open: bool) -> void:
	_language_popup.visible = open
	_language_button.get_parent().visible = not open


func _on_popup_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_set_popup_open(false)


func _apply_language() -> void:
	play_button.text = Localization.t("menu.start")
	_language_button.text = Localization.t("menu.language")
	for code in _popup_buttons:
		var option: Button = _popup_buttons[code]
		option.text = Localization.t("language." + code)
		option.modulate.a = 1.0 if code == Localization.language else 0.6


func _on_play_pressed() -> void:
	if _starting:
		return
	_starting = true
	play_button.disabled = true
	SceneTransition.change_scene(GameState.UNICORN_MONOLOGUE_SCENE, 0.2)
