class_name MazePulse
extends Control
## The few things that pulse: the big glitter pellets and the gem. Only these are redrawn every
## frame, so the many plain dots stay in `MazeDots`.

const GEM_COLOR: Color = Color(0.55, 0.95, 1.0)
const GEM_RADIUS: float = 11.0
const GEM_WIDTH_RATIO: float = 0.75  # the diamond is narrower than it is tall
const PELLET_RADIUS: float = 8.0
const GLOW_RADIUS_SCALE: float = 1.9
const PULSE_SPEED: float = 6.0

var _pellets: Array[Vector2i] = []
var _gem: Vector2i = Vector2i(-1, -1)
var _has_gem: bool = false
var _pulse: float = 0.0  # 0 to 1


func set_pellets(tiles: Array[Vector2i]) -> void:
	_pellets = tiles
	size = MazeGrid.pixel_size()
	queue_redraw()


func remove_pellet(tile: Vector2i) -> void:
	_pellets.erase(tile)
	queue_redraw()


func show_gem(tile: Vector2i) -> void:
	_gem = tile
	_has_gem = true


func hide_gem() -> void:
	_has_gem = false
	queue_redraw()


func _process(_delta: float) -> void:
	if _pellets.is_empty() and not _has_gem:
		return
	_pulse = 0.5 + 0.5 * sin(Time.get_ticks_msec() / 1000.0 * PULSE_SPEED)
	queue_redraw()


func _draw() -> void:
	if _has_gem:
		var at := MazeGrid.tile_center(_gem)
		var r: float = GEM_RADIUS + _pulse * 2.0
		var half_width: float = r * GEM_WIDTH_RATIO
		draw_circle(at, r * GLOW_RADIUS_SCALE, Color(GEM_COLOR, 0.2))
		draw_colored_polygon(PackedVector2Array([at + Vector2(0, -r), at + Vector2(half_width, 0), at + Vector2(0, r), at + Vector2(-half_width, 0)]), GEM_COLOR)
	for tile in _pellets:
		var center := MazeGrid.tile_center(tile)
		var radius: float = PELLET_RADIUS + _pulse * 2.5
		draw_circle(center, radius * GLOW_RADIUS_SCALE, Color(MazeDots.GLITTER_COLOR, 0.18 + _pulse * 0.1))
		draw_circle(center, radius, MazeDots.GLITTER_COLOR)
