extends CanvasLayer
## Global unicorn-horn cursor and cursor movement particle trail (Autoload: Cursor).
## The horn is drawn by the game on the top layer while the OS cursor is hidden, so no
## control, popup or pause overlay can ever swap it for a system cursor.

const CURSOR_PATH: String = "res://assets/ui/cursor.png"
const CURSOR_SIZE: Vector2 = Vector2(100, 100)
const CURSOR_HOTSPOT: Vector2 = Vector2(11, 6)  # the horn tip inside the image
const EMIT_HOLD_SECONDS: float = 0.06

var _horn: TextureRect
var _particles: CPUParticles2D
var _emit_time_left: float = 0.0
var _last_mouse_pos: Vector2 = Vector2.ZERO
var _has_mouse_pos: bool = false


func _ready() -> void:
	layer = 128  # above every other layer, including the pause menu (101)
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(false)

	_setup_cursor()
	_setup_particles()
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var motion := event as InputEventMouseMotion
		var mouse_pos := _particles.get_global_mouse_position()
		_horn.position = mouse_pos - CURSOR_HOTSPOT
		_horn.visible = true
		var moved: bool = motion.relative.length_squared() > 0.0 \
				or (_has_mouse_pos and mouse_pos.distance_squared_to(_last_mouse_pos) > 0.25)
		_has_mouse_pos = true
		_last_mouse_pos = mouse_pos
		_particles.position = mouse_pos
		if moved:
			_emit_on_move()


func _process(delta: float) -> void:
	_emit_time_left -= delta
	if _emit_time_left <= 0.0:
		_emit_time_left = 0.0
		_particles.emitting = false
		set_process(false)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_MOUSE_EXIT:
		if _horn:
			_horn.visible = false
		_has_mouse_pos = false
		_emit_time_left = 0.0
		if _particles:
			_particles.emitting = false
		set_process(false)


func _emit_on_move() -> void:
	_emit_time_left = EMIT_HOLD_SECONDS
	_particles.emitting = true
	set_process(true)


func _setup_cursor() -> void:
	_horn = TextureRect.new()
	_horn.name = "Horn"
	_horn.texture = load(CURSOR_PATH) as Texture2D
	_horn.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_horn.stretch_mode = TextureRect.STRETCH_SCALE
	_horn.size = CURSOR_SIZE
	_horn.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_horn.visible = false
	add_child(_horn)


func _setup_particles() -> void:
	var color_ramp := Gradient.new()
	color_ramp.offsets = PackedFloat32Array([0.0, 0.45, 1.0])
	color_ramp.colors = PackedColorArray([
		Color(1.0, 0.94, 0.76, 0.9),
		Color(0.96, 0.66, 0.80, 0.65),
		Color(0.82, 0.54, 0.78, 0.0),
	])

	var scale_curve := Curve.new()
	scale_curve.add_point(Vector2(0.0, 1.0))
	scale_curve.add_point(Vector2(1.0, 0.0))

	_particles = CPUParticles2D.new()
	_particles.name = "CursorParticles"
	_particles.emitting = false
	_particles.amount = 28
	_particles.lifetime = 0.5
	_particles.lifetime_randomness = 0.25
	_particles.local_coords = false
	_particles.texture = _create_particle_texture()
	_particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	_particles.emission_sphere_radius = 4.0
	_particles.direction = Vector2.DOWN
	_particles.spread = 180.0
	_particles.gravity = Vector2(0.0, 28.0)
	_particles.initial_velocity_min = 12.0
	_particles.initial_velocity_max = 36.0
	_particles.damping_min = 20.0
	_particles.damping_max = 40.0
	_particles.scale_amount_min = 0.4
	_particles.scale_amount_max = 0.85
	_particles.scale_amount_curve = scale_curve
	_particles.color_ramp = color_ramp
	add_child(_particles)

func _create_particle_texture() -> ImageTexture:
	const TEXTURE_SIZE: int = 16
	
	var image := Image.create(TEXTURE_SIZE, TEXTURE_SIZE, false, Image.FORMAT_RGBA8)
	var center := Vector2(TEXTURE_SIZE - 1, TEXTURE_SIZE - 1) * 0.5
	var radius := float(TEXTURE_SIZE - 1) * 0.5

	for y in range(TEXTURE_SIZE):
		for x in range(TEXTURE_SIZE):
			var dist := Vector2(x, y).distance_to(center) / radius
			var alpha := pow(clampf(1.0 - dist, 0.0, 1.0), 1.8)
			image.set_pixel(x, y, Color(1.0, 1.0, 1.0, alpha))

	return ImageTexture.create_from_image(image)
