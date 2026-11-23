class_name MazeDots
extends Control
## The plain glitter dots. They never animate, so this only redraws when one is eaten.

const GLITTER_COLOR: Color = Color(1.0, 0.86, 0.72)
const DOT_RADIUS: float = 3.5

var _tiles: Array[Vector2i] = []


func set_tiles(tiles: Array[Vector2i]) -> void:
	_tiles = tiles
	size = MazeGrid.pixel_size()
	queue_redraw()


func remove_tile(tile: Vector2i) -> void:
	_tiles.erase(tile)
	queue_redraw()


func _draw() -> void:
	for tile in _tiles:
		var center := MazeGrid.tile_center(tile)
		draw_circle(center, DOT_RADIUS * 2.2, Color(GLITTER_COLOR, 0.16))
		draw_circle(center, DOT_RADIUS, GLITTER_COLOR)
