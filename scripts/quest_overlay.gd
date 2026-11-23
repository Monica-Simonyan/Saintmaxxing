class_name QuestOverlay
extends Control
## Base for the hint mini-games laid over a conversation. While one is open it hides the stats HUD
## and registers in GameState.QUEST_GROUP so the pause menu can swap its buttons. `won` is emitted
## when the player beats it; the dialogue then closes the overlay.
## A game that can be lost calls _offer_retry(); the button runs the game's _on_retry().

signal won

const RETRY_FONT_SIZE: int = 28
const DIM_COLOR: Color = Color(0.2, 0.2, 0.2, 0.75)
const MISS_COLOR: Color = Color("6D0F1C")
const MISS_FLASH_SECONDS: float = 0.6

var _retry_button: Button
var _dim: ColorRect  # the games that flash on a failure keep their DIM_COLOR backdrop here
var _dim_tween: Tween
var _dim_rest: Color = DIM_COLOR  # the colour _dim returns to after a flash


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP  # keeps clicks from reaching the dialogue underneath
	add_to_group(GameState.QUEST_GROUP)
	StatsHud.set_forced_hidden(true)


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


## Restarts the game after a loss.
func _on_retry() -> void:
	pass
