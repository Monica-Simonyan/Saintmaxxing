extends Node

## Global RPG state: stats, progress and scene paths (Autoload: GameState). Content lives in data/character_data.gd.

const MENU_SCENE: String = "res://scenes/menu.tscn"
const UNICORN_MONOLOGUE_SCENE: String = "res://scenes/unicorn_monologue.tscn"
const MAP_SCENE: String = "res://scenes/map.tscn"
const MAP_TEXTURE: Texture2D = preload("res://assets/map/map.png")
const STORY_FONT: Font = preload("res://assets/fonts/Eleanora.ttf")
const DIALOGUE_FONT: Font = preload("res://assets/fonts/Dumbledor.ttf")
const SPEECH_BUBBLE_TEXTURE: Texture2D = preload("res://assets/ui/speech_bubble.png")
const SPEECH_BUBBLE_REGION: Rect2 = Rect2(169, 244, 1683, 595)  # the cloud inside the sheet
const DIALOGUE_SCENE: String = "res://scenes/dialogue.tscn"
const QUEST_CARD_TEXTURES: Array[Texture2D] = [
	preload("res://assets/quest/card_skull.png"),
	preload("res://assets/quest/card_crystal_ball.png"),
	preload("res://assets/quest/card_candle.png"),
	preload("res://assets/quest/card_dagger.png"),
]
const QUEST_CARDS_PER_KIND: int = 3
const QUEST_GROUP: StringName = &"quest_overlay"  # members of this group are the open hint mini-games

## Horizontal left-to-right display order for the character screen.
const CHARACTER_ORDER: Array[String] = [
	"priest",
	"witch",
	"vampire",
	"brothel_worker",
]

signal stat_changed(stat_id: String, value: int, applied_delta: int)
## The scene or the set of open mini-games changed; the HUD and pause button re-decide what to show.
signal view_changed

const STAT_MAX: int = 100
const STAT_START: int = 50

var stats: Dictionary = {"love": STAT_START, "faith": STAT_START, "justice": STAT_START, "magic": STAT_START}
var selected_character_id: String = "priest"
var completed_conversations: Dictionary = {}
var conversation_outcomes: Dictionary = {}  # character_id -> "converted" or "spared"
var map_intro_shown: bool = false
# Progress kept while the player steps away (back button, quest); cleared by reset_state().
var dialogue_progress: Dictionary = {}  # character id -> dialogue node key
var completed_quests: Dictionary = {}  # character id -> true once their quest is won
var quest_up: Array[bool] = []  # per grid slot: card face up
var quest_pending: Array[int] = []  # slots turned in the current, unfinished attempt
var quest_turns: int = 0  # completed three-card attempts in the current round
var quest_levels: Dictionary = {}  # character id -> highest level cleared in a multi-level quest
var _quest_deck: Array[int] = []  # card kind (index into QUEST_CARD_TEXTURES) per grid slot

var characters: Dictionary = CharacterData.ALL.duplicate(true)


func _ready() -> void:
	get_tree().scene_changed.connect(view_changed.emit)


func complete_quest(character_id: String) -> void:
	completed_quests[character_id] = true


func is_quest_complete(character_id: String) -> bool:
	return completed_quests.get(character_id, false)


func reset_state() -> void:
	stats = {"love": STAT_START, "faith": STAT_START, "justice": STAT_START, "magic": STAT_START}
	selected_character_id = "priest"
	completed_conversations = {}
	conversation_outcomes = {}
	map_intro_shown = false
	_quest_deck = []
	dialogue_progress = {}
	completed_quests = {}
	quest_levels = {}
	quest_up = []
	quest_pending = []
	quest_turns = 0
	for stat_id in stats:
		stat_changed.emit(stat_id, stats[stat_id], 0)


func select_character(character_id: String) -> void:
	if not characters.has(character_id):
		push_warning("GameState: Unknown character_id '%s', defaulting to 'priest'." % character_id)
		selected_character_id = "priest"
		return
	selected_character_id = character_id

## Clamps the stat to 0..STAT_MAX and announces the change that was actually applied.
func change_stat(stat_id: String, delta: int) -> void:
	var before: int = int(stats.get(stat_id, 0))
	stats[stat_id] = clampi(before + delta, 0, STAT_MAX)
	stat_changed.emit(stat_id, stats[stat_id], stats[stat_id] - before)


## Locks the conversation and applies the character's stat effects for the outcome
## ("converted" or "spared"). Does nothing if it was already completed.
func finish_conversation(outcome: String) -> void:
	if is_conversation_completed(selected_character_id):
		return
	completed_conversations[selected_character_id] = true
	conversation_outcomes[selected_character_id] = outcome
	var effects: Dictionary = get_selected_character().get("effects", {}).get(outcome, {})
	for stat_id in effects:
		change_stat(stat_id, effects[stat_id])


## Card layout for the Card Matching Quest: shuffled once per game session, then kept until restart.
func get_quest_deck() -> Array[int]:
	if _quest_deck.is_empty():
		for kind in QUEST_CARD_TEXTURES.size():
			for _copy in QUEST_CARDS_PER_KIND:
				_quest_deck.append(kind)
		_quest_deck.shuffle()
	return _quest_deck


## Starts the card quest over with a freshly shuffled layout.
func reshuffle_quest_deck() -> void:
	_quest_deck = []
	quest_up = []
	quest_pending = []
	quest_turns = 0


func is_conversation_completed(character_id: String) -> bool:
	return completed_conversations.get(character_id, false)


func get_selected_character() -> Dictionary:
	return characters.get(selected_character_id, characters["priest"])


func get_character(character_id: String) -> Dictionary:
	return characters.get(character_id, {})


## True on the main menu and the opening monologue, where the HUD and pause button stay hidden.
func is_intro_scene() -> bool:
	var scene := get_tree().current_scene
	return scene != null and scene.scene_file_path in [MENU_SCENE, UNICORN_MONOLOGUE_SCENE]


func all_conversations_completed() -> bool:
	return CHARACTER_ORDER.all(is_conversation_completed)
