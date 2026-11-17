extends CanvasLayer
## Top-right stats bar: an icon with its score below, and a tooltip below on hover (Autoload: StatsHud).

const ICON_SIZE: float = 30.0
const STATS: Array[Dictionary] = [
	{"id": "love", "name": "Love", "icon": "res://assets/stats/love.png", "tip": "Love: the warmth and affection people feel for you."},
	{"id": "faith", "name": "Faith", "icon": "res://assets/stats/faith.png", "tip": "Faith: your devotion and standing with the Church."},
	{"id": "justice", "name": "Justice", "icon": "res://assets/stats/justice.png", "tip": "Justice: The fall of rogues and all evil."},
	{"id": "magic", "name": "Magic", "icon": "res://assets/stats/magic.png", "tip": "Magic: The graceful craft that heals the sick."},
]

var _score_labels: Dictionary = {}
var _row: HBoxContainer
var _tooltip: PanelContainer
var _tooltip_label: Label
var _forced_hidden: bool = false
var _stat_boxes: Dictionary = {}
var _pending_changes: Dictionary = {}
var _showing_popups: bool = false


func _ready() -> void:
	layer = 100
	GameState.stat_changed.connect(_on_stat_changed)
	process_mode = Node.PROCESS_MODE_ALWAYS

	_row = HBoxContainer.new()
	_row.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_row.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_row.offset_right = -16.0
	_row.offset_top = 10.0
	_row.add_theme_constant_override("separation", 12)
	add_child(_row)

	for stat in STATS:
		_row.add_child(_make_stat(stat))

	_tooltip = PanelContainer.new()
	_tooltip.visible = false
	_tooltip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.05, 0.14, 0.95)
	style.border_color = Color(0.88, 0.74, 0.42, 0.9)
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(7)
	_tooltip.add_theme_stylebox_override("panel", style)
	_tooltip_label = Label.new()
	_tooltip_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tooltip_label.custom_minimum_size.x = 170.0
	_tooltip_label.add_theme_font_size_override("font_size", 11)
	_tooltip.add_child(_tooltip_label)
	add_child(_tooltip)


func _process(_delta: float) -> void:
	var intro: bool = GameState.is_intro_scene()
	var shown: bool = not intro and not _forced_hidden
	_row.visible = shown
	if not shown:
		_tooltip.visible = false
	elif not _pending_changes.is_empty() and not _showing_popups:
		_show_delta_popups()


## Hides the bar, e.g. while a full-screen ending scene is shown.
func set_forced_hidden(value: bool) -> void:
	_forced_hidden = value


func _on_stat_changed(stat_id: String, _value: int, applied_delta: int) -> void:
	_refresh(stat_id)
	if applied_delta != 0:
		_pending_changes[stat_id] = int(_pending_changes.get(stat_id, 0)) + applied_delta


func _show_delta_popups() -> void:
	_showing_popups = true
	var deltas := _pending_changes.duplicate()
	_pending_changes.clear()
	await get_tree().process_frame  # let the freshly shown row lay out
	for stat_id in deltas:
		var delta: int = deltas[stat_id]
		var box := _stat_boxes[stat_id] as Control
		var rect := box.get_global_rect()
		var label := Label.new()
		label.text = "%+d" % delta
		label.add_theme_font_size_override("font_size", 20)
		label.add_theme_color_override("font_color", Color(0.45, 0.95, 0.5) if delta > 0 else Color(1.0, 0.4, 0.4))
		label.add_theme_color_override("font_outline_color", Color(0.05, 0.02, 0.08, 1.0))
		label.add_theme_constant_override("outline_size", 6)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.custom_minimum_size = Vector2(rect.size.x, 28.0)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.position = Vector2(rect.position.x, rect.end.y + 4.0)
		label.modulate.a = 0.0
		add_child(label)
		var tween := create_tween()
		tween.tween_property(label, "modulate:a", 1.0, 0.25)
		tween.parallel().tween_property(label, "position:y", label.position.y + 10.0, 0.25)
		tween.tween_interval(2.0)
		tween.tween_property(label, "modulate:a", 0.0, 0.6)
		tween.tween_callback(label.queue_free)
	_showing_popups = false


func _make_stat(stat: Dictionary) -> Control:
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.mouse_filter = Control.MOUSE_FILTER_STOP
	box.add_theme_constant_override("separation", 2)

	var icon := TextureRect.new()
	icon.texture = load(stat["icon"]) as Texture2D
	icon.custom_minimum_size = Vector2(ICON_SIZE, ICON_SIZE)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(icon)

	var score := Label.new()
	score.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score.add_theme_font_size_override("font_size", 11)
	score.add_theme_color_override("font_outline_color", Color(0.05, 0.02, 0.08, 1.0))
	score.add_theme_constant_override("outline_size", 4)
	score.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(score)
	_score_labels[stat["id"]] = score
	_stat_boxes[stat["id"]] = box
	_refresh(stat["id"])

	box.mouse_entered.connect(_show_tooltip.bind(box, stat["tip"]))
	box.mouse_exited.connect(_hide_tooltip)
	return box


func _refresh(stat_id: String) -> void:
	if _score_labels.has(stat_id):
		(_score_labels[stat_id] as Label).text = "%d/%d" % [GameState.stats[stat_id], GameState.STAT_MAX]


func _show_tooltip(anchor: Control, text: String) -> void:
	_tooltip_label.text = text
	_tooltip.reset_size()
	_tooltip.visible = true
	await get_tree().process_frame
	var viewport_width: float = get_viewport().get_visible_rect().size.x
	var rect := anchor.get_global_rect()
	var x: float = clampf(rect.get_center().x - _tooltip.size.x * 0.5, 8.0, viewport_width - _tooltip.size.x - 8.0)
	_tooltip.position = Vector2(x, rect.end.y + 8.0)


func _hide_tooltip() -> void:
	_tooltip.visible = false
