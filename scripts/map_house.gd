class_name MapHouse
extends TextureRect
## A painted house on the town map. While its character can still be talked to it shimmers periodically
## and emits `pressed` when its visible pixels are clicked; transparent pixels let the mouse through.

signal pressed

const HIT_ALPHA: float = 0.5  # pixels more transparent than this are not part of the house
const SHIMMER_SHADER: Shader = preload("res://shaders/house_shimmer.gdshader")
const SHIMMER_PAUSE_MIN: float = 3.0  # seconds between glints, picked at random each time
const SHIMMER_PAUSE_MAX: float = 5.0
const SHIMMER_SWEEP_SECONDS: float = 0.7

var _pixels: Image  # cached once: Texture2D.get_image() is too slow to call per mouse event


func _init(sprite: Texture2D, active: bool) -> void:
	texture = sprite
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_SCALE
	if not active:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		return
	_pixels = sprite.get_image()
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var shimmer := ShaderMaterial.new()
	shimmer.shader = SHIMMER_SHADER
	material = shimmer
	_schedule_glint()


## Waits a random pause, sweeps one glint across the house, then schedules the next.
func _schedule_glint() -> void:
	var glint := create_tween()
	glint.tween_interval(randf_range(SHIMMER_PAUSE_MIN, SHIMMER_PAUSE_MAX))
	glint.tween_method(_set_glint_progress, 0.0, 1.0, SHIMMER_SWEEP_SECONDS)
	glint.finished.connect(_schedule_glint)


func _set_glint_progress(progress: float) -> void:
	(material as ShaderMaterial).set_shader_parameter("progress", progress)


func _has_point(point: Vector2) -> bool:
	var pixel := Vector2i(point / size * Vector2(_pixels.get_size()))
	return Rect2i(Vector2i.ZERO, _pixels.get_size()).has_point(pixel) and _pixels.get_pixelv(pixel).a > HIT_ALPHA


func _gui_input(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	if click != null and click.pressed and click.button_index == MOUSE_BUTTON_LEFT:
		pressed.emit()
