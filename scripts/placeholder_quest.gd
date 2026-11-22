class_name PlaceholderQuest
extends QuestOverlay
## Stand-in mini-game for characters whose real quest isn't built yet: a dim backdrop and a
## button that wins immediately. Replace a character's `hint_game` to swap it out.

const DIM_COLOR: Color = Color(0.2, 0.2, 0.2, 0.75)
const BUTTON_FONT_SIZE: int = 28
const BUTTON_BOTTOM_MARGIN: int = 24


func _ready() -> void:
	super()
	var dim := ColorRect.new()
	dim.color = DIM_COLOR
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)

	var button := Button.new()
	button.text = Localization.t("ui.continue")
	MenuButtonStyle.apply(button, BUTTON_FONT_SIZE)
	button.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM, Control.PRESET_MODE_MINSIZE, BUTTON_BOTTOM_MARGIN)
	button.grow_horizontal = Control.GROW_DIRECTION_BOTH
	button.grow_vertical = Control.GROW_DIRECTION_BEGIN
	button.pressed.connect(func() -> void: won.emit())
	add_child(button)
