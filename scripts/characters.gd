extends Control
## Town map: each character stands at a house marked with a name tag; clicking a tag starts their dialogue.

const TAG_TEXTURE: Texture2D = preload("res://assets/map_tag.png")
const STORY_FONT: Font = preload("res://assets/fonts/GrandMalon-Regular.ttf")
const TAG_FONT_SIZE: int = 22
const TAG_TEXT_COLOR: Color = Color(0.3, 0.16, 0.08)
const TAG_PADDING: Vector2 = Vector2(30, 14)
const HOVER_SCALE: float = 1.08
const SCROLL_TEXTURE: Texture2D = preload("res://assets/scroll.png")
const SCROLL_HEIGHT: float = 660.0
const SCROLL_TEXT_MARGINS: Vector4 = Vector4(0.14, 0.22, 0.2, 0.14)  # left, top, right, bottom as image fractions
const SCROLL_FONT_SIZE: int = 26
const SCROLL_TEXT_COLOR: Color = Color(0.2, 0.11, 0.04)
const NEWS_HEADLINE: String = "On today's news of Sinerwood"
# Paragraph per stat, in reading order; a stat that ended exactly at 50 adds nothing.
const NEWS_ORDER: Array[String] = ["justice", "faith", "magic", "love"]
const NEWS: Dictionary = {
	"justice": {
		"down": "Oh sweet lord, since when are our folk so violent? What has gone wrong, I wonder?",
		"up": "As unbelievable as it is, my darling neighbours started following law!! Some very interesting affairs are running in the city!!",
	},
	"faith": {
		"down": "Ah to no one's surprise the heretic and bribetaking whoreson ruined the last peace of spiritual hope in our already Godforsaken town. We can only hope for forgiveness now.",
		"up": "Sweet reader you won't believe, but that \"Godfearing\" priest finally started using the donations for good!! I wonder what divine power infiltrated our town that our neighbours started praying once more.",
	},
	"magic": {
		"down": "Another day, another curse upon our souls. That witch poisoned my cows again!!! I'd go have a talk with that evil woman if I didn't knew she'd turn me into some ugly bastard.",
		"up": "Folks, as shocked as I am, the witch that poisoned my cows not only saved them, but started helping our agricultural comrades. One can only wonder what new magic is brewing in town.",
	},
	"love": {
		"down": "Alas our town is saddened by many, my sweet citizens weren't the most enthusiastic but now they are feeling as down as it gets.",
		"up": "Why look at that! These sweet things are starting to develop feelings that were unknown to them before.",
	},
}

var _map: TextureRect
var _tags: Dictionary = {}  # character_id -> Button


func _ready() -> void:
	_map = TextureRect.new()
	_map.set_anchors_preset(Control.PRESET_FULL_RECT)
	_map.texture = GameState.MAP_TEXTURE
	_map.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_map.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_map.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_map)

	for character_id in GameState.CHARACTER_ORDER:
		var data: Dictionary = GameState.get_character(character_id)
		if data.is_empty():
			continue
		var tag := _make_tag(character_id, data)
		add_child(tag)
		_tags[character_id] = tag

	resized.connect(_place_tags)
	_place_tags()
	if GameState.all_conversations_completed():
		_show_ending_scroll(_compose_news())


func _unhandled_input(event: InputEvent) -> void:
	if SceneTransition.is_transitioning():
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		SceneTransition.change_scene(GameState.MENU_SCENE)


## Builds the town newspaper from how each stat moved away from its starting value.
func _compose_news() -> String:
	var paragraphs: Array[String] = ["[center]%s[/center]\n" % NEWS_HEADLINE]
	for stat_id in NEWS_ORDER:
		var change: int = signi(GameState.stats[stat_id] - GameState.STAT_START)
		if change != 0:
			paragraphs.append(NEWS[stat_id]["up" if change > 0 else "down"])
	return "\n".join(paragraphs)


## Dims the map and unrolls a closing scroll with the given text; a click dismisses it.
func _show_ending_scroll(text: String) -> void:
	var overlay := ColorRect.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0.05, 0.03, 0.08, 0.55)
	overlay.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed:
			overlay.queue_free())
	add_child(overlay)

	var scroll := TextureRect.new()
	scroll.texture = SCROLL_TEXTURE
	scroll.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	scroll.stretch_mode = TextureRect.STRETCH_SCALE
	scroll.custom_minimum_size = Vector2(SCROLL_HEIGHT * SCROLL_TEXTURE.get_width() / SCROLL_TEXTURE.get_height(), SCROLL_HEIGHT)
	scroll.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(center)
	center.add_child(scroll)

	var label := RichTextLabel.new()
	label.position = scroll.custom_minimum_size * Vector2(SCROLL_TEXT_MARGINS.x, SCROLL_TEXT_MARGINS.y)
	label.size = scroll.custom_minimum_size * Vector2(1.0 - SCROLL_TEXT_MARGINS.x - SCROLL_TEXT_MARGINS.z, 1.0 - SCROLL_TEXT_MARGINS.y - SCROLL_TEXT_MARGINS.w)
	label.scroll_active = false
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.bbcode_enabled = true
	label.text = text
	label.add_theme_font_override("normal_font", STORY_FONT)
	label.add_theme_color_override("default_color", SCROLL_TEXT_COLOR)
	scroll.add_child(label)
	TextFit.shrink_to_fit(label, SCROLL_FONT_SIZE)


func _make_tag(character_id: String, data: Dictionary) -> Button:
	var done: bool = GameState.is_conversation_completed(character_id)

	var tag := Button.new()
	tag.text = data.get("name", "")
	tag.disabled = done
	tag.modulate.a = 0.55 if done else 1.0
	tag.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	tag.add_theme_font_override("font", STORY_FONT)
	tag.add_theme_font_size_override("font_size", TAG_FONT_SIZE)
	for color_name in ["font_color", "font_hover_color", "font_pressed_color", "font_disabled_color", "font_focus_color"]:
		tag.add_theme_color_override(color_name, TAG_TEXT_COLOR)

	var normal := _tag_style(false)
	tag.add_theme_stylebox_override("normal", normal)
	tag.add_theme_stylebox_override("disabled", normal)
	tag.add_theme_stylebox_override("focus", normal)
	tag.add_theme_stylebox_override("hover", _tag_style(true))
	tag.add_theme_stylebox_override("pressed", _tag_style(true))

	tag.mouse_entered.connect(_animate_tag.bind(tag, HOVER_SCALE))
	tag.mouse_exited.connect(_animate_tag.bind(tag, 1.0))
	tag.pressed.connect(_engage_character.bind(character_id))
	return tag


func _tag_style(hovered: bool) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = TAG_TEXTURE
	style.set_texture_margin_all(16.0)
	style.content_margin_left = TAG_PADDING.x
	style.content_margin_right = TAG_PADDING.x
	style.content_margin_top = TAG_PADDING.y
	style.content_margin_bottom = TAG_PADDING.y
	style.modulate_color = Color(1.12, 1.08, 1.0) if hovered else Color.WHITE
	return style


func _animate_tag(tag: Button, target_scale: float) -> void:
	create_tween().tween_property(tag, "scale", Vector2.ONE * target_scale, 0.12)


## Maps each tag's image-fraction position through the map's cover-scaling onto the screen.
func _place_tags() -> void:
	var map_size: Vector2 = GameState.MAP_TEXTURE.get_size()
	var cover: float = maxf(size.x / map_size.x, size.y / map_size.y)
	var offset: Vector2 = (size - map_size * cover) * 0.5
	for character_id in _tags:
		var tag: Button = _tags[character_id]
		var fraction: Vector2 = GameState.get_character(character_id).get("map_pos", Vector2(0.5, 0.5))
		tag.reset_size()
		tag.pivot_offset = tag.size * 0.5
		tag.position = offset + map_size * cover * fraction - tag.size * 0.5


func _engage_character(character_id: String) -> void:
	if GameState.is_conversation_completed(character_id) or SceneTransition.is_transitioning():
		return
	GameState.select_character(character_id)
	SceneTransition.change_scene(GameState.DIALOGUE_SCENE)
