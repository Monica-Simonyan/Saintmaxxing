extends Node

## Global RPG state and character/dialogue data registry (Autoload: GameState).

const MENU_SCENE: String = "res://menu.tscn"
const UNICORN_MONOLOGUE_SCENE: String = "res://unicorn_monologue.tscn"
const CHARACTERS_SCENE: String = "res://characters.tscn"
const MAP_TEXTURE: Texture2D = preload("res://assets/map.png")
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
		"name": "Temple",
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
				"text": "*A foolish boy dares to ask him for a scrap of bread. Little does he know what hides behind that noble face...*",
				"choices": [{"label": "Good evening, Father!", "next": "n2"}],
			},
			"n2": {
				"text": "*He tilts his head, veil swaying.* Good evening, traveler.",
				"choices": [{"label": "What brings a man of the cloth to such an ungodly place?", "next": "n4"}],
			},
			"n4": {
				"text": "*A faint smirk curls beneath the veil.* Opportunity lies in every corner, and my evening is wide open. And what of you?",
				"choices": [
					{"label": "I've heard whispers, Father, that you haven't been honest with the Church's money.", "next": "n8"},
					{"label": "I've heard some things about you, Father. I thought you might need a bit of guidance, or a helping hand.", "next": "n9"},
					{"label": "Leave the Priest alone.", "next": "e1"},
				],
			},
			"n8": {
				"text": "*He smiles, eyes cold and unreadable.* You know what they say: curiosity kills the cat. And a unicorn, too, if it digs deep enough...",
				"choices": [
					{"label": "All the town trusts you, Father. They say no priest understands a troubled heart better. What will they feel when the truth comes out?", "next": "n13"},
					{"label": "The young servants look up to you! Is this what you want to teach them?", "next": "n14"},
				],
			},
			"n9": {
				"text": "Help? Me?! The one who helps everybody?! *He laughs a little too loudly.* Spare me your charity, my friend.",
				"choices": [
					{"label": "All the town trusts you, Father. They say no priest understands a troubled heart better. What will they feel when the truth comes out?", "next": "n13"},
					{"label": "The young servants look up to you! Is this what you want to teach them?", "next": "n14"},
				],
			},
			"n13": {
				"text": "*He tugs the veil lower, hands trembling.* If you know, then HE must know! This is a disaster! I'll be damned for certain! What in all the heavens should I do?!",
				"choices": [{"label": "God has mercy on those who feel guilt. Tell me, Father, how did it start?", "next": "n19"}],
			},
			"n14": {
				"text": "*His smile fades.* Every man must answer for his own deeds, and I'll not carry the sins of others on my back. Don't you dare guilt-trap me!",
				"choices": [{"label": "Well, I can't trap you with something you don't have, can I?", "next": "n20"}],
			},
			"n19": {
				"text": "*He looks into his cup and speaks quietly.* I was just a young servant of the Church when I first saw gold on the plate. I was deep in debt, and to a soul so young and frail, the temptation was too strong.",
				"choices": [{"label": "Every illness has a cure, Father, even greed. Take the first step.", "next": "n23"}],
			},
			"n20": {
				"text": "*He gives a thin, dangerous smile.* The only trap you can set for me is the pile of crap you leave on the road for me to step in.",
				"choices": [{"label": "[Continue]", "next": "e5"}],
			},
			"n23": {
				"text": "*He closes his eyes and breathes out.* No... no... I cannot serve two lords and still call myself a priest. One day God's anger will crash down on me, and I will truly regret it. It is time to step back.",
				"choices": [{"label": "[Continue]", "next": "e6"}],
			},
			"e1": {
				"text": "St. Max departs, heavy with sorrow and despair. A bitter ache stirs inside the priest, but he stays unchanged. The poor carry on with their miserable agony, and the young sweethearts work tirelessly to set aside a coin, hoping one day to afford a wedding.",
				"scene": "res://assets/priest_church.png",
				"choices": [],
			},
			"e5": {
				"text": "St. Max departs, heavy with sorrow and despair. A bitter ache stirs inside the priest, but he stays unchanged. The poor carry on with their miserable agony, and the young sweethearts work tirelessly to set aside a coin, hoping one day to afford a wedding. The priest does not turn pure and carries on living the same life. Only now, every time he goes for a walk, he watches his steps with great care. His veil stays down.",
				"scene": "res://assets/priest_church.png",
				"choices": [],
			},
			"e6": {
				"text": "He lifts the veil for the first time. From that day on, the priest lived a God-pleasing life. He no longer joined the feasts, nor the company of sweet-smelling young ladies. All the Church's savings were sent to the poor and the foster homes, and no extra penny was taken for baptisms or weddings. Thus, marriages bloomed across the town.",
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
		"name": "Hut",
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
				"text": "*The clashing of chains, binding the skeleton's body and soul, is interrupted by the unexpected arrival of a guest.*",
				"choices": [
					{"label": "Evening to you, lovely lady.", "next": "w1"},
					{"label": "Good eve, mistress of the house.", "next": "w1"},
				],
			},
			"w1": {
				"text": "*She does not turn from her cauldron.* May the night be kind to you, traveler.",
				"choices": [
					{"label": "What is that rattling in the dark below?", "next": "w2"},
					{"label": "Forgive me, but something is clanking down there. What is it?", "next": "w2"},
				],
			},
			"w2": {
				"text": "*Her smile is thin.* Only an old friend. He is not much for conversation, but he never leaves. Come closer, the fire is warm.",
				"choices": [
					{"label": "...I see. I am Saint Max. You may call me Max for short.", "next": "w3"},
					{"label": "How curious. They call me Saint Max, but Max will do.", "next": "w3"},
				],
			},
			"w3": {
				"text": "*Her eyes glint.* Max... what a charming name. I am Ahsoka. And such a fine horn, unicorn. Rare in these parts.",
				"choices": [
					{"label": "Ooooh, I smell a delicious brew of love potion.", "next": "w4"},
					{"label": "Pray, witch, does the good priest know what mischief you get up to here?", "next": "w4x"},
					{"label": "Leave the witch alone.", "next": "e1"},
				],
			},
			"w4": {
				"text": "*She stirs the cauldron slowly.* Yes! It is my specialty, for a very special client. Wives who want their husbands back, husbands who want younger wives. Love is only half my trade, of course. For those who grow tired of their loved ones, there are other brews.",
				"choices": [
					{"label": "A love born of a spell is not true love, witch. I hope you understand that.", "next": "w5a"},
					{"label": "Your crafts could heal the ill in need and make you a fortune through good deeds!", "next": "w5b"},
				],
			},
			"w4x": {
				"text": "*The fire snaps and goes cold.* You dare threaten me?! Then be cursed for a thousand years, you stupid unicorn!",
				"choices": [
					{"label": "[Continue]", "next": "e2"},
				],
			},
			"w5a": {
				"text": "*Her eyes blaze.* You dare lecture me?! Then be cursed for a thousand years, you stupid unicorn!",
				"choices": [
					{"label": "[Continue]", "next": "e3"},
				],
			},
			"w5b": {
				"text": "*The chains rattle below.* Heal? I have not healed a soul in a hundred years. I have forgotten how. *She stares into the cauldron.* Perhaps there is nothing left in me worth saving.",
				"choices": [
					{"label": "You are a coward hiding behind your chains and spells.", "next": "e4"},
					{"label": "It is never too late, Ahsoka. Set him free, and start again.", "next": "w6"},
				],
			},
			"w6": {
				"text": "*Her horns tremble, and the chains fall silent.* Perhaps... yes. Perhaps it is time.",
				"choices": [
					{"label": "[Continue]", "next": "e5"},
				],
			},
			"e1": {
				"text": "The unicorn feels his horn burning from within. In agony, he sees the witch crumble into dust and vanish from sight. Yet she lives on, casting love spells and death spells, and tangling the lives of the townsfolk. And in the cellar, the chained skeleton is dragged to the cauldron and brewed into her next potion.",
				"scene": "res://assets/witch_failed.png",
				"scene_back": "res://assets/witch_room.png",
				"choices": [],
			},
			"e2": {
				"text": "The unicorn feels his horn burning from within. In agony, he sees the witch crumble into dust and vanish from sight. Yet she lives on, casting love spells and death spells, and tangling the lives of the townsfolk. And in the cellar, the chained skeleton is dragged to the cauldron and brewed into her next potion.",
				"scene": "res://assets/witch_failed.png",
				"scene_back": "res://assets/witch_room.png",
				"choices": [],
			},
			"e3": {
				"text": "The unicorn feels his horn burning from within. In agony, he sees the witch crumble into dust and vanish from sight. Yet she lives on, casting love spells and death spells, and tangling the lives of the townsfolk. And in the cellar, the chained skeleton is dragged to the cauldron and brewed into her next potion.",
				"scene": "res://assets/witch_failed.png",
				"scene_back": "res://assets/witch_room.png",
				"choices": [],
			},
			"e4": {
				"text": "The unicorn feels his horn burning from within. In agony, he sees the witch crumble into dust and vanish from sight. Yet she lives on, casting love spells and death spells, and tangling the lives of the townsfolk. And in the cellar, the chained skeleton is dragged to the cauldron and brewed into her next potion.",
				"scene": "res://assets/witch_failed.png",
				"scene_back": "res://assets/witch_room.png",
				"choices": [],
			},
			"e5": {
				"text": "Joy and wonder fill Ahsoka's eyes. The loony jailed skeleton finally breaks free from the witch's wicked chains. Her horns drop to the ground like fallen leaves, and from that day on she brews healing herbs and cares for the sick. The town grew stronger and healthier than ever before.",
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
		"name": "Castle",
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
				"text": "*By a dying fire, a pale lord sips something dark and steaming, a starving dog bound at his feet. The great doors groan open, and a stranger steps into the gloom. Wait, is it a dog...?*",
				"choices": [
					{"label": "Good eve, good sir.", "next": "n2"},
					{"label": "Well met, good sir. A dark evening, is it not?", "next": "n2"},
				],
			},
			"n2": {
				"text": "Good evening, my dear. How delightful to see a new face.",
				"choices": [
					{"label": "What is that strange drink in your hand?", "next": "n3"},
					{"label": "Pray, what are you drinking, sir? It smells... strange.", "next": "n3"},
				],
			},
			"n3": {
				"text": "*He lifts the cup with a sly smile.* Tea, good traveler, steeped from a maiden's moon-rag. A rare brew, and a fine one!",
				"choices": [
					{"label": "...I see. I am Saint Max. You may call me Max for short.", "next": "n4"},
					{"label": "How curious. They call me Saint Max, but Max will do.", "next": "n4"},
				],
			},
			"n4": {
				"text": "*His fangs flash as he smiles.* What an interesting name, Max. And such fluffy cheeks...",
				"choices": [
					{"label": "That is no tea. That is blood! Half the town has gone missing, and now I see why.", "next": "n8"},
					{"label": "Odd tea, sir. And a bit red. Folk in town say people keep disappearing.", "next": "n8"},
					{"label": "Leave the Vampire alone.", "next": "e1"},
				],
			},
			"n8": {
				"text": "*He sips from the cup, unbothered.* Yes, it is blood, a midnight snack that I collect from ladies. Meanwhile, I only kill the wicked: thieves, murderers, men who hurt young girls. Ask the streets if they miss them.",
				"choices": [
					{"label": "Who made you the judge? Nobody gets to kill people, wicked or not.", "next": "n11"},
					{"label": "Maybe so. But the guards and the courts should deal with them, not you.", "next": "n12"},
				],
			},
			"n11": {
				"text": "*His smile thins.* Someone has to. The guards take bribes, and the priest feasts on church gold. Who else is there?",
				"choices": [
					{"label": "You're a killer, nothing more. Call it justice if it helps you sleep.", "next": "n13"},
				],
			},
			"n12": {
				"text": "*He lowers his cup.* The guards look away for a coin, and the priest feasts on stolen gold. This town needs someone who doesn't.",
				"choices": [
					{"label": "Then let me help. Drink animal blood instead, and give the guards a chance to do their job.", "next": "n14"},
				],
			},
			"n13": {
				"text": "*He turns his face away.* Call me what you like. The streets are safe tonight, and that is all I care about. Now leave me to my tea.",
				"choices": [
					{"label": "[Continue]", "next": "e2"},
				],
			},
			"n14": {
				"text": "*He is quiet for a long moment.* Goats are easier to catch than thieves, I admit. Very well, Max. I will try it your way.",
				"choices": [
					{"label": "[Continue]", "next": "e3"},
				],
			},
			"e1": {
				"text": "As the thirsty sir keeps sipping his red tea, the town stays free of wicked deeds. Thieves, murderers, and those who hurt innocent girls vanish one by one into the night, at the faint glint of his sharp fangs. The streets are safe to walk after dark, and the young girls are thankful for his service.",
				"scene": "res://assets/vampire_prisoner.png",
				"scene_back": "res://assets/vampire_room.png",
				"choices": [],
			},
			"e2": {
				"text": "As the thirsty sir keeps sipping his red tea, the town stays free of wicked deeds. Thieves, murderers, and those who hurt innocent girls vanish one by one into the night, at the faint glint of his sharp fangs. The streets are safe to walk after dark, and the young girls are thankful for his service.",
				"scene": "res://assets/vampire_prisoner.png",
				"scene_back": "res://assets/vampire_room.png",
				"choices": [],
			},
			"e3": {
				"text": "The thirsty sir's sharp fangs hid behind his thin lips. His glowing red gaze softened into a warm hazelnut glance, as if a predator had turned into a lamb. But the wicked he once drained now stroll freely through the streets. The young ladies are terrified, and no one leaves home at night.",
				"scene": "res://assets/vampire_room.png",
				"converted": true,
				"choices": [],
			},
		},
	},
	"brothel_worker": {
		"id": "brothel_worker",
		"map_pos": Vector2(0.47, 0.77),  # tag centre as a fraction of the map image
		"name": "Brothel",
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
				"text": "*Rose leans against the curtain, eyeing the newcomer.*",
				"choices": [
					{"label": "Good evening, fair lady.", "next": "n2"},
				],
			},
			"n2": {
				"text": "Good evening, funny creature",
				"choices": [
					{"label": "What does such a lovely woman do out here alone, in this hustle under starry night", "next": "n4"},
					{"label": "Quite an authentic dress you wear, my lady. I shall admit", "next": "n6"},
				],
			},
			"n4": {
				"text": "Nothing of note, in truth. Only making preparations for tonight’s good service",
				"choices": [
					{"label": "What manner of labor demands such devotion?", "next": "n11"},
					{"label": "What kind of labor calls for such particular dressing?", "next": "n11"},
				],
			},
			"n6": {
				"text": "I thank thee, kind traveler. It is nothing special, only my uniform for work.",
				"choices": [
					{"label": "What manner of labor demands such devotion?", "next": "n11"},
					{"label": "What kind of labor calls for such particular dressing?", "next": "n11"},
				],
			},
			"n11": {
				"text": "The finest kind, curious stranger. The kind that gives relief to the worried and worries the relieved. The kind that is paid for in good gold. Speaking of gold, those church lads have already worn me out, and I’ve barely had a moment to myself this evening. Anyway, where was I? Ah, yes. The kind of labor that keeps a pathetic man with coin alive.",
				"choices": [
					{"label": "I see, please tell me, do you take pleasure in your work?", "next": "n13"},
					{"label": "Forgive me, my lady, but with thighs so full, don’t they rub sore against each other in so short a skirt?", "next": "n34"},
					{"label": "I beg thy pardon, my lady, but on a night this cold, do thy thighs not freeze?", "next": "n34"},
					{"label": "Leave the Harlot alone.", "next": "n32"},
				],
			},
			"n13": {
				"text": "Most days, I love my work, but some days it makes my blood boil! Just the other day, my favorite patron canceled on me because it was his wife’s birthday. ‘Husband duties,’ he said. Can you believe it?! Either he spent a devil of a lot of gold on her gift, or he shared her bed. Neither serves me well! And it was our anniversary, too, by the way!",
				"choices": [
					{"label": "Oooh, that is a great shame to hear. Yet I see thy services are in high demand.", "next": "n17"},
					{"label": "Woe, that is sad news indeed. But surely, my lady, you are paid a proper price for what you have to offer, are you not?", "next": "n17"},
				],
			},
			"n32": {
				"text": "The lovely maiden, who had been chatting with her gentleman in another corner, slipped away on his arm, relieved. Rose carried on as before. In time, her favorite visitor left his wife, and she gave him love, the real kind. As crime fell, justice took root, for even the toughest rogues turned soft as butter in her arms.",
				"scene": "res://assets/brothel_failed.png",
				"scene_back": "res://assets/brothel_pure.png",
				"choices": [
				],
			},
			"n17": {
				"text": "Truth be told, I have no cause to complain. Behold my hair, behold my beauty, and a goblet of the finest drink shall soon arrive. My loyal admirers keep me afloat, you see!",
				"choices": [
					{"label": "Tell me, does your heart feel no shame for your deeds?", "next": "n19"},
					{"label": "Hmm... Have you heard though, nuns these days receive quite a good pay?", "next": "n22"},
				],
			},
			"n19": {
				"text": "I make an honest living, and what do you do, hm? I am the best in town, and everyone in this tavern can swear to it. Or are you just jealous that you are the one who gets settled, and not the settler?",
				"choices": [
					{"label": "[Continue]", "next": "n20"},
				],
			},
			"n22": {
				"text": "Are you serious? Nuns? Tell me, what do they do to earn more than I do, when I pour my sweat and blood into my work?",
				"choices": [
					{"label": "Truth be told, I am no expert in this. I know that nuns usually take a vow of poverty and give away all their earnings. BUT I have heard that in this particular church, they are paid well to preach and to teach in the schools. All the benefits are included too, with days of rest and the healer’s care paid for.", "next": "n24"},
					{"label": "They surely do not \"sweat\" as much as you do, my lady. Perhaps, they simply lead a humbler life, you know.", "next": "n27"},
				],
			},
			"n20": {
				"text": "Wounded in dignity and shaken to the soul, St. Max leaves her behind. The lovely maiden, who had been chatting with her gentleman in another corner, slipped away on his arm, relieved. Rose carried on as before. In time, her favorite visitor left his wife, and she gave him love, the real kind. As crime fell, justice took root, for even the toughest rogues turned soft as butter in her arms.",
				"scene": "res://assets/brothel_failed.png",
				"scene_back": "res://assets/brothel_pure.png",
				"choices": [
				],
			},
			"n24": {
				"text": "I won’t have to lie beneath any man anymore, nor bear the scribbles those wicked women leave on my walls. And I’ll have a decent life, too!!",
				"choices": [
					{"label": "[Continue]", "next": "n25"},
				],
			},
			"n27": {
				"text": "Live a humble life? Money won’t make you happy, beauty won’t make you happy. Just some bullshit that only ugly and poor can claim. I’m doing fine in my own trade, thanks.",
				"choices": [
					{"label": "[Continue]", "next": "n28"},
				],
			},
			"n25": {
				"text": "The thought struck Rose's heart, and her soft fingers trembled. She hurried to share it with every girl in town, and soon they all left worldly life behind to become nuns in the temple of Sinerwood. An empty silence haunted the houses of the sweet women. No more couples were wed, and no more goblets were raised to toast the bride and groom. As love vanished from the air, evil rose, rage erupted, and criminals rushed to commit their dark deeds. Justice suffered. Oh, poor Rose...",
				"converted": true,
				"scene": "res://assets/brothel_pure.png",
				"choices": [
				],
			},
			"n28": {
				"text": "The lovely maiden, who had been chatting with her gentleman in another corner, slipped away on his arm, relieved. Rose carried on as before. In time, her favorite visitor left his wife, and she gave him love, the real kind. As crime fell, justice took root, for even the toughest rogues turned soft as butter in her arms.",
				"scene": "res://assets/brothel_failed.png",
				"scene_back": "res://assets/brothel_pure.png",
				"choices": [
				],
			},
			"n34": {
				"text": "Aren’t you a bit too curious for a unicorn with a horn the size of a shrimp? It’s probably the cold weather, isn’t it?",
				"choices": [
					{"label": "I’ll do my best not to take that personally... And yes, it IS freezing out there!", "next": "n35"},
				],
			},
			"n35": {
				"text": "*Rose laughs, hugging her shoulders against the chill.*",
				"choices": [
					{"label": "Tell me, does your heart feel no shame for your deeds?", "next": "n37"},
					{"label": "Hmm... Have you heard though, nuns these days receive quite a good pay?", "next": "n40"},
				],
			},
			"n37": {
				"text": "I make an honest living, and what do you do, hm? I am the best in town, and everyone in this tavern can swear to it. Or are you just jealous that you are the one who gets settled, and not the settler?",
				"choices": [
					{"label": "[Continue]", "next": "n38"},
				],
			},
			"n40": {
				"text": "Are you serious? Nuns? Tell me, what do they do to earn more than I do, when I pour my sweat and blood into my work?",
				"choices": [
					{"label": "Truth be told, I am no expert in this. I know that nuns usually take a vow of poverty and give away all their earnings. BUT I have heard that in this particular church, they are paid well to preach and to teach in the schools. All the benefits are included too, with days of rest and the healer’s care paid for.", "next": "n42"},
					{"label": "They surely do not \"sweat\" as much as you do, my lady. Perhaps, they simply lead a humbler life, you know.", "next": "n45"},
				],
			},
			"n38": {
				"text": "Wounded in dignity and shaken to the soul, St. Max leaves her behind. The lovely maiden, who had been chatting with her gentleman in another corner, slipped away on his arm, relieved. Rose carried on as before. In time, her favorite visitor left his wife, and she gave him love, the real kind. As crime fell, justice took root, for even the toughest rogues turned soft as butter in her arms.",
				"scene": "res://assets/brothel_failed.png",
				"scene_back": "res://assets/brothel_pure.png",
				"choices": [
				],
			},
			"n42": {
				"text": "I won’t have to lie beneath any man anymore, nor bear the scribbles those wicked women leave on my walls. And I’ll have a decent life, too!!",
				"choices": [
					{"label": "[Continue]", "next": "n43"},
				],
			},
			"n45": {
				"text": "Live a humble life? Money won’t make you happy, beauty won’t make you happy. Just some bullshit that only ugly and poor can claim. I’m doing fine in my own trade, thanks.",
				"choices": [
					{"label": "[Continue]", "next": "n46"},
				],
			},
			"n43": {
				"text": "The thought struck Rose's heart, and her soft fingers trembled. She hurried to share it with every girl in town, and soon they all left worldly life behind to become nuns in the temple of Sinerwood. An empty silence haunted the houses of the sweet women. No more couples were wed, and no more goblets were raised to toast the bride and groom. As love vanished from the air, evil rose, rage erupted, and criminals rushed to commit their dark deeds. Justice suffered. Oh, poor Rose...",
				"converted": true,
				"scene": "res://assets/brothel_pure.png",
				"choices": [
				],
			},
			"n46": {
				"text": "The lovely maiden, who had been chatting with her gentleman in another corner, slipped away on his arm, relieved. Rose carried on as before. In time, her favorite visitor left his wife, and she gave him love, the real kind. As crime fell, justice took root, for even the toughest rogues turned soft as butter in her arms.",
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
