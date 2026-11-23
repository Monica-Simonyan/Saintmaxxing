class_name MazeGrid
extends RefCounted
## The lane layout of the vampire's maze, with no nodes or drawing. Nodes sit on every second
## tile and the tiles between them are open where two lanes connect.

const NODE_COLS: int = 11
const NODE_ROWS: int = 6
const COLS: int = NODE_COLS * 2 - 1
const ROWS: int = NODE_ROWS * 2 - 1
const TILE: float = 50.0  # pixels
const DEN_TILE: Vector2i = Vector2i(10, 4)  # the teeth wake up here, and the maze grows from it
const START_TILE: Vector2i = Vector2i(10, 10)
const DEAD_END_OPEN_CHANCE: float = 0.85  # most dead ends get a second way out
const DIRECTIONS: Array[Vector2i] = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]

var _open: Array = []  # [row][col] -> bool, whether that tile is part of a lane


static func tile_center(tile: Vector2i) -> Vector2:
	return (Vector2(tile) + Vector2(0.5, 0.5)) * TILE


static func pixel_size() -> Vector2:
	return Vector2(COLS, ROWS) * TILE


## The four corner tiles, clockwise from the top right.
static func corners() -> Array[Vector2i]:
	return [Vector2i(COLS - 1, 0), Vector2i(0, 0), Vector2i(0, ROWS - 1), Vector2i(COLS - 1, ROWS - 1)]


func in_grid(tile: Vector2i) -> bool:
	return tile.x >= 0 and tile.y >= 0 and tile.x < COLS and tile.y < ROWS


func is_open(tile: Vector2i) -> bool:
	return in_grid(tile) and _open[tile.y][tile.x]


## The directions in which a lane continues from `tile`.
func open_directions(tile: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for dir in DIRECTIONS:
		if is_open(tile + dir):
			result.append(dir)
	return result


func open_tiles() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for row in ROWS:
		for col in COLS:
			var tile := Vector2i(col, row)
			if is_open(tile):
				result.append(tile)
	return result


## A random maze: a spanning tree of lanes, then dead ends and `extra_openings` more walls opened for loops.
func generate(extra_openings: int) -> void:
	_open = []
	for row in ROWS:
		var cells: Array[bool] = []
		cells.resize(COLS)
		cells.fill(false)
		_open.append(cells)

	var visited: Dictionary = {DEN_TILE: true}
	_set_open(DEN_TILE)
	var stack: Array[Vector2i] = [DEN_TILE]
	while not stack.is_empty():
		var tile: Vector2i = stack.back()
		var fresh: Array[Vector2i] = []
		for dir in DIRECTIONS:
			var next: Vector2i = tile + dir * 2
			if in_grid(next) and not visited.has(next):
				fresh.append(next)
		if fresh.is_empty():
			stack.pop_back()
			continue
		var chosen: Vector2i = fresh.pick_random()
		_set_open(tile + (chosen - tile) / 2)
		_set_open(chosen)
		visited[chosen] = true
		stack.append(chosen)

	for row in range(0, ROWS, 2):
		for col in range(0, COLS, 2):
			var tile := Vector2i(col, row)
			if open_directions(tile).size() == 1 and randf() < DEAD_END_OPEN_CHANCE:
				_knock_through(tile)
	for i in extra_openings:
		_knock_through(Vector2i(randi_range(0, NODE_COLS - 1) * 2, randi_range(0, NODE_ROWS - 1) * 2))


## Opens the wall between a node and a random neighbouring node, if it has a closed one.
func _knock_through(tile: Vector2i) -> void:
	var closed: Array[Vector2i] = []
	for dir in DIRECTIONS:
		if in_grid(tile + dir * 2) and not is_open(tile + dir):
			closed.append(dir)
	if not closed.is_empty():
		_set_open(tile + closed.pick_random())


func _set_open(tile: Vector2i) -> void:
	_open[tile.y][tile.x] = true
