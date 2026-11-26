class_name DressUpQuest
extends QuestOverlay
## Rose's quest: dress one of her maidens. The maiden sits on a table on the left, wearing
## the basic top and bottom; the grid on the right swaps clothes onto her, one per slot
## (top, bottom). A maiden voices a wish above her head; Finish wins only when she wears the matching set.

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
# What the maiden says, and the set (top, bottom) that answers it.
const WISHES: Array[Dictionary] = [
	{"text": "harlot.wish-floral", "top": "green_top", "bottom": "green_bottom"},
	{"text": "harlot.wish-lace", "top": "lace_top", "bottom": "lace_bottom"},
	{"text": "harlot.wish-ruffle", "top": "pink_top", "bottom": "pink_bottom"},
]
const BUBBLE_TEXTURE: Texture2D = preload("res://assets/ui/speech_bubble.png")
const BUBBLE_REGION: Rect2 = Rect2(169, 244, 1683, 595)
const BUBBLE_SIZE: Vector2 = Vector2(300, 120)
const BUBBLE_OFFSET: Vector2 = Vector2(70, 70)  # top-left of the bubble from the maiden's centre, beside her face
const BUBBLE_TEXT_INSET: Vector4 = Vector4(34, 10, 28, 34)  # left, top, right, bottom; the tail takes the bottom
const WISH_FONT_SIZE: int = 22
const POP_SECONDS: float = 0.35
const POP_START_SCALE: float = 0.6
const NUDGE_DISTANCE: float = 12.0
const NUDGE_SECONDS: float = 0.06
const CANVAS_RATIO: float = 16.0 / 9.0  # every layer PNG is a 1920x1080 canvas
const STAGE_CENTER: float = 0.3  # horizontal centre of the maiden, as a fraction of the screen
const PANEL_LEFT: float = 0.58  # where the clothes panel starts, as a fraction of the screen width
const GRID_COLUMNS: int = 2
const ITEM_SIZE: Vector2 = Vector2(108, 108)
const GRID_GAP: int = 10
const FINISH_FONT_SIZE: int = 28
const PANEL_MARGIN: int = 24

var _wish: Dictionary
var _worn: Dictionary = {}  # slot -> item name
var _slot_layers: Dictionary = {}  # slot -> TextureRect
var _item_buttons: Dictionary = {}  # item name -> Button
var _wish_bubble: TextureRect
var _wish_label: Label
var _bubble_tween: Tween


func _ready() -> void:
	super()
	_dim = _add_backdrop(DIM_COLOR)  # _flash_miss flashes it
	_build_stage()
	_build_panel()
	_build_wish_bubble()
	_start_round()


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


func _build_wish_bubble() -> void:
	var texture := AtlasTexture.new()
	texture.atlas = BUBBLE_TEXTURE
	texture.region = BUBBLE_REGION
	_wish_bubble = TextureRect.new()
	_wish_bubble.texture = texture
	_wish_bubble.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_wish_bubble.stretch_mode = TextureRect.STRETCH_SCALE
	_wish_bubble.size = BUBBLE_SIZE
	_wish_bubble.position = _bubble_home()
	_wish_bubble.pivot_offset = Vector2(0.0, BUBBLE_SIZE.y)  # grows out of the tail
	_wish_bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_wish_bubble)

	_wish_label = CloudLabel.create("", WISH_FONT_SIZE)
	_wish_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_wish_label.offset_left = BUBBLE_TEXT_INSET.x
	_wish_label.offset_top = BUBBLE_TEXT_INSET.y
	_wish_label.offset_right = -BUBBLE_TEXT_INSET.z
	_wish_label.offset_bottom = -BUBBLE_TEXT_INSET.w
	_wish_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_wish_bubble.add_child(_wish_label)


func _bubble_home() -> Vector2:
	return Vector2(size.x * STAGE_CENTER, 0.0) + BUBBLE_OFFSET


## The bubble springs out of its tail whenever the maiden voices a new wish.
func _pop_wish_bubble() -> void:
	if _bubble_tween:
		_bubble_tween.kill()
	_wish_bubble.position = _bubble_home()
	_wish_bubble.scale = Vector2.ONE * POP_START_SCALE
	_wish_bubble.modulate.a = 0.0
	_bubble_tween = create_tween().set_parallel()
	_bubble_tween.tween_property(_wish_bubble, "scale", Vector2.ONE, POP_SECONDS) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_bubble_tween.tween_property(_wish_bubble, "modulate:a", 1.0, POP_SECONDS)


## A wrong outfit makes the bubble shake, restating what she asked for.
func _nudge_wish_bubble() -> void:
	if _bubble_tween:
		_bubble_tween.kill()
	var home_x := _bubble_home().x
	_bubble_tween = create_tween()
	for offset in [NUDGE_DISTANCE, -NUDGE_DISTANCE, NUDGE_DISTANCE / 2.0, 0.0]:
		_bubble_tween.tween_property(_wish_bubble, "position:x", home_x + offset, NUDGE_SECONDS)


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
	finish.pressed.connect(_on_finish)
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


func _on_finish() -> void:
	if _worn.get(&"top") == _wish.top and _worn.get(&"bottom") == _wish.bottom:
		_offer_finish([_continue_option(), _replay_option()])
	else:
		_flash_miss()
		_nudge_wish_bubble()


## A new wish and the default outfit.
func _on_retry() -> void:
	_start_round()


func _start_round() -> void:
	_wish = WISHES.pick_random()
	_wish_label.text = Localization.t(_wish.text)
	_pop_wish_bubble()
	for slot in DEFAULT_OUTFIT:
		_wear(slot, DEFAULT_OUTFIT[slot])


func _on_item_toggled(pressed: bool, item: Dictionary) -> void:
	_wear(item.slot, item.name if pressed else "")


## Puts `item_name` on `slot` (or strips the slot when empty) and syncs the grid highlights.
func _wear(slot: StringName, item_name: String) -> void:
	_worn[slot] = item_name
	_slot_layers[slot].texture = load(ASSET_DIR + item_name + ".png") if not item_name.is_empty() else null
	for item in ITEMS:
		if item.slot == slot:
			_item_buttons[item.name].set_pressed_no_signal(item.name == item_name)
