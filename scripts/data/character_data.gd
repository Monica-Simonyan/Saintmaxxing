class_name CharacterData
extends RefCounted

## Static character and dialogue content. Text values are locale keys, resolved through Localization.t().

const ALL: Dictionary = {
	"priest": {
		"id": "priest",
		"quest_intro": "priest.quest-intro",
		"hint_game": "coins",  # starred hint opens the coin-catching game
		"quest_scroll": "priest.quest-scroll",  # shown when the game is won
		"map_pos": Vector2(0.196, 0.35),  # tag centre as a fraction of the map image
		"name": "priest.name",
		"effects": {
			"converted": {"love": 25, "faith": 25},
			"spared": {"love": -25, "faith": -25},
		},
		"start_node": "start",
		"start_scene": "res://assets/characters/priest/priest_church.png",
		"start_layers": ["res://assets/characters/priest/priest_hungry.png"],
		"outcome_on_top": true,
		"bubble_texture": "res://assets/characters/priest/priest_bubble.png",
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
					{"label": "priest.n8.choice-1", "next": "n13", "helps": true},
					{"label": "priest.n8.choice-2", "next": "n14"},
				],
			},
			"n9": {
				"text": "priest.n9",
				"choices": [
					{"label": "priest.n8.choice-1", "next": "n13", "helps": true},
					{"label": "priest.n8.choice-2", "next": "n14"},
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
				"scene": "res://assets/characters/priest/priest_church.png",
				"choices": [],
			},
			"e5": {
				"text": "priest.e5",
				"scene": "res://assets/characters/priest/priest_church.png",
				"choices": [],
			},
			"e6": {
				"text": "priest.e6",
				"scene": "res://assets/characters/priest/priest_thanks.png",
				"scene_back": "res://assets/characters/priest/priest_church.png",
				"converted": true,
				"choices": [],
			},
		},
	},
	"witch": {
		"id": "witch",
		"map_pos": Vector2(0.83, 0.45),  # tag centre as a fraction of the map image
		"name": "witch.name",
		"quest_intro": "witch.quest-intro",
		"hint_game": "cards",  # starred hint opens the Card Matching Quest
		"quest_scroll": "witch.quest-scroll",  # shown when the Card Matching Quest is won
		"effects": {
			"converted": {"love": 25, "magic": 25},
			"spared": {"love": -15, "magic": -25},
		},
		"start_node": "start",
		"start_scene": "res://assets/characters/witch/witch_room.png",
		"start_layers": ["res://assets/characters/witch/witch_start.png"],
		"bubble_texture": "res://assets/characters/witch/witch_bubble.png",
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
					{"label": "witch.w3.choice-1", "next": "w4", "helps": true},
					{"label": "witch.w3.choice-2", "next": "w4x"},
					{"label": "witch.w3.choice-3", "next": "e1"},
				],
			},
			"w4": {
				"text": "witch.w4",
				"choices": [
					{"label": "witch.w4.choice-1", "next": "w5a"},
					{"label": "witch.w4.choice-2", "next": "w5b", "helps": true},
				],
			},
			"w4x": {
				"text": "witch.w4x",
				"choices": [
					{"label": "witch.w4x.choice-1", "next": "w4c"},
					{"label": "witch.w4x.choice-2", "next": "w5d", "helps": true},
				],
			},
			"w4c": {
				"text": "witch.w4c",
				"choices": [
					{"label": "ui.continue", "next": "e1"},
				],
			},
			"w5a": {
				"text": "witch.w5a",
				"choices": [
					{"label": "witch.w5a.choice-1", "next": "e1"},
					{"label": "witch.w5a.choice-2", "next": "w6a", "helps": true},
				],
			},
			"w5b": {
				"text": "witch.w5b",
				"choices": [
					{"label": "witch.w5b.choice-1", "next": "e1"},
					{"label": "witch.w5b.choice-2", "next": "w6", "helps": true},
				],
			},
			"w5d": {
				"text": "witch.w5d",
				"choices": [
					{"label": "witch.w5b.choice-1", "next": "e1"},
					{"label": "witch.w5b.choice-2", "next": "w6", "helps": true},
				],
			},
			"w6": {
				"text": "witch.w6",
				"choices": [
					{"label": "ui.continue", "next": "e5"},
				],
			},
			"w6a": {
				"text": "witch.w6a",
				"choices": [
					{"label": "ui.continue", "next": "e5"},
				],
			},
			"e1": {
				"text": "witch.e1",
				"scene": "res://assets/characters/witch/witch_failed.png",
				"scene_back": "res://assets/characters/witch/witch_room.png",
				"choices": [],
			},
			"e5": {
				"text": "witch.e5",
				"converted": true,
				"scene": "res://assets/characters/witch/witch_purified.png",
				"scene_back": "res://assets/characters/witch/witch_room.png",
				"choices": [],
			},
		},
	},
	"vampire": {
		"id": "vampire",
		"quest_intro": "vampire.quest-intro",
		"hint_game": "maze",  # a Pac-Man maze: the unicorn eats glitter and the vampire's teeth prowl
		"hint_levels": GlitterMaze.LEVEL_COUNT,  # after the quest the hint icon opens the next level
		"quest_scroll": "vampire.quest-scroll",
		"map_pos": Vector2(0.80, 0.975),  # tag centre as a fraction of the map image
		"name": "vampire.name",
		"effects": {
			"converted": {"justice": -25},
			"spared": {"justice": 25},
		},
		"start_node": "start",
		"start_scene": "res://assets/characters/vampire/vampire_room.png",
		"start_layers": ["res://assets/characters/vampire/vampire_prisoner.png"],
		"bubble_texture": "res://assets/characters/vampire/vampire_bubble.png",
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
					{"label": "witch.w2.choice-1", "next": "n4"},
					{"label": "witch.w2.choice-2", "next": "n4"},
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
					{"label": "vampire.n8.choice-1", "next": "n11", "helps": true},
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
				"scene": "res://assets/characters/vampire/vampire_prisoner.png",
				"scene_back": "res://assets/characters/vampire/vampire_room.png",
				"choices": [],
			},
			"e2": {
				"text": "vampire.e1",
				"scene": "res://assets/characters/vampire/vampire_prisoner.png",
				"scene_back": "res://assets/characters/vampire/vampire_room.png",
				"choices": [],
			},
			"e3": {
				"text": "vampire.e3",
				"scene": "res://assets/characters/vampire/vampire_room.png",
				"converted": true,
				"choices": [],
			},
		},
	},
	"brothel_worker": {
		"id": "brothel_worker",
		"quest_intro": "harlot.quest-intro",
		"hint_game": "dress",  # Rose's dress-up quest (work in progress)
		"quest_scroll": "harlot.quest-scroll",
		"map_pos": Vector2(0.49, 0.80),  # tag centre as a fraction of the map image
		"name": "harlot.name",
		"effects": {
			"converted": {"love": -25, "justice": -15},
			"spared": {"love": 25},
		},
		"start_node": "start",
		"start_scene": "res://assets/characters/harlot/harlot_pure.png",
		"start_layers": [
			"res://assets/characters/harlot/harlot_failed.png",
			"res://assets/characters/harlot/harlot_couple.png",
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
					{"label": "harlot.n4.choice-1", "next": "n11"},
					{"label": "harlot.n4.choice-2", "next": "n11"},
				],
			},
			"n11": {
				"text": "harlot.n11",
				"choices": [
					{"label": "harlot.n11.choice-1", "next": "n13", "helps": true},
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
				"scene": "res://assets/characters/harlot/harlot_failed.png",
				"scene_back": "res://assets/characters/harlot/harlot_pure.png",
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
				"scene": "res://assets/characters/harlot/harlot_failed.png",
				"scene_back": "res://assets/characters/harlot/harlot_pure.png",
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
				"scene": "res://assets/characters/harlot/harlot_pure.png",
				"choices": [
				],
			},
			"n28": {
				"text": "harlot.n32",
				"scene": "res://assets/characters/harlot/harlot_failed.png",
				"scene_back": "res://assets/characters/harlot/harlot_pure.png",
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
					{"label": "harlot.n17.choice-1", "next": "n37"},
					{"label": "harlot.n17.choice-2", "next": "n40"},
				],
			},
			"n37": {
				"text": "harlot.n19",
				"choices": [
					{"label": "ui.continue", "next": "n38"},
				],
			},
			"n40": {
				"text": "harlot.n22",
				"choices": [
					{"label": "harlot.n22.choice-1", "next": "n42"},
					{"label": "harlot.n22.choice-2", "next": "n45"},
				],
			},
			"n38": {
				"text": "harlot.n20",
				"scene": "res://assets/characters/harlot/harlot_failed.png",
				"scene_back": "res://assets/characters/harlot/harlot_pure.png",
				"choices": [
				],
			},
			"n42": {
				"text": "harlot.n24",
				"choices": [
					{"label": "ui.continue", "next": "n43"},
				],
			},
			"n45": {
				"text": "harlot.n27",
				"choices": [
					{"label": "ui.continue", "next": "n46"},
				],
			},
			"n43": {
				"text": "harlot.n25",
				"converted": true,
				"scene": "res://assets/characters/harlot/harlot_pure.png",
				"choices": [
				],
			},
			"n46": {
				"text": "harlot.n32",
				"scene": "res://assets/characters/harlot/harlot_failed.png",
				"scene_back": "res://assets/characters/harlot/harlot_pure.png",
				"choices": [
				],
			},
		},
	},
}
