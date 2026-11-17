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
const CHOICES_PADDING: float = 90.0
const MIN_CLOUD_HEIGHT: float = 100.0
const BUBBLE_FONT_SIZE: int = 24
const OUTCOME_FONT_SIZE: int = 28
const CHOICE_FONT_SIZE: int = 13
const CLOUD_OPACITY: float = 0.6
const CLOUD_TEXT_COLOR: Color = Color(0.2, 0.05, 0.18)
const CHOICE_ALPHA: Dictionary = {"normal": 0.3, "hover": 0.55, "pressed": 0.7, "focus": 0.3}
const STORY_FONT: Font = preload("res://assets/fonts/GrandMalon-Regular.ttf")

var _dialogue_nodes: Dictionary = {}
var _current_choices: Array = []
var _typewriter_tween: Tween
var _scene_only: bool = false
var _choices_bottom: float = 0.0

var _background: TextureRect
var _bubble: Control
var _choices_bubble: TextureRect
var _scene_overlay: TextureRect
var _start_layers: Array[TextureRect] = []
var _bubble_text: RichTextLabel
var _unicorn: TextureRect
var _choices_box: VBoxContainer
var _outcome_panel: PanelContainer
var _outcome_label: RichTextLabel


func _ready() -> void:
	var data: Dictionary = GameState.get_selected_character()
	_dialogue_nodes = data.get("dialogue", {})
	_build_ui(data)
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
	_choices_box = _make_choices_box()
	_choices_bubble.add_child(_choices_box)

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


func _make_choices_box() -> VBoxContainer:
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 50.0
	box.offset_right = -56.0
	box.offset_top = 32.0
	box.offset_bottom = -58.0
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
	_outcome_label.add_theme_font_override("normal_font", STORY_FONT)
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
	if node_data.get("choices", []).is_empty():
		GameState.finish_conversation("converted" if node_data.get("converted", false) else "spared")
	if _show_full_scene(node_data.get("scene", ""), node_data.get("text", ""), node_data.get("scene_back", "")):
		return

	var line_text: String = node_data.get("text", "")
	_current_choices = node_data.get("choices", [])
	if _typewriter_tween and _typewriter_tween.is_running():
		_typewriter_tween.kill()
	_bubble_text.text = line_text
	_bubble_text.visible_ratio = 0.0
	_bubble_text.offset_bottom = TEXT_TOP + TEXT_AREA_HEIGHT
	_rebuild_choices()
	await TextFit.shrink_to_fit(_bubble_text, BUBBLE_FONT_SIZE)
	_compact_clouds()
	var duration: float = clampf(float(line_text.length()) / CHARS_PER_SECOND, 0.25, 2.2)
	_typewriter_tween = create_tween()
	_typewriter_tween.tween_property(_bubble_text, "visible_ratio", 1.0, duration)


## Trims both clouds to their content so they never grow larger than the text needs.
func _compact_clouds() -> void:
	var text_height: float = float(_bubble_text.get_content_height())
	_bubble_text.offset_bottom = TEXT_TOP + text_height
	_bubble.size.y = maxf(MIN_CLOUD_HEIGHT, TEXT_TOP + text_height + BUBBLE_TAIL_SPACE)
	if _current_choices.is_empty():
		return
	var height: float = maxf(MIN_CLOUD_HEIGHT, _choices_box.get_combined_minimum_size().y + CHOICES_PADDING)
	_choices_bubble.size.y = height
	_choices_bubble.position.y = _choices_bottom - height


func _rebuild_choices() -> void:
	for child in _choices_box.get_children():
		_choices_box.remove_child(child)
		child.queue_free()
	_choices_bubble.visible = not _current_choices.is_empty()
	for i in range(_current_choices.size()):
		var btn := Button.new()
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		btn.add_theme_font_size_override("font_size", CHOICE_FONT_SIZE)
		_style_choice_button(btn)
		btn.text = _current_choices[i].get("label", "Continue")
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
func _show_full_scene(scene_path: String, outcome_text: String, back_path: String = "") -> bool:
	if scene_path.is_empty() or not ResourceLoader.exists(scene_path):
		return false
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
	_outcome_label.text = outcome_text
	_outcome_panel.visible = not outcome_text.is_empty()
	TextFit.shrink_to_fit(_outcome_label, OUTCOME_FONT_SIZE)
	_current_choices = []
	_scene_only = true
	return true


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
