class_name QuestIntroPopup
extends Control
## The unicorn's cloud, opened over a conversation to explain a quest before it starts.
## A click outside the cloud closes it; the button emits `started`.

signal started

const INSET: Vector4 = Vector4(50, 32, 56, 58)  # left, top, right, bottom inside the cloud
const TEXT_FONT_SIZE: int = 16
const BUTTON_FONT_SIZE: int = 20
const CONTENT_SEPARATION: int = 12
const MIN_CLOUD_HEIGHT: float = 270.0

var _cloud_texture: Texture2D
var _cloud_rect: Rect2
var _text: String


## `cloud_rect` is the area the cloud fills; its bottom edge stays put if the cloud has to grow.
func setup(cloud_texture: Texture2D, cloud_rect: Rect2, text: String) -> void:
	_cloud_texture = cloud_texture
	_cloud_rect = cloud_rect
	_text = text


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)

	var cloud := TextureRect.new()
	cloud.texture = _cloud_texture
	cloud.flip_h = true
	cloud.mouse_filter = Control.MOUSE_FILTER_STOP  # clicks on the cloud must not close the popup
	cloud.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	cloud.stretch_mode = TextureRect.STRETCH_SCALE
	cloud.size = Vector2(_cloud_rect.size.x, maxf(_cloud_rect.size.y, MIN_CLOUD_HEIGHT))
	cloud.position = Vector2(_cloud_rect.position.x, _cloud_rect.end.y - cloud.size.y)
	add_child(cloud)

	var content := VBoxContainer.new()
	content.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.offset_left = INSET.x
	content.offset_top = INSET.y
	content.offset_right = -INSET.z
	content.offset_bottom = -INSET.w
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", CONTENT_SEPARATION)
	cloud.add_child(content)

	var label := CloudLabel.create(_text, TEXT_FONT_SIZE)
	label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(label)

	var start := Button.new()
	start.text = Localization.t("ui.start-quest")
	MenuButtonStyle.apply(start, BUTTON_FONT_SIZE)
	start.pressed.connect(started.emit)
	content.add_child(start)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		queue_free()
