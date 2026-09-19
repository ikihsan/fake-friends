#!/usr/bin/env bash
set -euo pipefail
# Dedicated project and user-data namespace: no live autoloads or save access.
repo="$(cd "$(dirname "$0")/.." && pwd)"
sandbox="$(mktemp -d)"
trap 'rm -rf "$sandbox"' EXIT
mkdir -p "$sandbox/scripts/gameplay" "$sandbox/resources" "$sandbox/textures" "$sandbox/tests"
cp -R "$repo/scripts/gameplay/state" "$repo/scripts/gameplay/ui" "$sandbox/scripts/gameplay/"
cp -R "$repo/resources/handbook" "$sandbox/resources/"
cp "$repo/textures/paper.png" "$sandbox/textures/"
cp "$repo/tests/state_ui_isolation.gd" "$sandbox/tests/"
printf '[application]\nconfig/name="FF State UI Isolation"\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n' > "$sandbox/project.godot"
export XDG_DATA_HOME="$sandbox/userdata"
"${GODOT:-godot}" --headless --path "$sandbox" --editor --import --quit >/dev/null 2>&1
"${GODOT:-godot}" --headless --path "$sandbox" --script res://tests/state_ui_isolation.gd
