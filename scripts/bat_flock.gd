class_name BatFlock
extends Control
## Every so often a flapping bat crosses the screen from a random edge, for a gothic mood.
## Draw it between the background and the characters; it ignores the mouse.

const FRAMES: Array[Texture2D] = [
	preload("res://assets/minigame/bat/bat_down.png"),
	preload("res://assets/minigame/bat/bat_up.png"),
]
const INTERVAL_MIN: float = 7.0
const INTERVAL_MAX: float = 13.0
const FIRST_DELAY_MIN: float = 2.0
const FIRST_DELAY_MAX: float = 5.0
const SCALE_MIN: float = 0.4
const SCALE_MAX: float = 0.9
const SPEED_MIN: float = 180.0
const SPEED_MAX: float = 320.0
const FLAP_FPS_MIN: float = 7.0
const FLAP_FPS_MAX: float = 11.0
const BOB_PIXELS: float = 22.0
const BOB_SPEED: float = 3.0
const TILT: float = 0.18  # radians, nose up or down with the bobbing
const MARGIN: float = 120.0  # how far off screen a bat starts and ends
const HEIGHT_MIN: float = 0.05  # a bat's flight stays between these fractions of the screen height
const HEIGHT_MAX: float = 0.75
const SMALL_BAT_SPEED: float = 0.8  # small bats are slower, large ones faster
const LARGE_BAT_SPEED: float = 1.2
const BAT_COLOR: Color = Color(0.1, 0.04, 0.12)  # the default; a darker scene passes a lighter one

var color: Color = BAT_COLOR

var _countdown: float = randf_range(FIRST_DELAY_MIN, FIRST_DELAY_MAX)
var _bats: Array[Dictionary] = []  # {sprite, direction, speed, base_y, climb, phase, flap_fps}


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	_countdown -= delta
	if _countdown <= 0.0:
		_countdown = randf_range(INTERVAL_MIN, INTERVAL_MAX)
		_spawn_bat()
	var seconds: float = Time.get_ticks_msec() / 1000.0
	for bat in _bats.duplicate():
		var sprite: TextureRect = bat.sprite
		var wave: float = sin(seconds * BOB_SPEED + bat.phase)
		sprite.position.x += bat.direction * bat.speed * delta
		bat.base_y += bat.climb * delta
		sprite.position.y = bat.base_y + wave * BOB_PIXELS
		sprite.rotation = wave * TILT * -bat.direction
		sprite.texture = FRAMES[int(seconds * bat.flap_fps) % FRAMES.size()]
		if sprite.position.x < -sprite.size.x - MARGIN * 2.0 or sprite.position.x > size.x + MARGIN * 2.0:
			_bats.erase(bat)
			sprite.queue_free()


func _spawn_bat() -> void:
	var direction: float = 1.0 if randf() < 0.5 else -1.0
	var scale_factor: float = randf_range(SCALE_MIN, SCALE_MAX)
	var sprite := TextureRect.new()
	sprite.texture = FRAMES[0]
	sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sprite.stretch_mode = TextureRect.STRETCH_SCALE
	sprite.size = FRAMES[0].get_size() * scale_factor
	sprite.pivot_offset = sprite.size / 2.0
	sprite.self_modulate = color
	sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var base_y: float = randf_range(size.y * HEIGHT_MIN, size.y * HEIGHT_MAX)
	var end_y: float = randf_range(size.y * HEIGHT_MIN, size.y * HEIGHT_MAX)
	var speed: float = randf_range(SPEED_MIN, SPEED_MAX) * lerpf(SMALL_BAT_SPEED, LARGE_BAT_SPEED, inverse_lerp(SCALE_MIN, SCALE_MAX, scale_factor))
	var crossing_seconds: float = (size.x + sprite.size.x + MARGIN * 2.0) / speed
	var start_x: float = -sprite.size.x - MARGIN if direction > 0.0 else size.x + MARGIN
	sprite.position = Vector2(start_x, base_y)
	add_child(sprite)
	_bats.append({
		"sprite": sprite,
		"direction": direction,
		"speed": speed,
		"base_y": base_y,
		"climb": (end_y - base_y) / crossing_seconds,
		"phase": randf() * TAU,
		"flap_fps": randf_range(FLAP_FPS_MIN, FLAP_FPS_MAX),
	})
