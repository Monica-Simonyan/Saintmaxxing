class_name MenuButtonStyle
## Gives a Button the hand-drawn pink look used by every menu button.

const TEXTURE: Texture2D = preload("res://assets/menu_button.png")
const TEXT_COLOR: Color = Color(0.45, 0.2, 0.2)
const HOVER_TINT: Color = Color(1.06, 1.0, 0.96)
const PRESSED_TINT: Color = Color(0.9, 0.82, 0.82)
const PADDING: Vector2 = Vector2(28, 12)


static func apply(button: Button, font_size: int = 24) -> void:
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_font_override("font", GameState.STORY_FONT)
	button.add_theme_font_size_override("font_size", font_size)
	for color_name in ["font_color", "font_hover_color", "font_pressed_color", "font_disabled_color", "font_focus_color"]:
		button.add_theme_color_override(color_name, TEXT_COLOR)
	var normal := _style(Color.WHITE)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("focus", normal)
	button.add_theme_stylebox_override("disabled", normal)
	button.add_theme_stylebox_override("hover", _style(HOVER_TINT))
	button.add_theme_stylebox_override("pressed", _style(PRESSED_TINT))


static func _style(tint: Color) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = TEXTURE
	style.modulate_color = tint
	style.content_margin_left = PADDING.x
	style.content_margin_right = PADDING.x
	style.content_margin_top = PADDING.y
	style.content_margin_bottom = PADDING.y
	return style
