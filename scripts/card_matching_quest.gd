class_name CardMatchingQuest
extends QuestOverlay

## The Card Matching Quest, laid over the dialogue from the starred hint icon.
## Cards start face down in a centred grid (layout from GameState.get_quest_deck()) and turn over
## when clicked. A full set of three that doesn't match turns back over; matching every card wins.
## The pause menu's back button is the only other control.

const BACKGROUND_COLOR: Color = Color(0.435, 0.306, 0.216, 0.6)  # translucent so the dialogue shows through
const GRID_COLUMNS: int = 4
const CARD_GAP: int = 16
const MISMATCH_PEEK_SECONDS: float = 0.8
const MAX_TURNS: int = 10
const NOTICE_FONT_SIZE: int = 36
const SHUFFLE_SECONDS: float = 0.5

var _cards: Array[QuestCard] = []
var _turned: Array[QuestCard] = []  # cards turned in the current attempt, not yet matched
var _busy: bool = false  # a flip, mismatch reveal or reshuffle is in progress
var _grid: GridContainer
var _hud: QuestHud


func _ready() -> void:
	super()
	if GameState.is_quest_complete(GameState.selected_character_id):
		GameState.reshuffle_quest_deck()  # a replay starts from a fresh deck
	_add_backdrop(BACKGROUND_COLOR)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	_grid = GridContainer.new()
	_grid.columns = GRID_COLUMNS
	_grid.add_theme_constant_override("h_separation", CARD_GAP)
	_grid.add_theme_constant_override("v_separation", CARD_GAP)
	center.add_child(_grid)

	var notice := Label.new()
	notice.text = Localization.t("ui.attempts") % MAX_TURNS
	notice.add_theme_font_override("font", GameState.STORY_FONT)
	notice.add_theme_font_size_override("font_size", NOTICE_FONT_SIZE)
	notice.add_theme_color_override("font_color", QuestHud.VALUE_COLOR)
	notice.add_theme_color_override("font_outline_color", QuestHud.VALUE_OUTLINE_COLOR)
	notice.add_theme_constant_override("outline_size", QuestHud.VALUE_OUTLINE_SIZE)
	notice.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	notice.offset_top = 20.0
	notice.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notice.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(notice)

	_hud = QuestHud.new()
	add_child(_hud)

	_build_cards()
	_restore_turned()
	_update_turns()
	if _is_out_of_turns():
		_busy = true
		_offer_retry()


## Lays the deck out in the grid, restoring which cards are face up from GameState.
func _build_cards() -> void:
	for card in _cards:
		_grid.remove_child(card)
		card.queue_free()
	_cards.clear()
	_turned.clear()
	var deck: Array[int] = GameState.get_quest_deck()
	if GameState.quest_up.size() != deck.size():
		GameState.quest_up.assign(deck.map(func(_kind: int) -> bool: return false))
		GameState.quest_pending.clear()
	for slot in deck.size():
		var card := QuestCard.new(deck[slot], slot, GameState.quest_up[slot])
		card.clicked.connect(_on_card_clicked)
		_grid.add_child(card)
		_cards.append(card)


## Re-arms the unfinished attempt; a full unmatched set that was mid-reveal just turns back over.
func _restore_turned() -> void:
	var pending: Array[int] = GameState.quest_pending
	if pending.size() >= GameState.QUEST_CARDS_PER_KIND:
		for slot in pending:
			_cards[slot].reset_face_down()
	else:
		for slot in pending:
			_turned.append(_cards[slot])
	_save_state()


func _save_state() -> void:
	for card in _cards:
		GameState.quest_up[card.slot] = card.face_up
	GameState.quest_pending.assign(_turned.map(func(card: QuestCard) -> int: return card.slot))


func _on_card_clicked(card: QuestCard) -> void:
	if _busy or card.face_up:
		return
	_busy = true
	await card.flip(true)
	_turned.append(card)
	if _turned.size() == GameState.QUEST_CARDS_PER_KIND:
		await _resolve_attempt()
	_save_state()
	if _cards.all(func(c: QuestCard) -> bool: return c.face_up):
		_offer_finish([_continue_option(), _replay_option()])
	elif _is_out_of_turns():
		_offer_retry()
	else:
		_busy = false


## Keeps a matching set face up; an unmatched one is shown briefly, then turned back over.
func _resolve_attempt() -> void:
	GameState.quest_turns += 1
	_update_turns()
	var kind: int = _turned[0].kind
	if not _turned.all(func(card: QuestCard) -> bool: return card.kind == kind):
		_save_state()
		await get_tree().create_timer(MISMATCH_PEEK_SECONDS).timeout
		for card in _turned:
			card.flip(false)
		await get_tree().create_timer(QuestCard.FLIP_HALF_SECONDS * 2.0).timeout
	_turned.clear()


func _is_out_of_turns() -> bool:
	return GameState.quest_turns >= MAX_TURNS


func _update_turns() -> void:
	_hud.set_value("%d/%d" % [GameState.quest_turns, MAX_TURNS])


## The cards spin away, come back reshuffled and face down, and play resumes.
func _on_retry() -> void:
	_hide_retry()
	await _spin_grid(0.0, PI)
	GameState.reshuffle_quest_deck()
	_build_cards()
	_update_turns()
	_grid.rotation = -PI
	await _spin_grid(1.0, 0.0)
	_busy = false


func _spin_grid(target_scale: float, target_rotation: float) -> void:
	_grid.pivot_offset = _grid.size / 2.0
	var spin := create_tween().set_parallel()
	spin.tween_property(_grid, "scale", Vector2.ONE * target_scale, SHUFFLE_SECONDS).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	spin.tween_property(_grid, "rotation", target_rotation, SHUFFLE_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await spin.finished
