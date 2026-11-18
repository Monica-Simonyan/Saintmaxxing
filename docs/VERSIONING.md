# Versioning

Semantic versioning (`MAJOR.MINOR.PATCH`), stored in `VERSION`. Every push to `main` gets a bump decided by these rules, applied by `tools/bump_version.sh` and tagged `vX.Y.Z`.

| Bump | When | Examples |
|---|---|---|
| **Major** | The story structure or the scene set changes. A `.tscn` scene is added or removed, or a character is added or removed in `game_state.gd`. | New location and character, removing a scene |
| **Minor** | New content or capability without changing the story structure. A new script, locale file, shader or asset is added, or at least 10 net lines are added to `game_state.gd` or `locales/en.json`. | New feature script, new language, new art or font, new dialogue branch |
| **Patch** | Anything else that affects the game. | Bug fixes, layout tweaks, text edits, tuning numbers, replacing an existing image |
| **None** | Only docs, `README.md`, `tools/`, `VERSION`, or import sidecars (`.import`, `.uid`) changed. | Spec updates |

The highest matching level wins. "Medium" is treated as **minor**.

## Usage

```
git add -A
tools/bump_version.sh --dry-run   # preview the level
tools/bump_version.sh             # writes and stages VERSION
git commit -m "<scene or script name>"
git tag vX.Y.Z && git push origin main --tags
```

Desktop downloads are rebuilt as a GitHub Release only on request, using the same tag.
