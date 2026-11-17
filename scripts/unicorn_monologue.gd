extends Control

const LINES: Array[String] = [
	"What has come over this town?",
	"Knights chase after maidens, maidens chase after priests, and blood is everywhere.",
	"Anarchy, chaos!!! I’m going to have a little word with every last one of them. ",
	"Don’t worry, darlings, I’ll be dusting each of you with my shimmering wisdom.",
	"You may not want it, but you definitely need it.",
]

const STORY_FONT: Font = preload("res://assets/fonts/GrandMalon-Regular.ttf")

const TYPE_SPEED: float = 0.03   # seconds per character
const DRIFT_SECONDS: float = 1.2
const FADE_SHADER: Shader = preload("res://shaders/hair_fade.gdshader")
const LINE_FADE_IN: float = 0.25  # seconds for a line bubble to appear

@onready var hair_panel: MarginContainer = $HairPanel
@onready var lines_container: VBoxContainer = $HairPanel/ScrollContainer/LinesContainer
@onready var continue_button: Button = $ContinueButton

var _current_line: int = 0
var _is_typing: bool = false
var _skip_typing: bool = false
var _busy: bool = true  # blocks clicks until the unicorn has drifted in


func _ready() -> void:
	_place_hair_panel()
	continue_button.hide()
	continue_button.pressed.connect(_on_continue)
	await _drift_unicorn_in()
	_busy = false
	_show_next_line()


# The monologue is written on the unicorn's mane, wherever the final pose puts it.
func _place_hair_panel() -> void:
	var view_size: Vector2 = get_viewport_rect().size
	var area: Rect2 = UnicornPose.hair_text_rect(view_size)
	hair_panel.add_theme_constant_override("margin_left", int(area.position.x))
	hair_panel.add_theme_constant_override("margin_top", int(area.position.y))
	hair_panel.add_theme_constant_override("margin_right", int(view_size.x - area.end.x))
	hair_panel.add_theme_constant_override("margin_bottom", int(view_size.y - area.end.y))


# The maned unicorn drifts from the menu pose to its centre/right monologue pose.
func _drift_unicorn_in() -> void:
	var view_w: float = get_viewport_rect().size.x
	var drifter := TextureRect.new()
	drifter.texture = load("res://assets/unicorn_hair.png") as Texture2D
	drifter.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	drifter.stretch_mode = TextureRect.STRETCH_SCALE
	drifter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	drifter.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	var fade := ShaderMaterial.new()
	fade.shader = FADE_SHADER
	fade.set_shader_parameter("strength", 1.0)  # the mane melts into the dark background on the left
	fade.set_shader_parameter("min_alpha", 0.0)
	drifter.material = fade
	add_child(drifter)
	move_child(drifter, 1)
	var set_slide := func(t: float) -> void:
		UnicornPose.apply(drifter, view_w, t)
	set_slide.call(0.0)
	var tween := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_interval(0.3)  # stand still first, as on the menu
	tween.tween_method(set_slide, 0.0, 1.0, DRIFT_SECONDS)
	await tween.finished


func _input(event: InputEvent) -> void:
	if continue_button.visible:
		return  # let the Begin button receive the click
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		get_viewport().set_input_as_handled()
		if _is_typing:
			_skip_typing = true
		elif not _busy and _current_line < LINES.size():
			_show_next_line()


func _show_next_line() -> void:
	if _current_line >= LINES.size():
		_finish_monologue()
		return

	_busy = true
	var text: String = LINES[_current_line]
	_current_line += 1

	var bubble := _make_bubble()
	lines_container.add_child(bubble)

	# Fade the line in
	bubble.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(bubble, "modulate:a", 1.0, LINE_FADE_IN)
	await tween.finished

	await _type_text(bubble, text)
	_busy = false

	if _current_line >= LINES.size():
		_finish_monologue()


func _make_bubble() -> RichTextLabel:
	var label := RichTextLabel.new()
	label.bbcode_enabled = true
	label.fit_content = true
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	label.add_theme_color_override("default_color", Color(0.95, 0.90, 1.0, 1.0))
	label.add_theme_font_override("normal_font", STORY_FONT)
	label.add_theme_font_size_override("normal_font_size", 22)
	label.add_theme_color_override("font_shadow_color", Color(0.1, 0.0, 0.12, 0.7))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	return label


func _type_text(label: RichTextLabel, full_text: String) -> void:
	_is_typing = true
	_skip_typing = false

	label.text = ""
	for i in full_text.length():
		if _skip_typing:
			label.text = full_text
			break
		label.text = full_text.substr(0, i + 1)
		await get_tree().create_timer(TYPE_SPEED).timeout

	_is_typing = false
	_skip_typing = false


func _finish_monologue() -> void:
	continue_button.show()
	continue_button.modulate.a = 0.0
	continue_button.position.y += 8

	var tween := create_tween()
	tween.set_parallel(true)

	tween.tween_property(
			continue_button,
			"modulate:a",
			1.0,
			0.45
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	tween.tween_property(
			continue_button,
			"position:y",
			continue_button.position.y - 8,
			0.45
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _on_continue() -> void:
	SceneTransition.change_scene(GameState.CHARACTERS_SCENE)
