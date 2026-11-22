class_name QuestCard
extends TextureRect

## One card of the Card Matching Quest: remembers its kind and grid slot, and animates turning over.

signal clicked(card: QuestCard)

const BACK: Texture2D = preload("res://assets/quest/card_back.png")
const SIZE: Vector2 = Vector2(117, 180)
const FLIP_HALF_SECONDS: float = 0.15

var kind: int
var slot: int
var face_up: bool


func _init(card_kind: int, card_slot: int, is_face_up: bool) -> void:
	kind = card_kind
	slot = card_slot
	face_up = is_face_up


func _ready() -> void:
	texture = _face_texture(face_up)
	custom_minimum_size = SIZE
	pivot_offset = SIZE / 2.0
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		clicked.emit(self)


## Turns the card edge-on, swaps its picture, and turns it back; resolves when finished.
func flip(up: bool) -> void:
	face_up = up
	var tween := create_tween()
	tween.tween_property(self, "scale:x", 0.0, FLIP_HALF_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_callback(func() -> void: texture = _face_texture(up))
	tween.tween_property(self, "scale:x", 1.0, FLIP_HALF_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await tween.finished


## Shows the back straight away, with no animation.
func reset_face_down() -> void:
	face_up = false
	texture = BACK


func _face_texture(up: bool) -> Texture2D:
	return GameState.QUEST_CARD_TEXTURES[kind] if up else BACK
