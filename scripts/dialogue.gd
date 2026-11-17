extends Control

const CHARS_PER_SECOND: float = 65.0

const STORY_FONT: Font = preload("res://assets/fonts/GrandMalon-Regular.ttf")

@onready var ambient_tint: ColorRect = $AmbientTint
@onready var back_button: Button = $MarginContainer/VBoxContainer/TopBar/BackButton

@onready var portrait_tint: ColorRect = $MarginContainer/VBoxContainer/ContentRow/PortraitCard/PortraitMargin/PortraitVBox/PortraitFrame/Tint
@onready var portrait_texture: TextureRect = $MarginContainer/VBoxContainer/ContentRow/PortraitCard/PortraitMargin/PortraitVBox/PortraitFrame/PortraitTexture
@onready var character_title_label: Label = $MarginContainer/VBoxContainer/ContentRow/PortraitCard/PortraitMargin/PortraitVBox/CharacterTitleLabel
@onready var character_name_label: Label = $MarginContainer/VBoxContainer/ContentRow/PortraitCard/PortraitMargin/PortraitVBox/CharacterNameLabel
@onready var character_summary_label: Label = $MarginContainer/VBoxContainer/ContentRow/PortraitCard/PortraitMargin/PortraitVBox/CharacterSummaryLabel

@onready var dialogue_card: PanelContainer = $MarginContainer/VBoxContainer/ContentRow/DialogueCard
@onready var dialogue_text: RichTextLabel = $MarginContainer/VBoxContainer/ContentRow/DialogueCard/DialogueMargin/DialogueVBox/DialogueText
@onready var choices_container: VBoxContainer = $MarginContainer/VBoxContainer/ContentRow/DialogueCard/DialogueMargin/DialogueVBox/ChoicesContainer

var _character_data: Dictionary = {}
var _dialogue_nodes: Dictionary = {}
var _current_choices: Array = []
var _typewriter_tween: Tween
var _scene_texture: TextureRect

func _ready() -> void:
	_scene_texture = TextureRect.new()
	_scene_texture.set_anchors_preset(Control.PRESET_FULL_RECT)
	_scene_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_scene_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_scene_texture.mouse_filter = Control.MOUSE_FILTER_STOP
	_scene_texture.gui_input.connect(_on_scene_input)
	_scene_texture.visible = false
	add_child(_scene_texture)
	move_child(_scene_texture, ambient_tint.get_index())

	back_button.hide()
	dialogue_card.gui_input.connect(_on_dialogue_card_input)

	_load_character()

func _unhandled_input(event: InputEvent) -> void:
	if SceneTransition.is_transitioning():
		return

	# Support numeric hotkeys (1-9) for classic conversation RPG selection.
	if event is InputEventKey and event.pressed and not event.echo:
		var index: int = int(event.keycode) - int(KEY_1)
		if index >= 0 and index < _current_choices.size():
			get_viewport().set_input_as_handled()
			_select_choice(index)

func _load_character() -> void:
	_character_data = GameState.get_selected_character()
	_dialogue_nodes = _character_data.get("dialogue", {})

	var title: String = _character_data.get("title", "Unknown")
	var char_name: String = _character_data.get("name", "")
	var accent: Color = _character_data.get("accent", Color.WHITE)
	var bg_tint: Color = _character_data.get("bg_tint", Color(0.12, 0.10, 0.14))

	character_title_label.text = title
	character_name_label.add_theme_font_override("font", STORY_FONT)
	character_name_label.text = char_name
	character_name_label.add_theme_color_override("font_color", accent)
	character_summary_label.text = _character_data.get("summary", "")

	portrait_tint.color = bg_tint
	ambient_tint.color = Color(bg_tint.r, bg_tint.g, bg_tint.b, 0.35)

	var char_id: String = _character_data.get("id", GameState.selected_character_id)
	var portrait_tex: Texture2D = GameState.get_character_portrait(char_id)
	portrait_texture.texture = portrait_tex
	portrait_texture.visible = portrait_tex != null

	var start_key: String = _character_data.get("start_node", "start")
	show_dialogue_node(start_key)


func show_dialogue_node(node_key: String) -> void:
	if not _dialogue_nodes.has(node_key):
		_leave_conversation()
		return

	var node_data: Dictionary = _dialogue_nodes[node_key]
	if node_data.get("choices", []).is_empty():
		GameState.finish_conversation("spared")
	var line_text: String = node_data.get("text", "")
	_current_choices = node_data.get("choices", [])
	_show_scene(node_data.get("scene", ""))

	if _typewriter_tween and _typewriter_tween.is_running():
		_typewriter_tween.kill()

	dialogue_text.text = line_text
	dialogue_text.visible_ratio = 0.0

	var duration: float = clampf(float(line_text.length()) / CHARS_PER_SECOND, 0.25, 2.2)
	_typewriter_tween = create_tween()
	_typewriter_tween.tween_property(dialogue_text, "visible_ratio", 1.0, duration)

	_rebuild_choices()


func _show_scene(scene_path: String) -> void:
	var has_scene: bool = not scene_path.is_empty() and ResourceLoader.exists(scene_path)
	if has_scene:
		_scene_texture.texture = load(scene_path) as Texture2D
	_scene_texture.visible = has_scene
	StatsHud.set_forced_hidden(has_scene)
	$MarginContainer.visible = not has_scene
	ambient_tint.visible = not has_scene


func _on_scene_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_leave_conversation()


func _rebuild_choices() -> void:
	for child in choices_container.get_children():
		choices_container.remove_child(child)
		child.queue_free()

	for i in range(_current_choices.size()):
		var choice: Dictionary = _current_choices[i]

		var btn := Button.new()
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		btn.text = choice.get("label", "Continue")
		btn.pressed.connect(_select_choice.bind(i))
		choices_container.add_child(btn)

func _select_choice(index: int) -> void:
	if index < 0 or index >= _current_choices.size():
		return

	var choice: Dictionary = _current_choices[index]
	var next_key: String = choice.get("next", "")
	if next_key.is_empty():
		GameState.finish_conversation("spared")
		_leave_conversation()
	else:
		show_dialogue_node(next_key)

func _on_dialogue_card_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if _typewriter_tween and _typewriter_tween.is_running():
			_typewriter_tween.kill()
			dialogue_text.visible_ratio = 1.0


func _leave_conversation() -> void:
	StatsHud.set_forced_hidden(false)
	SceneTransition.change_scene(GameState.CHARACTERS_SCENE)
