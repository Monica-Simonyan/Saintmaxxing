class_name MazeGlow
extends Control
## The red lanes: a soft glow with a thin bright core. Drawn once per maze.

const RAIL_COLOR: Color = Color(0.85, 0.12, 0.2)
const RAIL_GLOW_ALPHA: float = 0.1
const RAIL_HALO_ALPHA: float = 0.14
const RAIL_CORE_ALPHA: float = 0.9
const RAIL_GLOW_THICKNESS: float = 12.0
const RAIL_HALO_THICKNESS: float = 6.0
const RAIL_CORE_THICKNESS: float = 3.0
const WALL_CAP: float = 1.5  # extends wall ends so corners join

var _segments: Array[Array] = []  # [from, to] pairs in maze pixels


## Rebuilds the walls for a maze and sizes this node to cover it.
func build(grid: MazeGrid) -> void:
	_segments.clear()
	for tile in grid.open_tiles():
		_segments.append_array(_wall_segments(grid, tile))
	size = MazeGrid.pixel_size()
	queue_redraw()


## Wall lines along every side of a lane tile that has no lane next to it.
func _wall_segments(grid: MazeGrid, tile: Vector2i) -> Array[Array]:
	const T: float = MazeGrid.TILE
	const EDGES: Dictionary = {
		Vector2i.UP: [Vector2(0, 0), Vector2(T, 0)],
		Vector2i.DOWN: [Vector2(0, T), Vector2(T, T)],
		Vector2i.LEFT: [Vector2(0, 0), Vector2(0, T)],
		Vector2i.RIGHT: [Vector2(T, 0), Vector2(T, T)],
	}
	var walls: Array[Array] = []
	var origin := Vector2(tile) * T
	for dir in EDGES:
		if grid.is_open(tile + dir):
			continue
		var edge: Array = EDGES[dir]
		var along: Vector2 = (edge[1] - edge[0]).normalized() * WALL_CAP
		walls.append([origin + edge[0] - along, origin + edge[1] + along])
	return walls


func _draw() -> void:
	var glow := Color(RAIL_COLOR, RAIL_GLOW_ALPHA)
	var halo := Color(RAIL_COLOR, RAIL_HALO_ALPHA)
	var core := Color(RAIL_COLOR, RAIL_CORE_ALPHA)
	for segment in _segments:
		draw_line(segment[0], segment[1], glow, RAIL_GLOW_THICKNESS, true)
		draw_line(segment[0], segment[1], halo, RAIL_HALO_THICKNESS, true)
		draw_line(segment[0], segment[1], core, RAIL_CORE_THICKNESS, true)
