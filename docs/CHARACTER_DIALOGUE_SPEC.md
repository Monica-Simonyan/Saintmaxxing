# Character Dialogue Spec

How a character conversation is built, generalised from Rose (the Harlot, `brothel_worker`).
Follow this for every new character so they all behave and look alike.

## 1. Inputs per character

| Input | Rose example |
|---|---|
| Dialogue chart (HTML/graph, player vs NPC lines, endings) | `~/Downloads/harlot_chart.html` |
| Map position of their house | `map_pos` |
| Stat effects per outcome (from the design doc) | converting: -25 love, -15 justice; not converting: +25 love |
| Scene art: one background plus optional layers | `brothel_pure/failed/couple.png` |

## 2. Data (`scripts/game_state.gd`, `characters[id]`)

```gdscript
"brothel_worker": {
	"id": "brothel_worker",
	"map_pos": Vector2(0.47, 0.77),      # tag centre, fraction of the map image
	"name": "Rose",                      # shown on the map tag
	"effects": {                         # applied once, when the conversation ends
		"converted": {"love": -25, "justice": -15},
		"spared":    {"love": 25},
	},
	"start_node": "start",
	"start_scene": "res://assets/brothel_pure.png",    # illustrated layout: background
	"start_layers": ["res://assets/brothel_failed.png"],  # optional transparent layers over it
	"bubble_rect": Rect2(270, 20, 480, 190),   # optional: NPC cloud position
	"choices_rect": Rect2(770, 40, 360, 270),  # optional: choices cloud position
	"choices_opacity": 1.0,                    # optional
	"outcome_on_top": false,             # true if the ending art sits low (priest)
	"dialogue": { ...nodes... },
}
```

Stats: `love`, `faith`, `justice`, `magic`. Outcome keys used so far: `converted`, `spared`.

## 3. Dialogue nodes

```gdscript
"n11": {
	"text": "What the NPC says.",
	"choices": [ {"label": "What the player may say.", "next": "n13"} ],
},
"n25": {                                  # ending: empty choices
	"text": "Narrated outcome shown over the full-screen scene.",
	"scene": "res://assets/brothel_failed.png",        # optional full-screen art
	"scene_back": "res://assets/brothel_pure.png",     # optional layer under `scene`
	"converted": true,                                  # marks the converting outcome
	"choices": [],
},
```

Rules (taken from the chart):

1. Node ids are the chart ids (`n2`, `n11`, ...). The first NPC line is `start`.
2. Each chart edge from an NPC node becomes a `choices` entry; wording is verbatim.
3. NPC text is verbatim too.
4. An ending is a node with `"choices": []`; its `text` is the outcome text.
5. Endings that convert the character carry `"converted": true`; all others count as `spared`.
6. A choice with `next: ""` leaves immediately and counts as `spared`.
7. Design choice labels to fit the 12px choices cloud (Rose's longest set is the benchmark).

## 4. Runtime flow

1. Player clicks the character's tag on the map (`characters.gd`).
2. `GameState.select_character(id)` then `SceneTransition.change_scene(GameState.DIALOGUE_SCENE)`.
3. Choices are clicked or picked with keys `1`-`9`.
4. On an ending, `GameState.finish_conversation(outcome)` runs once: it locks the
   conversation and applies `effects[outcome]` via `GameState.change_stat`
   (clamped 0-100, emits `stat_changed`).
5. The ending shows `scene` full screen with the outcome text; click or Esc returns to
   the map. The stats bar is hidden meanwhile and shows `+N`/`-N` popups on return.
6. Finished characters' tags are dimmed and disabled. State is in memory only.
7. No Back button and no Esc mid-conversation.

## 5. Illustrated layout (`brothel_dialogue.tscn/.gd`)

- Background room, plus start layers on top (Rose, then the couple). Endings hide the
  layers and show `scene` over `scene_back`.
- NPC speech cloud top-centre (`BUBBLE_RECT`); text auto-shrinks via `_fit_text`.
- Hairless, flipped unicorn pinned bottom-right (`UNICORN_HEIGHT`, `UNICORN_BLEED`).
- Player choices in a separate flipped cloud (`CHOICES_RECT`).
- Outcome text: Grand Malon 28px in a dark panel.

The scene is fully data-driven: `start_scene`, `start_layers`, `outcome_on_top` and the
dialogue come from the character data. Used by every character (Rose, priest, witch, vampire).

## 6. Style rules

- Font: Grand Malon for names, monologue and outcome text.
- Every `BaseButton` click plays a sound automatically (`Audio`).
- `StatsHud` hidden on the menu, monologue and ending scenes.
- No stat numbers outside a character's `effects`.

## 7. Checklist for a new character

1. Read the chart: list nodes, edges, endings; mark which endings convert.
2. Add the data block with `map_pos` and `effects`.
3. Transcribe nodes verbatim; every `next` must exist.
4. Add art to `assets/`, run `Godot --headless --import`.
5. Set `start_scene`, `start_layers` and cloud rects.
6. Validate: headless run with no script errors; walk every branch to an ending; check
   text fit, stat changes and the lock.
7. Screenshot each ending and the map tag.

## 9. Open questions per remaining character (priest, witch, vampire)

- Final dialogue chart?
- Illustration layers for each ending?
- Stat effects for converted vs spared?
- Reuse Rose's illustrated layout?
