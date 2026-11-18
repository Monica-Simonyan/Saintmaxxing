extends Node

## Global RPG state and character/dialogue data registry (Autoload: GameState).

const MENU_SCENE: String = "res://menu.tscn"
const UNICORN_MONOLOGUE_SCENE: String = "res://unicorn_monologue.tscn"
const CHARACTERS_SCENE: String = "res://characters.tscn"
const MAP_TEXTURE: Texture2D = preload("res://assets/map.png")
const STORY_FONT: Font = preload("res://assets/fonts/Eleanora.ttf")
const DIALOGUE_FONT: Font = preload("res://assets/fonts/Dumbledor.ttf")
const DIALOGUE_SCENE: String = "res://brothel_dialogue.tscn"

## Horizontal left-to-right display order for the character screen.
const CHARACTER_ORDER: Array[String] = [
	"priest",
	"witch",
	"vampire",
	"brothel_worker",
]

signal stat_changed(stat_id: String, value: int, applied_delta: int)

const STAT_MAX: int = 100
const STAT_START: int = 50

var stats: Dictionary = {"love": STAT_START, "faith": STAT_START, "justice": STAT_START, "magic": STAT_START}
var selected_character_id: String = "priest"
var completed_conversations: Dictionary = {}
var map_intro_shown: bool = false

var characters: Dictionary = {
	"priest": {
		"id": "priest",
		"map_pos": Vector2(0.19, 0.33),  # tag centre as a fraction of the map image
		"name": "priest.name",
		"effects": {
			"converted": {"love": 25, "faith": 25},
			"spared": {"love": -25, "faith": -25},
		},
		"start_node": "start",
		"start_scene": "res://assets/priest_church.png",
		"start_layers": ["res://assets/priest_hungry.png"],
		"outcome_on_top": true,
		"bubble_texture": "res://assets/priest_bubble.png",
		"bubble_region": Rect2(217, 247, 1530, 542),
		"bubble_rect": Rect2(340, 20, 560, 205),
		"cloud_text_color": Color(0.17, 0.04, 0.08),
		"choices_rect": Rect2(660, 450, 450, 200),  # smaller, clear of the kid
		"dialogue": {
			"start": {
				"text": "priest.start",
				"choices": [{"label": "priest.start.choice-1", "next": "n2"}],
			},
			"n2": {
				"text": "priest.n2",
				"choices": [{"label": "priest.n2.choice-1", "next": "n4"}],
			},
			"n4": {
				"text": "priest.n4",
				"choices": [
					{"label": "priest.n4.choice-1", "next": "n8"},
					{"label": "priest.n4.choice-2", "next": "n9"},
					{"label": "priest.n4.choice-3", "next": "e1"},
				],
			},
			"n8": {
				"text": "priest.n8",
				"choices": [
					{"label": "priest.n8.choice-1", "next": "n13"},
					{"label": "priest.n8.choice-2", "next": "n14"},
				],
			},
			"n9": {
				"text": "priest.n9",
				"choices": [
					{"label": "priest.n9.choice-1", "next": "n13"},
					{"label": "priest.n9.choice-2", "next": "n14"},
				],
			},
			"n13": {
				"text": "priest.n13",
				"choices": [{"label": "priest.n13.choice-1", "next": "n19"}],
			},
			"n14": {
				"text": "priest.n14",
				"choices": [{"label": "priest.n14.choice-1", "next": "n20"}],
			},
			"n19": {
				"text": "priest.n19",
				"choices": [{"label": "priest.n19.choice-1", "next": "n23"}],
			},
			"n20": {
				"text": "priest.n20",
				"choices": [{"label": "ui.continue", "next": "e5"}],
			},
			"n23": {
				"text": "priest.n23",
				"choices": [{"label": "ui.continue", "next": "e6"}],
			},
			"e1": {
				"text": "priest.e1",
				"scene": "res://assets/priest_church.png",
				"choices": [],
			},
			"e5": {
				"text": "priest.e5",
				"scene": "res://assets/priest_church.png",
				"choices": [],
			},
			"e6": {
				"text": "priest.e6",
				"scene": "res://assets/priest_thanks.png",
				"scene_back": "res://assets/priest_church.png",
				"converted": true,
				"choices": [],
			},
		},
	},
	"witch": {
		"id": "witch",
		"map_pos": Vector2(0.85, 0.43),  # tag centre as a fraction of the map image
		"name": "witch.name",
		"effects": {
			"converted": {"love": 25, "magic": 25},
			"spared": {"love": -15, "magic": -25},
		},
		"start_node": "start",
		"start_scene": "res://assets/witch_room.png",
		"start_layers": ["res://assets/witch_start.png"],
		"bubble_texture": "res://assets/witch_bubble.png",
		"bubble_region": Rect2(0, 0, 915, 322),
		"cloud_text_color": Color(0.96, 0.97, 0.94),
		"bubble_rect": Rect2(335, 20, 420, 190),
		"choices_rect": Rect2(640, 440, 400, 250),
		"dialogue": {
			"start": {
				"text": "witch.start",
				"choices": [
					{"label": "witch.start.choice-1", "next": "w1"},
					{"label": "witch.start.choice-2", "next": "w1"},
				],
			},
			"w1": {
				"text": "witch.w1",
				"choices": [
					{"label": "witch.w1.choice-1", "next": "w2"},
					{"label": "witch.w1.choice-2", "next": "w2"},
				],
			},
			"w2": {
				"text": "witch.w2",
				"choices": [
					{"label": "witch.w2.choice-1", "next": "w3"},
					{"label": "witch.w2.choice-2", "next": "w3"},
				],
			},
			"w3": {
				"text": "witch.w3",
				"choices": [
					{"label": "witch.w3.choice-1", "next": "w4"},
					{"label": "witch.w3.choice-2", "next": "w4x"},
					{"label": "witch.w3.choice-3", "next": "e1"},
				],
			},
			"w4": {
				"text": "witch.w4",
				"choices": [
					{"label": "witch.w4.choice-1", "next": "w5a"},
					{"label": "witch.w4.choice-2", "next": "w5b"},
				],
			},
			"w4x": {
				"text": "witch.w4x",
				"choices": [
					{"label": "ui.continue", "next": "e2"},
				],
			},
			"w5a": {
				"text": "witch.w5a",
				"choices": [
					{"label": "ui.continue", "next": "e3"},
				],
			},
			"w5b": {
				"text": "witch.w5b",
				"choices": [
					{"label": "witch.w5b.choice-1", "next": "e4"},
					{"label": "witch.w5b.choice-2", "next": "w6"},
				],
			},
			"w6": {
				"text": "witch.w6",
				"choices": [
					{"label": "ui.continue", "next": "e5"},
				],
			},
			"e1": {
				"text": "witch.e1",
				"scene": "res://assets/witch_failed.png",
				"scene_back": "res://assets/witch_room.png",
				"choices": [],
			},
			"e2": {
				"text": "witch.e2",
				"scene": "res://assets/witch_failed.png",
				"scene_back": "res://assets/witch_room.png",
				"choices": [],
			},
			"e3": {
				"text": "witch.e3",
				"scene": "res://assets/witch_failed.png",
				"scene_back": "res://assets/witch_room.png",
				"choices": [],
			},
			"e4": {
				"text": "witch.e4",
				"scene": "res://assets/witch_failed.png",
				"scene_back": "res://assets/witch_room.png",
				"choices": [],
			},
			"e5": {
				"text": "witch.e5",
				"converted": true,
				"scene": "res://assets/witch_purified.png",
				"scene_back": "res://assets/witch_room.png",
				"choices": [],
			},
		},
	},
	"vampire": {
		"id": "vampire",
		"map_pos": Vector2(0.80, 0.93),  # tag centre as a fraction of the map image
		"name": "vampire.name",
		"effects": {
			"converted": {"justice": -25},
			"spared": {"justice": 25},
		},
		"start_node": "start",
		"start_scene": "res://assets/vampire_room.png",
		"start_layers": ["res://assets/vampire_prisoner.png"],
		"bubble_texture": "res://assets/vampire_bubble.png",
		"bubble_region": Rect2(0, 0, 987, 348),
		"cloud_text_color": Color(0.96, 0.95, 0.98),
		"bubble_rect": Rect2(270, 20, 480, 190),
		"choices_rect": Rect2(770, 40, 360, 270),
		"dialogue": {
			"start": {
				"text": "vampire.start",
				"choices": [
					{"label": "vampire.start.choice-1", "next": "n2"},
					{"label": "vampire.start.choice-2", "next": "n2"},
				],
			},
			"n2": {
				"text": "vampire.n2",
				"choices": [
					{"label": "vampire.n2.choice-1", "next": "n3"},
					{"label": "vampire.n2.choice-2", "next": "n3"},
				],
			},
			"n3": {
				"text": "vampire.n3",
				"choices": [
					{"label": "vampire.n3.choice-1", "next": "n4"},
					{"label": "vampire.n3.choice-2", "next": "n4"},
				],
			},
			"n4": {
				"text": "vampire.n4",
				"choices": [
					{"label": "vampire.n4.choice-1", "next": "n8"},
					{"label": "vampire.n4.choice-2", "next": "n8"},
					{"label": "vampire.n4.choice-3", "next": "e1"},
				],
			},
			"n8": {
				"text": "vampire.n8",
				"choices": [
					{"label": "vampire.n8.choice-1", "next": "n11"},
					{"label": "vampire.n8.choice-2", "next": "n12"},
				],
			},
			"n11": {
				"text": "vampire.n11",
				"choices": [
					{"label": "vampire.n11.choice-1", "next": "n13"},
				],
			},
			"n12": {
				"text": "vampire.n12",
				"choices": [
					{"label": "vampire.n12.choice-1", "next": "n14"},
				],
			},
			"n13": {
				"text": "vampire.n13",
				"choices": [
					{"label": "ui.continue", "next": "e2"},
				],
			},
			"n14": {
				"text": "vampire.n14",
				"choices": [
					{"label": "ui.continue", "next": "e3"},
				],
			},
			"e1": {
				"text": "vampire.e1",
				"scene": "res://assets/vampire_prisoner.png",
				"scene_back": "res://assets/vampire_room.png",
				"choices": [],
			},
			"e2": {
				"text": "vampire.e2",
				"scene": "res://assets/vampire_prisoner.png",
				"scene_back": "res://assets/vampire_room.png",
				"choices": [],
			},
			"e3": {
				"text": "vampire.e3",
				"scene": "res://assets/vampire_room.png",
				"converted": true,
				"choices": [],
			},
		},
	},
	"brothel_worker": {
		"id": "brothel_worker",
		"map_pos": Vector2(0.47, 0.77),  # tag centre as a fraction of the map image
		"name": "harlot.name",
		"effects": {
			"converted": {"love": -25, "justice": -15},
			"spared": {"love": 25},
		},
		"start_node": "start",
		"start_scene": "res://assets/brothel_pure.png",
		"start_layers": [
			"res://assets/brothel_failed.png",
			"res://assets/brothel_couple.png",
		],
		"dialogue": {
			"start": {
				"text": "harlot.start",
				"choices": [
					{"label": "harlot.start.choice-1", "next": "n2"},
				],
			},
			"n2": {
				"text": "harlot.n2",
				"choices": [
					{"label": "harlot.n2.choice-1", "next": "n4"},
					{"label": "harlot.n2.choice-2", "next": "n6"},
				],
			},
			"n4": {
				"text": "harlot.n4",
				"choices": [
					{"label": "harlot.n4.choice-1", "next": "n11"},
					{"label": "harlot.n4.choice-2", "next": "n11"},
				],
			},
			"n6": {
				"text": "harlot.n6",
				"choices": [
					{"label": "harlot.n6.choice-1", "next": "n11"},
					{"label": "harlot.n6.choice-2", "next": "n11"},
				],
			},
			"n11": {
				"text": "harlot.n11",
				"choices": [
					{"label": "harlot.n11.choice-1", "next": "n13"},
					{"label": "harlot.n11.choice-2", "next": "n34"},
					{"label": "harlot.n11.choice-3", "next": "n34"},
					{"label": "harlot.n11.choice-4", "next": "n32"},
				],
			},
			"n13": {
				"text": "harlot.n13",
				"choices": [
					{"label": "harlot.n13.choice-1", "next": "n17"},
					{"label": "harlot.n13.choice-2", "next": "n17"},
				],
			},
			"n32": {
				"text": "harlot.n32",
				"scene": "res://assets/brothel_failed.png",
				"scene_back": "res://assets/brothel_pure.png",
				"choices": [
				],
			},
			"n17": {
				"text": "harlot.n17",
				"choices": [
					{"label": "harlot.n17.choice-1", "next": "n19"},
					{"label": "harlot.n17.choice-2", "next": "n22"},
				],
			},
			"n19": {
				"text": "harlot.n19",
				"choices": [
					{"label": "ui.continue", "next": "n20"},
				],
			},
			"n22": {
				"text": "harlot.n22",
				"choices": [
					{"label": "harlot.n22.choice-1", "next": "n24"},
					{"label": "harlot.n22.choice-2", "next": "n27"},
				],
			},
			"n20": {
				"text": "harlot.n20",
				"scene": "res://assets/brothel_failed.png",
				"scene_back": "res://assets/brothel_pure.png",
				"choices": [
				],
			},
			"n24": {
				"text": "harlot.n24",
				"choices": [
					{"label": "ui.continue", "next": "n25"},
				],
			},
			"n27": {
				"text": "harlot.n27",
				"choices": [
					{"label": "ui.continue", "next": "n28"},
				],
			},
			"n25": {
				"text": "harlot.n25",
				"converted": true,
				"scene": "res://assets/brothel_pure.png",
				"choices": [
				],
			},
			"n28": {
				"text": "harlot.n28",
				"scene": "res://assets/brothel_failed.png",
				"scene_back": "res://assets/brothel_pure.png",
				"choices": [
				],
			},
			"n34": {
				"text": "harlot.n34",
				"choices": [
					{"label": "harlot.n34.choice-1", "next": "n35"},
				],
			},
			"n35": {
				"text": "harlot.n35",
				"choices": [
					{"label": "harlot.n35.choice-1", "next": "n37"},
					{"label": "harlot.n35.choice-2", "next": "n40"},
				],
			},
			"n37": {
				"text": "harlot.n37",
				"choices": [
					{"label": "ui.continue", "next": "n38"},
				],
			},
			"n40": {
				"text": "harlot.n40",
				"choices": [
					{"label": "harlot.n40.choice-1", "next": "n42"},
					{"label": "harlot.n40.choice-2", "next": "n45"},
				],
			},
			"n38": {
				"text": "harlot.n38",
				"scene": "res://assets/brothel_failed.png",
				"scene_back": "res://assets/brothel_pure.png",
				"choices": [
				],
			},
			"n42": {
				"text": "harlot.n42",
				"choices": [
					{"label": "ui.continue", "next": "n43"},
				],
			},
			"n45": {
				"text": "harlot.n45",
				"choices": [
					{"label": "ui.continue", "next": "n46"},
				],
			},
			"n43": {
				"text": "harlot.n43",
				"converted": true,
				"scene": "res://assets/brothel_pure.png",
				"choices": [
				],
			},
			"n46": {
				"text": "harlot.n46",
				"scene": "res://assets/brothel_failed.png",
				"scene_back": "res://assets/brothel_pure.png",
				"choices": [
				],
			},
		},
	},
}


func reset_state() -> void:
	stats = {"love": STAT_START, "faith": STAT_START, "justice": STAT_START, "magic": STAT_START}
	selected_character_id = "priest"
	completed_conversations = {}
	map_intro_shown = false
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
	var effects: Dictionary = get_selected_character().get("effects", {}).get(outcome, {})
	for stat_id in effects:
		change_stat(stat_id, effects[stat_id])


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
