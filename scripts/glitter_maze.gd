class_name GlitterMaze
extends QuestOverlay
## Vampire's hint mini-game, a Pac-Man in the vampire's den: the unicorn runs along a maze of
## glowing red lanes (W/A/S/D or the arrow keys) eating the glitter dots. Snapping vampire teeth
## prowl the lanes; touching one costs a heart. A big glitter pellet makes the teeth scared for a
## few seconds so the unicorn can eat them instead. Eating every dot wins; the third heart lost
## offers a retry, which builds a fresh maze.

enum Mode { WAITING, ACTIVE, SCARED }

const TEETH_TEXTURE: Texture2D = preload("res://assets/minigame/dodge/teeth.png")
const TEETH_BLOODY_TEXTURE: Texture2D = preload("res://assets/minigame/dodge/teeth_bloody.png")
const HISS_SOUND: AudioStream = preload("res://assets/audio/vampire_hiss.mp3")
const EAT_SOUND: AudioStream = preload("res://assets/audio/glitter_eat.mp3")
const PELLET_SOUND: AudioStream = preload("res://assets/audio/pellet_eat.mp3")
const GEM_SOUND: AudioStream = preload("res://assets/audio/gem_eat.mp3")
const UNICORN_TEXTURE: Texture2D = preload("res://assets/characters/unicorn/unicorn.png")

# Maze: nodes sit on every second tile; the tiles between them are open where lanes connect.
const NODE_COLS: int = 11
const NODE_ROWS: int = 6
const GRID_COLS: int = NODE_COLS * 2 - 1
const GRID_ROWS: int = NODE_ROWS * 2 - 1
const TILE: float = 50.0
const DEN_TILE: Vector2i = Vector2i(10, 4)  # the teeth wake up here
const START_TILE: Vector2i = Vector2i(10, 10)
const DEAD_END_OPEN_CHANCE: float = 0.85  # most dead ends get a second way out
const DIRECTIONS: Array[Vector2i] = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]

const MAX_HITS: int = 3
const UNICORN_SPEED: float = 5.2  # tiles per second
const UNICORN_HEIGHT: float = 62.0
const UNICORN_TILT: float = 0.3  # radians when running up or down
const UNICORN_TILT_SPEED: float = 12.0
const CHOMP_PULSE: float = 1.12
const CHOMP_PULSE_SECONDS: float = 0.1

const TEETH_SIZE: Vector2 = Vector2(54, 32)  # the picture is about 1.7 times wider than tall
const TEETH_SPEEDS: Array[float] = [4.3, 4.0, 3.7, 3.9]  # tiles per second, one entry per enemy
const AMBUSH_TILES: int = 3  # the ambusher aims this many tiles ahead of the unicorn
const SHY_DISTANCE: float = 5.0  # the shy one retreats to its corner when closer than this many tiles

# Levels 1 to 4; every list has one entry per level. Level 1 is the quest, the rest are optional.
const LEVEL_COUNT: int = 4
const LEVEL_TEETH: Array[int] = [3, 3, 4, 4]
const LEVEL_SPEED_SCALE: Array[float] = [1.0, 1.07, 1.14, 1.2]
const LEVEL_SCARED_SECONDS: Array[float] = [6.0, 5.0, 4.0, 3.0]
const LEVEL_SCATTER_SECONDS: Array[float] = [6.0, 5.0, 4.0, 3.0]  # the teeth give up the chase for a while, as in Pac-Man
const LEVEL_CHASE_SECONDS: Array[float] = [18.0, 22.0, 26.0, 30.0]
const LEVEL_EXTRA_OPENINGS: Array[int] = [14, 11, 8, 5]  # fewer loops make the maze harder to escape
const LEVEL_INTRO_SECONDS: float = 1.4

const FRUIT_AT: Array[float] = [0.35, 0.7]  # share of the dots eaten when a gem appears
const FRUIT_SECONDS: float = 9.0
const FRUIT_SCORE: int = 100  # times the level
const GEM_RADIUS: float = 11.0
const GEM_WIDTH_RATIO: float = 0.75  # the diamond is narrower than it is tall
const GLOW_RADIUS_SCALE: float = 1.9
const PULSE_SPEED: float = 6.0
const RAIL_GLOW_ALPHA: float = 0.1
const RAIL_HALO_ALPHA: float = 0.14
const RAIL_CORE_ALPHA: float = 0.9
const BANNER_IN_SECONDS: float = 0.35
const BANNER_OUT_SECONDS: float = 0.3
const FRUIT_COLOR: Color = Color(0.55, 0.95, 1.0)
const NO_TILE: Vector2i = Vector2i(-1, -1)
const SAVE_PATH: String = "user://glitter_maze.cfg"
const CHOICE_BOTTOM_MARGIN: float = 70.0
const CHOICE_GAP: float = 24.0
const TEETH_WAKE_SECONDS: Array[float] = [1.5, 4.0, 7.0, 9.5]
const RESPAWN_SECONDS: float = 3.0
const SCARED_SPEED_SCALE: float = 0.6
const SCARED_FLASH_SECONDS: float = 1.5
const SCARED_FLASH_INTERVAL: float = 0.15
const SCARED_COLOR: Color = Color(0.5, 0.7, 1.6)
const WAITING_ALPHA: float = 0.45
const CATCH_DISTANCE: float = 30.0
const CHOMP_SPEED: float = 14.0
const CHOMP_CLOSED_SCALE: float = 0.8
const CHOMP_OPEN_SCALE: float = 1.15

const DOT_SCORE: int = 10
const PELLET_SCORE: int = 50
const ENEMY_SCORE: int = 200  # doubles for every enemy eaten with the same pellet

const HURT_SECONDS: float = 1.6  # the unicorn blinks and can't be caught after a reset
const HURT_FREEZE_SECONDS: float = 0.9
const HURT_BLINK_SECONDS: float = 0.07
const VANISH_PULSE_SCALE: float = 1.35
const VANISH_PULSE_SECONDS: float = 0.18
const VANISH_PULSE_COUNT: int = 2
const VANISH_FADE_SECONDS: float = 0.25

# Look
const BACKGROUND_COLOR: Color = Color(0.08, 0.01, 0.03, 0.88)  # the vampire's den stays visible
const VIGNETTE_COLOR: Color = Color(0.03, 0.0, 0.02, 0.55)
const RAIL_COLOR: Color = Color(0.85, 0.12, 0.2)
const RAIL_GLOW_THICKNESS: float = 12.0
const RAIL_HALO_THICKNESS: float = 6.0
const RAIL_CORE_THICKNESS: float = 3.0
const WALL_CAP: float = 1.5  # extends wall ends so corners join
const RAIL_PULSE_SECONDS: float = 1.8
const GLITTER_COLOR: Color = Color(1.0, 0.86, 0.72)
const DOT_RADIUS: float = 3.5
const PELLET_RADIUS: float = 8.0
const MOTE_COUNT: int = 16
const BAT_COLOR: Color = Color(0.4, 0.12, 0.22, 0.75)  # lighter than the dialogue's bats so they show on the dark den
const BURST_COUNT: int = 24
const BURST_SECONDS: float = 0.6
const SHAKE_PIXELS: float = 10.0
const SHAKE_STEPS: int = 6
const SHAKE_STEP_SECONDS: float = 0.04
const WIN_FONT_SIZE: int = 72
const WIN_SECONDS: float = 1.2
const RETRY_FADE_SECONDS: float = 0.5
const HELP_FONT_SIZE: int = 36
const HELP_WIDTH: float = 760.0
const HELP_PADDING: int = 36
const HELP_RADIUS: int = 24
const HELP_COLOR: Color = Color(0.05, 0.01, 0.03, 0.92)
const HELP_TEXT_COLOR: Color = Color(1.0, 0.93, 0.85)

var _open: Array = []  # [row][col] -> bool, whether that tile is part of a lane
var _dots: Dictionary = {}  # tile -> true for a big pellet, false for a plain dot
var _world: Control  # shaken on a hit
var _maze: Control  # tile coordinates are relative to this; centred on screen
var _glow: MazeGlow
var _dot_view: DotView
var _unicorn: TextureRect
var _unicorn_walker: Walker = Walker.new()
var _unicorn_tween: Tween
var _enemies: Array[Enemy] = []
var _wanted: Vector2i = Vector2i.ZERO  # the direction the player last asked for
var _hud: QuestHud
var _clock: float = 0.0
var _score: int = 0
var _hits: int = 0
var _hurt_left: float = 0.0
var _freeze_left: float = 0.0
var _scared_left: float = 0.0
var _level: int = 1
var _level_start_score: int = 0
var _best_score: int = 0
var _saved_best: int = 0  # what the file holds, so it is only rewritten after a new record
var _eaten: int = 0
var _total_dots: int = 0
var _fruits_spawned: int = 0
var _fruit_tile: Vector2i = NO_TILE
var _fruit_left: float = 0.0
var _banner: Label
var _help: PanelContainer  # the controls popup; the maze stays frozen while it is open
var _choices: HBoxContainer
var _hiss: AudioStreamPlayer
var _eat_player: AudioStreamPlayer
var _pellet_player: AudioStreamPlayer
var _gem_player: AudioStreamPlayer
var _eaten_combo: int = 0
var _chase_clock: float = 0.0
var _over: bool = false
var _shake_tween: Tween


## Something that travels along lanes, one tile at a time: from `from_tile` to `to_tile`, `progress` of the way.
class Walker:
	extends RefCounted
	signal arrived(tile: Vector2i)
	var from_tile: Vector2i = Vector2i.ZERO
	var to_tile: Vector2i = Vector2i.ZERO
	var progress: float = 0.0
	var heading: Vector2i = Vector2i.ZERO


class Enemy:
	extends Walker
	var sprite: TextureRect
	var mode: GlitterMaze.Mode = GlitterMaze.Mode.WAITING
	var wake_left: float = 0.0
	var speed: float = 4.0
	var index: int = 0
	var phase: float = 0.0


## The red lanes: a soft glow with a thin bright core.
class MazeGlow:
	extends Control
	var segments: Array[Array] = []  # [from, to] pairs in maze pixels

	func _draw() -> void:
		var glow := Color(GlitterMaze.RAIL_COLOR, GlitterMaze.RAIL_GLOW_ALPHA)
		var halo := Color(GlitterMaze.RAIL_COLOR, GlitterMaze.RAIL_HALO_ALPHA)
		var core := Color(GlitterMaze.RAIL_COLOR, GlitterMaze.RAIL_CORE_ALPHA)
		for segment in segments:
			draw_line(segment[0], segment[1], glow, GlitterMaze.RAIL_GLOW_THICKNESS, true)
			draw_line(segment[0], segment[1], halo, GlitterMaze.RAIL_HALO_THICKNESS, true)
			draw_line(segment[0], segment[1], core, GlitterMaze.RAIL_CORE_THICKNESS, true)


## The glitter dots; a pellet is bigger and pulses.
class DotView:
	extends Control
	var dots: Dictionary = {}
	var pulse: float = 0.0  # 0 to 1
	var fruit: Vector2i = GlitterMaze.NO_TILE

	func _draw() -> void:
		if fruit != GlitterMaze.NO_TILE:
			var at: Vector2 = (Vector2(fruit) + Vector2(0.5, 0.5)) * GlitterMaze.TILE
			var r: float = GlitterMaze.GEM_RADIUS + pulse * 2.0
			var half_width: float = r * GlitterMaze.GEM_WIDTH_RATIO
			draw_circle(at, r * GlitterMaze.GLOW_RADIUS_SCALE, Color(GlitterMaze.FRUIT_COLOR, 0.2))
			draw_colored_polygon(PackedVector2Array([at + Vector2(0, -r), at + Vector2(half_width, 0), at + Vector2(0, r), at + Vector2(-half_width, 0)]), GlitterMaze.FRUIT_COLOR)
		for tile in dots:
			var center: Vector2 = (Vector2(tile) + Vector2(0.5, 0.5)) * GlitterMaze.TILE
			var color: Color = GlitterMaze.GLITTER_COLOR
			if dots[tile]:
				var radius: float = GlitterMaze.PELLET_RADIUS + pulse * 2.5
				draw_circle(center, radius * GlitterMaze.GLOW_RADIUS_SCALE, Color(color, 0.18 + pulse * 0.1))
				draw_circle(center, radius, color)
			else:
				draw_circle(center, GlitterMaze.DOT_RADIUS * 2.2, Color(color, 0.16))
				draw_circle(center, GlitterMaze.DOT_RADIUS, color)


func _ready() -> void:
	super()
	clip_contents = true
	_dim_rest = BACKGROUND_COLOR
	_dim = _add_backdrop(BACKGROUND_COLOR)
	_add_vignette()
	_add_motes()
	var bats := BatFlock.new()
	bats.color = BAT_COLOR
	add_child(bats)

	_world = Control.new()
	_world.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_world.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_world)
	_maze = Control.new()
	_maze.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_world.add_child(_maze)

	_glow = MazeGlow.new()
	_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_maze.add_child(_glow)
	var pulse := create_tween().set_loops()
	pulse.tween_property(_glow, "modulate:a", 0.6, RAIL_PULSE_SECONDS / 2.0).set_trans(Tween.TRANS_SINE)
	pulse.tween_property(_glow, "modulate:a", 1.0, RAIL_PULSE_SECONDS / 2.0).set_trans(Tween.TRANS_SINE)
	_dot_view = DotView.new()
	_dot_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_maze.add_child(_dot_view)

	_unicorn = _make_unicorn()
	_hiss = _make_player(HISS_SOUND)
	_eat_player = _make_player(EAT_SOUND)
	_pellet_player = _make_player(PELLET_SOUND)
	_gem_player = _make_player(GEM_SOUND)
	_saved_best = _load_best()
	_best_score = _saved_best

	_hud = QuestHud.new(MAX_HITS)
	add_child(_hud)
	resized.connect(_center_maze)
	_center_maze()
	_start_round()
	_show_help()


func _make_player(stream: AudioStream) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.stream = stream
	add_child(player)
	return player


func _input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	if _help:
		return
	match key.physical_keycode:
		KEY_W, KEY_UP:
			_wanted = Vector2i.UP
		KEY_S, KEY_DOWN:
			_wanted = Vector2i.DOWN
		KEY_A, KEY_LEFT:
			_wanted = Vector2i.LEFT
		KEY_D, KEY_RIGHT:
			_wanted = Vector2i.RIGHT


func _gui_input(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	if _help and click != null and click.pressed and click.button_index == MOUSE_BUTTON_LEFT:
		_help.queue_free()
		_help = null
		accept_event()


func _process(delta: float) -> void:
	_dot_view.pulse = 0.5 + 0.5 * sin(Time.get_ticks_msec() / 1000.0 * PULSE_SPEED)
	_dot_view.queue_redraw()
	if _over or _help:
		return
	_clock += delta
	_chase_clock += delta
	_hurt_left = maxf(_hurt_left - delta, 0.0)
	if _freeze_left > 0.0:
		_freeze_left -= delta
		_sync_visuals(delta)
		return

	_move_unicorn(delta)
	_update_scare(delta)
	if _fruit_tile != NO_TILE:
		_fruit_left -= delta
		if _fruit_left <= 0.0:
			_clear_fruit()
	for enemy in _enemies:
		_move_enemy(enemy, delta)
	_check_catches()
	_sync_visuals(delta)


# --- Maze --------------------------------------------------------------------------------

## A random maze: a spanning tree of lanes, then dead ends and a few extra walls opened for loops.
func _generate_maze() -> void:
	_open = []
	for row in GRID_ROWS:
		var cells: Array[bool] = []
		cells.resize(GRID_COLS)
		cells.fill(false)
		_open.append(cells)

	var visited: Dictionary = {DEN_TILE: true}
	_open[DEN_TILE.y][DEN_TILE.x] = true
	var stack: Array[Vector2i] = [DEN_TILE]
	while not stack.is_empty():
		var tile: Vector2i = stack.back()
		var fresh: Array[Vector2i] = []
		for dir in DIRECTIONS:
			var next: Vector2i = tile + dir * 2
			if _in_grid(next) and not visited.has(next):
				fresh.append(next)
		if fresh.is_empty():
			stack.pop_back()
			continue
		var chosen: Vector2i = fresh.pick_random()
		_set_open(tile + (chosen - tile) / 2)
		_set_open(chosen)
		visited[chosen] = true
		stack.append(chosen)

	for row in range(0, GRID_ROWS, 2):
		for col in range(0, GRID_COLS, 2):
			var tile := Vector2i(col, row)
			if _open_neighbors(tile).size() == 1 and randf() < DEAD_END_OPEN_CHANCE:
				_knock_through(tile)
	for i in LEVEL_EXTRA_OPENINGS[_level - 1]:
		_knock_through(Vector2i(randi_range(0, NODE_COLS - 1) * 2, randi_range(0, NODE_ROWS - 1) * 2))


## Opens the wall between a node and a random neighbouring node, if it has a closed one.
func _knock_through(tile: Vector2i) -> void:
	var closed: Array[Vector2i] = []
	for dir in DIRECTIONS:
		if _in_grid(tile + dir * 2) and not _is_open(tile + dir):
			closed.append(dir)
	if not closed.is_empty():
		_set_open(tile + closed.pick_random())


func _set_open(tile: Vector2i) -> void:
	_open[tile.y][tile.x] = true


func _in_grid(tile: Vector2i) -> bool:
	return tile.x >= 0 and tile.y >= 0 and tile.x < GRID_COLS and tile.y < GRID_ROWS


func _is_open(tile: Vector2i) -> bool:
	return _in_grid(tile) and _open[tile.y][tile.x]


func _open_neighbors(tile: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for dir in DIRECTIONS:
		if _is_open(tile + dir):
			result.append(dir)
	return result


func _tile_center(tile: Vector2i) -> Vector2:
	return (Vector2(tile) + Vector2(0.5, 0.5)) * TILE


func _walker_position(walker: Walker) -> Vector2:
	return _tile_center(walker.from_tile).lerp(_tile_center(walker.to_tile), walker.progress)


## Wall lines along every side of a corridor tile that has no corridor next to it.
func _wall_segments(tile: Vector2i) -> Array[Array]:
	var walls: Array[Array] = []
	var origin := Vector2(tile) * TILE
	var corners: Dictionary = {
		Vector2i.UP: [Vector2(0, 0), Vector2(TILE, 0)],
		Vector2i.DOWN: [Vector2(0, TILE), Vector2(TILE, TILE)],
		Vector2i.LEFT: [Vector2(0, 0), Vector2(0, TILE)],
		Vector2i.RIGHT: [Vector2(TILE, 0), Vector2(TILE, TILE)],
	}
	for dir in corners:
		if _is_open(tile + dir):
			continue
		var edge: Array = corners[dir]
		var along: Vector2 = (edge[1] - edge[0]).normalized() * WALL_CAP
		walls.append([origin + edge[0] - along, origin + edge[1] + along])
	return walls


## Fills the lanes and the dots for a fresh maze.
func _build_maze() -> void:
	_generate_maze()
	var segments: Array[Array] = []
	_dots.clear()
	for row in GRID_ROWS:
		for col in GRID_COLS:
			var tile := Vector2i(col, row)
			if not _is_open(tile):
				continue
			_dots[tile] = false
			segments.append_array(_wall_segments(tile))
	_dots.erase(START_TILE)
	_dots.erase(DEN_TILE)
	for corner in [Vector2i(0, 0), Vector2i(GRID_COLS - 1, 0), Vector2i(0, GRID_ROWS - 1), Vector2i(GRID_COLS - 1, GRID_ROWS - 1)]:
		_dots[corner] = true
	_glow.segments = segments
	_glow.queue_redraw()
	_total_dots = _dots.size()
	_dot_view.dots = _dots
	_glow.size = Vector2(GRID_COLS, GRID_ROWS) * TILE
	_dot_view.size = _glow.size
	_maze.size = _glow.size


func _center_maze() -> void:
	_maze.position = ((size - Vector2(GRID_COLS, GRID_ROWS) * TILE) / 2.0).round()


# --- Actors ------------------------------------------------------------------------------

func _make_unicorn() -> TextureRect:
	var unicorn := TextureRect.new()
	unicorn.texture = UNICORN_TEXTURE
	unicorn.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	unicorn.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	unicorn.size = Vector2(UNICORN_HEIGHT * UNICORN_TEXTURE.get_width() / UNICORN_TEXTURE.get_height(), UNICORN_HEIGHT)
	unicorn.pivot_offset = unicorn.size / 2.0
	unicorn.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_maze.add_child(unicorn)
	_unicorn_walker.arrived.connect(_on_unicorn_arrived)
	return unicorn


func _make_enemy(index: int) -> Enemy:
	var enemy := Enemy.new()
	enemy.speed = TEETH_SPEEDS[index] * LEVEL_SPEED_SCALE[_level - 1]
	enemy.index = index
	enemy.phase = randf() * TAU
	enemy.sprite = TextureRect.new()
	enemy.sprite.texture = TEETH_TEXTURE
	enemy.sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	enemy.sprite.stretch_mode = TextureRect.STRETCH_SCALE
	enemy.sprite.size = TEETH_SIZE
	enemy.sprite.pivot_offset = TEETH_SIZE / 2.0
	enemy.sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_maze.add_child(enemy.sprite)
	return enemy


## Moves a walker along its lane; at every tile it asks `pick` which way to go next.
func _advance(walker: Walker, tiles_per_second: float, delta: float, pick: Callable) -> void:
	var remaining: float = tiles_per_second * delta
	while remaining > 0.0:
		if walker.from_tile == walker.to_tile:
			var dir: Vector2i = pick.call(walker)
			if dir == Vector2i.ZERO:
				return
			walker.heading = dir
			walker.to_tile = walker.from_tile + dir
			walker.progress = 0.0
		var step: float = minf(remaining, 1.0 - walker.progress)
		walker.progress += step
		remaining -= step
		if walker.progress >= 1.0:
			walker.from_tile = walker.to_tile
			walker.progress = 0.0
			walker.arrived.emit(walker.from_tile)


func _move_unicorn(delta: float) -> void:
	var walker := _unicorn_walker
	if _wanted != Vector2i.ZERO and _wanted == -walker.heading and walker.from_tile != walker.to_tile:
		var tile: Vector2i = walker.from_tile  # turning around mid-lane is allowed
		walker.from_tile = walker.to_tile
		walker.to_tile = tile
		walker.progress = 1.0 - walker.progress
		walker.heading = _wanted
	_advance(walker, UNICORN_SPEED, delta, _pick_unicorn_direction)


func _pick_unicorn_direction(walker: Walker) -> Vector2i:
	if _wanted != Vector2i.ZERO and _is_open(walker.from_tile + _wanted):
		return _wanted
	if walker.heading != Vector2i.ZERO and _is_open(walker.from_tile + walker.heading):
		return walker.heading
	return Vector2i.ZERO


func _unicorn_tile() -> Vector2i:
	return _unicorn_walker.from_tile if _unicorn_walker.progress < 0.5 else _unicorn_walker.to_tile


func _move_enemy(enemy: Enemy, delta: float) -> void:
	if enemy.mode == Mode.WAITING:
		enemy.wake_left -= delta
		if enemy.wake_left <= 0.0:
			enemy.mode = Mode.SCARED if _scared_left > 0.0 else Mode.ACTIVE
		return
	var speed: float = enemy.speed * (SCARED_SPEED_SCALE if enemy.mode == Mode.SCARED else 1.0)
	_advance(enemy, speed, delta, _pick_enemy_direction)


## True while the teeth are in a scatter phase and head for their own corners.
func _scattering() -> bool:
	return fmod(_chase_clock, LEVEL_SCATTER_SECONDS[_level - 1] + LEVEL_CHASE_SECONDS[_level - 1]) < LEVEL_SCATTER_SECONDS[_level - 1]


## The tile an enemy is aiming for: each one has its own personality, like the Pac-Man ghosts.
func _enemy_target(enemy: Enemy) -> Vector2i:
	var corners: Array[Vector2i] = [Vector2i(GRID_COLS - 1, 0), Vector2i(0, 0), Vector2i(0, GRID_ROWS - 1), Vector2i(GRID_COLS - 1, GRID_ROWS - 1)]
	var unicorn: Vector2i = _unicorn_tile()
	if _scattering():
		return corners[enemy.index % corners.size()]
	match enemy.index:
		1:
			return unicorn + _unicorn_walker.heading * AMBUSH_TILES
		2:
			if Vector2(enemy.from_tile - unicorn).length() < SHY_DISTANCE:
				return corners[2]
		3:
			return unicorn - _unicorn_walker.heading * AMBUSH_TILES  # cuts him off from behind
	return unicorn


## At a junction an enemy never turns back unless it is in a dead end. It takes the step that
## ends closest to its target tile (farthest from the unicorn when scared, which wanders).
func _pick_enemy_direction(walker: Walker) -> Vector2i:
	var enemy := walker as Enemy
	var options: Array[Vector2i] = []
	for dir in _open_neighbors(enemy.from_tile):
		if dir != -enemy.heading:
			options.append(dir)
	if options.is_empty():
		return -enemy.heading
	if enemy.mode == Mode.SCARED:
		return options.pick_random()
	var target: Vector2i = _enemy_target(enemy)
	var best: Vector2i = options[0]
	var best_distance: float = INF
	for dir in options:
		var distance: float = Vector2(enemy.from_tile + dir - target).length_squared()
		if distance < best_distance:
			best = dir
			best_distance = distance
	return best


func _send_to_den(enemy: Enemy, wake_seconds: float) -> void:
	enemy.from_tile = DEN_TILE
	enemy.to_tile = DEN_TILE
	enemy.progress = 0.0
	enemy.heading = Vector2i.ZERO
	enemy.mode = Mode.WAITING
	enemy.wake_left = wake_seconds


func _place_actors() -> void:
	_unicorn_walker.from_tile = START_TILE
	_unicorn_walker.to_tile = START_TILE
	_unicorn_walker.progress = 0.0
	_unicorn_walker.heading = Vector2i.ZERO
	_wanted = Vector2i.ZERO
	_scared_left = 0.0
	_chase_clock = 0.0
	for i in _enemies.size():
		_send_to_den(_enemies[i], TEETH_WAKE_SECONDS[i])
	_sync_visuals(0.0)


func _sync_visuals(delta: float) -> void:
	var unicorn_center: Vector2 = _walker_position(_unicorn_walker)
	_unicorn.position = unicorn_center - _unicorn.size / 2.0
	var heading: Vector2i = _unicorn_walker.heading
	if heading.x != 0:
		_unicorn.flip_h = heading.x < 0
	var tilt: float = float(heading.y) * UNICORN_TILT * (-1.0 if _unicorn.flip_h else 1.0)
	_unicorn.rotation = lerpf(_unicorn.rotation, tilt, minf(UNICORN_TILT_SPEED * delta, 1.0))

	for enemy in _enemies:
		var sprite: TextureRect = enemy.sprite
		sprite.position = _walker_position(enemy) - TEETH_SIZE / 2.0
		var jaw: float = absf(sin(_clock * CHOMP_SPEED + enemy.phase))
		sprite.scale.y = lerpf(CHOMP_CLOSED_SCALE, CHOMP_OPEN_SCALE, jaw)
		sprite.modulate = _enemy_tint(enemy)


func _enemy_tint(enemy: Enemy) -> Color:
	match enemy.mode:
		Mode.WAITING:
			return Color(1.0, 1.0, 1.0, WAITING_ALPHA)
		Mode.SCARED:
			var ending: bool = _scared_left < SCARED_FLASH_SECONDS
			if ending and int(_scared_left / SCARED_FLASH_INTERVAL) % 2 == 0:
				return Color.WHITE
			return SCARED_COLOR
	return Color.WHITE


# --- Eating and catching -----------------------------------------------------------------

func _on_unicorn_arrived(tile: Vector2i) -> void:
	if tile == _fruit_tile:
		_eat_fruit()
	if not _dots.has(tile):
		return
	_eaten += 1
	_maybe_spawn_fruit()
	var pellet: bool = _dots[tile]
	if pellet:
		_pellet_player.play()
	else:
		_eat_player.play()  # restarts on every dot, so a run of glitter chimes rather than overlaps
	_dots.erase(tile)
	_score += PELLET_SCORE if pellet else DOT_SCORE
	_update_progress()
	_chomp()
	if pellet:
		_scare_enemies()
		_burst(_tile_center(tile), GLITTER_COLOR, BURST_COUNT / 2)
	if _dots.is_empty():
		_win()


func _maybe_spawn_fruit() -> void:
	if _fruits_spawned >= FRUIT_AT.size() or _fruit_tile != NO_TILE:
		return
	if _eaten < int(_total_dots * FRUIT_AT[_fruits_spawned]):
		return
	_fruits_spawned += 1
	var tiles: Array[Vector2i] = []
	for row in GRID_ROWS:
		for col in GRID_COLS:
			var tile := Vector2i(col, row)
			if _is_open(tile) and tile != DEN_TILE and tile != START_TILE and tile != _unicorn_tile():
				tiles.append(tile)
	_fruit_tile = tiles.pick_random()
	_fruit_left = FRUIT_SECONDS
	_dot_view.fruit = _fruit_tile


func _eat_fruit() -> void:
	_gem_player.play()
	_score += FRUIT_SCORE * _level
	_burst(_tile_center(_fruit_tile), FRUIT_COLOR, BURST_COUNT / 2)
	_clear_fruit()
	_update_progress()
	_chomp()


func _clear_fruit() -> void:
	_fruit_tile = NO_TILE
	_dot_view.fruit = NO_TILE


func _chomp() -> void:
	if _unicorn_tween:
		_unicorn_tween.kill()
	_unicorn_tween = create_tween()
	_unicorn_tween.tween_property(_unicorn, "scale", Vector2.ONE * CHOMP_PULSE, CHOMP_PULSE_SECONDS / 2.0)
	_unicorn_tween.tween_property(_unicorn, "scale", Vector2.ONE, CHOMP_PULSE_SECONDS / 2.0)


func _scare_enemies() -> void:
	_scared_left = LEVEL_SCARED_SECONDS[_level - 1]
	_eaten_combo = 0
	for enemy in _enemies:
		if enemy.mode == Mode.ACTIVE:
			enemy.mode = Mode.SCARED
			_turn_around(enemy)


func _turn_around(enemy: Enemy) -> void:
	if enemy.from_tile == enemy.to_tile:
		return
	var tile: Vector2i = enemy.from_tile
	enemy.from_tile = enemy.to_tile
	enemy.to_tile = tile
	enemy.progress = 1.0 - enemy.progress
	enemy.heading = -enemy.heading


func _update_scare(delta: float) -> void:
	if _scared_left <= 0.0:
		return
	_scared_left -= delta
	if _scared_left <= 0.0:
		for enemy in _enemies:
			if enemy.mode == Mode.SCARED:
				enemy.mode = Mode.ACTIVE


func _check_catches() -> void:
	var unicorn_center: Vector2 = _walker_position(_unicorn_walker)
	for enemy in _enemies:
		if enemy.mode == Mode.WAITING:
			continue
		if _walker_position(enemy).distance_to(unicorn_center) > CATCH_DISTANCE:
			continue
		if enemy.mode == Mode.SCARED:
			_eat_enemy(enemy)
		elif _hurt_left <= 0.0:
			_on_hit(enemy)
			return


func _eat_enemy(enemy: Enemy) -> void:
	_score += ENEMY_SCORE << _eaten_combo
	_eaten_combo += 1
	_update_progress()
	_burst(_walker_position(enemy), SCARED_COLOR, BURST_COUNT)
	_chomp()
	_send_to_den(enemy, RESPAWN_SECONDS)


# --- Hits, win and retry -----------------------------------------------------------------

## The teeth that caught him pulse and vanish, the unicorn loses a heart, and everybody goes home.
func _on_hit(enemy: Enemy) -> void:
	_hits += 1
	_hud.lose_heart(_hits - 1)
	_flash_miss()
	_shake()
	_burst(_walker_position(_unicorn_walker), Color(0.85, 0.1, 0.15), BURST_COUNT)
	_vanish_copy(enemy)
	_hiss.play()
	if _hits >= MAX_HITS:
		_over = true
		_save_best()
		_offer_retry()
		if _level > 1:
			_show_choices(false)
		_retry_button.modulate.a = 0.0
		create_tween().tween_property(_retry_button, "modulate:a", 1.0, RETRY_FADE_SECONDS)
		return
	_hurt_left = HURT_SECONDS
	_freeze_left = HURT_FREEZE_SECONDS
	_place_actors()
	_blink_unicorn()


## A stand-in for the catching teeth that pulses and fades while the real ones go back to the den.
func _vanish_copy(enemy: Enemy) -> void:
	var copy: TextureRect = enemy.sprite.duplicate()
	copy.modulate = Color.WHITE
	copy.texture = TEETH_BLOODY_TEXTURE
	copy.scale = Vector2.ONE
	_maze.add_child(copy)
	var tween := create_tween()
	for i in VANISH_PULSE_COUNT:
		tween.tween_property(copy, "scale", Vector2.ONE * VANISH_PULSE_SCALE, VANISH_PULSE_SECONDS / 2.0)
		tween.tween_property(copy, "scale", Vector2.ONE, VANISH_PULSE_SECONDS / 2.0)
	tween.tween_property(copy, "modulate:a", 0.0, VANISH_FADE_SECONDS)
	tween.tween_callback(copy.queue_free)


func _shake() -> void:
	if _shake_tween:
		_shake_tween.kill()
	_shake_tween = create_tween()
	for i in SHAKE_STEPS:
		var strength: float = SHAKE_PIXELS * (1.0 - float(i) / SHAKE_STEPS)
		_shake_tween.tween_property(_world, "position", Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * strength, SHAKE_STEP_SECONDS)
	_shake_tween.tween_property(_world, "position", Vector2.ZERO, SHAKE_STEP_SECONDS)


## A puff of particles at a point in the maze.
func _burst(at: Vector2, color: Color, count: int) -> void:
	var burst := CPUParticles2D.new()
	burst.position = at
	burst.emitting = true
	burst.one_shot = true
	burst.explosiveness = 1.0
	burst.amount = count
	burst.lifetime = BURST_SECONDS
	burst.direction = Vector2.UP
	burst.spread = 180.0
	burst.gravity = Vector2.ZERO
	burst.initial_velocity_min = 80.0
	burst.initial_velocity_max = 260.0
	burst.scale_amount_min = 3.0
	burst.scale_amount_max = 7.0
	burst.color = color
	_maze.add_child(burst)
	get_tree().create_timer(BURST_SECONDS + 0.2).timeout.connect(burst.queue_free)


## The unicorn flashes red, then blinks for the rest of the grace period.
func _blink_unicorn() -> void:
	var tween := create_tween()
	tween.tween_property(_unicorn, "modulate", Color(1.0, 0.3, 0.3), 0.05)
	tween.tween_property(_unicorn, "modulate", Color.WHITE, 0.1)
	var blinks: int = int(HURT_SECONDS / (HURT_BLINK_SECONDS * 2.0))
	for i in blinks:
		tween.tween_property(_unicorn, "modulate:a", 0.35, HURT_BLINK_SECONDS)
		tween.tween_property(_unicorn, "modulate:a", 1.0, HURT_BLINK_SECONDS)


func _win() -> void:
	_over = true
	_clear_fruit()
	_save_best()
	_show_banner(Localization.t("ui.maze-win"))
	var tween := create_tween()
	tween.tween_interval(WIN_SECONDS)
	tween.tween_callback(_show_choices.bind(_level < LEVEL_COUNT))


## Explains the controls and the blue-fang rule; a click closes it and the game begins.
func _show_help() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = HELP_COLOR
	style.set_corner_radius_all(HELP_RADIUS)
	style.set_content_margin_all(HELP_PADDING)
	_help = PanelContainer.new()
	_help.add_theme_stylebox_override("panel", style)
	_help.set_anchors_preset(Control.PRESET_CENTER)
	_help.custom_minimum_size.x = HELP_WIDTH
	_help.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_help.grow_vertical = Control.GROW_DIRECTION_BOTH
	_help.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var label := Label.new()
	label.text = Localization.t("ui.maze-controls") + "\n\n" + Localization.t("ui.click-to-continue")
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", GameState.STORY_FONT)
	label.add_theme_font_size_override("font_size", HELP_FONT_SIZE)
	label.add_theme_color_override("font_color", HELP_TEXT_COLOR)
	_help.add_child(label)
	add_child(_help)


## The big centred text that pops in; `intro` banners fade out on their own.
func _show_banner(text: String, intro: bool = false) -> void:
	if _banner:
		_banner.queue_free()
	var label := Label.new()
	_banner = label
	label.text = text
	label.add_theme_font_override("font", GameState.STORY_FONT)
	label.add_theme_font_size_override("font_size", WIN_FONT_SIZE)
	label.add_theme_color_override("font_color", QuestHud.VALUE_COLOR)
	label.add_theme_color_override("font_outline_color", QuestHud.VALUE_OUTLINE_COLOR)
	label.add_theme_constant_override("outline_size", QuestHud.VALUE_OUTLINE_SIZE)
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.pivot_offset = size / 2.0
	label.scale = Vector2.ZERO
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	var tween := create_tween()
	tween.tween_property(label, "scale", Vector2.ONE, BANNER_IN_SECONDS).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if intro:
		tween.tween_interval(LEVEL_INTRO_SECONDS - BANNER_IN_SECONDS - BANNER_OUT_SECONDS)
		tween.tween_property(label, "modulate:a", 0.0, BANNER_OUT_SECONDS)
		tween.tween_callback(label.queue_free)


## The buttons at the bottom: back to the conversation, and optionally the next level.
func _show_choices(next_level: bool) -> void:
	_hide_choices()
	_choices = HBoxContainer.new()
	_choices.add_theme_constant_override("separation", int(CHOICE_GAP))
	_choices.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_choices.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_choices.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_choices.offset_bottom = -CHOICE_BOTTOM_MARGIN
	var proceed := Button.new()
	proceed.text = Localization.t("ui.maze-continue")
	MenuButtonStyle.apply(proceed, RETRY_FONT_SIZE)
	proceed.pressed.connect(func() -> void:
		proceed.disabled = true  # a double click must not finish the quest twice
		won.emit())
	_choices.add_child(proceed)
	if next_level:
		var next := Button.new()
		next.text = Localization.t("ui.maze-level") % (_level + 1)
		MenuButtonStyle.apply(next, RETRY_FONT_SIZE)
		next.pressed.connect(_start_level.bind(_level + 1))
		_choices.add_child(next)
	add_child(_choices)


func _hide_choices() -> void:
	if _choices:
		_choices.queue_free()
		_choices = null


func _on_retry() -> void:
	_start_round()


func _start_level(level: int) -> void:
	_level = level
	_level_start_score = _score
	_start_round()
	_show_banner(Localization.t("ui.maze-level") % _level, true)
	_freeze_left = LEVEL_INTRO_SECONDS


func _start_round() -> void:
	_hud.refill_hearts()
	_hide_retry()
	_hide_choices()
	if _banner:
		_banner.queue_free()
		_banner = null
	_hits = 0
	_score = _level_start_score
	_eaten = 0
	_fruits_spawned = 0
	_clear_fruit()
	_clock = 0.0
	_hurt_left = 0.0
	_freeze_left = 0.0
	_unicorn.modulate = Color.WHITE
	for enemy in _enemies:
		enemy.sprite.queue_free()
	_enemies.clear()
	for i in LEVEL_TEETH[_level - 1]:
		_enemies.append(_make_enemy(i))
	_build_maze()
	_place_actors()
	_update_progress()
	_over = false


func _update_progress() -> void:
	_best_score = maxi(_best_score, _score)
	_hud.set_value(Localization.t("ui.maze-hud") % [_level, _score, _best_score])


func _load_best() -> int:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return 0
	return int(config.get_value("maze", "best", 0))


func _save_best() -> void:
	if _best_score <= _saved_best:
		return
	var config := ConfigFile.new()
	config.set_value("maze", "best", _best_score)
	if config.save(SAVE_PATH) != OK:
		push_warning("GlitterMaze: could not save the best score to %s." % SAVE_PATH)
		return
	_saved_best = _best_score


func _exit_tree() -> void:
	_save_best()


# --- Scenery -----------------------------------------------------------------------------

func _add_vignette() -> void:
	var gradient := Gradient.new()
	gradient.set_color(0, Color(VIGNETTE_COLOR, 0.0))
	gradient.set_color(1, VIGNETTE_COLOR)
	gradient.add_point(0.55, Color(VIGNETTE_COLOR, 0.0))
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	var vignette := TextureRect.new()
	vignette.texture = texture
	vignette.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	vignette.stretch_mode = TextureRect.STRETCH_SCALE
	vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(vignette)


## Slow red specks drifting upward.
func _add_motes() -> void:
	var motes := CPUParticles2D.new()
	motes.position = size / 2.0
	motes.amount = MOTE_COUNT
	motes.lifetime = 8.0
	motes.preprocess = 8.0
	motes.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	motes.emission_rect_extents = size / 2.0
	motes.direction = Vector2.UP
	motes.spread = 25.0
	motes.gravity = Vector2.ZERO
	motes.initial_velocity_min = 8.0
	motes.initial_velocity_max = 28.0
	motes.scale_amount_min = 1.5
	motes.scale_amount_max = 4.0
	motes.color = Color(0.9, 0.2, 0.25, 0.35)
	add_child(motes)
