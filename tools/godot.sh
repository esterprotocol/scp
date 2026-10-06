#!/usr/bin/env bash
set -euo pipefail
project_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
export XDG_CACHE_HOME="$project_dir/.tools/cache"
export XDG_DATA_HOME="$project_dir/.tools/data"
export XDG_CONFIG_HOME="$project_dir/.tools/config"
mkdir -p "$XDG_CACHE_HOME" "$XDG_DATA_HOME" "$XDG_CONFIG_HOME"
godot_bin="${GODOT_BIN:-godot}"
if ! command -v "$godot_bin" >/dev/null 2>&1; then
  printf '%s\n' 'Godot não encontrado. Instale Godot 4.6.3 stable oficial ou defina GODOT_BIN.' >&2
  exit 1
fi
godot_version="$("$godot_bin" --headless --version)"
if [[ "$godot_version" != '4.6.3.stable.official.7d41c59c4' ]]; then
  printf 'Versão esperada: 4.6.3.stable.official.7d41c59c4; encontrada: %s\n' "$godot_version" >&2
  exit 1
fi
exec "$godot_bin" --path "$project_dir" "$@"
