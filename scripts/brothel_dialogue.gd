extends Control
## Illustrated conversation layout: the character speaks from a speech bubble,
## and the unicorn answers from its own cloud of choices.

const CHARS_PER_SECOND: float = 65.0
const BUBBLE_REGION: Rect2 = Rect2(169, 244, 1683, 595)
const BUBBLE_RECT: Rect2 = Rect2(380, 20, 520, 200)
const CHOICES_RECT: Rect2 = Rect2(520, 430, 520, 270)
const UNICORN_BLEED: float = 104.0
const UNICORN_HEIGHT: float = 560.0
const TEXT_AREA_HEIGHT: float = 180.0  # tallest the text may grow; the cloud then stretches to match instead of the font shrinking
const TEXT_TOP: float = 30.0
const BUBBLE_TAIL_SPACE: float = 50.0
const CHOICES_INSET: Vector4 = Vector4(50, 32, 56, 58)  # left, top, right, bottom inside the cloud
const SCREEN_MARGIN: float = 16.0
const MIN_CLOUD_HEIGHT: float = 100.0
const BUBBLE_FONT_SIZE: int = 24
const OUTCOME_FONT_SIZE: int = 28
const CHOICE_FONT_SIZE: int = 13
const GLOW_COLOR: Color = Color(1.0, 0.93, 0.88)
const GLOOM_COLOR: Color = Color(0.05, 0.03, 0.07)
const SCENE_WASH_IN: float = 0.45
const SCENE_WASH_OUT: float = 1.1
const CLOUD_OPACITY: float = 0.6
const CLOUD_TEXT_COLOR: Color = Color(0.2, 0.05, 0.18)
const CHOICE_ALPHA: Dictionary = {"normal": 0.3, "hover": 0.55, "pressed": 0.7, "focus": 0.3}

var _dialogue_nodes: Dictionary = {}
var _current_choices: Array = []
var _typewriter_tween: Tween
var _scene_only: bool = false
var _current_node: Dictionary = {}
var _outcome_key: String = ""
var _showing_scene: bool = false
var _choices_bottom: float = 0.0

var _background: TextureRect
var _bubble: Control
var _choices_bubble: TextureRect
var _scene_overlay: TextureRect
var _start_layers: Array[TextureRect] = []
var _bubble_text: RichTextLabel
var _unicorn: TextureRect
var _choices_scroll: ScrollContainer
var _choices_box: VBoxContainer
var _outcome_panel: PanelContainer
var _outcome_label: RichTextLabel


func _ready() -> void:
	var data: Dictionary = GameState.get_selected_character()
	_dialogue_nodes = data.get("dialogue", {})
	_build_ui(data)
	Localization.language_changed.connect(_apply_language)
	show_dialogue_node(data.get("start_node", "start"))


## A full-screen cover-scaled picture that ignores the mouse.
func _make_layer(texture: Texture2D) -> TextureRect:
	var layer := TextureRect.new()
	layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	layer.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.texture = texture
	return layer


func _build_ui(data: Dictionary) -> void:
	_background = _make_layer(load(data.get("start_scene", "")) as Texture2D)
	_background.mouse_filter = Control.MOUSE_FILTER_STOP
	_background.gui_input.connect(_on_background_input)
	add_child(_background)

	# Optional transparent layers stacked over the background during the conversation.
	for layer_path in data.get("start_layers", []):
		var layer := _make_layer(load(layer_path) as Texture2D)
		add_child(layer)
		_start_layers.append(layer)

	_scene_overlay = _make_layer(null)
	_scene_overlay.visible = false
	add_child(_scene_overlay)

	var cloud_tex := AtlasTexture.new()
	cloud_tex.atlas = load(data.get("bubble_texture", "res://assets/speech_bubble.png")) as Texture2D
	cloud_tex.region = data.get("bubble_region", BUBBLE_REGION)

	_bubble = _make_cloud(cloud_tex, data.get("bubble_rect", BUBBLE_RECT), CLOUD_OPACITY, false)
	_bubble_text = _make_bubble_text(data.get("cloud_text_color", CLOUD_TEXT_COLOR))
	_bubble.add_child(_bubble_text)

	_unicorn = _make_unicorn()
	add_child(_unicorn)

	# Choices live in their own mirrored cloud beside the unicorn, its tail pointing at him.
	_choices_bubble = _make_cloud(cloud_tex, data.get("choices_rect", CHOICES_RECT), CLOUD_OPACITY, true)
	_choices_bottom = _choices_bubble.position.y + _choices_bubble.size.y
	_choices_scroll = _make_choices_scroll()
	_choices_box = _make_choices_box()
	_choices_scroll.add_child(_choices_box)
	_choices_bubble.add_child(_choices_scroll)

	_build_outcome_panel(data.get("outcome_on_top", false))


## A translucent cloud picture placed on screen; only the cloud fades, never its children.
func _make_cloud(texture: Texture2D, rect: Rect2, opacity: float, mirrored: bool) -> TextureRect:
	var cloud := TextureRect.new()
	cloud.texture = texture
	cloud.flip_h = mirrored
	cloud.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	cloud.stretch_mode = TextureRect.STRETCH_SCALE
	cloud.position = rect.position
	cloud.size = rect.size
	cloud.self_modulate.a = opacity
	cloud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(cloud)
	return cloud


func _make_bubble_text(color: Color) -> RichTextLabel:
	var label := RichTextLabel.new()
	label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	label.offset_left = 56.0
	label.offset_right = -40.0
	label.offset_top = TEXT_TOP
	label.offset_bottom = TEXT_TOP + TEXT_AREA_HEIGHT
	label.scroll_active = false
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_override("normal_font", GameState.DIALOGUE_FONT)
	label.add_theme_color_override("default_color", color)
	return label


func _make_unicorn() -> TextureRect:
	var texture := load("res://assets/unicorn.png") as Texture2D
	var width: float = UNICORN_HEIGHT * texture.get_width() / texture.get_height()
	var unicorn := TextureRect.new()
	unicorn.texture = texture
	unicorn.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	unicorn.stretch_mode = TextureRect.STRETCH_SCALE
	unicorn.flip_h = true
	unicorn.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	unicorn.offset_left = -width + UNICORN_BLEED
	unicorn.offset_right = UNICORN_BLEED
	unicorn.offset_top = -UNICORN_HEIGHT
	unicorn.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return unicorn


## Choices scroll inside the cloud when they are too many or too long to fit on screen.
func _make_choices_scroll() -> ScrollContainer:
	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.offset_left = CHOICES_INSET.x
	scroll.offset_top = CHOICES_INSET.y
	scroll.offset_right = -CHOICES_INSET.z
	scroll.offset_bottom = -CHOICES_INSET.w
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED  # enabled only when the choices outgrow the cloud
	return scroll


func _make_choices_box() -> VBoxContainer:
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.size_flags_vertical = Control.SIZE_EXPAND_FILL  # fills the scroll so short lists stay centred
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 6)
	return box


## Characters whose ending art sits low on screen put the outcome text at the top.
func _build_outcome_panel(text_on_top: bool) -> void:
	_outcome_panel = PanelContainer.new()
	_outcome_panel.set_anchors_preset(Control.PRESET_TOP_WIDE if text_on_top else Control.PRESET_BOTTOM_WIDE)
	_outcome_panel.offset_left = 80.0
	_outcome_panel.offset_right = -80.0
	_outcome_panel.offset_top = 30.0 if text_on_top else -230.0
	_outcome_panel.offset_bottom = 230.0 if text_on_top else -30.0
	_outcome_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_outcome_panel.visible = false
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.1, 0.03, 0.12, 0.82)
	panel_style.set_corner_radius_all(14)
	panel_style.set_content_margin_all(24)
	_outcome_panel.add_theme_stylebox_override("panel", panel_style)
	add_child(_outcome_panel)

	_outcome_label = RichTextLabel.new()
	_outcome_label.scroll_active = false
	_outcome_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_outcome_label.add_theme_font_override("normal_font", GameState.STORY_FONT)
	_outcome_label.add_theme_font_size_override("normal_font_size", OUTCOME_FONT_SIZE)
	_outcome_label.add_theme_color_override("default_color", Color(0.98, 0.93, 0.85))
	_outcome_panel.add_child(_outcome_label)


func _unhandled_input(event: InputEvent) -> void:
	if SceneTransition.is_transitioning():
		return
	if _scene_only and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_leave_conversation()
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var index: int = int(event.keycode) - int(KEY_1)
		if index >= 0 and index < _current_choices.size():
			get_viewport().set_input_as_handled()
			_select_choice(index)


func show_dialogue_node(node_key: String) -> void:
	if not _dialogue_nodes.has(node_key):
		_leave_conversation()
		return

	var node_data: Dictionary = _dialogue_nodes[node_key]
	_current_node = node_data
	if node_data.get("choices", []).is_empty():
		GameState.finish_conversation("converted" if node_data.get("converted", false) else "spared")
	if _show_full_scene(node_data.get("scene", ""), node_data.get("text", ""), node_data.get("scene_back", ""), node_data.get("converted", false)):
		return
	_showing_scene = false
	_show_line(true)


## Puts the current node's line and choices into the clouds, typed out when animate is set.
func _show_line(animate: bool) -> void:
	var line_text: String = Localization.t(_current_node.get("text", ""))
	_current_choices = _current_node.get("choices", [])
	if _typewriter_tween and _typewriter_tween.is_running():
		_typewriter_tween.kill()
	_bubble_text.text = line_text
	_bubble_text.visible_ratio = 0.0 if animate else 1.0
	_bubble_text.offset_bottom = TEXT_TOP + TEXT_AREA_HEIGHT
	_rebuild_choices()
	# Size the choices cloud as soon as the buttons have laid out, not after the (slower) text fit.
	await get_tree().process_frame
	_fit_choices_cloud()
	await TextFit.shrink_to_fit(_bubble_text, BUBBLE_FONT_SIZE)
	_compact_clouds()
	if animate:
		var duration: float = clampf(float(line_text.length()) / CHARS_PER_SECOND, 0.25, 2.2)
		_typewriter_tween = create_tween()
		_typewriter_tween.tween_property(_bubble_text, "visible_ratio", 1.0, duration)


## Re-translates whatever is on screen without replaying the line.
func _apply_language() -> void:
	if _current_node.is_empty():
		return
	if not _showing_scene:
		_show_line(false)
	elif not _outcome_key.is_empty():
		_outcome_label.text = Localization.t(_outcome_key)
		TextFit.shrink_to_fit(_outcome_label, OUTCOME_FONT_SIZE)


## Trims the speech cloud to its text.
func _compact_clouds() -> void:
	var text_height: float = float(_bubble_text.get_content_height())
	_bubble_text.offset_bottom = TEXT_TOP + text_height
	_bubble.size.y = maxf(MIN_CLOUD_HEIGHT, TEXT_TOP + text_height + BUBBLE_TAIL_SPACE)
	_fit_choices_cloud()


## Fits the choices cloud around its buttons, growing upward from its fixed bottom edge;
## the choices scroll only if they would not fit on screen.
func _fit_choices_cloud() -> void:
	if _current_choices.is_empty():
		return
	var wanted: float = _choices_box.get_combined_minimum_size().y + CHOICES_INSET.y + CHOICES_INSET.w
	var height: float = clampf(wanted, MIN_CLOUD_HEIGHT, maxf(MIN_CLOUD_HEIGHT, _choices_bottom - SCREEN_MARGIN))
	_choices_bubble.size.y = height
	_choices_bubble.position.y = _choices_bottom - height
	var overflows: bool = wanted > height + 0.5
	_choices_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO if overflows else ScrollContainer.SCROLL_MODE_DISABLED


func _rebuild_choices() -> void:
	for child in _choices_box.get_children():
		_choices_box.remove_child(child)
		child.queue_free()
	_choices_bubble.visible = not _current_choices.is_empty()
	_choices_scroll.scroll_vertical = 0
	for i in range(_current_choices.size()):
		var btn := Button.new()
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		btn.add_theme_font_override("font", GameState.DIALOGUE_FONT)
		btn.add_theme_font_size_override("font_size", CHOICE_FONT_SIZE)
		_style_choice_button(btn)
		btn.text = Localization.t(_current_choices[i].get("label", "ui.continue"))
		btn.pressed.connect(_select_choice.bind(i))
		_choices_box.add_child(btn)


func _select_choice(index: int) -> void:
	if index < 0 or index >= _current_choices.size():
		return
	var next_key: String = _current_choices[index].get("next", "")
	if next_key.is_empty():
		GameState.finish_conversation("spared")
		_leave_conversation()
	else:
		show_dialogue_node(next_key)


## Replaces the whole screen with a single illustration; returns true if shown.
func _show_full_scene(scene_path: String, outcome_text: String, back_path: String = "", happy: bool = false) -> bool:
	if scene_path.is_empty() or not ResourceLoader.exists(scene_path):
		return false
	_current_choices = []
	_outcome_key = outcome_text
	_showing_scene = true
	_play_scene_change(scene_path, outcome_text, back_path, happy)
	return true


## Swaps to the outcome illustration through a wash of colour: warm light and sparkles when
## the conversion succeeded, a slow fade through darkness when it did not.
func _play_scene_change(scene_path: String, outcome_text: String, back_path: String, happy: bool) -> void:
	var glow := ColorRect.new()
	glow.color = GLOW_COLOR if happy else GLOOM_COLOR
	glow.set_anchors_preset(Control.PRESET_FULL_RECT)
	glow.mouse_filter = Control.MOUSE_FILTER_STOP
	glow.modulate.a = 0.0
	add_child(glow)

	var wash_in := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	wash_in.tween_property(glow, "modulate:a", 1.0, SCENE_WASH_IN)
	await wash_in.finished

	if not back_path.is_empty():
		_background.texture = load(back_path) as Texture2D
		_scene_overlay.texture = load(scene_path) as Texture2D
		_scene_overlay.visible = true
	else:
		_background.texture = load(scene_path) as Texture2D
		_scene_overlay.visible = false
	StatsHud.set_forced_hidden(true)
	for layer in _start_layers:
		layer.visible = false
	_background.mouse_filter = Control.MOUSE_FILTER_STOP
	for node in [_bubble, _choices_bubble, _unicorn]:
		node.visible = false
	_outcome_label.text = Localization.t(outcome_text) if not outcome_text.is_empty() else ""
	_outcome_panel.visible = not outcome_text.is_empty()
	_outcome_panel.modulate.a = 0.0
	TextFit.shrink_to_fit(_outcome_label, OUTCOME_FONT_SIZE)

	if happy:
		_add_sparkles()
	var wash_out := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	wash_out.tween_property(glow, "modulate:a", 0.0, SCENE_WASH_OUT)
	wash_out.parallel().tween_property(_outcome_panel, "modulate:a", 1.0, SCENE_WASH_OUT).set_delay(0.3)
	await wash_out.finished
	glow.queue_free()
	_scene_only = true


func _add_sparkles() -> void:
	var sparkles := CPUParticles2D.new()
	sparkles.position = Vector2(640, 760)
	sparkles.emitting = true
	sparkles.one_shot = true
	sparkles.explosiveness = 0.2
	sparkles.amount = 70
	sparkles.lifetime = 2.2
	sparkles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	sparkles.emission_rect_extents = Vector2(660, 10)
	sparkles.direction = Vector2.UP
	sparkles.spread = 25.0
	sparkles.gravity = Vector2.ZERO
	sparkles.initial_velocity_min = 120.0
	sparkles.initial_velocity_max = 320.0
	sparkles.scale_amount_min = 2.0
	sparkles.scale_amount_max = 5.0
	var fade := Gradient.new()
	fade.colors = PackedColorArray([Color(1, 0.95, 0.75, 0.0), Color(1, 0.95, 0.75, 1.0), Color(1, 0.85, 0.95, 0.0)])
	fade.offsets = PackedFloat32Array([0.0, 0.25, 1.0])
	sparkles.color_ramp = fade
	add_child(sparkles)
	get_tree().create_timer(sparkles.lifetime + 0.5).timeout.connect(sparkles.queue_free)


func _on_background_input(event: InputEvent) -> void:
	if _scene_only and event is InputEventMouseButton and event.pressed:
		_leave_conversation()


func _leave_conversation() -> void:
	StatsHud.set_forced_hidden(false)
	SceneTransition.change_scene(GameState.CHARACTERS_SCENE)


## Soft translucent pill that sits quietly inside the cloud.
func _style_choice_button(btn: Button) -> void:
	for state in CHOICE_ALPHA:
		var box := StyleBoxFlat.new()
		box.bg_color = Color(1, 1, 1, CHOICE_ALPHA[state])
		box.set_corner_radius_all(10)
		box.content_margin_left = 12.0
		box.content_margin_right = 12.0
		box.content_margin_top = 5.0
		box.content_margin_bottom = 5.0
		btn.add_theme_stylebox_override(state, box)
	for color_name in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		btn.add_theme_color_override(color_name, CLOUD_TEXT_COLOR)
