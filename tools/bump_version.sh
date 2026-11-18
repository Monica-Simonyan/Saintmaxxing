#!/usr/bin/env bash
# Decides the semver bump for the staged changes, updates VERSION, and prints the new version.
# Usage: git add -A && tools/bump_version.sh [--dry-run]
# Rules are documented in docs/VERSIONING.md.
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"
dry_run=false
[[ "${1:-}" == "--dry-run" ]] && dry_run=true

current=$(tr -d '[:space:]' < VERSION)
IFS=. read -r major minor patch <<< "$current"

# Ignore import sidecars, the version file itself, and documentation.
relevant=$(git diff --cached --name-status | grep -Ev '\.(import|uid)$|[[:space:]](VERSION|docs/.*|README\.md|tools/.*)$' || true)

if [[ -z "$relevant" ]]; then
	echo "none $current (no game-affecting changes)"
	exit 0
fi

level=patch

# MAJOR: a scene added or removed, or a character added or removed in the data registry.
if echo "$relevant" | grep -E '^[AD][[:space:]]+.*\.tscn$' > /dev/null; then
	level=major
fi
if git diff --cached -U0 -- scripts/game_state.gd | grep -E '^[+-][[:space:]]+"id": "' > /dev/null; then
	level=major
fi

# MINOR: a new script, locale, or asset; or a sizeable content addition to the story or translations.
if [[ $level == patch ]]; then
	if echo "$relevant" | grep -E '^A[[:space:]]+(scripts/|locales/|assets/|shaders/)' > /dev/null; then
		level=minor
	fi
	added=$(git diff --cached --numstat -- scripts/game_state.gd locales/en.json | awk '{s+=$1-$2} END {print s+0}')
	if (( added >= 10 )); then
		level=minor
	fi
fi

case $level in
	major) new="$((major + 1)).0.0" ;;
	minor) new="$major.$((minor + 1)).0" ;;
	patch) new="$major.$minor.$((patch + 1))" ;;
esac

if ! $dry_run; then
	echo "$new" > VERSION
	git add VERSION
fi
echo "$level $new (was $current)"
