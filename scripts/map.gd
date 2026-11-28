extends Control
## Town map: each character stands at a house marked with a name tag; clicking a tag or the house starts their dialogue.

const TAG_TEXTURE: Texture2D = preload("res://assets/map/map_tag.png")
const TAG_FONT_SIZE: int = 22
const TAG_TEXT_COLOR: Color = Color(0.3, 0.16, 0.08)
const TAG_PADDING: Vector2 = Vector2(30, 14)
const HOVER_SCALE: float = 1.08
# Each house sprite and its top-left corner in map-image pixels, where it was painted onto the map.
const HOUSES: Dictionary = {
	"priest": {"texture": preload("res://assets/map/house_priest.png"), "position": Vector2(226, 19)},
	"witch": {"texture": preload("res://assets/map/house_witch.png"), "position": Vector2(1355, 76)},
	"vampire": {"texture": preload("res://assets/map/house_vampire.png"), "position": Vector2(1374, 586)},
	"brothel_worker": {"texture": preload("res://assets/map/house_brothel_worker.png"), "position": Vector2(769, 469)},
}
# Paragraph per stat, in reading order (keys scroll.news.<stat>-up/-down); a stat that ended exactly at 50 adds nothing.
const NEWS_ORDER: Array[String] = ["justice", "faith", "magic", "love"]

var _map: TextureRect
var _tags: Dictionary = {}  # character_id -> Button
var _houses: Dictionary = {}  # character_id -> MapHouse


func _ready() -> void:
	_map = TextureRect.new()
	_map.set_anchors_preset(Control.PRESET_FULL_RECT)
	_map.texture = GameState.MAP_TEXTURE
	_map.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_map.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_map.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_map)

	for character_id in HOUSES:
		var active: bool = not GameState.is_conversation_completed(character_id)
		var house := MapHouse.new(HOUSES[character_id]["texture"], active)
		house.pressed.connect(_engage_character.bind(character_id))
		add_child(house)
		_houses[character_id] = house

	_add_outcome_overlays()

	for character_id in GameState.CHARACTER_ORDER:
		var data: Dictionary = GameState.get_character(character_id)
		if data.is_empty():
			continue
		var tag := _make_tag(character_id, data)
		add_child(tag)
		_tags[character_id] = tag

	resized.connect(_place_tags)
	_place_tags()
	Localization.language_changed.connect(_apply_language)
	if GameState.all_conversations_completed():
		_show_scroll(_compose_news, PauseMenu.show_ending)
	elif not GameState.map_intro_shown:
		GameState.map_intro_shown = true
		_show_scroll(func() -> String: return Localization.t("scroll.intro"))


## Paints each finished conversation's `outcome_overlays` art over the map.
func _add_outcome_overlays() -> void:
	for character_id in GameState.CHARACTER_ORDER:
		var outcome: String = GameState.conversation_outcomes.get(character_id, "")
		var path: String = GameState.get_character(character_id).get("outcome_overlays", {}).get(outcome, "")
		if path.is_empty():
			continue
		var overlay := TextureRect.new()
		overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
		overlay.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		overlay.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		overlay.texture = load(path) as Texture2D
		add_child(overlay)


func _unhandled_input(event: InputEvent) -> void:
	if SceneTransition.is_transitioning():
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		SceneTransition.change_scene(GameState.MENU_SCENE)


## Builds the town newspaper from how each stat moved away from its starting value.
func _compose_news() -> String:
	var paragraphs: Array[String] = ["[center]%s[/center]\n" % Localization.t("scroll.news-headline")]
	for stat_id in NEWS_ORDER:
		var change: int = signi(GameState.stats[stat_id] - GameState.STAT_START)
		if change != 0:
			paragraphs.append(Localization.t("scroll.news.%s-%s" % [stat_id, "up" if change > 0 else "down"]))
	return "\n".join(paragraphs)


## Re-translates the map tags.
func _apply_language() -> void:
	for character_id in _tags:
		(_tags[character_id] as Button).text = Localization.t(GameState.get_character(character_id).get("name", ""))
	_place_tags()


## Unrolls a scroll with the text text_for returns; dismissing it runs on_dismiss.
func _show_scroll(text_for: Callable, on_dismiss: Callable = Callable()) -> void:
	var scroll := StoryScroll.new(text_for)
	if on_dismiss.is_valid():
		scroll.dismissed.connect(on_dismiss)
	add_child(scroll)


func _make_tag(character_id: String, data: Dictionary) -> Button:
	var done: bool = GameState.is_conversation_completed(character_id)

	var tag := Button.new()
	tag.text = Localization.t(data.get("name", ""))
	tag.disabled = done
	tag.modulate.a = 0.55 if done else 1.0
	tag.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	tag.add_theme_font_override("font", GameState.STORY_FONT)
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


## Maps houses and tags through the map's cover-scaling onto the screen.
func _place_tags() -> void:
	var map_size: Vector2 = GameState.MAP_TEXTURE.get_size()
	var cover: float = maxf(size.x / map_size.x, size.y / map_size.y)
	var offset: Vector2 = (size - map_size * cover) * 0.5
	for character_id in _houses:
		var house: MapHouse = _houses[character_id]
		house.position = offset + (HOUSES[character_id]["position"] as Vector2) * cover
		house.size = house.texture.get_size() * cover
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
