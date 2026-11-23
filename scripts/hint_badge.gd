class_name HintBadge
extends Control

signal pressed

## A question-mark icon on the left wall that flips into a starred one, with a tooltip, when a
## hint is on offer: a helpful choice, or a finished quest that can be played on. Clickable only
## when starred (emits pressed); the tooltip closes on the next click anywhere.

const ICON: Texture2D = preload("res://assets/ui/hint.png")
const READY_ICON: Texture2D = preload("res://assets/ui/hint_available.png")
const ICON_SIZE: float = 72.0
const MARGIN: float = 16.0
const TIP_GAP: float = 10.0
const TIP_TEXT_COLOR: Color = Color(0.2, 0.05, 0.18)

## Whether the starred icon can be clicked (only when there is a quest to open).
var clickable: bool = true
var _tip_key: String = ""  # locale key of the tooltip; empty while the plain icon shows
var _icon: TextureRect
var _tip: PanelContainer
var _tip_label: Label
var _flip_tween: Tween
var _tip_tween: Tween


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	_icon = TextureRect.new()
	_icon.texture = ICON
	_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_icon.set_anchors_preset(Control.PRESET_CENTER_LEFT)
	_icon.offset_left = MARGIN
	_icon.offset_right = MARGIN + ICON_SIZE
	_icon.offset_top = -ICON_SIZE / 2.0
	_icon.offset_bottom = ICON_SIZE / 2.0
	_icon.pivot_offset = Vector2(ICON_SIZE, ICON_SIZE) / 2.0
	_icon.gui_input.connect(_on_icon_input)
	add_child(_icon)

	_tip = PanelContainer.new()
	_tip.visible = false
	_tip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tip.anchor_top = 0.5
	_tip.anchor_bottom = 0.5
	_tip.offset_left = MARGIN + ICON_SIZE + TIP_GAP
	_tip.grow_vertical = Control.GROW_DIRECTION_BOTH
	_tip.pivot_offset_ratio = Vector2(0.0, 0.5)
	var box := StyleBoxFlat.new()
	box.bg_color = Color(1, 1, 1, 0.55)
	box.set_corner_radius_all(12)
	box.set_content_margin_all(10)
	_tip.add_theme_stylebox_override("panel", box)
	_tip_label = Label.new()
	_tip_label.add_theme_font_override("font", GameState.DIALOGUE_FONT)
	_tip_label.add_theme_font_size_override("font_size", 15)
	_tip_label.add_theme_color_override("font_color", TIP_TEXT_COLOR)
	_tip.add_child(_tip_label)
	add_child(_tip)

	Localization.language_changed.connect(_apply_language)
	_apply_language()


## Shows the starred icon with the tooltip `tip_key` names, or the plain icon when it is empty.
## The tooltip opens when the star flips in, and again whenever `animate` is set on a starred icon.
func show_hint(tip_key: String, animate: bool) -> void:
	var was_ready: bool = not _tip_key.is_empty()
	var is_ready: bool = not tip_key.is_empty()
	_tip_key = tip_key
	_apply_language()
	if was_ready == is_ready:
		if is_ready and animate:
			_show_tip()
		return
	_icon.mouse_filter = Control.MOUSE_FILTER_STOP if is_ready and clickable else Control.MOUSE_FILTER_IGNORE
	_icon.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if is_ready and clickable else Control.CURSOR_ARROW
	_hide_tip()
	if _flip_tween and _flip_tween.is_running():
		_flip_tween.kill()
	var target: Texture2D = READY_ICON if is_ready else ICON
	if not animate:
		_icon.texture = target
		_icon.scale = Vector2.ONE
		return
	_flip_tween = create_tween()
	_flip_tween.tween_property(_icon, "scale:x", 0.0, 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_flip_tween.tween_callback(func() -> void: _icon.texture = target)
	_flip_tween.tween_property(_icon, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if is_ready:
		_flip_tween.tween_callback(_show_tip)


func _input(event: InputEvent) -> void:
	if _tip.visible and event is InputEventMouseButton and event.pressed:
		_hide_tip()


func _on_icon_input(event: InputEvent) -> void:
	if not _tip_key.is_empty() and clickable and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		pressed.emit()


func _apply_language() -> void:
	_tip_label.text = Localization.t(_tip_key) if not _tip_key.is_empty() else ""


func _show_tip() -> void:
	_tip.size = Vector2.ZERO
	_tip.modulate.a = 0.0
	_tip.scale = Vector2(0.6, 0.6)
	_tip.visible = true
	if _tip_tween:
		_tip_tween.kill()
	_tip_tween = create_tween().set_parallel(true)
	_tip_tween.tween_property(_tip, "modulate:a", 1.0, 0.25)
	_tip_tween.tween_property(_tip, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _hide_tip() -> void:
	if _tip_tween:
		_tip_tween.kill()
	if not _tip.visible:
		return
	_tip_tween = create_tween().set_parallel(true)
	_tip_tween.tween_property(_tip, "modulate:a", 0.0, 0.2)
	_tip_tween.tween_property(_tip, "scale", Vector2(0.8, 0.8), 0.2)
	_tip_tween.chain().tween_callback(func() -> void: _tip.visible = false)
