#!/usr/bin/env bash
# Commit, version, tag, push and (optionally) rebuild the desktop downloads as a GitHub Release.
# Usage: tools/publish.sh "<scene or script name>" [--release]
# Run from the git working copy. Edits live in ~/Desktop/saintmaxxing-main and are mirrored here first.
set -euo pipefail

msg="${1:?commit message (scene or script name) required}"
release=false
[[ "${2:-}" == "--release" ]] && release=true

SRC="$HOME/Desktop/saintmaxxing-main"
REPO="Monica-Simonyan/Saintmaxxing"
GODOT=/Applications/Godot.app/Contents/MacOS/Godot

# The app injects tokens that override the gh login.
unset GH_TOKEN GITHUB_TOKEN GIT_ASKPASS GIT_CONFIG_PARAMETERS GIT_CONFIG_COUNT GIT_CONFIG_SYSTEM
export GIT_TERMINAL_PROMPT=0

cd "$(git rev-parse --show-toplevel)"
rsync -a --delete --exclude .git --exclude .godot --exclude build --exclude tools --exclude VERSION --exclude .github --exclude .DS_Store --exclude docs/VERSIONING.md --exclude docs/PRODUCT_AND_ENGINEERING_SPEC.md "$SRC/" ./
git add -A

if git diff --cached --quiet; then
	echo "Nothing to commit."
else
	tools/bump_version.sh
	git commit -q -m "$msg"
	git tag "v$(tr -d '[:space:]' < VERSION)"
fi

git push -q origin main --tags
version="v$(tr -d '[:space:]' < VERSION)"
echo "Pushed $version; the web deploy runs on GitHub (about 2 minutes)."

if $release; then
	mkdir -p "$SRC/build/windows" "$SRC/build/macos"
	(cd "$SRC" && "$GODOT" --headless --path . --export-release "Windows Desktop" build/windows/Saintmaxxing.exe >/dev/null 2>&1 \
		&& "$GODOT" --headless --path . --export-release "macOS" build/macos/Saintmaxxing.zip >/dev/null 2>&1)
	tmp=$(mktemp -d)
	(cd "$SRC/build/windows" && zip -q "$tmp/Saintmaxxing-windows.zip" Saintmaxxing.exe)
	# Godot leaves the template's signature on a modified bundle, which macOS reports as "damaged".
	mkdir "$tmp/mac" && unzip -q "$SRC/build/macos/Saintmaxxing.zip" -d "$tmp/mac"
	codesign --force --deep -s - "$tmp/mac"/*.app
	ditto -c -k --keepParent "$tmp/mac"/*.app "$tmp/Saintmaxxing-macOS.zip"
	rm -rf "$tmp/mac"
	gh release create "$version" "$tmp"/*.zip -R "$REPO" -t "Saintmaxxing $version" \
		-n "Download the zip for your system, unzip it and double-click to play.
- macOS: right-click the app and choose Open the first time (not signed by Apple).
- Windows: if SmartScreen warns, click More info, then Run anyway."
	rm -rf "$tmp"
fi
