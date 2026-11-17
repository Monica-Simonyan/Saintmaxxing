class_name UnicornPose
extends RefCounted
## Shared placement of the maned unicorn (a 16:9 image glued to the bottom-left corner)
## so the menu and the monologue scene agree: it starts on the menu cropped by the left
## wall, then drifts toward the centre/right where the monologue is written on its hair.

const MENU_WIDTH_RATIO: float = 0.82
const MENU_X_RATIO: float = -0.55
const MONOLOGUE_WIDTH_RATIO: float = 0.85
const MONOLOGUE_X_RATIO: float = 0.15
const ASPECT: float = 9.0 / 16.0
## The mane's open area as fractions of the image, where the monologue text is placed.
const HAIR_TEXT_AREA: Rect2 = Rect2(-0.13, 0.38, 0.72, 0.56)


## Places `unicorn` at progress `t` (0 = menu pose, 1 = monologue pose).
static func apply(unicorn: Control, viewport_width: float, t: float) -> void:
	var width: float = viewport_width * lerpf(MENU_WIDTH_RATIO, MONOLOGUE_WIDTH_RATIO, t)
	var x: float = viewport_width * lerpf(MENU_X_RATIO, MONOLOGUE_X_RATIO, t)
	unicorn.offset_left = x
	unicorn.offset_right = x + width
	unicorn.offset_top = -width * ASPECT
	unicorn.offset_bottom = 0.0


## The monologue pose's hair area in screen pixels.
static func hair_text_rect(viewport_size: Vector2) -> Rect2:
	var width: float = viewport_size.x * MONOLOGUE_WIDTH_RATIO
	var image_rect := Rect2(viewport_size.x * MONOLOGUE_X_RATIO, viewport_size.y - width * ASPECT, width, width * ASPECT)
	return Rect2(
			image_rect.position + HAIR_TEXT_AREA.position * image_rect.size,
			HAIR_TEXT_AREA.size * image_rect.size)
