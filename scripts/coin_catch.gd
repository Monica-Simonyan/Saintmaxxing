class_name CoinCatch
extends QuestOverlay

## Hint mini-game laid over a dialogue: after a click-to-start screen, coins fall from random spots and a sack, moved with
## A/D or the arrow keys, catches them. Each catch plays a sound and raises the count.
## A fixed number of coins fall; the third miss ends the round with a retry button,
## letting every coin pass with fewer misses wins.

const COIN_TEXTURE: Texture2D = preload("res://assets/minigame/coin.png")
const SACK_TEXTURE: Texture2D = preload("res://assets/minigame/sack.png")
const CATCH_SOUND: AudioStream = preload("res://assets/audio/coin_catch.mp3")
const COIN_SIZE: float = 56.0
const SACK_SIZE: Vector2 = Vector2(150, 150)
const SACK_SPEED: float = 650.0
const SACK_BOTTOM_MARGIN: float = 10.0
const SPAWN_Y: float = -COIN_SIZE  # coins enter from above the screen
const INTRO_FONT_SIZE: int = 40
const TOTAL_COINS: int = 30
const MAX_MISSES: int = 3
const SPAWN_GAP_MIN: float = 1.0
const SPAWN_GAP_MAX: float = 2.2
const FALL_TIME_MIN: float = 1.6  # seconds a coin needs to cross the whole screen
const FALL_TIME_MAX: float = 4.0
# Some coins fall slowly, then speed up part-way down.
const BOOST_CHANCE: float = 0.35
const BOOST_MIN: float = 1.8
const BOOST_MAX: float = 2.6
const BOOST_START_MIN: float = 0.3  # share of the screen crossed before the speed-up
const BOOST_START_MAX: float = 0.6
# Winnability: a coin is only scheduled if the sack can reach it after the previous catch,
# at SACK_SPEED * REACH_SLACK, plus a human REACTION_TIME.
const REACTION_TIME: float = 0.3
const REACH_SLACK: float = 0.95
const MOUTH_MARGIN: float = 0.1  # fraction of the sack width ignored on each side of its opening
const MOUTH_DEPTH: float = 0.45  # fraction of the sack height, from its top, that counts as the opening

var count: int = 0
var _coins: Array[TextureRect] = []
var _falls: Dictionary = {}  # coin -> {speed: px/s, boost_y: y where it speeds up, boost: speed multiplier}
var _spawn_timer: float = 0.0
var _clock: float = 0.0
var _last_catch_time: float = 0.0  # when the most recently spawned coin will reach the sack
var _last_catch_x: float = 0.0  # ...and its centre x
var _spawned: int = 0
var _misses: int = 0
var _over: bool = false
var _sack: TextureRect
var _hud: QuestHud
var _intro: Label
var _waiting: bool = true  # until the player's first click
var _sound: AudioStreamPlayer


func _ready() -> void:
	super()
	clip_contents = true
	_dim = _add_backdrop(DIM_COLOR)

	_sack = TextureRect.new()
	_sack.texture = SACK_TEXTURE
	_sack.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_sack.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_sack.size = SACK_SIZE
	_sack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_sack)
	_place_sack(size.x / 2.0 - SACK_SIZE.x / 2.0)

	_intro = Label.new()
	_intro.text = Localization.t("ui.coin-controls") + "\n\n" + Localization.t("ui.click-to-continue")
	_intro.add_theme_font_override("font", GameState.STORY_FONT)
	_intro.add_theme_font_size_override("font_size", INTRO_FONT_SIZE)
	_intro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_intro.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_intro.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_intro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_intro)

	_hud = QuestHud.new(MAX_MISSES)
	add_child(_hud)

	_sound = AudioStreamPlayer.new()
	_sound.stream = CATCH_SOUND
	add_child(_sound)

	_start_round()


func _gui_input(event: InputEvent) -> void:
	if _waiting and event is InputEventMouseButton and event.pressed:
		_waiting = false
		_intro.hide()
		accept_event()


func _process(delta: float) -> void:
	if _waiting:
		return
	var direction: float = 0.0
	if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT):
		direction -= 1.0
	if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT):
		direction += 1.0
	_place_sack(_sack.position.x + direction * SACK_SPEED * delta)

	if _over:
		return
	_clock += delta
	if _spawned < TOTAL_COINS:
		_spawn_timer -= delta
		if _spawn_timer <= 0.0:
			_schedule_next_coin()
			_spawn_coin()

	var mouth := Rect2(_sack.position + Vector2(SACK_SIZE.x * MOUTH_MARGIN, 0.0), Vector2(SACK_SIZE.x * (1.0 - 2.0 * MOUTH_MARGIN), SACK_SIZE.y * MOUTH_DEPTH))
	for coin in _coins.duplicate():
		var fall: Dictionary = _falls[coin]
		var boosted: bool = coin.position.y >= fall.boost_y
		coin.position.y += fall.speed * (fall.boost if boosted else 1.0) * delta
		if mouth.has_point(coin.position + Vector2(COIN_SIZE, COIN_SIZE) / 2.0):
			_catch(coin)
		elif coin.position.y > size.y:
			_remove_coin(coin)
			_miss()
			if _over:
				return
	if _spawned == TOTAL_COINS and _coins.is_empty():
		_over = true
		_offer_finish([_continue_option(), _replay_option()])


func _place_sack(x: float) -> void:
	_sack.position = Vector2(clampf(x, 0.0, size.x - SACK_SIZE.x), size.y - SACK_SIZE.y - SACK_BOTTOM_MARGIN)


func _spawn_coin() -> void:
	var coin := TextureRect.new()
	coin.texture = COIN_TEXTURE
	coin.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	coin.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	coin.size = Vector2(COIN_SIZE, COIN_SIZE)
	coin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var plan := _plan_coin()
	coin.position = Vector2(plan.x - COIN_SIZE / 2.0, SPAWN_Y)
	add_child(coin)
	_coins.append(coin)
	_spawned += 1
	_falls[coin] = {"speed": plan.speed, "boost_y": plan.boost_y, "boost": plan.boost}


## Picks a spawn x and a fall profile (`x` centre, `speed`, `boost_y`, `boost`) so the sack can
## always get from the previous coin to this one. A boosted coin falls slowly, then speeds up
## past `boost_y`; its start speed is chosen so the total fall time stays the planned one and
## the catch time stays predictable. If the random pick is too fast or too far, the fall is
## slowed, and failing that the x is pulled toward the previous coin.
func _plan_coin() -> Dictionary:
	var min_x: float = SACK_SIZE.x + COIN_SIZE / 2.0
	var max_x: float = size.x - SACK_SIZE.x - COIN_SIZE / 2.0
	var x: float = randf_range(min_x, max_x)
	var distance: float = size.y - SPAWN_Y  # fall length, in px
	var boost: float = 1.0
	var boost_share: float = 1.0  # share of the distance covered before the speed-up
	if randf() < BOOST_CHANCE:
		boost = randf_range(BOOST_MIN, BOOST_MAX)
		boost_share = randf_range(BOOST_START_MIN, BOOST_START_MAX)
	# time share of a whole crossing, for the sack-top and for the speed-up point
	var time_per_distance: float = boost_share + (1.0 - boost_share) / boost
	var catch_distance: float = _sack.position.y - COIN_SIZE / 2.0 - SPAWN_Y
	var catch_fraction: float = catch_distance / distance
	var catch_share: float = (minf(catch_fraction, boost_share) + maxf(catch_fraction - boost_share, 0.0) / boost) / time_per_distance
	var reach_speed: float = SACK_SPEED * REACH_SLACK
	var earliest: float = _last_catch_time + REACTION_TIME + absf(x - _last_catch_x) / reach_speed
	var fall_min: float = maxf(FALL_TIME_MIN, (earliest - _clock) / catch_share)
	if fall_min > FALL_TIME_MAX:
		var reach: float = (_clock + FALL_TIME_MAX * catch_share - _last_catch_time - REACTION_TIME) * reach_speed
		x = clampf(clampf(x, _last_catch_x - reach, _last_catch_x + reach), min_x, max_x)
		fall_min = FALL_TIME_MAX
	var fall: float = randf_range(fall_min, FALL_TIME_MAX)
	_last_catch_time = _clock + fall * catch_share
	_last_catch_x = x
	return {
		"x": x,
		"speed": distance * time_per_distance / fall,
		"boost_y": SPAWN_Y + boost_share * distance,
		"boost": boost,
	}


func _catch(coin: TextureRect) -> void:
	_remove_coin(coin)
	count += 1
	_update_count()
	_sound.play()


func _miss() -> void:
	_misses += 1
	_hud.lose_heart(_misses - 1)
	_flash_miss()
	if _misses >= MAX_MISSES:
		_over = true
		for coin in _coins.duplicate():
			_remove_coin(coin)
		_offer_retry()


func _on_retry() -> void:
	_start_round()


func _start_round() -> void:
	_hud.refill_hearts()
	_hide_retry()
	_misses = 0
	_spawned = 0
	count = 0
	_update_count()
	_spawn_timer = 0.0
	_clock = 0.0
	_last_catch_time = 0.0
	_last_catch_x = size.x / 2.0
	_over = false


func _schedule_next_coin() -> void:
	_spawn_timer = randf_range(SPAWN_GAP_MIN, SPAWN_GAP_MAX)


func _remove_coin(coin: TextureRect) -> void:
	_coins.erase(coin)
	_falls.erase(coin)
	coin.queue_free()


func _update_count() -> void:
	_hud.set_value("%d/%d" % [count, TOTAL_COINS])
