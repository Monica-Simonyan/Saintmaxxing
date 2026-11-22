# Saintmaxxing: Product and Engineering Spec

Status: reflects the game as shipped in release v1.0 (Godot 4.7.2).

---

# Part 1: Product Spec

## 1.1 Summary

Saintmaxxing is a short, single-player, choice-driven narrative RPG. The player is a wise unicorn who walks a chaotic medieval town (Sinerwood) and talks to four morally ambiguous residents. In each conversation the player chooses whether to *convert* the character to kindness or *spare* them (leave them as they are). Each outcome moves four town-wide stats. When all four conversations are finished, a town newspaper summarises how the town changed.

## 1.2 Goals

- A complete, replayable story of about 15 to 25 minutes.
- Zero-install play in a browser, plus a downloadable app for macOS and Windows.
- Fully playable in English and Russian.
- Consequences the player can see: stat bars, floating deltas, and an ending newspaper that reflects their choices.

## 1.3 Non-goals (v1.0)

- Save/load or progress persistence (only the language choice persists).
- Voice acting, controller or touch support, accessibility options beyond text size fitting.
- More than two languages, or in-game settings such as volume.
- Multiple endings beyond the stat-driven newspaper.

## 1.4 Target audience and platforms

- Players of short narrative and visual-novel games, desktop mouse users.
- Web: https://monica-simonyan.github.io/Saintmaxxing/ (desktop browser, single-threaded WebAssembly).
- Downloads: GitHub Releases, `Saintmaxxing-macOS.zip` (universal) and `Saintmaxxing-windows.zip` (x86_64). Builds are unsigned.

## 1.5 Player flow

1. **Main menu:** "Start the Adventure" and "Language" (English / Russian).
2. **Unicorn monologue:** five lines drift in over the unicorn's mane. Click skips typing or advances. A "Begin" button appears at the end.
3. **Town map:** an intro scroll opens. Click it or outside it to close. Four tags mark the locations.
4. **Conversation:** pick a location, talk through a branching dialogue ending in an illustrated outcome scene, then return to the map. Each conversation can be completed once.
5. **Ending:** after the fourth conversation the news scroll appears on the map, composed from how the stats ended up.
6. **Anytime:** the pause button (top left) or Esc opens Resume / Restart / Exit. Esc on the map returns to the menu.

## 1.3 Content

| Location | Character | Converted | Spared |
|---|---|---|---|
| Temple | Priest | +25 Love, +25 Faith | -25 Love, -25 Faith |
| Hut | Witch | +25 Love, +25 Magic | -15 Love, -25 Magic |
| Castle | Vampire | -25 Justice | +25 Justice |
| Brothel | Rose (brothel worker) | -25 Love, -15 Justice | +25 Love |

Stats: **Love**, **Faith**, **Justice**, **Magic**. Each starts at 50 and is clamped to 0..100. Hovering a stat icon shows its tooltip. A stat that ends above or below 50 contributes one "up" or "down" paragraph to the newspaper. Stats exactly at 50 add nothing.

Dialogue is a directed graph per character. Some choices lead to a failure or early ending that gives no effect other than being marked complete. The unmarked ending nodes are the "spared" outcome, and nodes marked `converted: true` are the converting one.

## 1.7 UX requirements

- Hidden OS cursor, replaced by a unicorn-horn cursor with a sparkle trail that always renders above all UI.
- Text always fits its container: fonts shrink down to a 10 pt floor rather than overflow.
- Typewriter text at 65 characters per second, with a minimum of 0.25 s and a maximum of 2.2 s per line. Click skips.
- Fade transition between scenes (0.32 s).
- Stat changes show floating deltas and a sound (up or down).
- Looping background music and a click sound on every button.
- Language switch re-translates whatever is currently on screen without replaying it.

## 1.8 Success measures

- Players reach the ending newspaper (completion rate).
- Page loads and plays without freezing on typical laptops (target 60 fps).
- No untranslated strings in either language.

## 1.9 Open questions and risks

- Reported lag on the deployed web build was not reproduced in automated headless testing (about 60 fps, rare stalls up to 180 ms). The downloadable build avoids the single-thread limitation.
- Third-party assets (the Dumbledor font ships an EULA) need a licensing check before wide distribution.
- Some art may derive from an earlier personal project. Confirm rights before commercial use.
- Builds are unsigned, so macOS Gatekeeper and Windows SmartScreen warn on first launch.
- The commit author name and email in git history are public.

---

# Part 2: Engineering Spec

## 2.1 Stack

| Item | Choice |
|---|---|
| Engine | Godot 4.7.2, GDScript |
| Renderer | GL Compatibility (required for web) |
| Viewport | 1280x720, stretch mode `canvas_items` |
| Web export | Single-threaded, no extensions (`variant/thread_support=false`), no special server headers needed |
| Desktop export | macOS universal zip, Windows x86_64 single exe (embedded PCK) |
| Hosting | GitHub Pages, branch `gh-pages` |
| CI | GitHub Actions `.github/workflows/deploy.yml` |

## 2.2 Repository layout

```
project.godot            settings and autoloads
export_presets.cfg       presets: Windows Desktop, Web, macOS
scenes/menu.tscn         main menu
scenes/unicorn_monologue.tscn  opening monologue
scenes/map.tscn          town map
scenes/dialogue.tscn     the generic dialogue scene used for all four characters
scripts/                 all GDScript (about 2,300 lines)
scripts/data/character_data.gd  character and dialogue content (locale keys, art paths)
scripts/hint_badge.gd    hint icon and tooltip shown in dialogues
scripts/quest_overlay.gd  base class of the hint mini-games (HUD hiding, pause-menu group, retry button)
scripts/quest_hud.gd     top-right readout shared by the mini-games (value plus optional hearts)
scripts/quest_intro_popup.gd  the unicorn's cloud that explains a quest before it starts
scripts/card_matching_quest.gd, quest_card.gd  witch mini-game
scripts/coin_catch.gd    priest mini-game
scripts/story_scroll.gd  scroll overlay shared by the map and quest rewards
scripts/cloud_label.gd   label style used inside speech clouds
shaders/hair_fade.gdshader  mane fade on the monologue
themes/                  default Godot theme
locales/en.json, ru.json translation tables
assets/characters/<name>/  per-character art; assets/map, assets/ui (with stats/), fonts, audio
docs/                    this spec and CHARACTER_DIALOGUE_SPEC.md
build/                   export output (gitignored, with .gdignore)
```

## 2.3 Scene flow

`menu` -> `unicorn_monologue` -> `map` <-> `dialogue` (one scene, driven by data). Every change goes through `SceneTransition.change_scene()`, which fades out, swaps, and fades in.

## 2.4 Autoloads

| Autoload | Responsibility |
|---|---|
| `Localization` | Loads `locales/*.json`, `t(key)` lookup with English fallback, `set_language()`, persists the choice to `user://settings.cfg`, emits `language_changed`, and sets Cyrillic fallback fonts. |
| `GameState` | Game state and scene paths: `stats`, `completed_conversations`, `selected_character_id`, `map_intro_shown`, and the `characters` registry, copied from `CharacterData.ALL` (dialogue graphs, art paths, layout rects, effects). API: `change_stat`, `finish_conversation(outcome)`, `select_character`, `reset_state`, `all_conversations_completed`, `is_intro_scene`. Signal `stat_changed(stat_id, value, applied_delta)`. |
| `SceneTransition` | Fade overlay and scene swapping. |
| `Cursor` | Top layer (128) unicorn-horn cursor and a `CPUParticles2D` trail, processing only while the mouse moves. |
| `Audio` | Looping music, click sound on every `BaseButton` (hooked through `node_added`), stat up/down effects. Music pauses with the tree. |
| `PauseMenu` | Layer 101. Pause button, overlay with Resume, Restart and Exit, Esc handling. Hidden on intro scenes. |
| `StatsHud` | Four stat icons with scores, tooltips and floating delta popups. Hidden on intro scenes. |

## 2.5 Data model

A character entry (see `docs/CHARACTER_DIALOGUE_SPEC.md` for the full contract):

```
id, map_pos (fraction of map), name (key), effects {converted|spared: {stat: delta}},
start_node, start_scene, start_layers, bubble_* and choices_* layout rects,
dialogue: { node_id: { text: key, choices: [{label: key, next: node_id}],
                       scene?: path, scene_back?: path, converted?: bool } }
```

- A node with empty `choices` is an ending. `converted: true` selects the converting effects, otherwise the spared effects are applied.
- `finish_conversation` is idempotent per character: it marks completion and applies effects once.
- All displayed text is a locale key. Adding a character means adding data in `scripts/data/character_data.gd`, strings to both JSON files, and art. No new scenes or scripts.

## 2.6 Key behaviours

- **Map** (`map.gd`): builds the background, creates a styled tag button per character at `map_pos`, hover scale 1.08, and tags of completed characters are inert. Shows the intro scroll once per run and the news scroll once all four are done. Scroll closes on a click outside it or on the hint.
- **News** (`_compose_news`): for stats in the order Justice, Faith, Magic, Love, add the up or down paragraph when the stat differs from 50.
- **Dialogue** (`dialogue.gd`): builds the UI in code from character data: background and layers, NPC cloud, mirrored choices cloud, unicorn, outcome panel, sparkle effect. Clouds auto-size to the text. Ending nodes wash in a full-screen scene with outcome text, then return to the map on click.
- **Hint mini-games:** a starred hint icon appears on a line with a `helps` choice until the character's quest is complete. While it shows, the choices cloud is replaced by a lock (click for the "Defeat the quest" note) and number keys are ignored. Clicking the icon opens `QuestIntroPopup` (`quest_intro` text), whose button starts the game named by `hint_game` (`"coins"`, `"cards"`, `"dress"` or the `"placeholder"` stand-in). Both games extend `QuestOverlay`, are added over the dialogue and emit `won`. The dialogue then shows the character's `quest_scroll`; dismissing it closes the game, calls `GameState.complete_quest` and redraws the line with the choices. The back button during a game returns to the dialogue (saved progress resumes); restarting the game clears everything.
  - **Card Matching Quest (witch):** 3x4 face-down grid from `GameState.get_quest_deck()` (shuffled once per session, translucent brown background). Turning three cards is one turn; a matching set stays up, otherwise it flips back. The top-right counter shows turns used of `MAX_TURNS` (10). Using all turns without matching everything offers Retry, which spins the grid away and back with a fresh shuffle (`GameState.reshuffle_quest_deck`). State lives in `GameState.quest_up/quest_pending/quest_turns`.
  - **Dress-up (Rose, work in progress):** the maiden sits on a table on the left in her basic top and bottom; a grid on the right holds eight clothing items (`DressUpQuest.ITEMS`, one top and one bottom worn at a time; clicking a worn item again removes it). Finish ends the quest. The reward scroll depends on whether the player clicked any item (`harlot.quest-scroll`) or not (`harlot.quest-scroll-bare`, no hint) via the `QuestOverlay.reward_scroll_key()` hook.
  - **Coin catch (priest):** 30 coins drop on a timer 1.5-3 s apart, never waiting for the previous coin to land (each takes 2-5 s to fall and is scheduled so the sack can always reach it after the previous catch; about a third fall slowly, then speed up 1.8-2.6x part-way down; never within a sack-width of the side edges) onto a sack moved with A/D or the arrow keys. A catch plays `coin_catch.mp3`; a miss flashes the overlay #6D0F1C, plays the negative stat sound and empties a heart. The third miss offers Retry; finishing all 30 coins wins.
- **Scrolls** (`StoryScroll`): one overlay for the map intro and news and for quest rewards. Text shrinks to fit; a click anywhere or on the footer dismisses it.
- **Text fitting** (`TextFit.shrink_to_fit`): steps the font down one size per frame until `get_content_height()` fits. This needs a frame per step because the label only lays out between frames.
- **Localization:** `language_changed` makes every screen re-translate in place. The story and dialogue fonts lack Cyrillic glyphs, so Ruslan Display and Underdog are registered as fallbacks.
- **Pause:** `get_tree().paused` while the overlay is open. Exit quits on desktop. On web it tries `window.close()` and otherwise returns to the menu.

## 2.7 Build and deploy

**Web (automatic):** push to `main` runs the workflow. It downloads Godot 4.7.2 and the export templates, exports the preset named exactly `Web`, copies `index.html` to `404.html`, adds `.nojekyll`, and force-publishes to `gh-pages` (about 2 minutes). Pages serves `gh-pages` at `/`. Manual runs: `gh workflow run deploy.yml`.

**Desktop (manual):**

```
godot --headless --path . --export-release "Windows Desktop" build/windows/Saintmaxxing.exe
godot --headless --path . --export-release "macOS" build/macos/Saintmaxxing.zip
gh release create vX.Y <zips> -R Monica-Simonyan/Saintmaxxing
```

macOS universal export requires `textures/vram_compression/import_etc2_astc=true`, which is set.

**Local git setup:** two copies are used. `~/Desktop/saintmaxxing-main` is edited in the Godot editor, and `~/Downloads/saintmaxxing-main` is the git working copy, synced with rsync. The app injects `GH_TOKEN` and `GIT_ASKPASS`, which must be unset before git or gh commands.

## 2.8 Performance notes

- Large textures are about 1920x1080 PNGs (8 MB each in VRAM); the unicorn art was downscaled from 2480x3508 to 1060x1500.
- The 22 MB `exploration.wav` music is imported as ADPCM. Converting it to Ogg Vorbis would shrink the download and the web build.
- Per-frame work is minimal: the HUD and pause button visibility checks, the music pause flag, and the cursor trail only while moving.
- Text fitting costs one frame per font step, which is fine in practice but can cause a visible settle on long lines.

## 2.9 Testing

There is no automated test suite. Verification so far has been manual, plus headless-rendered screenshots (`godot -s script.gd` with `root.get_texture().get_image().save_png`) and headless browser frame-time sampling against the deployed site.

Suggested additions: a headless script that walks every dialogue graph and asserts that all `next` targets and locale keys exist in both languages, and that every ending applies effects.

## 2.10 Known issues and technical debt

- No save system, so a reload restarts the story.
- Builds are not signed or notarized, and desktop releases are not built by CI.
- The first web load downloads about 70 MB of build output.
