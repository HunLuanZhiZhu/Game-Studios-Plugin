#!/bin/sh
# env_inventory.sh — machine environment inventory for game-studios-init.
#
# Run with bash:  bash "$SKILL_DIR/scripts/env_inventory.sh" [--no-launch] [WORKSPACE_DIR]
#
# WORKSPACE_DIR (default: current directory) anchors the "workspace-nearby"
# scans: the directory itself, its parent, and its grandparent are scanned
# IN ADDITION to the drive roots (deeper, and catches installs that live next
# to the project — e.g. a portable Godot checkout kept in ../godot/).
#
# Read-only diagnostic EXCEPT one action: if Blender is installed but not
# running it is launched (the MCP addon socket only exists while Blender is
# open). Pass --no-launch to suppress. Never writes to the workspace.
#
# Sections:
#   1. Game engines   — Godot / Unity / Unreal installs; if none, recommends
#                       https://godotengine.org/download
#   2. Blender MCP    — bridge CLI + addon socket on 127.0.0.1:9876; if the
#                       socket is down, walks the installed/running/relaunch
#                       ladder; final fallback points the user at
#                       https://www.blender.org/lab/mcp-server/
#   3. ComfyUI        — install discovery (same order as the comfyui-headless
#                       skills), then which of the expected Qwen-Image-2.1 /
#                       Pixal3D-TRELLIS.2 weight files are actually registered.

set -u

NO_LAUNCH=0
WS=""
for arg in "$@"; do
  case "$arg" in
    --no-launch) NO_LAUNCH=1 ;;
    -h|--help) sed -n '2,12p' "$0" | sed 's/^# \?//'; exit 0 ;;
    *) if [ -z "$WS" ]; then WS="$arg"; else printf 'error: unexpected argument: %s\n' "$arg" >&2; exit 1; fi ;;
  esac
done
if ! WS="$(cd "${WS:-$PWD}" 2>/dev/null && pwd)"; then
  printf 'warning: workspace dir not found, using current directory\n' >&2
  WS="$PWD"
fi

OS=$(uname -s 2>/dev/null || echo unknown)
case "$OS" in
  MINGW*|MSYS*|CYGWIN*) HOST_OS=windows ;;
  Darwin)               HOST_OS=mac ;;
  Linux*)               HOST_OS=linux ;;
  *)                    HOST_OS=other ;;
esac

say() { printf '%s\n' "$*"; }
hdr() { say ""; say "―― $* ――"; }
ind() { printf '    %s\n' "$*"; }
warn() { printf '    [!] %s\n' "$*"; }
ok()   { printf '    [+] %s\n' "$*"; }
bad()  { printf '    [-] %s\n' "$*"; }

# POSIX-path helper: on Git Bash, Windows env vars hold backslash paths.
p() {
  _p_val="$1"
  if [ "$HOST_OS" = windows ] && command -v cygpath >/dev/null 2>&1; then
    cygpath -u "$_p_val" 2>/dev/null || printf '%s' "$_p_val"
  else
    printf '%s' "$_p_val"
  fi
}

# TCP probe via bash's /dev/tcp (this script is documented to run under bash).
port_open() {
  ( exec 3<>"/dev/tcp/$1/$2" ) 2>/dev/null && return 0
  return 1
}

# ── 1. Game engines ───────────────────────────────────────────────────────
FOUND_ENGINE=""

check_godot() {
  found=""
  for exe in godot godot4 godot4.4 godot4.3; do
    command -v "$exe" >/dev/null 2>&1 && { found="$(command -v "$exe")"; break; }
  done
  candidates=""
  if [ "$HOST_OS" = windows ]; then
    for base in "$(p "${LOCALAPPDATA:-}/Programs")" "$(p "${PROGRAMFILES:-}")"; do
      [ -d "$base" ] && candidates="$candidates $(find "$base" -maxdepth 2 -iname 'Godot*.exe' 2>/dev/null)"
    done
    # workspace-nearby first (deeper than the drive scan reaches)
    for wsd in "$WS" "$WS/.." "$WS/../.."; do
      [ -d "$wsd" ] || continue
      candidates="$candidates $(find "$wsd" -maxdepth 4 \( -iname Windows -o -iname 'Windows.old' -o -iname Users -o -iname node_modules \) -prune -o -iname 'Godot*.exe' -print 2>/dev/null)"
    done
    # portable installs live anywhere — scan drive roots (pruned, depth 4)
    for d in $(for L in c d e f g h i j k l m n o p q r s t u v w x y z; do [ -d "/$L" ] && printf '/%s ' "$L"; done); do
      candidates="$candidates $(find "$d" -maxdepth 4 \( -iname Windows -o -iname 'Windows.old' -o -iname Users \) -prune -o -iname 'Godot*.exe' -print 2>/dev/null)"
    done
  elif [ "$HOST_OS" = mac ]; then
    candidates="$(find /Applications -maxdepth 2 -iname 'Godot*.app' 2>/dev/null)"
  else
    candidates="$(command -v godot 2>/dev/null || true)"
  fi
  for c in $candidates; do
    found="$c"; break
  done
  [ -n "$found" ] || return 1
  found="$(cd "$(dirname "$found")" 2>/dev/null && pwd)/$(basename "$found")"
  # prefer the console wrapper for a clean --version read on Windows
  ver_exe="$found"
  case "$found" in
    *_console.exe) ;;
    *.exe) [ -f "${found%.exe}_console.exe" ] && ver_exe="${found%.exe}_console.exe" ;;
  esac
  ver="$("$ver_exe" --version 2>/dev/null | head -1)"
  ok "Godot: $found ${ver:+(v$ver)}"
  FOUND_ENGINE="godot"
  return 0
}

check_unity() {
  editors=""
  if [ "$HOST_OS" = windows ]; then
    for hub in "$(p "${PROGRAMFILES:-}/Unity/Hub/Editor")" "$(p "${LOCALAPPDATA:-}/Programs/Unity/Hub/Editor")" "$(p "${PROGRAMFILES:-}/Unity/Editor")"; do
      [ -d "$hub" ] && editors="$editors $(find "$hub" -maxdepth 3 -name 'Unity.exe' 2>/dev/null)"
    done
  elif [ "$HOST_OS" = mac ]; then
    [ -d /Applications/Unity ] && editors="$(find /Applications/Unity -maxdepth 4 -name 'Unity.app' 2>/dev/null)"
  else
    [ -d "$HOME/Unity/Hub/Editor" ] && editors="$(find "$HOME/Unity/Hub/Editor" -maxdepth 3 -name Unity 2>/dev/null)"
  fi
  [ -n "$(printf '%s' "$editors" | tr -d ' ')" ] || return 1
  for e in $editors; do
    ok "Unity: $e"
    FOUND_ENGINE="unity"
  done
  return 0
}

check_unreal() {
  dirs=""
  if [ "$HOST_OS" = windows ]; then
    for hive in 'HKLM\SOFTWARE\EpicGames\Unreal Engine' 'HKCU\SOFTWARE\EpicGames\Unreal Engine'; do
      q="$(MSYS_NO_PATHCONV=1 reg query "$hive" /s /v InstalledDirectory 2>/dev/null || true)"
      dirs="$dirs $(printf '%s\n' "$q" | grep 'InstalledDirectory' | awk '{print $NF}' | tr -d '\r')"
    done
  elif [ "$HOST_OS" = mac ]; then
    [ -d "/Users/Shared/Epic Games" ] && dirs="$(find "/Users/Shared/Epic Games" -maxdepth 1 -name 'UE_*' 2>/dev/null)"
  fi
  hit=0
  for d in $dirs; do
    [ -d "$d" ] || continue
    ok "Unreal Engine: $d"
    FOUND_ENGINE="unreal"
    hit=1
  done
  return $((1 - hit))
}

hdr "1. Game engines"
check_godot || true
check_unity || true
check_unreal || true
if [ -z "$FOUND_ENGINE" ]; then
  bad "no game engine detected on this machine"
  ind "recommendation: install Godot (free, open source) — https://godotengine.org/download"
else
  ok "engines detected: $FOUND_ENGINE"
fi

# ── 2. Blender + MCP ──────────────────────────────────────────────────────
BLENDER_URL="https://www.blender.org/lab/mcp-server/"
MCP_PORT=9876
BLENDER_EXE=""

find_blender() {
  if command -v blender >/dev/null 2>&1; then BLENDER_EXE="$(command -v blender)"; return 0; fi
  if [ "$HOST_OS" = windows ]; then
    # default file-association target of .blend files records the exe path
    for hive in 'HKCU\SOFTWARE\Classes\blendfile\shell\open\command' 'HKLM\SOFTWARE\Classes\blendfile\shell\open\command'; do
      v="$(MSYS_NO_PATHCONV=1 reg query "$hive" /ve 2>/dev/null | grep REG_SZ | sed 's/.*REG_SZ *//; s/"%1".*//; s/"//g' | tr -d '\r')"
      if [ -n "$v" ] && [ -f "$(p "$v")" ]; then BLENDER_EXE="$(p "$v")"; return 0; fi
    done
    for exe in $(find "$(p "${PROGRAMFILES:-}/Blender Foundation")" -maxdepth 2 -name blender.exe 2>/dev/null); do
      BLENDER_EXE="$exe"; return 0
    done
  elif [ "$HOST_OS" = mac ]; then
    [ -x /Applications/Blender.app/Contents/MacOS/Blender ] && { BLENDER_EXE=/Applications/Blender.app/Contents/MacOS/Blender; return 0; }
  else
    for exe in /usr/bin/blender /usr/local/bin/blender /snap/bin/blender; do
      [ -x "$exe" ] && { BLENDER_EXE="$exe"; return 0; }
    done
  fi
  return 1
}

blender_running() {
  if [ "$HOST_OS" = windows ]; then
    tasklist 2>/dev/null | grep -qi 'blender\.exe'
  else
    pgrep -x blender >/dev/null 2>&1 || pgrep -x Blender >/dev/null 2>&1
  fi
}

launch_blender() {
  if [ "$NO_LAUNCH" = 1 ]; then
    ind "(--no-launch: not starting Blender)"
    return 1
  fi
  [ -n "$BLENDER_EXE" ] || return 1
  ind "starting Blender ..."
  if [ "$HOST_OS" = windows ]; then
    cmd //c start "" "$(cygpath -w "$BLENDER_EXE" 2>/dev/null || echo "$BLENDER_EXE")" >/dev/null 2>&1
  elif [ "$HOST_OS" = mac ]; then
    open -a Blender >/dev/null 2>&1
  else
    setsid "$BLENDER_EXE" >/dev/null 2>&1 &
  fi
  # the addon socket only appears once Blender is up; wait up to ~24s
  i=0
  while [ $i -lt 12 ]; do
    sleep 2; i=$((i + 1))
    port_open 127.0.0.1 "$MCP_PORT" && return 0
  done
  return 1
}

hdr "2. Blender / MCP"
bridge_ok=0
if command -v blender-mcp >/dev/null 2>&1; then
  ok "blender-mcp bridge on PATH: $(command -v blender-mcp)"
else
  warn "blender-mcp CLI not on PATH (the .mcp.json server needs it; pip install blender-mcp)"
fi
if port_open 127.0.0.1 "$MCP_PORT"; then
  ok "Blender MCP addon socket listening on 127.0.0.1:$MCP_PORT — MCP usable now"
  bridge_ok=1
else
  bad "nothing listening on 127.0.0.1:$MCP_PORT (Blender addon socket down)"
  if find_blender; then
    ok "Blender installed: $BLENDER_EXE"
    if blender_running; then
      warn "Blender is running but the MCP addon socket is not — enable the MCP addon (Edit > Preferences > Add-ons) or press its Start server button, then retry"
    else
      if launch_blender; then
        ok "Blender started and MCP socket came up on 127.0.0.1:$MCP_PORT"
        bridge_ok=1
      else
        warn "retried after launching Blender — socket still down; if you need Blender, start it and enable the MCP addon per: $BLENDER_URL"
      fi
    fi
  else
    bad "Blender is not installed; if you need it (3D modeling), set it up per: $BLENDER_URL"
  fi
fi

# ── 3. ComfyUI + registered models ────────────────────────────────────────
# Expected weights (from skills/comfyui-headless-image21 and -pixal3d).
# image21: one per row of the first three is enough for image generation.
MODELS_EXPECTED="
diffusion_models|qwen_image_2.1_int8_convrot.safetensors|image21
diffusion_models|qwen_image_2.1_bf16.safetensors|image21
text_encoders|qwen3vl_8b_int8_convrot.safetensors|image21
text_encoders|qwen3vl_8b_bf16.safetensors|image21
vae|qwen_image_2.1_vae_bf16.safetensors|image21
diffusion_models|pixal3d_int8_convrot.safetensors|pixal3d
diffusion_models|pixal3d_multiview_int8_convrot.safetensors|pixal3d
diffusion_models|trellis_2_int8_convrot.safetensors|pixal3d
vae|trellis_2_shape_vae_bf16.safetensors|pixal3d
vae|trellis_2_texture_vae_bf16.safetensors|pixal3d
clip_vision|dino_v3_L_naf_fp32.safetensors|pixal3d
geometry_estimation|moge_2_vitl_normal_fp16.safetensors|pixal3d
background_removal|birefnet.safetensors|pixal3d
"

hdr "3. ComfyUI"
COMFY_HOME="${COMFYUI_HOME:-}"
comfy_install=""
if [ -n "$COMFY_HOME" ] && [ -e "$(p "$COMFY_HOME")/main.py" ]; then
  comfy_install="$(p "$COMFY_HOME")"
  ok "install (COMFYUI_HOME): $comfy_install"
fi
if [ -z "$comfy_install" ] && [ "$HOST_OS" = windows ]; then
  regfile="$(p "${APPDATA:-}")/Comfy Desktop/installations.json"
  if [ -f "$regfile" ]; then
    # JSON escapes backslashes (\\) — tr -s '\134' collapses them to single ones
    for ip in $(grep -o '"installPath"[^,}]*' "$regfile" | sed 's/.*:\s*"//; s/"$//' | tr -s '\134' | tr -d '\r'); do
      ip="$(p "$ip")"
      if   [ -e "$ip/main.py" ];        then comfy_install="$ip"
      elif [ -e "$ip/ComfyUI/main.py" ]; then comfy_install="$ip/ComfyUI"
      fi
      if [ -n "$comfy_install" ]; then ok "install (Desktop registry): $comfy_install"; break; fi
    done
    [ -n "$comfy_install" ] || warn "Desktop registry exists but no installPath contains main.py"
  fi
fi
if [ -z "$comfy_install" ]; then
  # shallow scan of drive roots + program dirs for *omfy* (per skill convention)
  scan_dirs="/opt $HOME $WS $WS/.. $WS/../.. $(p "${LOCALAPPDATA:-}/Programs") $(p "${PROGRAMFILES:-}")"
  if [ "$HOST_OS" = windows ]; then
    for L in c d e f g h i j k l m n o p q r s t u v w x y z; do [ -d "/$L" ] && scan_dirs="$scan_dirs /$L"; done
  fi
  for base in $scan_dirs; do
    [ -d "$base" ] || continue
    hit="$(find "$base" -maxdepth 2 -iname '*omfy*' -type d 2>/dev/null | head -1)"
    if [ -n "$hit" ]; then
      hit2="$(find "$hit" -maxdepth 4 -name main.py 2>/dev/null | head -1)"
      if [ -n "$hit2" ]; then
        comfy_install="$(dirname "$hit2")"
        ok "install (shallow scan): $comfy_install"
        break
      fi
    fi
  done
fi

if [ -z "$comfy_install" ]; then
  bad "ComfyUI not detected on this machine (skipping model inventory)"
  say ""
  say "Inventory finished."
  exit 0
fi

# where models can be registered: server port 8188 is ground truth when up
roots="$comfy_install/models"
if [ "$HOST_OS" = windows ]; then
  dsettings="$(p "${APPDATA:-}")/Comfy Desktop"
  [ -f "$dsettings/settings.json" ] && \
    roots="$roots $(grep -o '"modelsDirs"[^]]*]' "$dsettings/settings.json" | sed 's/.*\[//; s/\]//; s/"//g' | tr ',' '\n' | tr -d '\r' | while IFS= read -r mp; do [ -n "$mp" ] && p "$mp"; done)"
  for yml in "$dsettings/shared_model_paths.yaml" "$comfy_install/extra_model_paths.yaml"; do
    [ -f "$yml" ] && roots="$roots $(grep -oE "base_path: *['\"]?[^'\"]+" "$yml" | sed "s/base_path: *['\"]\?//" | while IFS= read -r mp; do [ -n "$mp" ] && p "$mp"; done)"
  done
else
  for yml in "$HOME/.config/ComfyUI/extra_model_paths.yaml" "$comfy_install/extra_model_paths.yaml"; do
    [ -f "$yml" ] && roots="$roots $(grep -oE "base_path: *['\"]?[^'\"]+" "$yml" | sed "s/base_path: *['\"]\?//")"
  done
fi

server_up=0
if port_open 127.0.0.1 8188; then
  server_up=1
  ok "ComfyUI server running on 127.0.0.1:8188 (listing via API)"
fi

say ""
ind "expected-weight check (image21 needs one per type; pixal3d needs all 8):"
img21_diff=0; img21_te=0; img21_vae=0
while IFS='|' read -r ftype fname skill; do
  [ -n "$ftype" ] || continue
  hit=""
  if [ "$server_up" = 1 ] && command -v curl >/dev/null 2>&1; then
    hit="$(curl -s --max-time 4 "http://127.0.0.1:8188/models/$ftype" 2>/dev/null | grep -oF "$fname" | head -1)"
  fi
  if [ -z "$hit" ]; then
    for r in $roots; do
      [ -d "$r" ] || continue
      hit="$(find "$r" -maxdepth 5 -name "$fname" 2>/dev/null | head -1)"
      [ -n "$hit" ] && break
    done
  fi
  if [ -n "$hit" ]; then
    case "$skill/$ftype" in
      image21/diffusion_models) img21_diff=1 ;;
      image21/text_encoders)    img21_te=1 ;;
      image21/vae)              img21_vae=1 ;;
    esac
    ok "[$skill] $fname"
  else
    bad "[$skill] $fname  ($ftype)  — missing"
  fi
done <<EOF
$MODELS_EXPECTED
EOF
say ""
ind "image21 set complete: $((img21_diff + img21_te + img21_vae))/3 (diffusion=$img21_diff text_encoder=$img21_te vae=$img21_vae) — 3/3 means text-to-image works"

say ""
say "Inventory finished."
exit 0
