class_name QuestHud
extends HBoxContainer
## Top-right readout shared by the hint mini-games: optional hearts, then a gold value.
## Losing a heart pulses it, swapping to the empty heart at the peak of the pulse.

const HEART_FULL: Texture2D = preload("res://assets/minigame/heart_full.png")
const HEART_EMPTY: Texture2D = preload("res://assets/minigame/heart_empty.png")
const HEART_SIZE: Vector2 = Vector2(44, 35)
const HEART_PULSE_SCALE: float = 1.6
const HEART_PULSE_SECONDS: float = 0.3
const HEART_WOBBLE: float = 0.35  # radians
const MARGIN: Vector2 = Vector2(24, 14)
const SEPARATION: int = 22
const VALUE_MIN_WIDTH: float = 90.0
const VALUE_FONT_SIZE: int = 44
const VALUE_OUTLINE_SIZE: int = 8
const VALUE_COLOR: Color = Color(1.0, 0.83, 0.1)  # coin gold
const VALUE_OUTLINE_COLOR: Color = Color(0.25, 0.05, 0.1)  # the church's dark red

var _value_label: Label
var _hearts: Array[TextureRect] = []


func _init(lives: int = 0) -> void:
	set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	grow_horizontal = Control.GROW_DIRECTION_BEGIN
	offset_right = -MARGIN.x
	offset_top = MARGIN.y
	alignment = BoxContainer.ALIGNMENT_CENTER
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_constant_override("separation", SEPARATION)

	for i in lives:
		var heart := TextureRect.new()
		heart.texture = HEART_FULL
		heart.custom_minimum_size = HEART_SIZE
		heart.pivot_offset = HEART_SIZE / 2.0
		heart.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		heart.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		heart.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		heart.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(heart)
		_hearts.append(heart)

	_value_label = Label.new()
	_value_label.custom_minimum_size.x = VALUE_MIN_WIDTH
	_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_value_label.add_theme_font_override("font", GameState.STORY_FONT)
	_value_label.add_theme_font_size_override("font_size", VALUE_FONT_SIZE)
	_value_label.add_theme_color_override("font_color", VALUE_COLOR)
	_value_label.add_theme_color_override("font_outline_color", VALUE_OUTLINE_COLOR)
	_value_label.add_theme_constant_override("outline_size", VALUE_OUTLINE_SIZE)
	_value_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_value_label)


func set_value(text: String) -> void:
	_value_label.text = text


## Empties the heart at `index`; the first heart goes first, then the next.
func lose_heart(index: int) -> void:
	var heart: TextureRect = _hearts[index]
	var pulse := create_tween()
	pulse.tween_property(heart, "scale", Vector2.ONE * HEART_PULSE_SCALE, HEART_PULSE_SECONDS / 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	pulse.tween_callback(func() -> void: heart.texture = HEART_EMPTY)
	pulse.tween_property(heart, "scale", Vector2.ONE, HEART_PULSE_SECONDS / 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	var wobble := create_tween()
	for angle in [HEART_WOBBLE, -HEART_WOBBLE, HEART_WOBBLE / 2.0, 0.0]:
		wobble.tween_property(heart, "rotation", angle, HEART_PULSE_SECONDS / 4.0)


func refill_hearts() -> void:
	for heart in _hearts:
		heart.texture = HEART_FULL
