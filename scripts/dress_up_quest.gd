class_name DressUpQuest
extends QuestOverlay
## Rose's quest: dress one of her maidens. The maiden sits on a table on the left, wearing
## the basic top and bottom; the grid on the right swaps clothes onto her, one per slot
## (top, bottom). Finish ends the quest. Winning rules are still to come, so Finish wins as is.

const ASSET_DIR: String = "res://assets/minigame/dressup/"
const SLOTS: Array[StringName] = [&"bottom", &"top"]  # draw order, lowest first
const DEFAULT_OUTFIT: Dictionary = {&"top": "basic_top", &"bottom": "basic_bottom"}
const ITEMS: Array[Dictionary] = [
	{"slot": &"top", "name": "basic_top"},
	{"slot": &"bottom", "name": "basic_bottom"},
	{"slot": &"top", "name": "pink_top"},
	{"slot": &"bottom", "name": "pink_bottom"},
	{"slot": &"top", "name": "lace_top"},
	{"slot": &"bottom", "name": "lace_bottom"},
	{"slot": &"top", "name": "green_top"},
	{"slot": &"bottom", "name": "green_bottom"},
]
const CANVAS_RATIO: float = 16.0 / 9.0  # every layer PNG is a 1920x1080 canvas
const STAGE_CENTER: float = 0.3  # horizontal centre of the maiden, as a fraction of the screen
const PANEL_LEFT: float = 0.58  # where the clothes panel starts, as a fraction of the screen width
const GRID_COLUMNS: int = 2
const ITEM_SIZE: Vector2 = Vector2(108, 108)
const GRID_GAP: int = 10
const FINISH_FONT_SIZE: int = 28
const PANEL_MARGIN: int = 24

var _touched: bool = false  # whether the player changed her outfit at all
var _slot_layers: Dictionary = {}  # slot -> TextureRect
var _item_buttons: Dictionary = {}  # item name -> Button


func _ready() -> void:
	super()
	_add_backdrop(DIM_COLOR)
	_build_stage()
	_build_panel()
	for slot in DEFAULT_OUTFIT:
		_wear(slot, DEFAULT_OUTFIT[slot])


func _build_stage() -> void:
	var stage := Control.new()
	stage.size = Vector2(size.y * CANVAS_RATIO, size.y)
	stage.position.x = size.x * STAGE_CENTER - stage.size.x / 2.0
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(stage)
	_add_layer(stage, load(ASSET_DIR + "table.png"))
	_add_layer(stage, load(ASSET_DIR + "girl.png"))
	for slot in SLOTS:
		_slot_layers[slot] = _add_layer(stage, null)


func _add_layer(parent: Control, texture: Texture2D) -> TextureRect:
	var layer := TextureRect.new()
	layer.texture = texture
	layer.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	layer.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(layer)
	return layer


func _build_panel() -> void:
	var panel := VBoxContainer.new()
	panel.anchor_left = PANEL_LEFT
	panel.anchor_right = 1.0
	panel.anchor_bottom = 1.0
	panel.offset_left = PANEL_MARGIN
	panel.offset_right = -PANEL_MARGIN
	panel.offset_top = PANEL_MARGIN
	panel.offset_bottom = -PANEL_MARGIN
	add_child(panel)

	var middle := CenterContainer.new()
	middle.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(middle)

	var grid := GridContainer.new()
	grid.columns = GRID_COLUMNS
	grid.add_theme_constant_override("h_separation", GRID_GAP)
	grid.add_theme_constant_override("v_separation", GRID_GAP)
	middle.add_child(grid)
	for item in ITEMS:
		grid.add_child(_make_item_button(item))

	var finish := Button.new()
	finish.text = Localization.t("ui.finish")
	MenuButtonStyle.apply(finish, FINISH_FONT_SIZE)
	finish.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	finish.pressed.connect(func() -> void: won.emit())
	panel.add_child(finish)


func _make_item_button(item: Dictionary) -> Button:
	var button := Button.new()
	button.toggle_mode = true
	button.icon = load(ASSET_DIR + "icons/%s.png" % item.name)
	button.expand_icon = true
	button.custom_minimum_size = ITEM_SIZE
	MenuButtonStyle.apply(button)
	button.toggled.connect(_on_item_toggled.bind(item))
	_item_buttons[item.name] = button
	return button


func reward_scroll_key() -> String:
	return "harlot.quest-scroll" if _touched else "harlot.quest-scroll-bare"


func _on_item_toggled(pressed: bool, item: Dictionary) -> void:
	_touched = true
	_wear(item.slot, item.name if pressed else "")


## Puts `item_name` on `slot` (or strips the slot when empty) and syncs the grid highlights.
func _wear(slot: StringName, item_name: String) -> void:
	_slot_layers[slot].texture = load(ASSET_DIR + item_name + ".png") if not item_name.is_empty() else null
	for item in ITEMS:
		if item.slot == slot:
			_item_buttons[item.name].set_pressed_no_signal(item.name == item_name)
