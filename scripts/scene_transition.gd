extends CanvasLayer
## Global screen transition manager (Autoload: SceneTransition).
## Provides smooth fade-to-black transitions between scenes while blocking stray input.

const DEFAULT_DURATION: float = 0.32
const FADE_COLOR: Color = Color(0.06, 0.05, 0.08, 1.0)

var _fade_rect: ColorRect
var _is_transitioning: bool = false

func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS

	_fade_rect = ColorRect.new()
	_fade_rect.name = "FadeOverlay"
	_fade_rect.color = FADE_COLOR
	_fade_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_rect.modulate.a = 1.0
	add_child(_fade_rect)

	# Smooth initial fade-in on game launch.
	var intro_tween := create_tween()
	intro_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	intro_tween.tween_property(_fade_rect, "modulate:a", 0.0, DEFAULT_DURATION)

func is_transitioning() -> bool:
	return _is_transitioning

func change_scene(scene_path: String, duration: float = DEFAULT_DURATION) -> void:
	if _is_transitioning:
		return

	_is_transitioning = true
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_STOP

	var fade_out := create_tween()
	fade_out.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	fade_out.tween_property(_fade_rect, "modulate:a", 1.0, duration)
	await fade_out.finished

	var err := get_tree().change_scene_to_file(scene_path)
	if err != OK:
		push_error("SceneTransition: Failed to change scene to '%s' (error %d)" % [scene_path, err])
		_fade_rect.modulate.a = 0.0
		_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_is_transitioning = false
		return

	await get_tree().process_frame

	var fade_in := create_tween()
	fade_in.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	fade_in.tween_property(_fade_rect, "modulate:a", 0.0, duration)
	await fade_in.finished

	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_is_transitioning = false
