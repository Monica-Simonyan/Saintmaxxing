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

# --- Unicorn ---
const MAX_HITS: int = 3
const UNICORN_SPEED: float = 5.2  # tiles per second
const UNICORN_HEIGHT: float = 62.0
const UNICORN_TILT: float = 0.3  # radians when running up or down
const UNICORN_TILT_SPEED: float = 12.0
const CHOMP_SPEED: float = 14.0
const CHOMP_CLOSED_SCALE: float = 0.8
const CHOMP_OPEN_SCALE: float = 1.15
const CHOMP_PULSE: float = 1.12
const CHOMP_PULSE_SECONDS: float = 0.1
const HURT_SECONDS: float = 1.6  # the unicorn blinks and can't be caught after a reset
const HURT_FREEZE_SECONDS: float = 0.9
const HURT_BLINK_SECONDS: float = 0.07

# --- Teeth ---
const TEETH_SIZE: Vector2 = Vector2(54, 32)  # the picture is about 1.7 times wider than tall
const TEETH_SPEEDS: Array[float] = [4.3, 4.0, 3.7, 3.9]  # tiles per second, one entry per enemy
const TEETH_WAKE_SECONDS: Array[float] = [1.5, 4.0, 7.0, 9.5]
const AMBUSH_TILES: int = 3  # the ambusher aims this many tiles ahead of the unicorn
const SHY_DISTANCE: float = 5.0  # the shy one retreats to its corner when closer than this many tiles
const CATCH_DISTANCE: float = 30.0
const RESPAWN_SECONDS: float = 3.0
const SCARED_SPEED_SCALE: float = 0.6
const SCARED_FLASH_SECONDS: float = 1.5
const SCARED_FLASH_INTERVAL: float = 0.15
const SCARED_COLOR: Color = Color(0.5, 0.7, 1.6)
const WAITING_ALPHA: float = 0.45

# Levels 1 to 4; every list has one entry per level. Level 1 is the quest, the rest are optional.
const LEVEL_COUNT: int = 4
const LEVEL_TEETH: Array[int] = [3, 3, 4, 4]
const LEVEL_SPEED_SCALE: Array[float] = [1.0, 1.07, 1.14, 1.2]
const LEVEL_SCARED_SECONDS: Array[float] = [6.0, 5.0, 4.0, 3.0]
const LEVEL_SCATTER_SECONDS: Array[float] = [6.0, 5.0, 4.0, 3.0]  # the teeth give up the chase for a while, as in Pac-Man
const LEVEL_CHASE_SECONDS: Array[float] = [18.0, 22.0, 26.0, 30.0]
const LEVEL_EXTRA_OPENINGS: Array[int] = [14, 11, 8, 5]  # fewer loops make the maze harder to escape
const LEVEL_INTRO_SECONDS: float = 1.4

# --- Scoring, gem and feedback ---
const DOT_SCORE: int = 10
const PELLET_SCORE: int = 50
const ENEMY_SCORE: int = 200  # doubles for every enemy eaten with the same pellet
const FRUIT_AT: Array[float] = [0.35, 0.7]  # share of the dots eaten when a gem appears
const FRUIT_SECONDS: float = 9.0
const FRUIT_SCORE: int = 100  # times the level
const HUD_STRIP_HEIGHT: float = 64.0  # keeps the hearts, score and back button clear of the maze
const BOTTOM_MARGIN: float = 14.0
const NO_TILE: Vector2i = Vector2i(-1, -1)
const SAVE_PATH: String = "user://glitter_maze.cfg"
const VANISH_PULSE_SCALE: float = 1.35
const VANISH_PULSE_SECONDS: float = 0.18
const VANISH_PULSE_COUNT: int = 2
const VANISH_FADE_SECONDS: float = 0.25
const BANNER_IN_SECONDS: float = 0.35
const BANNER_OUT_SECONDS: float = 0.3

# --- Look ---
const BACKGROUND_COLOR: Color = Color(0.08, 0.01, 0.03, 0.88)  # the vampire's den stays visible
const VIGNETTE_COLOR: Color = Color(0.03, 0.0, 0.02, 0.55)
const RAIL_PULSE_SECONDS: float = 1.8
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
const HIT_COLOR: Color = Color(0.85, 0.1, 0.15)
const HIT_FLASH_COLOR: Color = Color(1.0, 0.3, 0.3)
const HIT_FLASH_SECONDS: float = 0.05
const HIT_FADE_SECONDS: float = 0.1
const BLINK_ALPHA: float = 0.35
const BURST_SPEED_RANGE: Vector2 = Vector2(80.0, 260.0)
const BURST_SIZE_RANGE: Vector2 = Vector2(3.0, 7.0)
const MOTE_SECONDS: float = 8.0
const MOTE_SPEED_RANGE: Vector2 = Vector2(8.0, 28.0)
const MOTE_SIZE_RANGE: Vector2 = Vector2(1.5, 4.0)
const MOTE_COLOR: Color = Color(0.9, 0.2, 0.25, 0.35)
const HELP_FONT_SIZE: int = 36
const HELP_WIDTH: float = 760.0
const HELP_PADDING: int = 36
const HELP_RADIUS: int = 24
const HELP_COLOR: Color = Color(0.05, 0.01, 0.03, 0.92)
const HELP_TEXT_COLOR: Color = Color(1.0, 0.93, 0.85)

var _grid := MazeGrid.new()
var _dots: Dictionary = {}  # tile -> true for a big pellet, false for a plain dot
var _world: Control  # shaken on a hit
var _maze: Control  # tile coordinates are relative to this; scaled to fill the screen below the HUD
var _glow: MazeGlow
var _dot_view: MazeDots
var _pulse_view: MazePulse
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
	_build_world()
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
	_level = mini(_cleared_level() + 1, LEVEL_COUNT)  # the hint icon continues where the player left off
	_start_round()
	if _level == 1:
		_show_help()
	else:
		_announce_level()


## The shakeable world: pulsing rails, dots, pellets and the unicorn, all inside the scaled maze.
func _build_world() -> void:
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
	_dot_view = MazeDots.new()
	_dot_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_maze.add_child(_dot_view)
	_pulse_view = MazePulse.new()
	_pulse_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_maze.add_child(_pulse_view)

	_unicorn = _make_unicorn()


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

func _walker_position(walker: Walker) -> Vector2:
	return MazeGrid.tile_center(walker.from_tile).lerp(MazeGrid.tile_center(walker.to_tile), walker.progress)


## Builds a fresh maze with its lanes and dots.
func _build_maze() -> void:
	_grid.generate(LEVEL_EXTRA_OPENINGS[_level - 1])
	_dots.clear()
	var pellets: Array[Vector2i] = MazeGrid.corners()
	var plain: Array[Vector2i] = []
	for tile in _grid.open_tiles():
		if tile == MazeGrid.START_TILE or tile == MazeGrid.DEN_TILE:
			continue
		var is_pellet: bool = tile in pellets
		_dots[tile] = is_pellet
		if not is_pellet:
			plain.append(tile)
	_total_dots = _dots.size()
	_glow.build(_grid)
	_dot_view.set_tiles(plain)
	_pulse_view.set_pellets(pellets.duplicate())
	_maze.size = MazeGrid.pixel_size()


## Scales the maze to the largest size that fits below the HUD strip and centres it.
func _center_maze() -> void:
	var maze_size: Vector2 = MazeGrid.pixel_size()
	var free := Vector2(size.x, size.y - HUD_STRIP_HEIGHT - BOTTOM_MARGIN)
	var fit: float = minf(free.x / maze_size.x, free.y / maze_size.y)
	_maze.scale = Vector2(fit, fit)
	_maze.position = (Vector2(0.0, HUD_STRIP_HEIGHT) + (free - maze_size * fit) / 2.0).round()


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
	if _wanted != Vector2i.ZERO and _grid.is_open(walker.from_tile + _wanted):
		return _wanted
	if walker.heading != Vector2i.ZERO and _grid.is_open(walker.from_tile + walker.heading):
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
	var corners: Array[Vector2i] = MazeGrid.corners()
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
	for dir in _grid.open_directions(enemy.from_tile):
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
	enemy.from_tile = MazeGrid.DEN_TILE
	enemy.to_tile = MazeGrid.DEN_TILE
	enemy.progress = 0.0
	enemy.heading = Vector2i.ZERO
	enemy.mode = Mode.WAITING
	enemy.wake_left = wake_seconds


func _place_actors() -> void:
	_unicorn_walker.from_tile = MazeGrid.START_TILE
	_unicorn_walker.to_tile = MazeGrid.START_TILE
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
	if pellet:
		_pulse_view.remove_pellet(tile)
	else:
		_dot_view.remove_tile(tile)
	_score += PELLET_SCORE if pellet else DOT_SCORE
	_update_progress()
	_chomp()
	if pellet:
		_scare_enemies()
		_burst(MazeGrid.tile_center(tile), MazeDots.GLITTER_COLOR, BURST_COUNT / 2)
	if _dots.is_empty():
		_win()


func _maybe_spawn_fruit() -> void:
	if _fruits_spawned >= FRUIT_AT.size() or _fruit_tile != NO_TILE:
		return
	if _eaten < int(_total_dots * FRUIT_AT[_fruits_spawned]):
		return
	_fruits_spawned += 1
	var tiles: Array[Vector2i] = _grid.open_tiles().filter(func(tile: Vector2i) -> bool:
		return tile != MazeGrid.DEN_TILE and tile != MazeGrid.START_TILE and tile != _unicorn_tile())
	_fruit_tile = tiles.pick_random()
	_fruit_left = FRUIT_SECONDS
	_pulse_view.show_gem(_fruit_tile)


func _eat_fruit() -> void:
	_gem_player.play()
	_score += FRUIT_SCORE * _level
	_burst(MazeGrid.tile_center(_fruit_tile), MazePulse.GEM_COLOR, BURST_COUNT / 2)
	_clear_fruit()
	_update_progress()
	_chomp()


func _clear_fruit() -> void:
	_fruit_tile = NO_TILE
	_pulse_view.hide_gem()


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
	_burst(_walker_position(_unicorn_walker), HIT_COLOR, BURST_COUNT)
	_vanish_copy(enemy)
	_hiss.play()
	if _hits >= MAX_HITS:
		_over = true
		_save_best()
		if _level > 1:
			_offer_finish([{"text": Localization.t("ui.retry"), "action": _start_round}, _continue_option()])
		else:
			_offer_retry()
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
	burst.initial_velocity_min = BURST_SPEED_RANGE.x
	burst.initial_velocity_max = BURST_SPEED_RANGE.y
	burst.scale_amount_min = BURST_SIZE_RANGE.x
	burst.scale_amount_max = BURST_SIZE_RANGE.y
	burst.color = color
	_maze.add_child(burst)
	get_tree().create_timer(BURST_SECONDS + 0.2).timeout.connect(burst.queue_free)


## The unicorn flashes red, then blinks for the rest of the grace period.
func _blink_unicorn() -> void:
	var tween := create_tween()
	tween.tween_property(_unicorn, "modulate", HIT_FLASH_COLOR, HIT_FLASH_SECONDS)
	tween.tween_property(_unicorn, "modulate", Color.WHITE, HIT_FADE_SECONDS)
	var blinks: int = int(HURT_SECONDS / (HURT_BLINK_SECONDS * 2.0))
	for i in blinks:
		tween.tween_property(_unicorn, "modulate:a", BLINK_ALPHA, HURT_BLINK_SECONDS)
		tween.tween_property(_unicorn, "modulate:a", 1.0, HURT_BLINK_SECONDS)


func _win() -> void:
	_over = true
	GameState.quest_levels[GameState.selected_character_id] = maxi(_cleared_level(), _level)
	_clear_fruit()
	_save_best()
	_show_banner(Localization.t("ui.maze-win"))
	var tween := create_tween()
	tween.tween_interval(WIN_SECONDS)
	tween.tween_callback(_offer_next_steps)


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


## After a cleared level: the next level if there is one, and back to the conversation.
func _offer_next_steps() -> void:
	var options: Array[Dictionary] = []
	if _level < LEVEL_COUNT:
		options.append({"text": Localization.t("ui.maze-level") % (_level + 1), "action": _start_level.bind(_level + 1)})
	options.append(_continue_option())
	_offer_finish(options)


func _cleared_level() -> int:
	return GameState.quest_levels.get(GameState.selected_character_id, 0)


func _start_level(level: int) -> void:
	_level = level
	_level_start_score = _score
	_start_round()
	_announce_level()


func _announce_level() -> void:
	_show_banner(Localization.t("ui.maze-level") % _level, true)
	_freeze_left = LEVEL_INTRO_SECONDS


func _start_round() -> void:
	_hud.refill_hearts()
	_hide_retry()
	_hide_finish()
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
	motes.lifetime = MOTE_SECONDS
	motes.preprocess = MOTE_SECONDS
	motes.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	motes.emission_rect_extents = size / 2.0
	motes.direction = Vector2.UP
	motes.spread = 25.0
	motes.gravity = Vector2.ZERO
	motes.initial_velocity_min = MOTE_SPEED_RANGE.x
	motes.initial_velocity_max = MOTE_SPEED_RANGE.y
	motes.scale_amount_min = MOTE_SIZE_RANGE.x
	motes.scale_amount_max = MOTE_SIZE_RANGE.y
	motes.color = MOTE_COLOR
	add_child(motes)
