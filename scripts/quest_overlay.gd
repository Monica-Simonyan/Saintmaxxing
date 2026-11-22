class_name QuestOverlay
extends Control
## Base for the hint mini-games laid over a conversation. While one is open it hides the stats HUD
## and registers in GameState.QUEST_GROUP so the pause menu can swap its buttons. `won` is emitted
## when the player beats it; the dialogue then closes the overlay.
## A game that can be lost calls _offer_retry(); the button runs the game's _on_retry().

signal won

const RETRY_FONT_SIZE: int = 28

var _retry_button: Button


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP  # keeps clicks from reaching the dialogue underneath
	add_to_group(GameState.QUEST_GROUP)
	StatsHud.set_forced_hidden(true)


func _exit_tree() -> void:
	StatsHud.set_forced_hidden(false)


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
