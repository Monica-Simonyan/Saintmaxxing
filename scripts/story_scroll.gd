class_name StoryScroll
extends ColorRect

## A dimmed overlay with an unrolled scroll of story text and a clickable footer.
## Clicking the footer or anywhere outside the scroll emits dismissed and removes the overlay.

signal dismissed

const SCROLL_TEXTURE: Texture2D = preload("res://assets/ui/scroll_intro.png")
const SCROLL_HEIGHT: float = 660.0
const TEXT_MARGINS: Vector4 = Vector4(0.18, 0.22, 0.19, 0.14)  # left, top, right, bottom as image fractions
const FONT_SIZE: int = 26
const LINE_SEPARATION: int = 8  # extra space between lines of the story text
const TEXT_COLOR: Color = Color(0.2, 0.11, 0.04)
const HINT_SIZE: int = 18
const HINT_HEIGHT: float = 34.0

var _text_for: Callable
var _hint_key: String
var _label: RichTextLabel
var _hint: Label


## text_for returns the (BBCode) text, and is called again when the language changes.
func _init(text_for: Callable, hint_key: String = "scroll.hint") -> void:
	_text_for = text_for
	_hint_key = hint_key


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	color = Color(0.05, 0.03, 0.08, 0.55)
	gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed:
			_dismiss())

	var scroll := TextureRect.new()
	scroll.texture = SCROLL_TEXTURE
	scroll.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	scroll.stretch_mode = TextureRect.STRETCH_SCALE
	scroll.custom_minimum_size = Vector2(SCROLL_HEIGHT * SCROLL_TEXTURE.get_width() / SCROLL_TEXTURE.get_height(), SCROLL_HEIGHT)
	scroll.mouse_filter = Control.MOUSE_FILTER_STOP
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	center.add_child(scroll)

	_label = RichTextLabel.new()
	_label.position = scroll.custom_minimum_size * Vector2(TEXT_MARGINS.x, TEXT_MARGINS.y)
	_label.size = scroll.custom_minimum_size * Vector2(1.0 - TEXT_MARGINS.x - TEXT_MARGINS.z, 1.0 - TEXT_MARGINS.y - TEXT_MARGINS.w)
	_label.size.y -= HINT_HEIGHT
	_label.scroll_active = false
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.bbcode_enabled = true
	_label.add_theme_font_override("normal_font", GameState.STORY_FONT)
	_label.add_theme_color_override("default_color", TEXT_COLOR)
	_label.add_theme_constant_override("line_separation", LINE_SEPARATION)
	scroll.add_child(_label)

	_hint = Label.new()
	_hint.position = Vector2(_label.position.x, _label.position.y + _label.size.y)
	_hint.size = Vector2(_label.size.x, HINT_HEIGHT)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_hint.mouse_filter = Control.MOUSE_FILTER_STOP
	_hint.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_hint.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_dismiss())
	_hint.add_theme_font_override("font", GameState.STORY_FONT)
	_hint.add_theme_font_size_override("font_size", HINT_SIZE)
	_hint.add_theme_color_override("font_color", TEXT_COLOR)
	scroll.add_child(_hint)

	Localization.language_changed.connect(_apply_language)
	_apply_language()


func _apply_language() -> void:
	_label.text = _text_for.call()
	_hint.text = Localization.t(_hint_key)
	TextFit.shrink_to_fit(_label, FONT_SIZE)


func _dismiss() -> void:
	dismissed.emit()
	queue_free()
