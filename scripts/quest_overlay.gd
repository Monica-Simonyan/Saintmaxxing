class_name QuestOverlay
extends Control
## Base for the hint mini-games laid over a conversation. While one is open it hides the stats HUD
## and registers in GameState.QUEST_GROUP so the pause menu can swap its buttons. `won` is emitted
## when the player beats it; the dialogue then closes the overlay.
## A game that can be lost calls _offer_retry(); the button runs the game's _on_retry().
## A game that is finished calls _offer_finish() with its options, usually _continue_option()
## (which emits `won`) and _replay_option() (which runs the game's _on_retry()).

signal won

const RETRY_FONT_SIZE: int = 28
const DIM_COLOR: Color = Color(0.2, 0.2, 0.2, 0.75)
const MISS_COLOR: Color = Color("6D0F1C")
const MISS_FLASH_SECONDS: float = 0.6
const FINISH_VEIL_COLOR: Color = Color(0.25, 0.25, 0.25, 0.7)
const FINISH_GAP: int = 24
const FINISH_FADE_SECONDS: float = 0.4

var _retry_button: Button
var _finish: Control  # the grey veil with the end-of-game buttons
var _dim: ColorRect  # the games that flash on a failure keep their DIM_COLOR backdrop here
var _dim_tween: Tween
var _dim_rest: Color = DIM_COLOR  # the colour _dim returns to after a flash


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP  # keeps clicks from reaching the dialogue underneath
	add_to_group(GameState.QUEST_GROUP)
	StatsHud.set_forced_hidden(true)
	GameState.view_changed.emit()
	tree_exited.connect(GameState.view_changed.emit)  # by then the node has left the group


func _exit_tree() -> void:
	StatsHud.set_forced_hidden(false)


## Fills the overlay with a flat colour; clicks still hit the overlay itself, not the dialogue below.
func _add_backdrop(color: Color) -> ColorRect:
	var backdrop := ColorRect.new()
	backdrop.color = color
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)
	return backdrop


## Negative-stat sound plus a dark-red flash of the dim backdrop that fades back.
func _flash_miss() -> void:
	Audio.play_stat_change(false)
	if _dim_tween:
		_dim_tween.kill()
	_dim.color = MISS_COLOR
	_dim_tween = create_tween()
	_dim_tween.tween_property(_dim, "color", _dim_rest, MISS_FLASH_SECONDS)


## Locale key of the scroll shown on a win; empty uses the character's `quest_scroll`.
func reward_scroll_key() -> String:
	return ""


func _offer_retry() -> void:
	if _retry_button == null:
		_retry_button = Button.new()
		_retry_button.text = Localization.t("ui.retry")
		MenuButtonStyle.apply(_retry_button, RETRY_FONT_SIZE)
		_retry_button.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		_retry_button.grow_horizontal = Control.GROW_DIRECTION_BOTH
		_retry_button.grow_vertical = Control.GROW_DIRECTION_BOTH
		_retry_button.pressed.connect(_on_retry)
		add_child(_retry_button)
	_retry_button.visible = true


func _hide_retry() -> void:
	if _retry_button != null:
		_retry_button.visible = false


## Greys out the game and lists the buttons to choose from; each option is {"text": String, "action": Callable}.
func _offer_finish(options: Array[Dictionary]) -> void:
	_hide_finish()
	_finish = Control.new()
	_finish.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_finish.mouse_filter = Control.MOUSE_FILTER_STOP
	var veil := ColorRect.new()
	veil.color = FINISH_VEIL_COLOR
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_finish.add_child(veil)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", FINISH_GAP)
	row.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	row.grow_horizontal = Control.GROW_DIRECTION_BOTH
	row.grow_vertical = Control.GROW_DIRECTION_BOTH
	_finish.add_child(row)
	for option in options:
		var button := Button.new()
		button.text = option.text
		MenuButtonStyle.apply(button, RETRY_FONT_SIZE)
		button.pressed.connect(func() -> void:
			_hide_finish()
			option.action.call())
		row.add_child(button)
	_finish.modulate.a = 0.0
	add_child(_finish)
	create_tween().tween_property(_finish, "modulate:a", 1.0, FINISH_FADE_SECONDS)


func _hide_finish() -> void:
	if _finish:
		_finish.queue_free()
		_finish = null


func _continue_option() -> Dictionary:
	return {"text": Localization.t("ui.continue-to-dialogue"), "action": func() -> void: won.emit()}


func _replay_option() -> Dictionary:
	return {"text": Localization.t("ui.replay"), "action": _on_retry}


## Restarts the game after a loss, or on Replay.
func _on_retry() -> void:
	pass
