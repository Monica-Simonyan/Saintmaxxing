class_name TextFit
## Shared helper that shrinks a RichTextLabel's font until its text fits its box.

const MIN_FONT_SIZE: int = 10


## Needs a frame per step because the label only re-lays out its text between frames.
static func shrink_to_fit(label: RichTextLabel, start_size: int) -> void:
	var size_px: int = start_size
	label.add_theme_font_size_override("normal_font_size", size_px)
	await label.get_tree().process_frame
	while is_instance_valid(label) and size_px > MIN_FONT_SIZE and label.get_content_height() > label.size.y:
		size_px -= 1
		label.add_theme_font_size_override("normal_font_size", size_px)
		await label.get_tree().process_frame
